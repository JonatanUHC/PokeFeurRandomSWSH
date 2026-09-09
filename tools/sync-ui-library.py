#!/usr/bin/env python3
"""Embarque `ui/PfControls.cs` dans le générateur, ou vérifie qu'il l'est.

Pourquoi cet outil existe
-------------------------
PokeFeur se distribue en **un seul `.ps1`** : la bibliothèque de contrôles doit
donc vivre à l'intérieur du monolithe. Mais éditer 950 lignes de C# à travers un
here-string PowerShell est intenable.

`ui/PfControls.cs` reste donc la source éditable, et cet outil en synchronise
une copie exacte dans le script, entre deux marqueurs. Le mode `--check` échoue
si les deux ont divergé — même logique que les deux autres contrats du projet :
on déclare une source unique, puis on valide.

Usage
-----
    python tools/sync-ui-library.py            # embarque
    python tools/sync-ui-library.py --check    # échoue (1) si divergence
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CS = ROOT / 'ui' / 'PfControls.cs'
# La bibliotheque C# embarquee a suivi l'interface dans src/Interface.ps1
# lors du decoupage du monolithe.
PS1 = ROOT / 'src' / 'Interface.ps1'

BEGIN = '# <PfControlLibrary> --- genere par tools/sync-ui-library.py, ne pas editer ici'
END = '# </PfControlLibrary>'

# Le here-string est LITTERAL (@'...'@) : sans cela PowerShell tenterait
# d'interpoler tout $ present dans le C#. Le marqueur de fin doit etre en
# colonne 0, d'ou l'absence d'indentation sur la ligne '@.
TEMPLATE = """{begin}
function Initialize-PfControlLibrary {{
    if ("PokeFeur.Ui.PfTheme" -as [type]) {{
        return
    }}

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $source = @'
{cs}
'@

    Add-Type -TypeDefinition $source -ReferencedAssemblies @("System.Windows.Forms", "System.Drawing")
}}
{end}"""


def build() -> str:
    cs = CS.read_text(encoding='utf-8')
    if "\n'@" in cs or cs.startswith("'@"):
        raise SystemExit("ui/PfControls.cs contient une ligne commencant par '@ : "
                         "elle fermerait le here-string prematurement.")
    for ch in cs:
        if ord(ch) > 0x7F and not (0xC0 <= ord(ch) <= 0x17F):
            pass
    return TEMPLATE.format(begin=BEGIN, cs=cs.rstrip('\n'), end=END)


def locate(text: str):
    if BEGIN not in text:
        return None
    a = text.index(BEGIN)
    b = text.index(END, a) + len(END)
    return a, b


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--check', action='store_true',
                    help='ne rien ecrire ; sortir 1 si le script a derive de ui/PfControls.cs')
    ap.add_argument('--anchor', default='function New-GuiFont {',
                    help='texte avant lequel inserer le bloc, a la premiere pose')
    args = ap.parse_args()

    if not CS.exists():
        print('ECHEC: %s introuvable.' % CS)
        return 1

    block = build()
    raw = PS1.read_bytes()
    bom = raw.startswith(b'\xef\xbb\xbf')
    text = raw.decode('utf-8-sig')
    span = locate(text)

    if args.check:
        if span is None:
            print("ECHEC: le generateur ne contient pas la bibliotheque. "
                  "Lance tools/sync-ui-library.py.")
            return 1
        current = text[span[0]:span[1]]
        if current != block:
            print('ECHEC: le bloc embarque a derive de ui/PfControls.cs. '
                  'Relance tools/sync-ui-library.py.')
            return 1
        if not bom:
            print("ECHEC: le generateur n'a pas de BOM UTF-8. Sans lui PowerShell 5.1 "
                  "le lit en ANSI et tous les accents sont detruits.")
            return 1
        print('OK  : bibliotheque a jour (%d lignes de C#), BOM present.'
              % len(CS.read_text(encoding='utf-8').splitlines()))
        return 0

    if span is None:
        if args.anchor not in text:
            print("ECHEC: ancre introuvable dans le generateur : %s" % args.anchor)
            return 1
        i = text.index(args.anchor)
        text = text[:i] + block + '\n\n' + text[i:]
        action = 'inseree'
    else:
        text = text[:span[0]] + block + text[span[1]:]
        action = 'mise a jour'

    # Le BOM n'est pas cosmetique : sans lui PowerShell 5.1 lit le script en
    # ANSI, et tout caractere accentue devient illisible.
    PS1.write_bytes(b'\xef\xbb\xbf' + text.encode('utf-8'))
    print('OK  : bibliotheque %s (%d lignes de C#), BOM UTF-8 %s.'
          % (action, len(CS.read_text(encoding='utf-8').splitlines()),
             'conserve' if bom else 'ajoute'))
    return 0


if __name__ == '__main__':
    sys.exit(main())
