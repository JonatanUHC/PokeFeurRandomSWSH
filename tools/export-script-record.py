#!/usr/bin/env python3
"""Exporte `script_id_record.bin` en JSON pour la compilation du module.

Pourquoi cet outil existe
-------------------------
`misc/scripts/build_romfs.py` refuse de compiler sans un enregistrement de
script exporté depuis le ROMFS de l'utilisateur :

    RuntimeError: Missing base script record JSON. Export it from the user's
    own ROMFS script_id_record.bin and pass BASE_SCRIPT_RECORD_JSON; do not
    ship a vanilla-derived default_script_record.json with the randomizer.

Ce garde-fou est délibéré et légitime : le dépôt ne doit contenir aucune donnée
dérivée du jeu. Mais aucun outil du projet ne produisait cet export — le
PowerShell sait *écrire* le format, pas le *lire*. La compilation était donc
bloquée par une pièce manquante.

Format
------
FlatBuffers. Disposition déduite du constructeur de
`CustomSwShRandomizer.ps1` (classe `PokeFeurScriptRecordCodec`) :

    racine        : table à un champ, un vecteur d'entrées
    entrée        : script_id u64 à +8, amx_path string à +16,
                    text_path string à +20

Aucun code tiers n'a été repris : la disposition est un fait, lu dans le
constructeur du projet lui-même.

Usage
-----
    python tools/export-script-record.py <romfs> [-o sortie.json]
    python tools/export-script-record.py "C:/Users/.../sword/romfs"

Puis, pour compiler :

    BASE_SCRIPT_RECORD_JSON=<sortie.json> make version=SWORD
"""
from __future__ import annotations

import argparse
import json
import struct
import sys
from pathlib import Path

REL = 'bin/script/param/script_id/script_id_record.bin'

# Position du champ DANS LA VTABLE, pas la valeur qu'il y contient. La vtable
# construite par le PowerShell est : [taille=10][taille table=24][8][16][20],
# donc les trois champs occupent les emplacements 4, 6 et 8 de la vtable et y
# stockent les décalages 8, 16 et 20 depuis le début de la table.
VT_SCRIPT_ID = 4
VT_AMX_PATH = 6
VT_TEXT_PATH = 8


class FlatReader:
    """Lecteur FlatBuffers minimal, limité à ce dont ce format a besoin."""

    def __init__(self, data: bytes) -> None:
        self.d = data

    def u16(self, p: int) -> int:
        return struct.unpack_from('<H', self.d, p)[0]

    def u32(self, p: int) -> int:
        return struct.unpack_from('<I', self.d, p)[0]

    def i32(self, p: int) -> int:
        return struct.unpack_from('<i', self.d, p)[0]

    def u64(self, p: int) -> int:
        return struct.unpack_from('<Q', self.d, p)[0]

    def field(self, table: int, field_offset: int) -> int | None:
        """Position absolue d'un champ, ou None s'il est absent de la vtable."""
        vtable = table - self.i32(table)
        vtable_size = self.u16(vtable)
        if field_offset >= vtable_size:
            return None
        rel = self.u16(vtable + field_offset)
        return table + rel if rel else None

    def string(self, p: int) -> str:
        start = p + self.u32(p)
        length = self.u32(start)
        return self.d[start + 4:start + 4 + length].decode('utf-8', 'replace')


def parse(data: bytes) -> list[dict]:
    r = FlatReader(data)
    root = r.u32(0)

    vector_field = r.field(root, 4)
    if vector_field is None:
        raise SystemExit('ECHEC: la table racine ne porte pas le vecteur attendu.')

    vector = vector_field + r.u32(vector_field)
    count = r.u32(vector)
    entries = []
    for i in range(count):
        slot = vector + 4 + i * 4
        table = slot + r.u32(slot)

        sid_at = r.field(table, VT_SCRIPT_ID)
        amx_at = r.field(table, VT_AMX_PATH)
        txt_at = r.field(table, VT_TEXT_PATH)

        entries.append({
            'script_id': r.u64(sid_at) if sid_at is not None else 0,
            'amx_path': r.string(amx_at) if amx_at is not None else '',
            'text_path': r.string(txt_at) if txt_at is not None else '',
        })
    return entries


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('romfs', help='racine du romfs (ou chemin direct du .bin)')
    ap.add_argument('-o', '--output', default='script_record.json',
                    help='fichier JSON de sortie (défaut : script_record.json)')
    args = ap.parse_args()

    src = Path(args.romfs)
    path = src if src.is_file() else src / REL
    if not path.is_file():
        print(f'ECHEC: {path} introuvable.')
        return 1

    data = path.read_bytes()
    print(f'lecture : {path}  ({len(data)} octets)')

    entries = parse(data)
    if not entries:
        print('ECHEC: aucune entrée lue — le format ne correspond pas.')
        return 1

    # Contrôle de cohérence : des chemins vides ou des identifiants nuls en
    # nombre signaleraient une mauvaise interprétation de la disposition.
    empty = sum(1 for e in entries if not e['amx_path'])
    if empty > len(entries) // 10:
        print(f'ECHEC: {empty}/{len(entries)} entrées sans chemin AMX. '
              f'La disposition lue est probablement fausse.')
        return 1

    out = Path(args.output)
    out.write_text(json.dumps({'scripts': entries}, indent=2, ensure_ascii=False),
                   encoding='utf-8')

    print(f'{len(entries)} entrées exportées vers {out}')
    print('exemples :')
    for e in entries[:3]:
        print(f'  0x{e["script_id"]:016X}  {e["amx_path"]}')
    print()
    print('Pour compiler :')
    print(f'  BASE_SCRIPT_RECORD_JSON="{out.resolve()}" make version=SWORD')
    return 0


if __name__ == '__main__':
    sys.exit(main())
