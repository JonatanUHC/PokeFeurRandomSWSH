# PokeFeur Randomizer SWSH

Local randomizer for **Pokémon Sword** and **Pokémon Shield** (v1.3.2).
It reads your own extracted game files and writes a separate mod folder. Your dump is never modified.

### [Join the Discord](https://discord.gg/h2ZrwNNePF)

**Questions, help, bug reports and early builds all happen on Discord.** New versions land there before they land here, and it is the place where you will actually get an answer.

> No ROM, no dump, no keys and no Nintendo file is provided here, nor any way to obtain one.
> You must own the game and extract your own copy.

*[Version française plus bas](#français)*

---

## The flagship: what you see is not what you fight

Two **independent** settings decide what walks around in the grass, and what you actually battle.

Set them differently and seeing a Pokémon tells you nothing about the fight ahead. This is the Nuzlocke setting: you cannot pick your catch on sight. Each side gets its own mode — unchanged, random on every appearance, stable per zone, stable everywhere — and its own legendary switch.

Two **Discovery** modes go further. The grass stays vanilla — or shows a random decoy — until your first battle in that zone. That battle **reveals** the species: from then on it is the one roaming there, and the one you fight again. Zones complete themselves as you play, and discoveries survive a console restart.

**And every species can now appear outside.** The base game shows only 330 in the overworld; that was never an engine limit — 664 species have a complete entry in the symbol behaviour table. You choose between all 664, the vanilla 330, or a test pool of the 334 the game never shows. A bulk filter keeps Wailord-sized Pokémon out of your view, based on the game's own collision radius, without removing them from battles.

---

## Everything you can randomize

### Trainers

- **Species** — full random, similar strength, or untouched.
- **Moves** — four random, moves natural for their level, or the **Smogon** competitive set, with a fallback rule when the experts give fewer than four.
- **Held items** — only trainers who already had one, everyone, or nobody. Choose the pool: battle items only, or almost the whole game.
- **Abilities, IVs, EVs, natures** — random, Smogon strategic, or vanilla. IVs at 31 everywhere, EVs zeroed or a legal random spread.
- **Team size** — set a minimum and a maximum, or force full teams of six. Separately for bosses, with a choice between every important battle or gyms and League only.
- **Add Pokémon** — up to five extra per trainer, tuned by importance: gym leaders and Champion, rivals and enemy leaders, or everyone.
- **Legendaries** — none at all, exactly one per team, or **entire teams of legendaries**. Pick who it applies to: gyms and League, all bosses, or every trainer.
- **Minimum power** — force chosen trainers to only use Pokémon above a base-stat total. Type 600 and you face nothing but monsters.
- **Type-themed trainers** — one random type per trainer, whole team. Or the opposite: block duplicates so a single super-effective move can no longer sweep.
- **Level multiplier**, **max battle AI**, **shiny rate**, **force fully evolved** past a level, **Dynamax level**, **let everyone Dynamax**.
- **Trainer bags** — 52 of the 437 trainers carry healing items. Empty their bags, or randomize them.

### Pokémon, moves and machines

- **Types** — redrawn at random, optionally forcing a single type on everyone.
- **Abilities** — the three slots redrawn, with Wonder Guard opt-in.
- **Base stats** — shuffled, or redistributed keeping the same total.
- **Move data** — type, power, PP, accuracy and physical/special category, each with your own min/max bounds.
- **Learnsets** — shuffled between species, redrawn from moves they already learn, or drawn from all 787. Levels never move.
- **TMs and TRs** — which move each machine teaches, and who can learn it: a coin flip, a bias toward matching types, or everyone learns everything. Move tutors get the same treatment.
- **EXP curve** — everyone fast, medium or slow.
- **EXP yield** — a multiplier, or the brutal one-point-per-battle.
- **Minimum catch rate** — make everything catchable, up to first-ball-guaranteed.
- **Follow evolutions** — keep a whole family coherent in types and abilities.

### Encounters

- **Wild grass, fixed and scripted encounters, the Underground** — each with its own mode and legendary toggle.
- **Mapping stability** — every Victreebel of a zone becomes the same thing, or each slot is drawn on its own.
- **Wild levels** — scaled by a percentage.
- **Generation filters** — restrict the game to the generations you want. The general filter covers everything; per-category fields refine what you see, what you fight, what you are given and opposing teams.

### Evolutions

- **What evolves into what** — random, or kept within a strength range, legendaries allowed or not.
- **Trade, friendship and exotic evolutions become plain level-ups** at a level you choose — essential when you play alone. Stones, times of day, locations and held items all collapse into a number.

### Starters, gifts and trades

- **Starters** — random, similar strength, or a trio you type in by hand, in French or English.
- **Gifts and in-game trades** — both sides of a trade change. Legendaries allowed or not, separately for each.
- **NPC gift items** — what characters hand you, shuffled between them or fully redrawn.
- Trainers tied to your starter choice are patched to stay coherent, moves included.

### Items, shops and the world

- **Shops** — randomized, with a choice between same kind of item or anything the shop sells.
- **Prices** — from free to five times, or drawn at random from a range.
- **Field items, hidden items, pickup items, Technical Records** — all randomizable, with an option to keep key items out.
- **Wild held items**.

---

## What is applied in game

Some options rewrite no file at all: a runtime module applies them while you play. They require your **`exefs`** folder.

- **EXP Share off from the start** — only the Pokémon that fight earn experience.
- **Experience multiplier** — from half to several times, applied live.
- **Level caps** — the gym and Champion levels, a dynamic cap that rises with your progress, a strict cap on listed bosses, or an ordered main-story mode. Caps are read from the teams **actually generated**, not the original ones.
- **PC menu** — a menu on the PC in Pokémon Centers showing shared EXP and the EXP boost, that you can toggle **mid-game, without rebuilding a ROM**.
- **Comfort** — overworld shinies with adjustable odds, Wild Area level cap removal, a following Pokémon you can steer, free camera, a populated Glimwood Tangle, fishing chains kept after a brilliant, nature synchronisation, faster Pokédex animations, the Rotom Bike from the start.

The hidden battles and Discovery modes also run through this module.

---

## Install

You need **Windows**, **Ryujinx**, and a dump of your own copy on **1.3.2** (`romfs`, plus `exefs` for the in-game options). [Python 3](https://www.python.org/downloads/) is required on first run.

1. Clone or download this repository.
2. Run `Launch-CustomSwShRandomizer.bat`.
3. Point it at your `romfs` and `exefs` folders.
4. Set your options, then **Generate mod**.

Tick **Auto-install** to send the mod straight to Ryujinx. Close the emulator before generating.

Every option is documented inside the software: hover it and the explanation shows at the bottom. Settings export as **JSON presets**, and each build writes **detailed JSON reports** of everything that changed. A seed makes any run reproducible.

## Data files

The software needs name tables extracted from the game. They are not shipped here — this repository redistributes nothing that comes from the game. It **builds them itself** from your dump on first run, using Python.

One exception: trainer names have no extractor, so trainers stay anonymous in the reports.

## Legal notice

This project provides **no ROM, no game file, no key, no firmware and no Nintendo binary**, nor any link or means to obtain them.

You must **buy and own** Pokémon Sword or Shield, then supply your own dumps made from your own copy. Do not use downloaded ROMs, shared dumps, leaked files, keys or firmware you have no right to use.

The author does not endorse piracy, illegal downloading, file sharing, redistribution of Nintendo files, or any use of this tool with unlawfully obtained game data. It is provided for personal use with your own legally obtained files.

You are solely responsible for your files, your dumps, your backups, what you generate, what you share, and for complying with the laws that apply in your country.

This project is not affiliated with Nintendo, Game Freak, Creatures Inc. or The Pokémon Company.

## Licence

**GPL-3.0-only**, see [LICENSE](LICENSE). The project embeds a file from [KM-Editor](https://github.com/KotMatrosk1n/KM-Editor) released under that licence.

Built on [exlaunch](https://github.com/shadowninja108/exlaunch) and Lincoln-LM's [swsh-mods-exl](https://github.com/Lincoln-LM/swsh-mods-exl). Strategic data: [Smogon](https://www.smogon.com/).

---

<a name="français"></a>

# Français

Randomizer local pour **Pokémon Épée** et **Pokémon Bouclier** (v1.3.2).
Il lit tes propres fichiers extraits du jeu et écrit un dossier de mod séparé. Ton dump n'est jamais modifié.

### [Rejoins le Discord](https://discord.gg/h2ZrwNNePF)

**Les questions, l'aide, les bugs et les versions en avance, c'est sur Discord.** Les nouvelles versions y arrivent avant d'arriver ici, et c'est là que tu auras vraiment une réponse.

> Aucune ROM, aucun dump, aucune clé, aucun fichier Nintendo n'est fourni ici, ni aucun moyen d'en obtenir.
> Tu dois posséder le jeu et extraire ta propre copie.

---

## La fonction phare : ce que tu vois n'est pas ce que tu affrontes

Deux réglages **indépendants** décident de ce qui se promène dans l'herbe, et de ce que tu combats réellement.

Réglés différemment, voir un Pokémon ne t'apprend plus rien sur le combat qui vient. C'est le réglage des runs Nuzlocke : impossible de choisir sa capture à vue. Chaque côté a son mode — inchangé, aléatoire à chaque apparition, stable par zone, stable partout — et son autorisation de légendaires.

Deux modes **Découverte** vont plus loin. L'herbe reste vanilla — ou montre un leurre tiré au sort — jusqu'à ton premier combat dans la zone. Ce combat **révèle** l'espèce : à partir de là, c'est elle qui s'y promène, et c'est elle que tu réaffrontes. Les zones se complètent au fil du jeu, et les découvertes survivent à l'extinction de la console.

**Et toutes les espèces peuvent désormais apparaître dehors.** Le jeu de base n'en montre que 330 en overworld ; ce n'était pas une limite du moteur — 664 espèces ont une entrée complète dans la table de comportement des symboles. Tu choisis entre les 664, les 330 du vanilla, ou un réservoir de test des 334 que le jeu ne montre jamais. Un filtre d'encombrement écarte les Pokémon de la taille d'un Wailord, d'après le rayon de collision du jeu, sans les retirer des combats.

---

## Tout ce que tu peux randomiser

### Dresseurs

- **Espèces** — random complet, force proche, ou inchangé.
- **Attaques** — quatre au hasard, celles de leur niveau, ou le set compétitif **Smogon**, avec une règle de repli quand les experts en donnent moins de quatre.
- **Objets tenus** — seulement ceux qui en avaient un, tout le monde, ou personne. Au choix : objets de combat, ou presque tout le jeu.
- **Talents, IV, EV, natures** — au hasard, stratégiques Smogon, ou vanilla. IV à 31 partout, EV à zéro ou répartition légale tirée au sort.
- **Taille d'équipe** — minimum et maximum, ou équipes complètes de six. Séparément pour les boss, avec le choix entre tous les combats importants ou seulement arènes et Ligue.
- **Ajouter des Pokémon** — jusqu'à cinq de plus par dresseur, dosés selon l'importance : champions et Maître, rivaux et chefs adverses, ou tout le monde.
- **Légendaires** — aucun, exactement un par équipe, ou **des équipes entières de légendaires**. À toi de choisir qui : arènes et Ligue, tous les boss, ou chaque dresseur.
- **Puissance minimale** — force les dresseurs choisis à n'utiliser que des Pokémon au-dessus d'un total de stats. Mets 600 et tu n'affrontes que des monstres.
- **Dresseurs mono-type** — un type au hasard par dresseur, toute l'équipe. Ou l'inverse : bloquer les doublons, pour qu'une seule attaque efficace ne balaie plus tout.
- **Multiplicateur de niveaux**, **IA maximale**, **taux de chromatiques**, **évolution forcée** au-delà d'un niveau, **niveau Dynamax**, **Dynamax pour tous**.
- **Sacs des dresseurs** — 52 des 437 dresseurs portent des soins. Vide leurs sacs, ou randomise-les.

### Pokémon, attaques et machines

- **Types** — retirés au sort, avec option mono-type pour tous.
- **Talents** — les trois emplacements redistribués, Garde Mystik en option.
- **Stats de base** — permutées, ou redistribuées à total constant.
- **Données d'attaques** — type, puissance, PP, précision et catégorie physique/spéciale, chacun avec tes propres bornes.
- **Learnsets** — permutés entre espèces, tirés parmi les attaques déjà apprises, ou parmi les 787. Les niveaux ne bougent jamais.
- **CT et DT** — quelle attaque enseigne chaque machine, et qui peut l'apprendre : une chance sur deux, un penchant pour le même type, ou tout le monde apprend tout. Les maîtres de capacités suivent.
- **Courbe d'EXP** — tous rapides, moyens ou lents.
- **Expérience donnée** — un multiplicateur, ou le brutal un point par combat.
- **Taux de capture minimal** — rendre tout capturable, jusqu'au premier lancer garanti.
- **Suivre les évolutions** — garder une famille cohérente en types et en talents.

### Rencontres

- **Herbes hautes, rencontres fixes et scriptées, souterrain** — chacune avec son mode et son autorisation de légendaires.
- **Stabilité du mapping** — tous les Empiflor d'une zone deviennent la même chose, ou chaque slot est tiré séparément.
- **Niveaux sauvages** — mis à l'échelle par un pourcentage.
- **Filtres de génération** — limite le jeu aux générations voulues. Le filtre général couvre tout ; des champs par catégorie affinent ce que tu vois, ce que tu affrontes, ce qu'on te donne et les équipes adverses.

### Évolutions

- **Qui évolue en quoi** — au hasard, ou dans une fourchette de puissance, légendaires autorisés ou non.
- **Les évolutions par échange, par bonheur et les plus exotiques deviennent de simples montées de niveau** au niveau que tu choisis — indispensable en solo. Pierres, heure du jour, lieux et objets tenus se réduisent tous à un nombre.

### Starters, cadeaux et échanges

- **Starters** — au hasard, force proche, ou un trio que tu saisis à la main, en français ou en anglais.
- **Cadeaux et échanges PNJ** — les deux côtés d'un échange changent. Légendaires autorisés ou non, séparément.
- **Objets offerts par les PNJ** — permutés entre eux ou entièrement retirés au sort.
- Les dresseurs liés à ton choix de starter sont ajustés pour rester cohérents, attaques comprises.

### Objets, boutiques et monde

- **Boutiques** — randomisées, avec le choix entre même genre d'objet ou tout ce que la boutique vend.
- **Prix** — de gratuit à cinq fois, ou tirés au hasard dans une fourchette.
- **Objets au sol, objets cachés, objets ramassables, Disques Techniques** — tous randomisables, avec une option pour écarter les objets clés.
- **Objets tenus des sauvages**.

---

## Ce qui se règle en jeu

Une partie des options ne réécrit aucun fichier : un module les applique pendant que tu joues. Elles demandent ton dossier **`exefs`**.

- **EXP Share éteint au départ** — seuls les Pokémon qui combattent gagnent de l'expérience.
- **Multiplicateur d'expérience** — de la moitié à plusieurs fois, appliqué en direct.
- **Plafonds de niveau** — celui des arènes et du Maître, un plafond dynamique qui monte avec ta progression, un plafond strict sur les boss listés, ou un mode ordonné sur l'histoire principale. Les plafonds sont lus sur les équipes **réellement générées**, pas sur celles d'origine.
- **Menu PC** — un menu au PC des Centres Pokémon affichant le partage d'EXP et le boost, que tu peux basculer **en pleine partie, sans refaire une ROM**.
- **Confort** — chromatiques visibles dehors avec taux réglable, déblocage du niveau en Zone Sauvage, Pokémon qui suit et qu'on pilote, caméra libre, Bois Chancelier peuplé, chaîne de pêche conservée, synchronisation de nature, animations du Pokédex accélérées, Vélo Rotom dès le début.

Le combat caché et les modes Découverte passent aussi par ce module.

---

## Installation

Il te faut **Windows**, **Ryujinx**, et un dump de ta copie du jeu en **1.3.2** (`romfs`, plus `exefs` pour les options en jeu). [Python 3](https://www.python.org/downloads/) est nécessaire au premier lancement.

1. Clone ou télécharge ce dépôt.
2. Lance `Launch-CustomSwShRandomizer.bat`.
3. Indique tes dossiers `romfs` et `exefs`.
4. Règle tes options, puis **Générer le mod**.

Coche **Installation auto** pour que le mod parte directement dans Ryujinx. Ferme l'émulateur avant de générer.

Chaque option est décrite dans le logiciel : survole-la, l'explication s'affiche en bas. Les réglages s'exportent en **presets JSON**, et chaque génération écrit des **rapports JSON détaillés** de tout ce qui a changé. Une seed rend n'importe quelle run reproductible.

## Fichiers de données

Le logiciel a besoin de tables de noms extraites du jeu. Elles ne sont pas fournies ici — ce dépôt ne redistribue rien qui vienne du jeu. Il les **construit tout seul** depuis ton dump au premier lancement, avec Python.

Seule exception : les noms de dresseurs n'ont pas d'extracteur, ils restent donc anonymes dans les rapports.

## Mentions légales

Ce projet ne fournit **aucune ROM, aucun fichier de jeu, aucune clé, aucun firmware, aucun binaire Nintendo**, ni aucun lien ou moyen d'en obtenir.

Tu dois **acheter et posséder** Pokémon Épée ou Bouclier, puis fournir tes propres extractions faites depuis ta propre copie. N'utilise pas de ROM téléchargée, de dump partagé, de fichier fuité, de clé ni de firmware que tu n'as pas le droit d'utiliser.

L'auteur ne cautionne ni le piratage, ni le téléchargement illégal, ni le partage, ni la redistribution de fichiers Nintendo, ni l'usage de cet outil avec des données obtenues illégalement. Il est fourni pour un usage personnel avec tes propres fichiers légalement obtenus.

Tu es seul responsable de tes fichiers, de tes dumps, de tes sauvegardes, de ce que tu génères, de ce que tu partages, et du respect des lois de ton pays.

Projet sans aucun lien avec Nintendo, Game Freak, Creatures Inc. ou The Pokémon Company.

## Licence

**GPL-3.0-only**, voir [LICENSE](LICENSE). Le projet embarque un fichier de [KM-Editor](https://github.com/KotMatrosk1n/KM-Editor) publié sous cette licence.

Construit sur [exlaunch](https://github.com/shadowninja108/exlaunch) et les mods [swsh-mods-exl](https://github.com/Lincoln-LM/swsh-mods-exl) de Lincoln-LM. Données stratégiques : [Smogon](https://www.smogon.com/).
