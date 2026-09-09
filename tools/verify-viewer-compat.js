#!/usr/bin/env node
/*
 * Relit les sorties du generateur AVEC LE DECODAGE DU VISUALISEUR.
 *
 * Pourquoi ce script existe
 * -------------------------
 * Le visualiseur https://jonatanuhc.github.io/PokeFeur/ est une implementation
 * INDEPENDANTE des memes structures : il lit personal_total.bin,
 * wazaoboe_total.bin et bin/trainer/* pour afficher les equipes. Si une sortie
 * du generateur ne s'y relit pas, l'utilisateur voit des cases vides ou un
 * plantage - et aucun test interne ne l'aurait dit, puisque le generateur se
 * relit toujours lui-meme sans probleme.
 *
 * Les decalages ci-dessous sont repris de assets/js/swsh-folder-bridge.js du
 * depot du site. Ils concordent champ pour champ avec ceux du generateur, ce
 * qui est deja un resultat : deux implementations ecrites separement lisent la
 * meme chose au meme endroit.
 *
 *   personal   0xB0 : stats 0x00-0x05, types 0x06/0x07,
 *                     talents 0x18/0x1A/0x1C, formStatsIndex 0x1E
 *   learnset  0x104 : paires (u16 attaque, u16 niveau), fin FFFF FFFF
 *   dresseur  0x20  : espece 0x0C, forme 0x0E, objet 0x10,
 *                     attaques 0x12/0x14/0x16/0x18
 *
 * Les bornes de validite ne sont pas devinees : elles sont MESUREES sur le dump
 * vanilla passe en premier argument. Une attaque valide est une attaque qui
 * existe dans le jeu d'origine, pas un nombre plausible.
 *
 * Usage
 * -----
 *   node tools/verify-viewer-compat.js <romfs-vanilla> <dossier-du-lot>
 */
'use strict';

const fs = require('fs');
const path = require('path');

const PERSONAL_ENTRY_SIZE = 0xB0;
const LEARNSET_ENTRY_SIZE = 0x104;
const TRAINER_POKE_SIZE = 0x20;

const u8 = (b, o) => b.readUInt8(o);
const u16 = (b, o) => b.readUInt16LE(o);

function parsePersonalTable(buf) {
  const out = [];
  for (let i = 0; i + PERSONAL_ENTRY_SIZE <= buf.length; i += PERSONAL_ENTRY_SIZE) {
    out.push({
      hp: u8(buf, i + 0x00), atk: u8(buf, i + 0x01), def: u8(buf, i + 0x02),
      spe: u8(buf, i + 0x03), spa: u8(buf, i + 0x04), spd: u8(buf, i + 0x05),
      type1: u8(buf, i + 0x06), type2: u8(buf, i + 0x07),
      ability1: u16(buf, i + 0x18), ability2: u16(buf, i + 0x1A),
      abilityH: u16(buf, i + 0x1C), formStatsIndex: u16(buf, i + 0x1E),
    });
  }
  return out;
}

function parseLearnsetTable(buf) {
  const out = [];
  for (let i = 0; i + LEARNSET_ENTRY_SIZE <= buf.length; i += LEARNSET_ENTRY_SIZE) {
    const moves = [];
    let clos = false;
    for (let c = 0; c < LEARNSET_ENTRY_SIZE; c += 4) {
      const moveId = u16(buf, i + c);
      const level = u16(buf, i + c + 2);
      if (moveId === 0xFFFF && level === 0xFFFF) { clos = true; break; }
      if (moveId && moveId !== 0xFFFF) moves.push({ moveId, level });
    }
    out.push({ moves, clos });
  }
  return out;
}

function parseTrainerPoke(buf) {
  const out = [];
  for (let i = 0; i + TRAINER_POKE_SIZE <= buf.length; i += TRAINER_POKE_SIZE) {
    out.push({
      level: u16(buf, i + 0x0A),
      speciesId: u16(buf, i + 0x0C),
      formId: u16(buf, i + 0x0E),
      heldItemId: u16(buf, i + 0x10),
      moves: [u16(buf, i + 0x12), u16(buf, i + 0x14), u16(buf, i + 0x16), u16(buf, i + 0x18)],
    });
  }
  return out;
}

function lireRomfs(racine) {
  const p = (...s) => path.join(racine, ...s);
  const romfs = fs.existsSync(p('romfs')) ? p('romfs') : racine;
  const q = (...s) => path.join(romfs, ...s);
  return {
    romfs,
    personal: fs.existsSync(q('bin/pml/personal/personal_total.bin'))
      ? parsePersonalTable(fs.readFileSync(q('bin/pml/personal/personal_total.bin'))) : null,
    learnset: fs.existsSync(q('bin/pml/waza_oboe/wazaoboe_total.bin'))
      ? parseLearnsetTable(fs.readFileSync(q('bin/pml/waza_oboe/wazaoboe_total.bin'))) : null,
    pokeDir: q('bin/trainer/trainer_poke'),
    dataDir: q('bin/trainer/trainer_data'),
  };
}

function referentiel(racineVanilla) {
  const v = lireRomfs(racineVanilla);
  if (!v.personal || !v.learnset) throw new Error('dump vanilla incomplet');
  const especes = new Set();
  let typeMax = 0, abilMax = 0;
  v.personal.forEach((e, i) => {
    if (e.hp + e.atk + e.def + e.spe + e.spa + e.spd > 0) {
      especes.add(i);
      typeMax = Math.max(typeMax, e.type1, e.type2);
      abilMax = Math.max(abilMax, e.ability1, e.ability2, e.abilityH);
    }
  });
  // Les attaques valides sont celles que le JEU declare, pas seulement celles
  // qu'un Pokemon apprend en montant de niveau. Ma premiere version prenait le
  // referentiel dans les learnsets : 615 attaques, alors que bin/pml/waza en
  // contient 827. Elle rapportait donc des milliers de fausses alertes sur des
  // attaques parfaitement legitimes. C'est le lot complet qui l'a revele.
  const attaques = new Set();
  const wazaDir = path.join(v.romfs, 'bin/pml/waza');
  if (fs.existsSync(wazaDir)) {
    for (const f of fs.readdirSync(wazaDir)) {
      const m = /^waza(\d+)\.wazabin$/i.exec(f);
      if (m) attaques.add(parseInt(m[1], 10));
    }
  }
  v.learnset.forEach(r => r.moves.forEach(m => attaques.add(m.moveId)));
  return {
    especes, typeMax, abilMax, attaques,
    nbPersonal: v.personal.length,
    formIndex: v.personal.map(e => e.formStatsIndex),
  };
}

function dexDuSite(racineSite) {
  // Charge le dex du site tel quel : c'est un simple objet assigne a `window`.
  // Ce controle-la est different des autres. Les precedents demandent « cet
  // identifiant existe-t-il dans le JEU ? » ; celui-ci demande « le site
  // sait-il le NOMMER ? ». Un identifiant valide mais absent du dex donne une
  // case vide dans le visualiseur - un defaut visible par l'utilisateur que
  // rien du cote generateur ne peut voir.
  const f = path.join(racineSite, 'assets', 'js', 'local-dex-data.js');
  if (!fs.existsSync(f)) return null;
  const w = {};
  new Function('window', fs.readFileSync(f, 'utf8'))(w);
  const d = w.LOCAL_DEX_DATA || {};
  const ids = coll => {
    const s = new Set();
    for (const k of Object.keys(coll || {})) {
      const id = coll[k] && coll[k].id;
      if (Number.isFinite(id)) s.add(id);
    }
    return s;
  };
  return { pokemon: ids(d.pokemon), moves: ids(d.moves), items: ids(d.items), abilities: ids(d.abilities) };
}

function objetsConnus(projet) {
  const f = path.join(projet, 'items.csv');
  if (!fs.existsSync(f)) return null;
  const s = new Set();
  fs.readFileSync(f, 'utf8').split(/\r?\n/).slice(1).forEach(l => {
    const id = parseInt(l.split(',')[0], 10);
    if (!isNaN(id)) s.add(id);
  });
  return s;
}

function verifier(nom, racine, ref, objets, dex) {
  const r = lireRomfs(racine);
  const pb = [];
  const compte = { especes: 0, slots: 0, attaques: 0, objets: 0, sac: 0 };

  if (r.personal) {
    if (r.personal.length !== ref.nbPersonal) {
      pb.push(`personal : ${r.personal.length} enregistrements contre ${ref.nbPersonal}`);
    }
    r.personal.forEach((e, i) => {
      if (!ref.especes.has(i)) return;
      compte.especes++;
      if (e.type1 > ref.typeMax || e.type2 > ref.typeMax) {
        pb.push(`espece ${i} : type hors bornes (${e.type1}/${e.type2}, max vanilla ${ref.typeMax})`);
      }
      for (const [k, a] of [['1', e.ability1], ['2', e.ability2], ['H', e.abilityH]]) {
        if (a > ref.abilMax) pb.push(`espece ${i} : talent ${k} = ${a} hors bornes (max ${ref.abilMax})`);
      }
      if (e.hp === 0) pb.push(`espece ${i} : PV a 0, le visualiseur la traiterait comme absente`);
      if (ref.formIndex[i] !== e.formStatsIndex) {
        pb.push(`espece ${i} : formStatsIndex modifie (${ref.formIndex[i]} -> ${e.formStatsIndex})`);
      }
    });
  }

  if (r.learnset) {
    r.learnset.forEach((rec, i) => {
      if (!rec.clos) pb.push(`learnset ${i} : pas de terminateur FFFF FFFF`);
      rec.moves.forEach(m => {
        compte.attaques++;
        if (!ref.attaques.has(m.moveId)) pb.push(`learnset ${i} : attaque ${m.moveId} inconnue du jeu`);
        // Le niveau 0 est LEGITIME : 217 paliers vanilla en portent un. Ce sont
        // les attaques connues des l'eclosion. Ma premiere borne exigeait 1 et
        // rapportait donc 217 faux positifs sur le dump d'origine - c'est le
        // temoin qui l'a dit, avant que je ne croie a un defaut du generateur.
        if (m.level > 100) pb.push(`learnset ${i} : niveau ${m.level} au-dessus de 100`);
      });
    });
  }

  if (fs.existsSync(r.pokeDir)) {
    for (const f of fs.readdirSync(r.pokeDir)) {
      parseTrainerPoke(fs.readFileSync(path.join(r.pokeDir, f))).forEach((s, idx) => {
        if (!s.speciesId) return;
        compte.slots++;
        if (!ref.especes.has(s.speciesId)) {
          pb.push(`${f} slot ${idx} : espece ${s.speciesId} absente de personal - sprite vide dans le visualiseur`);
        }
        if (s.level < 1 || s.level > 100) pb.push(`${f} slot ${idx} : niveau ${s.level}`);
        if (s.heldItemId) {
          compte.objets++;
          if (objets && !objets.has(s.heldItemId)) {
            pb.push(`${f} slot ${idx} : objet ${s.heldItemId} inexistant dans ce jeu`);
          }
        }
        s.moves.forEach((m, k) => {
          if (m && !ref.attaques.has(m)) pb.push(`${f} slot ${idx} : attaque ${k + 1} = ${m} inconnue`);
          if (dex && m && !dex.moves.has(m)) pb.push(`${f} slot ${idx} : attaque ${m} absente du dex du site`);
        });
        if (dex && !dex.pokemon.has(s.speciesId)) {
          pb.push(`${f} slot ${idx} : espece ${s.speciesId} absente du dex du site`);
        }
        if (dex && s.heldItemId && !dex.items.has(s.heldItemId)) {
          pb.push(`${f} slot ${idx} : objet ${s.heldItemId} absent du dex du site`);
        }
      });
    }
  }

  // trainer_data : le visualiseur y lit la classe du dresseur et les QUATRE
  // objets de son sac (0x04, 0x06, 0x08, 0x0A). Ces champs ne sont couverts par
  // aucun autre controle : un objet de sac inexistant donnerait une ligne vide
  // dans la fiche du dresseur.
  if (fs.existsSync(r.dataDir)) {
    for (const f of fs.readdirSync(r.dataDir)) {
      const b = fs.readFileSync(path.join(r.dataDir, f));
      if (b.length < 0x0C) continue;
      for (const o of [0x04, 0x06, 0x08, 0x0A]) {
        const it = u16(b, o);
        if (!it) continue;
        compte.sac++;
        if (objets && !objets.has(it)) {
          pb.push(`${f} : objet de sac ${it} inexistant dans ce jeu`);
        } else if (dex && !dex.items.has(it)) {
          pb.push(`${f} : objet de sac ${it} absent du dex du site`);
        }
      }
    }
  }

  return { nom, pb, compte };
}

function main() {
  const [vanilla, lot] = process.argv.slice(2);
  if (!vanilla || !lot) {
    console.error('usage: node tools/verify-viewer-compat.js <romfs-vanilla> <dossier-du-lot> [<racine-du-site>]');
    process.exit(2);
  }
  const projet = path.resolve(__dirname, '..');
  const ref = referentiel(vanilla);
  const objets = objetsConnus(projet);
  const site = process.argv[4] || '';
  const dex = site ? dexDuSite(site) : null;
  console.log('referentiel mesure sur le dump vanilla :');
  console.log(`  especes reelles ${ref.especes.size}, type max ${ref.typeMax}, talent max ${ref.abilMax}, attaques connues ${ref.attaques.size}`);
  console.log(`  objets connus (items.csv) : ${objets ? objets.size : 'items.csv absent'}`);
  if (dex) {
    console.log(`  dex du site : ${dex.pokemon.size} Pokemon, ${dex.moves.size} attaques, ${dex.items.size} objets, ${dex.abilities.size} talents`);
  }
  console.log('');

  const dossiers = fs.readdirSync(lot).filter(d => fs.statSync(path.join(lot, d)).isDirectory()).sort();
  let total = 0;
  for (const d of dossiers) {
    const r = verifier(d, path.join(lot, d), ref, objets, dex);
    total += r.pb.length;
    const detail = `${r.compte.especes} especes, ${r.compte.slots} slots, ${r.compte.attaques} paliers, ${r.compte.objets} tenus, ${r.compte.sac} en sac`;
    if (r.pb.length === 0) {
      console.log(`  OK    ${d.padEnd(14)} ${detail}`);
    } else {
      console.log(`  ECHEC ${d.padEnd(14)} ${r.pb.length} probleme(s) | ${detail}`);
      const vus = new Map();
      for (const p of r.pb) {
        const cle = p.replace(/\d+/g, 'N');
        vus.set(cle, (vus.get(cle) || 0) + 1);
      }
      [...vus.entries()].sort((a, b) => b[1] - a[1]).slice(0, 4)
        .forEach(([k, n]) => console.log(`          ${String(n).padStart(5)} x ${k}`));
      r.pb.slice(0, 2).forEach(p => console.log(`          ex: ${p}`));
    }
  }
  console.log('');
  console.log(total === 0
    ? `Toutes les sorties se relisent avec le decodage du visualiseur (${dossiers.length} lots).`
    : `${total} probleme(s) au total sur ${dossiers.length} lots.`);
  process.exit(total === 0 ? 0 : 1);
}

main();
