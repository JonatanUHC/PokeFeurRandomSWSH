# PokeFeur Randomizer SWSH

<div align="center">

[![Discord](https://img.shields.io/badge/Discord-Join_the_server-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/bSUKYEJE)
[![Windows](https://img.shields.io/badge/Windows_10%2F11-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://github.com)
[![PowerShell](https://img.shields.io/badge/PowerShell_5.1+-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://github.com)

[English](#english) | [Français](#français)

</div>

---

## Table of Contents / Table des matières

- [English](#english)
  - [Requirements](#requirements)
  - [Launch](#launch)
  - [What Gets Generated](#what-gets-generated)
  - [Quick Start](#quick-start)
  - [Seed](#seed)
  - [Race Mode](#race-mode)
  - [Difficulty Profiles](#difficulty-profiles)
  - [JSON Presets](#json-presets)
  - [Trainers Tab](#trainers-tab)
  - [Pokemon Tab](#pokemon-tab)
  - [Evolutions Tab](#evolutions-tab)
  - [Starters / Gifts Tab](#starters--gifts-tab)
  - [Encounters Tab](#encounters-tab)
  - [Smogon Data](#smogon-data)
  - [ExLaunch Runtime Options](#exlaunch-runtime-options)
  - [Generated JSON Reports](#generated-json-reports)
  - [PokeFeur Viewer](#pokefeur-viewer)
  - [Troubleshooting](#troubleshooting)
  - [Sources, Dependencies, and Thanks](#sources-dependencies-and-thanks)
  - [Legal Notice](#legal-notice)
- [Français](#français)
  - [Ce qu'il te faut](#ce-quil-te-faut)
  - [Lancement](#lancement)
  - [Ce que le logiciel génère](#ce-que-le-logiciel-génère)
  - [Utilisation rapide](#utilisation-rapide)
  - [Seed](#seed-1)
  - [Mode course](#mode-course)
  - [Profils de difficulté](#profils-de-difficulté)
  - [Présets JSON](#présets-json)
  - [Onglet Dresseurs](#onglet-dresseurs)
  - [Onglet Pokemon](#onglet-pokemon)
  - [Onglet Évolutions](#onglet-évolutions)
  - [Onglet Starters / Cadeaux](#onglet-starters--cadeaux)
  - [Onglet Rencontres](#onglet-rencontres)
  - [Données Smogon](#données-smogon)
  - [Options runtime ExLaunch](#options-runtime-exlaunch)
  - [Rapports JSON générés](#rapports-json-générés)
  - [Viewer PokeFeur](#viewer-pokefeur)
  - [Dépannage](#dépannage)
  - [Sources, dépendances et remerciements](#sources-dépendances-et-remerciements)
  - [Avertissement légal](#avertissement-légal)

---

<a name="english"></a>
# English

Local randomizer for **Pokemon Sword** and **Pokemon Shield**.

The tool reads your own extracted game files and writes a separate randomized output folder.

It provides **no ROMs, no game dumps, no game files, no Nintendo files, and no way to obtain them**. Nothing in this project is a substitute for buying the game and dumping your own copy.

This README intentionally documents only the randomizer and the generated output. How you use the generated folder afterward depends on your own setup and is outside this document.

## Requirements

- Windows 10 or Windows 11.
- Windows PowerShell 5.1 or newer.
- Your own `romfs` dump from a Pokemon Sword or Pokemon Shield copy that you personally own.
- Your own `exefs` dump only if you enable ExLaunch runtime options such as EXP Share control, level caps, PC runtime menu, or hidden overworld battles.
- Internet access the first time you use Smogon modes, because the tool builds a local cache from public Smogon pages and public Pokemon Showdown indexes.
- Node.js only if you manually rebuild Smogon cache files from `tools/build-smogon-dex-cache.js`.

You do not need Python or a database to launch the graphical interface.

## Launch

Double-click:

```bat
Launch-CustomSwShRandomizer.bat
```

PowerShell alternative:

```powershell
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\CustomSwShRandomizer.ps1
```

If Windows blocks the files because they came from the Internet:

```powershell
Unblock-File .\CustomSwShRandomizer.ps1
Unblock-File .\Launch-CustomSwShRandomizer.bat
```

## What Gets Generated

Example output:

```text
output/Sword/
  romfs/
  exefs/
  sdmc/
    config/swsh-mods-exl/config.toml
```

- `romfs/` contains modified files derived from your own `romfs`.
- `exefs/` is created when runtime options need ExLaunch. `main.npdm` must come from your own `exefs`; `subsdk9` is the custom project module.
- `sdmc/config/swsh-mods-exl/config.toml` stores runtime settings such as EXP Share state, EXP multiplier, level caps, and overworld battle behavior.

The generated output can contain modified Nintendo data. Do not publish or share generated `romfs`, `exefs`, `sdmc`, or full `output` folders.

## Quick Start

1. Use your own legally obtained copy of the game, then extract your own files and keep the `romfs` folder available.
2. Launch `Launch-CustomSwShRandomizer.bat`.
3. In `Original ROMFS folder`, select the `romfs` folder itself, not its parent.
4. Fill `Original ExeFS folder` only if you need ExLaunch options.
5. In `Generated mod folder`, choose a package root such as `output/Sword`, not `output/Sword/romfs`.
6. Choose Sword or Shield.
7. Pick a seed and configure the tabs.
8. Run `Check config`, then `Build summary`.
9. Click `Generate mod`.
10. Before committing to a run, inspect the result with the PokeFeur Viewer if you accept possible spoilers.

## Seed

The seed controls reproducibility.

- `-1`: the tool picks a new random seed every generation.
- Fixed number, for example `12345`: same seed + same options + same dump should give the same result.

Use a fixed seed when you want to regenerate or compare a run. Use `-1` when you want a fresh surprise.

## Race Mode

Race mode is currently **experimental and not properly tested**.

The intended idea is to keep a short public summary in `race-summary.json` and the full details in `spoiler-log.json`. Since this mode has not been properly tested, it is worth checking the generated files manually before using them in an actual shared race.

## Difficulty Profiles

Difficulty profiles apply several options at once.

They are best treated as **examples or starting points**, not as guaranteed balanced configurations. They can be outdated, too easy, too hard, or simply not match your taste.

The author is not a competitive strategy expert, so these presets should not be treated as official balanced Nuzlocke rulesets. You can use them if you like their style; manual configuration just gives you more control.

## JSON Presets

`Export preset` saves your current settings to a JSON file. `Import preset` loads settings from such a file.

Presets do not contain Nintendo files, but they can still be misleading if the software changed after the preset was created. They are most useful for backup, sharing a style, or documenting a setup, not as proof that a configuration is "the best".

After importing a preset, `Check config` and the build summary are useful to see exactly what will be generated.

## Trainers Tab

This tab controls NPC teams.

### Species

- `Keep vanilla`: leaves trainer species unchanged.
- `Balanced random`: replaces each species with a Pokemon of similar global strength, based on BST.
- `Full random`: draws from the allowed species pool without trying to preserve strength.

BST means `Base Stat Total`, the sum of the six base stats. It is useful for rough balancing, but it is not perfect: typing, abilities, movepool, level, and evolution stage still matter.

### Moves

- `Keep vanilla`: keeps existing trainer moves.
- `Natural moves for its level`: rebuilds moves from the Pokemon learnset at its level.
- `4 random moves`: draws four moves from the valid move pool.
- `Smogon strategic`: uses public Smogon Sword/Shield sets when available.
- `Smogon + older gens`: uses Sword/Shield first; if no SS set exists, searches older generations in this order: SS, SM, XY, BW, DP, RS, GS, RB.

If a Smogon set references a move that is not usable in Sword/Shield data, the tool falls back according to the selected Smogon move backup.

### Held Items

- `Keep vanilla`: leaves items unchanged.
- `Random when item already present`: only replaces existing held items.
- `Random item on every trainer Pokemon`: gives an item to every trainer Pokemon.
- `Smogon strategic item`: copies an item from the selected Smogon Sword/Shield set when possible.
- `Smogon item + older gens`: same idea, but can use an older-generation set if no Sword/Shield set exists.
- `Remove all held items`: clears held items.

Smogon item IDs are converted through the PokeFeur/PokeAPI item index so Sword/Shield writes the correct item IDs. For example, `Heavy-Duty Boots` must be written as item ID `1178` in this project data.

### Abilities

- `Keep vanilla`: leaves trainer ability choice unchanged.
- `Randomize trainer ability slot`: picks a legal ability slot for the species.
- `Smogon strategic ability`: tries to use the ability requested by a Smogon Sword/Shield set.
- `Smogon ability + older gens`: can use an older-generation Smogon set if no Sword/Shield set exists.

When Smogon ability mode succeeds, the trainer slot is forced to ability slot `1`, `2`, or `3`; it is not left as "probable/random".

### IVs, EVs, and Natures

IVs are hidden values from 0 to 31. Higher IVs mean better stats.

EVs are bonus stat investment. Legal EV mode respects the usual 510 total / 252 per stat limits. Smogon EV mode copies the spread from the selected set when it exists.

Natures modify one stat upward and one stat downward by about 10%. Smogon nature mode copies the nature from the same selected set when possible.

These options can make trainers much harder, especially when combined with better moves, items, and max AI.

### Boss Teams and Difficulty

- `Set all trainers to 6 Pokemon`: expands every team when possible.
- `Set certain bosses to 6 Pokemon`: targets important fights such as gym leaders, rivals, league fights, and major story trainers.
- `Teams by type`: gives each trainer a type theme.
- `Force final evolutions`: evolves trainer Pokemon from a chosen level.
- `Max trainer AI`: enables stronger known AI flags.
- `Allow legendaries`: allows legendary and mythical Pokemon in new trainer draws.

Stacking several difficulty options can quickly make a run much harder or more chaotic. That can be exactly what you want; the important part is knowing what changed.

### Field Items, Shops, TMs/TRs

These options randomize decoded item tables, not compiled `.amx` scripts.

- Field items: decoded pickup/ground item tables that the script can safely rewrite.
- Shop items: decoded shop inventory tables.
- TM/TR items: includes detected TM/TR IDs in the item randomization pool.

`item-changes.json` records replacements and can spoil a run. Items embedded only inside compiled field/shop scripts are not rewritten by this pass.

## Pokemon Tab

This tab changes global species and move data. These edits affect the whole game, not just trainers.

- Type randomization changes species typing.
- Monotype mode forces a single type when type randomization is active.
- Ability randomization changes global ability slots.
- Wonder Guard is separated because it can break balance.
- Stat shuffle preserves total BST but rearranges stats.
- BST redistribution keeps the total but reallocates it differently.
- Move type/power/PP/accuracy/category randomization changes moves globally.

Global edits are high impact. Randomizing trainers and encounters keeps the result easier to read, while global type/stat/ability/move edits make the whole game more chaotic.

## Evolutions Tab

Evolution options can randomize evolution targets or simplify awkward evolution methods.

- Friendship evolutions can become level-up evolutions.
- Trade evolutions can become level-up evolutions.
- Special evolutions can become level-up evolutions.

This is useful for solo play because it prevents Pokemon from getting stuck behind trade or unusual conditions.

## Starters / Gifts Tab

- Starter modes can keep vanilla starters, draw random starters, or draw starters with similar BST.
- Manual starters accept French or English names when the species exists in Sword/Shield data.
- Starter-related trainer patching updates early teams tied to the starter choice.
- Gift Pokemon and NPC trades can be randomized separately.
- Legendary toggles exist separately for starters, gifts, and trades.

If you enter manual starters, fill all three slots or leave all three empty.

## Encounters Tab

Encounter options randomize fixed encounters, wild encounter tables, visible overworld behavior, and underground/chika tables when the data is available.

Mapping rules:

- Stable by species: the same vanilla species maps to the same replacement everywhere in that category.
- Stable by slot: each table slot keeps its own replacement.
- Fresh roll per entry: every entry rolls independently.

Visible overworld behavior:

- Classic: visible Pokemon and battle Pokemon match.
- Vanilla visible + hidden battle: models outside stay vanilla, but battle species can be randomized separately.
- Random visible + hidden battle: visible models are randomized and battle species can also be separate.

The two hidden battle modes require ExLaunch and your own `exefs`.

## Smogon Data

Smogon modes are built from public Smogon Strategy Dex pages and public Pokemon Showdown indexes.

Strict mode:

- `cache/smogon-strategic-gen8.json`
- `cache/smogon-showdown-swsh-recommendations.json`
- Uses Sword/Shield pages only.
- When trainer species are randomized under strict Smogon mode, the species pool can be limited to Pokemon that have a real Sword/Shield Smogon set.

Older-generation fallback mode:

- `cache/smogon-strategic-latest-history.json`
- `cache/smogon-showdown-latest-history-recommendations.json`
- Uses Sword/Shield first, then searches SM, XY, BW, DP, RS, GS, RB.
- If a species still has no set, the species is kept and the configured backups are used.

Important limitation: the author is not a competitive strategy expert. The tool copies public sets and tries to map them correctly into Sword/Shield data, but it does not guarantee perfect competitive balance.

Manual cache rebuild:

```powershell
node .\tools\build-smogon-dex-cache.js --repo-root .
```

## ExLaunch Runtime Options

Some options cannot be done cleanly through ROMFS edits only. ExLaunch handles runtime behavior through the custom `subsdk9` module.

Common runtime features:

- EXP Share default state.
- EXP multiplier.
- No EXP / level cap style options.
- PC runtime controls.
- Hidden battle behavior for visible overworld Pokemon.

For these options, `main.npdm` must come from your own `exefs`, and the generated `subsdk9` must be present in the generated `exefs`.

The public repository should not include generated ExLaunch artifacts such as `subsdk9`, AMX runtime scripts, build folders, or downloaded release zips. Keep those artifacts local and rebuild or provide them from your own allowed toolchain setup. Nintendo ExeFS files are never bundled: `main.npdm` is copied from the user's own dump only when needed.

## Generated JSON Reports

Reports are written inside the generated `romfs` folder.

| File | Content | Spoilers |
| --- | --- | --- |
| `randomizer-report.json` | Options, seed, counters, generated paths | Low |
| `trainer-changes.json` | Trainer teams before/after | Yes |
| `wild-changes.json` | Wild encounter changes | Yes |
| `encounter-zones.json` | Encounter slots grouped by zone/table | Yes |
| `seed-summary.json` | Starters and quick seed summary | Yes |
| `race-summary.json` | Experimental race summary | Partial |
| `spoiler-log.json` | Full spoiler log | Yes |
| `level-caps.json` | Calculated level caps | Usually no |

`encounter-zones.json` is generated for future viewer support, but the PokeFeur Viewer does **not** support that encounter JSON yet.

## PokeFeur Viewer

[PokeFeur Trainer Viewer](https://jonatanuhc.github.io/PokeFeur/trainer_viewer_6_1.html?lang=fr) is Jonatan's trainer viewer for PokeFeur. It can load generated Sword/Shield trainer data and show teams, levels, items, moves, abilities, IVs, EVs, and stats.

Recommended use:

1. Open the viewer.
2. Click `Charger dossier SWSH / mod`.
3. Select your generated output folder or its `romfs` folder.
4. Search for a trainer or Pokemon.
5. Check starters, important trainers, and difficulty signals before spending hours on a run.

Viewer warning: checking generated teams can spoil the run. If you want to stay mostly blind, only check broad signals, then change the seed before playing.

Current limitation: the viewer does not yet support `encounter-zones.json`, so the encounter-zone report is mainly for later integration or manual inspection.

## Example First Run

Example setup for a readable run:

- Trainer species: balanced random.
- Trainer moves: natural moves for level.
- Trainer items: random only when already present.
- Duplicate trainer species: blocked.
- Wild encounters: full random with stable slot mapping.
- Visible encounters: classic visible = battle.
- Starters: similar BST.
- Trade/friendship evolutions: convert to level-up.

Global type, stat, ability, and move-property randomization can be added whenever you want more chaos. They are fun options, just harder to read at a glance.

## Troubleshooting

### The software rejects my ROMFS

Select the `romfs` folder itself. It should contain files such as:

```text
bin/pml/personal/personal_total.bin
bin/trainer/trainer_data/
bin/trainer/trainer_poke/
```

### ExLaunch options do not work

Check that:

- your `exefs` folder is provided;
- `main.npdm` exists in that `exefs`;
- `output/<game>/exefs/subsdk9` exists after generation;
- `output/<game>/sdmc/config/swsh-mods-exl/config.toml` exists when runtime config is needed.

### The first Smogon generation is slow

The first run downloads public strategy data and builds local cache files in `cache/`. Later generations reuse the cache.

### I want to share my result

Do not share generated folders that contain `romfs`, `exefs`, `sdmc`, or modified game files.

Safer things to share:

- the project link;
- screenshots;
- text summaries;
- presets as references or shared styles, with a note that they are not guaranteed balanced configs;
- JSON reports only if you are comfortable with spoilers and they do not include private local paths you care about.

## Sources, Dependencies, and Thanks

PokeFeur Randomizer is an original tool, but it exists thanks to public documentation, open-source projects, research tools, and community data. Thanks to every project and community listed below for making Pokemon research, modding, and strategy tooling easier to understand.

These projects are credited as references, dependencies, or data sources. They are not responsible for PokeFeur Randomizer, they do not endorse it, and they do not provide Nintendo files for this project.

### Runtime and Toolchain Dependencies

| Project | Link | Used for |
| --- | --- | --- |
| PowerShell | [github.com/PowerShell/PowerShell](https://github.com/PowerShell/PowerShell) | Local helper scripts and verification commands |
| .NET / Windows Forms | [learn.microsoft.com/dotnet/desktop/winforms](https://learn.microsoft.com/en-us/dotnet/desktop/winforms/) | Desktop UI and application runtime |
| Node.js | [github.com/nodejs/node](https://github.com/nodejs/node) | Cache builders, JSON generation, and data conversion scripts |
| ExLaunch | [github.com/shadowninja108/exlaunch](https://github.com/shadowninja108/exlaunch) | Runtime hook framework used by `subsdk9` |
| devkitPro / libnx | [devkitpro.org](https://devkitpro.org/) / [github.com/switchbrew/libnx](https://github.com/switchbrew/libnx) | Native Switch homebrew toolchain references used by ExLaunch-based projects |
| FlatBuffers | [github.com/google/flatbuffers](https://github.com/google/flatbuffers) | Binary data structure reference in the research tree |
| toml++ | [github.com/marzer/tomlplusplus](https://github.com/marzer/tomlplusplus) | TOML parsing reference used by ExLaunch-based runtime config projects |
| Pawn | [github.com/compuphase/pawn](https://github.com/compuphase/pawn/) | Script/compiler reference present in the ExLaunch research dependencies |

### Pokemon Data and Strategy Sources

| Project | Link | Used for |
| --- | --- | --- |
| Smogon Strategy Dex SS | [smogon.com/dex/ss/pokemon](https://www.smogon.com/dex/ss/pokemon/) | Strict Sword/Shield Smogon sets: moves, items, abilities, natures, and EVs |
| Smogon Strategy Dex older generations | [smogon.com/dex](https://www.smogon.com/dex/) | Optional fallback mode when a Pokemon has no Sword/Shield strategy page |
| Pokemon Showdown | [github.com/smogon/pokemon-showdown](https://github.com/smogon/pokemon-showdown) | Public indexes for Pokemon, moves, abilities, formats, and names |
| PokeAPI | [pokeapi.co](https://pokeapi.co/) / [github.com/PokeAPI/pokeapi](https://github.com/PokeAPI/pokeapi) | Public Pokemon data reference and name/index cross-checking |
| PokeFeur local dex | [local-dex-data.js](https://jonatanuhc.github.io/PokeFeur/assets/js/local-dex-data.js) | Item index used to map Smogon item names to Sword/Shield item IDs |
| PokeFeur Trainer Viewer | [trainer_viewer_6_1.html](https://jonatanuhc.github.io/PokeFeur/trainer_viewer_6_1.html?lang=fr) | Jonatan's PokeFeur trainer viewer, used for visual trainer verification |

### Research References and Ecosystem Tools

| Project | Link | Used for |
| --- | --- | --- |
| pkNX | [github.com/kwsch/pkNX](https://github.com/kwsch/pkNX) | File-structure reference and randomizer inspiration |
| PKHeX | [github.com/kwsch/PKHeX](https://github.com/kwsch/PKHeX) | Pokemon ecosystem reference for data, forms, and legality concepts |
| swsh-mods-exl | [github.com/Lincoln-LM/swsh-mods-exl](https://github.com/Lincoln-LM/swsh-mods-exl) | Sword/Shield ExLaunch modding reference and runtime config inspiration |
| Raytwo SwSh Randomizer | [github.com/Raytwo/swsh_randomizer](https://github.com/Raytwo/swsh_randomizer) | Sword/Shield randomizer research reference |
| Imposters-Ordeal | [github.com/Nifyr/Imposters-Ordeal](https://github.com/Nifyr/Imposters-Ordeal) | Pokemon modding/randomizer ecosystem reference, especially for editor UX ideas |

## Legal Notice

This project provides **absolutely no ROMs and no game files**. It does not provide NSP/XCI files, keys, firmware, Nintendo binaries, extracted `romfs`, extracted `exefs`, updates, DLC files, Pokemon/Nintendo assets, or any download link/source for those files.

You must buy and own Pokemon Sword or Pokemon Shield yourself, then provide your own dumps made from your own copy. Do not use downloaded ROMs, shared dumps, leaked files, keys, firmware, or any files that you do not have the legal right to use.

The author does not endorse piracy, illegal downloading, file sharing, redistribution of Nintendo files, or any use of the tool with unlawfully obtained game data. The tool is provided for personal use with your own legally obtained files.

You are fully responsible for your own files, dumps, backups, generated output, sharing choices, and compliance with the laws that apply in your country. The author is not responsible for how you obtain, use, modify, store, share, or run any game files or generated files.

This project is not affiliated with Nintendo, Game Freak, Creatures Inc., or The Pokemon Company.

---

<a name="français"></a>
# Français

Randomizer local pour **Pokemon Epee** et **Pokemon Bouclier**.

Le logiciel lit tes propres fichiers extraits du jeu et écrit un dossier de sortie randomisé séparé.

Il ne fournit **AUCUNE ROM, aucun dump, aucun fichier de jeu, aucun fichier Nintendo, et aucun moyen d'en obtenir**. Ce projet ne remplace pas l'achat du jeu ni l'extraction de ta propre copie.

Ce README documente volontairement le randomizer et les fichiers générés. L'utilisation du dossier généré ensuite dépend de ton environnement et n'est pas détaillée ici.

## Ce qu'il te faut

- Windows 10 ou Windows 11.
- Windows PowerShell 5.1 ou plus récent.
- Ton propre dump `romfs` depuis une copie de Pokemon Epee ou Pokemon Bouclier que tu possèdes personnellement.
- Ton propre dump `exefs` uniquement si tu actives des options ExLaunch: Partage EXP, caps de niveaux, menu PC runtime, combats cachés des Pokemon visibles, etc.
- Une connexion Internet au premier usage des modes Smogon, pour construire le cache local depuis les pages publiques Smogon et les index publics Pokemon Showdown.
- Node.js uniquement si tu reconstruis manuellement les caches Smogon avec `tools/build-smogon-dex-cache.js`.

Tu n'as pas besoin de Python ni d'une base de données pour lancer l'interface graphique.

## Lancement

Double-clique:

```bat
Launch-CustomSwShRandomizer.bat
```

Alternative PowerShell:

```powershell
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\CustomSwShRandomizer.ps1
```

Si Windows bloque les fichiers parce qu'ils viennent d'Internet:

```powershell
Unblock-File .\CustomSwShRandomizer.ps1
Unblock-File .\Launch-CustomSwShRandomizer.bat
```

## Ce que le logiciel génère

Exemple:

```text
output/Epee/
  romfs/
  exefs/
  sdmc/
    config/swsh-mods-exl/config.toml
```

- `romfs/` contient les fichiers modifiés à partir de ton propre `romfs`.
- `exefs/` est créé quand des options runtime utilisent ExLaunch. `main.npdm` doit venir de ton propre `exefs`; `subsdk9` est le module custom du projet.
- `sdmc/config/swsh-mods-exl/config.toml` contient les réglages runtime: Partage EXP, multiplicateur EXP, caps de niveaux, comportement des combats visibles, etc.

Le dossier généré peut contenir des données Nintendo modifiées. Ne publie pas et ne partage pas les dossiers générés `romfs`, `exefs`, `sdmc` ou `output`.

## Utilisation rapide

1. Utilise ta propre copie du jeu achetée légalement, puis extrais tes propres fichiers et garde le dossier `romfs`.
2. Lance `Launch-CustomSwShRandomizer.bat`.
3. Dans `Dossier ROMFS original`, sélectionne le dossier `romfs` lui-même, pas son parent.
4. Remplis `Dossier ExeFS original` seulement si tu utilises des options ExLaunch.
5. Dans `Dossier du mod généré`, choisis une racine de sortie comme `output/Epee`, pas `output/Epee/romfs`.
6. Choisis Epee ou Bouclier.
7. Choisis une seed et configure les onglets.
8. Lance `Vérifier la configuration`, puis `Résumé du build`.
9. Clique `Générer le mod`.
10. Avant de partir sur une run longue, inspecte le résultat avec le Viewer PokeFeur si tu acceptes les spoilers possibles.

## Seed

La seed contrôle la reproductibilité.

- `-1`: le logiciel tire une nouvelle seed aléatoire à chaque génération.
- Nombre fixe, par exemple `12345`: même seed + mêmes options + même dump donnent normalement le même résultat.

Utilise une seed fixe pour régénérer ou comparer une run. Utilise `-1` pour une surprise complète.

## Mode course

Le mode course est actuellement **expérimental et pas correctement testé**.

L'idée prévue est de garder un résumé public court dans `race-summary.json` et les détails complets dans `spoiler-log.json`. Comme ce mode n'a pas été correctement testé, ça vaut le coup de vérifier les fichiers générés à la main avant de les utiliser dans une vraie course partagée.

## Profils de difficulté

Les profils appliquent plusieurs options d'un coup.

Ils sont surtout à voir comme **des exemples ou des points de départ**, pas comme des configurations garanties équilibrées. Ils peuvent être dépassés, trop faciles, trop durs, ou simplement ne pas correspondre à ce que tu veux.

L'auteur n'est pas expert en stratégie compétitive, Nuzlocke ou équilibrage. Tu peux les utiliser si leur style te plaît; la configuration manuelle donne juste plus de contrôle.

## Présets JSON

`Exporter preset` sauvegarde tes réglages actuels dans un JSON. `Importer preset` recharge les réglages depuis ce type de fichier.

Un preset ne contient pas de fichiers Nintendo, mais il peut devenir trompeur si le logiciel a changé depuis sa création. C'est surtout utile comme sauvegarde, partage de style ou documentation d'une config, pas comme preuve qu'une configuration est "la meilleure".

Après import d'un preset, `Vérifier la configuration` et le résumé du build permettent de voir exactement ce qui va être généré.

## Onglet Dresseurs

Cet onglet contrôle les équipes des PNJ.

### Espèces

- `Garder vanilla`: ne change pas les espèces.
- `Random équilibré`: remplace par un Pokemon de puissance globale proche, selon le BST.
- `Random complet`: tire dans le pool autorisé sans essayer de préserver la puissance.

BST signifie `Base Stat Total`: la somme des six stats de base. C'est utile pour équilibrer grossièrement, mais ce n'est pas parfait. Les types, talents, attaques, niveaux et stades d'évolution comptent aussi beaucoup.

### Attaques

- `Garder vanilla`: garde les attaques existantes.
- `Attaques naturelles au niveau`: reconstruit les attaques depuis le learnset du Pokemon à son niveau.
- `4 attaques aléatoires`: tire quatre attaques dans le pool valide.
- `Stratégique Smogon`: utilise les sets publics Smogon Sword/Shield quand ils existent.
- `Smogon + anciennes gens`: utilise Sword/Shield d'abord; si aucun set SS n'existe, cherche dans les anciennes générations dans cet ordre: SS, SM, XY, BW, DP, RS, GS, RB.

Si un set Smogon référence une attaque inutilisable dans les données Sword/Shield, le logiciel complète selon le backup Smogon choisi.

### Objets tenus

- `Garder vanilla`: ne change pas les objets.
- `Random si objet déjà présent`: remplace seulement les objets existants.
- `Objet random sur tous`: donne un objet à chaque Pokemon de dresseur.
- `Objet stratégique Smogon`: copie un objet du set Smogon Sword/Shield choisi quand possible.
- `Objet Smogon + anciennes gens`: même logique, mais peut utiliser un set d'une ancienne génération si aucun set Sword/Shield n'existe.
- `Supprimer tous les objets`: retire les objets tenus.

Les objets Smogon sont convertis via l'index d'objets PokeFeur/PokeAPI pour écrire les bons IDs Sword/Shield. Exemple: `Heavy-Duty Boots` doit être écrit en ID `1178` dans ces données.

### Talents

- `Garder vanilla`: ne change pas le choix de talent.
- `Randomiser le slot talent`: choisit un slot légal pour l'espèce.
- `Talent stratégique Smogon`: essaie d'utiliser le talent demandé par un set Smogon Sword/Shield.
- `Talent Smogon + anciennes gens`: peut utiliser un set d'une ancienne génération si aucun set Sword/Shield n'existe.

Quand le mode talent Smogon réussit, le slot est forcé en `1`, `2` ou `3`; il n'est pas laissé en "talent probable" aléatoire.

### IV, EV et natures

Les IV sont des valeurs cachées de 0 à 31. Plus l'IV est haut, meilleure est la stat.

Les EV sont des points d'investissement. Le mode EV légal respecte les limites habituelles: 510 au total, 252 par stat. Le mode EV Smogon copie la répartition du set choisi quand elle existe.

La nature augmente une stat et en baisse une autre d'environ 10%. Le mode nature Smogon copie la nature du même set choisi quand possible.

Ces options peuvent rendre les dresseurs beaucoup plus forts, surtout avec de meilleures attaques, de meilleurs objets et l'IA au maximum.

### Boss et difficulté

- `Mettre tous les dresseurs à 6 Pokemon`: agrandit toutes les équipes quand possible.
- `Mettre certains boss à 6 Pokemon`: cible les combats importants comme champions, rivaux, ligue et gros combats histoire.
- `Équipes par type`: donne un thème de type à chaque dresseur.
- `Forcer les évolutions finales`: fait évoluer les Pokemon de dresseurs à partir d'un niveau choisi.
- `IA dresseur au maximum`: active les flags d'IA connus.
- `Autoriser les légendaires`: ajoute légendaires et mythiques aux nouveaux tirages.

Empiler plusieurs options de difficulté peut rendre une run beaucoup plus dure ou plus chaotique. Ça peut être exactement ce que tu cherches; l'important est surtout de savoir ce qui a changé.

### Objets ramassables, boutiques, CT/TR

Ces options randomisent les tables d'objets décodées, pas les scripts compilés `.amx`.

- Objets ramassables: tables décodées d'objets récupérables que le script peut réécrire proprement.
- Objets boutiques: tables décodées d'inventaires de boutiques.
- Objets CT/TR: ajoute les IDs CT/TR détectés au pool de randomisation d'objets.

`item-changes.json` liste les remplacements et peut spoiler la run. Les objets uniquement cachés dans des scripts field/shop compilés ne sont pas réécrits dans cette passe.

## Onglet Pokemon

Cet onglet modifie les espèces et attaques globales. Ces changements s'appliquent partout, pas seulement aux dresseurs.

- La randomisation des types change les types des espèces.
- Le mode monotype force un seul type quand les types sont randomisés.
- La randomisation des talents change les slots de talents globaux.
- Wonder Guard / Garde Mystik est séparé parce que ce talent peut casser l'équilibrage.
- Le mélange de stats garde le BST total mais déplace les stats.
- La redistribution BST garde le total mais le répartit autrement.
- La randomisation type/puissance/PP/précision/catégorie modifie les attaques globalement.

Ces options ont un gros impact. Randomiser seulement les dresseurs et les rencontres garde un résultat plus lisible, tandis que les types/stats/talents/attaques globales rendent tout le jeu plus chaotique.

## Onglet Évolutions

Les options d'évolution peuvent randomiser les cibles d'évolution ou simplifier les méthodes pénibles.

- Les évolutions par amitié peuvent devenir des évolutions par niveau.
- Les évolutions par échange peuvent devenir des évolutions par niveau.
- Les évolutions spéciales peuvent devenir des évolutions par niveau.

C'est utile en solo, parce que ça évite de bloquer des Pokemon derrière un échange ou une condition très spécifique.

## Onglet Starters / Cadeaux

- Les starters peuvent rester vanilla, être random, ou être tirés avec BST proche.
- Les starters manuels acceptent les noms français ou anglais si l'espèce existe dans les données Sword/Shield.
- Le patch des dresseurs liés aux starters adapte les premières équipes dépendantes du choix de starter.
- Les cadeaux et échanges PNJ se randomisent séparément.
- Les légendaires ont des toggles séparés pour starters, cadeaux et échanges.

Si tu remplis les starters manuels, remplis les trois champs ou laisse les trois vides.

## Onglet Rencontres

Les rencontres peuvent randomiser les rencontres fixes, les tables sauvages, le comportement des Pokemon visibles, et les tables underground/chika quand les données existent.

Règles de mapping:

- Stable par espèce: la même espèce vanilla devient le même remplacement partout dans cette catégorie.
- Stable par slot: chaque slot de table garde son propre remplacement.
- Tirage frais par entrée: chaque entrée tire indépendamment.

Comportement des Pokemon visibles:

- Classique: le Pokemon visible et le Pokemon combattu correspondent.
- Visuel vanilla + combat caché: les modèles dehors restent vanilla, mais le combat peut être randomisé séparément.
- Visuel random + combat caché: les modèles visibles sont randomisés et le combat peut aussi être séparé.

Les deux modes de combat caché demandent ExLaunch et ton propre `exefs`.

## Données Smogon

Les modes Smogon utilisent les pages publiques du Smogon Strategy Dex et les index publics Pokemon Showdown.

Mode strict:

- `cache/smogon-strategic-gen8.json`
- `cache/smogon-showdown-swsh-recommendations.json`
- Utilise seulement les pages Sword/Shield.
- Quand les espèces dresseurs sont randomisées en mode strict Smogon, le pool peut être limité aux Pokemon qui ont un vrai set Smogon Sword/Shield.

Mode anciennes générations:

- `cache/smogon-strategic-latest-history.json`
- `cache/smogon-showdown-latest-history-recommendations.json`
- Utilise Sword/Shield d'abord, puis SM, XY, BW, DP, RS, GS, RB.
- Si une espèce n'a toujours aucun set, elle reste dans la run et les backups configurés sont utilisés.

Limite importante: l'auteur n'est pas expert en stratégie compétitive. Le logiciel copie des sets publics et essaie de les mapper correctement dans les données Sword/Shield, mais il ne garantit pas un équilibrage parfait.

Reconstruire le cache à la main:

```powershell
node .\tools\build-smogon-dex-cache.js --repo-root .
```

## Options runtime ExLaunch

Certaines options ne peuvent pas être faites proprement en simple édition ROMFS. ExLaunch gère ces comportements via le module custom `subsdk9`.

Fonctions runtime typiques:

- état par défaut du Partage EXP;
- multiplicateur EXP;
- No EXP / caps de niveaux;
- contrôles runtime via PC;
- combat caché pour les Pokemon visibles.

Pour ces options, `main.npdm` doit venir de ton propre `exefs`, et `subsdk9` doit être présent dans le `exefs` généré.

Le dépôt public ne doit pas contenir les artefacts ExLaunch générés comme `subsdk9`, les scripts runtime AMX, les dossiers de build ou les zips téléchargés. Garde ces artefacts en local et reconstruis-les ou fournis-les depuis ton propre environnement autorisé. Les fichiers ExeFS Nintendo ne sont jamais inclus: `main.npdm` est copié depuis le dump utilisateur uniquement quand nécessaire.

## Rapports JSON générés

Les rapports sont écrits dans le dossier `romfs` généré.

| Fichier | Contenu | Spoilers |
| --- | --- | --- |
| `randomizer-report.json` | Options, seed, compteurs, chemins générés | Faible |
| `trainer-changes.json` | Dresseurs avant/après | Oui |
| `wild-changes.json` | Changements des rencontres sauvages | Oui |
| `encounter-zones.json` | Slots de rencontres groupés par zone/table | Oui |
| `seed-summary.json` | Starters et résumé rapide de seed | Oui |
| `race-summary.json` | Résumé course expérimental | Partiel |
| `spoiler-log.json` | Spoiler log complet | Oui |
| `level-caps.json` | Caps de niveaux calculés | Généralement non |

`encounter-zones.json` est généré pour un futur support viewer, mais le Viewer PokeFeur ne supporte **pas encore** ce JSON de rencontres.

## Viewer PokeFeur

Le [PokeFeur Trainer Viewer](https://jonatanuhc.github.io/PokeFeur/trainer_viewer_6_1.html?lang=fr) est le viewer de dresseurs PokeFeur créé par Jonatan. Il peut charger les données de dresseurs Sword/Shield générées et afficher équipes, niveaux, objets, attaques, talents, IV, EV et stats.

Utilisation recommandée:

1. Ouvre le viewer.
2. Clique `Charger dossier SWSH / mod`.
3. Sélectionne le dossier de sortie généré ou son dossier `romfs`.
4. Recherche un dresseur ou un Pokemon.
5. Vérifie les starters, les combats importants et les signaux de difficulté avant de passer des heures sur une run.

Attention: consulter les équipes générées peut spoiler la run. Si tu veux rester presque blind, vérifie seulement les grandes lignes, puis change la seed avant de jouer.

Limite actuelle: le viewer ne supporte pas encore `encounter-zones.json`; le rapport de zones de rencontres sert donc surtout à une intégration future ou à une inspection manuelle.

## Exemple de configuration pour commencer

Exemple de configuration pour une run lisible:

- Espèces dresseurs: random équilibré.
- Attaques dresseurs: attaques naturelles au niveau.
- Objets dresseurs: random seulement si objet déjà présent.
- Doublons d'équipe: bloqués.
- Rencontres sauvages: random complet avec mapping stable par slot.
- Pokemon visibles: classique visible = combat.
- Starters: BST proche.
- Évolutions par échange/amitié: converties en niveau.

La randomisation des types, stats, talents globaux et propriétés des attaques peut être ajoutée dès que tu veux plus de chaos. Ce sont des options fun, juste moins lisibles au premier regard.

## Dépannage

### Le logiciel refuse mon ROMFS

Sélectionne le dossier `romfs` lui-même. Il doit contenir des fichiers comme:

```text
bin/pml/personal/personal_total.bin
bin/trainer/trainer_data/
bin/trainer/trainer_poke/
```

### Les options ExLaunch ne marchent pas

Vérifie que:

- ton dossier `exefs` est fourni;
- `main.npdm` existe dans ce `exefs`;
- `output/<jeu>/exefs/subsdk9` existe après génération;
- `output/<jeu>/sdmc/config/swsh-mods-exl/config.toml` existe quand une config runtime est nécessaire.

### Le premier chargement Smogon est lent

Le premier usage télécharge les données stratégiques publiques et construit les caches dans `cache/`. Les générations suivantes réutilisent ces caches.

### Je veux partager mon résultat

Ne partage pas de dossiers générés contenant `romfs`, `exefs`, `sdmc` ou des fichiers modifiés du jeu.

Ce qui est plus sûr à partager:

- le lien du projet;
- des captures;
- des résumés texte;
- des presets comme références ou styles partagés, avec une note qu'ils ne sont pas des configs garanties équilibrées;
- des rapports JSON seulement si tu acceptes les spoilers et qu'ils ne contiennent pas de chemins locaux privés que tu veux garder pour toi.

## Sources, dépendances et remerciements

PokeFeur Randomizer est un outil original, mais il existe grâce à de la documentation publique, des projets open-source, des outils de recherche et des données communautaires. Merci à tous les projets et communautés ci-dessous: ils rendent la recherche Pokemon, le modding et les outils stratégiques beaucoup plus compréhensibles.

Ces projets sont cités comme références, dépendances ou sources de données. Ils ne sont pas responsables de PokeFeur Randomizer, ils ne le cautionnent pas, et ils ne fournissent aucun fichier Nintendo pour ce projet.

### Dépendances runtime et outillage

| Projet | Lien | Utilisation |
| --- | --- | --- |
| PowerShell | [github.com/PowerShell/PowerShell](https://github.com/PowerShell/PowerShell) | Scripts locaux et commandes de vérification |
| .NET / Windows Forms | [learn.microsoft.com/dotnet/desktop/winforms](https://learn.microsoft.com/en-us/dotnet/desktop/winforms/) | Interface desktop et runtime de l'application |
| Node.js | [github.com/nodejs/node](https://github.com/nodejs/node) | Construction de caches, génération JSON et scripts de conversion de données |
| ExLaunch | [github.com/shadowninja108/exlaunch](https://github.com/shadowninja108/exlaunch) | Framework runtime utilisé par `subsdk9` |
| devkitPro / libnx | [devkitpro.org](https://devkitpro.org/) / [github.com/switchbrew/libnx](https://github.com/switchbrew/libnx) | Références de toolchain homebrew Switch utilisées par les projets basés sur ExLaunch |
| FlatBuffers | [github.com/google/flatbuffers](https://github.com/google/flatbuffers) | Référence de structures de données binaires dans l'arbre de recherche |
| toml++ | [github.com/marzer/tomlplusplus](https://github.com/marzer/tomlplusplus) | Référence de parsing TOML utilisée par les projets de config runtime basés sur ExLaunch |
| Pawn | [github.com/compuphase/pawn](https://github.com/compuphase/pawn/) | Référence de scripts/compilateur présente dans les dépendances de recherche ExLaunch |

### Données Pokemon et sources stratégiques

| Projet | Lien | Utilisation |
| --- | --- | --- |
| Smogon Strategy Dex SS | [smogon.com/dex/ss/pokemon](https://www.smogon.com/dex/ss/pokemon/) | Sets Smogon stricts Sword/Shield: attaques, objets, talents, natures et EVs |
| Smogon Strategy Dex anciennes générations | [smogon.com/dex](https://www.smogon.com/dex/) | Mode fallback optionnel quand un Pokemon n'a pas de fiche stratégique Sword/Shield |
| Pokemon Showdown | [github.com/smogon/pokemon-showdown](https://github.com/smogon/pokemon-showdown) | Index publics pour Pokemon, attaques, talents, formats et noms |
| PokeAPI | [pokeapi.co](https://pokeapi.co/) / [github.com/PokeAPI/pokeapi](https://github.com/PokeAPI/pokeapi) | Référence publique de données Pokemon et vérification des noms/index |
| PokeFeur local dex | [local-dex-data.js](https://jonatanuhc.github.io/PokeFeur/assets/js/local-dex-data.js) | Index d'objets utilisé pour mapper les objets Smogon vers les IDs Sword/Shield |
| PokeFeur Trainer Viewer | [trainer_viewer_6_1.html](https://jonatanuhc.github.io/PokeFeur/trainer_viewer_6_1.html?lang=fr) | Viewer de dresseurs PokeFeur créé par Jonatan, utilisé pour la vérification visuelle des dresseurs |

### Références de recherche et outils de l'écosystème

| Projet | Lien | Utilisation |
| --- | --- | --- |
| pkNX | [github.com/kwsch/pkNX](https://github.com/kwsch/pkNX) | Référence pour les structures de fichiers et idées de randomisation |
| PKHeX | [github.com/kwsch/PKHeX](https://github.com/kwsch/PKHeX) | Référence de l'écosystème Pokemon pour les données, formes et concepts de légalité |
| swsh-mods-exl | [github.com/Lincoln-LM/swsh-mods-exl](https://github.com/Lincoln-LM/swsh-mods-exl) | Référence de modding ExLaunch Sword/Shield et inspiration pour la config runtime |
| Raytwo SwSh Randomizer | [github.com/Raytwo/swsh_randomizer](https://github.com/Raytwo/swsh_randomizer) | Référence de recherche sur la randomisation Sword/Shield |
| Imposters-Ordeal | [github.com/Nifyr/Imposters-Ordeal](https://github.com/Nifyr/Imposters-Ordeal) | Référence de l'écosystème modding/randomizer Pokemon, surtout pour les idées d'UX d'éditeur |

## Avertissement légal

Ce projet ne fournit **absolument aucune ROM et aucun fichier de jeu**. Il ne fournit pas de NSP/XCI, clés, firmware, binaires Nintendo, `romfs` extrait, `exefs` extrait, mises à jour, DLC, assets Pokemon/Nintendo, ni lien/source de téléchargement pour obtenir ces fichiers.

Tu dois acheter et posséder toi-même Pokemon Epee ou Pokemon Bouclier, puis fournir tes propres dumps faits depuis ta propre copie. N'utilise pas de ROM téléchargée, dump partagé, fichier leaké, clés, firmware ou fichier que tu n'as pas légalement le droit d'utiliser.

L'auteur ne cautionne pas le piratage, le téléchargement illégal, le partage de fichiers, la redistribution de fichiers Nintendo, ni l'utilisation du logiciel avec des données de jeu obtenues illégalement. L'outil est fourni pour un usage personnel avec tes propres fichiers obtenus légalement.

Tu es entièrement responsable de tes fichiers, dumps, sauvegardes, sorties générées, choix de partage, et du respect des lois applicables dans ton pays. L'auteur n'est pas responsable de la manière dont tu obtiens, utilises, modifies, stockes, partages ou exécutes tes fichiers de jeu ou fichiers générés.

Ce projet n'est pas affilié à Nintendo, Game Freak, Creatures Inc. ou The Pokemon Company.

---

<div align="center">

Questions, bugs, suggestions?

[![Discord](https://img.shields.io/badge/Discord-Rejoindre_le_serveur-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/bSUKYEJE)

</div>
