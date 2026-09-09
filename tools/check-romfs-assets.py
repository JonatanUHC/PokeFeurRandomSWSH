#!/usr/bin/env python3
"""Valide la seconde moitié du contrat : les ressources ROMFS.

Pourquoi cet outil existe
-------------------------
`check-config-contract.py` garantit qu'une clé écrite est lue et réciproquement.
Il ne dit rien de ce qui se passe *ensuite*. Or activer une fonctionnalité ne
suffit pas :

1. son ou ses fichiers doivent être **copiés** dans le ROMFS de sortie ;
2. ses scripts doivent être **enregistrés** dans `script_id_record.bin`, sinon
   le jeu ne les exécute jamais ;
3. tout fichier listé dans `$allRuntimeFiles` sans être copié par une porte est
   **activement supprimé** de la sortie.

`dex_animations` échouait sur les trois. `config.toml` était muet, le `.amx`
était effacé par la boucle de nettoyage, et l'entrée `dex_dialog` manquait — et
aucun outil du projet ne pouvait le voir. ADR-001 nommait explicitement ce trou
comme limite connue.

Ce validateur lit le PowerShell **réel** (pas une description de ce qu'il est
censé faire) et le confronte au bloc `romfsAssets` du schéma.

Usage
-----
    python tools/check-romfs-assets.py            # échoue sur tout écart
    python tools/check-romfs-assets.py --list     # affiche ce qui a été analysé

Code de sortie 1 = divergence.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCHEMA = ROOT / 'contract' / 'runtime-config.schema.json'
PS1 = ROOT / 'CustomSwShRandomizer.ps1'

FNV_BASIS = 0xCBF29CE484222645
FNV_PRIME = 0x100000001B3
MASK = 0xFFFFFFFFFFFFFFFF


def fnv1a64(text: str) -> int:
    """FNV-1a 64 bits, base GameFreak. Même fonction que Fnv1a64 du PS1."""
    h = FNV_BASIS
    for byte in text.encode('utf-8'):
        h ^= byte
        h = (h * FNV_PRIME) & MASK
    return h


def normalise(path: str) -> str:
    """Les deux couches n'écrivent pas les séparateurs pareil.

    La liste de copie utilise des antislashs Windows (`bin\\script\\amx\\x.amx`),
    l'enregistrement de script des slashs (`bin/script/amx/x.amx`). Comparer les
    deux tels quels ferait passer une divergence pour une égalité, ou l'inverse.
    """
    return path.replace('\\', '/').strip().lower()


# --- Analyse du PowerShell -------------------------------------------------

def extract_block(text: str, start_pattern: str, end_pattern: str) -> str:
    """Isole une région du monolithe entre deux ancres, la première fois.

    Le fichier fait 17 000 lignes : chercher un motif dans tout le texte capture
    des occurrences sans rapport. On borne d'abord, on cherche ensuite.
    """
    start = re.search(start_pattern, text)
    if not start:
        raise SystemExit(f'ancre introuvable dans le PS1 : {start_pattern}')
    rest = text[start.end():]
    end = re.search(end_pattern, rest)
    if not end:
        raise SystemExit(f'fin de bloc introuvable : {end_pattern}')
    return rest[:end.start()]


def parse_copy_function(text: str) -> tuple[list[str], dict[str, list[str]]]:
    """Renvoie (liste de nettoyage, {porte: [fichiers copiés]}).

    On lit la fonction réelle, pas une liste maintenue à part.
    """
    body = extract_block(
        text,
        r'function Copy-ExLaunchCustomRomfsFiles \{',
        r'\n    \$sourceScriptRecordPath')

    cleanup_src = re.search(r'\$allRuntimeFiles = @\((.*?)\n    \)', body, re.S)
    if not cleanup_src:
        raise SystemExit('$allRuntimeFiles introuvable dans Copy-ExLaunchCustomRomfsFiles')
    cleanup = re.findall(r'"([^"]+)"', cleanup_src.group(1))

    gates: dict[str, list[str]] = {}
    for gate, block in re.findall(
            r'if \(\$(\w+)\) \{\s*(.*?)\s*\}', body, re.S):
        files = re.findall(r'\$relativeFiles\.Add\("([^"]+)"\)', block)
        if files:
            gates.setdefault(gate, []).extend(files)

    # Fichiers copiés sans condition : ils comptent comme une porte "toujours".
    unconditional = re.findall(
        r'^\s*\$relativeFiles\.Add\("([^"]+)"\)', body, re.M)
    inside = {f for files in gates.values() for f in files}
    always = [f for f in unconditional if f not in inside]
    if always:
        gates['<toujours>'] = always

    return cleanup, gates


def parse_script_record(text: str) -> dict[str, list[tuple[int | str, str, str]]]:
    """Renvoie {porte C#: [(id ou nom, amx, text)]} lus dans PokeFeurScriptRecordCodec."""
    body = extract_block(
        text,
        r'public static byte\[\] Patch\(',
        r'\n        return Build\(entries\);')

    entries: dict[str, list[tuple[int | str, str, str]]] = {}
    for gate, block in re.findall(r'if \((\w+)\)\s*\{(.*?)\n        \}', body, re.S):
        for id_expr, amx, txt in re.findall(
                r'Upsert\(entries,\s*([^,]+?),\s*"([^"]+)",\s*"([^"]+)"\)', block):
            id_expr = id_expr.strip()
            named = re.match(r'Fnv1a64\("([^"]+)"\)', id_expr)
            if named:
                key: int | str = named.group(1)
            else:
                literal = re.match(r'(\d+)UL$', id_expr)
                if not literal:
                    raise SystemExit(f'expression Upsert non reconnue : {id_expr}')
                key = int(literal.group(1))
            entries.setdefault(gate, []).append((key, amx, txt))
    return entries


# --- Confrontation ---------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--list', action='store_true',
                    help='afficher ce qui a été lu dans le PowerShell')
    # Permet de valider le validateur : on lui donne une copie volontairement
    # cassée du générateur et on vérifie qu'il la refuse. Sans cette option il
    # faudrait abîmer le vrai fichier pour tester l'outil.
    ap.add_argument('--ps1', type=Path, default=PS1,
                    help='générateur à analyser (défaut : CustomSwShRandomizer.ps1)')
    ap.add_argument('--schema', type=Path, default=SCHEMA,
                    help='schéma à confronter')
    args = ap.parse_args()

    globals()['SCHEMA'] = args.schema
    globals()['PS1'] = args.ps1
    schema = json.loads(args.schema.read_text(encoding='utf-8'))
    block = schema.get('romfsAssets')
    if not block:
        print('ECHEC: le schema ne contient pas de bloc romfsAssets.')
        return 1
    features = block['features']
    asset_root = ROOT / block['assetRoot']

    text = args.ps1.read_text(encoding="utf-8")
    cleanup, copy_gates = parse_copy_function(text)
    record_gates = parse_script_record(text)

    print('Contrat ressources ROMFS — PokeFeur')
    print(f'  schema      {args.schema} : '
          f'{len(features)} fonctionnalite(s) declaree(s)')
    print(f'  generateur  liste de nettoyage : {len(cleanup)} fichier(s), '
          f'{len(copy_gates)} porte(s) de copie')
    print(f'  generateur  enregistrement de script : '
          f'{sum(len(v) for v in record_gates.values())} entree(s) sur '
          f'{len(record_gates)} porte(s)')
    print(f'  ressources  {block["assetRoot"]}')
    print()

    if args.list:
        print('--- liste de nettoyage ($allRuntimeFiles) ---')
        for f in cleanup:
            print(f'    {f}')
        print('--- portes de copie ---')
        for gate, files in sorted(copy_gates.items()):
            for f in files:
                print(f'    {gate:28s} {f}')
        print('--- entrees d\'enregistrement ---')
        for gate, rows in sorted(record_gates.items()):
            for key, amx, txt in rows:
                shown = f'"{key}"' if isinstance(key, str) else str(key)
                print(f'    {gate:28s} {shown} -> {amx} | {txt}')
        print()

    errors: list[str] = []
    warnings: list[str] = []

    copied_all = {normalise(f) for files in copy_gates.values() for f in files}
    declared_all = {normalise(f) for feat in features.values() for f in feat['files']}

    for name, feat in sorted(features.items()):
        gate = feat.get('gate')
        status = feat.get('status', 'verified')

        for rel in feat['files']:
            key = normalise(rel)

            # 1. La ressource existe-t-elle vraiment sur le disque ?
            if not (asset_root / rel).exists():
                errors.append(
                    f'[{name}] {rel} : declare mais ABSENT de {block["assetRoot"]}. '
                    f'La generation echouerait sur "ExLaunch runtime files missing".')

            if status == 'unreachable':
                if key in copied_all:
                    errors.append(
                        f'[{name}] {rel} : le schema le dit inatteignable, mais le '
                        f'generateur le copie. Mets a jour le schema ou la porte.')
                continue

            # 2. Une porte le copie-t-elle, et est-ce la bonne ?
            gates_copying = [g for g, files in copy_gates.items()
                             if key in {normalise(x) for x in files}]
            if not gates_copying:
                errors.append(
                    f'[{name}] {rel} : AUCUNE porte ne le copie. '
                    f'{"Il figure en plus dans la liste de nettoyage, donc il est " if key in {normalise(c) for c in cleanup} else ""}'
                    f'{"activement supprime de la sortie." if key in {normalise(c) for c in cleanup} else "Il ne sera jamais present."}')
            elif gate and gate not in gates_copying:
                errors.append(
                    f'[{name}] {rel} : copie sous la porte {gates_copying} alors que '
                    f'le schema declare {gate}.')

        # 3. Les entrees d'enregistrement declarees existent-elles ?
        for row in feat.get('scriptRecord', []):
            expected_id = row['scriptId']
            found = None
            found_gate = None
            for g, rows in record_gates.items():
                for key, amx, txt in rows:
                    actual_id = fnv1a64(key) if isinstance(key, str) else key
                    if actual_id == expected_id:
                        found = (key, amx, txt)
                        found_gate = g
            if not found:
                errors.append(
                    f'[{name}] entree d\'enregistrement {expected_id} '
                    f'({row.get("name") or "sans nom"}) : ABSENTE du codec. '
                    f'Le script ne sera jamais execute par le jeu.')
                continue

            key, amx, txt = found
            if isinstance(key, str) and row.get('name') and key != row['name']:
                errors.append(
                    f'[{name}] entree {expected_id} : le codec utilise le nom '
                    f'"{key}", le schema declare "{row["name"]}".')
            if isinstance(key, str) and fnv1a64(key) != expected_id:
                errors.append(
                    f'[{name}] "{key}" : hash FNV-1a {fnv1a64(key)} != '
                    f'{expected_id} declare.')
            if normalise(amx) != normalise(row['amx']):
                errors.append(
                    f'[{name}] entree {expected_id} : pointe sur {amx}, '
                    f'le schema declare {row["amx"]}.')
            if normalise(txt) != normalise(row['text']):
                errors.append(
                    f'[{name}] entree {expected_id} : texte {txt}, '
                    f'le schema declare {row["text"]}.')
            # La porte C# est declaree separement : elle ne porte pas le meme nom
            # que la porte PowerShell (runtimePcControls / RuntimePcControlsEnabled).
            cs_gate = feat.get('csharpGate')
            if cs_gate and found_gate and found_gate != cs_gate:
                errors.append(
                    f'[{name}] entree {expected_id} enregistree sous la porte C# '
                    f'"{found_gate}", le schema declare "{cs_gate}".')

            # Un script enregistre sans que son .amx soit copie ne fait rien.
            if normalise(amx) not in declared_all:
                errors.append(
                    f'[{name}] entree {expected_id} pointe sur {amx}, qui n\'est '
                    f'declare dans aucune fonctionnalite du schema.')

    # 4. Un fichier de la liste de nettoyage que personne ne copie est efface.
    for rel in cleanup:
        key = normalise(rel)
        if key in copied_all:
            continue
        owner = [n for n, f in features.items()
                 if key in {normalise(x) for x in f['files']}]
        if not owner:
            errors.append(
                f'[nettoyage] {rel} : supprime de la sortie et absent du schema. '
                f'Declare-le (status "unreachable" si c\'est voulu).')
        elif features[owner[0]].get('status') != 'unreachable':
            errors.append(
                f'[{owner[0]}] {rel} : dans la liste de nettoyage, copie par '
                f'aucune porte, et le schema ne le dit pas inatteignable.')
        else:
            warnings.append(
                f'[{owner[0]}] {rel} : supprime de la sortie a chaque generation '
                f'(declare inatteignable).')

    # 5. Rien ne doit etre enregistre sans etre declare.
    declared_ids = {row['scriptId']
                    for feat in features.values()
                    for row in feat.get('scriptRecord', [])}
    for g, rows in record_gates.items():
        for key, amx, txt in rows:
            actual = fnv1a64(key) if isinstance(key, str) else key
            if actual not in declared_ids:
                errors.append(
                    f'[{g}] entree {actual} -> {amx} : enregistree par le codec '
                    f'mais ABSENTE du schema.')

    for w in warnings:
        print(f'AVERT: {w}')
    if warnings:
        print()
    for e in errors:
        print(f'ECHEC: {e}')

    if errors:
        print(f'\n{len(errors)} divergence(s), {len(warnings)} avertissement(s).')
        return 1

    print(f'OK  : ressources ROMFS conformes ({len(features)} fonctionnalites, '
          f'{len(warnings)} avertissement(s)).')
    return 0


if __name__ == '__main__':
    sys.exit(main())
