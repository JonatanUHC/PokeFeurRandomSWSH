#!/usr/bin/env python3
"""Construit et vérifie une empreinte de référence de tous les points de hook.

Problème
--------
Le module `subsdk9` installe ses correctifs à des offsets codés en dur. Rien ne
vérifie qu'ils pointent sur les instructions attendues. Un offset faux écrase du
code vivant et produit un plantage différé et trompeur — COMBAT-CACHE §4
documente trois adresses réfutées et le temps que ça a coûté.

Le projet applique déjà ce garde-fou à un seul endroit (la signature
`0xB9402A60` du combat caché). Cet outil le généralise à tous les hooks.

Principe
--------
`--build` lit le `.text` d'un ExeFS de référence et enregistre, pour chaque
point de hook trouvé dans les sources C++, les 16 octets présents. C'est
l'empreinte de référence.

Sans argument, l'outil relit un ExeFS et compare aux empreintes enregistrées.
Toute divergence signale soit un binaire différent, soit un offset modifié.

L'empreinte ne dit PAS qu'un offset est correct : elle dit qu'il n'a pas changé
depuis la dernière vérification manuelle. C'est une détection de régression, pas
une preuve de justesse.

Portée : Épée 1.3.2 (VER_OFF = 0). Bouclier n'est pas couvert.

Usage
-----
    python tools/build-hook-baseline.py --build <exefs>   # enregistre
    python tools/build-hook-baseline.py <exefs>           # vérifie
"""
from __future__ import annotations

import argparse
import json
import re
import struct
import sys
from pathlib import Path

try:
    import lz4.block
except ImportError:
    print('ECHEC: le module python "lz4" est requis (pip install lz4).')
    sys.exit(1)

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'research' / 'swsh-mods-exl' / 'source' / 'program'
BASELINE = ROOT / 'contract' / 'hook-baseline-epee-1.3.2.json'

EXPECTED_TEXT_LENGTH = 26218288  # Épée 1.3.2
PREIMAGE_BYTES = 16


# --------------------------------------------------------------- extraction
def collect_symbols() -> dict[str, int]:
    """Constantes `const u64 NOM_offset = 0x... - VER_OFF;` (Épée : VER_OFF = 0)."""
    syms: dict[str, int] = {}
    for path in SRC.rglob('*.hpp'):
        for m in re.finditer(
            # const ET constexpr, u32 comme u64 : exp_level_cap.hpp declare ses
            # offsets en `constexpr u64`, que le motif d origine ratait.
            r'(?:const|constexpr)\s+u\d+\s+(\w+)\s*=\s*'
            r'(0x[0-9a-fA-F]+)\s*(?:-\s*VER_OFF)?\s*;',
            path.read_text(encoding='utf-8', errors='replace'),
        ):
            syms[m.group(1)] = int(m.group(2), 16)

    # Seconde passe : certaines constantes sont definies A PARTIR d une autre
    # (`FromParams_after_spec_copy_offset = FromParams_offset + 0x1f8`). On
    # itere jusqu au point fixe pour les resoudre aussi.
    pending: dict[str, str] = {}
    for path in SRC.rglob('*.hpp'):
        for m in re.finditer(
            r'(?:const|constexpr)\s+u\d+\s+(\w+)\s*=\s*([A-Za-z_]\w*[^;]*);',
            path.read_text(encoding='utf-8', errors='replace'),
        ):
            if m.group(1) not in syms:
                pending[m.group(1)] = m.group(2)

    for _ in range(4):
        progressed = False
        for name, expr in list(pending.items()):
            value = resolve(expr, syms)
            if value is not None:
                syms[name] = value
                del pending[name]
                progressed = True
        if not progressed:
            break
    return syms


def collect_arrays() -> dict[str, list[int]]:
    """Tableaux `const u32 NOM[N] = { 0x.., 0x.. };` — p.ex. kSpeciesReadSites."""
    arrays: dict[str, list[int]] = {}
    for path in SRC.rglob('*.hpp'):
        for m in re.finditer(
            r'const\s+u\d+\s+(\w+)\s*\[\s*\d*\s*\]\s*=\s*\{([^}]*)\}',
            path.read_text(encoding='utf-8', errors='replace'),
        ):
            values = re.findall(r'0x[0-9a-fA-F]+', m.group(2))
            if values:
                arrays[m.group(1)] = [int(v, 16) for v in values]
    return arrays


def collect_hooks(syms: dict[str, int], arrays: dict[str, list[int]]) -> list[dict]:
    """Appels `X::InstallAtOffset(expr)` dont l'expression est résoluble."""
    hooks: list[dict] = []
    for path in sorted(SRC.rglob('*.hpp')) + sorted(SRC.rglob('*.cpp')):
        rel = path.relative_to(ROOT).as_posix()
        text = path.read_text(encoding='utf-8', errors='replace')
        for i, line in enumerate(text.splitlines(), 1):
            m = re.search(r'(\w+)::InstallAtOffset\(([^)]+)\)', line)
            if not m:
                continue
            name, expr = m.group(1), m.group(2).strip()

            # Un hook pose en boucle sur un tableau (le combat cache et ses
            # quatre sites) donne une entree par element.
            am = re.fullmatch(r'(\w+)\[\s*\w+\s*\]', expr)
            if am and am.group(1) in arrays:
                for k, addr in enumerate(arrays[am.group(1)]):
                    hooks.append({'hook': f'{name}[{k}]', 'expression': expr,
                                  'file': rel, 'line': i, 'address': addr})
                continue

            hooks.append({'hook': name, 'expression': expr, 'file': rel,
                          'line': i, 'address': resolve(expr, syms)})
    return hooks


def resolve(expr: str, syms: dict[str, int]) -> int | None:
    """Résout `0x123`, `NOM_offset`, `NOM_offset + 0x4C`, `0x123 - VER_OFF`.

    VER_OFF vaut 0 sur Épée. Toute expression non reconnue renvoie None plutôt
    qu'une valeur devinée : mieux vaut un trou signalé qu'un offset invente.
    """
    e = expr.replace('VER_OFF', '0')
    # Depouiller TOUTE qualification, y compris imbriquee
    # (Field::ExtendedCamera::X_offset). Un motif ferme sur une liste de
    # namespaces connus laissait 14 hooks non resolus.
    while re.search(r'\b\w+::', e):
        e = re.sub(r'\b\w+::', '', e)
    for name, value in syms.items():
        e = re.sub(rf'\b{re.escape(name)}\b', str(value), e)
    if not re.fullmatch(r'[\s0-9a-fA-FxX+\-*()]+', e):
        return None
    try:
        return int(eval(e, {'__builtins__': {}}, {}))  # noqa: S307 — expr filtrée
    except Exception:
        return None


# ------------------------------------------------------------------- NSO
def read_text(exefs: Path) -> bytes:
    main = exefs / 'main'
    if not main.is_file():
        raise SystemExit(f'ECHEC: {main} introuvable.')
    raw = main.read_bytes()
    if raw[:4] != b'NSO0':
        raise SystemExit('ECHEC: "main" n est pas un NSO0.')
    off, _, dec = struct.unpack_from('<III', raw, 0x10)
    comp = struct.unpack_from('<I', raw, 0x60)[0]
    flags = struct.unpack_from('<I', raw, 0x0C)[0]
    blob = raw[off:off + comp]
    text = lz4.block.decompress(blob, uncompressed_size=dec) if flags & 1 else blob
    if len(text) != dec:
        raise SystemExit('ECHEC: taille de .text incohérente après décompression.')
    return text


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('exefs', help='dossier exefs contenant "main"')
    ap.add_argument('--build', action='store_true',
                    help='enregistrer l empreinte au lieu de la vérifier')
    args = ap.parse_args()

    text = read_text(Path(args.exefs))
    print(f'.text : {len(text)} octets')
    if len(text) != EXPECTED_TEXT_LENGTH:
        print(f'ECHEC témoin : taille attendue {EXPECTED_TEXT_LENGTH}. '
              f'Binaire différent — rien de ce qui suit n a de sens.')
        return 1
    print('OK    témoin : taille de .text conforme à Épée 1.3.2\n')

    syms = collect_symbols()
    arrays = collect_arrays()
    hooks = collect_hooks(syms, arrays)
    resolved = [h for h in hooks if h['address'] is not None]
    unresolved = [h for h in hooks if h['address'] is None]
    print(f'{len(syms)} constantes, {len(arrays)} tableaux, {len(hooks)} points de hook '
          f'({len(resolved)} résolus, {len(unresolved)} non résolus)')

    for h in resolved:
        a = h['address']
        h['preimage'] = (text[a:a + PREIMAGE_BYTES].hex().upper()
                         if a + PREIMAGE_BYTES <= len(text) else None)

    if args.build:
        payload = {
            'build': 'Epee 1.3.2',
            'textLength': len(text),
            'preimageBytes': PREIMAGE_BYTES,
            'note': ("Empreinte de reference des points de hook. Elle detecte "
                     "un changement d offset ou de binaire ; elle ne prouve pas "
                     "qu un offset est correct."),
            'hooks': sorted(resolved, key=lambda h: h['address']),
            'unresolved': unresolved,
        }
        BASELINE.parent.mkdir(parents=True, exist_ok=True)
        BASELINE.write_text(json.dumps(payload, indent=2, ensure_ascii=False),
                            encoding='utf-8')
        print(f'\nEmpreinte écrite : {BASELINE.relative_to(ROOT)} '
              f'({len(resolved)} points)')
        if unresolved:
            print('Non résolus (expression non reconnue) :')
            for h in unresolved:
                print(f'  {h["hook"]:<32} {h["expression"]}  '
                      f'({h["file"]}:{h["line"]})')
        return 0

    if not BASELINE.is_file():
        print(f'ECHEC: aucune empreinte. Lance d abord --build.')
        return 1

    ref = json.loads(BASELINE.read_text(encoding='utf-8'))
    known = {(h['hook'], h['address']): h['preimage'] for h in ref['hooks']}
    failures, new = [], []
    for h in resolved:
        key = (h['hook'], h['address'])
        if key not in known:
            new.append(h)
            continue
        if known[key] != h['preimage']:
            failures.append((h, known[key]))

    for h, want in failures:
        print(f'ECHEC {h["hook"]} 0x{h["address"]:X} ({h["file"]}:{h["line"]})')
        print(f'      empreinte enregistrée {want}')
        print(f'      lue                   {h["preimage"]}')
    for h in new:
        print(f'AVERT {h["hook"]} 0x{h["address"]:X} — point de hook nouveau, '
              f'absent de l empreinte ({h["file"]}:{h["line"]})')

    print()
    if failures:
        print(f'{len(failures)} divergence(s). Un offset a changé, ou le binaire '
              f'n est pas celui de référence.')
        return 1
    print(f'Les {len(resolved)} points de hook concordent avec l empreinte'
          + (f' ({len(new)} nouveau(x) à enregistrer).' if new else '.'))
    return 0


if __name__ == '__main__':
    sys.exit(main())
