# Changelog

## V5 — 9 September 2026

This release lifts a limit everyone believed was technical, simplifies the interface, and stops redistributing game data.

*[Version française plus bas](#v5--9-septembre-2026)*

### Every Pokémon can now appear outside

The game only shows 330 species in the overworld, and that was long believed to be an engine constraint. Measured on a Sword dump: **665 species have a model archive**, and **664 have a complete entry** in `symbol_encount_mons_param.bin` — model part, collision radius, grass shake radius. Almost the whole Pokédex is ready to go.

Verified in game: Persian and Goodra, which Sword/Shield never show outside, appear normally and can be battled. Identical measurements on both versions.

New "Species allowed outside" list:

- **Every species** — 664, the new default
- **Seen in vanilla** — back to the base game's 330
- **TEST: only the unintended ones** — 334, to reproduce the experiment

### Bulk filter

A Wailord in a grass corridor blocks the view. New "Maximum bulk outside" list, based on the game's own collision radius rather than Pokédex height — the distinction matters: Rayquaza is coiled and only scores 70, while Gyarados scores 220.

| Threshold | Species removed |
|---|---|
| No colossal ones (> 250) | 4 |
| No very large ones (> 200) | 7 |
| No large ones (> 150) | 31, Gyarados included |
| Compact only (> 100) | 85 |

It affects only what you see: the battle pool stays complete, you can still fight them.

### New "Discovery, random grass" mode

The old Discovery mode left the grass vanilla until the first battle. The new one puts a random decoy there, stable per zone. You fight it, and the zone locks onto the species actually fought — same as before, but without knowing what to expect from the start.

### Wild encounter mapping finally works

The "Wild encounter mapping rule" list was displayed, clickable, saved in presets — and never read. The branch of code consuming it was unreachable: the normaliser only ever returned three values, all handled before it. Rewired.

"True random build" was also removed from both stability lists: its output was identical bit for bit to "by slot", since the stability key contains the slot coordinates and is therefore never met twice.

### Presets fixed

- **Nine options were lost on every export**: the four per-category generation filters, `ShopItemMode`, `TrainerBagItemMode`, `EvolutionMinBstGain`, `WriteInstallationPackage`, `StrictDataFiles`. Adjustable, translated, read at launch — but absent from the preset, so silently reset to defaults on import.
- **An import overwrote your ROMFS/ExeFS/output paths**, while displaying "Local paths ignored from preset". Same bug when browsing a ROMFS of the other version.

### Language

- The software starts in English, both interface and JSON reports.
- 21 dropdown lists kept their French labels hardcoded. Translated — internal values unchanged, so existing presets remain valid.
- The navigation rail and card titles froze in the previous language: the refreshes happened mid-switch, before three of the nine tabs had been renamed.

### Options removed

- Race mode and difficulty profiles: manual tuning instead.
- Six emulators out of seven. Only Ryujinx remains, with its detection, its paths and its cleanup.

### No game data redistributed any more

The name and item tables are derived from the game. They are no longer versioned — including `pokemon_species_names.csv`, which V1 published.

Instead, **the software rebuilds them itself** from your own dump on the first build, through the tools in `tools/`. All you need is Python 3; without it, the build continues in degraded mode and tells you what is missing. Verified from a pristine clone: the tables regenerate bit for bit.

One exception: trainer names (`vanilla_exports/`) have no extractor, so trainers stay anonymous in the reports.

### GPL-3.0 licence

The NPC gift catalogue from [KM-Editor](https://github.com/KotMatrosk1n/KM-Editor) is now embedded in `third_party/`, so the "NPC gift items" option works straight from a clone, with no external dependency.

That file is published under GPL-3.0-only, so the project adopts that licence. It was the cleanest route — re-extracting the same data to avoid the licence would have run into the European *sui generis* database right. The repository had no licence at all until now, which in practice forbade any reuse.

### Interface

- Unreadable status bar: 24 px tall for 16 px of internal padding, leaving 8 px for a font that occupies 17.
- Invisible help panel: a `PfTheme.Line` border (50,53,61) on a (28,29,33) background.
- Descriptions fixed: the examples cited "Amphiflore" and "Pangoléon", two Pokémon that do not exist. Replaced with Empiflor and Pingoléon (*Victreebel* and *Empoleon* in English).
- Encounters tab realigned: the "Underground" row placed its list below its label, alone of its card in doing so.

### Documentation

README cut from 1180 lines to a single page, bilingual. Internal working notes and screenshots taken out of the repository.

### Under the hood

ExLaunch module recompiled for Sword and Shield, with the new encounter mode. A previous build mixed the object files of both versions: Shield inherited Sword's offsets and would not boot. Each binary is now pure, verified in game up to the title screen. Expected SHA-256 fingerprints updated on the generator side.

---

<a name="v5--9-septembre-2026"></a>

## V5 — 9 septembre 2026 (français)

Cette version lève une limite qu'on croyait technique, simplifie l'interface, et arrête de redistribuer des données du jeu.

### Tous les Pokémon peuvent apparaître dehors

Le jeu ne montre que 330 espèces en overworld, et on a longtemps cru à une contrainte du moteur. Mesure faite sur un dump Épée : **665 espèces ont une archive de modèle**, et **664 ont une entrée complète** dans `symbol_encount_mons_param.bin` — partie de modèle, rayon de collision, rayon de secouage de l'herbe. Tout est prêt pour presque tout le Pokédex.

Vérifié en jeu : Persian et Muplodocus, que Épée/Bouclier ne montrent jamais dehors, apparaissent normalement et se combattent sans problème. Mesures identiques sur les deux versions.

Nouvelle liste « Espèces autorisées dehors » :

- **Toutes les espèces** — 664, le nouveau défaut
- **Visibles en vanilla** — retour aux 330 du jeu de base
- **TEST : uniquement les non prévues** — 334, pour refaire l'expérience

### Filtre d'encombrement

Un Wailord dans un couloir d'herbe, ça bouche la vue. Nouvelle liste « Encombrement maximal dehors », basée sur le rayon de collision du jeu et non sur la taille du Pokédex — la distinction compte : Rayquaza est enroulé et ne pèse que 70, alors que Léviator en fait 220.

| Palier | Espèces retirées |
|---|---|
| Sans les colosses (> 250) | 4 |
| Sans les très gros (> 200) | 7 |
| Sans les gros (> 150) | 31, Léviator compris |
| Compact (> 100) | 85 |

Ça ne touche que ce que tu vois : le réservoir de combat reste complet, tu peux toujours les affronter.

### Nouveau mode « Découverte, herbe aléatoire »

L'ancien mode Découverte laissait l'herbe vanilla jusqu'au premier combat. Le nouveau y met un leurre tiré au sort, stable par zone. Tu le combats, et la zone se fige sur l'espèce réellement affrontée — comme avant, mais sans savoir à quoi t'attendre dès le départ.

### Le mapping des rencontres sauvages fonctionne enfin

La liste « Règle de mapping sauvage » était affichée, cliquable, sauvegardée dans les presets — et jamais lue. La branche du code qui la consommait était inatteignable : le normalisateur ne renvoyait que trois valeurs, toutes traitées avant elle. Rebranchée.

Au passage, « Vrai random build » a été retiré des deux listes de stabilité : ses sorties étaient identiques au bit près à celles de « par slot », la clé de stabilité contenant les coordonnées du slot, elle n'était jamais rencontrée deux fois.

### Presets réparés

- **Neuf options se perdaient à chaque export** : les quatre filtres de génération par catégorie, `ShopItemMode`, `TrainerBagItemMode`, `EvolutionMinBstGain`, `WriteInstallationPackage`, `StrictDataFiles`. Réglables, traduites, lues au lancement — mais absentes du preset, donc silencieusement remises par défaut à l'import.
- **Un import écrasait tes chemins ROMFS/ExeFS/sortie**, tout en affichant « Chemins locaux ignorés depuis le preset ». Même bug en parcourant un ROMFS de l'autre version.

### Langue

- Le logiciel démarre en anglais, interface et rapports JSON.
- 21 listes déroulantes gardaient leurs libellés français écrits en dur. Traduites — valeurs internes inchangées, donc les presets existants restent valides.
- Le rail de navigation et les titres de cartes se figeaient dans la langue précédente : les rafraîchissements arrivaient au milieu de la bascule, avant que trois onglets sur neuf soient renommés.

### Options retirées

- Mode race et profils de difficulté : place au réglage manuel.
- Six émulateurs sur sept. Seul Ryujinx reste, avec sa détection, ses chemins et son nettoyage.

### Plus aucune donnée du jeu redistribuée

Les tables de noms et d'objets sont dérivées du jeu. Elles ne sont plus versionnées — y compris `pokemon_species_names.csv`, que la V1 publiait.

À la place, le logiciel les reconstruit tout seul depuis ton propre dump à la première génération, via les outils de `tools/`. Il te faut juste Python 3 ; sans lui, la génération continue en mode dégradé et te dit ce qui manque. Vérifié depuis un clone vierge : les tables se régénèrent à l'octet près.

Seule exception, les noms de dresseurs (`vanilla_exports/`) n'ont pas d'extracteur : sans eux les dresseurs restent anonymes dans les rapports.

### Licence GPL-3.0

Le catalogue des cadeaux PNJ de [KM-Editor](https://github.com/KotMatrosk1n/KM-Editor) est désormais embarqué dans `third_party/`, pour que l'option « objets offerts par les PNJ » fonctionne dès le clonage, sans dépendance externe.

Ce fichier est publié sous GPL-3.0-only : le projet adopte donc cette licence. C'était le choix le plus propre — réextraire les mêmes données pour éviter la licence se serait heurté au droit européen *sui generis* sur les bases de données. Le dépôt n'avait jusqu'ici aucune licence, ce qui interdisait en pratique toute réutilisation.

### Interface

- Barre d'état illisible : 24 px de haut pour 16 px de marge interne, il ne restait que 8 px pour une police qui en occupe 17.
- Encadré d'aide invisible : bordure `PfTheme.Line` (50,53,61) sur un fond (28,29,33).
- Descriptions corrigées : les exemples citaient « Amphiflore » et « Pangoléon », deux Pokémon qui n'existent pas. Remplacés par Empiflor et Pingoléon (*Victreebel* et *Empoleon* côté anglais).
- Onglet Rencontres réorganisé : la rangée « Underground » posait sa liste sous son étiquette, seule de sa carte à le faire.

### Documentation

README ramené de 1180 lignes à une page courte, bilingue. Notes de travail internes et captures d'écran sorties du dépôt.

### Sous le capot

Module ExLaunch recompilé pour Épée et Bouclier, avec le nouveau mode de rencontre. Un build précédent mélangeait les objets des deux versions : Bouclier héritait des offsets d'Épée et ne se lançait pas. Chaque binaire est désormais pur, vérifié en jeu jusqu'à l'écran-titre. Empreintes SHA-256 attendues mises à jour côté générateur.

---

## v2.5 and earlier / et antérieures

See the commit history / voir l'historique des commits.
