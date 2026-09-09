# PokeFeur Randomizer SWSH

Local randomizer for **Pokémon Sword** and **Pokémon Shield** (v1.3.2).
It reads your own extracted game files and writes a separate mod folder. Your dump is never modified.

> No ROM, no dump, no keys and no Nintendo file is provided here, nor any way to obtain one.
> You must own the game and extract your own copy.

*[Version française plus bas](#français)*

## What it does

**Trainers** — species, moves, items, abilities, IVs/EVs, natures, levels, team size, AI, Dynamax. Smogon strategic modes included.

**The rest** — wild encounters, evolutions, starters, gifts, shops, TMs/TRs, types, stats, learnsets, plus a set of in-game comfort options.

Everything is set in the interface, exports as a JSON preset, and produces detailed reports of what changed. Every option is documented inside the software: hover it and the explanation shows at the bottom.

## What you see, and what you fight

The flagship feature, built on **two independent settings**:

- **Pokémon you SEE outside**
- **Pokémon you FIGHT**

Set them differently and seeing a Pokémon no longer tells you what you will fight. This is the Nuzlocke setting: you cannot pick your catch on sight.

Two **Discovery** modes go further. The grass stays vanilla — or shows a random decoy, depending on the mode — until your first battle in that zone. That battle **reveals** the species: from then on it is the one roaming there, and the one you fight again. Zones complete themselves as you battle, and discoveries survive a console restart.

### Every species can appear outside

The base game only shows **330 species** in the overworld. That was never an engine limit: on a dump, **664 species** have a complete entry in the symbol behaviour table — model, collision radius, grass shake. The cap was a content choice.

The randomizer lifts it. You choose:

- **Every species** — 664, the default
- **Seen in vanilla** — the base game's 330
- **TEST: only the unintended ones** — 334, the ones the game never shows

A second setting keeps **oversized** Pokémon out, based on the game's own collision radius rather than Pokédex height: Rayquaza is coiled and only scores 70, while Gyarados scores 220. It affects display only — you can still battle them.

## What is applied in game

Some options rewrite no file at all: they are applied at runtime by a module. They therefore require your **`exefs`** folder as well.

**Difficulty curve**

- **EXP Share off from the start** — only the Pokémon that fight earn experience.
- **Experience multiplier** — from half to several times the normal rate, applied live.
- **Level caps** — blocks experience above a ceiling: the gym and champion levels, a dynamic cap that rises with your progress, or a strict cap on bosses. Caps are read from the teams **actually generated**, not from the original ones.

**PC menu** — adds a menu to the PC in Pokémon Centers. It shows the state of shared EXP and the EXP boost, and lets you change them **mid-game, without rebuilding a ROM**.

**Comfort** — overworld shinies, Wild Area level cap removal, a following Pokémon you can steer, free camera, a populated Glimwood Tangle, fishing chains kept after a brilliant. The free camera turns on, but its fine settings (speed, angles, distances) stay at their default values.

The hidden battles and Discovery modes described above also run through this module.

**Generation filters** — restrict the game to the generations you want. The general filter applies to **everything**, including the Pokémon visible outside. Per-category fields then refine what you fight, what you are given and opposing teams separately.

## Install

You need **Windows**, **Ryujinx**, and a dump of your own copy on **1.3.2** (`romfs`, plus `exefs` for the in-game options). [Python 3](https://www.python.org/downloads/) is required on first run.

1. Clone or download this repository.
2. Run `Launch-CustomSwShRandomizer.bat`.
3. Point it at your `romfs` and `exefs` folders.
4. Set your options, then **Generate mod**.

Tick **Auto-install** to send the mod straight to Ryujinx. Close the emulator before generating.

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

> Aucune ROM, aucun dump, aucune clé, aucun fichier Nintendo n'est fourni ici, ni aucun moyen d'en obtenir.
> Tu dois posséder le jeu et extraire ta propre copie.

## Ce qu'il sait faire

**Dresseurs** — espèces, attaques, objets, talents, IV/EV, natures, niveaux, taille d'équipe, IA, Dynamax. Modes stratégiques Smogon inclus.

**Le reste** — rencontres sauvages, évolutions, starters, cadeaux, boutiques, CT/DT, types, stats, learnsets, plus une série d'options de confort appliquées en jeu.

Tout se règle dans l'interface, s'exporte en preset JSON, et produit des rapports détaillés de ce qui a changé. Chaque option est décrite dans le logiciel : survole-la, l'explication s'affiche en bas.

## Ce que tu vois, et ce que tu affrontes

C'est la fonction phare, et elle repose sur **deux réglages indépendants** :

- **Pokémon que tu VOIS dehors**
- **Pokémon que tu AFFRONTES**

Réglés différemment, voir un Pokémon ne te dit plus lequel tu vas combattre. C'est le réglage des runs Nuzlocke : impossible de choisir sa capture à vue.

Deux modes **Découverte** vont plus loin. L'herbe reste vanilla — ou montre un leurre tiré au sort, selon le mode — jusqu'à ton premier combat dans la zone. Ce combat **révèle** l'espèce : à partir de là, c'est elle qui s'y promène, et c'est elle que tu réaffrontes. La zone se complète au fil de tes combats, et les découvertes survivent à l'extinction de la console.

### Toutes les espèces peuvent apparaître dehors

Le jeu de base ne montre que **330 espèces** en overworld. Ce n'était pas une limite du moteur : sur un dump, **664 espèces** ont une entrée complète dans la table de comportement des symboles — modèle, rayon de collision, secouage de l'herbe. Le plafond était un choix de contenu.

Le randomizer le lève. Tu choisis :

- **Toutes les espèces** — 664, le défaut
- **Visibles en vanilla** — les 330 du jeu de base
- **TEST : uniquement les non prévues** — 334, celles que le jeu ne montre jamais

Un second réglage écarte les Pokémon **trop encombrants**, d'après le rayon de collision du jeu et non la taille du Pokédex : Rayquaza est enroulé et ne pèse que 70, alors que Léviator en fait 220. Ça ne touche que l'affichage — tu peux toujours les affronter.

## Ce qui se règle en jeu

Une partie des options ne réécrit aucun fichier : elles sont appliquées à l'exécution par un module. Elles demandent donc de fournir aussi ton dossier **`exefs`**.

**Courbe de difficulté**

- **EXP Share éteint au départ** — seuls les Pokémon qui combattent gagnent de l'expérience.
- **Multiplicateur d'expérience** — de 0,5 à plusieurs fois la normale, appliqué en direct.
- **Plafonds de niveau** — bloque l'expérience au-dessus d'un plafond : celui des arènes et de Tarak, un plafond dynamique qui monte avec ta progression, ou un plafond strict sur les boss. Les plafonds sont lus sur les équipes **réellement générées**, pas sur celles du jeu d'origine.

**Menu PC** — ajoute un menu au PC des Centres Pokémon. Tu y vois l'état du partage d'EXP et du boost, et tu peux les changer **en pleine partie, sans refaire une ROM**.

**Confort** — chromatiques visibles dehors, déblocage du niveau en Zone Sauvage, Pokémon qui suit et qu'on peut piloter, caméra libre, Bois Chancelier peuplé, chaîne de pêche conservée. La caméra libre s'active, mais ses réglages fins (vitesse, angles, distances) restent figés sur les valeurs par défaut.

Le combat caché et les modes Découverte décrits plus haut passent aussi par ce module.

**Filtres de génération** — limite le jeu aux générations de ton choix. Le filtre général s'applique à **tout**, Pokémon visibles dehors compris. Des champs par catégorie permettent ensuite d'affiner séparément ce que tu affrontes, ce qu'on te donne et les équipes adverses.

## Installation

Il te faut **Windows**, **Ryujinx**, et un dump de ta copie du jeu en **1.3.2** (`romfs`, plus `exefs` pour les options en jeu). [Python 3](https://www.python.org/downloads/) est nécessaire au premier lancement.

1. Clone ou télécharge ce dépôt.
2. Lance `Launch-CustomSwShRandomizer.bat`.
3. Indique tes dossiers `romfs` et `exefs`.
4. Règle tes options, puis **Générer le mod**.

Coche **Installation auto** pour que le mod parte directement dans Ryujinx. Ferme l'émulateur avant de générer.

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
