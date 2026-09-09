#!/usr/bin/env python3
"""Restaure les accents des chaînes françaises de l'interface.

Pourquoi c'était nécessaire
---------------------------
Le générateur n'a jamais eu de BOM UTF-8. PowerShell 5.1 lit alors le `.ps1`
en ANSI, et tout caractère accentué devient illisible. L'auteur avait donc
retiré **tous** les accents : « Reglages », « peche », « Metamorph »,
« Generation ». Le BOM est désormais posé (`tools/sync-ui-library.py`), les
accents sont possibles, et cet outil rattrape la dette.

Trois garde-fous, parce que la classe de défaut dominante du projet est le
changement silencieux :

1. **Seules les chaînes détectées comme françaises** sont touchées, par mots
   outils (le, la, des, pour…). L'anglais n'est jamais modifié.
2. **Remplacement par mot entier.** `espece` devient `espèce`, mais
   `slot_par_espece` reste intact : le tiret bas est un caractère de mot, donc
   il n'y a pas de frontière là où il ne faut pas.
3. **La bibliothèque C# embarquée est exclue** par plage de lignes.

Vérifié avant d'écrire : aucune chaîne française n'est utilisée comme valeur
comparée (les listes déroulantes séparent `-Label` de `-Value`), donc accentuer
un libellé ne peut pas changer un comportement.

Usage :
    python tools/apply-ui-accents.py            # applique
    python tools/apply-ui-accents.py --dry-run  # montre sans ecrire
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PS1 = ROOT / 'CustomSwShRandomizer.ps1'
# Les DEUX fichiers du generateur depuis le decoupage. N'en traiter qu'un
# laisserait 475 chaines francaises sans surveillance, sans aucune erreur.
SOURCES = [PS1, ROOT / 'src' / 'Interface.ps1']
EXTRACT = Path(__file__).resolve().parent / 'extract-ui-strings.py'

# On reutilise la table et le detecteur de l'extracteur plutot que d'en tenir
# deux copies : une divergence entre les deux serait invisible. Le module a un
# tiret dans son nom, donc pas d'import possible : on l'execute, en lui donnant
# __file__ dont il se sert pour retrouver la racine du projet.
_ns: dict = {'__name__': '_extract', '__file__': str(EXTRACT)}
exec(compile(EXTRACT.read_text(encoding='utf-8'), str(EXTRACT), 'exec'), _ns)
ACCENTS = _ns['ACCENTS']
is_french = _ns['is_french']
TECHNICAL = _ns['TECHNICAL']
SINGLE_TOKEN = _ns['SINGLE_TOKEN']

BEGIN = '# <PfControlLibrary>'
END = '# </PfControlLibrary>'

PATTERNS = [(re.compile(r'\b%s\b' % re.escape(k)), v) for k, v in ACCENTS.items()]


def accentuate(value: str) -> str:
    for rx, repl in PATTERNS:
        value = rx.sub(repl, value)
    return value


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--dry-run', action='store_true')
    args = ap.parse_args()

    presents = [q for q in SOURCES if q.is_file()]
    if not presents:
        print('ECHEC: aucun fichier source trouve.')
        return 1
    for source in presents:
        traiter(source, args.dry_run)
    return 0


def traiter(source, dry_run: bool) -> int:
    """Traite UNE source. Depuis le decoupage du monolithe, les reperes de ce
    script - bornes de la bibliotheque C#, bloc francais de Get-UiStrings - ne
    sont plus dans le meme fichier : leur absence n'est donc plus une erreur,
    seulement un contexte en moins pour ce fichier-la."""
    text = source.read_text(encoding='utf-8-sig')
    lines = text.split('\n')

    lib_start = lib_end = None
    for i, l in enumerate(lines):
        if l.startswith(BEGIN):
            lib_start = i
        elif l.startswith(END):
            lib_end = i
    # Absentes de ce fichier-la : depuis le decoupage, ce n'est plus une erreur.
    if lib_start is None or lib_end is None:
        lib_start, lib_end = -1, -2

    # Bornes du bloc francais de Get-UiStrings : il commence apres la
    # fermeture du bloc anglais et court jusqu'a la fin de la fonction.
    fr_block_start = fr_block_end = -1
    for i, l in enumerate(lines):
        if l.startswith('function Get-UiStrings'):
            depth_start = i
            for j in range(i, len(lines)):
                if lines[j].strip() == 'return @{' and not lines[j].startswith('        return'):
                    fr_block_start = j
                    break
            for j in range(fr_block_start if fr_block_start > 0 else i, len(lines)):
                if lines[j] == '}':
                    fr_block_end = j
                    break
            break
    # Idem : Get-UiStrings ne vit que dans un des deux fichiers.
    if fr_block_start < 0 or fr_block_end < 0:
        fr_block_start, fr_block_end = -1, -2

    changed = 0
    samples = []
    for i, line in enumerate(lines):
        if lib_start <= i <= lib_end:
            continue
        stripped = line.lstrip()
        if stripped.startswith('#') or stripped.startswith('//'):
            continue
        if '"' not in line:
            continue

        # Certaines zones sont francaises PAR CONSTRUCTION : on n'a pas besoin
        # d'y deviner la langue, et c'est la que vivent les libelles d'un seul
        # mot (« Generation », « Epee », « Francais ») qu'aucun mot outil ne
        # permet de reconnaitre.
        certain_fr = (
            stripped.startswith('$Ui.Descriptions.') and not line.startswith('        ')
        ) or fr_block_start <= i <= fr_block_end

        def repl(m):
            nonlocal changed
            value = m.group(1)
            if len(value) < 3 or TECHNICAL.search(value):
                return m.group(0)
            if not certain_fr:
                if SINGLE_TOKEN.match(value) or not is_french(value):
                    return m.group(0)
            new = accentuate(value)
            if new != value:
                changed += 1
                if len(samples) < 10:
                    samples.append((i + 1, value[:70], new[:70]))
                return '"%s"' % new
            return m.group(0)

        lines[i] = re.sub(r'"([^"\\]*)"', repl, line)

        # Cas particulier : « if ($isEn) { "anglais" } else { "francais" } ».
        # La moitie de droite est francaise par construction, meme si aucun mot
        # outil ne s'y trouve.
        m = re.search(r'else \{ ("(?:[^"\\]*)") \}', lines[i])
        if m:
            raw = m.group(1)[1:-1]
            if raw and not TECHNICAL.search(raw):
                fixed = accentuate(raw)
                if fixed != raw:
                    lines[i] = lines[i][:m.start(1)] + '"%s"' % fixed + lines[i][m.end(1):]
                    changed += 1

    print('Accents de l\'interface')
    print('  chaines modifiees : %d' % changed)
    for ln, old, new in samples:
        print('    L%-6d %s' % (ln, new))

    if dry_run:
        print('  (essai a blanc, rien ecrit)')
        return changed

    if changed:
        source.write_bytes(b'\xef\xbb\xbf' + '\n'.join(lines).encode('utf-8'))
        print('  ecrit, BOM UTF-8 conserve.')

    return changed


if __name__ == '__main__':
    sys.exit(main())
