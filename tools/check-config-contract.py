#!/usr/bin/env python3
"""Valide le contrat config.toml entre le generateur PowerShell et le module runtime.

Pourquoi cet outil existe
-------------------------
Les deux couches de PokeFeur ne partagent aucun code. Le generateur PowerShell
ecrit config.toml ; le module C++ le relit avec `.value_or(defaut)`. Une cle
absente, mal orthographiee ou renommee d'un seul cote ne produit AUCUNE erreur :
le module prend simplement le defaut et la fonctionnalite se tait.

Trois defauts reels sont passes par cette faille :
  * [dex_animations] active  : lu par le module, jamais ecrit -> correctif inerte
  * [runtime_pc] active      : ecrit, lu par personne -> reglage sans effet
  * 14 cles                  : lues, jamais ecrites -> options sans interface

Ce script compare les DEUX implementations reelles au contrat declare dans
contract/runtime-config.schema.json et echoue si elles divergent.

Usage
-----
    python tools/check-config-contract.py            # valide, code de sortie 1 si echec
    python tools/check-config-contract.py --list     # affiche le contrat resolu
    python tools/check-config-contract.py --baseline # tolere les ecarts deja connus

Le mode --baseline sert pendant la transition : il n'echoue que sur les NOUVEAUX
ecarts, pas sur ceux que le schema documente deja (status unreachable / dead).
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCHEMA = ROOT / 'contract' / 'runtime-config.schema.json'
CPP = ROOT / 'research' / 'swsh-mods-exl' / 'source' / 'program' / 'config.hpp'
PS1 = ROOT / 'CustomSwShRandomizer.ps1'

OK, FAIL, WARN = 'OK  ', 'ECHEC', 'AVERT'


# --------------------------------------------------------------------------- lecture C++
def parse_cpp(text: str) -> dict[tuple[str, str], str | None]:
    """(section, cle) -> defaut litteral, tel que le module le lit reellement."""
    found: dict[tuple[str, str], str | None] = {}

    # table["section"]["cle"].value_or(defaut)
    for m in re.finditer(
        r'table\["([a-z_0-9]+)"\]\["([a-z_0-9]+)"\]\s*\.value_or\(\s*(.*?)\s*\)\s*;',
        text, re.S,
    ):
        found[(m.group(1), m.group(2))] = m.group(3)

    # formes tableau : load_species_array(table["s"]["k"], ...) et .as_array()
    for m in re.finditer(
        r'(?:load_species_array\(\s*)?table\["([a-z_0-9]+)"\]\["([a-z_0-9]+)"\]'
        r'(?:\s*,|\s*\.as_array\(\))',
        text,
    ):
        found.setdefault((m.group(1), m.group(2)), None)

    return found


# --------------------------------------------------------------- lecture PowerShell
def parse_ps1(text: str) -> tuple[set[tuple[str, str]], int, int]:
    """(section, cle) ecrites par le gabarit config.toml, + ses bornes de lignes.

    On isole le here-string de Write-ExpLevelCapExLaunchConfig au lieu de scanner
    tout le script : sans cette delimitation, un en-tete [section] capture chaque
    ligne `cle =` des 17 000 lignes suivantes et le resultat est du bruit.
    """
    lines = text.splitlines()

    fn = next((i for i, l in enumerate(lines)
               if l.startswith('function Write-ExpLevelCapExLaunchConfig')), None)
    if fn is None:
        raise SystemExit('ECHEC: fonction Write-ExpLevelCapExLaunchConfig introuvable '
                         'dans CustomSwShRandomizer.ps1 (a-t-elle ete renommee ?)')

    start = next((i for i in range(fn, len(lines))
                  if re.match(r'^\s*\[[a-z_0-9]+\]\s*$', lines[i])), None)
    if start is None:
        raise SystemExit('ECHEC: aucun en-tete de section TOML apres '
                         'Write-ExpLevelCapExLaunchConfig')

    end = next((i for i in range(start, len(lines)) if lines[i].strip() == '"@'), None)
    if end is None:
        raise SystemExit('ECHEC: fin de here-string ("@) introuvable apres le gabarit')

    written: set[tuple[str, str]] = set()
    section = None
    for line in lines[start:end]:
        s = line.strip()
        m = re.match(r'^\[([a-z_0-9]+)\]$', s)
        if m:
            section = m.group(1)
            continue
        m = re.match(r'^([a-z_][a-z_0-9]*)\s*=', s)
        if m and section:
            written.add((section, m.group(1)))
    return written, start + 1, end


# ------------------------------------------------------------------------ schema
def load_schema() -> tuple[dict[tuple[str, str], dict], dict]:
    raw = json.loads(SCHEMA.read_text(encoding='utf-8'))
    flat: dict[tuple[str, str], dict] = {}
    for sec, body in raw['sections'].items():
        for key, spec in body['keys'].items():
            flat[(sec, key)] = spec | {'_section': sec, '_feature': body.get('feature', '')}
    return flat, raw


# ------------------------------------------------------------------- comparaison
def norm_default(raw: str | None):
    """Normalise un litteral C++ pour le comparer au JSON du schema."""
    if raw is None:
        return None
    # Les suffixes C++ se cumulent (1.0f, 0x...ULL, 12u) : il faut les retirer
    # tous d'un coup. Un rstrip chaine laisse le 'U' de 'ULL' et casse int(v, 16).
    v = raw.strip().rstrip('fFuUlL')
    if v in ('true', 'false'):
        return v == 'true'
    if v.startswith('"') and v.endswith('"'):
        return v[1:-1]
    if v.startswith('0x'):
        try:
            return int(v, 16)
        except ValueError:
            return raw
    try:
        return int(v)
    except ValueError:
        pass
    try:
        return float(v)
    except ValueError:
        return raw


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--list', action='store_true', help='afficher le contrat resolu')
    ap.add_argument('--baseline', action='store_true',
                    help='ne signaler que les ecarts NON documentes par le schema')
    args = ap.parse_args()

    for p in (SCHEMA, CPP, PS1):
        if not p.exists():
            print(f'{FAIL}: fichier introuvable : {p}')
            return 1

    schema, raw_schema = load_schema()
    cpp_reads = parse_cpp(CPP.read_text(encoding='utf-8', errors='replace'))
    ps1_writes, tpl_start, tpl_end = parse_ps1(PS1.read_text(encoding='utf-8',
                                                             errors='replace'))

    print('Contrat config.toml — PokeFeur')
    print(f'  schema    {SCHEMA.relative_to(ROOT)} : {len(schema)} cles declarees')
    print(f'  runtime   {CPP.relative_to(ROOT)} : {len(cpp_reads)} cles lues')
    print(f'  generateur {PS1.name} lignes {tpl_start}-{tpl_end} : '
          f'{len(ps1_writes)} cles ecrites')
    print()

    if args.list:
        for (sec, key), spec in sorted(schema.items()):
            flags = ''.join(('R' if spec.get('read') else '-',
                             'W' if spec.get('written') else '-',
                             'U' if spec.get('ui') else '-'))
            print(f'  [{flags}] {spec["status"]:<12} [{sec}] {key}')
        return 0

    errors: list[str] = []
    warnings: list[str] = []

    # 1. le module lit une cle absente du schema
    for k in sorted(set(cpp_reads) - set(schema)):
        errors.append(f'[{k[0]}] {k[1]} : lue par le module mais ABSENTE du schema. '
                      f'Ajoute-la a contract/runtime-config.schema.json.')

    # 2. le schema declare une lecture que le module ne fait pas
    for k, spec in sorted(schema.items()):
        if spec.get('read') and k not in cpp_reads:
            errors.append(f'[{k[0]}] {k[1]} : le schema la dit lue, mais config.hpp '
                          f'ne la lit pas. Cle renommee ou supprimee cote C++ ?')

    # 3. le schema declare une ecriture que le generateur ne fait pas
    for k, spec in sorted(schema.items()):
        if spec.get('written') and k not in ps1_writes:
            errors.append(f'[{k[0]}] {k[1]} : le schema la dit ecrite, mais le gabarit '
                          f'ne l ecrit pas -> le module prendra le defaut EN SILENCE.')

    # 4. le generateur ecrit une cle que personne ne lit
    for k in sorted(ps1_writes - set(cpp_reads)):
        spec = schema.get(k)
        msg = (f'[{k[0]}] {k[1]} : ecrite par le generateur, lue par AUCUNE source C++ '
               f'-> reglage sans effet.')
        if spec and spec.get('status') == 'dead' and args.baseline:
            warnings.append(msg + ' (ecart connu, documente dans le schema)')
        else:
            errors.append(msg)

    # 5. defauts divergents entre le C++ et le schema
    for k, spec in sorted(schema.items()):
        if k not in cpp_reads or cpp_reads[k] is None or 'default' not in spec:
            continue
        got, want = norm_default(cpp_reads[k]), spec['default']
        if isinstance(got, float) or isinstance(want, float):
            same = got is not None and want is not None and abs(float(got) - float(want)) < 1e-6
        else:
            same = got == want
        if not same:
            errors.append(f'[{k[0]}] {k[1]} : defaut divergent — config.hpp dit '
                          f'{got!r}, le schema dit {want!r}.')

    # 6. options lues mais sans interface (avertissement, pas erreur)
    for k, spec in sorted(schema.items()):
        if spec.get('read') and not spec.get('written') and spec.get('status') == 'unreachable':
            warnings.append(f'[{k[0]}] {k[1]} : option du module SANS INTERFACE '
                            f'(figee sur {spec.get("default")!r}).')

    for w in warnings:
        print(f'{WARN}: {w}')
    if warnings:
        print()

    if errors:
        for e in errors:
            print(f'{FAIL}: {e}')
        print()
        print(f'{len(errors)} divergence(s) de contrat, {len(warnings)} avertissement(s).')
        return 1

    print(f'{OK}: les deux couches respectent le contrat '
          f'({len(schema)} cles, {len(warnings)} avertissement(s)).')
    return 0


if __name__ == '__main__':
    sys.exit(main())
