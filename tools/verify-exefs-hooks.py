#!/usr/bin/env python3
"""Vérifie les points de hook du module runtime contre l'ExeFS réel.

Le module `subsdk9` installe ses correctifs à des offsets codés en dur dans
`symbols.hpp` et les `patches/*.hpp`. Rien ne vérifie aujourd'hui que ces
offsets pointent bien sur les instructions attendues : si un offset est faux,
le hook écrase du code vivant et le jeu plante de façon différée et trompeuse
(COMBAT-CACHE §4 documente trois adresses réfutées et le temps perdu).

Ce script décompresse le segment `.text` du NSO principal et compare les octets
présents aux préimages attendues. C'est le garde-fou par signature
d'instruction que le projet applique déjà ailleurs (`0xB9402A60`), généralisé.

Portée : Épée 1.3.2. Bouclier n'est pas couvert — VER_OFF n'est pas appliqué ici.

Usage
-----
    python tools/verify-exefs-hooks.py <chemin-exefs>
    python tools/verify-exefs-hooks.py "C:/Users/.../sword/exefs"
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

try:
    import lz4.block
except ImportError:
    print('ECHEC: le module python "lz4" est requis (pip install lz4).')
    sys.exit(1)

# Identite attendue du binaire, d'apres le profil KM-Editor
# research/KM-Editor/native/km-native-settings/profiles/swsh-1.3.2.json
EXPECTED_TEXT_LENGTH_SWORD = 26218288

# Preimages attendues : offset dans .text -> (octets attendus, description, source)
# Les valeurs sont en hexadecimal, telles qu'elles apparaissent dans les sources.
PREIMAGES = {
    0x1464FC0: (
        'F30F1EF8FD7B01A9FD430091F30300AA88310094',
        "hook d'enregistrement des natives AMX (Epee)",
        'KM swsh-1.3.2.json registrationPreimage ; PokeFeur amx_handler.hpp:92 '
        'installe a 0x1464ff0 - VER_OFF',
    ),
    0x7FB2C0: (
        'E0030032',
        'fonction de requete du partage d EXP',
        'KM swsh-1.3.2.json gameplayApply.experienceShare.retailInstruction',
    ),
    0x8A564C: (
        'E80340B9',
        'calcul du taux d EXP',
        'KM swsh-1.3.2.json gameplayApply.experienceRate.retailInstruction',
    ),
    0x83A3E0: (
        'F50F1DF8',
        'plafond de niveau',
        'KM swsh-1.3.2.json gameplayApply.levelCap.retailInstruction',
    ),
    0x66CBA0: (
        '008001910200801272030014',
        'enregistreur de tableau natif',
        'KM swsh-1.3.2.json sharedWindows[native-array-registrar]',
    ),
}


def read_nso_text(path: Path) -> tuple[bytes, dict]:
    """Decompresse le segment .text d'un NSO0 et renvoie (texte, en-tete)."""
    raw = path.read_bytes()
    if raw[:4] != b'NSO0':
        raise SystemExit(f'ECHEC: {path.name} n est pas un NSO0 '
                         f'(magie {raw[:4]!r}).')

    flags = struct.unpack_from('<I', raw, 0x0C)[0]
    text_file_off, text_mem_off, text_dec_size = struct.unpack_from('<III', raw, 0x10)
    text_file_size = struct.unpack_from('<I', raw, 0x60)[0]

    hdr = {
        'flags': flags,
        'text_file_offset': text_file_off,
        'text_memory_offset': text_mem_off,
        'text_decompressed_size': text_dec_size,
        'text_file_size': text_file_size,
        'text_compressed': bool(flags & 1),
    }

    blob = raw[text_file_off:text_file_off + text_file_size]
    if hdr['text_compressed']:
        text = lz4.block.decompress(blob, uncompressed_size=text_dec_size)
    else:
        text = blob

    if len(text) != text_dec_size:
        raise SystemExit(f'ECHEC: .text decompresse fait {len(text)} octets, '
                         f'l en-tete en annonce {text_dec_size}.')
    return text, hdr


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('exefs', help='dossier exefs contenant "main"')
    args = ap.parse_args()

    root = Path(args.exefs)
    main_nso = root / 'main'
    if not main_nso.is_file():
        print(f'ECHEC: {main_nso} introuvable.')
        return 1

    print('Vérification des points de hook — Épée 1.3.2')
    print(f'binaire : {main_nso}')

    text, hdr = read_nso_text(main_nso)
    print(f'  .text : {len(text)} octets décompressés '
          f'(compressé : {hdr["text_compressed"]}, '
          f'{hdr["text_file_size"]} octets sur disque)')

    failures = []

    # Temoin : l identite du binaire avant toute lecture d offset.
    ok = len(text) == EXPECTED_TEXT_LENGTH_SWORD
    print(f'  {"OK   " if ok else "ECHEC"} témoin : taille de .text '
          f'attendue {EXPECTED_TEXT_LENGTH_SWORD}, lue {len(text)}')
    if not ok:
        print('  -> binaire différent de celui attendu. '
              'Les offsets ci-dessous ne veulent rien dire.')
        return 1

    print('\n  -- préimages --')
    for off, (hexpat, label, source) in sorted(PREIMAGES.items()):
        want = bytes.fromhex(hexpat)
        if off + len(want) > len(text):
            print(f'  ECHEC 0x{off:X} {label} — hors du segment')
            failures.append(off)
            continue
        got = text[off:off + len(want)]
        good = got == want
        print(f'  {"OK   " if good else "ECHEC"} 0x{off:X}  {label}')
        print(f'        attendu {want.hex().upper()}')
        print(f'        lu      {got.hex().upper()}')
        if not good:
            failures.append(off)
        print(f'        source : {source}')

    print()
    if failures:
        print(f'{len(failures)} préimage(s) discordante(s) : '
              + ', '.join(f'0x{o:X}' for o in failures))
        return 1
    print('Toutes les préimages concordent avec le binaire.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
