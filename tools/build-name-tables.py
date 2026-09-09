#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Extrait les tables de NOMS du jeu et produit les CSV que le generateur attend.

Ce que ca repare
----------------
Quatre fichiers de donnees manquaient depuis toujours, et le manifeste du
generateur (`$DataFileManifest`) decrit leur absence : les rapports affichent
« Species 425 » au lieu d'un nom, et la recherche par nom dans l'interface ne
trouve rien. Ils etaient attendus d'une source EXTERNE.

Ce script les derive du dump de l'utilisateur. Le jeu porte ses propres noms,
dans toutes ses langues : il n'y a aucune raison d'aller les chercher ailleurs,
et ceux-la sont exacts pour SA version.

  ATTENTION : les fichiers produits sont DERIVES DU JEU. Ne pas les publier ni
  les versionner - meme regle que `items.csv` et `npc-gifts.csv`.

Format, ETABLI PAR MESURE
--------------------------
`bin/message/<Langue>/common/<table>.dat` :

    u16 nombre de sections        (1)
    u16 nombre de lignes          itemname 1608, monsname 899, wazaname 827
    u32 longueur totale
    i32 cle initiale              (0)
    u32 decalage de la section    (0x10)
    puis, a ce decalage :
      u32 longueur de la section
      N x (u32 decalage, u16 longueur, u16 drapeaux)   -- 8 octets par ligne
      les chaines, en UTF-16LE CHIFFRE

Le decalage de chaque chaine est relatif au debut de la section.

Chiffrement, un par ligne : cle = 0x7C89 + n*0x2983 ; chaque caractere est
XORe avec la cle, puis la cle tourne de 3 bits vers la gauche sur 16 bits.

Temoins concordants - ancres tirees de la table CT/DT du jeu lui-meme et de la
table Pokemon, pas d'une documentation :

    objet 1230 -> TM00 / CT00        objet 1130 -> TR00 / DT00
    objet  328 -> TM01 / CT01        objet 1229 -> TR99 / DT99
    objet  236 -> Light Ball / Balle Lumiere   (Pikachu, docs/offsets)

Le script REFUSE d'ecrire si un temoin ne concorde pas : une table de noms
fausse serait pire que pas de table, parce qu'elle aurait l'air juste.

Usage
-----
    python tools/build-name-tables.py "<chemin-romfs>"
    python tools/build-name-tables.py "<chemin-romfs>" --verifier
"""
from __future__ import annotations

import argparse
import csv
import struct
import sys
from pathlib import Path

# Identifiants de langue attendus par le generateur (voir $FrenchLanguageId).
LANGUES = {'French': 5, 'English': 9}

# table du jeu -> (fichier CSV, nom de la colonne d'identifiant)
TABLES = {
    'itemname':  ('item_names.csv', 'item_id'),
    'monsname':  ('pokemon_species_names.csv', 'pokemon_species_id'),
    'wazaname':  ('move_names.csv', 'move_id'),
    'tokusei':   ('ability_names.csv', 'ability_id'),
}

# Ancres verifiees dans le jeu : table CT/DT (item.dat) et docs/offsets.
TEMOINS = {
    'itemname': {1230: ('TM00', 'CT00'), 328: ('TM01', 'CT01'),
                 1130: ('TR00', 'DT00'), 1229: ('TR99', 'DT99'),
                 236: ('Light Ball', 'Balle Lumière')},
    'monsname': {1: ('Bulbasaur', 'Bulbizarre'), 25: ('Pikachu', 'Pikachu'),
                 890: ('Eternatus', 'Éthernatos')},
    # « Danse Lames » SANS trait d'union : c'est l'orthographe du jeu.
    # docs/offsets/swsh-1.3.2-epee.md l'ecrit avec, en prose. Le temoin a
    # attrape ma faute de frappe, pas un defaut de decodage - les onze autres
    # ancres concordaient deja, accents compris.
    'wazaname': {14: ('Swords Dance', 'Danse Lames'), 34: ('Body Slam', 'Plaquage'),
                 53: ('Flamethrower', 'Lance-Flammes'), 56: ('Hydro Pump', 'Hydrocanon')},
}


def decoder(chemin: Path):
    """Rend la liste des chaines d'un fichier de texte du jeu."""
    d = chemin.read_bytes()
    if len(d) < 0x14:
        raise SystemExit('ECHEC: %s trop court' % chemin)
    _sections, lignes = struct.unpack_from('<HH', d, 0)
    sec_off = struct.unpack_from('<I', d, 12)[0]
    out = []
    for i in range(lignes):
        off, ln, _flags = struct.unpack_from('<IHH', d, sec_off + 4 + i * 8)
        debut = sec_off + off
        cle = (0x7C89 + i * 0x2983) & 0xFFFF
        chars = []
        for k in range(ln):
            v = struct.unpack_from('<H', d, debut + k * 2)[0] ^ cle
            cle = ((cle << 3) | (cle >> 13)) & 0xFFFF
            if v == 0:
                break
            chars.append(v)
        out.append(''.join(chr(c) for c in chars))
    return out


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('romfs')
    ap.add_argument('--verifier', action='store_true',
                    help='tout mesurer et controler, mais n ecrire aucun fichier')
    args = ap.parse_args()

    projet = Path(__file__).resolve().parents[1]
    racine = Path(args.romfs) / 'bin' / 'message'
    if not racine.is_dir():
        print('ECHEC: %s introuvable' % racine)
        return 1

    tout = {}
    for table in TABLES:
        par_langue = {}
        for langue in LANGUES:
            f = racine / langue / 'common' / (table + '.dat')
            if not f.is_file():
                continue
            par_langue[langue] = decoder(f)
        if par_langue:
            tout[table] = par_langue

    # --- Temoin avant mesure ------------------------------------------------
    print('temoins :')
    faux = []
    for table, ancres in TEMOINS.items():
        if table not in tout:
            continue
        for ident, (en, fr) in sorted(ancres.items()):
            lu_en = tout[table].get('English', [])[ident:ident + 1]
            lu_fr = tout[table].get('French', [])[ident:ident + 1]
            lu_en = lu_en[0] if lu_en else ''
            lu_fr = lu_fr[0] if lu_fr else ''
            ok = (lu_en == en and lu_fr == fr)
            print('  %-5s %-9s %-5d  %-14s / %-16s  %s'
                  % ('OK' if ok else 'ECHEC', table, ident, lu_en, lu_fr,
                     '' if ok else ('attendu %s / %s' % (en, fr))))
            if not ok:
                faux.append('%s[%d]' % (table, ident))
    if faux:
        print('\nECHEC: %d temoin(s) discordant(s) : %s' % (len(faux), ', '.join(faux)))
        print('Le chiffrement ou la disposition a change. Rien n a ete ecrit.')
        return 1

    print('\ntables lues :')
    for table, par_langue in sorted(tout.items()):
        n = max(len(v) for v in par_langue.values())
        print('  %-10s %5d entrees   langues : %s'
              % (table, n, ', '.join(sorted(par_langue))))

    if args.verifier:
        print('\nOK  : tous les temoins concordent. Rien n a ete ecrit (--verifier).')
        return 0

    print()
    for table, (nom_csv, colonne) in TABLES.items():
        if table not in tout:
            print('  ignore  %-28s (table absente du dump)' % nom_csv)
            continue
        lignes = []
        for langue, code in LANGUES.items():
            noms = tout[table].get(langue)
            if not noms:
                continue
            for ident, nom in enumerate(noms):
                if not nom:
                    continue
                lignes.append({colonne: ident, 'local_language_id': code, 'name': nom})
        cible = projet / nom_csv
        with cible.open('w', encoding='utf-8', newline='') as fh:
            w = csv.DictWriter(fh, fieldnames=[colonne, 'local_language_id', 'name'])
            w.writeheader()
            w.writerows(lignes)
        print('  ecrit   %-28s %5d lignes' % (nom_csv, len(lignes)))

    print('\n      Ces fichiers sont DERIVES DU JEU : ne pas les publier ni les versionner.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
