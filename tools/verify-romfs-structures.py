#!/usr/bin/env python3
"""Vérifie par lecture d'octets les structures ROMFS documentées.

Méthode : **témoin avant mesure**. Le script revalide d'abord des champs déjà
établis (statistiques et compatibilités CT/DT de trois espèces connues). Si le
témoin ne concorde pas, il s'arrête : le dump n'est pas celui attendu, ou la
disposition a changé, et aucune conclusion ne peut être tirée du reste.

Portée : Épée 1.3.2. Bouclier n'est pas couvert.

Structures vérifiées, documentées dans docs/offsets/swsh-1.3.2-epee.md :
  * personal_total.bin : taille d'enregistrement, CT, DT, tuteurs de type,
                         maîtres de capacités (0xA8)
  * item.dat           : table CT/DT indirectée par pointeur
  * wazaoboe_total.bin : capacités apprises par niveau

Usage
-----
    python tools/verify-romfs-structures.py <chemin-romfs>
    python tools/verify-romfs-structures.py "C:/Users/.../sword/romfs"

Code de sortie 0 si tout concorde, 1 sinon.
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

PERSONAL_REL = 'bin/pml/personal/personal_total.bin'
ITEM_REL = 'bin/pml/item/item.dat'
LEARNSET_REL = 'bin/pml/waza_oboe/wazaoboe_total.bin'

PERSONAL_RECORD_SIZE = 0xB0
# Largeur du champ EN OCTETS, distincte du nombre de bits utilises : les 100 bits
# de compatibilite occupent 16 octets (0x28-0x37 et 0x3C-0x4B), pas 13. Deriver
# la largeur par bits // 8 tronque les 4 derniers bits et fait lire 96 au lieu
# de 100 — c'est le temoin qui a rattrape cette erreur.
TM_OFFSET, TM_WIDTH, TM_BITS = 0x28, 0x10, 100
TYPE_TUTOR_OFFSET, TYPE_TUTOR_WIDTH, TYPE_TUTOR_BITS = 0x38, 0x01, 8
TR_OFFSET, TR_WIDTH, TR_BITS = 0x3C, 0x10, 100
# Maitres de capacites de l'Ile solitaire de l'Armure. 18 bits exactement : le
# 19e et au-dela ne sont JAMAIS mis dans le fichier, et c'est precisement ce qui
# a permis de localiser le champ. Le generateur n'ecrit que ces 18 bits.
TUTOR_OFFSET, TUTOR_WIDTH, TUTOR_BITS = 0xA8, 0x03, 18

LEARNSET_RECORD_SIZE = 0x104
LEARNSET_TERMINATOR = 0xFFFF

ITEM_HEADER_SIZE = 0x44
ITEM_MACHINE_PTR_OFFSET = 0x02
MACHINE_COUNT, MACHINE_ENTRY_SIZE = 200, 4

# Témoins : espèce -> (bits CT attendus, bits DT attendus). COMBAT-CACHE §14.
CONTROLS = {
    151: ('Mew', 100, 100),
    132: ('Metamorph', 0, 0),
    6: ('Dracaufeu', 37, 22),
}

# Frontière CT/DT et affectations connues du jeu. docs/offsets/.
MACHINE_CONTROLS = {
    0: (1230, 5),      # CT00 -> Poing Meteore
    100: (1130, 14),   # DT00 -> Danse-Lames
    101: (1131, 34),   # DT01 -> Plaquage
    102: (1132, 53),   # DT02 -> Lance-Flammes
    103: (1133, 56),   # DT03 -> Hydrocanon
    199: (1229, 776),  # DT99 -> Poing Bouclier
}


def popcount(data: bytes) -> int:
    return sum(bin(b).count('1') for b in data)


class Report:
    def __init__(self) -> None:
        self.failures: list[str] = []

    def check(self, ok: bool, label: str, detail: str = '') -> bool:
        mark = 'OK   ' if ok else 'ECHEC'
        print(f'  {mark} {label}' + (f' — {detail}' if detail else ''))
        if not ok:
            self.failures.append(label)
        return ok


def verify_personal(path: Path, r: Report) -> None:
    print(f'\n=== {PERSONAL_REL} ===')
    data = path.read_bytes()
    count, remainder = divmod(len(data), PERSONAL_RECORD_SIZE)
    print(f'  {len(data)} octets, {count} enregistrements de '
          f'0x{PERSONAL_RECORD_SIZE:X}')

    if not r.check(remainder == 0, 'taille multiple de la taille d enregistrement',
                   f'reste {remainder}'):
        return

    def record(i: int) -> bytes:
        return data[i * PERSONAL_RECORD_SIZE:(i + 1) * PERSONAL_RECORD_SIZE]

    print('  -- témoin --')
    control_ok = True
    for idx, (name, want_tm, want_tr) in CONTROLS.items():
        if idx >= count:
            control_ok &= r.check(False, f'témoin {name}', 'index hors du fichier')
            continue
        rec = record(idx)
        got_tm = popcount(rec[TM_OFFSET:TM_OFFSET + TM_WIDTH])
        got_tr = popcount(rec[TR_OFFSET:TR_OFFSET + TR_WIDTH])
        control_ok &= r.check(
            (got_tm, got_tr) == (want_tm, want_tr),
            f'témoin {name} (espèce {idx})',
            f'CT attendu {want_tm} lu {got_tm}, DT attendu {want_tr} lu {got_tr}')

    if not control_ok:
        print('  -> témoin discordant : le reste n est pas concluant.')
        return

    print('  -- champ 0x38 : tuteurs de type, pas du remplissage --')
    nonzero = [0, 0, 0, 0]
    for i in range(count):
        quad = record(i)[TYPE_TUTOR_OFFSET:TYPE_TUTOR_OFFSET + 4]
        for j in range(4):
            if quad[j]:
                nonzero[j] += 1

    r.check(nonzero[0] > 0,
            f'0x{TYPE_TUTOR_OFFSET:02X} porte des données',
            f'{nonzero[0]} espèces concernées')
    r.check(nonzero[1:] == [0, 0, 0],
            f'0x{TYPE_TUTOR_OFFSET+1:02X}-0x{TYPE_TUTOR_OFFSET+3:02X} '
            f'sont bien du remplissage',
            f'non nuls : {nonzero[1:]}')

    over = [i for i in range(count)
            if popcount(record(i)[TYPE_TUTOR_OFFSET:TYPE_TUTOR_OFFSET + 1])
            > TYPE_TUTOR_BITS]
    r.check(not over, f'aucune espèce ne dépasse {TYPE_TUTOR_BITS} tuteurs')

    print(f'  -- champ 0x{TUTOR_OFFSET:02X} : maîtres de capacités, 18 bits --')
    # C'est la mesure qui a localise le champ : un champ de N bits se reconnait
    # a ce qu'aucun enregistrement du fichier n'utilise le bit N+1.
    values = [int.from_bytes(record(i)[TUTOR_OFFSET:TUTOR_OFFSET + TUTOR_WIDTH],
                             'little')
              for i in range(count)]
    mask = (1 << TUTOR_BITS) - 1
    beyond = sum(1 for v in values if v & ~mask)
    widths = [bin(v).count('1') for v in values]
    r.check(beyond == 0,
            f'aucun enregistrement n utilise un bit au-dela du {TUTOR_BITS}e',
            f'{beyond} enregistrement(s) fautif(s)')
    r.check(max(widths) == TUTOR_BITS,
            f'le maximum observe vaut exactement {TUTOR_BITS}',
            f'lu {max(widths)}')
    r.check(widths[151] == TUTOR_BITS, 'Mew accepte les 18 maîtres')
    r.check(widths[132] == 0 and widths[133] == 0,
            'Métamorph et Évoli n en acceptent aucun')
    r.check(sum(1 for w in widths if w) > 500,
            'le champ est largement peuplé',
            f'{sum(1 for w in widths if w)} espèces concernées')


def verify_learnset(path: Path, r: Report) -> None:
    print(f'\n=== {LEARNSET_REL} ===')
    data = path.read_bytes()
    count, remainder = divmod(len(data), LEARNSET_RECORD_SIZE)
    print(f'  {len(data)} octets, {count} enregistrements de '
          f'0x{LEARNSET_RECORD_SIZE:X}')

    if not r.check(remainder == 0, 'taille multiple de la taille d enregistrement',
                   f'reste {remainder}'):
        return

    personal = path.parents[1] / 'personal' / 'personal_total.bin'
    if personal.is_file():
        want = personal.stat().st_size // PERSONAL_RECORD_SIZE
        r.check(count == want,
                'autant d enregistrements que la table Pokémon',
                f'{count} contre {want}')

    paliers = 0
    peuples = 0
    debordements = 0
    for i in range(count):
        base = i * LEARNSET_RECORD_SIZE
        vu = 0
        clos = False
        for c in range(0, LEARNSET_RECORD_SIZE, 4):
            move, lvl = struct.unpack_from('<HH', data, base + c)
            if move == LEARNSET_TERMINATOR and lvl == LEARNSET_TERMINATOR:
                clos = True
                break
            vu += 1
        if not clos:
            # Un enregistrement sans terminateur ferait lire la suite comme des
            # paliers : c'est exactement le mode de panne a surveiller.
            debordements += 1
        paliers += vu
        if vu:
            peuples += 1

    r.check(debordements == 0,
            'chaque enregistrement se termine par FFFF FFFF',
            f'{debordements} sans terminateur')
    r.check(paliers > 10000, 'la table porte bien les paliers attendus',
            f'{paliers} paliers sur {peuples} espèces')


def verify_item(path: Path, r: Report) -> None:
    print(f'\n=== {ITEM_REL} ===')
    data = path.read_bytes()
    print(f'  {len(data)} octets')

    ptr = struct.unpack_from('<H', data, ITEM_MACHINE_PTR_OFFSET)[0]
    offset = ITEM_HEADER_SIZE + ptr * 2
    length = MACHINE_COUNT * MACHINE_ENTRY_SIZE
    print(f'  pointeur u16 a +0x{ITEM_MACHINE_PTR_OFFSET:02X} = {ptr} '
          f'(0x{ptr:04X})  ->  table a 0x{offset:X}, fin 0x{offset+length:X}')

    if not r.check(offset + length <= len(data),
                   'la table tient dans le fichier'):
        return

    entries = [struct.unpack_from('<HH', data, offset + i * MACHINE_ENTRY_SIZE)
               for i in range(MACHINE_COUNT)]

    r.check(all(e != (0, 0) for e in entries), 'aucune entrée nulle')
    r.check(len({e[0] for e in entries}) == MACHINE_COUNT,
            'identifiants d objet tous distincts')
    r.check(len({e[1] for e in entries}) == MACHINE_COUNT,
            'identifiants d attaque tous distincts')

    tr_ids = [e[0] for e in entries[100:]]
    r.check(tr_ids == list(range(1130, 1230)),
            'entrées 100-199 = objets 1130..1229 contigus (DT00..DT99)')

    print('  -- témoin sémantique --')
    for idx, (want_item, want_move) in MACHINE_CONTROLS.items():
        got = entries[idx]
        r.check(got == (want_item, want_move),
                f'entrée {idx}',
                f'attendu {(want_item, want_move)}, lu {got}')


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('romfs', help='racine du romfs Epee 1.3.2 (dossier bin/ dedans)')
    args = ap.parse_args()

    root = Path(args.romfs)
    if not root.is_dir():
        print(f'ECHEC: dossier introuvable : {root}')
        return 1

    print(f'Vérification des structures ROMFS — Épée 1.3.2')
    print(f'racine : {root}')

    r = Report()
    for rel, fn in ((PERSONAL_REL, verify_personal), (ITEM_REL, verify_item),
                    (LEARNSET_REL, verify_learnset)):
        p = root / rel
        if not p.is_file():
            print(f'\n=== {rel} ===')
            r.check(False, 'fichier présent', str(p))
            continue
        fn(p, r)

    print()
    if r.failures:
        print(f'{len(r.failures)} échec(s) : ' + ', '.join(r.failures))
        return 1
    print('Toutes les structures documentées concordent avec le dump.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
