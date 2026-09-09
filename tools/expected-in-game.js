#!/usr/bin/env node
/*
 * Dit ce qu'on DOIT observer en jeu, avec des valeurs concretes.
 *
 * Pourquoi cet outil
 * ------------------
 * Un test en jeu du genre « le cadeau doit etre different » ne se conclut pas :
 * different de quoi, et comment savoir si c'est le bon different ? Ce script lit
 * une sortie du generateur et imprime la liste de ce qui devrait apparaitre a
 * l'ecran - noms compris. On coche, ou on ne coche pas.
 *
 * Les noms viennent du dex du visualiseur PokeFeur, qui est deja sur la machine.
 * Aucun catalogue n'est recopie ici.
 *
 * Usage
 * -----
 *   node tools/expected-in-game.js <sortie> [<racine-du-site>] [<romfs-vanilla>]
 *
 *   <sortie>  le dossier produit par le generateur (celui qui contient romfs/)
 */
'use strict';

const fs = require('fs');
const path = require('path');

const PROJET = path.resolve(__dirname, '..');
const PERSONAL = 0xB0, LEARNSET = 0x104, POKE = 0x20;
const u16 = (b, o) => b.readUInt16LE(o);

function dex(racineSite) {
  const f = path.join(racineSite, 'assets', 'js', 'local-dex-data.js');
  if (!fs.existsSync(f)) return null;
  const w = {};
  new Function('window', fs.readFileSync(f, 'utf8'))(w);
  const d = w.LOCAL_DEX_DATA || {};
  const index = coll => {
    const m = new Map();
    for (const v of Object.values(coll || {})) {
      // Premier arrive gagne, comme le fait le pont du site. Sur ce dex, les
      // identifiants 237 et 1000 sont partages par 17 et 33 entrees.
      if (Number.isFinite(v.id) && !m.has(v.id)) m.set(v.id, v);
    }
    return m;
  };
  return { moves: index(d.moves), items: index(d.items), pokemon: index(d.pokemon), abilities: index(d.abilities) };
}

function nom(map, id, prefixe) {
  if (!id) return '-';
  const e = map && map.get(id);
  return e ? (e.nameFr || e.nameEn) : `${prefixe} ${id}`;
}

// Les OBJETS ne passent pas par le dex : son espace d'identifiants n'est pas
// celui du jeu. Verifie sur trois ancres tirees de la table CT/DT du jeu -
// objet 1230 = CT00 mais le dex dit « DT42 », 1130 = DT00 mais « Bonbon
// Artikodin », 1229 = DT99 mais « DT41 ». Les especes et les attaques, elles,
// concordent. On affiche donc l'identifiant et sa poche, qui sont mesures.
const POCHES = { 5: 'CT/DT', 8: 'objet cle', 32: 'soin', 33: 'Ball' };
function nomObjet(noms, poches, id) {
  if (!id) return '-';
  const p = poches ? poches[id] : undefined;
  const n = noms && noms[id];
  const etiquette = n ? `${n} (${id})` : `objet ${id}`;
  if (p === undefined) return `${etiquette} — ABSENT DU JEU !`;
  return POCHES[p] ? `${etiquette} [${POCHES[p]}]` : etiquette;
}

// Noms tires du JEU (bin/message), pas d'un catalogue externe : c'est
// tools/build-name-tables.py qui les extrait. Le dex du visualiseur ne peut pas
// servir ici - son espace d'identifiants d'objets n'est pas celui du jeu.
function nomsDuJeu(fichier, colonne) {
  const m = {};
  for (const r of csv(path.join(PROJET, fichier))) {
    if (+r.local_language_id === 5) m[+r[colonne]] = r.name;
  }
  return Object.keys(m).length ? m : null;
}

function csv(f) {
  if (!fs.existsSync(f)) return [];
  const l = fs.readFileSync(f, 'utf8').split(/\r?\n/).filter(Boolean);
  const cles = l[0].split(',');
  return l.slice(1).map(x => {
    const c = x.split(',');
    return Object.fromEntries(cles.map((k, i) => [k, c[i]]));
  });
}

// --- codec AMX compact 64 bits, identique a celui du generateur -------------
function cellulesAmx(chemin) {
  const d = fs.readFileSync(chemin);
  const size = d.readUInt32LE(0), cod = d.readUInt32LE(0x0C);
  if (size !== d.length) return null;
  const comp = d.slice(cod, size);
  const out = [];
  let i = comp.length;
  while (i > 0) {
    let c = 0n, sh = 0n;
    for (;;) {
      i--;
      c |= BigInt(comp[i] & 0x7F) << sh; sh += 7n;
      if (i === 0 || (comp[i - 1] & 0x80) === 0) break;
    }
    if (comp[i] & 0x40) { while (sh < 64n) { c |= 0xFFn << sh; sh += 8n; } }
    out.push(c & 0xFFFFFFFFFFFFFFFFn);
  }
  out.reverse();
  return out;
}

function main() {
  const sortie = process.argv[2];
  const site = process.argv[3] || 'C:/Users/Jonatan/Downloads/PokeFeur-main/PokeFeur-main';
  const vanilla = process.argv[4] || 'C:/Users/Jonatan/Documents/Sword/romfs';
  if (!sortie) {
    console.error('usage: node tools/expected-in-game.js <sortie> [<racine-site>] [<romfs-vanilla>]');
    process.exit(2);
  }
  const R = fs.existsSync(path.join(sortie, 'romfs')) ? path.join(sortie, 'romfs') : sortie;
  const D = dex(site);
  const poches = {};
  for (const r of csv(path.join(PROJET, 'items.csv'))) poches[+r.id] = +r.category_id;
  const NOMS = {
    objets: nomsDuJeu('item_names.csv', 'item_id'),
    attaques: nomsDuJeu('move_names.csv', 'move_id'),
    especes: nomsDuJeu('pokemon_species_names.csv', 'pokemon_species_id'),
  };
  const nomJeu = (t, id, prefixe) => (NOMS[t] && NOMS[t][id]) ? NOMS[t][id] : `${prefixe} ${id}`;
  const q = (...s) => path.join(R, ...s);
  const V = (...s) => path.join(vanilla, ...s);

  console.log('A OBSERVER EN JEU');
  console.log('sortie : ' + R);
  console.log('noms   : extraits du JEU par tools/build-name-tables.py' +
              (NOMS.objets ? '' : '  [MANQUANTS - lance build-name-tables.py]'));

  // --- 1. Cadeaux des PNJ ---------------------------------------------------
  const donneurs = csv(path.join(PROJET, 'npc-gifts-donneurs.csv'));
  const cat = csv(path.join(PROJET, 'npc-gifts.csv'));
  const amxDir = q('bin', 'script', 'amx');
  if (cat.length && fs.existsSync(amxDir)) {
    console.log('\n1. CADEAUX DES PNJ');
    const cache = new Map();
    let n = 0, cles = 0;
    for (const e of cat) {
      const f = path.join(amxDir, e.amx);
      if (!fs.existsSync(f)) continue;
      if (!cache.has(e.amx)) cache.set(e.amx, cellulesAmx(f));
      const cel = cache.get(e.amx);
      if (!cel) continue;
      const v = cel[+e.cellule];
      if ((v & 0xFFFFFFFFn) !== 0xBCn) continue;
      const neuf = Number((v >> 32n) & 0xFFFFFFFFn);
      const meta = donneurs.find(x => x.amx === e.amx && +x.cellule === +e.cellule) || {};
      const inchange = neuf === +e.item_id;
      if (inchange) { cles++; continue; }
      if (n++ < 12) {
        console.log(`   ${(meta.donneur || '?').padEnd(18)} ${(meta.lieu || '').padEnd(20)} ${(meta.objet_vanilla || '').padEnd(18)} -> ${nomObjet(NOMS.objets, poches, neuf)}`);
      }
    }
    console.log(`   ... ${n} cadeaux changes au total, ${cles} inchanges (dont les objets cles, qui DOIVENT l'etre)`);
  }

  // --- 2. CT et DT ----------------------------------------------------------
  const itemDat = q('bin', 'pml', 'item', 'item.dat');
  if (fs.existsSync(itemDat)) {
    const d = fs.readFileSync(itemDat);
    const off = 0x44 + d.readUInt16LE(2) * 2;
    const dv = fs.existsSync(V('bin/pml/item/item.dat')) ? fs.readFileSync(V('bin/pml/item/item.dat')) : null;
    const offv = dv ? 0x44 + dv.readUInt16LE(2) * 2 : 0;
    console.log('\n2. CT ET DT  (ouvre le sac, onglet CT)');
    for (const i of [0, 1, 2, 3, 100, 101]) {
      const mv = u16(d, off + i * 4 + 2);
      const av = dv ? u16(dv, offv + i * 4 + 2) : 0;
      const etiquette = i === 0 ? 'CT00' : (i < 100 ? 'CT' + String(i).padStart(2, '0') : 'DT' + String(i - 100).padStart(2, '0'));
      console.log(`   ${etiquette} : ${nomJeu('attaques', av, 'attaque')} -> ${nomJeu('attaques', mv, 'attaque')}`);
    }
  }

  // --- 2 bis. Prix des objets ----------------------------------------------
  // ShopPriceMultiplier ecrit un u32 au debut de chaque enregistrement
  // d'objet, dans le MEME fichier que la table CT/DT. Aucun test automatique
  // ne le couvre : c'est un des points a verifier en boutique.
  if (fs.existsSync(itemDat) && fs.existsSync(V('bin/pml/item/item.dat'))) {
    const d = fs.readFileSync(itemDat);
    const dv = fs.readFileSync(V('bin/pml/item/item.dat'));
    const rec = (b) => ({ off: b.readUInt32LE(0x40), idx: 0x44 });
    const prixDe = (b, id) => {
      const r = rec(b);
      const n = b.readUInt16LE(r.idx + id * 2);
      if (!n) return null;
      return b.readUInt32LE(r.off + n * 48);
    };
    const echantillon = [4, 17, 25, 236, 538, 1230];
    const lignes = [];
    let changes = 0, total = 0;
    for (let id = 1; id < 1608; id++) {
      const a = prixDe(dv, id), b2 = prixDe(d, id);
      if (a === null || b2 === null || a === 0) continue;
      total++;
      if (a !== b2) changes++;
    }
    console.log('\n2 bis. PRIX DES OBJETS  (ouvre une boutique)');
    console.log(`   ${changes} prix modifies sur ${total} objets achetables`);
    for (const id of echantillon) {
      const a = prixDe(dv, id), b2 = prixDe(d, id);
      if (a === null || b2 === null) continue;
      lignes.push(`   ${nomObjet(NOMS.objets, poches, id).padEnd(34)} ${a} -> ${b2}`);
    }
    lignes.forEach(l => console.log(l));
  }

  // --- 3. Attaques apprises -------------------------------------------------
  const lf = q('bin', 'pml', 'waza_oboe', 'wazaoboe_total.bin');
  if (fs.existsSync(lf)) {
    const b = fs.readFileSync(lf);
    console.log('\n3. ATTAQUES APPRISES  (monte le Pokemon d un niveau)');
    for (const [id, appellation] of [[810, 'Ouistempo'], [813, 'Flambino'], [816, 'Larmeleon']]) {
      const base = id * LEARNSET;
      if (base + LEARNSET > b.length) continue;
      const paliers = [];
      for (let c = 0; c < LEARNSET; c += 4) {
        const m = u16(b, base + c), l = u16(b, base + c + 2);
        if (m === 0xFFFF && l === 0xFFFF) break;
        if (m) paliers.push(`Niv.${l} ${nomJeu('attaques', m, 'attaque')}`);
      }
      console.log(`   ${appellation.padEnd(12)} ${paliers.slice(0, 5).join('  |  ')}`);
    }
  }

  // --- 4. Maitres de capacites ---------------------------------------------
  const pf = q('bin', 'pml', 'personal', 'personal_total.bin');
  if (fs.existsSync(pf)) {
    const b = fs.readFileSync(pf);
    let reels = 0, complets = 0;
    for (let i = 0; i + PERSONAL <= b.length; i += PERSONAL) {
      let somme = 0;
      for (let o = 0; o < 6; o++) somme += b[i + o];
      if (!somme) continue;
      reels++;
      if (b[i + 0xA8] === 0xFF && b[i + 0xA9] === 0xFF && (b[i + 0xAA] & 3) === 3) complets++;
    }
    console.log('\n4. MAITRES DE CAPACITES  (Ile solitaire de l Armure)');
    console.log(`   ${complets} especes sur ${reels} acceptent les 18 maitres`);
  }

  // --- 5. Caps d EXP --------------------------------------------------------
  const toml = [path.join(sortie, 'sdmc', 'config', 'swsh-mods-exl', 'config.toml')].find(fs.existsSync);
  if (toml) {
    const t = fs.readFileSync(toml, 'utf8');
    const m = /story_caps\s*=\s*\[([^\]]*)\]/.exec(t);
    const actif = /\[exp_level_cap\][\s\S]*?active\s*=\s*(\w+)/.exec(t);
    console.log('\n5. CAPS D EXP  (config.toml present : le module est deploye)');
    console.log(`   actif : ${actif ? actif[1] : '?'}`);
    if (m) console.log(`   paliers par badge : ${m[1].trim()}`);
    console.log('   -> avec 0 badge, un Pokemon ne doit pas depasser le premier palier.');
  } else {
    console.log('\n5. CAPS D EXP : config.toml absent - le module n a pas ete deploye (ExeFS non fourni ?)');
  }
  console.log('');
}

main();
