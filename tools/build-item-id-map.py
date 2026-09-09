#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Traduit les identifiants d'objets du jeu de donnees Smogon vers ceux du JEU.

Le defaut repare
----------------
`cache/smogon-strategic-gen8.json` stocke ses objets par identifiant, et ces
identifiants viennent du dex du visualiseur (voir tools/build-smogon-dex-cache.js
ligne 267, `Object.values(localDex?.items || {})`). Or cette numerotation N'EST
PAS celle du jeu :

    Eviolite      dex 581   jeu 538
    Balle Lumiere dex 259   jeu 236

Mesure sur les trois domaines, par comparaison des noms anglais :

    attaques : 808 / 808 identifiants communs portent le meme nom  (100 %)
    talents  : 267 / 267                                            (100 %)
    objets   : 116 / 1556                                           (  7 %)

Les attaques et les talents concordent donc parfaitement ; seuls les OBJETS
divergent. En mode Smogon, le generateur ecrivait l'identifiant du dex tel quel :
le Kabuto cense tenir un Eviolite recevait l'objet 581 du jeu, qui est tout
autre chose. Le controle d'existence ajoute plus tot ne pouvait pas le voir,
puisque 581 existe bel et bien - simplement, ce n'est pas le bon objet.

La correspondance se fait par NOM ANGLAIS normalise. C'est la seule cle commune
aux deux sources, et elle est verifiable : le script imprime ses temoins et
refuse d'ecrire s'ils ne tombent pas.

  ATTENTION : fichier DERIVE DU JEU. Ne pas le publier ni le versionner.

Usage
-----
    python tools/build-item-id-map.py [--site <racine>] [--verifier]
"""
from __future__ import annotations

import argparse
import csv
import io
import json
import re
import sys
import unicodedata
from pathlib import Path

SITE_DEFAUT = r'C:/Users/Jonatan/Downloads/PokeFeur-main/PokeFeur-main'

# Temoins : (identifiant cote dex, identifiant attendu cote jeu, nom).
# Trois d'entre eux sont INDEPENDANTS des noms : cote jeu, 1230/1130/1229 ont
# ete etablis en lisant la table CT/DT de item.dat, pas une table de texte. Si
# la correspondance par nom les retrouve, c'est qu'elle relie bien les deux
# numerotations. Eviolite vient de l'observation du defaut lui-meme : le site
# affichait « Eviolite » pour l'objet 581 que la ROM avait ecrit.
TEMOINS = [
    (1288, 1230, 'TM00'),
    (1188, 1130, 'TR00'),
    (1287, 1229, 'TR99'),
    (581, 538, 'Eviolite'),
    (1, 1, 'Master Ball'),
]


def norme(s: str) -> str:
    s = unicodedata.normalize('NFKD', s or '').encode('ascii', 'ignore').decode()
    return re.sub(r'[^a-z0-9]', '', s.lower())


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--site', default=SITE_DEFAUT)
    ap.add_argument('--verifier', action='store_true')
    args = ap.parse_args()

    projet = Path(__file__).resolve().parents[1]
    f_noms = projet / 'item_names.csv'
    if not f_noms.is_file():
        print('ECHEC: item_names.csv absent. Lance d abord tools/build-name-tables.py')
        return 1

    # Cote JEU : identifiant -> nom anglais.
    jeu = {}
    for r in csv.DictReader(io.open(f_noms, encoding='utf-8')):
        if r['local_language_id'] == '9':
            jeu[int(r['item_id'])] = r['name']
    par_nom = {}
    for ident, nom in sorted(jeu.items()):
        cle = norme(nom)
        # Premier arrive gagne : les identifiants bas sont les objets reels,
        # les hauts sont souvent des variantes ou des doublons de debug.
        if cle and cle not in par_nom:
            par_nom[cle] = ident

    # Cote DEX : identifiant -> nom anglais.
    f_dex = Path(args.site) / 'assets' / 'js' / 'local-dex-data.js'
    if not f_dex.is_file():
        print('ECHEC: %s introuvable' % f_dex)
        return 1
    src = io.open(f_dex, encoding='utf-8').read()
    d = json.loads(src[src.index('{', src.index('=')):].strip().rstrip(';'))
    dex = {}
    for v in (d.get('items') or {}).values():
        if isinstance(v.get('id'), int) and v['id'] not in dex:
            dex[v['id']] = v.get('nameEn') or v.get('nameFr') or ''

    table = {}
    for ident, nom in sorted(dex.items()):
        cible = par_nom.get(norme(nom))
        if cible is not None:
            table[ident] = cible

    print('objets du jeu : %d | du dex : %d | correspondances par nom : %d'
          % (len(jeu), len(dex), len(table)))

    print('temoins :')
    faux = []
    for source, attendu, nom in TEMOINS:
        lu = table.get(source)
        ok = lu == attendu
        print('  %-5s %-14s dex %-5d -> jeu %-5s (attendu %d)'
              % ('OK' if ok else 'ECHEC', nom, source, lu, attendu))
        if not ok:
            faux.append(nom)
    if faux:
        print('\nECHEC: temoin(s) discordant(s) : %s. Rien n a ete ecrit.' % ', '.join(faux))
        return 1

    # Combien d'identifiants du cache Smogon sont couverts ?
    cache = projet / 'cache' / 'smogon-strategic-gen8.json'
    if cache.is_file():
        data = json.loads(cache.read_text(encoding='utf-8'))
        vus, traduits, inchanges = set(), 0, 0
        def collecte(o):
            if isinstance(o, dict):
                for k, v in o.items():
                    if k == 'items' and isinstance(v, list):
                        for x in v:
                            if isinstance(x, int):
                                vus.add(x)
                    else:
                        collecte(v)
            elif isinstance(o, list):
                for x in o:
                    collecte(x)
        collecte(data)
        for i in vus:
            if i in table:
                traduits += 1
                if table[i] == i:
                    inchanges += 1
        print('cache Smogon : %d identifiants d objets distincts, %d traduits, '
              '%d inchanges par la traduction' % (len(vus), traduits, inchanges))
        manquants = sorted(i for i in vus if i not in table)
        if manquants:
            print('  sans correspondance : %d %s' % (len(manquants), manquants[:10]))

    if args.verifier:
        print('\nOK  : temoins concordants. Rien n a ete ecrit (--verifier).')
        return 0

    cible = projet / 'item-id-map.csv'
    with cible.open('w', encoding='utf-8', newline='') as fh:
        w = csv.writer(fh)
        w.writerow(['dex_item_id', 'game_item_id', 'name_en'])
        for ident in sorted(table):
            w.writerow([ident, table[ident], jeu[table[ident]]])
    print('\nOK  : %d correspondances ecrites dans %s' % (len(table), cible))
    print('      Fichier DERIVE DU JEU : ne pas le publier ni le versionner.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
