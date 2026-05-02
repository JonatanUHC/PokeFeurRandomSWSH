#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");
const https = require("https");
const http = require("http");

const SMOGON_ROOT = "https://www.smogon.com/dex/";
const SMOGON_BASE = `${SMOGON_ROOT}ss/pokemon/`;
const SHOWDOWN_BASE = "https://play.pokemonshowdown.com/data/";
const POKEFEUR_VIEWER_URL = "https://jonatanuhc.github.io/PokeFeur/trainer_viewer_6_1.html?lang=fr";
const POKEFEUR_LOCAL_DEX_FALLBACK_URL = "https://jonatanuhc.github.io/PokeFeur/assets/js/local-dex-data.js";
const USER_AGENT = "PokeFeurRandomSWSH/1.0 (+Smogon Strategy Dex cache builder)";
const CACHE_VERSION = 6;
const BASE_SPECIES_MAX = 898;
const SMOGON_GENERATIONS = [
  { id: "ss", name: "Sword/Shield", generation: 8 },
  { id: "sm", name: "Sun/Moon", generation: 7 },
  { id: "xy", name: "X/Y", generation: 6 },
  { id: "bw", name: "Black/White", generation: 5 },
  { id: "dp", name: "Diamond/Pearl", generation: 4 },
  { id: "rs", name: "Ruby/Sapphire", generation: 3 },
  { id: "gs", name: "Gold/Silver", generation: 2 },
  { id: "rb", name: "Red/Blue", generation: 1 },
];

const NATURE_IDS = {
  hardy: 0,
  lonely: 1,
  brave: 2,
  adamant: 3,
  naughty: 4,
  bold: 5,
  docile: 6,
  relaxed: 7,
  impish: 8,
  lax: 9,
  timid: 10,
  hasty: 11,
  serious: 12,
  jolly: 13,
  naive: 14,
  modest: 15,
  mild: 16,
  quiet: 17,
  bashful: 18,
  rash: 19,
  calm: 20,
  gentle: 21,
  sassy: 22,
  careful: 23,
  quirky: 24,
};

function parseArgs(argv) {
  const options = {
    repoRoot: process.cwd(),
    strategicOut: "",
    recommendationsOut: "",
    legacyStrategicOut: "",
    legacyRecommendationsOut: "",
    concurrency: 8,
  };

  for (let i = 2; i < argv.length; i++) {
    const arg = argv[i];
    const next = argv[i + 1];
    if (arg === "--repo-root" && next) {
      options.repoRoot = next;
      i++;
    } else if (arg === "--strategic-out" && next) {
      options.strategicOut = next;
      i++;
    } else if (arg === "--recommendations-out" && next) {
      options.recommendationsOut = next;
      i++;
    } else if (arg === "--legacy-strategic-out" && next) {
      options.legacyStrategicOut = next;
      i++;
    } else if (arg === "--legacy-recommendations-out" && next) {
      options.legacyRecommendationsOut = next;
      i++;
    } else if (arg === "--concurrency" && next) {
      options.concurrency = Math.max(1, Math.min(16, Number.parseInt(next, 10) || 8));
      i++;
    }
  }

  if (!options.strategicOut) {
    options.strategicOut = path.join(options.repoRoot, "cache", "smogon-strategic-gen8.json");
  }
  if (!options.recommendationsOut) {
    options.recommendationsOut = path.join(options.repoRoot, "cache", "smogon-showdown-swsh-recommendations.json");
  }
  if (!options.legacyStrategicOut) {
    options.legacyStrategicOut = path.join(options.repoRoot, "cache", "smogon-strategic-latest-history.json");
  }
  if (!options.legacyRecommendationsOut) {
    options.legacyRecommendationsOut = path.join(options.repoRoot, "cache", "smogon-showdown-latest-history-recommendations.json");
  }
  return options;
}

function ensureDir(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function fetchText(url, redirectsLeft = 4) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith("http://") ? http : https;
    const req = client.get(
      url,
      {
        headers: {
          "user-agent": USER_AGENT,
          "accept": "text/html,application/javascript,text/javascript,*/*",
        },
      },
      (res) => {
        const status = res.statusCode || 0;
        const location = res.headers.location;
        if (status >= 300 && status < 400 && location && redirectsLeft > 0) {
          res.resume();
          const nextUrl = new URL(location, url).toString();
          fetchText(nextUrl, redirectsLeft - 1).then(resolve, reject);
          return;
        }

        let body = "";
        res.setEncoding("utf8");
        res.on("data", (chunk) => {
          body += chunk;
        });
        res.on("end", () => {
          if (status < 200 || status >= 300) {
            reject(new Error(`HTTP ${status} for ${url}`));
            return;
          }
          resolve({ url, finalUrl: res.responseUrl || url, status, body });
        });
      },
    );
    req.setTimeout(30000, () => {
      req.destroy(new Error(`Timeout for ${url}`));
    });
    req.on("error", reject);
  });
}

async function fetchTextWithRetry(url, attempts = 3) {
  let lastError = null;
  for (let attempt = 1; attempt <= attempts; attempt++) {
    try {
      return await fetchText(url);
    } catch (error) {
      lastError = error;
      if (attempt < attempts) {
        await sleep(500 * attempt);
      }
    }
  }
  throw lastError;
}

function parseDexSettings(html, sourceUrl) {
  const marker = "dexSettings = ";
  const start = html.indexOf(marker);
  if (start < 0) {
    throw new Error(`dexSettings absent from ${sourceUrl}`);
  }
  const scriptEnd = html.indexOf("</script>", start);
  if (scriptEnd < 0) {
    throw new Error(`dexSettings script end absent from ${sourceUrl}`);
  }
  const raw = html.slice(start + marker.length, scriptEnd).trim().replace(/;$/, "");
  return JSON.parse(raw);
}

function getRpc(settings, needle) {
  for (const rpc of settings.injectRpcs || []) {
    const request = Array.isArray(rpc) ? rpc[0] : null;
    if (String(request).includes(needle)) {
      return Array.isArray(rpc) ? rpc[1] : null;
    }
  }
  return null;
}

function toShowdownId(value) {
  return String(value || "").toLowerCase().replace(/[^a-z0-9]+/g, "");
}

function toUrlAlias(value) {
  return String(value || "")
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[’']/g, "")
    .replace(/\./g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function uniqueSortedNumbers(values) {
  return [...new Set(values.filter((value) => Number.isInteger(value) && value > 0))].sort((a, b) => a - b);
}

function uniqueStrings(values) {
  const seen = new Set();
  const output = [];
  for (const value of values || []) {
    const text = String(value || "").trim();
    if (!text) {
      continue;
    }
    const key = text.toLowerCase();
    if (seen.has(key)) {
      continue;
    }
    seen.add(key);
    output.push(text);
  }
  return output;
}

function readNumericIndexFromShowdownJs(text) {
  const index = {};
  const keyRegex = /(?:^|[,{])\s*([A-Za-z0-9]+):\{/g;
  let match;
  while ((match = keyRegex.exec(text))) {
    const key = match[1].toLowerCase();
    const start = match.index;
    const snippet = text.slice(start, start + 3000);
    const numMatch = /(?:^|[,{])\s*num:(-?\d+)/.exec(snippet);
    if (!numMatch) {
      continue;
    }
    const num = Number.parseInt(numMatch[1], 10);
    if (num > 0 && index[key] === undefined) {
      index[key] = num;
    }
  }
  return index;
}

function readPokeFeurLocalDexData(text, sourceUrl) {
  const marker = "window.LOCAL_DEX_DATA =";
  const start = text.indexOf(marker);
  if (start < 0) {
    throw new Error(`LOCAL_DEX_DATA absent from ${sourceUrl}`);
  }

  let raw = text.slice(start + marker.length).trim();
  if (raw.endsWith(";")) {
    raw = raw.slice(0, -1).trim();
  }
  return JSON.parse(raw);
}

function buildPokeFeurItemIndex(localDex) {
  const index = {};
  for (const entry of Object.values(localDex?.items || {})) {
    const id = Number.parseInt(entry?.id, 10);
    if (!Number.isInteger(id) || id <= 0) {
      continue;
    }

    for (const value of [entry.slug, entry.nameEn, entry.nameFr]) {
      const key = toShowdownId(value);
      if (key && index[key] === undefined) {
        index[key] = id;
      }
    }
  }
  return index;
}

async function fetchPokeFeurItemIndex() {
  let localDexUrl = POKEFEUR_LOCAL_DEX_FALLBACK_URL;
  try {
    const viewer = await fetchTextWithRetry(POKEFEUR_VIEWER_URL, 2);
    const match = /<script\s+src=["']([^"']*assets\/js\/local-dex-data\.js[^"']*)["']/i.exec(viewer.body);
    if (match) {
      localDexUrl = new URL(match[1], POKEFEUR_VIEWER_URL).toString();
    }
  } catch {
    localDexUrl = POKEFEUR_LOCAL_DEX_FALLBACK_URL;
  }

  const localDexJs = await fetchTextWithRetry(localDexUrl, 3);
  const localDex = readPokeFeurLocalDexData(localDexJs.body, localDexUrl);
  const index = buildPokeFeurItemIndex(localDex);
  return {
    index,
    sourceUrl: localDexUrl,
    count: Object.keys(index).length,
  };
}

function indexBasicsByName(rows) {
  const output = {};
  for (const row of rows || []) {
    output[toShowdownId(row.name)] = row;
  }
  return output;
}

function idsFromNames(names, index) {
  return uniqueSortedNumbers(uniqueStrings(names).map((name) => index[toShowdownId(name)] || 0));
}

function evSpreadToArray(evs) {
  if (!evs || typeof evs !== "object") {
    return [];
  }
  const keys = ["hp", "atk", "def", "spa", "spd", "spe"];
  const values = keys.map((key) => Math.max(0, Math.min(252, Number.parseInt(evs[key] || 0, 10) || 0)));
  const total = values.reduce((sum, value) => sum + value, 0);
  if (total <= 0) {
    return [];
  }
  if (total <= 510) {
    return values;
  }

  const scaled = values.map((value) => Math.min(252, Math.floor((value * 510) / total)));
  let remaining = 510 - scaled.reduce((sum, value) => sum + value, 0);
  const order = values
    .map((value, index) => ({ index, fraction: ((value * 510) / total) % 1 }))
    .sort((a, b) => b.fraction - a.fraction);
  while (remaining > 0) {
    let changed = false;
    for (const entry of order) {
      if (scaled[entry.index] < 252) {
        scaled[entry.index]++;
        remaining--;
        changed = true;
        if (remaining <= 0) {
          break;
        }
      }
    }
    if (!changed) {
      break;
    }
  }
  return scaled;
}

function getFirstSpread(spreads) {
  for (const spread of spreads || []) {
    const values = evSpreadToArray(spread);
    if (values.length) {
      return values;
    }
  }
  return [];
}

function flattenMoveSlot(slot) {
  const names = [];
  const collect = (value) => {
    if (!value) {
      return;
    }
    if (typeof value === "string") {
      names.push(value);
      return;
    }
    if (Array.isArray(value)) {
      for (const entry of value) {
        collect(entry);
      }
      return;
    }
    if (typeof value === "object") {
      if (typeof value.move === "string") {
        names.push(value.move);
      } else if (typeof value.name === "string") {
        names.push(value.name);
      } else if (value.moves) {
        collect(value.moves);
      }
    }
  };
  collect(slot);
  return uniqueStrings(names);
}

function normalizeMoveset(raw, indexes, basicsByName) {
  const itemNames = uniqueStrings(raw.items || raw.item || []);
  const abilityNames = uniqueStrings(raw.abilities || raw.ability || []);
  const natureNames = uniqueStrings(raw.natures || raw.nature || []);
  const evConfigs = Array.isArray(raw.evconfigs) ? raw.evconfigs : raw.evs ? [raw.evs] : [];
  const ivConfigs = Array.isArray(raw.ivconfigs) ? raw.ivconfigs : raw.ivs ? [raw.ivs] : [];
  const moveSlotsRaw = Array.isArray(raw.moveslots) ? raw.moveslots : raw.moves ? raw.moves : [];
  const moveSlots = moveSlotsRaw.map(flattenMoveSlot).filter((slot) => slot.length > 0);

  return {
    name: String(raw.name || "Set"),
    pokemon: raw.pokemon || null,
    items: itemNames.map((name) => ({ name, itemId: indexes.items[toShowdownId(name)] || null })),
    abilities: abilityNames.map((name) => ({ name, abilityId: indexes.abilities[toShowdownId(name)] || null })),
    natures: natureNames.map((name) => ({ name, natureId: NATURE_IDS[toShowdownId(name)] ?? null })),
    evs: evConfigs,
    ivs: ivConfigs,
    levels: Array.isArray(raw.levels) ? raw.levels : [],
    moveslots: moveSlots.map((slot) =>
      slot.map((name) => {
        const moveId = indexes.moves[toShowdownId(name)] || null;
        const moveInfo = basicsByName.moves[toShowdownId(name)] || null;
        return {
          name,
          moveId,
          type: moveInfo ? moveInfo.type || null : null,
          category: moveInfo ? moveInfo.category || null : null,
        };
      }),
    ),
  };
}

function normalizeStrategy(raw, indexes, basicsByName, formeName = null) {
  const movesets = Array.isArray(raw.movesets)
    ? raw.movesets.map((set) => normalizeMoveset(set, indexes, basicsByName))
    : [];
  return {
    format: String(raw.format || ""),
    forme: formeName,
    sets: movesets,
  };
}

function buildStrategicSets(strategies, indexes) {
  const sets = [];
  for (const strategy of strategies || []) {
    for (const moveset of strategy.sets || []) {
      const moveChoices = (moveset.moveslots || [])
        .map((slot) => idsFromNames(slot.map((move) => move.name), indexes.moves))
        .filter((ids) => ids.length > 0);
      const items = idsFromNames((moveset.items || []).map((item) => item.name), indexes.items);
      const abilities = idsFromNames((moveset.abilities || []).map((ability) => ability.name), indexes.abilities);
      const natures = uniqueSortedNumbers((moveset.natures || []).map((nature) => nature.natureId || 0));
      const evs = getFirstSpread(moveset.evs || []);

      if (!moveChoices.length && !items.length && !abilities.length && !natures.length && !evs.length) {
        continue;
      }

      sets.push({
        name: [strategy.format, moveset.name].filter(Boolean).join(" / ") || "Set",
        moveChoices,
        items,
        abilities,
        natures,
        evs,
      });
    }
  }
  return sets;
}

function smogonPokemonUrl(generationId, alias) {
  return `${SMOGON_ROOT}${generationId}/pokemon/${alias}/`;
}

function hasStrategySets(entry) {
  return (entry?.strategies || []).some((strategy) => (strategy.sets || []).length > 0);
}

function aggregateStrategicEntry(name, sets, source = {}) {
  const moves = [];
  const items = [];
  const abilities = [];
  const natures = [];
  for (const set of sets || []) {
    for (const group of set.moveChoices || []) {
      moves.push(...group);
    }
    items.push(...(set.items || []));
    abilities.push(...(set.abilities || []));
    natures.push(...(set.natures || []));
  }
  return {
    name,
    moves: uniqueSortedNumbers(moves),
    items: uniqueSortedNumbers(items),
    abilities: uniqueSortedNumbers(abilities),
    natures: uniqueSortedNumbers(natures),
    sourceGeneration: source.generationId || null,
    sourceGenerationName: source.generationName || null,
    sourceGenerationNumber: source.generationNumber || null,
    sourceUrl: source.url || null,
    sets,
  };
}

function isSwordShieldShowdownPokemon(pokemon) {
  if (!pokemon || (pokemon.isNonstandard !== "Standard" && pokemon.isNonstandard !== "NatDex")) {
    return false;
  }
  const oob = pokemon.oob || null;
  if (oob && oob.dex_number > 0 && Array.isArray(oob.genfamily) && oob.genfamily.includes("SS")) {
    return true;
  }
  return !oob && Array.isArray(pokemon.formats) && pokemon.formats.length > 0;
}

async function fetchPokemonPage(pokemon, indexes, basicsByName, generation = SMOGON_GENERATIONS[0]) {
  const alias = toUrlAlias(pokemon.name);
  const url = smogonPokemonUrl(generation.id, alias);
  const result = {
    name: pokemon.name,
    alias,
    dexNumber: pokemon.oob && pokemon.oob.dex_number > 0 ? pokemon.oob.dex_number : null,
    sourceGeneration: generation.id,
    sourceGenerationName: generation.name,
    sourceGenerationNumber: generation.generation,
    isNonstandard: pokemon.isNonstandard || null,
    formats: pokemon.formats || [],
    types: pokemon.types || [],
    abilities: pokemon.abilities || [],
    smogonUrl: url,
    pageStatus: "unfetched",
    strategies: [],
    formeStrategies: [],
  };

  try {
    const response = await fetchTextWithRetry(url);
    const settings = parseDexSettings(response.body, url);
    const pokemonRpc = getRpc(settings, "dump-pokemon");
    if (!pokemonRpc) {
      throw new Error("dump-pokemon RPC missing");
    }

    result.pageStatus = "ok";
    result.finalUrl = response.finalUrl || url;
    result.pageVerified = true;
    result.strategies = (pokemonRpc.strategies || []).map((strategy) => normalizeStrategy(strategy, indexes, basicsByName));
    result.formeStrategies = (pokemonRpc.formeStrategies || []).map((forme) => ({
      forme: forme.forme || null,
      strategies: (forme.strategies || []).map((strategy) => normalizeStrategy(strategy, indexes, basicsByName, forme.forme || null)),
    }));
  } catch (error) {
    result.pageStatus = "failed";
    result.pageVerified = false;
    result.error = error.message;
  }

  return result;
}

function buildSpeciesOutputFromResolvedEntries(entries, indexes) {
  const speciesOutput = {};

  for (const entry of entries) {
    if (!entry?.dexNumber || entry.dexNumber <= 0 || entry.dexNumber > BASE_SPECIES_MAX || entry.pageStatus !== "ok") {
      continue;
    }

    const sets = buildStrategicSets(entry.strategies || [], indexes);
    if (!sets.length) {
      continue;
    }

    const outputKey = String(entry.dexNumber);
    const incomingLooksLikeForm = String(entry.name).includes("-");
    if (speciesOutput[outputKey]) {
      const existingLooksLikeForm = String(speciesOutput[outputKey].name || "").includes("-");
      if (!existingLooksLikeForm && incomingLooksLikeForm) {
        continue;
      }
    }

    speciesOutput[outputKey] = aggregateStrategicEntry(entry.name, sets, {
      generationId: entry.sourceGeneration || null,
      generationName: entry.sourceGenerationName || null,
      generationNumber: entry.sourceGenerationNumber || null,
      url: entry.smogonUrl || entry.finalUrl || null,
    });
  }

  return speciesOutput;
}

function computeStrategicStats(speciesOutput) {
  const stats = {
    species: 0,
    moves: 0,
    items: 0,
    abilities: 0,
    sets: 0,
  };

  for (const entry of Object.values(speciesOutput)) {
    stats.species++;
    stats.moves += entry.moves.length;
    stats.items += entry.items.length;
    stats.abilities += entry.abilities.length;
    stats.sets += entry.sets.length;
  }

  return stats;
}

async function mapWithConcurrency(items, concurrency, worker) {
  const results = new Array(items.length);
  let nextIndex = 0;
  const workers = Array.from({ length: concurrency }, async () => {
    while (nextIndex < items.length) {
      const current = nextIndex++;
      results[current] = await worker(items[current], current);
    }
  });
  await Promise.all(workers);
  return results;
}

async function main() {
  const options = parseArgs(process.argv);
  const generatedAt = new Date().toISOString();

  console.error("Downloading Smogon Strategy Dex basics...");
  const yveltalPage = await fetchTextWithRetry(`${SMOGON_BASE}yveltal/`);
  const settings = parseDexSettings(yveltalPage.body, `${SMOGON_BASE}yveltal/`);
  const basics = getRpc(settings, "dump-basics");
  if (!basics) {
    throw new Error("Smogon dump-basics RPC missing");
  }

  console.error("Downloading Pokemon Showdown numeric indexes...");
  const [pokedexJs, movesJs, itemsJs, abilitiesJs] = await Promise.all([
    fetchTextWithRetry(`${SHOWDOWN_BASE}pokedex.js`),
    fetchTextWithRetry(`${SHOWDOWN_BASE}moves.js`),
    fetchTextWithRetry(`${SHOWDOWN_BASE}items.js`),
    fetchTextWithRetry(`${SHOWDOWN_BASE}abilities.js`),
  ]);

  console.error("Downloading PokeFeur/PokeAPI item index for Sword/Shield item ids...");
  const pokeFeurItemIndex = await fetchPokeFeurItemIndex();
  const indexes = {
    species: readNumericIndexFromShowdownJs(pokedexJs.body),
    moves: readNumericIndexFromShowdownJs(movesJs.body),
    items: pokeFeurItemIndex.index,
    abilities: readNumericIndexFromShowdownJs(abilitiesJs.body),
  };
  const basicsByName = {
    pokemon: indexBasicsByName(basics.pokemon || []),
    moves: indexBasicsByName(basics.moves || []),
    items: indexBasicsByName(basics.items || []),
    abilities: indexBasicsByName(basics.abilities || []),
  };

  const candidates = (basics.pokemon || []).filter(isSwordShieldShowdownPokemon);
  console.error(`Fetching ${candidates.length} Smogon Pokemon pages with concurrency ${options.concurrency}...`);
  let done = 0;
  const pokemon = await mapWithConcurrency(candidates, options.concurrency, async (candidate) => {
    const entry = await fetchPokemonPage(candidate, indexes, basicsByName, SMOGON_GENERATIONS[0]);
    done++;
    if (done % 50 === 0 || done === candidates.length) {
      console.error(`  ${done}/${candidates.length}`);
    }
    return entry;
  });

  const latestHistoryEntries = [...pokemon];
  let unresolved = pokemon
    .map((entry, index) => ({ entry, index, candidate: candidates[index] }))
    .filter(({ entry }) => !hasStrategySets(entry));

  for (const generation of SMOGON_GENERATIONS.slice(1)) {
    if (!unresolved.length) {
      break;
    }

    console.error(`Fetching ${unresolved.length} fallback pages from ${generation.id.toUpperCase()}...`);
    let fallbackDone = 0;
    const fallbackEntries = await mapWithConcurrency(unresolved, options.concurrency, async (item) => {
      const entry = await fetchPokemonPage(item.candidate, indexes, basicsByName, generation);
      fallbackDone++;
      if (fallbackDone % 50 === 0 || fallbackDone === unresolved.length) {
        console.error(`  ${generation.id.toUpperCase()} ${fallbackDone}/${unresolved.length}`);
      }
      return { index: item.index, candidate: item.candidate, entry };
    });

    const stillUnresolved = [];
    for (const item of fallbackEntries) {
      if (hasStrategySets(item.entry)) {
        latestHistoryEntries[item.index] = item.entry;
      } else {
        stillUnresolved.push({ entry: item.entry, index: item.index, candidate: item.candidate });
      }
    }
    unresolved = stillUnresolved;
  }

  const speciesOutput = buildSpeciesOutputFromResolvedEntries(pokemon, indexes);
  const strategicStats = computeStrategicStats(speciesOutput);
  const legacySpeciesOutput = buildSpeciesOutputFromResolvedEntries(latestHistoryEntries, indexes);
  const legacyStrategicStats = computeStrategicStats(legacySpeciesOutput);

  const pagesOk = pokemon.filter((entry) => entry.pageStatus === "ok").length;
  const pagesFailed = pokemon.length - pagesOk;
  const pagesWithStrategies = pokemon.filter(hasStrategySets).length;
  const legacyPagesWithStrategies = latestHistoryEntries.filter(hasStrategySets).length;
  const legacyFallbackPagesUsed = latestHistoryEntries.filter((entry) => entry.sourceGeneration && entry.sourceGeneration !== "ss" && hasStrategySets(entry)).length;
  const legacyStillWithoutStrategies = latestHistoryEntries.filter((entry) => !hasStrategySets(entry)).length;
  const yveltal = pokemon.find((entry) => entry.name === "Yveltal");
  const yveltalItems = uniqueStrings(
    (yveltal?.strategies || []).flatMap((strategy) =>
      (strategy.sets || []).flatMap((set) => (set.items || []).map((item) => item.name)),
    ),
  );
  const poliwag = latestHistoryEntries.find((entry) => entry.name === "Poliwag");

  const verification = {
    smogonDexBase: SMOGON_BASE,
    yveltalSourceUrl: `${SMOGON_BASE}yveltal/`,
    yveltalPageVerified: Boolean(yveltal && yveltal.pageStatus === "ok"),
    yveltalRecommendedItems: yveltalItems,
    heavyDutyBootsItemId: indexes.items.heavydutyboots || null,
    choiceScarfItemId: indexes.items.choicescarf || null,
    whiteFluteItemId: indexes.items.whiteflute || null,
    itemIndexSource: pokeFeurItemIndex.sourceUrl,
    itemIndexCount: pokeFeurItemIndex.count,
    pagesRequested: pokemon.length,
    pagesOk,
    pagesFailed,
    pagesWithStrategies,
    latestHistorySearchOrder: SMOGON_GENERATIONS.map((generation) => generation.id),
    latestHistoryPagesWithStrategies: legacyPagesWithStrategies,
    latestHistoryFallbackPagesUsed: legacyFallbackPagesUsed,
    latestHistoryStillWithoutStrategies: legacyStillWithoutStrategies,
    poliwagLatestSourceGeneration: poliwag?.sourceGeneration || null,
    poliwagLatestSourceUrl: poliwag?.smogonUrl || null,
    poliwagLatestPageHasStrategies: hasStrategySets(poliwag),
    failedPages: pokemon
      .filter((entry) => entry.pageStatus !== "ok")
      .slice(0, 100)
      .map((entry) => ({ name: entry.name, url: entry.smogonUrl, error: entry.error || "unknown" })),
  };

  const recommendations = {
    version: CACHE_VERSION,
    generatedAt,
    generation: 8,
    game: "SwordShield",
    sourceMode: "smogon-strategy-dex-pages",
    warning: "Contains Smogon Strategy Dex recommendations. Showing this file in a viewer can spoil strategic trainer builds.",
    sources: {
      smogonDex: SMOGON_BASE,
      smogonYveltal: `${SMOGON_BASE}yveltal/`,
      showdownPokedex: `${SHOWDOWN_BASE}pokedex.js`,
      showdownMoves: `${SHOWDOWN_BASE}moves.js`,
      showdownItems: `${SHOWDOWN_BASE}items.js`,
      showdownAbilities: `${SHOWDOWN_BASE}abilities.js`,
      pokefeurLocalDexItems: pokeFeurItemIndex.sourceUrl,
    },
    stats: {
      pokemon: pokemon.length,
      pagesOk,
      pagesFailed,
      pagesWithStrategies,
    },
    verification,
    pokemon,
  };

  const legacyRecommendations = {
    version: CACHE_VERSION,
    generatedAt,
    generation: 8,
    game: "SwordShield",
    sourceMode: "smogon-strategy-dex-pages-latest-history-fallback",
    warning: "Contains Smogon Strategy Dex recommendations. SS is preferred; older generations are used only when SS has no set. Showing this file in a viewer can spoil strategic trainer builds.",
    searchOrder: SMOGON_GENERATIONS,
    sources: {
      smogonDexRoot: SMOGON_ROOT,
      smogonYveltal: `${SMOGON_BASE}yveltal/`,
      smogonPoliwagSm: `${SMOGON_ROOT}sm/pokemon/poliwag/`,
      showdownPokedex: `${SHOWDOWN_BASE}pokedex.js`,
      showdownMoves: `${SHOWDOWN_BASE}moves.js`,
      showdownItems: `${SHOWDOWN_BASE}items.js`,
      showdownAbilities: `${SHOWDOWN_BASE}abilities.js`,
      pokefeurLocalDexItems: pokeFeurItemIndex.sourceUrl,
    },
    stats: {
      pokemon: latestHistoryEntries.length,
      strictSsPagesWithStrategies: pagesWithStrategies,
      pagesWithStrategies: legacyPagesWithStrategies,
      fallbackPagesUsed: legacyFallbackPagesUsed,
      stillWithoutStrategies: legacyStillWithoutStrategies,
    },
    verification,
    pokemon: latestHistoryEntries,
  };

  const strategic = {
    version: CACHE_VERSION,
    generatedAt,
    generation: 8,
    game: "SwordShield",
    sourceMode: "smogon-strategy-dex-pages",
    sources: {
      smogonDex: SMOGON_BASE,
      smogonYveltal: `${SMOGON_BASE}yveltal/`,
      showdownPokedex: `${SHOWDOWN_BASE}pokedex.js`,
      showdownMoves: `${SHOWDOWN_BASE}moves.js`,
      showdownItems: `${SHOWDOWN_BASE}items.js`,
      showdownAbilities: `${SHOWDOWN_BASE}abilities.js`,
      pokefeurLocalDexItems: pokeFeurItemIndex.sourceUrl,
    },
    stats: strategicStats,
    verification,
    species: speciesOutput,
  };

  const legacyStrategic = {
    version: CACHE_VERSION,
    generatedAt,
    generation: 8,
    game: "SwordShield",
    sourceMode: "smogon-strategy-dex-pages-latest-history-fallback",
    searchOrder: SMOGON_GENERATIONS,
    sources: {
      smogonDexRoot: SMOGON_ROOT,
      smogonYveltal: `${SMOGON_BASE}yveltal/`,
      smogonPoliwagSm: `${SMOGON_ROOT}sm/pokemon/poliwag/`,
      showdownPokedex: `${SHOWDOWN_BASE}pokedex.js`,
      showdownMoves: `${SHOWDOWN_BASE}moves.js`,
      showdownItems: `${SHOWDOWN_BASE}items.js`,
      showdownAbilities: `${SHOWDOWN_BASE}abilities.js`,
      pokefeurLocalDexItems: pokeFeurItemIndex.sourceUrl,
    },
    stats: legacyStrategicStats,
    verification,
    species: legacySpeciesOutput,
  };

  ensureDir(options.recommendationsOut);
  ensureDir(options.strategicOut);
  ensureDir(options.legacyRecommendationsOut);
  ensureDir(options.legacyStrategicOut);
  fs.writeFileSync(options.recommendationsOut, `${JSON.stringify(recommendations, null, 2)}\n`, "utf8");
  fs.writeFileSync(options.strategicOut, `${JSON.stringify(strategic, null, 2)}\n`, "utf8");
  fs.writeFileSync(options.legacyRecommendationsOut, `${JSON.stringify(legacyRecommendations, null, 2)}\n`, "utf8");
  fs.writeFileSync(options.legacyStrategicOut, `${JSON.stringify(legacyStrategic, null, 2)}\n`, "utf8");

  console.error(`Wrote ${options.recommendationsOut}`);
  console.error(`Wrote ${options.strategicOut}`);
  console.error(`Wrote ${options.legacyRecommendationsOut}`);
  console.error(`Wrote ${options.legacyStrategicOut}`);
  console.log(
    JSON.stringify(
      {
        strategicOut: options.strategicOut,
        recommendationsOut: options.recommendationsOut,
        legacyStrategicOut: options.legacyStrategicOut,
        legacyRecommendationsOut: options.legacyRecommendationsOut,
        stats: strategicStats,
        legacyStats: legacyStrategicStats,
        verification,
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error(error && error.stack ? error.stack : String(error));
  process.exit(1);
});
