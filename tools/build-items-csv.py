#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Construit `items.csv` a partir du ROMFS de l'utilisateur.

Pourquoi ce fichier n'est pas livre avec le projet
--------------------------------------------------
`items.csv` etait attendu par le generateur depuis toujours, et absent. Son
absence rend le mode « pool d'objets tenus » TOTALEMENT inoperant : sans lui,
`Get-TrainerItemPool` retombe sur une liste codee en dur qui ignore le mode
demande - severite « haute » au manifeste des fichiers de donnees.

Le schema attendu (`id,identifier,category_id,cost`) est celui d'un jeu de
donnees externe. Plutot que d'ajouter cette dependance, ce script derive le
fichier du dump de l'utilisateur : les donnees sont alors exactes pour SA
version du jeu, et le projet ne depend de rien.

  ATTENTION : le fichier produit est DERIVE DU JEU. Il ne doit etre ni publie,
  ni versionne, au meme titre que `research/swsh-mods-exl/script_record.json`.

Structure lue, VERIFIEE sur le dump Epee 1.3.2
-----------------------------------------------
    bin/pml/item/item.dat
    u32 a 0x40        offset des enregistrements (0x122C sur ce dump)
    u16 a 0x04        nombre d'enregistrements   (965)
    table d'index a 0x44 : 1608 x u16, identifiant d'objet -> n° d'enregistrement
                           la valeur 0 signifie « cet objet n'existe pas »
    enregistrements de 48 octets :
      +0x00  u32  prix d'achat
      +0x11  u8   poche
      +0x12  u8   puissance de Degommage
      +0x13  u8   type d'usage sur le terrain
      +0x16  u8   type d'objet
      +0x2B  u8   quantite de soin

Temoin : (50972 - 0x122C) / 48 = 965, exactement la valeur lue en 0x04 ; et les
200 objets de la table CT/DT sont EXACTEMENT ceux dont la poche vaut 5, sans
faux positif ni oubli. La disposition n'est donc plus « provisoire ».

Ce que la poche vaut, et ce qu'elle ne vaut pas
-----------------------------------------------
Quatre poches sont identifiees avec certitude, chacune par un temoin :

    5   machines      les 200 objets de la table CT/DT, exactement
    33  Poke Balls    identifiants 1 a 16, prix nul
    32  soins         17 des 36 objets portent une quantite de soin non nulle
    8   objets cles   prix nul sur les 47

Les huit autres poches ne sont PAS identifiees : sans table de noms, je ne peux
pas les nommer sans deviner. Le generateur ne s'en sert donc que pour EXCLURE
ce qui est prouve, jamais pour inclure ce qui est suppose.

Usage
-----
    python tools/build-items-csv.py "<chemin-romfs>"
    python tools/build-items-csv.py "<chemin-romfs>" --sortie items.csv
    python tools/build-items-csv.py "<chemin-romfs>" --verifier   # ne rien ecrire
"""
from __future__ import annotations

import argparse
import csv
import struct
import sys
from pathlib import Path

ITEM_REL = "bin/pml/item/item.dat"
INDEX_OFFSET = 0x44
INDEX_COUNT = 1608
RECORDS_PTR_OFFSET = 0x40
RECORD_COUNT_OFFSET = 0x04
RECORD_SIZE = 48

F_COST = 0x00
F_POCKET = 0x11
F_FLING = 0x12
F_FIELD_USE = 0x13
F_TYPE = 0x16
F_HEAL = 0x2B

MACHINE_PTR_OFFSET = 0x02
MACHINE_COUNT = 200
MACHINE_ENTRY_SIZE = 4
MACHINE_POCKET = 5


def lire_table(data: bytes):
    """Rend (index, offset des enregistrements, nombre d'enregistrements)."""
    rec_offset = struct.unpack_from("<I", data, RECORDS_PTR_OFFSET)[0]
    rec_count = struct.unpack_from("<H", data, RECORD_COUNT_OFFSET)[0]
    attendu = (len(data) - rec_offset) // RECORD_SIZE
    if rec_offset <= INDEX_OFFSET or rec_offset >= len(data):
        raise SystemExit("ECHEC: offset d'enregistrements hors fichier (0x%X)" % rec_offset)
    if attendu != rec_count:
        raise SystemExit(
            "ECHEC: %d enregistrements deduits de la taille, %d annonces en 0x04. "
            "La structure n'est pas celle attendue, rien n'est ecrit." % (attendu, rec_count))
    index = [struct.unpack_from("<H", data, INDEX_OFFSET + i * 2)[0]
             for i in range(INDEX_COUNT)]
    return index, rec_offset, rec_count


def temoin_machines(data: bytes, index, rec_offset: int) -> int:
    """Temoin avant mesure : les 200 machines doivent etre exactement la poche 5.

    Si ce controle echoue, le decalage de la poche a bouge et TOUT le reste du
    fichier produit serait faux. On s'arrete plutot que d'ecrire des donnees
    fausses avec l'air d'etre justes.
    """
    ptr = struct.unpack_from("<H", data, MACHINE_PTR_OFFSET)[0]
    debut = INDEX_OFFSET + ptr * 2
    machines = {struct.unpack_from("<H", data, debut + i * MACHINE_ENTRY_SIZE)[0]
                for i in range(MACHINE_COUNT)}

    def poche(item_id: int):
        if item_id <= 0 or item_id >= INDEX_COUNT or index[item_id] == 0:
            return None
        return data[rec_offset + index[item_id] * RECORD_SIZE + F_POCKET]

    poche5 = {i for i in range(1, INDEX_COUNT)
              if index[i] != 0 and poche(i) == MACHINE_POCKET}
    if poche5 != machines:
        manquants = sorted(machines - poche5)[:5]
        surplus = sorted(poche5 - machines)[:5]
        raise SystemExit(
            "ECHEC: le temoin des machines ne concorde pas. Manquants %s, surplus %s. "
            "Rien n'est ecrit." % (manquants, surplus))
    return len(machines)


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("romfs", help="racine du romfs (contient bin/)")
    ap.add_argument("--sortie", default="", help="chemin du CSV (defaut: <projet>/items.csv)")
    ap.add_argument("--verifier", action="store_true",
                    help="tout mesurer et tout controler, mais n'ecrire aucun fichier")
    args = ap.parse_args()

    chemin = Path(args.romfs) / ITEM_REL
    if not chemin.is_file():
        print("ECHEC: %s introuvable" % chemin)
        return 1

    data = chemin.read_bytes()
    index, rec_offset, rec_count = lire_table(data)
    n_machines = temoin_machines(data, index, rec_offset)

    print("item.dat : %d octets" % len(data))
    print("  enregistrements : %d a partir de 0x%X" % (rec_count, rec_offset))
    print("  temoin machines : %d objets en poche %d, concordance exacte"
          % (n_machines, MACHINE_POCKET))

    lignes = []
    poches = {}
    for item_id in range(1, INDEX_COUNT):
        rec = index[item_id]
        if rec == 0:
            # 644 identifiants pointent sur l'enregistrement 0 : ce sont des
            # objets d'autres generations, absents de cette version du jeu.
            continue
        base = rec_offset + rec * RECORD_SIZE
        pocket = data[base + F_POCKET]
        poches[pocket] = poches.get(pocket, 0) + 1
        lignes.append({
            "id": item_id,
            # Pas de nom : le jeu n'en stocke pas ici. L'identifiant est stable
            # et suffit aux exclusions, qui se font desormais par numero.
            "identifier": "item-%04d" % item_id,
            "category_id": pocket,
            "cost": struct.unpack_from("<I", data, base + F_COST)[0],
            "fling_power": data[base + F_FLING],
            "field_use": data[base + F_FIELD_USE],
            "item_type": data[base + F_TYPE],
            "heal_amount": data[base + F_HEAL],
        })

    print("  objets reels    : %d sur %d identifiants (%d absents de cette version)"
          % (len(lignes), INDEX_COUNT - 1, INDEX_COUNT - 1 - len(lignes)))
    print("  poches          : " + ", ".join(
        "%d=%d" % (p, n) for p, n in sorted(poches.items())))

    if args.verifier:
        print("\nOK  : structure conforme. Rien n'a ete ecrit (--verifier).")
        return 0

    sortie = Path(args.sortie) if args.sortie else Path(__file__).resolve().parents[1] / "items.csv"
    with sortie.open("w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(lignes[0].keys()))
        w.writeheader()
        w.writerows(lignes)
    print("\nOK  : %d objets ecrits dans %s" % (len(lignes), sortie))
    print("      Ce fichier est DERIVE DU JEU : ne pas le publier ni le versionner.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
