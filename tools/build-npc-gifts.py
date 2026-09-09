#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Construit le catalogue des cadeaux d'objets des PNJ, VERIFIE contre le dump.

Ce que fait ce script, et ce qu'il ne fait pas
----------------------------------------------
KM-Editor (GPL-3.0-only) publie un catalogue de cadeaux PNJ sous forme d'un
fichier source C#. Ce script n'en reprend AUCUN code : il en lit uniquement des
FAITS SUR LE JEU - nom de fichier `.amx`, index de cellule, identifiant d'objet
attendu - et il verifie chacun de ces faits, un par un, contre le dump de
l'utilisateur. Ce qui ne se verifie pas est ecarte.

Le resultat est donc derive du dump, pas du code de KM. Les entrees Bouclier
tombent d'elles-memes : elles ne concordent pas sur un dump Epee.

  ATTENTION : le fichier produit est DERIVE DU JEU. Ne pas le publier, ne pas
  le versionner - meme regle que `items.csv` et `script_record.json`.

Format des scripts, ETABLI PAR MESURE
--------------------------------------
Les `.amx` de SwSh sont des modules Pawn 64 bits en encodage compact :

    en-tete standard : u32 size, u16 magic (0xF1E0/0xF1E1/0xF1E2),
                       u32 cod, u32 dat, u32 hea a +0x0C, +0x10, +0x14
    drapeau 0x0004 (compact) dans les flags a +0x0A
    zone compacte  : du decalage `cod` jusqu'a `size`
    cellules de 8 OCTETS - c'est la mesure qui l'a dit : (hea - cod) / 8 donne
                     exactement le nombre de cellules decodees, /4 en donnait le
                     double

Decodage compact, A REBOURS depuis la fin : chaque cellule est une suite
d'octets dont tous sauf le dernier portent le bit 0x80 ; le premier octet de la
suite porte le signe en 0x40.

Une cellule d'instruction vaut `(operande << 32) | opcode`. Les cadeaux
utilisent l'opcode **0xBC** (`push.c`) : l'identifiant de l'objet est donc les
32 bits de poids fort de la cellule.

Temoins concordants au moment de l'ecriture de ce script :

    main_event_0180 cellule 5119 -> 0x4_000000BC   = Poke Ball (4)
    main_event_0350 cellule 6101 -> 0x95_000000BC  = Baie Ceriz (149)
    main_event_0350 cellule 6106 -> 0x9B_000000BC  = Baie Oran (155)

Usage
-----
    python tools/build-npc-gifts.py "<chemin-romfs>"
    python tools/build-npc-gifts.py "<chemin-romfs>" --verifier
"""
from __future__ import annotations

import argparse
import csv
import re
import struct
import sys
from pathlib import Path

AMX_REL = "bin/script/amx"
OPCODE_PUSH_C = 0xBC
# Le catalogue est embarque dans third_party/ (GPL-3.0-only, cf. le README de
# ce dossier). On accepte aussi un clone complet de KM-Editor a cote, pour qui
# travaille depuis les sources amont.
KM_DEFS_CANDIDATS = (
    "third_party/KM-Editor/SwShNpcItemGiftDefinitions.cs",
    "research/KM-Editor/src/KM.SwSh/NpcItemGift/SwShNpcItemGiftDefinitions.cs",
)


def decoder(chemin: Path):
    """Rend (cellules, bornes) ou bornes[k] = (debut, fin) dans la zone compacte."""
    d = chemin.read_bytes()
    if len(d) < 0x20:
        return None, None, None
    size = struct.unpack_from("<I", d, 0)[0]
    magic = struct.unpack_from("<H", d, 4)[0]
    flags = struct.unpack_from("<H", d, 10)[0]
    cod, dat, hea = struct.unpack_from("<3I", d, 12)
    if magic not in (0xF1E0, 0xF1E1, 0xF1E2) or not (flags & 0x0004):
        return None, None, None
    if size > len(d) or cod >= size:
        return None, None, None

    comp = d[cod:size]
    cells, bornes = [], []
    i = len(comp)
    while i > 0:
        fin = i
        c = 0
        shift = 0
        while True:
            i -= 1
            c |= (comp[i] & 0x7F) << shift
            shift += 7
            if i == 0 or (comp[i - 1] & 0x80) == 0:
                break
        if comp[i] & 0x40:
            while shift < 64:
                c |= 0xFF << shift
                shift += 8
        cells.append(c & 0xFFFFFFFFFFFFFFFF)
        bornes.append((i, fin))
    cells.reverse()
    bornes.reverse()

    attendu = (hea - cod) // 8
    if len(cells) != attendu:
        # Le nombre de cellules doit tomber juste : sinon le decodage a derape
        # et tout ce qu'on lirait ensuite serait faux.
        return None, None, None
    return cells, bornes, (d, cod, size)


def faits_km(racine: Path):
    """Lit les FAITS du catalogue KM : (fichier amx, cellule, identifiant attendu).

    Aucun code n'est repris. On cherche les appels `Gift(...)`, qui portent le
    nom du fichier, puis les `Slot(...)` qui suivent jusqu'au `Gift` suivant.
    """
    src = next((racine / c for c in KM_DEFS_CANDIDATS if (racine / c).is_file()), None)
    if src is None:
        return []
    texte = src.read_text(encoding="utf-8")
    faits = []
    fichier = None
    for ligne in texte.splitlines():
        m = re.search(r'"([A-Za-z0-9_]+\.amx)"', ligne)
        if m:
            fichier = m.group(1)
        if fichier is None:
            continue
        for s in re.finditer(
                r'Slot\(\s*"[^"]*"\s*,\s*"([^"]*)"\s*,\s*(\d+)\s*,\s*(\d+)', ligne):
            faits.append({
                "amx": fichier,
                "nom": s.group(1),
                "cellule": int(s.group(2)),
                "item_attendu": int(s.group(3)),
            })
    return faits


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("romfs")
    ap.add_argument("--sortie", default="")
    ap.add_argument("--verifier", action="store_true")
    args = ap.parse_args()

    projet = Path(__file__).resolve().parents[1]
    amx_dir = Path(args.romfs) / AMX_REL
    if not amx_dir.is_dir():
        print("ECHEC: %s introuvable" % amx_dir)
        return 1

    faits = faits_km(projet)
    if not faits:
        print("ECHEC: catalogue de faits introuvable (%s)" % " ou ".join(KM_DEFS_CANDIDATS))
        return 1
    print("faits a verifier : %d" % len(faits))

    cache = {}
    retenus, rejetes = [], []
    for f in faits:
        chemin = amx_dir / f["amx"]
        if f["amx"] not in cache:
            cache[f["amx"]] = decoder(chemin) if chemin.is_file() else (None, None, None)
        cells, bornes, _ = cache[f["amx"]]
        if cells is None:
            rejetes.append((f, "fichier absent ou illisible"))
            continue
        idx = f["cellule"]
        if idx >= len(cells):
            rejetes.append((f, "cellule hors du module"))
            continue
        cell = cells[idx]
        if (cell & 0xFFFFFFFF) != OPCODE_PUSH_C:
            rejetes.append((f, "opcode 0x%02X au lieu de 0xBC" % (cell & 0xFFFFFFFF)))
            continue
        lu = (cell >> 32) & 0xFFFFFFFF
        if lu != f["item_attendu"]:
            rejetes.append((f, "objet %d au lieu de %d" % (lu, f["item_attendu"])))
            continue
        retenus.append({
            "amx": f["amx"],
            "cellule": idx,
            "item_id": lu,
            "octet_debut": bornes[idx][0],
            "octet_fin": bornes[idx][1],
            "nom": f["nom"],
        })

    print("  verifies sur le dump : %d" % len(retenus))
    print("  ecartes              : %d" % len(rejetes))
    motifs = {}
    for _, r in rejetes:
        cle = re.sub(r"\d+", "N", r)
        motifs[cle] = motifs.get(cle, 0) + 1
    for cle, n in sorted(motifs.items(), key=lambda kv: -kv[1]):
        print("      %-38s %d" % (cle, n))

    if not retenus:
        print("\nECHEC: aucun fait verifie. Rien n'est ecrit.")
        return 1

    if args.verifier:
        print("\nOK  : %d cadeaux verifies. Rien n'a ete ecrit (--verifier)." % len(retenus))
        return 0

    sortie = Path(args.sortie) if args.sortie else projet / "npc-gifts.csv"
    with sortie.open("w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(retenus[0].keys()))
        w.writeheader()
        w.writerows(retenus)
    print("\nOK  : %d cadeaux ecrits dans %s" % (len(retenus), sortie))
    print("      Ce fichier est DERIVE DU JEU : ne pas le publier ni le versionner.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
