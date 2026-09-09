[CmdletBinding()]
param(
    [string]$SourceRomfs,
    [string]$SourceExefs,
    [string]$OutputRomfs,
    [string]$GameVersion = "Sword",
    [switch]$AutoInstallToEden,
    [string]$EdenModName = "Randomizer",
    [bool]$InstallToRyujinx = $true,
    [long]$Seed = -1,
    [string]$TrainerSpeciesMode = "Random",
    [string]$TrainerMoveMode = "Random4",
    [string]$TrainerSmogonMoveFallbackMode = "LastLevelUp4",
    [string]$TrainerItemMode = "RandomWhenPresent",
    [string]$TrainerItemPoolMode = "Battle",
    [string]$TrainerAddedSlotSpeciesMode = "Random",
    [string]$TrainerDuplicateMode = "NoDuplicates",
    [string]$TrainerAbilityMode = "Unchanged",
    [string]$TrainerIVMode = "Unchanged",
    [string]$TrainerEVMode = "Unchanged",
    [string]$TrainerNatureMode = "Unchanged",
    [switch]$RandomizeTrainerNatures,
    [double]$TrainerLevelMultiplier = 1.0,
    [int]$TrainerTeamMin = -1,
    [int]$TrainerTeamMax = -1,
    [switch]$TrainerTypeThemed,
    [double]$TrainerShinyChancePercent = 0.0,
    [switch]$ForceTrainerFullyEvolved,
    [int]$TrainerFullyEvolvedLevel = 40,
    [switch]$MaxTrainerAI,
    #   TrainerBagItemMode : Unchanged | None | Random
    #     Unchanged  le sac du jeu, intact
    #     None       sac vide : plus aucun dresseur ne soigne en combat
    #     Random     des soins tires au hasard
    #   Mesure du 2026-09-07 : 52 dresseurs sur 437 portent un objet, surtout
    #   des Guerison et des Potions. Les vider change nettement la difficulte
    #   des combats de boss.
    [string]$TrainerBagItemMode = "Unchanged",
    [string]$TrainerDynamaxLevelMode = "Unchanged",
    [switch]$ForceTrainerCanDynamax,
    [switch]$ForceAllTeamsToSix,
    [switch]$AllowLegendaryTrainers,
    # Regles speciales de dresseurs. Trois classes, comme dans le Universal
    # Pokemon Randomizer : Boss (arenes, Conseil 4, Maitre), Important (rivaux,
    # Team Yell/Macro Cosmos), Normal (tous les autres).
    [int]$TrainerExtraPokemonBoss = 0,
    [int]$TrainerExtraPokemonImportant = 0,
    [int]$TrainerExtraPokemonRegular = 0,
    [string]$TrainerSpecialRuleScope = "GymLeague",
    [string]$TrainerLegendaryPolicy = "Unchanged",
    [int]$TrainerMinBaseStatTotal = 0,
    # Portee de la regle "pas deux fois le meme type dans une equipe".
    # Off | GymLeague | AllBosses | Everyone
    [string]$TrainerForceDiverseTypes = "Off",
    [string]$TypeMode = "Unchanged",
    [switch]$TypesMonotypeOnly,
    [string]$AbilityMode = "Unchanged",
    [switch]$AllowWonderGuard,
    [string]$StatMode = "Unchanged",
    [double]$ExpYieldMultiplier = 1.0,
    [switch]$ForceOneExpYield,
    [switch]$RandomizeMoveTypes,
    [switch]$RandomizeMovePower,
    [int]$MovePowerMin = 20,
    [int]$MovePowerMax = 150,
    [switch]$RandomizeMovePP,
    [int]$MovePPMin = 5,
    [int]$MovePPMax = 40,
    [switch]$RandomizeMoveAccuracy,
    [int]$MoveAccuracyMin = 70,
    [int]$MoveAccuracyMax = 100,
    [switch]$RandomizeMoveCategory,
    [switch]$RandomizePickupItems,
    [switch]$RandomizeShopItems,
    [switch]$RandomizeTechnicalRecords,
    # Multiplicateur applique au prix d'achat de tous les objets.
    # "0" rend tout gratuit, "1" ne change rien.
    [string]$ShopPriceMultiplier = "1",
    #   ShopPriceMode : Vanilla | Multiplier | Random
    #     Vanilla      les prix du jeu, intacts
    #     Multiplier   les prix du jeu x ShopPriceMultiplier
    #     Random       un prix tire entre ShopPriceMin et ShopPriceMax
    #   Un objet invendable (prix 0) le reste dans les trois modes.
    #   ShopItemMode : SamePocket (meme genre) | FullRandom (toutes les poches
    #                  que cette boutique vend deja, jamais une poche etrangere)
    #     SamePocket  une Poke Ball devient une Poke Ball, un soin un soin.
    #                 C'est le defaut, et c'est ce qui a repare le plantage
    #                 observe le 2026-09-07 : une CT mise en vente dans un
    #                 marche ordinaire vidait la liste et plantait a l'achat.
    #     FullRandom  n'importe quel objet, SAUF les machines (poche 5) et les
    #                 objets cles (poche 8). Les machines sont la seule cause de
    #                 plantage que j'aie identifiee ; les objets cles ne doivent
    #                 jamais etre vendables. Le reste est ouvert.
    [string]$ShopItemMode = "SamePocket",
    [string]$ShopPriceMode = "Multiplier",
    [int]$ShopPriceMin = 100,
    [int]$ShopPriceMax = 20000,
    # Objets ramassables du terrain : les Poke Balls posees au sol, et les
    # objets invisibles. Les deux vivent dans placement.gfpak.
    [switch]$RandomizeFieldItems,
    [switch]$RandomizeHiddenItems,
    [string]$FieldItemPoolMode = "Safe",
    # Fonctionnalites de confort deja presentes dans le module ExLaunch et
    # jusqu'ici non exposees. Toutes s'appliquent a l'execution.
    [switch]$ModOverworldShiny,
    [int]$OverworldShinyBoostPercent = 0,
    [switch]$ModUnderworld,
    [switch]$ModCameraTweaks,
    [switch]$ModUncapLevel,
    [switch]$ModFreecam,
    [switch]$ModGlimwoodOverworld,
    [int]$GlimwoodMaxSpawns = 5,
    [switch]$ModSynchroMode,
    [switch]$ModExtendedFollowing,
    [switch]$ModFishingTweaks,
    [switch]$ModDexAnimations,
    # Transforme l'absence d'un fichier de donnees en erreur au lieu d'une
    # degradation muette. Hors de ce mode, l'absence est signalee bruyamment
    # mais la generation continue - le comportement historique est preserve.
    [switch]$StrictDataFiles,
    # Reglages appliques directement sur la table personal_total.bin.
    [int]$MinimumCatchRate = 0,
    [string]$ExpCurveMode = "Unchanged",
    [string]$TmCompatibilityMode = "Unchanged",
    # Qui peut apprendre quoi aupres des maitres de capacites de l'Ile solitaire
    # de l'Armure. Meme mecanique que TmCompatibilityMode, autre champ de bits.
    [string]$TutorCompatibilityMode = "Unchanged",
    # Quelle ATTAQUE chaque CT/DT enseigne. A ne pas confondre avec
    # TmCompatibilityMode, qui dit QUI peut l'apprendre.
    [string]$TmMoveMode = "Unchanged",
    # Les attaques apprises en montant de niveau. Les NIVEAUX sont conserves :
    # seule l'attaque enseignee a chaque palier change.
    [string]$LearnsetMoveMode = "Unchanged",
    # Les objets offerts par les PNJ. Les objets CLES ne sont jamais touches :
    # remplacer le Velo Rotom ou le Bracelet Dynamax bloquerait la partie.
    [string]$NpcGiftItemMode = "Unchanged",
    [switch]$RandomizeWildHeldItems,
    [string]$EvolutionMode = "Unchanged",
    [switch]$AllowLegendaryEvolutions,
    # Contraintes sur les cibles d'evolution tirees au sort.
    [switch]$EvolutionForceGrowth,
    [switch]$EvolutionSameType,
    # Gain minimal de statistiques de base exige de la cible d'evolution.
    #   -1  aucune contrainte (defaut)
    #    0  au moins equivalent - la cible ne peut pas etre plus faible
    #   10  au moins 10 points de plus
    # C'est un PLANCHER : avec +10 sur un Pokemon a 300 de total, un candidat a
    # 600 reste valable. On ne vise pas 310, on exige 310 au minimum.
    # EvolutionForceGrowth reste accepte et vaut un gain minimal de 1.
    [int]$EvolutionMinBstGain = -1,
    # Une evolution herite du tirage de sa forme de base.
    [switch]$FollowEvolutionsForTypes,
    [switch]$FollowEvolutionsForAbilities,
    # Coupe les chaines d'evolution au-dela de trois stades.
    [switch]$EvolutionLimitToThreeStages,
    [bool]$NormalizeFriendshipEvolutions = $false,
    [int]$FriendshipEvolutionLevel = 30,
    [bool]$NormalizeTradeEvolutions = $false,
    [int]$TradeEvolutionLevel = 37,
    [switch]$NormalizeSpecialEvolutions,
    [int]$SpecialEvolutionLevel = 36,
    [string]$GiftMode = "Unchanged",
    [string]$StarterMode = "Unchanged",
    [string]$Starter1 = "",
    [string]$Starter2 = "",
    [string]$Starter3 = "",
    [bool]$PatchStarterRelatedTrainers = $true,
    # Bornes de statistiques totales pour les starters tires au sort. 0 = pas
    # de borne.
    [int]$StarterMinBaseStatTotal = 0,
    [int]$StarterMaxBaseStatTotal = 0,
    [switch]$AllowLegendaryGifts,
    [string]$TradeMode = "Unchanged",
    [switch]$AllowLegendaryTrades,
    [string]$StaticEncounterMode = "Unchanged",
    [switch]$AllowLegendaryStaticEncounters,
    [string]$StaticEncounterStableMapping = "Slot",
    [string]$GrassEncounterMode = "Unchanged",
    [switch]$AllowLegendaryGrassEncounters,
    [string]$GrassEncounterStableMapping = "Slot",
    [string]$VisibleEncounterBehavior = "MasqueFixe",
    [string]$EncounterDrawMode = "SlotParEspece",
    # Rencontres runtime : deux reglages independants, appliques par le module
    # ExLaunch et non par les fichiers ROMFS.
    #   LiveVisibleMode : Vanilla | Random | Zone | Global | Decouverte
    #   LiveBattleMode  : Vanilla | Random | Zone | Global
    [string]$LiveVisibleMode = "Vanilla",
    [string]$LiveBattleMode = "Zone",
    [switch]$AllowLegendaryLiveVisible,
    [switch]$AllowLegendaryLiveBattle,
    [string]$LiveGenerationFilter = "1,2,3,4,5,6,7,8",
    # Quelles especes ont le droit d'apparaitre DEHORS.
    #   All         : toutes les especes jouables (664 sur un dump Epee). DEFAUT.
    #   Vanilla     : les 330 que le jeu utilise deja comme symboles.
    #   UnusualOnly : UNIQUEMENT celles que le vanilla ne montre jamais.
    #
    # Le defaut a ete elargi apres verification EN JEU le 2026-09-09 : le
    # mode UnusualOnly a fait apparaitre Persian (#53) et Muplodocus (#706),
    # deux especes que Epee/Bouclier ne montrent JAMAIS dehors. Modele,
    # echelle, collision et declenchement du combat : tout fonctionne. Le
    # plafond de 330 etait un choix de contenu, pas une limite du moteur.
    # UnusualOnly reste disponible pour refaire le test.
    [string]$OverworldVisiblePoolMode = "All",
    # Encombrement maximal tolere pour un Pokemon VISIBLE dehors, en rayon
    # de collision lu dans symbol_encount_mons_param.bin. 0 = aucune limite.
    # Mesure du 2026-09-09 sur un dump Epee, 664 especes : mediane 47,
    # minimum 14, maximum 400 (Wailord et Onix). Reperes utiles :
    #   > 250 exclut 4 especes, > 200 en exclut 7, > 150 en exclut 31.
    # Ce filtre ne touche NI le reservoir de combat, NI les especes deja
    # revelees en mode decouverte : un colosse affronte se promenera bien
    # dans sa zone ensuite, c'est voulu.
    [int]$OverworldVisibleMaxHitbox = 0,
    # Pourcentage applique aux niveaux des Pokemon sauvages. 0 = inchange.
    [int]$WildLevelPercent = 0,
    [string]$UndergroundMode = "Unchanged",
    [switch]$AllowLegendaryUnderground,
    # Restreindre les rencontres fixes et le souterrain aux especes que le
    # VANILLA fait deja apparaitre dehors (330, lues dans encount_symbol_*).
    #
    # CE N'EST PAS une contrainte technique, et j'ai d'abord cru le contraire.
    # Mesure du 2026-09-07 : le romfs de base porte 575 archives de modele, dont
    # 281 pour des especes qui ne sont jamais des symboles en vanilla. Et 36
    # symboles vanilla n'ont aucune archive ici - leurs modeles sont dans les
    # extensions. On ne peut donc pas deduire de ce dump quelles especes savent
    # s'afficher ; les 330 sont un choix de Game Freak, pas une limite du jeu.
    #
    # Le mod « underworld » du module fait d'ailleurs exactement l'inverse : il
    # detourne le generateur de symboles vers la table des herbes hautes pour
    # faire apparaitre dehors des especes qui n'y sont jamais. Il fonctionne.
    #
    # L'option reste disponible pour qui veut rester pres du vanilla, mais elle
    # est COUPEE par defaut : elle reduisait les rencontres fixes de 410 a 281
    # especes sans benefice demontre.
    [bool]$OverworldModelSafeEncounters = $false,
    # Le dossier Installation est une COPIE DE CONFORT : 6210 fichiers dupliques
    # pour sept emulateurs, alors que la ROM est deja complete dans la sortie.
    # Les tests n'en ont aucun besoin, et le recopier a chaque generation
    # laissait des poignees ouvertes : une suite de quarante generations finissait
    # par voir des Remove-Item echouer en cascade et sortir en code 1 avec des
    # ROMs pourtant justes. On peut donc le sauter.
    [bool]$WriteInstallationPackage = $true,
    # Un filtre de generation par CATEGORIE. Vide = « suivre le filtre global
    # LiveGenerationFilter ». Format identique : "1,2,8".
    #
    #   Visible   ce que tu vois se promener dehors
    #   Battle    ce que tu combats : hautes herbes, symboles, fixes, souterrain
    #   Gifts     ce qu'on te donne : cadeaux, starters, echanges
    #   Trainers  les equipes des dresseurs
    #
    # Exemple « joueur en generation 1, adversaires en tout » :
    #   -GenerationFilterGifts "1" -GenerationFilterBattle "1"
    #   et GenerationFilterTrainers laisse vide.
    [string]$GenerationFilterVisible = "",
    [string]$GenerationFilterBattle = "",
    [string]$GenerationFilterGifts = "",
    [string]$GenerationFilterTrainers = "",
    [switch]$ForceBossTeamsToSix,
    [string]$BossTeamsToSixScope = "MajorBosses",
    [switch]$DisableExpShare,
    [bool]$EarlyBike = $false,
    [bool]$RuntimePcControls = $false,
    [switch]$DynamicExpLevelCap,
    [switch]$StrictBossMaxLevelCap,
    [switch]$MainStorySoftLevelCap,
    [switch]$GymLeagueStoryLevelCap,
    [switch]$StoryMajorBattleOrderLevelCap,
    [bool]$ExportJsonReport = $true,
    [bool]$ExportEncounterZoneReport = $true,
    [string]$ReportLanguage = "en",
    [string]$UiLanguage = "en",
    [string]$GuiTheme = "Dark",
    [string]$JsonReportPath = "",
    [switch]$SkipInitialCopy,
    [switch]$NoGui
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# La version du logiciel, ecrite A UN SEUL ENDROIT.
#
# Elle etait auparavant recopiee dans quinze chaines litterales, et elles
# avaient derive : l'interface annoncait V4.17 tandis que quatre rapports
# JSON ecrivaient V4.18. Un rapport qui ment sur sa propre version rend tout
# diagnostic a posteriori impossible. Un test de la suite verifie qu'aucun
# litteral de version ne reapparait ailleurs dans le fichier.
$AppVersion = "V5.0"

$PersonalRecordSize = 0xB0
$PersonalBaseExpOffset = 0x22
$LearnsetRecordSize = 0x104
$TrainerPokemonRecordSize = 0x20
$EvolutionRecordSize = 8
$EvolutionRecordsPerSpecies = 9
$BaseSpeciesMax = 898
$WonderGuardAbilityId = 25
$TrainerNatureMax = 24
$SmogonNatureIds = @{
    hardy = 0
    lonely = 1
    brave = 2
    adamant = 3
    naughty = 4
    bold = 5
    docile = 6
    relaxed = 7
    impish = 8
    lax = 9
    timid = 10
    hasty = 11
    serious = 12
    jolly = 13
    naive = 14
    modest = 15
    mild = 16
    quiet = 17
    bashful = 18
    rash = 19
    calm = 20
    gentle = 21
    sassy = 22
    careful = 23
    quirky = 24
}
$FrenchLanguageId = 5
$EnglishLanguageId = 9
$DataRootCandidates = @(
    $PSScriptRoot
)

# Fichiers de donnees attendus, et ce que leur absence degrade EXACTEMENT.
#
# Pourquoi ce manifeste existe : chaque Get-*Data retombe silencieusement sur
# une table vide quand son fichier manque. Aucune erreur, aucun avertissement,
# et le resultat reste plausible - c'est le motif de defaut dominant du projet.
# Mesure du 2026-09-05 : sans items.csv, Get-TrainerItemPool renvoie les memes
# 139 objets de repli pour TOUS les modes, donc le reglage "pool d'objets des
# dresseurs" de l'interface est totalement inerte et personne ne peut le voir.
#
# Une entree decrit le fichier, pas le code : ajouter un fichier ici ne change
# aucun comportement, cela le rend seulement visible dans le diagnostic.
$DataFileManifest = @(
    [pscustomobject]@{
        RelativePath = "pokemon_species_names.csv"
        Purpose = "Noms des espèces (FR/EN) dans les rapports et l'interface."
        Degradation = "Les rapports affichent 'Species <id>' au lieu du nom."
        Severity = "moyenne"
    },
    [pscustomobject]@{
        RelativePath = "item-id-map.csv"
        Purpose = "Traduit les identifiants d'objets du cache Smogon vers ceux du jeu."
        Degradation = "Le mode Smogon n'attribue plus d'objet stratégique et retombe sur le pool général."
        Severity = "moyenne"
    },
    [pscustomobject]@{
        RelativePath = "npc-gifts.csv"
        Purpose = "Cadeaux d'objets des PNJ : fichier .amx, cellule, objet offert."
        Degradation = "L'option « objets offerts par les PNJ » n'a AUCUN EFFET."
        Severity = "moyenne"
    },
    [pscustomobject]@{
        RelativePath = "items.csv"
        Purpose = "Catalogue des objets et leurs catégories."
        Degradation = "Le pool d'objets tenus retombe sur 139 objets codes en dur et le mode de pool choisi n'a PLUS AUCUN EFFET."
        Severity = "haute"
    },
    [pscustomobject]@{
        RelativePath = "item_names.csv"
        Purpose = "Noms des objets (FR/EN)."
        Degradation = "Les rapports affichent 'Item <id>' au lieu du nom."
        Severity = "moyenne"
    },
    [pscustomobject]@{
        RelativePath = "move_names.csv"
        Purpose = "Noms des attaques (FR/EN)."
        Degradation = "Les rapports affichent 'Move <id>' au lieu du nom."
        Severity = "moyenne"
    },
    [pscustomobject]@{
        RelativePath = "vanilla_exports\pokemon_sword_global_en.json"
        Purpose = "Noms et classes de dresseurs en anglais."
        Degradation = "Les dresseurs sont anonymes dans les rapports."
        Severity = "moyenne"
    },
    [pscustomobject]@{
        RelativePath = "vanilla_exports\pokemon_sword_global_fr.json"
        Purpose = "Noms et classes de dresseurs en français."
        Degradation = "Les dresseurs sont anonymes dans les rapports."
        Severity = "moyenne"
    }
)
$ExpShareDisablePatchDefinitions = @(
    [pscustomobject]@{
        Game = "Sword"
        BuildId = "A3B75BCD3311385AEED67FBEEB79CBB7BF02F471"
        Offset = 0x7FB3C0
        Data = [byte[]](0x00, 0x00, 0x80, 0x52)
    },
    [pscustomobject]@{
        Game = "Shield"
        BuildId = "A16802625E7826BF83B6F9708E475B912A9AB7DF"
        Offset = 0x7FB3C0
        Data = [byte[]](0x00, 0x00, 0x80, 0x52)
    }
)
$GymLeagueStoryCapPatchSpeciesBase = 890
# Cartes posees par Add-PfCardAround. Leur titre et leur sous-titre viennent
# soit d'un libelle existant - qui est deja traduit, donc rien a maintenir en
# double - soit d'un couple fr/en donne a l'appel.
$script:PfCardRegistry = @()
$script:PfNavRail = $null
$script:PfTabs = $null
$script:PfPageTitle = $null
$script:DataFileDiagnostics = @()
$script:TrainerItemPoolFallbackWarned = $false
$script:ApplyingUiLanguage = $false
# Changer la version de jeu remet les chemins ROMFS/ExeFS/sortie a leur valeur
# par defaut. C'est voulu quand l'utilisateur bascule le menu lui-meme, mais pas
# quand le changement vient d'un import de preset ou de la detection automatique
# apres un Parcourir : dans ces deux cas le chemin vient d'etre choisi et
# l'ecraser le perdait sans le moindre avertissement.
$script:SuppressGameVersionPathReset = $false
$script:ApplyingCompatibilityUi = $false
$script:LastDetailsDescription = $null
$script:SpeciesNameData = $null
$script:ItemData = $null
# Sous Set-StrictMode -Version Latest, lire une variable de portee script jamais
# affectee leve une exception. Le cache doit donc etre declare ici, pas seulement
# affecte dans la fonction qui le remplit.
$script:ExistingItemIds = $null
$script:NpcGiftCatalog = $null
$script:SmogonItemIdMap = $null
$script:MoveTypeTable = $null
$script:PythonCommandProbed = $false
$script:PythonCommand = $null
$script:SymbolHitboxTable = $null
$script:MachineMoveTable = $null
$script:ItemPocketMap = $null
$script:PlaceholderItemIds = $null
$script:ItemNameData = $null
# Correspondance hachage <-> identifiant d'objet, lue une seule fois depuis
# bin\pml\item\item_hash_to_index.dat.
$script:ItemHashLookup = $null
$script:MoveNameData = $null
$script:SmogonStrategicData = $null
$script:SmogonStrategicLegacyData = $null
$script:VanillaTrainerMetadata = $null
# POCHES D'OBJETS - vocabulaire du JEU, pas d'un jeu de donnees externe.
#
# `items.csv` est desormais derive du dump par tools/build-items-csv.py, et sa
# colonne `category_id` porte la poche telle que le jeu la stocke
# (item.dat, enregistrement +0x11). Les anciennes valeurs 5/6/7/12/13/15/17/19
# venaient d'une taxonomie externe et ne voulaient plus rien dire ici.
#
# Trois poches seulement sont utilisees, et chacune a son temoin :
#
#   5   machines     les 200 objets de la table CT/DT, EXACTEMENT - ni faux
#                    positif ni oubli, verifie par build-items-csv.py qui
#                    refuse d'ecrire si la concordance se perd
#   8   objets cles  prix nul sur les 47
#   33  Poke Balls   identifiants 1 a 16, prix nul
#
# Les huit autres poches ne sont PAS identifiees : sans table de noms, les
# nommer serait deviner. On ne s'en sert donc que pour EXCLURE ce qui est
# prouve, jamais pour inclure ce qui est suppose.
$ItemPocketMachines = 5
$ItemPocketKeyItems = 8
$ItemPocketPokeBalls = 33
# Un Pokemon ne tient utilement ni une CT, ni un objet cle, ni une Ball.
$TrainerHeldItemExcludedPockets = [System.Collections.Generic.HashSet[int]]::new()
@($ItemPocketMachines, $ItemPocketKeyItems, $ItemPocketPokeBalls) | ForEach-Object { $null = $TrainerHeldItemExcludedPockets.Add([int]$_) }
# L'ancienne liste d'exclusions par nom (« smoke-ball », les nectars...) a ete
# retiree : elle designait des objets par leur nom dans la taxonomie externe,
# que le fichier derive du jeu ne porte pas. Elle n'aurait plus jamais rien
# exclu, ce qui est pire qu'une exclusion absente : ca en donne l'illusion.
$FallbackTrainerHeldItemPool = [int[]]@(
    136, 137, 138, 139, 140, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 186, 187, 190,
    191, 194, 196, 197, 198, 199, 207, 209, 210, 211, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 230, 231, 232, 242, 243, 244, 245,
    246, 247, 248, 249, 250, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 272, 273, 274, 275, 276, 277, 278, 279, 280, 281, 282, 283, 284,
    285, 286, 287, 288, 289, 290, 291, 292, 293, 294, 295, 303, 304, 581, 582, 583, 584, 585, 586, 587, 588, 589, 590, 682, 683, 684, 688, 689, 690, 723, 883, 896,
    897, 898, 899, 900, 901, 1176, 1177, 1178, 1179, 1180, 1181
)

function Get-SelectedExpLevelCapMode {
    if ([bool]$MainStorySoftLevelCap) {
        return "storyMainProgressionSoft"
    }
    if ([bool]$GymLeagueStoryLevelCap) {
        return "storyGymLeague"
    }
    if ([bool]$StoryMajorBattleOrderLevelCap) {
        return "storyOrderedMajorBattles"
    }
    if ([bool]$StrictBossMaxLevelCap) {
        return "strictBossMaxLevel"
    }
    if ([bool]$DynamicExpLevelCap) {
        return "receiverVsDefeatedPokemon"
    }
    return "none"
}

function Get-AnyExpLevelCapEnabled {
    return ((Get-SelectedExpLevelCapMode) -ne "none")
}

function Get-EffectiveDynamicExpLevelCapEnabled {
    return (Get-AnyExpLevelCapEnabled)
}

function Get-RuntimeExpMultiplierEnabled {
    return ((-not [bool]$ForceOneExpYield) -and ([Math]::Abs([double]$ExpYieldMultiplier - 1.0) -gt 0.0001))
}

function Get-RandomizerPcMenuEnabled {
    return [bool]$RuntimePcControls
}

function Get-NormalizedVisibleEncounterBehavior {
    param([string]$Value)

    $normalized = ([string]$Value).Trim().ToLowerInvariant()
    switch ($normalized) {
        "masquefixe" { return "MasqueFixe" }
        "masque_fixe" { return "MasqueFixe" }
        "fixedmask" { return "MasqueFixe" }
        "fixed_mask" { return "MasqueFixe" }
        "lock" { return "MasqueFixe" }
        "locked" { return "MasqueFixe" }
        "vanillavisualbattlelock" { return "MasqueFixe" }
        "vanilla_visual_battle_lock" { return "MasqueFixe" }
        "vanillalock" { return "MasqueFixe" }
        "vanillalocked" { return "MasqueFixe" }
        "randomvisualbattlelock" { return "MasqueFixe" }
        "random_visual_battle_lock" { return "MasqueFixe" }
        "randomlock" { return "MasqueFixe" }
        "randomlocked" { return "MasqueFixe" }
        "revelationpermanente" { return "RevelationPermanente" }
        "revelation_permanente" { return "RevelationPermanente" }
        "revelepermanent" { return "RevelationPermanente" }
        "revele_stable" { return "RevelationPermanente" }
        "revealedstable" { return "RevelationPermanente" }
        "revealed_stable" { return "RevelationPermanente" }
        "vanillavisualbattlerandom" { return "RevelationPermanente" }
        "vanilla_visual_battle_random" { return "RevelationPermanente" }
        "randomvisualbattlerandom" { return "RevelationPermanente" }
        "random_visual_battle_random" { return "RevelationPermanente" }
        "vanillavisualbattleloop" { return "RevelationPermanente" }
        "vanilla_visual_battle_loop" { return "RevelationPermanente" }
        "randomvisualbattleloop" { return "RevelationPermanente" }
        "random_visual_battle_loop" { return "RevelationPermanente" }
        "romfsmatch" { return "RomfsMatch" }
        "romfs_match" { return "RomfsMatch" }
        "match" { return "RomfsMatch" }
        default { return "MasqueFixe" }
    }
}

function Get-NormalizedEncounterDrawMode {
    param(
        [string]$Value,
        [string]$LegacyVisibleBehavior = ""
    )

    $normalized = ([string]$Value).Trim().ToLowerInvariant()
    switch ($normalized) {
        "slotparespece" { return "SlotParEspece" }
        "slot_par_espece" { return "SlotParEspece" }
        "slot_species" { return "SlotParEspece" }
        "species" { return "SlotParEspece" }
        "espece" { return "SlotParEspece" }
        "espÃ¨ce" { return "SlotParEspece" }
        "fullrandom" { return "FullRandom" }
        "full_random" { return "FullRandom" }
        "random" { return "FullRandom" }
        "visiblefixetiragerandom" { return "VisibleFixeTirageRandom" }
        "visible_fixe_tirage_random" { return "VisibleFixeTirageRandom" }
        "fixed_visible_random_battle" { return "VisibleFixeTirageRandom" }
    }

    $legacy = ([string]$LegacyVisibleBehavior).Trim().ToLowerInvariant()
    switch ($legacy) {
        "randomvisualbattlerandom" { return "FullRandom" }
        "random_visual_battle_random" { return "FullRandom" }
        "randomvisualbattleloop" { return "FullRandom" }
        "random_visual_battle_loop" { return "FullRandom" }
        "randomloop" { return "FullRandom" }
        "loop" { return "FullRandom" }
        "separate" { return "FullRandom" }
        default { return "SlotParEspece" }
    }
}

function Get-LiveEncounterRandomizerMode {
    $behavior = Get-NormalizedVisibleEncounterBehavior -Value $VisibleEncounterBehavior
    $drawMode = Get-NormalizedEncounterDrawMode -Value $EncounterDrawMode -LegacyVisibleBehavior $VisibleEncounterBehavior
    if ($behavior -eq "RomfsMatch") {
        return "off"
    }
    if ($drawMode -eq "FullRandom") {
        return "full_random"
    }
    if ($drawMode -eq "VisibleFixeTirageRandom") {
        return "visible_fixe_tirage_random"
    }
    switch ($behavior) {
        "MasqueFixe" { return "slot_par_espece" }
        "RevelationPermanente" { return "slot_par_espece" }
        default { return "off" }
    }
}

function Get-LiveEncounterVisibleBehaviorValue {
    $behavior = Get-NormalizedVisibleEncounterBehavior -Value $VisibleEncounterBehavior
    switch ($behavior) {
        "MasqueFixe" { return "masque_fixe" }
        "RevelationPermanente" { return "revelation_permanente" }
        default { return "off" }
    }
}

function Get-LiveEncounterDrawModeValue {
    $drawMode = Get-NormalizedEncounterDrawMode -Value $EncounterDrawMode -LegacyVisibleBehavior $VisibleEncounterBehavior
    switch ($drawMode) {
        "FullRandom" { return "full_random" }
        "VisibleFixeTirageRandom" { return "visible_fixe_tirage_random" }
        default { return "slot_par_espece" }
    }
}

function Get-LiveEncounterMappingValue {
    $drawMode = Get-NormalizedEncounterDrawMode -Value $EncounterDrawMode -LegacyVisibleBehavior $VisibleEncounterBehavior
    switch ($drawMode) {
        "SlotParEspece" { return "species" }
        "FullRandom" { return "random" }
        "VisibleFixeTirageRandom" { return "random" }
        default { return (Normalize-StableMappingMode -Value $GrassEncounterStableMapping).ToLowerInvariant() }
    }
}

# ---------------------------------------------------------------------------
# RENCONTRES RUNTIME â€” deux reglages independants
#
#   LiveVisibleMode : ce qui APPARAIT dans l'herbe
#   LiveBattleMode  : ce qu'on AFFRONTE
#
# Les deux valeurs partent telles quelles dans config.toml et sont appliquees
# par le module ExLaunch. Elles ne touchent AUCUN fichier ROMFS : c'est ce qui
# permet de les changer sans regenerer une run complete.
#
# Les anciennes listes VisibleEncounterBehavior / EncounterDrawMode decrivaient
# un seul mecanisme melange et restent presentes pour la compatibilite des
# presets et des rapports ; elles ne pilotent plus le module.
# ---------------------------------------------------------------------------

$LiveGenerationRanges = @{
    1 = @(1, 151)
    2 = @(152, 251)
    3 = @(252, 386)
    4 = @(387, 493)
    5 = @(494, 649)
    6 = @(650, 721)
    7 = @(722, 809)
    8 = @(810, 898)
}

function Get-NormalizedLiveEncounterMode {
    param(
        [string]$Value,
        [string]$Fallback = "vanilla",
        [bool]$AllowDiscovery = $false
    )

    switch (([string]$Value).Trim().ToLowerInvariant()) {
        "vanilla" { return "vanilla" }
        "unchanged" { return "vanilla" }
        "off" { return "vanilla" }
        "random" { return "random" }
        "zone" { return "zone" }
        "area" { return "zone" }
        "global" { return "global" }
        "decouverte" { if ($AllowDiscovery) { return "decouverte" } else { return "zone" } }
        "discovery" { if ($AllowDiscovery) { return "decouverte" } else { return "zone" } }
        # Variante : meme revelation, mais l'herbe montre un leurre tire au
        # sort tant que la zone n'a pas ete revelee.
        "decouverterandom" { if ($AllowDiscovery) { return "decouverte_random" } else { return "zone" } }
        "decouverte_random" { if ($AllowDiscovery) { return "decouverte_random" } else { return "zone" } }
        "discoveryrandom" { if ($AllowDiscovery) { return "decouverte_random" } else { return "zone" } }
        default { return $Fallback }
    }
}

function Get-LiveVisibleModeValue {
    return Get-NormalizedLiveEncounterMode -Value $LiveVisibleMode -Fallback "vanilla" -AllowDiscovery $true
}

function Get-LiveBattleModeValue {
    return Get-NormalizedLiveEncounterMode -Value $LiveBattleMode -Fallback "vanilla" -AllowDiscovery $false
}

# Le mode decouverte a besoin du combat pour reveler : avec un combat "vanilla"
# rien ne serait jamais revele et la zone ne se completerait jamais.
function Get-EffectiveLiveBattleModeValue {
    $battle = Get-LiveBattleModeValue
    $visible = Get-LiveVisibleModeValue
    if (($visible -eq "decouverte" -or $visible -eq "decouverte_random") -and $battle -eq "vanilla") {
        return "zone"
    }
    return $battle
}

function Get-GenerationFilterSet {
    <#
        Lit un filtre de generation. Une valeur vide veut dire « suivre le
        filtre global », et un filtre global vide veut dire « toutes ».
    #>
    param([string]$Filter = "")

    $texte = if ([string]::IsNullOrWhiteSpace($Filter)) { [string]$LiveGenerationFilter } else { [string]$Filter }
    $requested = New-Object System.Collections.Generic.List[int]
    foreach ($piece in ($texte -split '[,;\s]+')) {
        if ([string]::IsNullOrWhiteSpace($piece)) {
            continue
        }
        $parsed = 0
        if ([int]::TryParse($piece, [ref]$parsed) -and $parsed -ge 1 -and $parsed -le 8) {
            $requested.Add($parsed)
        }
    }
    if ($requested.Count -eq 0) {
        return @(1, 2, 3, 4, 5, 6, 7, 8)
    }
    return @($requested | Sort-Object -Unique)
}

function Get-LiveGenerationFilterSet {
    $requested = New-Object System.Collections.Generic.List[int]
    foreach ($piece in (([string]$LiveGenerationFilter) -split '[,;\s]+')) {
        if ([string]::IsNullOrWhiteSpace($piece)) {
            continue
        }
        $parsed = 0
        if ([int]::TryParse($piece, [ref]$parsed) -and $parsed -ge 1 -and $parsed -le 8) {
            $requested.Add($parsed)
        }
    }
    if ($requested.Count -eq 0) {
        return @(1, 2, 3, 4, 5, 6, 7, 8)
    }
    return @($requested | Sort-Object -Unique)
}

function Select-SpeciesByGeneration {
    param(
        [int[]]$SpeciesIds,
        [string]$Filter = ""
    )

    $generations = @(Get-GenerationFilterSet -Filter $Filter)
    if ($generations.Count -ge 8 -or -not $SpeciesIds) {
        return [int[]]$SpeciesIds
    }

    $kept = New-Object System.Collections.Generic.List[int]
    foreach ($speciesId in $SpeciesIds) {
        foreach ($generation in $generations) {
            $range = $LiveGenerationRanges[$generation]
            if ($speciesId -ge $range[0] -and $speciesId -le $range[1]) {
                $kept.Add([int]$speciesId)
                break
            }
        }
    }

    # Un filtre trop serre viderait le pool, et un pool vide fait retomber le
    # module sur tout le pokedex : ce serait pire que de ne pas filtrer.
    if ($kept.Count -lt 8) {
        return [int[]]$SpeciesIds
    }
    return [int[]]$kept.ToArray()
}

function Get-NormalizedOverworldVisiblePoolMode {
    param([string]$Value)

    switch (([string]$Value).Trim().ToLowerInvariant()) {
        "all" { return "All" }
        "tous" { return "All" }
        "toutes" { return "All" }
        "unusualonly" { return "UnusualOnly" }
        "unusual" { return "UnusualOnly" }
        "nonprevues" { return "UnusualOnly" }
        default { return "Vanilla" }
    }
}

function Get-OverworldVisiblePoolForMode {
    <#
        Le reservoir des especes autorisees a s'afficher dehors, selon le mode
        choisi. Deux endroits en dependent et doivent rester d'accord : la
        couche runtime (visible_pool du config.toml) et les tables ROMFS des
        symboles. Les faire diverger donnerait un jeu qui affiche une chose
        dehors et une autre apres regeneration.
    #>
    param(
        [string]$RomfsRoot,
        [bool]$AllowLegendaries
    )

    $mode = Get-NormalizedOverworldVisiblePoolMode -Value $OverworldVisiblePoolMode
    $symboles = @(Get-OverworldVisualSpeciesPool -RomfsRoot $RomfsRoot -AllowLegendaries $AllowLegendaries)

    if ($mode -eq "Vanilla") {
        $pool = $symboles
    } elseif ($mode -eq "All") {
        $pool = @(Get-BaseSpeciesPool -AllowLegendaries $AllowLegendaries -RomfsRoot $RomfsRoot)
    } else {
        $toutes = @(Get-BaseSpeciesPool -AllowLegendaries $AllowLegendaries -RomfsRoot $RomfsRoot)
        $connues = [System.Collections.Generic.HashSet[int]]::new()
        foreach ($espece in $symboles) { $null = $connues.Add([int]$espece) }
        $restant = @($toutes | Where-Object { -not $connues.Contains([int]$_) })
        # Un reservoir vide ferait retomber le module sur tout le pokedex, ce
        # qui invaliderait silencieusement le mode de test.
        $pool = if ((Get-ObjectArrayCount $restant) -lt 1) { $toutes } else { $restant }
    }

    # Le filtre d'encombrement s'applique APRES le choix du reservoir : les deux
    # axes sont independants, y compris sur le reservoir vanilla (ou il retire
    # Leviator, qui est un symbole du jeu de base et l'un des plus encombrants).
    return [int[]](Select-SpeciesByOverworldHitbox -SpeciesIds ([int[]]$pool) -RomfsRoot $RomfsRoot -MaxHitbox $OverworldVisibleMaxHitbox)
}

function Get-LiveVisibleSpeciesPool {
    <#
        Quelles especes peuvent apparaitre DEHORS.

        Le reservoir par defaut reste celui des symboles de rencontre du jeu de
        base. Mesure du 2026-09-09 sur un dump Epee : 665 especes ont une
        archive de modele et 664 ont une entree complete dans
        symbol_encount_mons_param.bin (partie de modele, rayon de collision,
        rayon de secouage de l'herbe) -- mais seules 330 servent de symboles.
        Le plafond n'est donc pas technique, c'est un choix de contenu.

        UnusualOnly sert a le VERIFIER en jeu : il ne garde QUE les especes que
        le vanilla ne montre jamais. Rien dehors = le jeu les refuse. Quelque
        chose dehors = le plafond peut sauter.
    #>
    $pool = @(Get-OverworldVisiblePoolForMode -RomfsRoot $SourceRomfs -AllowLegendaries ([bool]$AllowLegendaryLiveVisible))
    return [int[]](Select-SpeciesByGeneration -SpeciesIds ([int[]]$pool) -Filter $GenerationFilterVisible)
}

function Get-LiveBattleSpeciesPool {
    <#
        Le Pokemon de COMBAT n'a pas besoin de modele overworld.

        J'ai un temps croise ce reservoir avec les especes que le vanilla fait
        apparaitre dehors, croyant qu'un Pingoleon observe en jeu venait de la.
        C'etait faux deux fois : il venait des tables ROMFS, qui ignoraient le
        filtre de generation ; et le croisement neutralisait l'option « faire
        apparaitre dehors les Pokemon des hautes herbes », dont c'est justement
        le but de sortir de ces especes-la.
    #>
    $pool = @(Get-BaseSpeciesPool -AllowLegendaries ([bool]$AllowLegendaryLiveBattle) -RomfsRoot $SourceRomfs)
    return [int[]](Select-SpeciesByGeneration -SpeciesIds ([int[]]$pool) -Filter $GenerationFilterBattle)
}

function Get-EffectiveGrassEncounterStableMapping {
    param(
        [string]$DrawModeValue = $EncounterDrawMode,
        [string]$LegacyVisibleBehavior = $VisibleEncounterBehavior,
        [string]$FallbackStableMapping = $GrassEncounterStableMapping
    )

    # Get-NormalizedEncounterDrawMode ne rend QUE trois valeurs : sa propre
    # branche par defaut retourne "SlotParEspece". Un switch qui traite ces
    # trois cas puis lit le choix de l'utilisateur dans son "default" ne le lit
    # donc jamais - c'est le defaut qui rendait cette liste inerte. On teste
    # maintenant les deux modes aleatoires en premier, et le choix de
    # l'utilisateur tranche dans le seul cas ou il a un sens.
    $drawMode = Get-NormalizedEncounterDrawMode -Value $DrawModeValue -LegacyVisibleBehavior $LegacyVisibleBehavior
    if ($drawMode -eq "FullRandom" -or $drawMode -eq "VisibleFixeTirageRandom") {
        # Ces deux modes refont un tirage a chaque entree : aucune stabilite a
        # respecter, quoi que dise la liste.
        return "Random"
    }

    switch (Normalize-StableMappingMode -Value $FallbackStableMapping) {
        "slot"   { return "Slot" }
        "random" { return "Random" }
        default  { return "Species" }
    }
}

function Get-LiveEncounterRandomizerEnabled {
    # Desormais pilote par les deux reglages independants, pas par l'ancien
    # mode melange : sans ca, choisir Vanilla/Vanilla laisserait quand meme la
    # couche runtime active.
    return (((Get-LiveVisibleModeValue) -ne "vanilla") -or ((Get-EffectiveLiveBattleModeValue) -ne "vanilla"))
}

# Fonctionnalites de confort fournies par le module ExLaunch. Elles sont
# appliquees a l'execution : aucun fichier ROMFS n'est reecrit pour elles.
function Get-AnyComfortModEnabled {
    return ([bool]$ModOverworldShiny -or
            [bool]$ModUnderworld -or
            [bool]$ModCameraTweaks -or
            [bool]$ModUncapLevel -or
            [bool]$ModFreecam -or
            [bool]$ModGlimwoodOverworld -or
            [bool]$ModSynchroMode -or
            [bool]$ModExtendedFollowing -or
            [bool]$ModFishingTweaks -or
            [bool]$ModDexAnimations)
}

function Get-AnyExLaunchRuntimeFeatureEnabled {
    return ((Get-RandomizerPcMenuEnabled) -or (Get-AnyExpLevelCapEnabled) -or (Get-RuntimeExpMultiplierEnabled) -or [bool]$DisableExpShare -or [bool]$EarlyBike -or (Get-LiveEncounterRandomizerEnabled) -or (Get-AnyComfortModEnabled))
}

function Get-BossLevelCapEnforcementMode {
    if ([bool]$MainStorySoftLevelCap) {
        return "mainStoryProgressionSoftByBadgeCount"
    }
    if ([bool]$GymLeagueStoryLevelCap) {
        return "nextGymLeaderOrChampionByBadgeCount"
    }
    if ([bool]$StoryMajorBattleOrderLevelCap) {
        return "orderedBaseStoryMajorBattlesStrictViaDynamicExpAndTeamNormalization"
    }
    if ([bool]$StrictBossMaxLevelCap) {
        return "bossTeamMaxLevelStrictViaBossLevelNormalization"
    }
    if (Get-EffectiveDynamicExpLevelCapEnabled) {
        return "receiverLevelVsDefeatedPokemonLevel"
    }
    return "referenceOnly"
}

function Get-NormalizedGameVersionSelection {
    param([string]$Value)

    $normalized = ([string]$Value).Trim().ToLowerInvariant()
    switch ($normalized) {
        "shield" { return "Shield" }
        "bouclier" { return "Shield" }
        "sword" { return "Sword" }
        "epee" { return "Sword" }
        "Ã©pÃ©e" { return "Sword" }
        default { return "Auto" }
    }
}

function Get-DefaultGameRoot {
    $portableDumpRoot = Join-Path $PSScriptRoot "dump"
    if (Test-Path -LiteralPath $portableDumpRoot) {
        return $portableDumpRoot
    }

    return ""
}

function Get-DefaultSourceRomfsPath {
    param([string]$GameVersion)

    $version = Get-NormalizedGameVersionSelection -Value $GameVersion
    $folder = if ($version -eq "Sword") { "Epee" } else { "Bouclier" }
    $gameRoot = Get-DefaultGameRoot
    if ([string]::IsNullOrWhiteSpace($gameRoot)) {
        return ""
    }

    return (Join-Path $gameRoot (Join-Path $folder "romfs"))
}

function Get-DefaultSourceExefsPath {
    param([string]$GameVersion)

    $version = Get-NormalizedGameVersionSelection -Value $GameVersion
    $folder = if ($version -eq "Sword") { "Epee" } else { "Bouclier" }
    $gameRoot = Get-DefaultGameRoot
    if ([string]::IsNullOrWhiteSpace($gameRoot)) {
        return ""
    }

    return (Join-Path $gameRoot (Join-Path $folder "exefs"))
}

function Get-DefaultOutputRomfsPath {
    param([string]$GameVersion)

    $version = Get-NormalizedGameVersionSelection -Value $GameVersion
    $folder = if ($version -eq "Sword") { "Epee" } elseif ($version -eq "Shield") { "Bouclier" } else { "Auto" }
    return (Join-Path $PSScriptRoot (Join-Path "output" $folder))
}

function Get-ExistingDefaultPathOrEmpty {
    param([string]$Path)

    if (-not [string]::IsNullOrWhiteSpace($Path) -and (Test-Path -LiteralPath $Path)) {
        return $Path
    }
    return ""
}

function Test-PathInsideRoot {
    param(
        [string]$Path,
        [string]$Root
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or [string]::IsNullOrWhiteSpace($Root)) {
        return $false
    }

    $trimChars = [char[]]@('\', '/')
    $fullPath = [IO.Path]::GetFullPath($Path).TrimEnd($trimChars)
    $fullRoot = [IO.Path]::GetFullPath($Root).TrimEnd($trimChars)
    return ($fullPath -ieq $fullRoot) -or $fullPath.StartsWith($fullRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or $fullPath.StartsWith($fullRoot + [IO.Path]::AltDirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
}

function Assert-PathIsUserDumpSource {
    param(
        [string]$Path,
        [string]$Kind
    )

    $blockedRoots = @(
        (Join-Path $PSScriptRoot "output"),
        (Join-Path $PSScriptRoot "Installation"),
        (Join-Path $PSScriptRoot "research\swsh-mods-exl\artifact"),
        (Join-Path $PSScriptRoot "research\swsh-mods-exl\deploy"),
        (Join-Path $PSScriptRoot "research\downloads")
    )

    foreach ($blockedRoot in $blockedRoots) {
        if ((Test-Path -LiteralPath $blockedRoot) -and (Test-PathInsideRoot -Path $Path -Root $blockedRoot)) {
            throw "$Kind invalide: '$Path' pointe vers une sortie générée ou un dossier interne du randomizer. Sélectionne le $Kind original extrait de ton propre dump du jeu."
        }
    }
}

$LegendarySpeciesIds = [System.Collections.Generic.HashSet[int]]::new()
@(
    144,145,146,150,151,243,244,245,249,250,251,377,378,379,380,381,382,383,384,385,386,
    480,481,482,483,484,485,486,487,488,489,490,491,492,493,494,638,639,640,641,642,643,644,
    645,646,647,648,649,716,717,718,719,720,721,772,773,785,786,787,788,789,790,791,792,793,
    794,795,796,797,798,799,800,801,802,803,804,805,806,807,808,809,888,889,890,891,892,893,
    894,895,896,897,898
) | ForEach-Object { $null = $LegendarySpeciesIds.Add($_) }

function Read-U16 {
    param([byte[]]$Data, [int]$Offset)
    return [BitConverter]::ToUInt16($Data, $Offset)
}

function Write-U16 {
    param([byte[]]$Data, [int]$Offset, [int]$Value)
    $bytes = [BitConverter]::GetBytes([uint16]$Value)
    [Array]::Copy($bytes, 0, $Data, $Offset, 2)
}

function Read-U32 {
    param([byte[]]$Data, [int]$Offset)
    return [BitConverter]::ToUInt32($Data, $Offset)
}

function Read-U64 {
    param([byte[]]$Data, [int]$Offset)
    return [BitConverter]::ToUInt64($Data, $Offset)
}

function Read-I32 {
    param([byte[]]$Data, [int]$Offset)
    return [BitConverter]::ToInt32($Data, $Offset)
}

function Write-U32 {
    param([byte[]]$Data, [int]$Offset, [uint32]$Value)
    $bytes = [BitConverter]::GetBytes($Value)
    [Array]::Copy($bytes, 0, $Data, $Offset, 4)
}

function Write-U64 {
    param([byte[]]$Data, [int]$Offset, [uint64]$Value)
    $bytes = [BitConverter]::GetBytes($Value)
    [Array]::Copy($bytes, 0, $Data, $Offset, 8)
}

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Ensure-ParentDirectory {
    param([string]$Path)
    $parent = Split-Path -Parent $Path
    if ($parent) {
        Ensure-Directory -Path $parent
    }
}

function Write-Utf8NoBomText {
    param(
        [string]$Path,
        [string]$Text
    )

    Ensure-ParentDirectory -Path $Path
    [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}

function Write-JsonFile {
    param(
        [object]$Value,
        [string]$Path,
        [int]$Depth = 20
    )

    Write-Utf8NoBomText -Path $Path -Text ($Value | ConvertTo-Json -Depth $Depth)
}

function Copy-DirectoryChildren {
    param(
        [string]$SourcePath,
        [string]$DestinationPath
    )

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        return
    }

    Ensure-Directory -Path $DestinationPath
    foreach ($child in Get-ChildItem -LiteralPath $SourcePath -Force) {
        $destinationChildPath = Join-Path $DestinationPath $child.Name
        Copy-Item -LiteralPath $child.FullName -Destination $destinationChildPath -Recurse -Force
    }
}

function Copy-DirectoryTreeMerge {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [System.Collections.Generic.List[string]]$ReplacedPaths = $null
    )

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        return
    }

    Ensure-Directory -Path $DestinationPath
    foreach ($child in Get-ChildItem -LiteralPath $SourcePath -Force) {
        $destinationChildPath = Join-Path $DestinationPath $child.Name
        if ($child.PSIsContainer) {
            if ((Test-Path -LiteralPath $destinationChildPath) -and (-not (Get-Item -LiteralPath $destinationChildPath).PSIsContainer)) {
                Remove-Item -LiteralPath $destinationChildPath -Force
                if ($ReplacedPaths) {
                    $ReplacedPaths.Add($destinationChildPath)
                }
            }
            Copy-DirectoryTreeMerge -SourcePath $child.FullName -DestinationPath $destinationChildPath -ReplacedPaths $ReplacedPaths
        } else {
            if (Test-Path -LiteralPath $destinationChildPath) {
                if ($ReplacedPaths) {
                    $ReplacedPaths.Add($destinationChildPath)
                }
            }
            Ensure-ParentDirectory -Path $destinationChildPath
            Copy-Item -LiteralPath $child.FullName -Destination $destinationChildPath -Force
        }
    }
}

function Remove-PathIfExists {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
        return $true
    }

    return $false
}

function Remove-EmptyDirectoryChain {
    param(
        [string]$StartPath,
        [string]$StopAtPath = ""
    )

    $current = $StartPath
    $stopNormalized = if ([string]::IsNullOrWhiteSpace($StopAtPath)) { "" } else { [IO.Path]::GetFullPath($StopAtPath).TrimEnd('\') }
    while (-not [string]::IsNullOrWhiteSpace($current) -and (Test-Path -LiteralPath $current)) {
        $currentNormalized = [IO.Path]::GetFullPath($current).TrimEnd('\')
        if (-not [string]::IsNullOrWhiteSpace($stopNormalized) -and ($currentNormalized -ieq $stopNormalized)) {
            break
        }

        $children = @(Get-ChildItem -LiteralPath $current -Force -ErrorAction SilentlyContinue)
        if ($children.Count -gt 0) {
            break
        }

        $parent = Split-Path -Parent $current
        Remove-Item -LiteralPath $current -Force
        $current = $parent
    }
}

function Test-RandomizerManagedSwshModsExlConfig {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or (-not (Test-Path -LiteralPath $Path))) {
        return $false
    }

    try {
        $head = Get-Content -LiteralPath $Path -TotalCount 6 -ErrorAction Stop
        return ((($head -join "`n")) -match "Generated by PokeFeurRandomSWSH")
    } catch {
        return $false
    }
}

function Get-OutputPackageRoot {
    param([string]$OutputRomfsRoot)

    if ([string]::IsNullOrWhiteSpace($OutputRomfsRoot)) {
        return ""
    }

    $fullPath = [IO.Path]::GetFullPath($OutputRomfsRoot)
    $leaf = Split-Path -Leaf $fullPath
    if ($leaf -ieq "romfs") {
        return (Split-Path -Parent $fullPath)
    }
    return $fullPath
}

function Get-OutputReportsRoot {
    param([string]$OutputRomfsRoot)

    $packageRoot = Get-OutputPackageRoot -OutputRomfsRoot $OutputRomfsRoot
    if ([string]::IsNullOrWhiteSpace($packageRoot)) {
        return ""
    }

    return (Join-Path $packageRoot "reports")
}

function Get-OutputReportPath {
    param(
        [string]$OutputRomfsRoot,
        [string]$FileName
    )

    return (Join-Path (Get-OutputReportsRoot -OutputRomfsRoot $OutputRomfsRoot) $FileName)
}

function Move-RootRomfsReportsToReports {
    param([string]$OutputRomfsRoot)

    if ([string]::IsNullOrWhiteSpace($OutputRomfsRoot) -or -not (Test-Path -LiteralPath $OutputRomfsRoot)) {
        return 0
    }

    $reportNames = @(
        "encounter-zones.json",
        "item-changes.json",
        "level-caps.json",
        "race-summary.json",
        "randomizer-report.json",
        "seed-summary.json",
        "spoiler-log.json",
        "story-gym-league-caps.json",
        "story-main-progression-soft-caps.json",
        "story-major-battle-caps.json",
        "trainer-changes.json",
        "wild-changes.json"
    )

    $reportsRoot = Get-OutputReportsRoot -OutputRomfsRoot $OutputRomfsRoot
    $moved = 0
    foreach ($name in $reportNames) {
        $sourcePath = Join-Path $OutputRomfsRoot $name
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            continue
        }

        Ensure-Directory -Path $reportsRoot
        $targetPath = Join-Path $reportsRoot $name
        if (Test-Path -LiteralPath $targetPath) {
            Remove-Item -LiteralPath $targetPath -Force
        }
        Move-Item -LiteralPath $sourcePath -Destination $targetPath
        $moved++
    }

    return $moved
}

function Resolve-OutputRomfsRoot {
    param([string]$OutputPath)

    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        throw "Dossier de sortie obligatoire: sélectionne le dossier du mod généré."
    }

    $fullPath = [IO.Path]::GetFullPath($OutputPath)
    if ((Split-Path -Leaf $fullPath) -ieq "romfs") {
        return $fullPath
    }

    return (Join-Path $fullPath "romfs")
}

function Resolve-SourceExefsRoot {
    param(
        [string]$SourceRomfsRoot,
        [string]$SourceExefsRoot = "",
        [string]$GameVersion = "Sword"
    )

    $candidates = New-Object System.Collections.Generic.List[string]

    if (-not [string]::IsNullOrWhiteSpace($SourceExefsRoot)) {
        $selectedExefs = [IO.Path]::GetFullPath($SourceExefsRoot)
        if ((Split-Path -Leaf $selectedExefs) -ieq "exefs") {
            $candidates.Add($selectedExefs)
        } else {
            $candidates.Add((Join-Path $selectedExefs "exefs"))
            $candidates.Add($selectedExefs)
        }

        foreach ($candidate in @($candidates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)) {
            if (Test-Path -LiteralPath (Join-Path $candidate "main.npdm")) {
                try {
                    return [IO.Path]::GetFullPath($candidate)
                } catch {
                    return $candidate
                }
            }
        }

        throw "Dossier ExeFS invalide: '$SourceExefsRoot'. Sélectionne le dossier exefs de ton dump, celui qui contient main.npdm."
    }

    if (-not [string]::IsNullOrWhiteSpace($SourceRomfsRoot)) {
        $resolvedRomfs = try { [IO.Path]::GetFullPath($SourceRomfsRoot) } catch { $SourceRomfsRoot }
        $romfsLeaf = Split-Path -Leaf $resolvedRomfs
        $romfsParent = Split-Path -Parent $resolvedRomfs
        if ($romfsLeaf -ieq "romfs" -and $romfsParent) {
            $candidates.Add((Join-Path $romfsParent "exefs"))
        }
        if ($romfsParent) {
            $gameRoot = Split-Path -Parent $romfsParent
            if ($gameRoot) {
                $candidates.Add((Join-Path $gameRoot "exefs"))
            }
        }
    }

    foreach ($candidate in @($candidates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)) {
        if (Test-Path -LiteralPath (Join-Path $candidate "main.npdm")) {
            try {
                return [IO.Path]::GetFullPath($candidate)
            } catch {
                return $candidate
            }
        }
    }

    return ""
}

function Resolve-RequiredSourceRomfsRoot {
    param([string]$SourceRomfsRoot)

    if ([string]::IsNullOrWhiteSpace($SourceRomfsRoot)) {
        throw "Dossier ROMFS obligatoire: sélectionne le dossier romfs de ton dump utilisateur."
    }

    $resolvedRomfs = [IO.Path]::GetFullPath($SourceRomfsRoot)
    if (-not (Test-Path -LiteralPath $resolvedRomfs)) {
        throw "Dossier ROMFS introuvable: '$SourceRomfsRoot'. Sélectionne le dossier romfs de ton dump utilisateur."
    }

    if ((Split-Path -Leaf $resolvedRomfs) -ine "romfs") {
        $romfsChild = Join-Path $resolvedRomfs "romfs"
        if (Test-Path -LiteralPath $romfsChild) {
            $resolvedRomfs = [IO.Path]::GetFullPath($romfsChild)
        }
    }

    if ((Split-Path -Leaf $resolvedRomfs) -ine "romfs") {
        throw "Dossier ROMFS invalide: '$SourceRomfsRoot'. Sélectionne le dossier romfs de ton dump utilisateur."
    }

    Assert-PathIsUserDumpSource -Path $resolvedRomfs -Kind "ROMFS"
    return $resolvedRomfs
}

function Resolve-RequiredSourceExefsRoot {
    param(
        [string]$SourceRomfsRoot,
        [string]$SourceExefsRoot,
        [string]$GameVersion
    )

    if ([string]::IsNullOrWhiteSpace($SourceExefsRoot)) {
        throw "Dossier ExeFS obligatoire: sélectionne le dossier exefs de ton dump utilisateur, celui qui contient main.npdm."
    }

    $resolvedExefs = Resolve-SourceExefsRoot -SourceRomfsRoot $SourceRomfsRoot -SourceExefsRoot $SourceExefsRoot -GameVersion $GameVersion
    if ([string]::IsNullOrWhiteSpace($resolvedExefs) -or (-not (Test-Path -LiteralPath (Join-Path $resolvedExefs "main.npdm")))) {
        throw "Dossier ExeFS invalide: '$SourceExefsRoot'. Sélectionne le dossier exefs de ton dump utilisateur, celui qui contient main.npdm."
    }

    Assert-PathIsUserDumpSource -Path $resolvedExefs -Kind "ExeFS"
    return $resolvedExefs
}

function Get-EmulatorSdmcRootForOutput {
    param([string]$OutputRomfsRoot)

    $fullPath = [IO.Path]::GetFullPath($OutputRomfsRoot)
    $parts = @($fullPath -split '[\\/]' | Where-Object { $_ -ne "" })
    for ($i = $parts.Count - 1; $i -ge 0; $i--) {
        if ($parts[$i] -ieq "load" -and $i -gt 0) {
            $rootParts = $parts[0..($i - 1)]
            if ($fullPath -match '^[A-Za-z]:[\\/]') {
                return (($rootParts -join "\") + "\sdmc")
            }
            return ([IO.Path]::DirectorySeparatorChar + (($rootParts -join [IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar + "sdmc"))
        }
    }

    return ""
}

function Get-NormalizedModName {
    param([string]$ModName)

    $trimmed = ([string]$ModName).Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        return "Randomizer"
    }

    return $trimmed
}

function Get-RyujinxRootPath {
    return (Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)) "Ryujinx")
}

function Get-EmulatorInstallTargets {
    param(
        [string]$GameVersion,
        [string]$ModName
    )

    $normalizedGameVersion = Get-NormalizedGameVersionSelection -Value $GameVersion
    if ($normalizedGameVersion -eq "Auto") {
        $normalizedGameVersion = "Sword"
    }
    $safeModName = Get-NormalizedModName -ModName $ModName
    $titleId = Get-GameTitleId -GameVersion $normalizedGameVersion

    return @(
        [pscustomobject]@{
            Key = "ryujinx"
            Name = "Ryujinx"
            RootPath = Get-RyujinxRootPath
            RelativeModPath = ("mods\contents\" + $titleId + "\" + $safeModName)
            RelativeSdmcPath = "sdcard"
            LegacyRelativeModPaths = @(
                ("sdcard\atmosphere\contents\" + $titleId + "\" + $safeModName),
                ("mods\exefs_patches\" + $titleId),
                ("sdcard\atmosphere\exefs_patches\" + $titleId)
            )
            TitleId = $titleId
            ModName = $safeModName
        }
    ) | ForEach-Object {
        $rootPath = [string]$_.RootPath
        $relativeModPath = [string]$_.RelativeModPath
        $relativeSdmcPath = [string]$_.RelativeSdmcPath
        $legacyRelativeModPaths = @($_.PSObject.Properties["LegacyRelativeModPaths"].Value)
        $modRoot = if ([string]::IsNullOrWhiteSpace($rootPath)) { "" } else { Join-Path $rootPath $relativeModPath }
        $sdmcRoot = if ([string]::IsNullOrWhiteSpace($rootPath)) { "" } else { Join-Path $rootPath $relativeSdmcPath }
        [pscustomobject]@{
            Key = [string]$_.Key
            Name = [string]$_.Name
            RootPath = $rootPath
            IsDetected = (-not [string]::IsNullOrWhiteSpace($rootPath)) -and (Test-Path -LiteralPath $rootPath)
            RelativeModPath = $relativeModPath
            RelativeSdmcPath = $relativeSdmcPath
            ModRoot = $modRoot
            SdmcRoot = $sdmcRoot
            LegacyModRoots = @(
                @([object[]]$legacyRelativeModPaths | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | ForEach-Object {
                    if ([string]::IsNullOrWhiteSpace($rootPath)) {
                        ""
                    } else {
                        Join-Path $rootPath ([string]$_)
                    }
                }) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) -and ([string]$_ -ne $modRoot) }
            )
            SdmcConfigRoot = if ([string]::IsNullOrWhiteSpace($sdmcRoot)) { "" } else { Join-Path $sdmcRoot "config\swsh-mods-exl" }
            SdmcConfigPath = if ([string]::IsNullOrWhiteSpace($sdmcRoot)) { "" } else { Join-Path $sdmcRoot "config\swsh-mods-exl\config.toml" }
            TitleId = [string]$_.TitleId
            ModName = [string]$_.ModName
        }
    }
}

function Get-RequestedEmulatorKeys {
    $keys = New-Object System.Collections.Generic.List[string]
    if ([bool]$InstallToRyujinx) { $keys.Add("ryujinx") }
    return [string[]]$keys.ToArray()
}

function Install-PackageToEmulatorTarget {
    param(
        [string]$OutputRomfsRoot,
        [string]$GameVersion,
        [pscustomobject]$Target
    )

    $packageRoot = Get-OutputPackageRoot -OutputRomfsRoot $OutputRomfsRoot
    $sourceRomfsPath = Join-Path $packageRoot "romfs"
    $sourceExefsPath = Join-Path $packageRoot "exefs"
    $sourceSdmcPath = Join-Path $packageRoot "sdmc"
    $sourceReportsPath = Join-Path $packageRoot "reports"
    $sourcePackageFullPath = [IO.Path]::GetFullPath($packageRoot)
    $targetModFullPath = if ([string]::IsNullOrWhiteSpace([string]$Target.ModRoot)) { "" } else { [IO.Path]::GetFullPath([string]$Target.ModRoot) }
    $alreadyAtTarget = (-not [string]::IsNullOrWhiteSpace($targetModFullPath)) -and
        ($sourcePackageFullPath.TrimEnd('\') -ieq $targetModFullPath.TrimEnd('\'))
    $removedExistingSdmcPaths = New-Object System.Collections.Generic.List[string]
    $removedExistingLegacyModPaths = New-Object System.Collections.Generic.List[string]

    $result = [pscustomobject]@{
        Emulator = [string]$Target.Name
        Key = [string]$Target.Key
        Requested = $true
        Detected = [bool]$Target.IsDetected
        Installed = $false
        GameVersion = ""
        TitleId = [string]$Target.TitleId
        RootPath = [string]$Target.RootPath
        PackageRoot = $packageRoot
        ModName = [string]$Target.ModName
        ModRoot = [string]$Target.ModRoot
        SdmcRoot = [string]$Target.SdmcRoot
        SdmcConfigPath = [string]$Target.SdmcConfigPath
        AlreadyAtTarget = $alreadyAtTarget
        RemovedExistingMod = $false
        RemovedExistingLegacyModPaths = @()
        RemovedExistingSdmcPaths = @()
        CopiedRomfs = $false
        CopiedExefs = $false
        CopiedSdmc = $false
        CopiedReports = $false
        Error = ""
    }

    if (-not [bool]$Target.IsDetected) {
        $result.Error = ("{0} introuvable sur ce PC." -f [string]$Target.Name)
        return $result
    }

    if (-not (Test-Path -LiteralPath $sourceRomfsPath)) {
        $result.Error = "Le package généré ne contient pas de dossier romfs."
        return $result
    }

    try {
        foreach ($legacyModRoot in @($Target.LegacyModRoots)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$legacyModRoot) -and (Test-Path -LiteralPath $legacyModRoot)) {
                Remove-Item -LiteralPath $legacyModRoot -Recurse -Force
                $removedExistingLegacyModPaths.Add([string]$legacyModRoot)
            }
        }

        if (-not $alreadyAtTarget) {
            if (Test-Path -LiteralPath $Target.ModRoot) {
                Remove-Item -LiteralPath $Target.ModRoot -Recurse -Force
                $result.RemovedExistingMod = $true
            }

            Ensure-Directory -Path (Split-Path -Parent $Target.ModRoot)
            Ensure-Directory -Path $Target.ModRoot
            Copy-DirectoryChildren -SourcePath $sourceRomfsPath -DestinationPath (Join-Path $Target.ModRoot "romfs")
            $result.CopiedRomfs = $true

            if (Test-Path -LiteralPath $sourceReportsPath) {
                Copy-DirectoryChildren -SourcePath $sourceReportsPath -DestinationPath (Join-Path $Target.ModRoot "reports")
                $result.CopiedReports = $true
            }

            if (Test-Path -LiteralPath $sourceExefsPath) {
                Copy-DirectoryChildren -SourcePath $sourceExefsPath -DestinationPath (Join-Path $Target.ModRoot "exefs")
                $null = Sync-RyujinxSpecificSubsdk9 -DestinationExefsRoot (Join-Path $Target.ModRoot "exefs") -GameVersion $GameVersion -TargetKey ([string]$Target.Key)
                $result.CopiedExefs = $true
            }
        } else {
            $result.CopiedRomfs = $true
            $result.CopiedExefs = (Test-Path -LiteralPath $sourceExefsPath)
            $result.CopiedReports = (Test-Path -LiteralPath $sourceReportsPath)
            if ($result.CopiedExefs) {
                $null = Sync-RyujinxSpecificSubsdk9 -DestinationExefsRoot (Join-Path $Target.ModRoot "exefs") -GameVersion $GameVersion -TargetKey ([string]$Target.Key)
            }
        }

        if (Test-Path -LiteralPath $sourceSdmcPath) {
            Ensure-Directory -Path $Target.SdmcRoot
            if (Test-Path -LiteralPath $Target.SdmcConfigRoot) {
                Remove-Item -LiteralPath $Target.SdmcConfigRoot -Recurse -Force
                $removedExistingSdmcPaths.Add($Target.SdmcConfigRoot)
            }
            Copy-DirectoryTreeMerge -SourcePath $sourceSdmcPath -DestinationPath $Target.SdmcRoot -ReplacedPaths $removedExistingSdmcPaths
            $result.CopiedSdmc = $true
        }

        $result.RemovedExistingLegacyModPaths = @($removedExistingLegacyModPaths.ToArray())
        $result.RemovedExistingSdmcPaths = @($removedExistingSdmcPaths.ToArray())
        $null = Sync-RyujinxModsJson -Target $Target
        $result.Installed = $true
        return $result
    } catch {
        $result.RemovedExistingLegacyModPaths = @($removedExistingLegacyModPaths.ToArray())
        $result.RemovedExistingSdmcPaths = @($removedExistingSdmcPaths.ToArray())
        $result.Error = $_.Exception.Message
        return $result
    }
}

function Install-PackageToSelectedEmulators {
    param(
        [string]$OutputRomfsRoot,
        [string]$GameVersion,
        [string]$ModName
    )

    $requestedKeys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($key in (Get-RequestedEmulatorKeys)) {
        $null = $requestedKeys.Add($key)
    }

    $results = New-Object System.Collections.Generic.List[object]
    foreach ($target in Get-EmulatorInstallTargets -GameVersion $GameVersion -ModName $ModName) {
        if (-not $requestedKeys.Contains([string]$target.Key)) {
            continue
        }

        $results.Add((Install-PackageToEmulatorTarget -OutputRomfsRoot $OutputRomfsRoot -GameVersion $GameVersion -Target $target))
    }

    return [object[]]$results.ToArray()
}

function Get-InstallationFolderRoot {
    param([string]$OutputRomfsRoot)
    return (Join-Path $PSScriptRoot "Installation")
}

function Get-InstallationGuideText {
    param(
        [string]$Language,
        [string]$GameVersion,
        [string]$ModName,
        [string]$OutputRomfsRoot
    )

    $lang = if (([string]$Language).ToLowerInvariant() -eq "en") { "en" } else { "fr" }
    $safeModName = Get-NormalizedModName -ModName $ModName
    $titleId = Get-GameTitleId -GameVersion $GameVersion
    $installRoot = Get-InstallationFolderRoot -OutputRomfsRoot $OutputRomfsRoot
    $targets = @(Get-EmulatorInstallTargets -GameVersion $GameVersion -ModName $safeModName)
    $detectedLines = foreach ($target in $targets) {
        $status = if ($target.IsDetected) {
            if ($lang -eq "en") { "detected" } else { "détecté" }
        } else {
            if ($lang -eq "en") { "not found" } else { "introuvable" }
        }
        ("- {0}: {1} ({2})" -f $target.Name, $target.RootPath, $status)
    }
    $manualPathLines = foreach ($target in $targets) {
        $rootPath = if ([string]::IsNullOrWhiteSpace([string]$target.RootPath)) {
            if ($target.Key -eq "ryujinx") {
                "%AppData%\Ryujinx"
            } else {
                ("%AppData%\" + [string]$target.Key)
            }
        } else {
            [string]$target.RootPath
        }
        if ($lang -eq "en") {
            ("- {0}: {1} and {2}" -f $target.Name, (Join-Path $rootPath $target.RelativeModPath), (Join-Path $rootPath ($target.RelativeSdmcPath + "\config\swsh-mods-exl\config.toml")))
        } else {
            ("- {0} : {1} et {2}" -f $target.Name, (Join-Path $rootPath $target.RelativeModPath), (Join-Path $rootPath ($target.RelativeSdmcPath + "\config\swsh-mods-exl\config.toml")))
        }
    }

    if ($lang -eq "en") {
        return @"
Auto-install targets are detected from this PC:
$(($detectedLines -join "`r`n"))

Generated installation package:
$installRoot

What the randomizer writes:
- romfs + exefs go inside the emulator mod folder for title id $titleId
- ExLaunch config goes under sdmc/sdcard config\\swsh-mods-exl\\config.toml
- ExLaunch runtime features target Pokemon Sword/Shield update 1.3.2. Install the 1.3.2 game update in your emulator before launching the mod.
- If an emulator starts crashing after changing ExLaunch builds or runtime options, try clearing that emulator's shader cache manually. The randomizer never deletes shader caches automatically.

Manual paths:
$(($manualPathLines -join "`r`n"))

The Installation folder contains ready-to-copy layouts for every supported emulator target.
The Reset tab removes only this mod folder plus the swsh-mods-exl config file when that config was generated by this randomizer.
"@
    }

    return @"
Cibles d'installation auto detectees sur ce PC :
$(($detectedLines -join "`r`n"))

Dossier d'installation genere :
$installRoot

Ce que le randomizer ecrit :
- romfs + exefs vont dans le dossier de mod de l'emulateur pour le title id $titleId
- la config ExLaunch va dans sdmc/sdcard config\\swsh-mods-exl\\config.toml
- les fonctions runtime ExLaunch ciblent Pokemon Epee/Bouclier en version 1.3.2. Installe la mise a jour 1.3.2 dans l'emulateur avant de lancer le mod.
- Si un emulateur commence a crash apres un changement de build ExLaunch ou d'options runtime, essaie de vider manuellement son cache shaders. Le randomizer ne supprime jamais les caches shaders automatiquement.

Chemins manuels :
$(($manualPathLines -join "`r`n"))

Le dossier Installation contient des arborescences deja pretes a copier pour tous les emulateurs supportes.
L'onglet Reset retire seulement ce dossier de mod et le fichier config swsh-mods-exl quand cette config a ete generee par ce randomizer.
"@
}

function Remove-DirectoryWithRetry {
    <#
        Supprime un dossier en reessayant : un verrou sur ces arborescences est
        presque toujours passager (antivirus qui indexe les 6210 fichiers qu'on
        vient d'ecrire, explorateur ouvert dessus).

        Rend $true si le dossier n'existe plus, $false sinon. L'appelant decide
        quoi faire de l'echec ; ici, il ne doit PAS faire echouer la generation,
        parce que la ROM est deja complete quand on en arrive la.

        Mesure du 2026-09-07 : trois generations sur trente-six d'une suite de
        tests sont sorties en code 1 sur ce seul Remove-Item, alors que leur
        ROM etait juste. Le test lisait donc un echec la ou il n'y en avait pas.
    #>
    param(
        [string]$Path,
        [int]$Tentatives = 5,
        [int]$AttenteMs = 400
    )

    for ($essai = 1; $essai -le $Tentatives; $essai++) {
        if (-not (Test-Path -LiteralPath $Path)) {
            return $true
        }
        try {
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
            return $true
        } catch {
            if ($essai -eq $Tentatives) {
                return $false
            }
            Start-Sleep -Milliseconds $AttenteMs
        }
    }
    return (-not (Test-Path -LiteralPath $Path))
}

function Write-InstallationPackage {
    param(
        [string]$OutputRomfsRoot,
        [string]$GameVersion,
        [string]$ModName
    )

    $packageRoot = Get-OutputPackageRoot -OutputRomfsRoot $OutputRomfsRoot
    $sourceRomfsPath = Join-Path $packageRoot "romfs"
    $sourceExefsPath = Join-Path $packageRoot "exefs"
    $sourceSdmcPath = Join-Path $packageRoot "sdmc"
    $sourceReportsPath = Join-Path $packageRoot "reports"
    $installRoot = Get-InstallationFolderRoot -OutputRomfsRoot $OutputRomfsRoot
    $legacyInstallRoot = Join-Path $packageRoot "Installation"
    if (($legacyInstallRoot -ne $installRoot) -and (Test-Path -LiteralPath $legacyInstallRoot)) {
        $null = Remove-DirectoryWithRetry -Path $legacyInstallRoot
    }
    $dossierNeuf = Remove-DirectoryWithRetry -Path $installRoot
    if (-not $dossierNeuf) {
        # On NE fait PAS echouer la generation : la ROM (romfs, exefs, sdmc) est
        # deja ecrite et juste. Mais on ne se tait pas non plus, parce que le
        # dossier va garder des fichiers d'une generation precedente - c'est
        # exactement ce piege qui a fait jouer une vieille ROM en croyant en
        # lancer une neuve.
        Write-Warning ("Le dossier Installation n'a pas pu être vidé ({0}) : il peut contenir des fichiers d'une génération précédente. La ROM elle-même est complète dans le dossier de sortie." -f $installRoot)
    }
    Ensure-Directory -Path $installRoot

    $targets = @(Get-EmulatorInstallTargets -GameVersion $GameVersion -ModName $ModName)
    foreach ($target in $targets) {
        $targetRoot = Join-Path $installRoot ([string]$target.Name)
        $targetModRoot = Join-Path $targetRoot ([string]$target.RelativeModPath)
        $targetSdmcRoot = Join-Path $targetRoot ([string]$target.RelativeSdmcPath)
        Ensure-Directory -Path $targetModRoot
        Copy-DirectoryChildren -SourcePath $sourceRomfsPath -DestinationPath (Join-Path $targetModRoot "romfs")
        if (Test-Path -LiteralPath $sourceReportsPath) {
            Copy-DirectoryChildren -SourcePath $sourceReportsPath -DestinationPath (Join-Path $targetModRoot "reports")
        }
        if (Test-Path -LiteralPath $sourceExefsPath) {
            Copy-DirectoryChildren -SourcePath $sourceExefsPath -DestinationPath (Join-Path $targetModRoot "exefs")
            $null = Sync-RyujinxSpecificSubsdk9 -DestinationExefsRoot (Join-Path $targetModRoot "exefs") -GameVersion $GameVersion -TargetKey ([string]$target.Key)
        }
        if (Test-Path -LiteralPath $sourceSdmcPath) {
            Copy-DirectoryTreeMerge -SourcePath $sourceSdmcPath -DestinationPath $targetSdmcRoot
        }
    }

    $readmePath = Join-Path $installRoot "README.txt"
    $bilingualReadme = @(
        "PokeFeurRandomSWSH Installation Guide",
        "",
        "===== FR =====",
        (Get-InstallationGuideText -Language "fr" -GameVersion $GameVersion -ModName $ModName -OutputRomfsRoot $OutputRomfsRoot),
        "",
        "===== EN =====",
        (Get-InstallationGuideText -Language "en" -GameVersion $GameVersion -ModName $ModName -OutputRomfsRoot $OutputRomfsRoot)
    ) -join "`r`n"
    [IO.File]::WriteAllText($readmePath, $bilingualReadme, [Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{
        Root = $installRoot
        ReadmePath = $readmePath
        Targets = $targets
    }
}

function Reset-SelectedEmulatorInstallations {
    param(
        [string]$GameVersion,
        [string]$ModName
    )

    $requestedKeys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($key in (Get-RequestedEmulatorKeys)) {
        $null = $requestedKeys.Add($key)
    }

    $results = New-Object System.Collections.Generic.List[object]
    foreach ($target in Get-EmulatorInstallTargets -GameVersion $GameVersion -ModName $ModName) {
        if (-not $requestedKeys.Contains([string]$target.Key)) {
            continue
        }

        $removedMod = $false
        $removedConfig = $false
        $note = ""
        $error = ""
        try {
            if ([bool]$target.IsDetected) {
                $removedMod = Remove-PathIfExists -Path $target.ModRoot
                foreach ($legacyModRoot in @($target.LegacyModRoots)) {
                    if (-not [string]::IsNullOrWhiteSpace([string]$legacyModRoot)) {
                        $removedMod = (Remove-PathIfExists -Path $legacyModRoot) -or $removedMod
                    }
                }
                if (Test-Path -LiteralPath $target.SdmcConfigPath) {
                    if (Test-RandomizerManagedSwshModsExlConfig -Path $target.SdmcConfigPath) {
                        Remove-Item -LiteralPath $target.SdmcConfigPath -Force
                        $removedConfig = $true
                    } else {
                        $note = if ($script:UiLanguage -eq "en") {
                            "swsh-mods-exl config left in place because it does not look like it was generated by PokeFeurRandomSWSH."
                        } else {
                            "Config swsh-mods-exl laissee en place car elle ne semble pas venir de PokeFeurRandomSWSH."
                        }
                    }
                }
                Remove-EmptyDirectoryChain -StartPath $target.SdmcConfigRoot -StopAtPath $target.SdmcRoot
                Remove-EmptyDirectoryChain -StartPath (Split-Path -Parent $target.ModRoot) -StopAtPath $target.RootPath
                foreach ($legacyModRoot in @($target.LegacyModRoots)) {
                    if (-not [string]::IsNullOrWhiteSpace([string]$legacyModRoot)) {
                        Remove-EmptyDirectoryChain -StartPath (Split-Path -Parent ([string]$legacyModRoot)) -StopAtPath $target.RootPath
                    }
                }
            } else {
                $error = if ($script:UiLanguage -eq "en") {
                    ("{0} was not found on this PC." -f [string]$target.Name)
                } else {
                    ("{0} introuvable sur ce PC." -f [string]$target.Name)
                }
            }
        } catch {
            $error = $_.Exception.Message
        }

        $results.Add([pscustomobject]@{
            Emulator = [string]$target.Name
            Key = [string]$target.Key
            Detected = [bool]$target.IsDetected
            ModRoot = [string]$target.ModRoot
            SdmcConfigPath = [string]$target.SdmcConfigPath
            RemovedMod = $removedMod
            RemovedConfig = $removedConfig
            Note = $note
            Error = $error
        })
    }

    return [object[]]$results.ToArray()
}

function Get-GameTitleId {
    param([string]$GameVersion)

    if ((Get-NormalizedGameVersionSelection -Value $GameVersion) -eq "Shield") {
        return "01008DB008C2C000"
    }

    return "0100ABF008968000"
}

function Get-ExLaunchArtifactExefsRoot {
    param([string]$GameVersion)

    $titleId = Get-GameTitleId -GameVersion $GameVersion
    $scriptRoot = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $PSScriptRoot
    } elseif (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        Split-Path -Parent $PSCommandPath
    } else {
        (Get-Location).Path
    }
    $candidates = @(
        (Join-Path $scriptRoot ("assets\exlaunch\" + $titleId)),
        (Join-Path $scriptRoot ("research\swsh-mods-exl\artifact\atmosphere\contents\" + $titleId + "\exefs")),
        (Join-Path $scriptRoot ("research\downloads\" + ($(if ($titleId -eq "01008DB008C2C000") { "SHIELD_artifact\SHIELD_artifact" } else { "SWORD_artifact\SWORD_artifact" })) + "\atmosphere\contents\" + $titleId + "\exefs"))
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath (Join-Path $candidate "subsdk9")) {
            return $candidate
        }
    }
    return $candidates[0]
}

function Get-ExpectedExLaunchSubsdk9Hash {
    param(
        [string]$GameVersion,
        [string]$Variant = "stable"
    )

    $normalizedGameVersion = Get-NormalizedGameVersionSelection -Value $GameVersion
    if ($normalizedGameVersion -eq "Auto") {
        $normalizedGameVersion = "Sword"
    }
    $titleId = Get-GameTitleId -GameVersion $normalizedGameVersion
    $normalizedVariant = ([string]$Variant).Trim().ToLowerInvariant()
    switch ("$titleId|$normalizedVariant") {
        "0100ABF008968000|stable" { return "AB13EC3B8693EF475E5FD81221095D6862D3C34E179399E6B25F351FD7563331" }
        "0100ABF008968000|ryujinx" { return "AB13EC3B8693EF475E5FD81221095D6862D3C34E179399E6B25F351FD7563331" }
        "01008DB008C2C000|stable" { return "C3969FC0E35339295AE46E88BE915372019A60C12B674B61A21D67AFC08B8B14" }
        "01008DB008C2C000|ryujinx" { return "C3969FC0E35339295AE46E88BE915372019A60C12B674B61A21D67AFC08B8B14" }
        default { return "" }
    }
}

function Get-ExLaunchMainNpdmSourcePath {
    param(
        [string]$GameVersion,
        [string]$Variant = "stable"
    )

    $normalizedGameVersion = Get-NormalizedGameVersionSelection -Value $GameVersion
    if ($normalizedGameVersion -eq "Auto") {
        $normalizedGameVersion = "Sword"
    }

    $titleId = Get-GameTitleId -GameVersion $normalizedGameVersion
    $normalizedVariant = ([string]$Variant).Trim().ToLowerInvariant()
    $scriptRoot = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $PSScriptRoot
    } elseif (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        Split-Path -Parent $PSCommandPath
    } else {
        (Get-Location).Path
    }

    $candidates = switch ($normalizedVariant) {
        "ryujinx" {
            @(
                (Join-Path $scriptRoot ("assets\exlaunch\" + $titleId + "\main.npdm_ryujinx")),
                (Join-Path $scriptRoot ("assets\exlaunch\" + $titleId + "\main.npdm"))
            )
        }
        default {
            @(
                (Join-Path $scriptRoot ("assets\exlaunch\" + $titleId + "\main.npdm_stable")),
                (Join-Path $scriptRoot ("assets\exlaunch\" + $titleId + "\main.npdm"))
            )
        }
    }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return ""
}

function Get-ExLaunchVariantSubsdk9SourcePath {
    param(
        [string]$GameVersion,
        [string]$Variant = "stable"
    )

    $normalizedGameVersion = Get-NormalizedGameVersionSelection -Value $GameVersion
    if ($normalizedGameVersion -eq "Auto") {
        $normalizedGameVersion = "Sword"
    }

    $titleId = Get-GameTitleId -GameVersion $normalizedGameVersion
    $normalizedVariant = ([string]$Variant).Trim().ToLowerInvariant()
    $scriptRoot = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $PSScriptRoot
    } elseif (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        Split-Path -Parent $PSCommandPath
    } else {
        (Get-Location).Path
    }

    $candidates = switch ($normalizedVariant) {
        "ryujinx" {
            @(
                (Join-Path $scriptRoot ("assets\exlaunch\" + $titleId + "\subsdk9_ryujinx")),
                (Join-Path $scriptRoot ("research\swsh-mods-exl\artifact\atmosphere\contents\" + $titleId + "\exefs\subsdk9")),
                (Join-Path $scriptRoot ("research\downloads\" + ($(if ($titleId -eq "01008DB008C2C000") { "SHIELD_artifact\SHIELD_artifact" } else { "SWORD_artifact\SWORD_artifact" })) + "\atmosphere\contents\" + $titleId + "\exefs\subsdk9"))
            )
        }
        default {
            @(
                (Join-Path $scriptRoot ("assets\exlaunch\" + $titleId + "\subsdk9_stable")),
                (Join-Path $scriptRoot ("assets\exlaunch\" + $titleId + "\subsdk9"))
            )
        }
    }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return ""
}

function Test-ExLaunchSubsdk9Hash {
    param(
        [string]$Path,
        [string]$GameVersion,
        [string]$Variant = "stable"
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or (-not (Test-Path -LiteralPath $Path))) {
        return $false
    }

    $expectedHash = Get-ExpectedExLaunchSubsdk9Hash -GameVersion $GameVersion -Variant $Variant
    if ([string]::IsNullOrWhiteSpace($expectedHash)) {
        return $true
    }

    $actualHash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    return ($actualHash -ieq $expectedHash)
}

function Write-ExLaunchVariantManifest {
    param(
        [string]$OutputRomfsRoot,
        [string]$GameVersion
    )

    $packageRoot = Get-OutputPackageRoot -OutputRomfsRoot $OutputRomfsRoot
    $variantsRoot = Join-Path $packageRoot "exlaunch_variants"
    Ensure-Directory -Path $variantsRoot

    $stableSourcePath = Get-ExLaunchVariantSubsdk9SourcePath -GameVersion $GameVersion -Variant "stable"
    $ryujinxSourcePath = Get-ExLaunchVariantSubsdk9SourcePath -GameVersion $GameVersion -Variant "ryujinx"
    $stableVariantRoot = Join-Path $variantsRoot "stable"
    $ryujinxVariantRoot = Join-Path $variantsRoot "ryujinx"
    Ensure-Directory -Path $stableVariantRoot
    Ensure-Directory -Path $ryujinxVariantRoot

    if (-not [string]::IsNullOrWhiteSpace($stableSourcePath) -and (Test-Path -LiteralPath $stableSourcePath)) {
        Copy-Item -LiteralPath $stableSourcePath -Destination (Join-Path $stableVariantRoot "subsdk9") -Force
    }
    if (-not [string]::IsNullOrWhiteSpace($ryujinxSourcePath) -and (Test-Path -LiteralPath $ryujinxSourcePath)) {
        Copy-Item -LiteralPath $ryujinxSourcePath -Destination (Join-Path $ryujinxVariantRoot "subsdk9") -Force
    }

    $manifestPath = Join-Path $variantsRoot "manifest.json"
    $stableHash = if (Test-Path -LiteralPath (Join-Path $stableVariantRoot "subsdk9")) { (Get-FileHash -LiteralPath (Join-Path $stableVariantRoot "subsdk9") -Algorithm SHA256).Hash } else { "" }
    $ryujinxHash = if (Test-Path -LiteralPath (Join-Path $ryujinxVariantRoot "subsdk9")) { (Get-FileHash -LiteralPath (Join-Path $ryujinxVariantRoot "subsdk9") -Algorithm SHA256).Hash } else { "" }
    $manifest = [ordered]@{
        gameVersion = (Get-NormalizedGameVersionSelection -Value $GameVersion)
        titleId = (Get-GameTitleId -GameVersion $GameVersion)
        defaultOutputVariant = "stable"
        autoInstallVariantByEmulator = [ordered]@{
            eden = "stable"
            ryujinx = "ryujinx"
            yuzu = "stable"
            sudachi = "stable"
            citron = "stable"
            suyu = "stable"
            citronneo = "stable"
        }
        variants = [ordered]@{
            stable = [ordered]@{
                file = (Join-Path $stableVariantRoot "subsdk9")
                expectedHash = (Get-ExpectedExLaunchSubsdk9Hash -GameVersion $GameVersion -Variant "stable")
                actualHash = $stableHash
            }
            ryujinx = [ordered]@{
                file = (Join-Path $ryujinxVariantRoot "subsdk9")
                expectedHash = (Get-ExpectedExLaunchSubsdk9Hash -GameVersion $GameVersion -Variant "ryujinx")
                actualHash = $ryujinxHash
            }
        }
    } | ConvertTo-Json -Depth 6
    [IO.File]::WriteAllText($manifestPath, $manifest, [Text.UTF8Encoding]::new($false))
    return $manifestPath
}

function Sync-RyujinxSpecificSubsdk9 {
    param(
        [string]$DestinationExefsRoot,
        [string]$GameVersion,
        [string]$TargetKey
    )

    if (([string]$TargetKey).ToLowerInvariant() -ne "ryujinx") {
        return $false
    }

    if ([string]::IsNullOrWhiteSpace($DestinationExefsRoot)) {
        return $false
    }

    $sourcePath = Get-ExLaunchVariantSubsdk9SourcePath -GameVersion $GameVersion -Variant "ryujinx"
    $mainNpdmSourcePath = Get-ExLaunchMainNpdmSourcePath -GameVersion $GameVersion -Variant "ryujinx"
    if ([string]::IsNullOrWhiteSpace($sourcePath) -or (-not (Test-Path -LiteralPath $sourcePath))) {
        return $false
    }
    if ([string]::IsNullOrWhiteSpace($mainNpdmSourcePath) -or (-not (Test-Path -LiteralPath $mainNpdmSourcePath))) {
        return $false
    }

    if (-not (Test-ExLaunchSubsdk9Hash -Path $sourcePath -GameVersion $GameVersion -Variant "ryujinx")) {
        return $false
    }

    $destinationPath = Join-Path $DestinationExefsRoot "subsdk9"
    $mainNpdmDestinationPath = Join-Path $DestinationExefsRoot "main.npdm"
    Ensure-Directory -Path $DestinationExefsRoot
    Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force
    Copy-Item -LiteralPath $mainNpdmSourcePath -Destination $mainNpdmDestinationPath -Force
    return $true
}

function Sync-RyujinxModsJson {
    param(
        [pscustomobject]$Target
    )

    if (([string]$Target.Key).ToLowerInvariant() -ne "ryujinx") {
        return $false
    }
    if ([string]::IsNullOrWhiteSpace([string]$Target.RootPath) -or
        [string]::IsNullOrWhiteSpace([string]$Target.TitleId) -or
        [string]::IsNullOrWhiteSpace([string]$Target.ModName) -or
        [string]::IsNullOrWhiteSpace([string]$Target.ModRoot)) {
        return $false
    }

    $gameConfigRoot = Join-Path (Join-Path ([string]$Target.RootPath) "games") ([string]$Target.TitleId).ToLowerInvariant()
    $modsJsonPath = Join-Path $gameConfigRoot "mods.json"
    $titleModsRoot = Join-Path (Join-Path ([string]$Target.RootPath) "mods\contents") ([string]$Target.TitleId)
    $titleModsRootFullPath = ([IO.Path]::GetFullPath($titleModsRoot).TrimEnd('\') + '\')
    $targetModFullPath = ([IO.Path]::GetFullPath([string]$Target.ModRoot).TrimEnd('\') + '\')
    Ensure-Directory -Path $gameConfigRoot

    $mods = @()
    if (Test-Path -LiteralPath $modsJsonPath) {
        try {
            $existing = Get-Content -LiteralPath $modsJsonPath -Raw | ConvertFrom-Json
            if ($existing -and ($existing.PSObject.Properties.Name -contains "mods")) {
                $mods = @($existing.mods)
            }
        } catch {
            $mods = @()
        }
    }

    $updated = New-Object System.Collections.Generic.List[object]
    foreach ($mod in $mods) {
        $entryName = [string]$mod.name
        $entryPath = [string]$mod.path
        $entryFullPath = ""
        if (-not [string]::IsNullOrWhiteSpace($entryPath)) {
            try {
                $entryFullPath = ([IO.Path]::GetFullPath($entryPath).TrimEnd('\') + '\')
            } catch {
                $entryFullPath = ""
            }
        }

        if (($entryName -ieq ([string]$Target.ModName)) -or ($entryFullPath -ieq $targetModFullPath)) {
            continue
        }

        $entry = [ordered]@{}
        foreach ($property in $mod.PSObject.Properties) {
            $entry[$property.Name] = $property.Value
        }

        $entryLeaf = if ([string]::IsNullOrWhiteSpace($entryPath)) { "" } else { Split-Path -Leaf $entryPath }
        $isGeneratedRandomizerSibling = (-not [string]::IsNullOrWhiteSpace($entryFullPath)) -and
            $entryFullPath.StartsWith($titleModsRootFullPath, [StringComparison]::OrdinalIgnoreCase) -and
            (($entryName -match '^Randomizer') -or ($entryLeaf -match '^Randomizer'))
        if ($isGeneratedRandomizerSibling) {
            $entry["enabled"] = $false
        }

        $updated.Add([pscustomobject]$entry)
    }
    $updated.Add([pscustomobject]@{
        name = [string]$Target.ModName
        path = [IO.Path]::GetFullPath([string]$Target.ModRoot)
        enabled = $true
    })

    $payload = [ordered]@{
        mods = @($updated.ToArray())
    } | ConvertTo-Json -Depth 6
    [IO.File]::WriteAllText($modsJsonPath, $payload, [Text.UTF8Encoding]::new($false))
    return $true
}

function Get-ExLaunchArtifactRomfsRoot {
    param([string]$GameVersion)

    $scriptRoot = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $PSScriptRoot
    } elseif (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        Split-Path -Parent $PSCommandPath
    } else {
        (Get-Location).Path
    }
    $titleId = Get-GameTitleId -GameVersion $GameVersion
    $candidates = @(
        (Join-Path $scriptRoot "assets\exlaunch\runtime"),
        (Join-Path $scriptRoot ("research\swsh-mods-exl\artifact\atmosphere\contents\" + $titleId + "\romfs")),
        (Join-Path $scriptRoot ("research\downloads\" + ($(if ($titleId -eq "01008DB008C2C000") { "SHIELD_artifact\SHIELD_artifact" } else { "SWORD_artifact\SWORD_artifact" })) + "\atmosphere\contents\" + $titleId + "\romfs"))
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }
    return $candidates[0]
}

function Initialize-ScriptRecordCodec {
    if ("PokeFeurScriptRecordCodec" -as [type]) {
        return
    }

    Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Text;

public static class PokeFeurScriptRecordCodec
{
    private sealed class Entry
    {
        public ulong ScriptId;
        public string AmxPath;
        public string TextPath;
    }

    private static ushort ReadU16(byte[] data, int offset) { return BitConverter.ToUInt16(data, offset); }
    private static uint ReadU32(byte[] data, int offset) { return BitConverter.ToUInt32(data, offset); }
    private static ulong ReadU64(byte[] data, int offset) { return BitConverter.ToUInt64(data, offset); }
    private static int ReadI32(byte[] data, int offset) { return BitConverter.ToInt32(data, offset); }

    private static int GetFieldAddress(byte[] data, int tablePos, int fieldIndex)
    {
        if (tablePos < 4 || tablePos >= data.Length) return -1;
        int vtablePos = tablePos - ReadI32(data, tablePos);
        if (vtablePos < 0 || vtablePos + 4 > data.Length) return -1;
        int vtableLength = ReadU16(data, vtablePos);
        int slotPos = vtablePos + 4 + (fieldIndex * 2);
        if (slotPos + 2 > vtablePos + vtableLength) return -1;
        int fieldOffset = ReadU16(data, slotPos);
        if (fieldOffset == 0) return -1;
        int fieldAddress = tablePos + fieldOffset;
        return (fieldAddress >= 0 && fieldAddress < data.Length) ? fieldAddress : -1;
    }

    private static string ReadString(byte[] data, int fieldAddress)
    {
        if (fieldAddress < 0 || fieldAddress + 4 > data.Length) return "";
        int stringPos = fieldAddress + (int)ReadU32(data, fieldAddress);
        if (stringPos < 0 || stringPos + 4 > data.Length) return "";
        int length = (int)ReadU32(data, stringPos);
        if (length < 0 || stringPos + 4 + length > data.Length) return "";
        return Encoding.UTF8.GetString(data, stringPos + 4, length);
    }

    private static List<Entry> Parse(byte[] data)
    {
        List<Entry> entries = new List<Entry>();
        if (data == null || data.Length < 12) return entries;

        int rootTable = (int)ReadU32(data, 0);
        int vectorField = GetFieldAddress(data, rootTable, 0);
        if (vectorField < 0 || vectorField + 4 > data.Length) return entries;

        int vectorPos = vectorField + (int)ReadU32(data, vectorField);
        if (vectorPos < 0 || vectorPos + 4 > data.Length) return entries;
        int count = (int)ReadU32(data, vectorPos);

        for (int i = 0; i < count; i++)
        {
            int entryOffsetPos = vectorPos + 4 + (i * 4);
            if (entryOffsetPos + 4 > data.Length) break;
            int tablePos = entryOffsetPos + (int)ReadU32(data, entryOffsetPos);
            if (tablePos < 0 || tablePos >= data.Length) continue;

            int idAddress = GetFieldAddress(data, tablePos, 0);
            if (idAddress < 0 || idAddress + 8 > data.Length) continue;
            entries.Add(new Entry {
                ScriptId = ReadU64(data, idAddress),
                AmxPath = ReadString(data, GetFieldAddress(data, tablePos, 1)),
                TextPath = ReadString(data, GetFieldAddress(data, tablePos, 2))
            });
        }

        return entries;
    }

    private static ulong Fnv1a64(string text)
    {
        unchecked
        {
            ulong hash = 0xCBF29CE484222645UL;
            foreach (char c in text)
            {
                hash ^= c;
                hash *= 0x00000100000001B3UL;
            }
            return hash;
        }
    }

    private static void Upsert(List<Entry> entries, ulong scriptId, string amxPath, string textPath)
    {
        for (int i = 0; i < entries.Count; i++)
        {
            if (entries[i].ScriptId == scriptId)
            {
                entries[i].AmxPath = amxPath;
                entries[i].TextPath = textPath;
                return;
            }
        }
        entries.Add(new Entry { ScriptId = scriptId, AmxPath = amxPath, TextPath = textPath });
    }

    private static void AddU16(List<byte> bytes, int value) { bytes.AddRange(BitConverter.GetBytes((ushort)value)); }
    private static void AddU32(List<byte> bytes, uint value) { bytes.AddRange(BitConverter.GetBytes(value)); }
    private static void AddI32(List<byte> bytes, int value) { bytes.AddRange(BitConverter.GetBytes(value)); }
    private static void AddU64(List<byte> bytes, ulong value) { bytes.AddRange(BitConverter.GetBytes(value)); }

    private static void SetU32(List<byte> bytes, int offset, uint value)
    {
        byte[] raw = BitConverter.GetBytes(value);
        for (int i = 0; i < 4; i++) bytes[offset + i] = raw[i];
    }

    private static void Align(List<byte> bytes, int alignment)
    {
        while ((bytes.Count % alignment) != 0) bytes.Add(0);
    }

    private static byte[] Build(List<Entry> entries)
    {
        List<byte> bytes = new List<byte>();
        List<int> vectorOffsetLocations = new List<int>();
        List<int> tablePositions = new List<int>();
        List<Tuple<int, string>> stringRefs = new List<Tuple<int, string>>();

        AddU32(bytes, 0);
        int rootVtable = bytes.Count;
        AddU16(bytes, 6);
        AddU16(bytes, 8);
        AddU16(bytes, 4);
        Align(bytes, 4);

        int rootTable = bytes.Count;
        SetU32(bytes, 0, (uint)rootTable);
        AddI32(bytes, rootTable - rootVtable);
        int rootVectorField = bytes.Count;
        AddU32(bytes, 0);

        int vectorPos = bytes.Count;
        AddU32(bytes, (uint)entries.Count);
        for (int i = 0; i < entries.Count; i++)
        {
            vectorOffsetLocations.Add(bytes.Count);
            AddU32(bytes, 0);
        }

        for (int i = 0; i < entries.Count; i++)
        {
            Entry entry = entries[i];
            int vtablePos = bytes.Count;
            AddU16(bytes, 10);
            AddU16(bytes, 24);
            AddU16(bytes, 8);
            AddU16(bytes, 16);
            AddU16(bytes, 20);
            Align(bytes, 8);

            int tablePos = bytes.Count;
            tablePositions.Add(tablePos);
            AddI32(bytes, tablePos - vtablePos);
            AddU32(bytes, 0);
            AddU64(bytes, entry.ScriptId);
            int amxOffsetLocation = bytes.Count;
            AddU32(bytes, 0);
            int textOffsetLocation = bytes.Count;
            AddU32(bytes, 0);
            stringRefs.Add(Tuple.Create(amxOffsetLocation, entry.AmxPath ?? ""));
            stringRefs.Add(Tuple.Create(textOffsetLocation, entry.TextPath ?? ""));
        }

        SetU32(bytes, rootVectorField, (uint)(vectorPos - rootVectorField));
        for (int i = 0; i < tablePositions.Count; i++)
        {
            SetU32(bytes, vectorOffsetLocations[i], (uint)(tablePositions[i] - vectorOffsetLocations[i]));
        }

        foreach (Tuple<int, string> item in stringRefs)
        {
            Align(bytes, 4);
            int stringPos = bytes.Count;
            byte[] raw = Encoding.UTF8.GetBytes(item.Item2);
            AddU32(bytes, (uint)raw.Length);
            bytes.AddRange(raw);
            bytes.Add(0);
            SetU32(bytes, item.Item1, (uint)(stringPos - item.Item1));
        }

        return bytes.ToArray();
    }

    public static byte[] Patch(byte[] data, bool runtimePcControls, bool earlyBikeEnabled, bool dexAnimationsEnabled)
    {
        List<Entry> entries = Parse(data);
        if (entries.Count == 0) throw new ArgumentException("script_id_record.bin is empty or invalid.");

        if (earlyBikeEnabled)
        {
            Upsert(entries, Fnv1a64("grant_early_bike"), "bin/script/amx/early_bike.amx", "script/script_dummy.dat");
        }

        if (runtimePcControls)
        {
            Upsert(entries, Fnv1a64("randomizer_pc_menu"), "bin/script/amx/randomizer_pc_menu.amx", "script/script_dummy.dat");
            Upsert(entries, 13435777772824609090UL, "bin/script/amx/randomizer_pc_menu.amx", "script/pokemoncenter.dat");
        }

        if (dexAnimationsEnabled)
        {
            // Le module fait apparaitre un objet de terrain dont le nom de script est
            // getFNV1aHashedString("dex_dialog") (patches/dex_animations.hpp). Sans cette
            // entree l'objet apparait mais l'interaction ne lance aucun script.
            Upsert(entries, Fnv1a64("dex_dialog"), "bin/script/amx/dex_animations.amx", "script/script_dummy.dat");
        }

        return Build(entries);
    }
}
"@
}

function Update-UserScriptRecordForExLaunch {
    param(
        [string]$OutputRomfsRoot,
        [bool]$RuntimePcControlsEnabled = $false,
        [bool]$EarlyBikeEnabled = $false,
        [bool]$DexAnimationsEnabled = $false
    )

    $scriptRecordPath = Join-Path $OutputRomfsRoot "bin\script\param\script_id\script_id_record.bin"
    if (-not (Test-Path -LiteralPath $scriptRecordPath)) {
        return $false
    }

    Initialize-ScriptRecordCodec
    $data = [IO.File]::ReadAllBytes($scriptRecordPath)
    $patched = [PokeFeurScriptRecordCodec]::Patch($data, $RuntimePcControlsEnabled, $EarlyBikeEnabled, $DexAnimationsEnabled)
    [IO.File]::WriteAllBytes($scriptRecordPath, $patched)
    return $RuntimePcControlsEnabled
}

function Copy-ExLaunchCustomRomfsFiles {
    param(
        [string]$SourceRomfsRoot,
        [string]$OutputRomfsRoot,
        [string]$GameVersion,
        [bool]$RuntimePcControlsEnabled = $false,
        [bool]$EarlyBikeEnabled = $false,
        [bool]$DexAnimationsEnabled = $false
    )

    $artifactRomfsRoot = Get-ExLaunchArtifactRomfsRoot -GameVersion $GameVersion
    $allRuntimeFiles = @(
        "bin\message\English\script\string_format.dat",
        "bin\message\English\script\string_format.tbl",
        "bin\script\amx\custom_message.amx",
        "bin\script\amx\dex_animations.amx",
        "bin\script\amx\early_bike.amx",
        "bin\script\amx\randomizer_pc_menu.amx"
    )
    $relativeFiles = New-Object System.Collections.Generic.List[string]
    if ($EarlyBikeEnabled) {
        $relativeFiles.Add("bin\script\amx\early_bike.amx")
    }
    if ($RuntimePcControlsEnabled) {
        $relativeFiles.Add("bin\script\amx\randomizer_pc_menu.amx")
    }
    if ($DexAnimationsEnabled) {
        $relativeFiles.Add("bin\script\amx\dex_animations.amx")
    }

    $missingFiles = New-Object System.Collections.Generic.List[string]
    foreach ($relativePath in $relativeFiles) {
        $sourcePath = Join-Path $artifactRomfsRoot $relativePath
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            $missingFiles.Add($relativePath)
        }
    }
    if ($missingFiles.Count -gt 0) {
        throw ("ExLaunch runtime files missing under '{0}': {1}" -f $artifactRomfsRoot, (($missingFiles.ToArray()) -join ", "))
    }

    foreach ($relativePath in $relativeFiles) {
        $sourcePath = Join-Path $artifactRomfsRoot $relativePath
        $targetPath = Join-Path $OutputRomfsRoot $relativePath
        Ensure-ParentDirectory -Path $targetPath
        Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force
    }

    $sourceScriptRecordPath = Join-Path $SourceRomfsRoot "bin\script\param\script_id\script_id_record.bin"
    $targetScriptRecordPath = Join-Path $OutputRomfsRoot "bin\script\param\script_id\script_id_record.bin"
    $needsScriptRecordPatch = $RuntimePcControlsEnabled -or $EarlyBikeEnabled -or $DexAnimationsEnabled
    if ($needsScriptRecordPatch -and (Test-Path -LiteralPath $sourceScriptRecordPath)) {
        Ensure-ParentDirectory -Path $targetScriptRecordPath
        Copy-Item -LiteralPath $sourceScriptRecordPath -Destination $targetScriptRecordPath -Force
    } elseif (-not $needsScriptRecordPatch -and (Test-Path -LiteralPath $targetScriptRecordPath)) {
        Remove-Item -LiteralPath $targetScriptRecordPath -Force
    }

    foreach ($relativePath in $allRuntimeFiles) {
        if ($relativeFiles.Contains($relativePath)) {
            continue
        }

        $stalePath = Join-Path $OutputRomfsRoot $relativePath
        if (Test-Path -LiteralPath $stalePath) {
            Remove-Item -LiteralPath $stalePath -Force
        }
    }

    if (-not $needsScriptRecordPatch) {
        return $false
    }

    return (Update-UserScriptRecordForExLaunch -OutputRomfsRoot $OutputRomfsRoot -RuntimePcControlsEnabled $RuntimePcControlsEnabled -EarlyBikeEnabled $EarlyBikeEnabled -DexAnimationsEnabled $DexAnimationsEnabled)
}

function Deploy-ExLaunchModule {
    param(
        [string]$SourceRomfsRoot,
        [string]$SourceExefsRoot,
        [string]$OutputRomfsRoot,
        [string]$GameVersion,
        [bool]$RuntimePcControlsEnabled = $false,
        [bool]$EarlyBikeEnabled = $false,
        [bool]$DexAnimationsEnabled = $false
    )

    $normalizedGameVersion = Get-NormalizedGameVersionSelection -Value $GameVersion
    if ($normalizedGameVersion -eq "Auto") {
        $normalizedGameVersion = "Sword"
    }
    $titleId = Get-GameTitleId -GameVersion $normalizedGameVersion
    $userExefsRoot = Resolve-SourceExefsRoot -SourceRomfsRoot $SourceRomfsRoot -SourceExefsRoot $SourceExefsRoot -GameVersion $normalizedGameVersion
    $mainNpdmSourcePath = Get-ExLaunchMainNpdmSourcePath -GameVersion $normalizedGameVersion
    $subsdkSourcePath = Get-ExLaunchVariantSubsdk9SourcePath -GameVersion $normalizedGameVersion -Variant "stable"
    $subsdkSourceRoot = if ([string]::IsNullOrWhiteSpace($subsdkSourcePath)) { "" } else { Split-Path -Parent $subsdkSourcePath }
    $missingFiles = New-Object System.Collections.Generic.List[string]
    if ([string]::IsNullOrWhiteSpace($mainNpdmSourcePath) -or (-not (Test-Path -LiteralPath $mainNpdmSourcePath))) {
        $missingFiles.Add("main.npdm ExLaunch-compatible du projet")
    }
    if (-not (Test-Path -LiteralPath $subsdkSourcePath)) {
        $missingFiles.Add($subsdkSourcePath)
    }

    $packageRoot = Get-OutputPackageRoot -OutputRomfsRoot $OutputRomfsRoot
    $targetRoot = Join-Path $packageRoot "exefs"
    $mainNpdmTargetPath = Join-Path $targetRoot "main.npdm"
    $subsdkTargetPath = Join-Path $targetRoot "subsdk9"

    if ($missingFiles.Count -gt 0) {
        return [pscustomobject]@{
            Requested = $true
            Available = $false
            Deployed = $false
            RuntimePcControlsEnabled = $RuntimePcControlsEnabled
            RuntimePcScriptApplied = $false
            GameVersion = $normalizedGameVersion
            TitleId = $titleId
            SourceRoot = $userExefsRoot
            SubsdkSourceRoot = $subsdkSourceRoot
            TargetRoot = $targetRoot
            MainNpdmPath = $mainNpdmTargetPath
            Subsdk9Path = $subsdkTargetPath
            VariantManifestPath = ""
            MissingFiles = @($missingFiles.ToArray())
        }
    }

    Ensure-Directory -Path $targetRoot
    Copy-Item -LiteralPath $mainNpdmSourcePath -Destination $mainNpdmTargetPath -Force
    Copy-Item -LiteralPath $subsdkSourcePath -Destination $subsdkTargetPath -Force
    if (-not (Test-ExLaunchSubsdk9Hash -Path $subsdkTargetPath -GameVersion $normalizedGameVersion -Variant "stable")) {
        throw ("subsdk9 stable hash mismatch for {0} at {1}" -f $normalizedGameVersion, $subsdkTargetPath)
    }
    $pcScriptApplied = Copy-ExLaunchCustomRomfsFiles -SourceRomfsRoot $SourceRomfsRoot -OutputRomfsRoot $OutputRomfsRoot -GameVersion $normalizedGameVersion -RuntimePcControlsEnabled $RuntimePcControlsEnabled -EarlyBikeEnabled $EarlyBikeEnabled -DexAnimationsEnabled $DexAnimationsEnabled
    $variantManifestPath = Write-ExLaunchVariantManifest -OutputRomfsRoot $OutputRomfsRoot -GameVersion $normalizedGameVersion

    return [pscustomobject]@{
        Requested = $true
        Available = $true
        Deployed = $true
        RuntimePcControlsEnabled = $RuntimePcControlsEnabled
        RuntimePcScriptApplied = $pcScriptApplied
        GameVersion = $normalizedGameVersion
        TitleId = $titleId
        SourceRoot = $userExefsRoot
        SubsdkSourceRoot = $subsdkSourceRoot
        TargetRoot = $targetRoot
        MainNpdmPath = $mainNpdmTargetPath
        Subsdk9Path = $subsdkTargetPath
        VariantManifestPath = $variantManifestPath
        MissingFiles = @()
    }
}

function Convert-BytesToHexString {
    param([byte[]]$Data)
    return (($Data | ForEach-Object { $_.ToString("X2") }) -join " ")
}

function New-IpsPatchBytes {
    param(
        [int]$Offset,
        [byte[]]$Data
    )

    return New-IpsPatchBytesFromRecords -Records @([pscustomobject]@{
        Offset = $Offset
        Data = $Data
    })
}

function New-IpsPatchBytesFromRecords {
    param([object[]]$Records)

    if (-not $Records -or $Records.Count -lt 1) {
        throw "Patch IPS vide."
    }

    $useIps32 = $false
    foreach ($record in $Records) {
        if ([uint64]$record.Offset -gt 0xFFFFFF) {
            $useIps32 = $true
            break
        }
    }

    $bytes = New-Object System.Collections.Generic.List[byte]
    $header = if ($useIps32) { "IPS32" } else { "PATCH" }
    foreach ($b in [Text.Encoding]::ASCII.GetBytes($header)) { $bytes.Add($b) }

    foreach ($record in $Records) {
        $Offset = [long]$record.Offset
        $Data = [byte[]]$record.Data

        if ($Offset -lt 0 -or ($useIps32 -and $Offset -gt 4294967295L) -or ((-not $useIps32) -and $Offset -gt 16777215L)) {
            $feature = if ($record.PSObject.Properties.Name -contains "Feature") { [string]$record.Feature } else { "unknown" }
            $game = if ($record.PSObject.Properties.Name -contains "Game") { [string]$record.Game } else { "unknown" }
            $buildId = if ($record.PSObject.Properties.Name -contains "BuildId") { [string]$record.BuildId } else { "unknown" }
            throw "Offset IPS invalide: 0x$($Offset.ToString('X')) (feature=$feature, game=$game, buildId=$buildId)."
        }
        if (-not $Data -or $Data.Length -lt 1 -or $Data.Length -gt 0xFFFF) {
            throw "Taille de patch IPS invalide."
        }

        if ($useIps32) {
            $bytes.Add([byte](($Offset -shr 24) -band 0xFF))
        }
        $bytes.Add([byte](($Offset -shr 16) -band 0xFF))
        $bytes.Add([byte](($Offset -shr 8) -band 0xFF))
        $bytes.Add([byte]($Offset -band 0xFF))
        $bytes.Add([byte](($Data.Length -shr 8) -band 0xFF))
        $bytes.Add([byte]($Data.Length -band 0xFF))
        foreach ($b in $Data) { $bytes.Add($b) }
    }

    $footer = if ($useIps32) { "EEOF" } else { "EOF" }
    foreach ($b in [Text.Encoding]::ASCII.GetBytes($footer)) { $bytes.Add($b) }
    return [byte[]]$bytes.ToArray()
}

function Write-IpsPatchFile {
    param(
        [string]$Path,
        [int]$Offset,
        [byte[]]$Data
    )

    Ensure-ParentDirectory -Path $Path
    [IO.File]::WriteAllBytes($Path, (New-IpsPatchBytes -Offset $Offset -Data $Data))
}

function Write-IpsPatchFileMulti {
    param(
        [string]$Path,
        [object[]]$Records
    )

    Ensure-ParentDirectory -Path $Path
    [IO.File]::WriteAllBytes($Path, (New-IpsPatchBytesFromRecords -Records $Records))
}

function Write-ExeFsPatches {
    param(
        [string]$OutputRomfsRoot,
        [object[]]$GymLeagueStoryCaps = @()
    )

    $enabledDefinitions = New-Object System.Collections.Generic.List[object]
    $expLevelCapMode = Get-SelectedExpLevelCapMode
    $effectiveDynamicExpLevelCap = Get-AnyExpLevelCapEnabled
    $expLevelCapRequiresExLaunch = [bool](Get-AnyExLaunchRuntimeFeatureEnabled)

    # EXP level caps, runtime EXP multiplier, and EXP Share state now go through
    # ExLaunch. Do not emit raw IPS hooks here; stale IPS files are removed below.

    $packageRoot = Get-OutputPackageRoot -OutputRomfsRoot $OutputRomfsRoot
    $patchRoot = Join-Path $packageRoot "exefs"
    foreach ($patch in $ExpShareDisablePatchDefinitions) {
        $stalePath = Join-Path $patchRoot ($patch.BuildId + ".ips")
        if (Test-Path -LiteralPath $stalePath) {
            Remove-Item -LiteralPath $stalePath -Force
        }
    }

    if ($enabledDefinitions.Count -lt 1) {
        return [pscustomobject]@{
            Enabled = $false
            PatchRoot = $patchRoot
            FilesWritten = 0
            DisableExpShareEnabled = [bool]$DisableExpShare
            DynamicExpLevelCapEnabled = $false
            StoryGymLeagueExpCapEnabled = $false
            ExpLevelCapRequiresExLaunch = $expLevelCapRequiresExLaunch
            Patches = @()
        }
    }

    $written = New-Object System.Collections.Generic.List[object]

    $groupedPatches = @($enabledDefinitions.ToArray() | Group-Object -Property BuildId)
    foreach ($group in $groupedPatches) {
        $patchPath = Join-Path $patchRoot ($group.Name + ".ips")
        Write-IpsPatchFileMulti -Path $patchPath -Records ([object[]]$group.Group)
        $fileFeatures = @($group.Group | Select-Object -ExpandProperty Feature -Unique)

        foreach ($patch in $group.Group) {
            $entry = [ordered]@{
                feature = $patch.Feature
                game = $patch.Game
                buildId = $patch.BuildId
                file = $patchPath
                fileFeatures = @($fileFeatures)
                offset = ("0x{0:X6}" -f ([int]$patch.Offset))
                data = Convert-BytesToHexString -Data ([byte[]]$patch.Data)
                meaning = $patch.Meaning
                notes = [ordered]@{
                    fr = $patch.NotesFr
                    en = $patch.NotesEn
                }
            }
            if ($patch.PSObject.Properties.Name -contains "VirtualAddress") {
                $entry["virtualAddress"] = ("0x{0:X6}" -f ([int]$patch.VirtualAddress))
            }
            $written.Add([pscustomobject]$entry)
        }
    }

    return [pscustomobject]@{
        Enabled = $true
        PatchRoot = $patchRoot
        FilesWritten = $groupedPatches.Count
        DisableExpShareEnabled = [bool]$DisableExpShare
        DynamicExpLevelCapEnabled = $false
        StoryGymLeagueExpCapEnabled = $false
        ExpLevelCapRequiresExLaunch = $expLevelCapRequiresExLaunch
        Patches = [object[]]$written.ToArray()
    }
}

function Write-DisableExpSharePatches {
    param([string]$OutputRomfsRoot)

    $previousDynamicCap = $DynamicExpLevelCap
    $previousStrictBossCap = $StrictBossMaxLevelCap
    $previousMainStorySoftCap = $MainStorySoftLevelCap
    $previousGymLeagueStoryCap = $GymLeagueStoryLevelCap
    $previousStoryMajorBattleOrderCap = $StoryMajorBattleOrderLevelCap
    try {
        $script:DynamicExpLevelCap = [switch]$false
        $script:StrictBossMaxLevelCap = [switch]$false
        $script:MainStorySoftLevelCap = [switch]$false
        $script:GymLeagueStoryLevelCap = [switch]$false
        $script:StoryMajorBattleOrderLevelCap = [switch]$false
        return Write-ExeFsPatches -OutputRomfsRoot $OutputRomfsRoot
    } finally {
        $script:DynamicExpLevelCap = $previousDynamicCap
        $script:StrictBossMaxLevelCap = $previousStrictBossCap
        $script:MainStorySoftLevelCap = $previousMainStorySoftCap
        $script:GymLeagueStoryLevelCap = $previousGymLeagueStoryCap
        $script:StoryMajorBattleOrderLevelCap = $previousStoryMajorBattleOrderCap
    }
}

function Write-ExpLevelCapExLaunchConfig {
    param(
        [string]$OutputRomfsRoot,
        [object[]]$MainStorySoftCaps = @(),
        [object[]]$GymLeagueStoryCaps = @()
    )

    if (-not (Get-AnyExLaunchRuntimeFeatureEnabled)) {
        return ""
    }

    $selectedMode = [string](Get-SelectedExpLevelCapMode)
    $mode = if ($selectedMode -in @("storyMainProgressionSoft", "storyGymLeague")) { "story_gym_league" } else { "receiver_vs_defeated" }
    $requestedMode = switch ($selectedMode) {
        "storyMainProgressionSoft" { "story_main_progression_soft" }
        "storyGymLeague" { "story_gym_league" }
        "storyOrderedMajorBattles" { "story_ordered_major_battles" }
        "strictBossMaxLevel" { "strict_boss_max_level" }
        "receiverVsDefeatedPokemon" { "receiver_vs_defeated" }
        default { "receiver_vs_defeated" }
    }
    $caps = @(20, 25, 30, 35, 40, 45, 50, 55, 65)
    if ($mode -eq "story_gym_league") {
        $storyCapsSource = if ($selectedMode -eq "storyMainProgressionSoft") { $MainStorySoftCaps } else { $GymLeagueStoryCaps }
        $storyCapsArray = Convert-ToObjectArray $storyCapsSource
        if ((Get-ObjectArrayCount $storyCapsArray) -eq 9) {
            $caps = @($storyCapsArray | ForEach-Object { [Math]::Max(1, [Math]::Min(100, [int]$_.capLevel)) })
        }
    }

    $packageRoot = Get-OutputPackageRoot -OutputRomfsRoot $OutputRomfsRoot
    $packageConfigPath = Join-Path $packageRoot "sdmc\config\swsh-mods-exl\config.toml"
    $romfsFallbackConfigRoot = Join-Path $packageRoot "romfs\config\swsh-mods-exl"
    $romfsFallbackConfigPath = Join-Path $packageRoot "romfs\config\swsh-mods-exl\config.toml"
    $emulatorSdmcRoot = Get-EmulatorSdmcRootForOutput -OutputRomfsRoot $OutputRomfsRoot
    $configPath = if ([string]::IsNullOrWhiteSpace($emulatorSdmcRoot)) {
        $packageConfigPath
    } else {
        Join-Path $emulatorSdmcRoot "config\swsh-mods-exl\config.toml"
    }

    $capText = ($caps | ForEach-Object { [string]$_ }) -join ", "
    $capActiveText = if (Get-AnyExpLevelCapEnabled) { "true" } else { "false" }
    $runtimeExpActiveText = if (Get-RuntimeExpMultiplierEnabled) { "true" } else { "false" }
    $runtimeExpEnabledText = if (Get-RuntimeExpMultiplierEnabled) { "true" } else { "false" }
    $expShareEnabledText = if ([bool]$DisableExpShare) { "false" } else { "true" }
    $earlyBikeActiveText = if ([bool]$EarlyBike) { "true" } else { "false" }
    $runtimePcActiveText = if (Get-RandomizerPcMenuEnabled) { "true" } else { "false" }
    $liveEncounterMode = Get-LiveEncounterRandomizerMode
    $liveEncounterActiveText = if (Get-LiveEncounterRandomizerEnabled) { "true" } else { "false" }
    $liveVisibleModeText = Get-LiveVisibleModeValue
    $liveBattleModeText = Get-EffectiveLiveBattleModeValue
    $liveVisiblePoolText = (@(Get-LiveVisibleSpeciesPool) | ForEach-Object { [string][int]$_ }) -join ", "
    $liveBattlePoolText = (@(Get-LiveBattleSpeciesPool) | ForEach-Object { [string][int]$_ }) -join ", "

    $boolText = { param([bool]$Value) if ($Value) { "true" } else { "false" } }
    $overworldShinyActiveText = & $boolText ([bool]$ModOverworldShiny)
    $overworldShinyBoostText = [string][Math]::Max(0, [Math]::Min(100, [int]$OverworldShinyBoostPercent))
    $underworldActiveText = & $boolText ([bool]$ModUnderworld)
    $cameraTweaksActiveText = & $boolText ([bool]$ModCameraTweaks)
    $uncapLevelActiveText = & $boolText ([bool]$ModUncapLevel)
    $freecamActiveText = & $boolText ([bool]$ModFreecam)
    $glimwoodActiveText = & $boolText ([bool]$ModGlimwoodOverworld)
    $glimwoodMaxSpawnsText = [string][Math]::Max(1, [Math]::Min(20, [int]$GlimwoodMaxSpawns))
    $synchroActiveText = & $boolText ([bool]$ModSynchroMode)
    $extendedFollowingActiveText = & $boolText ([bool]$ModExtendedFollowing)
    $fishingTweaksActiveText = & $boolText ([bool]$ModFishingTweaks)
    $dexAnimationsActiveText = & $boolText ([bool]$ModDexAnimations)
    $liveEncounterMapping = Get-LiveEncounterMappingValue
    $liveEncounterVisibleBehavior = Get-LiveEncounterVisibleBehaviorValue
    $liveEncounterDrawMode = Get-LiveEncounterDrawModeValue
    $liveEncounterSeedText = ([UInt64](Resolve-SeedValue -SeedValue $Seed)).ToString([Globalization.CultureInfo]::InvariantCulture)
    $liveEncounterVisualSpeciesPool = Get-OverworldVisualSpeciesPool -RomfsRoot $SourceRomfs -AllowLegendaries ([bool]$AllowLegendaryGrassEncounters)
    $liveEncounterVisualSpeciesText = (@($liveEncounterVisualSpeciesPool) | ForEach-Object { [string][int]$_ }) -join ", "
    # Toujours emettre un flottant TOML (ex: 2.0) : le module lit multiplier en float,
    # un entier TOML ne se convertit pas et retomberait sur la valeur par defaut 1.0.
    $runtimeMultiplierText = ([double]$ExpYieldMultiplier).ToString("0.0##", [Globalization.CultureInfo]::InvariantCulture)
    $content = @"
# Generated by PokeFeurRandomSWSH.
# Managed-by: PokeFeurRandomSWSH
# Requested-exp-cap-mode: $requestedMode
# ExLaunch-exp-cap-mode: $mode
# Install this under the Ryujinx sdcard config/swsh-mods-exl/config.toml
# together with the built swsh-mods-exl ExLaunch module.

[overworld_shiny]
active = $overworldShinyActiveText
boosted_percentage = $overworldShinyBoostText
# La boite de message demande des fichiers ROMFS supplementaires et peut faire
# croire a un chargement infini au retour d'un combat : on la laisse coupee.
show_message_box = false

[underworld]
active = $underworldActiveText

[camera_tweaks]
active = $cameraTweaksActiveText

[uncap_level]
active = $uncapLevelActiveText
fully = true

[freecam]
active = $freecamActiveText

[glimwood_overworld]
active = $glimwoodActiveText
maximum_spawns = $glimwoodMaxSpawnsText

[synchro_mode]
active = $synchroActiveText

[extended_following]
active = $extendedFollowingActiveText

[fishing_tweaks]
active = $fishingTweaksActiveText
keep_chain_after_brilliant = true

[dex_animations]
active = $dexAnimationsActiveText

[randomizer]
active = $liveEncounterActiveText
# Deux reglages independants : ce qui apparait, ce qu'on affronte.
# vanilla | random | zone | global (+ decouverte pour le visible uniquement)
visible_mode = "$liveVisibleModeText"
battle_mode = "$liveBattleModeText"
# Especes autorisees au tirage, deja filtrees (legendaires, generations).
# Une liste vide veut dire "tout le pokedex national".
visible_pool = [$liveVisiblePoolText]
battle_pool = [$liveBattlePoolText]
reset_discoveries = false
# Anciennes cles, conservees pour les configs generees avant la refonte.
mode = "$liveEncounterMode"
mapping = "$liveEncounterMapping"
visible_behavior = "$liveEncounterVisibleBehavior"
draw_mode = "$liveEncounterDrawMode"
seed = $liveEncounterSeedText
visual_species = [$liveEncounterVisualSpeciesText]

[exp_level_cap]
active = $capActiveText
mode = "$mode"
story_caps = [$capText]

[exp_runtime]
active = $runtimeExpActiveText
enabled = $runtimeExpEnabledText
multiplier = $runtimeMultiplierText

[exp_share]
enabled = $expShareEnabledText

[runtime_pc]
active = $runtimePcActiveText

[runtime_status]
active = false

[early_bike]
active = $earlyBikeActiveText
"@
    Ensure-ParentDirectory -Path $packageConfigPath
    [IO.File]::WriteAllText($packageConfigPath, $content, [Text.UTF8Encoding]::new($false))

    Ensure-ParentDirectory -Path $configPath
    [IO.File]::WriteAllText($configPath, $content, [Text.UTF8Encoding]::new($false))

    if (Test-Path -LiteralPath $romfsFallbackConfigPath) {
        Remove-Item -LiteralPath $romfsFallbackConfigPath -Force
    }
    if ((Test-Path -LiteralPath $romfsFallbackConfigRoot) -and -not (Get-ChildItem -LiteralPath $romfsFallbackConfigRoot -Force | Select-Object -First 1)) {
        Remove-Item -LiteralPath $romfsFallbackConfigRoot -Force
        $romfsConfigRoot = Split-Path -Parent $romfsFallbackConfigRoot
        if ((Test-Path -LiteralPath $romfsConfigRoot) -and -not (Get-ChildItem -LiteralPath $romfsConfigRoot -Force | Select-Object -First 1)) {
            Remove-Item -LiteralPath $romfsConfigRoot -Force
        }
    }
    return $configPath
}

function Sync-SourceFileToOutput {
    param(
        [string]$SourceRoot,
        [string]$OutputRoot,
        [string]$RelativePath
    )

    $sourcePath = Join-Path $SourceRoot $RelativePath
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        return
    }

    $outputPath = Join-Path $OutputRoot $RelativePath
    Ensure-ParentDirectory -Path $outputPath
    Copy-Item -LiteralPath $sourcePath -Destination $outputPath -Force
}

function Sync-SourceDirToOutput {
    param(
        [string]$SourceRoot,
        [string]$OutputRoot,
        [string]$RelativePath
    )

    $sourceDir = Join-Path $SourceRoot $RelativePath
    if (-not (Test-Path -LiteralPath $sourceDir)) {
        return
    }

    $outputDir = Join-Path $OutputRoot $RelativePath
    Ensure-Directory -Path $outputDir
    foreach ($entry in Get-ChildItem -LiteralPath $sourceDir -Force) {
        Copy-Item -LiteralPath $entry.FullName -Destination $outputDir -Recurse -Force
    }
}

# Multiplicateur de prix, lu comme un nombre a virgule independant de la langue
# du systeme : sur un Windows francais, [double]"0.5" echoue et donnerait 5.
function Get-ShopPriceModeValue {
    switch (Normalize-Mode $ShopPriceMode) {
        "vanilla" { return "vanilla" }
        "unchanged" { return "vanilla" }
        "inchange" { return "vanilla" }
        "random" { return "random" }
        "aleatoire" { return "random" }
        default { return "multiplier" }
    }
}

function Get-ShopPriceBounds {
    <#
        Les deux bornes du mode aleatoire, remises dans l'ordre et bridees sur
        ce qu'un prix peut valoir dans le jeu (u32, plafonne a 999999 comme la
        mise a l'echelle).
    #>
    $min = [int]$ShopPriceMin
    $max = [int]$ShopPriceMax
    if ($min -lt 1) { $min = 1 }
    if ($max -lt 1) { $max = 1 }
    if ($min -gt 999999) { $min = 999999 }
    if ($max -gt 999999) { $max = 999999 }
    if ($min -gt $max) {
        $echange = $min
        $min = $max
        $max = $echange
    }
    return @{ Min = $min; Max = $max }
}

function Get-ShopPriceMultiplierValue {
    $text = ([string]$ShopPriceMultiplier).Trim().Replace(",", ".")
    if ([string]::IsNullOrWhiteSpace($text)) {
        return 1.0
    }
    $parsed = 0.0
    if (-not [double]::TryParse($text, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$parsed)) {
        return 1.0
    }
    if ($parsed -lt 0.0) { return 0.0 }
    if ($parsed -gt 100.0) { return 100.0 }
    return $parsed
}

function Get-RequiredRomfsAssets {
    $files = New-Object System.Collections.Generic.HashSet[string]
    $dirs = New-Object System.Collections.Generic.HashSet[string]

    $needsTrainer = $true -or
        (Normalize-Mode $TrainerSpeciesMode) -ne "unchanged" -or
        (Normalize-Mode $TrainerMoveMode) -ne "unchanged" -or
        (Normalize-Mode $TrainerItemMode) -ne "unchanged" -or
        (Normalize-Mode $TrainerAbilityMode) -ne "unchanged" -or
        (Normalize-Mode $TrainerIVMode) -ne "unchanged" -or
        (Normalize-Mode $TrainerEVMode) -ne "unchanged" -or
        (Get-EffectiveTrainerNatureMode -Mode $TrainerNatureMode -LegacyRandomize $RandomizeTrainerNatures.IsPresent) -ne "unchanged" -or
        $RandomizeTrainerNatures.IsPresent -or
        $TrainerLevelMultiplier -ne 1.0 -or
        $TrainerTeamMin -ge 0 -or
        $TrainerTeamMax -ge 0 -or
        $TrainerTypeThemed.IsPresent -or
        $TrainerShinyChancePercent -gt 0.0 -or
        $ForceTrainerFullyEvolved.IsPresent -or
        $MaxTrainerAI.IsPresent -or
        (Normalize-Mode $TrainerDynamaxLevelMode) -ne "unchanged" -or
        $ForceTrainerCanDynamax.IsPresent -or
        $ForceAllTeamsToSix.IsPresent -or
        $ForceBossTeamsToSix -or
        $StrictBossMaxLevelCap -or
        $MainStorySoftLevelCap -or
        $GymLeagueStoryLevelCap -or
        $StoryMajorBattleOrderLevelCap -or
        (($PatchStarterRelatedTrainers) -and (Get-ConfiguredStarterSpeciesIds))

    $needsPersonal = $true -or
        $needsTrainer -or
        (Normalize-Mode $TypeMode) -ne "unchanged" -or
        (Normalize-Mode $AbilityMode) -ne "unchanged" -or
        (Normalize-Mode $StatMode) -ne "unchanged" -or
        $ForceOneExpYield.IsPresent -or
        [Math]::Abs([double]$ExpYieldMultiplier - 1.0) -gt 0.0001 -or
        (Normalize-Mode $EvolutionMode) -ne "unchanged" -or
        (Normalize-Mode $GiftMode) -ne "unchanged" -or
        (Normalize-Mode $StarterMode) -ne "unchanged" -or
        (Normalize-Mode $TradeMode) -ne "unchanged" -or
        (Normalize-Mode $StaticEncounterMode) -ne "unchanged" -or
        (Normalize-Mode $GrassEncounterMode) -ne "unchanged" -or
        (Normalize-Mode $UndergroundMode) -ne "unchanged" -or
        (Get-ConfiguredStarterSpeciesIds)
    if ($needsPersonal) {
        $null = $files.Add("bin\pml\personal\personal_total.bin")
    }

    # La table des machines vit dans item.dat : sans copie, il n'y a rien a
    # reecrire dans la sortie.
    if ((Normalize-Mode $TmMoveMode) -ne "unchanged") {
        $null = $files.Add("bin\pml\item\item.dat")
    }

    if ((Normalize-Mode $LearnsetMoveMode) -ne "unchanged") {
        $null = $files.Add("bin\pml\waza_oboe\wazaoboe_total.bin")
    }

    # Un script non copie ne peut pas etre reecrit : on ajoute exactement les
    # modules que le catalogue designe, pas le dossier entier (953 fichiers).
    if ((Normalize-Mode $NpcGiftItemMode) -ne "unchanged") {
        foreach ($g in @(Get-NpcGiftCatalog)) {
            $null = $files.Add((Join-Path "bin\script\amx" $g.Amx))
        }
    }

    if ($needsTrainer) {
        $null = $dirs.Add("bin\trainer\trainer_data")
        $null = $dirs.Add("bin\trainer\trainer_poke")
    }

    $requiredTrainerMoveMode = Normalize-Mode $TrainerMoveMode
    $requiredSmogonMoveFallbackMode = Normalize-Mode $TrainerSmogonMoveFallbackMode
    if ($requiredTrainerMoveMode -eq "lastlevelup4" -or ((Test-TrainerModeUsesSmogon $requiredTrainerMoveMode) -and $requiredSmogonMoveFallbackMode -eq "lastlevelup4")) {
        $null = $files.Add("bin\pml\waza_oboe\wazaoboe_total.bin")
    }
    if ($requiredTrainerMoveMode -eq "random4" -or (Test-TrainerModeUsesSmogon $requiredTrainerMoveMode)) {
        $null = $dirs.Add("bin\pml\waza")
    }
    if ($RandomizeMoveTypes.IsPresent -or $RandomizeMovePower.IsPresent -or $RandomizeMovePP.IsPresent -or $RandomizeMoveAccuracy.IsPresent -or $RandomizeMoveCategory.IsPresent) {
        $null = $dirs.Add("bin\pml\waza")
    }

    if ($RandomizePickupItems.IsPresent) {
        $null = $files.Add("bin\appli\chika\data_table\underground_exploration_item.prmb")
    }

    if ($RandomizeShopItems.IsPresent -or $RandomizeTechnicalRecords.IsPresent) {
        $null = $files.Add("bin\appli\shop\bin\shop_data.bin")
        if ($RandomizePickupItems.IsPresent) {
            $null = $files.Add("bin\appli\chika\data_table\underground_exploration_item.prmb")
        }
    }

    # Le mode aleatoire reecrit les prix sans passer par le multiplicateur :
    # tester le seul multiplicateur laissait item.dat hors de la copie, et la
    # passe des prix ne trouvait plus son fichier.
    if ((Get-ShopPriceModeValue) -eq "random" -or (Get-ShopPriceMultiplierValue) -ne 1.0) {
        $null = $files.Add("bin\pml\item\item.dat")
    }

    if ($RandomizeFieldItems.IsPresent -or $RandomizeHiddenItems.IsPresent) {
        $null = $files.Add("bin\archive\field\resident\placement.gfpak")
        # La table de correspondance hachage <-> identifiant est indispensable
        # pour ecrire un objet dans le terrain.
        $null = $files.Add("bin\pml\item\item_hash_to_index.dat")
    }

    if ((Normalize-Mode $EvolutionMode) -ne "unchanged" -or $NormalizeFriendshipEvolutions -or $NormalizeTradeEvolutions -or $NormalizeSpecialEvolutions -or $ForceTrainerFullyEvolved.IsPresent) {
        $null = $dirs.Add("bin\pml\evolution")
    }

    if ((Normalize-Mode $GiftMode) -ne "unchanged" -or (Normalize-Mode $StarterMode) -ne "unchanged" -or (Get-ConfiguredStarterSpeciesIds)) {
        $null = $files.Add("bin\script_event_data\add_poke.bin")
    }

    if ((Normalize-Mode $TradeMode) -ne "unchanged") {
        $null = $files.Add("bin\script_event_data\field_trade.bin")
    }

    if ((Normalize-Mode $StaticEncounterMode) -ne "unchanged") {
        $null = $files.Add("bin\script_event_data\event_encount_data.bin")
    }

    if ((Normalize-Mode $GrassEncounterMode) -ne "unchanged" -or ([int]$WildLevelPercent -ne 0)) {
        $null = $files.Add("bin\archive\field\resident\data_table.gfpak")
    }

    if ((Normalize-Mode $UndergroundMode) -ne "unchanged") {
        $null = $files.Add("bin\appli\chika\data_table\underground_exploration_poke.bin")
    }

    return [pscustomobject]@{
        Files = @($files)
        Directories = @($dirs)
    }
}

function Assert-ValidSourceRomfsForRandomizer {
    param([string]$RomfsRoot)

    $missing = New-Object System.Collections.Generic.List[string]

    if (-not (Test-Path -LiteralPath (Join-Path $RomfsRoot "bin") -PathType Container)) {
        $missing.Add("bin\")
    }

    $assets = Get-RequiredRomfsAssets
    foreach ($relativeDir in @($assets.Directories)) {
        $path = Join-Path $RomfsRoot $relativeDir
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            $missing.Add($relativeDir + "\")
        }
    }

    foreach ($relativeFile in @($assets.Files)) {
        $path = Join-Path $RomfsRoot $relativeFile
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            $missing.Add($relativeFile)
            continue
        }
        $item = Get-Item -LiteralPath $path
        if ($item.Length -le 0) {
            $missing.Add($relativeFile + " (vide)")
        }
    }

    $personalPath = Join-Path $RomfsRoot "bin\pml\personal\personal_total.bin"
    if (Test-Path -LiteralPath $personalPath -PathType Leaf) {
        $personalSize = (Get-Item -LiteralPath $personalPath).Length
        if ($personalSize -lt ($PersonalRecordSize * 899) -or (($personalSize % $PersonalRecordSize) -ne 0)) {
            $minimumSize = $PersonalRecordSize * 899
            $missing.Add(("bin\pml\personal\personal_total.bin (taille {0} octets; attendu: au moins {1} octets et un multiple de {2})" -f $personalSize, $minimumSize, $PersonalRecordSize))
        }
    }

    $trainerDataDir = Join-Path $RomfsRoot "bin\trainer\trainer_data"
    $trainerPokeDir = Join-Path $RomfsRoot "bin\trainer\trainer_poke"
    if (Test-Path -LiteralPath $trainerDataDir -PathType Container) {
        $trainerDataCount = @(Get-ChildItem -LiteralPath $trainerDataDir -Filter "trainer_data_*.bin" -File -ErrorAction SilentlyContinue).Count
        if ($trainerDataCount -lt 300) {
            $missing.Add("bin\trainer\trainer_data (trop peu de fichiers trainer_data_*.bin)")
        }
    }
    if (Test-Path -LiteralPath $trainerPokeDir -PathType Container) {
        $trainerPokeCount = @(Get-ChildItem -LiteralPath $trainerPokeDir -Filter "trainer_poke_*.bin" -File -ErrorAction SilentlyContinue).Count
        if ($trainerPokeCount -lt 300) {
            $missing.Add("bin\trainer\trainer_poke (trop peu de fichiers trainer_poke_*.bin)")
        }
    }

    if ((Get-RandomizerPcMenuEnabled) -or [bool]$EarlyBike) {
        $scriptRecordPath = Join-Path $RomfsRoot "bin\script\param\script_id\script_id_record.bin"
        if (-not (Test-Path -LiteralPath $scriptRecordPath -PathType Leaf)) {
            $missing.Add("bin\script\param\script_id\script_id_record.bin")
        }
    }

    if ($missing.Count -gt 0) {
        $summary = ($missing.ToArray() | Select-Object -First 12) -join ", "
        if ($missing.Count -gt 12) {
            $summary += (" ... (+{0})" -f ($missing.Count - 12))
        }
        throw "ROMFS invalide ou incomplet: $summary. Sélectionne le dossier romfs original complet de ton dump Sword/Shield."
    }
}

function Sync-RequiredRomfsAssets {
    param(
        [string]$SourceRoot,
        [string]$OutputRoot
    )

    if ([IO.Path]::GetFullPath($SourceRoot).TrimEnd('\') -eq [IO.Path]::GetFullPath($OutputRoot).TrimEnd('\')) {
        return
    }

    Ensure-Directory -Path $OutputRoot
    $assets = Get-RequiredRomfsAssets
    foreach ($relativeDir in $assets.Directories) {
        Sync-SourceDirToOutput -SourceRoot $SourceRoot -OutputRoot $OutputRoot -RelativePath $relativeDir
    }
    foreach ($relativeFile in $assets.Files) {
        Sync-SourceFileToOutput -SourceRoot $SourceRoot -OutputRoot $OutputRoot -RelativePath $relativeFile
    }
}

function Write-RandomizerProgress {
    param(
        [string]$Message,
        [scriptblock]$ProgressCallback = $null
    )

    Write-Host $Message
    if ($ProgressCallback) {
        & $ProgressCallback $Message
    }
}

function Normalize-SearchKey {
    param([string]$Value)

    $text = ([string]$Value).Trim().ToLowerInvariant()
    $normalized = $text.Normalize([Text.NormalizationForm]::FormD)
    $builder = New-Object System.Text.StringBuilder
    foreach ($char in $normalized.ToCharArray()) {
        $category = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($char)
        if ($category -eq [Globalization.UnicodeCategory]::NonSpacingMark) {
            continue
        }

        if (($char -ge 'a' -and $char -le 'z') -or ($char -ge '0' -and $char -le '9')) {
            [void]$builder.Append($char)
        } else {
            [void]$builder.Append(' ')
        }
    }

    return (($builder.ToString() -replace '\s+', ' ').Trim())
}

function Convert-ToObjectArray {
    param([object]$Value)

    $items = New-Object System.Collections.Generic.List[object]
    if ($null -ne $Value) {
        if ($Value -is [System.Collections.IDictionary] -or
            $Value -is [string] -or
            -not ($Value -is [System.Collections.IEnumerable])) {
            $items.Add($Value)
        } else {
            foreach ($item in $Value) {
                if ($null -ne $item) {
                    $items.Add($item)
                }
            }
        }
    }

    return [object[]]$items.ToArray()
}

function Get-ObjectArrayCount {
    param([object]$Value)

    if ($null -eq $Value) {
        return 0
    }
    if ($Value -is [System.Array]) {
        return $Value.Length
    }
    if ($Value -is [System.Collections.ICollection] -and
        -not ($Value -is [System.Collections.IDictionary]) -and
        -not ($Value -is [string])) {
        return $Value.Count
    }
    return (Convert-ToObjectArray $Value | Measure-Object).Count
}

function Find-DataFile {
    param([string]$RelativePath)

    foreach ($root in $DataRootCandidates) {
        if (-not $root) {
            continue
        }

        $candidate = Join-Path $root $RelativePath
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return $null
}

function Get-PythonCommand {
    <#
        Cherche un interpreteur Python 3 utilisable.

        On teste dans l'ordre : le lanceur Windows "py -3", puis "python", puis
        "python3". Chaque candidat est VALIDE en lui demandant sa version : sur
        Windows, "python3" est tres souvent un leurre du Microsoft Store qui
        ouvre une page au lieu de s'executer, et le detecter avec Get-Command
        seul suffirait a le prendre pour un interpreteur.

        Renvoie $null si rien d'utilisable.
    #>
    if ($script:PythonCommandProbed) {
        return $script:PythonCommand
    }
    $script:PythonCommandProbed = $true

    foreach ($candidat in @(
        [pscustomobject]@{ Exe = "py"; Prefix = @("-3") },
        [pscustomobject]@{ Exe = "python"; Prefix = @() },
        [pscustomobject]@{ Exe = "python3"; Prefix = @() }
    )) {
        $commande = Get-Command $candidat.Exe -ErrorAction SilentlyContinue
        if (-not $commande) {
            continue
        }
        try {
            $arguments = @($candidat.Prefix) + @("--version")
            $version = & $commande.Source @arguments 2>&1 | Select-Object -First 1
            if ("$version" -match "Python\s+3\.") {
                $script:PythonCommand = [pscustomobject]@{
                    Exe = $commande.Source
                    Prefix = @($candidat.Prefix)
                    Version = ("$version").Trim()
                }
                return $script:PythonCommand
            }
        } catch {
        }
    }

    return $null
}

function Restore-DataFilesFromDump {
    <#
        Reconstruit depuis le dump de l'utilisateur les tables que le depot ne
        redistribue pas.

        Ces fichiers sont DERIVES DU JEU : les versionner reviendrait a
        redistribuer du contenu Nintendo. Mais sans eux le logiciel est ampute
        - sans items.csv notamment, le reglage du pool d'objets tenus n'a plus
        aucun effet. La sortie propre est donc de les fabriquer ici, chez
        l'utilisateur, depuis SA copie.

        Les outils sont ceux de tools/, deja ecrits et deja mesures. On ne
        lance que ceux dont un fichier manque, et on n'echoue jamais : sans
        Python, la generation continue en mode degrade et Assert-DataFilesAvailable
        dira exactement ce qui manque.
    #>
    param(
        [string]$RomfsRoot,
        [scriptblock]$ProgressCallback = $null
    )

    $manquants = @(Get-DataFileDiagnostics | Where-Object { -not $_.Present } | ForEach-Object { [string]$_.RelativePath })
    if ($manquants.Count -lt 1) {
        return
    }

    # Chaque outil et les fichiers qu'il produit. vanilla_exports n'a PAS
    # d'outil : ces deux JSON ne se regenerent pas, et leur absence laisse les
    # dresseurs anonymes dans les rapports.
    $outils = @(
        [pscustomobject]@{ Script = "build-name-tables.py"; Romfs = $true;  Produit = @("pokemon_species_names.csv", "item_names.csv", "move_names.csv", "ability_names.csv") },
        [pscustomobject]@{ Script = "build-items-csv.py";   Romfs = $true;  Produit = @("items.csv") },
        [pscustomobject]@{ Script = "build-npc-gifts.py";   Romfs = $true;  Produit = @("npc-gifts.csv") },
        # Celui-ci ne lit PAS le dump : il croise le dex du visualiseur avec
        # item_names.csv, donc il passe en dernier, une fois ce CSV ecrit.
        [pscustomobject]@{ Script = "build-item-id-map.py"; Romfs = $false; Produit = @("item-id-map.csv") }
    )

    $aFaire = @($outils | Where-Object {
        $courant = $_
        @($courant.Produit | Where-Object { $manquants -contains $_ }).Count -gt 0
    })
    if ($aFaire.Count -lt 1) {
        return
    }

    $python = Get-PythonCommand
    if (-not $python) {
        Write-RandomizerProgress -Message ("[Donnees] {0} fichier(s) manquant(s) et aucun Python 3 trouve. Installe Python 3 (python.org) puis relance : les tables se construiront toutes seules depuis ton dump." -f $manquants.Count) -ProgressCallback $ProgressCallback
        return
    }

    Write-RandomizerProgress -Message ("[Donnees] {0} fichier(s) manquant(s), reconstruction depuis le dump avec {1}" -f $manquants.Count, $python.Version) -ProgressCallback $ProgressCallback

    foreach ($outil in $aFaire) {
        $chemin = Join-Path $PSScriptRoot (Join-Path "tools" $outil.Script)
        if (-not (Test-Path -LiteralPath $chemin)) {
            Write-RandomizerProgress -Message ("[Donnees] outil introuvable : {0}" -f $outil.Script) -ProgressCallback $ProgressCallback
            continue
        }
        try {
            $arguments = if ($outil.Romfs) { @($python.Prefix) + @($chemin, $RomfsRoot) } else { @($python.Prefix) + @($chemin) }
            $sortie = & $python.Exe @arguments 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-RandomizerProgress -Message ("[Donnees] {0} : ok" -f $outil.Script) -ProgressCallback $ProgressCallback
            } else {
                $derniere = @($sortie | Select-Object -Last 1) -join " "
                Write-RandomizerProgress -Message ("[Donnees] {0} a echoue ({1}) : {2}" -f $outil.Script, $LASTEXITCODE, $derniere) -ProgressCallback $ProgressCallback
            }
        } catch {
            Write-RandomizerProgress -Message ("[Donnees] {0} a echoue : {1}" -f $outil.Script, $_.Exception.Message) -ProgressCallback $ProgressCallback
        }
    }
}

function Get-DataFileDiagnostics {
    <#
      Confronte le manifeste au disque. Ne lit aucun fichier, ne modifie rien :
      c'est une mesure, pas une correction.
    #>
    $entries = @()
    foreach ($declared in $DataFileManifest) {
        $resolved = Find-DataFile -RelativePath $declared.RelativePath
        $entries += [pscustomobject]@{
            RelativePath = $declared.RelativePath
            Purpose = $declared.Purpose
            Degradation = $declared.Degradation
            Severity = $declared.Severity
            Present = [bool]$resolved
            ResolvedPath = if ($resolved) { $resolved } else { "" }
        }
    }
    return $entries
}

function Assert-DataFilesAvailable {
    <#
      Signale bruyamment ce qui manque. Avec -StrictDataFiles, echoue au lieu
      de degrader en silence. Renvoie le diagnostic pour que les rapports
      puissent le consigner.
    #>
    param([scriptblock]$ProgressCallback = $null)

    $diagnostics = @(Get-DataFileDiagnostics)
    $missing = @($diagnostics | Where-Object { -not $_.Present })
    if ($missing.Count -eq 0) {
        return $diagnostics
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add(("[Données] {0} fichier(s) de données sur {1} absent(s) : la génération va être degradee." -f $missing.Count, $diagnostics.Count))
    foreach ($entry in $missing) {
        $lines.Add(("[Donnees]   - {0} (gravite {1}) : {2}" -f $entry.RelativePath, $entry.Severity, $entry.Degradation))
    }
    $lines.Add(("[Donnees] Racines cherchees : {0}" -f (@($DataRootCandidates | Where-Object { $_ }) -join ", ")))

    if ($StrictDataFiles.IsPresent) {
        throw (($lines -join [Environment]::NewLine) + [Environment]::NewLine +
               "Arrêt demande par -StrictDataFiles. Restaure les fichiers ou relance sans ce commutateur.")
    }

    foreach ($line in $lines) {
        Write-RandomizerProgress -Message $line -ProgressCallback $ProgressCallback
    }
    Write-RandomizerProgress -Message "[Données] Relance avec -StrictDataFiles pour transformer cet avertissement en erreur." -ProgressCallback $ProgressCallback

    return $diagnostics
}

function Get-DynamicPropertyValue {
    param(
        [object]$Object,
        [string]$Name,
        [object]$DefaultValue = $null
    )

    if ($null -eq $Object -or [string]::IsNullOrWhiteSpace($Name)) {
        return $DefaultValue
    }

    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) {
            return $Object[$Name]
        }
        if (($Object.PSObject.Methods.Name -contains "ContainsKey") -and $Object.ContainsKey($Name)) {
            return $Object[$Name]
        }
        return $DefaultValue
    }

    $property = $Object.PSObject.Properties[$Name]
    if ($property) {
        return $property.Value
    }

    return $DefaultValue
}

function Get-SmogonStrategicCachePath {
    return (Join-Path $PSScriptRoot (Join-Path "cache" "smogon-strategic-gen8.json"))
}

function Get-SmogonRecommendationsCachePath {
    return (Join-Path $PSScriptRoot (Join-Path "cache" "smogon-showdown-swsh-recommendations.json"))
}

function Get-SmogonStrategicLegacyCachePath {
    return (Join-Path $PSScriptRoot (Join-Path "cache" "smogon-strategic-latest-history.json"))
}

function Get-SmogonLegacyRecommendationsCachePath {
    return (Join-Path $PSScriptRoot (Join-Path "cache" "smogon-showdown-latest-history-recommendations.json"))
}

function Get-SmogonNameKey {
    param([string]$Name)

    $key = Normalize-SearchKey -Value $Name
    if (-not $key) {
        return ""
    }
    return ($key -replace " ", "")
}

function Get-RemoteTextSafely {
    param([string]$Url)

    try {
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        } catch {
            # Older PowerShell hosts can ignore this; Invoke-WebRequest will still try its default.
        }
        $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 30
        return [string]$response.Content
    } catch {
        throw ("Impossible de télécharger {0}: {1}" -f $Url, $_.Exception.Message)
    }
}

function Get-ShowdownNumericIndex {
    param([string]$Text)

    $index = @{}
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $index
    }

    foreach ($match in [regex]::Matches($Text, "([A-Za-z0-9]+):\{")) {
        $key = ([string]$match.Groups[1].Value).ToLowerInvariant()
        if ($index.ContainsKey($key)) {
            continue
        }

        $start = [int]$match.Index
        $length = [Math]::Min(2200, $Text.Length - $start)
        if ($length -le 0) {
            continue
        }

        $snippet = $Text.Substring($start, $length)
        $numMatch = [regex]::Match($snippet, "(^|[,\{\s])num:(-?\d+)")
        if (-not $numMatch.Success) {
            continue
        }

        $num = [int]$numMatch.Groups[2].Value
        if ($num -gt 0) {
            $index[$key] = $num
        }
    }

    return $index
}

function Add-SmogonNameValue {
    param(
        [object]$Value,
        [System.Collections.Generic.HashSet[string]]$Names
    )

    if ($null -eq $Value -or $null -eq $Names) {
        return
    }

    if ($Value -is [string]) {
        $text = ([string]$Value).Trim()
        if ($text.Length -gt 0) {
            $null = $Names.Add($text)
        }
        return
    }

    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [System.Collections.IDictionary])) {
        foreach ($item in $Value) {
            Add-SmogonNameValue -Value $item -Names $Names
        }
    }
}

function Add-SmogonSetDataRecursive {
    param(
        [object]$Node,
        [hashtable]$Aggregate
    )

    if ($null -eq $Node -or $Node -is [string] -or $null -eq $Aggregate) {
        return
    }

    $properties = @($Node.PSObject.Properties)
    if ((Get-ObjectArrayCount $properties) -lt 1) {
        return
    }

    $moveProperty = $Node.PSObject.Properties["moves"]
    if ($moveProperty) {
        Add-SmogonNameValue -Value $moveProperty.Value -Names $Aggregate.MoveNames
    }

    $itemProperty = $Node.PSObject.Properties["item"]
    if ($itemProperty) {
        Add-SmogonNameValue -Value $itemProperty.Value -Names $Aggregate.ItemNames
    }

    $abilityProperty = $Node.PSObject.Properties["ability"]
    if ($abilityProperty) {
        Add-SmogonNameValue -Value $abilityProperty.Value -Names $Aggregate.AbilityNames
    }

    $natureProperty = $Node.PSObject.Properties["nature"]
    if ($natureProperty -and $Aggregate.ContainsKey("NatureNames")) {
        Add-SmogonNameValue -Value $natureProperty.Value -Names $Aggregate.NatureNames
    }

    foreach ($property in $properties) {
        if ($property.Name -in @("moves", "item", "ability", "nature", "evs", "ivs")) {
            continue
        }
        Add-SmogonSetDataRecursive -Node $property.Value -Aggregate $Aggregate
    }
}

function Convert-SmogonNamesToIds {
    param(
        [System.Collections.Generic.HashSet[string]]$Names,
        [hashtable]$Index
    )

    $ids = New-Object System.Collections.Generic.HashSet[int]
    if ($null -eq $Names -or $null -eq $Index) {
        return [int[]]@()
    }

    foreach ($name in $Names) {
        $key = Get-SmogonNameKey -Name ([string]$name)
        if ($key -and $Index.ContainsKey($key)) {
            $null = $ids.Add([int]$Index[$key])
        }
    }

    return [int[]]@($ids | Sort-Object)
}

function Convert-SmogonNameValueToIds {
    param(
        [object]$Value,
        [hashtable]$Index
    )

    $ids = [System.Collections.Generic.HashSet[int]]::new()
    if ($null -eq $Value -or $null -eq $Index) {
        return [int[]]@()
    }

    $addValue = {
        param([object]$InnerValue)

        if ($null -eq $InnerValue) {
            return
        }
        if ($InnerValue -is [string]) {
            $key = Get-SmogonNameKey -Name ([string]$InnerValue)
            if ($key -and $Index.ContainsKey($key)) {
                $null = $ids.Add([int]$Index[$key])
            }
            return
        }
        if ($InnerValue -is [System.Collections.IEnumerable] -and -not ($InnerValue -is [System.Collections.IDictionary])) {
            foreach ($item in $InnerValue) {
                & $addValue $item
            }
        }
    }

    & $addValue $Value
    return [int[]]@($ids | Sort-Object)
}

function Convert-SmogonMoveChoicesToIdGroups {
    param(
        [object]$MovesValue,
        [hashtable]$MoveIndex
    )

    $groups = New-Object System.Collections.Generic.List[object]
    foreach ($moveChoice in @($MovesValue)) {
        $ids = Convert-SmogonNameValueToIds -Value $moveChoice -Index $MoveIndex
        if ((Get-ObjectArrayCount $ids) -gt 0) {
            $groups.Add([int[]]$ids)
        }
    }

    return [object[]]$groups.ToArray()
}

function Convert-SmogonEvsToSpread {
    param([object]$EvsValue)

    if ($null -eq $EvsValue) {
        return $null
    }

    $statKeys = @("hp", "atk", "def", "spa", "spd", "spe")
    $values = @(0, 0, 0, 0, 0, 0)
    for ($i = 0; $i -lt $statKeys.Count; $i++) {
        $raw = Get-DynamicPropertyValue -Object $EvsValue -Name $statKeys[$i] -DefaultValue 0
        $value = 0
        if ($null -ne $raw -and [int]::TryParse(([string]$raw), [ref]$value)) {
            if ($value -lt 0) { $value = 0 }
            if ($value -gt 252) { $value = 252 }
            $values[$i] = $value
        }
    }

    $total = [int](($values | Measure-Object -Sum).Sum)
    if ($total -le 0) {
        return $null
    }
    if ($total -le 510) {
        return [int[]]$values
    }

    $scaled = @(0, 0, 0, 0, 0, 0)
    $remainders = New-Object System.Collections.Generic.List[object]
    $scaledTotal = 0
    for ($i = 0; $i -lt $values.Count; $i++) {
        $rawScaled = ([double]$values[$i] * 510.0) / [double]$total
        $floorValue = [int][Math]::Floor($rawScaled)
        if ($floorValue -gt 252) { $floorValue = 252 }
        $scaled[$i] = $floorValue
        $scaledTotal += $floorValue
        $remainders.Add([pscustomobject]@{
            Index = $i
            Remainder = ($rawScaled - [Math]::Floor($rawScaled))
        })
    }

    $remaining = 510 - $scaledTotal
    while ($remaining -gt 0) {
        $changed = $false
        foreach ($entry in @($remainders | Sort-Object Remainder -Descending)) {
            $index = [int]$entry.Index
            if ($scaled[$index] -lt 252) {
                $scaled[$index]++
                $remaining--
                $changed = $true
                if ($remaining -le 0) {
                    break
                }
            }
        }
        if (-not $changed) {
            break
        }
    }

    return [int[]]$scaled
}

function Add-SmogonSetObjectsRecursive {
    param(
        [object]$Node,
        [string[]]$Path,
        [hashtable]$Indexes,
        [System.Collections.Generic.List[object]]$Sets
    )

    if ($null -eq $Node -or $Node -is [string] -or $null -eq $Indexes -or $null -eq $Sets) {
        return
    }

    $properties = @($Node.PSObject.Properties)
    if ((Get-ObjectArrayCount $properties) -lt 1) {
        return
    }

    $moveProperty = $Node.PSObject.Properties["moves"]
    $itemProperty = $Node.PSObject.Properties["item"]
    $abilityProperty = $Node.PSObject.Properties["ability"]
    $natureProperty = $Node.PSObject.Properties["nature"]
    $evsProperty = $Node.PSObject.Properties["evs"]

    if ($moveProperty -or $itemProperty -or $abilityProperty -or $natureProperty -or $evsProperty) {
        $moveChoices = if ($moveProperty) { Convert-SmogonMoveChoicesToIdGroups -MovesValue $moveProperty.Value -MoveIndex $Indexes.Moves } else { [object[]]@() }
        $itemIds = if ($itemProperty) { Convert-SmogonNameValueToIds -Value $itemProperty.Value -Index $Indexes.Items } else { [int[]]@() }
        $abilityIds = if ($abilityProperty) { Convert-SmogonNameValueToIds -Value $abilityProperty.Value -Index $Indexes.Abilities } else { [int[]]@() }
        $natureIds = if ($natureProperty) { Convert-SmogonNameValueToIds -Value $natureProperty.Value -Index $Indexes.Natures } else { [int[]]@() }
        $evSpread = if ($evsProperty) { Convert-SmogonEvsToSpread -EvsValue $evsProperty.Value } else { $null }

        if ((Get-ObjectArrayCount $moveChoices) -gt 0 -or (Get-ObjectArrayCount $itemIds) -gt 0 -or (Get-ObjectArrayCount $abilityIds) -gt 0 -or (Get-ObjectArrayCount $natureIds) -gt 0 -or $null -ne $evSpread) {
            $Sets.Add([ordered]@{
                name = if ((Get-ObjectArrayCount $Path) -gt 0) { ($Path -join " / ") } else { "Set" }
                moveChoices = [object[]]$moveChoices
                items = [int[]]$itemIds
                abilities = [int[]]$abilityIds
                natures = [int[]]$natureIds
                evs = if ($null -ne $evSpread) { [int[]]$evSpread } else { [int[]]@() }
            })
        }
    }

    foreach ($property in $properties) {
        if ($property.Name -in @("moves", "item", "ability", "nature", "evs", "ivs")) {
            continue
        }
        Add-SmogonSetObjectsRecursive -Node $property.Value -Path ([string[]]@($Path + [string]$property.Name)) -Indexes $Indexes -Sets $Sets
    }
}

function New-SmogonStrategicDataFromWeb {
    $builderPath = Join-Path $PSScriptRoot (Join-Path "tools" "build-smogon-dex-cache.js")
    if (-not (Test-Path -LiteralPath $builderPath)) {
        throw "Generateur Smogon Strategy Dex absent: $builderPath"
    }

    $nodeCommand = Get-Command node -ErrorAction SilentlyContinue
    if (-not $nodeCommand) {
        throw "Node.js est requis pour reconstruire le cache Smogon depuis les pages Strategy Dex."
    }

    $strategicPath = Get-SmogonStrategicCachePath
    $recommendationsPath = Get-SmogonRecommendationsCachePath
    $legacyStrategicPath = Get-SmogonStrategicLegacyCachePath
    $legacyRecommendationsPath = Get-SmogonLegacyRecommendationsCachePath
    $arguments = @(
        $builderPath,
        "--repo-root", $PSScriptRoot,
        "--strategic-out", $strategicPath,
        "--recommendations-out", $recommendationsPath,
        "--legacy-strategic-out", $legacyStrategicPath,
        "--legacy-recommendations-out", $legacyRecommendationsPath
    )

    $builderOutput = & $nodeCommand.Source @arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ("Generation Smogon Strategy Dex echouee: {0}" -f (($builderOutput | Out-String).Trim()))
    }

    if (-not (Test-Path -LiteralPath $strategicPath)) {
        throw "Le générateur Smogon n'a pas produit le cache attendu: $strategicPath"
    }
    if (-not (Test-Path -LiteralPath $legacyStrategicPath)) {
        throw "Le générateur Smogon n'a pas produit le cache historique attendu: $legacyStrategicPath"
    }

    return (Get-Content -LiteralPath $strategicPath -Raw | ConvertFrom-Json)
}

function Get-SmogonStrategicData {
    if ($script:SmogonStrategicData) {
        return $script:SmogonStrategicData
    }

    $cachePath = Get-SmogonStrategicCachePath
    if (Test-Path -LiteralPath $cachePath) {
        try {
            $cachedData = Get-Content -LiteralPath $cachePath -Raw | ConvertFrom-Json
            $cacheVersion = [int](Get-DynamicPropertyValue -Object $cachedData -Name "version" -DefaultValue 0)
            if ($cacheVersion -ge 6) {
                $script:SmogonStrategicData = $cachedData
                return $script:SmogonStrategicData
            }
            Write-Warning "Cache Smogon ancien détecté, régénération depuis les pages Strategy Dex Sword/Shield."
        } catch {
            Write-Warning ("Cache Smogon illisible, nouveau telechargement tente: {0}" -f $_.Exception.Message)
        }
    }

    try {
        $data = New-SmogonStrategicDataFromWeb
        $cacheDir = Split-Path -Parent $cachePath
        if (-not (Test-Path -LiteralPath $cacheDir)) {
            $null = New-Item -ItemType Directory -Path $cacheDir -Force
        }
        Write-JsonFile -Value $data -Path $cachePath -Depth 12
        $script:SmogonStrategicData = Get-Content -LiteralPath $cachePath -Raw | ConvertFrom-Json
    } catch {
        Write-Warning ("Données strategiques Smogon indisponibles, les fallbacks seront utilises: {0}" -f $_.Exception.Message)
        $script:SmogonStrategicData = [pscustomobject]@{
            version = 1
            unavailable = $true
            error = $_.Exception.Message
            species = [pscustomobject]@{}
        }
    }

    return $script:SmogonStrategicData
}

function Get-SmogonStrategicLegacyData {
    if ($script:SmogonStrategicLegacyData) {
        return $script:SmogonStrategicLegacyData
    }

    $cachePath = Get-SmogonStrategicLegacyCachePath
    if (Test-Path -LiteralPath $cachePath) {
        try {
            $cachedData = Get-Content -LiteralPath $cachePath -Raw | ConvertFrom-Json
            $cacheVersion = [int](Get-DynamicPropertyValue -Object $cachedData -Name "version" -DefaultValue 0)
            if ($cacheVersion -ge 6) {
                $script:SmogonStrategicLegacyData = $cachedData
                return $script:SmogonStrategicLegacyData
            }
            Write-Warning "Cache Smogon historique ancien détecté, régénération depuis les pages Strategy Dex."
        } catch {
            Write-Warning ("Cache Smogon historique illisible, nouveau telechargement tente: {0}" -f $_.Exception.Message)
        }
    }

    try {
        $null = New-SmogonStrategicDataFromWeb
        if (Test-Path -LiteralPath $cachePath) {
            $script:SmogonStrategicLegacyData = Get-Content -LiteralPath $cachePath -Raw | ConvertFrom-Json
        } else {
            throw "Cache historique absent apres generation: $cachePath"
        }
    } catch {
        Write-Warning ("Données strategiques Smogon historiques indisponibles, les fallbacks seront utilises: {0}" -f $_.Exception.Message)
        $script:SmogonStrategicLegacyData = [pscustomobject]@{
            version = 1
            unavailable = $true
            error = $_.Exception.Message
            species = [pscustomobject]@{}
        }
    }

    return $script:SmogonStrategicLegacyData
}

function Get-SmogonStrategicEntry {
    param(
        [object]$Data,
        [int]$SpeciesId
    )

    if ($null -eq $Data -or $SpeciesId -le 0) {
        return $null
    }

    $species = Get-DynamicPropertyValue -Object $Data -Name "species"
    if ($null -eq $species) {
        return $null
    }

    return Get-DynamicPropertyValue -Object $species -Name ([string]$SpeciesId)
}

function Convert-ToIntArraySafe {
    param([object]$Value)

    $items = New-Object System.Collections.Generic.List[int]
    $addValue = {
        param([object]$InnerValue)

        if ($null -eq $InnerValue) {
            return
        }
        if ($InnerValue -is [string]) {
            $parsed = 0
            if ([int]::TryParse(([string]$InnerValue), [ref]$parsed)) {
                $items.Add($parsed)
            }
            return
        }
        if ($InnerValue -is [System.Collections.IEnumerable] -and -not ($InnerValue -is [System.Collections.IDictionary])) {
            foreach ($nested in $InnerValue) {
                & $addValue $nested
            }
            return
        }
        try {
            $items.Add([int]$InnerValue)
        } catch {
            return
        }
    }

    & $addValue $Value
    return [int[]]$items.ToArray()
}

function Get-SmogonStrategicSets {
    param(
        [object]$SmogonData,
        [int]$SpeciesId
    )

    $entry = Get-SmogonStrategicEntry -Data $SmogonData -SpeciesId $SpeciesId
    if (-not $entry) {
        return [object[]]@()
    }

    $sets = Get-DynamicPropertyValue -Object $entry -Name "sets" -DefaultValue @()
    return [object[]]@(Convert-ToObjectArray $sets)
}

function Get-SmogonStrategicSet {
    param(
        [object]$SmogonData,
        [int]$SpeciesId,
        [System.Random]$Rng,
        $PersonalEntries = $null,
        [switch]$RequireLegalAbility
    )

    $sets = @(Get-SmogonStrategicSets -SmogonData $SmogonData -SpeciesId $SpeciesId)
    if ((Get-ObjectArrayCount $sets) -lt 1) {
        return $null
    }

    if ($RequireLegalAbility.IsPresent -and $null -ne $PersonalEntries) {
        $legalAbilitySets = @($sets | Where-Object { Test-SmogonStrategicSetAbilityLegal -StrategicSet $_ -SpeciesId $SpeciesId -PersonalEntries $PersonalEntries })
        if ((Get-ObjectArrayCount $legalAbilitySets) -gt 0) {
            $sets = $legalAbilitySets
        }
    }

    return $sets[$Rng.Next(0, $sets.Count)]
}

function Test-SmogonStrategicSetAbilityLegal {
    param(
        [object]$StrategicSet,
        [int]$SpeciesId,
        $PersonalEntries
    )

    if ($null -eq $StrategicSet -or $null -eq $PersonalEntries -or $SpeciesId -le 0 -or $SpeciesId -ge $PersonalEntries.Count) {
        return $true
    }

    $abilities = @(Get-SmogonStrategicSetAbilities -StrategicSet $StrategicSet)
    if ((Get-ObjectArrayCount $abilities) -lt 1) {
        return $true
    }

    $personal = $PersonalEntries[$SpeciesId]
    if (-not $personal) {
        return $true
    }

    foreach ($ability in $abilities) {
        $abilityId = [int]$ability
        if ($abilityId -le 0) {
            continue
        }
        if ([int]$personal.Ability1 -eq $abilityId -or [int]$personal.Ability2 -eq $abilityId -or [int]$personal.AbilityH -eq $abilityId) {
            return $true
        }
    }

    return $false
}

function Get-SmogonStrategicSpeciesIdSet {
    param(
        [object]$SmogonData,
        $PersonalEntries = $null,
        [switch]$RequireLegalAbility
    )

    $result = [System.Collections.Generic.HashSet[int]]::new()
    if ($null -eq $SmogonData) {
        return $result
    }

    $speciesContainer = Get-DynamicPropertyValue -Object $SmogonData -Name "species" -DefaultValue $null
    if ($null -eq $speciesContainer) {
        return $result
    }

    foreach ($property in @($speciesContainer.PSObject.Properties)) {
        $speciesId = 0
        if (-not [int]::TryParse(([string]$property.Name), [ref]$speciesId)) {
            continue
        }
        if ($speciesId -le 0 -or $speciesId -gt $BaseSpeciesMax) {
            continue
        }

        $sets = @(Convert-ToObjectArray (Get-DynamicPropertyValue -Object $property.Value -Name "sets" -DefaultValue @()))
        if ((Get-ObjectArrayCount $sets) -lt 1) {
            continue
        }

        if ($RequireLegalAbility.IsPresent -and $null -ne $PersonalEntries) {
            $hasLegalAbilitySet = $false
            foreach ($set in $sets) {
                if (Test-SmogonStrategicSetAbilityLegal -StrategicSet $set -SpeciesId $speciesId -PersonalEntries $PersonalEntries) {
                    $hasLegalAbilitySet = $true
                    break
                }
            }
            if (-not $hasLegalAbilitySet) {
                continue
            }
        }

        $null = $result.Add($speciesId)
    }

    return $result
}

function Add-SmogonSetMoveChoices {
    param(
        [System.Collections.Generic.List[int]]$Target,
        [object]$StrategicSet,
        [System.Random]$Rng,
        [System.Collections.Generic.HashSet[int]]$AllowedMoveIds = $null
    )

    if ($null -eq $Target -or $null -eq $StrategicSet) {
        return
    }

    $moveChoices = Convert-ToObjectArray (Get-DynamicPropertyValue -Object $StrategicSet -Name "moveChoices" -DefaultValue @())
    foreach ($choice in @($moveChoices)) {
        $candidateIds = Convert-ToIntArraySafe -Value $choice
        $candidateIds = @($candidateIds | Where-Object {
            [int]$_ -gt 0 -and (-not $AllowedMoveIds -or $AllowedMoveIds.Count -lt 1 -or $AllowedMoveIds.Contains([int]$_))
        } | Select-Object -Unique)
        if ($candidateIds.Count -lt 1) {
            continue
        }

        $selectedMoveId = [int](Random-FromPool -Rng $Rng -Pool ([int[]]$candidateIds))
        if (-not $Target.Contains($selectedMoveId)) {
            $Target.Add($selectedMoveId)
        }
        if ($Target.Count -ge 4) {
            return
        }
    }
}

function Get-SmogonItemIdMap {
    <#
        Traduit les identifiants d'objets du cache Smogon vers ceux du JEU.

        Le cache resout ses noms d'objets via le dex du visualiseur (voir
        tools/build-smogon-dex-cache.js ligne 267), dont la numerotation N'EST
        PAS celle du jeu. Mesure par comparaison des noms anglais :

            attaques : 808/808 identifiants portent le meme nom  (100 %)
            talents  : 267/267                                    (100 %)
            objets   : 116/1556                                   (  7 %)

        Les attaques et les talents concordent, les objets non. Sans cette
        table, le Kabuto cense tenir un Eviolite recevait l'objet 581 du jeu,
        qui est tout autre chose - et le controle d'existence ne pouvait pas le
        voir, puisque 581 existe. Sur les 157 objets du cache, UN SEUL portait
        deja le bon identifiant.

        La table est produite par tools/build-item-id-map.py, qui refuse de
        l'ecrire si ses temoins ne tombent pas.
    #>
    if ($null -ne $script:SmogonItemIdMap) {
        return $script:SmogonItemIdMap
    }
    $table = @{}
    $path = Find-DataFile -RelativePath "item-id-map.csv"
    if ($path) {
        foreach ($r in (Import-Csv -LiteralPath $path -Encoding UTF8)) {
            $table[[int]$r.dex_item_id] = [int]$r.game_item_id
        }
    }
    $script:SmogonItemIdMap = $table
    return $table
}

function Get-SmogonStrategicSetItems {
    param([object]$StrategicSet)

    if ($null -eq $StrategicSet) {
        return [int[]]@()
    }
    $bruts = [int[]](Convert-ToIntArraySafe -Value (Get-DynamicPropertyValue -Object $StrategicSet -Name "items" -DefaultValue @()))
    $table = Get-SmogonItemIdMap
    if ($table.Count -eq 0) {
        # Sans la table, mieux vaut ne RIEN proposer que de proposer le mauvais
        # objet : l'appelant se rabat alors sur le pool general, qui lui est
        # exprime dans les identifiants du jeu.
        return [int[]]@()
    }
    return [int[]]@($bruts | ForEach-Object { if ($table.ContainsKey([int]$_)) { $table[[int]$_] } } | Where-Object { $_ })
}

function Get-SmogonStrategicSetAbilities {
    param([object]$StrategicSet)

    if ($null -eq $StrategicSet) {
        return [int[]]@()
    }
    return [int[]](Convert-ToIntArraySafe -Value (Get-DynamicPropertyValue -Object $StrategicSet -Name "abilities" -DefaultValue @()))
}

function Get-SmogonStrategicSetNatures {
    param([object]$StrategicSet)

    if ($null -eq $StrategicSet) {
        return [int[]]@()
    }
    return [int[]](Convert-ToIntArraySafe -Value (Get-DynamicPropertyValue -Object $StrategicSet -Name "natures" -DefaultValue @()))
}

function Get-SmogonStrategicSetEvs {
    param([object]$StrategicSet)

    if ($null -eq $StrategicSet) {
        return [int[]]@()
    }
    return [int[]](Convert-ToIntArraySafe -Value (Get-DynamicPropertyValue -Object $StrategicSet -Name "evs" -DefaultValue @()))
}

function Get-SpeciesNameData {
    if ($script:SpeciesNameData) {
        return $script:SpeciesNameData
    }

    $path = Find-DataFile -RelativePath "pokemon_species_names.csv"
    if (-not $path) {
        $script:SpeciesNameData = @{
            ById = @{}
            ByKey = @{}
        }
        return $script:SpeciesNameData
    }

    $byId = @{}
    $byKey = @{}
    foreach ($row in Import-Csv -LiteralPath $path -Encoding UTF8) {
        $speciesId = [int]$row.pokemon_species_id
        $languageId = [int]$row.local_language_id
        if ($languageId -ne $FrenchLanguageId -and $languageId -ne $EnglishLanguageId) {
            continue
        }

        if (-not $byId.ContainsKey($speciesId)) {
            $byId[$speciesId] = @{
                fr = ""
                en = ""
            }
        }

        $slot = if ($languageId -eq $FrenchLanguageId) { "fr" } else { "en" }
        $name = [string]$row.name
        $byId[$speciesId][$slot] = $name

        $key = Normalize-SearchKey -Value $name
        if ($key) {
            if (-not $byKey.ContainsKey($key)) {
                $byKey[$key] = New-Object System.Collections.Generic.List[int]
            }
            if (-not $byKey[$key].Contains($speciesId)) {
                $byKey[$key].Add($speciesId)
            }
        }
    }

    $script:SpeciesNameData = @{
        ById = $byId
        ByKey = $byKey
    }
    return $script:SpeciesNameData
}

function Get-ExistingItemIds {
    <#
        Les identifiants d'objet qui existent REELLEMENT dans cette version.

        Mesure du 2026-09-06 sur le dump Epee 1.3.2 : sur les 1607 identifiants
        possibles, 964 seulement portent un enregistrement ; les 643 autres
        pointent sur l'enregistrement 0, c'est-a-dire « cet objet n'est pas dans
        ce jeu ». Ce sont des objets d'autres generations.

        Ce que ca a permis de trouver, en confrontant les listes codees en dur :

          liste des objets tenus  : 45 des 139 n'existent pas (32 %)
          pool objets au sol      : 35 des 454 n'existent pas (7 %)
          pool CT/DT              : 0 sur 200 - celui-la etait deja derive du jeu

        Un identifiant fantome ecrit dans un fichier du jeu donne au mieux un
        emplacement vide, et rien ne le signale.
    #>
    if ($null -ne $script:ExistingItemIds) {
        return $script:ExistingItemIds
    }
    $ids = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($entry in @((Get-ItemData).Rows)) {
        if ($null -ne $entry -and [int]$entry.id -gt 0) {
            $null = $ids.Add([int]$entry.id)
        }
    }
    $script:ExistingItemIds = $ids
    return $ids
}

function Select-ExistingItemIds {
    <#
        Filtre une liste d'identifiants sur ce qui existe. Sans items.csv, la
        liste passe telle quelle : on ne peut pas filtrer sur une mesure qu'on
        n'a pas, et retourner une liste vide serait bien pire.
    #>
    param([int[]]$Ids)

    $existants = Get-ExistingItemIds
    if ($existants.Count -eq 0) {
        return [int[]]$Ids
    }
    return [int[]]@($Ids | Where-Object { $existants.Contains([int]$_) })
}

function Get-ItemData {
    if ($script:ItemData) {
        return $script:ItemData
    }

    $path = Find-DataFile -RelativePath "items.csv"
    if (-not $path) {
        $script:ItemData = @{
            Rows = @()
            ById = @{}
        }
        return $script:ItemData
    }

    $rows = @()
    $byId = @{}
    foreach ($row in Import-Csv -LiteralPath $path -Encoding UTF8) {
        $itemId = [int]$row.id
        $categoryId = [int]$row.category_id
        $cost = 0
        if (-not [string]::IsNullOrWhiteSpace([string]$row.cost)) {
            $cost = [int]$row.cost
        }

        $entry = [pscustomobject]@{
            id = $itemId
            identifier = [string]$row.identifier
            categoryId = $categoryId
            cost = $cost
        }

        $rows += $entry
        $byId[$itemId] = $entry
    }

    $script:ItemData = @{
        Rows = $rows
        ById = $byId
    }
    return $script:ItemData
}

function New-SpeciesAutoCompleteSource {
    $source = New-Object System.Windows.Forms.AutoCompleteStringCollection
    $data = Get-SpeciesNameData
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($speciesId in ($data.ById.Keys | Sort-Object)) {
        $entry = $data.ById[$speciesId]
        foreach ($name in @($entry.fr, $entry.en)) {
            $value = ([string]$name).Trim()
            if ($value -and $seen.Add($value)) {
                $null = $source.Add($value)
            }
        }
    }

    Write-Output -NoEnumerate $source
}

function Get-ItemNameData {
    if ($script:ItemNameData) {
        return $script:ItemNameData
    }

    $path = Find-DataFile -RelativePath "item_names.csv"
    if (-not $path) {
        $script:ItemNameData = @{ ById = @{} }
        return $script:ItemNameData
    }

    $byId = @{}
    foreach ($row in Import-Csv -LiteralPath $path -Encoding UTF8) {
        $itemId = [int]$row.item_id
        $languageId = [int]$row.local_language_id
        if ($languageId -ne $FrenchLanguageId -and $languageId -ne $EnglishLanguageId) {
            continue
        }

        if (-not $byId.ContainsKey($itemId)) {
            $byId[$itemId] = @{
                fr = ""
                en = ""
            }
        }

        $slot = if ($languageId -eq $FrenchLanguageId) { "fr" } else { "en" }
        $byId[$itemId][$slot] = [string]$row.name
    }

    $script:ItemNameData = @{ ById = $byId }
    return $script:ItemNameData
}

function Get-SpeciesDisplayName {
    param(
        [int]$SpeciesId,
        [string]$Language = "fr"
    )

    $lang = if (([string]$Language).ToLowerInvariant() -eq "en") { "en" } else { "fr" }
    $data = Get-SpeciesNameData
    $entry = $data.ById[$SpeciesId]
    if (-not $entry) {
        return "Pokemon $SpeciesId"
    }

    if ($entry[$lang]) {
        return $entry[$lang]
    }
    if ($entry.fr) {
        return $entry.fr
    }
    return $entry.en
}

function Get-ItemDisplayName {
    param(
        [int]$ItemId,
        [string]$Language = "fr"
    )

    if ($ItemId -le 0) {
        return ""
    }

    $lang = if (([string]$Language).ToLowerInvariant() -eq "en") { "en" } else { "fr" }
    $data = Get-ItemNameData
    $entry = $data.ById[$ItemId]
    if (-not $entry) {
        return "Item $ItemId"
    }

    if ($entry[$lang]) {
        return $entry[$lang]
    }
    if ($entry.fr) {
        return $entry.fr
    }
    return $entry.en
}

function Add-ItemIdRange {
    param(
        [System.Collections.Generic.List[int]]$List,
        [int]$Start,
        [int]$End
    )

    for ($itemId = $Start; $itemId -le $End; $itemId++) {
        $List.Add($itemId)
    }
}

function Get-TechnicalRecordItemPool {
    $pool = New-Object System.Collections.Generic.List[int]
    Add-ItemIdRange -List $pool -Start 328 -End 419
    Add-ItemIdRange -List $pool -Start 618 -End 620
    Add-ItemIdRange -List $pool -Start 690 -End 693
    Add-ItemIdRange -List $pool -Start 1130 -End 1229
    $pool.Add(1230)
    return [int[]]$pool.ToArray()
}

function Test-TechnicalRecordItemId {
    param([int]$ItemId)
    $isTechnicalRecord = (($ItemId -ge 328 -and $ItemId -le 419) -or
        ($ItemId -ge 618 -and $ItemId -le 620) -or
        ($ItemId -ge 690 -and $ItemId -le 693) -or
        ($ItemId -ge 1130 -and $ItemId -le 1229) -or
        ($ItemId -eq 1230))
    return [bool]$isTechnicalRecord
}

function Get-GeneralRandomItemPool {
    $pool = New-Object System.Collections.Generic.List[int]
    Add-ItemIdRange -List $pool -Start 1 -End 63
    Add-ItemIdRange -List $pool -Start 76 -End 92
    Add-ItemIdRange -List $pool -Start 106 -End 110
    Add-ItemIdRange -List $pool -Start 149 -End 212
    Add-ItemIdRange -List $pool -Start 213 -End 326
    Add-ItemIdRange -List $pool -Start 485 -End 500
    Add-ItemIdRange -List $pool -Start 537 -End 547
    Add-ItemIdRange -List $pool -Start 565 -End 582
    Add-ItemIdRange -List $pool -Start 639 -End 650
    Add-ItemIdRange -List $pool -Start 795 -End 796
    Add-ItemIdRange -List $pool -Start 849 -End 851
    Add-ItemIdRange -List $pool -Start 879 -End 884
    Add-ItemIdRange -List $pool -Start 1084 -End 1099
    Add-ItemIdRange -List $pool -Start 1105 -End 1129
    Add-ItemIdRange -List $pool -Start 1231 -End 1264
    Add-ItemIdRange -List $pool -Start 1279 -End 1326

    # Les plages ci-dessus ont ete ecrites a la main, et 35 des 454 identifiants
    # qu'elles couvrent ne correspondent a aucun objet de cette version. Deux
    # autres sont des objets CLES, qu'on ne veut ni au sol ni en boutique : un
    # objet cle duplique ou perdu peut bloquer la progression.
    $filtre = Select-ExistingItemIds -Ids ([int[]]$pool.ToArray())
    $existants = Get-ExistingItemIds
    if ($existants.Count -eq 0) {
        return [int[]]$filtre
    }
    $poches = @{}
    foreach ($entry in @((Get-ItemData).Rows)) {
        if ($null -ne $entry) { $poches[[int]$entry.id] = [int]$entry.categoryId }
    }
    $sansNom = Get-PlaceholderItemIds
    return [int[]]@($filtre | Where-Object {
        -not ($poches.ContainsKey([int]$_) -and $poches[[int]$_] -eq $ItemPocketKeyItems) -and
        -not $sansNom.Contains([int]$_)
    })
}

function Get-ItemPocketMap {
    <#
        La poche de chaque objet, telle que le JEU la stocke : items.csv est
        derive de item.dat par tools/build-items-csv.py, et sa colonne
        category_id porte l'octet +0x11 de l'enregistrement.
    #>
    if ($null -ne $script:ItemPocketMap) {
        return $script:ItemPocketMap
    }
    $map = @{}
    foreach ($entry in @((Get-ItemData).Rows)) {
        if ($null -ne $entry) { $map[[int]$entry.id] = [int]$entry.categoryId }
    }
    $script:ItemPocketMap = $map
    return $map
}

function Test-PlaceholderItemName {
    <#
        Un nom d'objet que le joueur ne peut pas lire : vide, ou commencant par
        une etoile pleine ou creuse. Ce sont les noms de debogage laisses dans
        la table itemname du jeu.
    #>
    param([string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) { return $true }
    $premier = $Name[0]
    return ($premier -eq [char]0x2605 -or $premier -eq [char]0x2606)
}

function Get-PlaceholderItemIds {
    <#
        Les objets dont le jeu lui-meme ne donne pas de nom lisible.

        Mesure du 2026-09-07 sur le dump Epee 1.3.2 : 300 des 1608 entrees de
        itemname portent un nom de debogage (« ★And390 », « ★Sgr6879 »). Ils
        FONCTIONNENT - l'un d'eux, ramasse au sol pendant les essais, affichait
        bien sa description d'Eclat Souhait - mais leur nom est illisible.

        Sur les 454 identifiants du pool general, 48 sont dans ce cas, et ce
        sont exactement les 48 de la plage 1279-1326. Aucun autre.

        Sans item_names.csv le filtre ne peut pas s'appliquer : on rend alors
        un ensemble vide plutot que de deviner une plage codee en dur, ce qui
        est precisement l'erreur qui a mis ces objets dans le pool.
    #>
    if ($null -ne $script:PlaceholderItemIds) {
        return $script:PlaceholderItemIds
    }
    $ids = [System.Collections.Generic.HashSet[int]]::new()
    $noms = (Get-ItemNameData).ById
    foreach ($cle in @($noms.Keys)) {
        $entree = $noms[$cle]
        if ((Test-PlaceholderItemName -Name ([string]$entree.fr)) -and
            (Test-PlaceholderItemName -Name ([string]$entree.en))) {
            $null = $ids.Add([int]$cle)
        }
    }
    $script:PlaceholderItemIds = $ids
    return $ids
}

function Get-RandomItemReplacement {
    param(
        [int]$CurrentItemId,
        [System.Random]$Rng,
        [switch]$PreferTechnicalRecord,
        [switch]$SamePocket,
        [int[]]$ShopPockets = @()
    )

    $pool = if ($PreferTechnicalRecord.IsPresent -or (Test-TechnicalRecordItemId -ItemId $CurrentItemId)) {
        Get-TechnicalRecordItemPool
    } elseif ($RandomizeTechnicalRecords.IsPresent) {
        @((Get-GeneralRandomItemPool) + (Get-TechnicalRecordItemPool))
    } else {
        Get-GeneralRandomItemPool
    }

    if (-not $pool -or $pool.Count -eq 0) {
        return $CurrentItemId
    }

    # Une machine se remplace par une machine : son reservoir est deja homogene
    # et vaut exactement la poche de l'emplacement. Lui appliquer en plus le
    # filtre des poches de la boutique viderait le reservoir - les machines
    # etant justement exclues de ce filtre - et plus aucune CT ne changerait.
    if ($ShopPockets -and $ShopPockets.Count -gt 0 -and -not $PreferTechnicalRecord.IsPresent) {
        # Tirage dans l'UNION des poches que cette boutique vend deja.
        #
        # Mesure du 2026-09-08 : l'ancien mode « n'importe quel objet » changeait
        # la poche de 17 emplacements sur 21 et transformait le marche de depart,
        # qui vend des Balls (33) et des soins (32), en poches [4, 7, 33]. C'est
        # exactement ce qui vidait la liste et faisait planter le jeu a l'achat.
        #
        # L'union est plus large que « meme genre » sans jamais sortir de ce que
        # l'interface sait afficher : le marche de depart peut echanger un soin
        # contre une Ball, la boutique 165 puise dans ses quatre poches.
        $pochesTirage = Get-ItemPocketMap
        if (-not $pochesTirage.ContainsKey($CurrentItemId)) {
            # Poche inconnue : emplacement pointant sur l'enregistrement 0 de
            # item.dat. On n'ecrit pas dans ce qu'on ne sait pas relire.
            return $CurrentItemId
        }
        $autorisees = New-Object System.Collections.Generic.HashSet[int]
        foreach ($p in $ShopPockets) {
            $pi = [int]$p
            if ($pi -ne $ItemPocketMachines -and $pi -ne $ItemPocketKeyItems) { $null = $autorisees.Add($pi) }
        }
        $restreint = [int[]]@($pool | Where-Object {
            $pochesTirage.ContainsKey([int]$_) -and $autorisees.Contains([int]$pochesTirage[[int]$_])
        })
        if ($restreint.Count -lt 2) {
            return $CurrentItemId
        }
        $pool = $restreint
    } elseif ($SamePocket.IsPresent) {
        # Une boutique n'affiche que ce qu'elle sait vendre. Mesure du
        # 2026-09-07 : le marche de depart, qui vendait des Poke Ball (poche 33)
        # et des soins (poche 32), s'est retrouve avec une CT (poche 5) ; la
        # liste s'affichait vide et le jeu plantait a l'achat. On remplace donc
        # une Poke Ball par une Poke Ball et une potion par une potion.
        $pochesTirage = Get-ItemPocketMap
        if (-not $pochesTirage.ContainsKey($CurrentItemId)) {
            # Poche inconnue : l'objet d'origine n'a pas d'enregistrement dans
            # item.dat, il n'existe donc pas dans cette version. Mesure du
            # 2026-09-07 : les deux boutiques du second vecteur racine de
            # shop_data.bin listent sept objets de ce genre (Vieux Bijou, Orbe
            # Vert, Fossile Griffe...), tous a l'enregistrement 0, prix 0.
            # On n'ecrit pas dans un emplacement qu'on ne sait pas relire.
            return $CurrentItemId
        }
        $pocheCible = [int]$pochesTirage[$CurrentItemId]
        $restreint = [int[]]@($pool | Where-Object {
            $pochesTirage.ContainsKey([int]$_) -and [int]$pochesTirage[[int]$_] -eq $pocheCible
        })
        if ($restreint.Count -lt 2) {
            # Rien a tirer dans cette poche : garder l'objet d'origine vaut
            # mieux qu'ecrire un objet que la boutique ne sait pas vendre.
            return $CurrentItemId
        }
        $pool = $restreint
    }

    if ($pool.Count -eq 1) {
        return [int]$pool[0]
    }

    $replacement = $CurrentItemId
    for ($attempt = 0; $attempt -lt 12 -and $replacement -eq $CurrentItemId; $attempt++) {
        $replacement = [int]$pool[$Rng.Next(0, $pool.Count)]
    }
    return $replacement
}

function Get-MoveNameData {
    if ($script:MoveNameData) {
        return $script:MoveNameData
    }

    $path = Find-DataFile -RelativePath "move_names.csv"
    if (-not $path) {
        $script:MoveNameData = @{ ById = @{} }
        return $script:MoveNameData
    }

    $byId = @{}
    foreach ($row in Import-Csv -LiteralPath $path -Encoding UTF8) {
        $moveId = [int]$row.move_id
        $languageId = [int]$row.local_language_id
        if ($languageId -ne $FrenchLanguageId -and $languageId -ne $EnglishLanguageId) {
            continue
        }

        if (-not $byId.ContainsKey($moveId)) {
            $byId[$moveId] = @{
                fr = ""
                en = ""
            }
        }

        $slot = if ($languageId -eq $FrenchLanguageId) { "fr" } else { "en" }
        $byId[$moveId][$slot] = [string]$row.name
    }

    $script:MoveNameData = @{ ById = $byId }
    return $script:MoveNameData
}

function Get-MoveDisplayName {
    param(
        [int]$MoveId,
        [string]$Language = "fr"
    )

    if ($MoveId -le 0) {
        return ""
    }

    $lang = if (([string]$Language).ToLowerInvariant() -eq "en") { "en" } else { "fr" }
    $data = Get-MoveNameData
    $entry = $data.ById[$MoveId]
    if (-not $entry) {
        return "Move $MoveId"
    }

    if ($entry[$lang]) {
        return $entry[$lang]
    }
    if ($entry.fr) {
        return $entry.fr
    }
    return $entry.en
}

function Resolve-SpeciesToken {
    param([string]$Token)

    $text = ([string]$Token).Trim()
    if (-not $text) {
        return 0
    }

    $numeric = 0
    if ([int]::TryParse($text, [ref]$numeric)) {
        if ($numeric -ge 1 -and $numeric -le $BaseSpeciesMax) {
            return $numeric
        }
        throw "ID de Pokémon invalide: $text"
    }

    $data = Get-SpeciesNameData
    $key = Normalize-SearchKey -Value $text
    if (-not $key) {
        throw "Pokemon introuvable: '$text'"
    }

    if ($data.ByKey.ContainsKey($key) -and $data.ByKey[$key].Count -gt 0) {
        return [int]$data.ByKey[$key][0]
    }

    $prefixMatches = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($candidateKey in $data.ByKey.Keys) {
        if ($candidateKey.StartsWith($key)) {
            foreach ($speciesId in $data.ByKey[$candidateKey]) {
                $null = $prefixMatches.Add([int]$speciesId)
            }
        }
    }

    if ($prefixMatches.Count -eq 1) {
        return [int]($prefixMatches | Select-Object -First 1)
    }

    if ($prefixMatches.Count -gt 1) {
        $examples = @($prefixMatches | Sort-Object | Select-Object -First 6 | ForEach-Object { Get-SpeciesDisplayName -SpeciesId $_ -Language "fr" })
        throw ("Pokémon ambigu pour '{0}'. Précise le nom. Exemples: {1}" -f $text, ($examples -join ", "))
    }

    throw "Pokemon introuvable: '$text'"
}

function Complete-SpeciesTextBoxValue {
    param(
        [object]$TextBox,
        [string]$Language = "fr"
    )

    if ($null -eq $TextBox) {
        return
    }

    $raw = ([string]$TextBox.Text).Trim()
    if (-not $raw) {
        return
    }

    try {
        $speciesId = Resolve-SpeciesToken -Token $raw
        if ($speciesId -le 0) {
            return
        }

        $displayName = Get-SpeciesDisplayName -SpeciesId $speciesId -Language $Language
        if ($displayName) {
            $TextBox.Text = $displayName
            $TextBox.SelectionStart = $TextBox.Text.Length
            $TextBox.SelectionLength = 0
        }
    } catch {
        return
    }
}

function Get-ConfiguredStarterSpeciesIds {
    $values = @($Starter1, $Starter2, $Starter3)
    $filledValues = @($values | Where-Object { ([string]$_).Trim() })
    if ($filledValues.Count -eq 0) {
        return $null
    }

    $blankValues = @($values | Where-Object { -not ([string]$_).Trim() })
    if ($blankValues.Count -gt 0) {
        throw "Quand tu choisis des starters manuels, il faut renseigner les 3 slots."
    }

    $resolved = @()
    foreach ($value in $values) {
        $resolved += Resolve-SpeciesToken -Token $value
    }

    $unique = @($resolved | Select-Object -Unique)
    if ($unique.Count -ne 3) {
        throw "Les 3 starters manuels doivent être différents."
    }

    return [int[]]$resolved
}

function Get-VanillaTrainerMetadata {
    if ($script:VanillaTrainerMetadata) {
        return $script:VanillaTrainerMetadata
    }

    $enPath = Find-DataFile -RelativePath "vanilla_exports\pokemon_sword_global_en.json"
    $frPath = Find-DataFile -RelativePath "vanilla_exports\pokemon_sword_global_fr.json"
    $byId = @{}

    foreach ($path in @($enPath, $frPath)) {
        if (-not $path) {
            continue
        }

        $dataset = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($trainer in $dataset.trainers) {
            $id = [int]$trainer.trainerId
            if (-not $byId.ContainsKey($id)) {
                $byId[$id] = [ordered]@{
                    Id = $id
                    EnName = ""
                    FrName = ""
                    EnClass = ""
                    FrClass = ""
                    EnFull = ""
                    FrFull = ""
                    Party = @()
                }
            }

            if (-not $byId[$id].Party -or $byId[$id].Party.Count -eq 0) {
                $party = New-Object System.Collections.Generic.List[object]
                $slot = 0
                foreach ($mon in @($trainer.party)) {
                    $party.Add([ordered]@{
                        slot = [int]$slot
                        speciesId = [int]$mon.speciesId
                        level = [int]$mon.level
                    })
                    $slot++
                }
                $byId[$id].Party = [object[]]$party.ToArray()
            }

            if ($path -eq $enPath) {
                $byId[$id].EnName = [string]$trainer.name
                $byId[$id].EnClass = [string]$trainer.trainerClassName
                $byId[$id].EnFull = [string]$trainer.fullDisplayName
            } else {
                $byId[$id].FrName = [string]$trainer.name
                $byId[$id].FrClass = [string]$trainer.trainerClassName
                $byId[$id].FrFull = [string]$trainer.fullDisplayName
            }
        }
    }

    $script:VanillaTrainerMetadata = $byId
    return $script:VanillaTrainerMetadata
}

function Get-BossTrainerIdSet {
    $set = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($entry in (Get-VanillaTrainerMetadata).Values) {
        $blob = @(
            $entry.EnName, $entry.FrName,
            $entry.EnClass, $entry.FrClass,
            $entry.EnFull, $entry.FrFull
        ) -join " | "

        $normalized = Normalize-SearchKey -Value $blob
        if (-not $normalized) {
            continue
        }

        $isBoss = $false
        if ($normalized -match 'gym leader|champion d arene|champion cup|chairman|president|secretary|secretaire|maitre du dojo|dojo master') {
            $isBoss = $true
        }
        if ($normalized -match '(^| )hop($| )|(^| )nabil($| )|(^| )bede($| )|(^| )marnie($| )|(^| )rosemary($| )|(^| )leon($| )|(^| )tarak($| )|(^| )oleana($| )|(^| )liv($| )|(^| )rose($| )|(^| )shehroz($| )|(^| )mustard($| )|(^| )mustar($| )|(^| )avery($| )|(^| )sophora($| )|(^| )klara($| )|(^| )saturnin($| )|(^| )peony($| )|(^| )peonia($| )|(^| )pivonia($| )|(^| )dhilan($| )|(^| )sordward($| )|(^| )shielbert($| )|(^| )jean fleuret($| )|(^| )jean targe($| )') {
            $isBoss = $true
        }

        if ($isBoss) {
            $null = $set.Add($entry.Id)
        }
    }

    return $set
}

function Normalize-BossTeamsToSixScope {
    param([string]$Scope)

    $normalized = Normalize-Mode $Scope
    if ($normalized -in @(
        "gymleague",
        "gymleagueonly",
        "gymsleague",
        "gymsleagueonly",
        "gymchampion",
        "arenaleague",
        "arenaleague",
        "arenesligue",
        "areneschampion",
        "arenesconseil4",
        "arenaelite4",
        "elite4"
    )) {
        return "GymLeague"
    }

    return "MajorBosses"
}

function Test-IsGymLeagueBossTarget {
    param($Entry)

    if (-not $Entry) {
        return $false
    }

    $blob = @(
        $Entry.EnName, $Entry.FrName,
        $Entry.EnClass, $Entry.FrClass,
        $Entry.EnFull, $Entry.FrFull
    ) -join " | "

    $normalized = Normalize-SearchKey -Value $blob
    if (-not $normalized) {
        return $false
    }

    return ($normalized -match 'gym leader|champion d arene|championne d arene|champion cup|(^| )champion($| )|(^| )leon($| )|(^| )tarak($| )')
}

function Get-GymLeagueTrainerThemeTypeId {
    param($Entry)

    if (-not $Entry) {
        return -1
    }

    $blob = @(
        $Entry.EnName, $Entry.FrName,
        $Entry.EnClass, $Entry.FrClass,
        $Entry.EnFull, $Entry.FrFull
    ) -join " | "

    $normalized = Normalize-SearchKey -Value $blob
    if (-not $normalized) {
        return -1
    }

    if ($normalized -match '(^| )(leon|tarak)($| )') {
        return -1
    }
    if ($normalized -match '(^| )milo($| )') { return 11 }                 # Grass
    if ($normalized -match '(^| )(nessa|donna)($| )') { return 10 }       # Water
    if ($normalized -match '(^| )kabu($| )') { return 9 }                 # Fire
    if ($normalized -match '(^| )(bea|faiza)($| )') { return 1 }          # Fighting
    if ($normalized -match '(^| )(allister|alistair)($| )') { return 7 }  # Ghost
    if ($normalized -match '(^| )(opal|sally)($| )') { return 17 }        # Fairy
    if ($normalized -match '(^| )(gordie|gordon|chaz)($| )') { return 5 } # Rock
    if ($normalized -match '(^| )(melony|lona)($| )') { return 14 }       # Ice
    if ($normalized -match '(^| )(piers|peterson|percy)($| )') { return 16 } # Dark
    if ($normalized -match '(^| )(raihan|roy)($| )') { return 15 }        # Dragon

    return -1
}

function Get-GymLeagueTrainerThemeTypeIdByTrainerId {
    param(
        [int]$TrainerId,
        [string]$GameVersionValue = "Sword"
    )

    switch ($TrainerId) {
        32 { return 11 }  # Milo / Percy - Grass
        36 { return 10 }  # Nessa / Donna - Water
        37 { return 9 }   # Kabu - Fire
        77 { return 1 }   # Bea / Faiza - Fighting
        137 { return 1 }  # Bea / Faiza rematch - Fighting
        78 { return 7 }   # Allister / Alistair - Ghost
        134 { return 7 }  # Allister / Alistair rematch - Ghost
        108 { return 17 } # Opal / Sally - Fairy
        135 { return 5 }  # Gordie / Chaz - Rock
        136 { return 14 } # Melony / Lona - Ice
        107 { return 16 } # Piers / Peterson - Dark
        144 { return 15 } # Raihan / Roy - Dragon
        149 { return -1 } # Leon / Tarak - balanced team
        default { return -1 }
    }
}

function Get-TypeThemeReportObject {
    param([int]$TypeId)

    $frNames = @("Normal", "Combat", "Vol", "Poison", "Sol", "Roche", "Insecte", "Spectre", "Acier", "Feu", "Eau", "Plante", "Electrik", "Psy", "Glace", "Dragon", "Tenebres", "Fee")
    $enNames = @("Normal", "Fighting", "Flying", "Poison", "Ground", "Rock", "Bug", "Ghost", "Steel", "Fire", "Water", "Grass", "Electric", "Psychic", "Ice", "Dragon", "Dark", "Fairy")
    if ($TypeId -lt 0 -or $TypeId -ge $frNames.Count) {
        return $null
    }

    return [ordered]@{
        typeId = [int]$TypeId
        fr = $frNames[$TypeId]
        en = $enNames[$TypeId]
    }
}

function Get-FallbackBossTrainerTargetCatalog {
    param(
        [string]$Scope = "MajorBosses",
        [string]$GameVersionValue = "Sword"
    )

    $scopeValue = Normalize-BossTeamsToSixScope -Scope $Scope
    $excludedTrainerIds = [System.Collections.Generic.HashSet[int]]::new()
    @(4, 5, 6) | ForEach-Object { $null = $excludedTrainerIds.Add([int]$_) }

    $version = Get-NormalizedGameVersionSelection -Value $GameVersionValue
    if ($version -eq "Auto") {
        $version = "Sword"
    }

    $targets = New-Object System.Collections.Generic.List[object]
    foreach ($spec in (Get-StoryMajorBattleProgressionSpecs -GameVersion $version)) {
        if ($scopeValue -eq "GymLeague" -and [string]$spec.category -notin @("gym", "champion")) {
            continue
        }

        foreach ($id in @($spec.trainerIds)) {
            if ($excludedTrainerIds.Contains([int]$id)) {
                continue
            }

            $targets.Add([pscustomobject][ordered]@{
                trainerId = [int]$id
                names = [ordered]@{
                    fr = [string]$spec.stageLabelFr
                    en = [string]$spec.stageLabelEn
                }
                trainerClass = [ordered]@{
                    fr = ""
                    en = ""
                }
                fallbackSource = "storyProgressionSpecs"
            })
        }
    }

    return [object[]]$targets.ToArray()
}

function Get-BossTrainerTargetCatalog {
    param(
        [string]$Scope = "MajorBosses",
        [string]$GameVersionValue = "Sword"
    )

    $scopeValue = Normalize-BossTeamsToSixScope -Scope $Scope
    $excludedTrainerIds = [System.Collections.Generic.HashSet[int]]::new()
    @(4, 5, 6) | ForEach-Object { $null = $excludedTrainerIds.Add([int]$_) }

    $targets = New-Object System.Collections.Generic.List[object]
    $metadata = Get-VanillaTrainerMetadata
    $bossIds = Get-BossTrainerIdSet
    foreach ($id in @($bossIds | Sort-Object)) {
        if ($excludedTrainerIds.Contains([int]$id)) {
            continue
        }

        $entry = $metadata[$id]
        if (-not $entry) {
            continue
        }
        if ($scopeValue -eq "GymLeague" -and -not (Test-IsGymLeagueBossTarget -Entry $entry)) {
            continue
        }

        $targets.Add([pscustomobject][ordered]@{
            trainerId = [int]$id
            names = [ordered]@{
                fr = [string]$entry["FrFull"]
                en = [string]$entry["EnFull"]
            }
            trainerClass = [ordered]@{
                fr = [string]$entry["FrClass"]
                en = [string]$entry["EnClass"]
            }
        })
    }

    if ($targets.Count -lt 1) {
        return Get-FallbackBossTrainerTargetCatalog -Scope $Scope -GameVersionValue $GameVersionValue
    }

    return [object[]]$targets.ToArray()
}

function Get-BossTrainerUniqueNames {
    param(
        [string]$Language = "fr",
        [string]$Scope = "MajorBosses"
    )

    $lang = if (([string]$Language).ToLowerInvariant() -eq "en") { "en" } else { "fr" }
    $names = New-Object System.Collections.Generic.HashSet[string]
    foreach ($target in Get-BossTrainerTargetCatalog -Scope $Scope) {
        $targetNames = if ($target -is [System.Collections.IDictionary]) { $target["names"] } else { $target.names }
        $targetClass = if ($target -is [System.Collections.IDictionary]) { $target["trainerClass"] } else { $target.trainerClass }
        $full = [string]$targetNames[$lang]
        $class = [string]$targetClass[$lang]
        if (-not $full) {
            $full = [string]$targetNames["en"]
            $class = [string]$targetClass["en"]
        }

        $clean = $full.Trim()
        if ($class -and $clean.StartsWith($class, [System.StringComparison]::OrdinalIgnoreCase)) {
            $clean = $clean.Substring($class.Length).Trim()
        }
        $clean = ($clean -replace '^(Dresseur|Dresseuse|Champion d.Ar.ne|Championne d.Ar.ne|Maitre|Maitre du Dojo|Macro Cosmos|Pokemon Trainer|Gym Leader|Champion|Dojo Master)\s+', '').Trim()
        if ($clean) {
            $null = $names.Add($clean)
        }
    }

    return [string[]]@($names | Sort-Object)
}

function Get-BossTrainerUniqueNamesText {
    param(
        [string]$Language = "fr",
        [string]$Scope = "MajorBosses"
    )

    $lang = if (([string]$Language).ToLowerInvariant() -eq "en") { "en" } else { "fr" }
    $scopeValue = Normalize-BossTeamsToSixScope -Scope $Scope
    $ordered = Get-BossTrainerUniqueNames -Language $lang -Scope $scopeValue
    $listText = ($ordered -join [Environment]::NewLine)
    if ($lang -eq "en") {
        $title = if ($scopeValue -eq "GymLeague") { "Gym + league targets" } else { "Major boss targets" }
        return $title + " (unique names):`r`n" + $listText + "`r`n`r`nExact trainer IDs are exported in JSON."
    }
    $title = if ($scopeValue -eq "GymLeague") { "Cibles arènes + ligue" } else { "Cibles boss importants" }
    return $title + " (noms uniques) :`r`n" + $listText + "`r`n`r`nLes identifiants exacts sont exportés dans le rapport JSON."
}

function Get-BossLevelCapEntries {
    param([string]$RomfsRoot)

    $entries = New-Object System.Collections.Generic.List[object]
    $bossIds = Get-BossTrainerIdSet
    $metadata = Get-VanillaTrainerMetadata
    $trainerDataDir = Get-TrainerDataDir -RomfsRoot $RomfsRoot
    $trainerPokeDir = Get-TrainerPokeDir -RomfsRoot $RomfsRoot

    foreach ($trainerId in @($bossIds | Sort-Object)) {
        $trainerDataPath = Join-Path $trainerDataDir ("trainer_data_{0:D3}.bin" -f [int]$trainerId)
        $trainerPokePath = Join-Path $trainerPokeDir ("trainer_poke_{0:D3}.bin" -f [int]$trainerId)
        if (-not (Test-Path -LiteralPath $trainerDataPath) -or -not (Test-Path -LiteralPath $trainerPokePath)) {
            continue
        }

        $dataBytes = [IO.File]::ReadAllBytes($trainerDataPath)
        $partyBytes = [IO.File]::ReadAllBytes($trainerPokePath)
        $recordCount = [int]($partyBytes.Length / $TrainerPokemonRecordSize)
        $teamSize = if ($dataBytes.Length -gt 3) { [int]$dataBytes[3] } else { $recordCount }
        if ($teamSize -lt 1 -or $teamSize -gt $recordCount) {
            $teamSize = $recordCount
        }

        $party = New-Object System.Collections.Generic.List[object]
        $capLevel = 0
        for ($slot = 0; $slot -lt $teamSize; $slot++) {
            $snapshot = Get-TrainerPokemonSnapshot -Data $partyBytes -Slot $slot
            if (-not $snapshot) {
                continue
            }
            $level = [int]$snapshot.level
            if ($level -gt $capLevel) {
                $capLevel = $level
            }
            $party.Add([ordered]@{
                slot = $slot + 1
                species = $snapshot.species
                formId = $snapshot.formId
                level = $level
            })
        }

        if ($capLevel -le 0) {
            continue
        }

        $entry = $metadata[[int]$trainerId]
        $entries.Add([ordered]@{
            trainerId = [int]$trainerId
            names = [ordered]@{
                fr = if ($entry) { [string]$entry["FrFull"] } else { "" }
                en = if ($entry) { [string]$entry["EnFull"] } else { "" }
            }
            trainerClass = [ordered]@{
                fr = if ($entry) { [string]$entry["FrClass"] } else { "" }
                en = if ($entry) { [string]$entry["EnClass"] } else { "" }
            }
            capLevel = [int]$capLevel
            teamSize = [int]$teamSize
            party = [object[]]$party.ToArray()
        })
    }

    return [object[]]$entries.ToArray()
}

function Get-GameBuildIdFromRomfsRoot {
    param([string]$RomfsRoot)

    $candidates = New-Object System.Collections.Generic.List[string]
    if ([string]::IsNullOrWhiteSpace($RomfsRoot)) {
        return ""
    }

    $resolvedRomfsRoot = try { (Resolve-Path -LiteralPath $RomfsRoot -ErrorAction Stop).Path } catch { $RomfsRoot }
    $romfsParent = Split-Path -Parent $resolvedRomfsRoot
    if ($romfsParent) {
        $candidates.Add((Join-Path $romfsParent "exefs\main"))
        $gameRoot = Split-Path -Parent $romfsParent
        if ($gameRoot) {
            $candidates.Add((Join-Path $gameRoot "exefs\main"))
        }
    }

    foreach ($candidate in @($candidates | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $candidate)) {
            continue
        }

        $stream = [IO.File]::Open($candidate, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        try {
            if ($stream.Length -lt 0x54) {
                continue
            }
            $buffer = New-Object byte[] 0x14
            $stream.Position = 0x40
            $read = $stream.Read($buffer, 0, $buffer.Length)
            if ($read -ne $buffer.Length) {
                continue
            }
            $buildId = ([BitConverter]::ToString($buffer)).Replace("-", "").ToUpperInvariant()
            if ($buildId -match '^[0-9A-F]{40}$') {
                return $buildId
            }
        } finally {
            $stream.Dispose()
        }
    }

    return ""
}

function Get-SourceGameVersion {
    param([string]$RomfsRoot)

    $buildId = Get-GameBuildIdFromRomfsRoot -RomfsRoot $RomfsRoot
    switch ($buildId) {
        "A3B75BCD3311385AEED67FBEEB79CBB7BF02F471" { return "Sword" }
        "A16802625E7826BF83B6F9708E475B912A9AB7DF" { return "Shield" }
    }

    $normalized = Normalize-SearchKey -Value $RomfsRoot
    if ($normalized -match '(^| )(epee|sword)( |$)') {
        return "Sword"
    }
    if ($normalized -match '(^| )(bouclier|shield)( |$)') {
        return "Shield"
    }

    return "Sword"
}

function Get-GymLeagueStoryProgressionSpecs {
    param([string]$GameVersion)

    $isShield = ([string]$GameVersion).ToLowerInvariant() -eq "shield"
    $gym4TrainerId = if ($isShield) { 78 } else { 77 }
    $gym4Key = if ($isShield) { "gym4Allister" } else { "gym4Bea" }
    $gym4LabelFr = if ($isShield) { "4e arene - Alistair" } else { "4e arène - Faiza" }
    $gym4LabelEn = if ($isShield) { "Gym 4 - Allister" } else { "Gym 4 - Bea" }
    $gym6TrainerId = if ($isShield) { 136 } else { 135 }
    $gym6Key = if ($isShield) { "gym6Melony" } else { "gym6Gordie" }
    $gym6LabelFr = if ($isShield) { "6e arene - Melony" } else { "6e arène - Gordon" }
    $gym6LabelEn = if ($isShield) { "Gym 6 - Melony" } else { "Gym 6 - Gordie" }

    return @(
        [ordered]@{ badgeCount = 0; patchSpeciesId = $GymLeagueStoryCapPatchSpeciesBase + 0; stageKey = "gym1Milo"; trainerId = 32; stageLabelFr = "1ere arene - Milo"; stageLabelEn = "Gym 1 - Milo" }
        [ordered]@{ badgeCount = 1; patchSpeciesId = $GymLeagueStoryCapPatchSpeciesBase + 1; stageKey = "gym2Nessa"; trainerId = 36; stageLabelFr = "2e arene - Donna"; stageLabelEn = "Gym 2 - Nessa" }
        [ordered]@{ badgeCount = 2; patchSpeciesId = $GymLeagueStoryCapPatchSpeciesBase + 2; stageKey = "gym3Kabu"; trainerId = 37; stageLabelFr = "3e arene - Kabu"; stageLabelEn = "Gym 3 - Kabu" }
        [ordered]@{ badgeCount = 3; patchSpeciesId = $GymLeagueStoryCapPatchSpeciesBase + 3; stageKey = $gym4Key; trainerId = $gym4TrainerId; stageLabelFr = $gym4LabelFr; stageLabelEn = $gym4LabelEn }
        [ordered]@{ badgeCount = 4; patchSpeciesId = $GymLeagueStoryCapPatchSpeciesBase + 4; stageKey = "gym5Opal"; trainerId = 108; stageLabelFr = "5e arene - Sally"; stageLabelEn = "Gym 5 - Opal" }
        [ordered]@{ badgeCount = 5; patchSpeciesId = $GymLeagueStoryCapPatchSpeciesBase + 5; stageKey = $gym6Key; trainerId = $gym6TrainerId; stageLabelFr = $gym6LabelFr; stageLabelEn = $gym6LabelEn }
        [ordered]@{ badgeCount = 6; patchSpeciesId = $GymLeagueStoryCapPatchSpeciesBase + 6; stageKey = "gym7Piers"; trainerId = 107; stageLabelFr = "7e arene - Peterson"; stageLabelEn = "Gym 7 - Piers" }
        [ordered]@{ badgeCount = 7; patchSpeciesId = $GymLeagueStoryCapPatchSpeciesBase + 7; stageKey = "gym8Raihan"; trainerId = 144; stageLabelFr = "8e arene - Roy"; stageLabelEn = "Gym 8 - Raihan" }
        [ordered]@{ badgeCount = 8; patchSpeciesId = $GymLeagueStoryCapPatchSpeciesBase + 8; stageKey = "championLeon"; trainerId = 149; stageLabelFr = "Maitre de la Ligue - Tarak"; stageLabelEn = "Champion Leon" }
    )
}

function Get-TrainerLevelCapEntry {
    param(
        [string]$RomfsRoot,
        [int]$TrainerId,
        [int]$BadgeCount,
        [int]$PatchSpeciesId,
        [string]$StageKey,
        [string]$StageLabelFr,
        [string]$StageLabelEn
    )

    $trainerDataPath = Join-Path (Get-TrainerDataDir -RomfsRoot $RomfsRoot) ("trainer_data_{0:D3}.bin" -f $TrainerId)
    $trainerPokePath = Join-Path (Get-TrainerPokeDir -RomfsRoot $RomfsRoot) ("trainer_poke_{0:D3}.bin" -f $TrainerId)
    if (-not (Test-Path -LiteralPath $trainerDataPath) -or -not (Test-Path -LiteralPath $trainerPokePath)) {
        throw ("Impossible de trouver les fichiers du dresseur story {0} ({1}) dans {2}" -f $TrainerId, $StageKey, $RomfsRoot)
    }

    $dataBytes = [IO.File]::ReadAllBytes($trainerDataPath)
    $partyBytes = [IO.File]::ReadAllBytes($trainerPokePath)
    $recordCount = [int]($partyBytes.Length / $TrainerPokemonRecordSize)
    $teamSize = if ($dataBytes.Length -gt 3) { [int]$dataBytes[3] } else { $recordCount }
    if ($teamSize -lt 1 -or $teamSize -gt $recordCount) {
        $teamSize = $recordCount
    }

    $metadata = (Get-VanillaTrainerMetadata)[$TrainerId]
    $party = New-Object System.Collections.Generic.List[object]
    $capLevel = 0
    for ($slot = 0; $slot -lt $teamSize; $slot++) {
        $snapshot = Get-TrainerPokemonSnapshot -Data $partyBytes -Slot $slot
        if (-not $snapshot) {
            continue
        }
        $level = [int]$snapshot.level
        if ($level -gt $capLevel) {
            $capLevel = $level
        }
        $party.Add([ordered]@{
            slot = $slot + 1
            species = $snapshot.species
            formId = $snapshot.formId
            level = $level
        })
    }

    if ($capLevel -le 0) {
        throw ("Impossible de calculer un cap pour le dresseur story {0} ({1})." -f $TrainerId, $StageKey)
    }

    return [ordered]@{
        badgeCount = $BadgeCount
        patchSpeciesId = $PatchSpeciesId
        stageKey = $StageKey
        trainerId = $TrainerId
        names = [ordered]@{
            fr = if ($metadata -and [string]$metadata["FrFull"]) { [string]$metadata["FrFull"] } else { $StageLabelFr }
            en = if ($metadata -and [string]$metadata["EnFull"]) { [string]$metadata["EnFull"] } else { $StageLabelEn }
        }
        trainerClass = [ordered]@{
            fr = if ($metadata) { [string]$metadata["FrClass"] } else { "" }
            en = if ($metadata) { [string]$metadata["EnClass"] } else { "" }
        }
        stageLabel = [ordered]@{
            fr = $StageLabelFr
            en = $StageLabelEn
        }
        capLevel = $capLevel
        teamSize = $teamSize
        party = [object[]]$party.ToArray()
    }
}

function Get-GymLeagueStoryCapEntries {
    param(
        [string]$SourceRomfsRoot,
        [string]$OutputRomfsRoot
    )

    $gameVersion = Get-SourceGameVersion -RomfsRoot $SourceRomfsRoot
    $entries = New-Object System.Collections.Generic.List[object]
    foreach ($spec in (Get-GymLeagueStoryProgressionSpecs -GameVersion $gameVersion)) {
        $entries.Add((Get-TrainerLevelCapEntry `
            -RomfsRoot $OutputRomfsRoot `
            -TrainerId ([int]$spec.trainerId) `
            -BadgeCount ([int]$spec.badgeCount) `
            -PatchSpeciesId ([int]$spec.patchSpeciesId) `
            -StageKey ([string]$spec.stageKey) `
            -StageLabelFr ([string]$spec.stageLabelFr) `
            -StageLabelEn ([string]$spec.stageLabelEn)))
    }

    return [object[]]$entries.ToArray()
}

function Get-StoryMajorBattleProgressionSpecs {
    param([string]$GameVersion)

    $isShield = ([string]$GameVersion).ToLowerInvariant() -eq "shield"
    $gym4TrainerIds = if ($isShield) { @(78) } else { @(77) }
    $gym4Key = if ($isShield) { "gym4Allister" } else { "gym4Bea" }
    $gym4LabelFr = if ($isShield) { "4e arene - Alistair" } else { "4e arène - Faiza" }
    $gym4LabelEn = if ($isShield) { "Gym 4 - Allister" } else { "Gym 4 - Bea" }
    $gym6TrainerIds = if ($isShield) { @(136) } else { @(135) }
    $gym6Key = if ($isShield) { "gym6Melony" } else { "gym6Gordie" }
    $gym6LabelFr = if ($isShield) { "6e arene - Melony" } else { "6e arène - Gordon" }
    $gym6LabelEn = if ($isShield) { "Gym 6 - Melony" } else { "Gym 6 - Gordie" }

    return @(
        [ordered]@{ stageIndex = 1; stageKey = "hopStarterChoice"; trainerIds = @(4, 5, 6); stageLabelFr = "Début - Nabil choix du starter"; stageLabelEn = "Opening - Hop starter choice"; category = "rival"; variantKind = "starterChoice" }
        [ordered]@{ stageIndex = 2; stageKey = "hopEarlyRoute"; trainerIds = @(7, 8, 9); stageLabelFr = "Debut - Nabil route 2"; stageLabelEn = "Early route - Hop"; category = "rival"; variantKind = "starterChoice" }
        [ordered]@{ stageIndex = 3; stageKey = "hopPreGym1Motostoke"; trainerIds = @(197, 198, 199); stageLabelFr = "Avant arene 1 - Nabil Motostoke"; stageLabelEn = "Before Gym 1 - Hop in Motostoke"; category = "rival"; variantKind = "starterChoice" }
        [ordered]@{ stageIndex = 4; stageKey = "hopPreGym1Bridge"; trainerIds = @(191, 192, 193); stageLabelFr = "Avant arene 1 - Nabil route"; stageLabelEn = "Before Gym 1 - Hop on route"; category = "rival"; variantKind = "starterChoice" }
        [ordered]@{ stageIndex = 5; stageKey = "gym1Milo"; trainerIds = @(32); stageLabelFr = "1ere arene - Milo"; stageLabelEn = "Gym 1 - Milo"; category = "gym"; variantKind = "single" }
        [ordered]@{ stageIndex = 6; stageKey = "bedeMine1"; trainerIds = @(195); stageLabelFr = "Galar Mine - Travis"; stageLabelEn = "Galar Mine - Bede"; category = "rival"; variantKind = "single" }
        [ordered]@{ stageIndex = 7; stageKey = "hopPostGym1"; trainerIds = @(121, 122, 123); stageLabelFr = "Apres arene 1 - Nabil"; stageLabelEn = "After Gym 1 - Hop"; category = "rival"; variantKind = "starterChoice" }
        [ordered]@{ stageIndex = 8; stageKey = "gym2Nessa"; trainerIds = @(36); stageLabelFr = "2e arene - Donna"; stageLabelEn = "Gym 2 - Nessa"; category = "gym"; variantKind = "single" }
        [ordered]@{ stageIndex = 9; stageKey = "bedeMine2"; trainerIds = @(240); stageLabelFr = "Mine de Galar 2 - Travis"; stageLabelEn = "Galar Mine 2 - Bede"; category = "rival"; variantKind = "single" }
        [ordered]@{ stageIndex = 10; stageKey = "hopPreGym3"; trainerIds = @(156, 157, 158); stageLabelFr = "Avant arene 3 - Nabil"; stageLabelEn = "Before Gym 3 - Hop"; category = "rival"; variantKind = "starterChoice" }
        [ordered]@{ stageIndex = 11; stageKey = "marnieMotostoke"; trainerIds = @(196); stageLabelFr = "Motorby - Rosemary"; stageLabelEn = "Motostoke - Marnie"; category = "rival"; variantKind = "single" }
        [ordered]@{ stageIndex = 12; stageKey = "gym3Kabu"; trainerIds = @(37); stageLabelFr = "3e arene - Kabu"; stageLabelEn = "Gym 3 - Kabu"; category = "gym"; variantKind = "single" }
        [ordered]@{ stageIndex = 13; stageKey = "hopPreGym4"; trainerIds = @(124, 125, 126); stageLabelFr = "Avant arene 4 - Nabil"; stageLabelEn = "Before Gym 4 - Hop"; category = "rival"; variantKind = "starterChoice" }
        [ordered]@{ stageIndex = 14; stageKey = "bedeMidStory"; trainerIds = @(133); stageLabelFr = "Milieu d'histoire - Travis"; stageLabelEn = "Mid story - Bede"; category = "rival"; variantKind = "single" }
        [ordered]@{ stageIndex = 15; stageKey = $gym4Key; trainerIds = $gym4TrainerIds; stageLabelFr = $gym4LabelFr; stageLabelEn = $gym4LabelEn; category = "gym"; variantKind = "version" }
        [ordered]@{ stageIndex = 16; stageKey = "hopPostGym4"; trainerIds = @(127, 128, 129); stageLabelFr = "Apres arene 4 - Nabil"; stageLabelEn = "After Gym 4 - Hop"; category = "rival"; variantKind = "starterChoice" }
        [ordered]@{ stageIndex = 17; stageKey = "gym5Opal"; trainerIds = @(108); stageLabelFr = "5e arene - Sally"; stageLabelEn = "Gym 5 - Opal"; category = "gym"; variantKind = "single" }
        [ordered]@{ stageIndex = 18; stageKey = "hopPreGym6"; trainerIds = @(202, 203, 204); stageLabelFr = "Avant arene 6 - Nabil"; stageLabelEn = "Before Gym 6 - Hop"; category = "rival"; variantKind = "starterChoice" }
        [ordered]@{ stageIndex = 19; stageKey = $gym6Key; trainerIds = $gym6TrainerIds; stageLabelFr = $gym6LabelFr; stageLabelEn = $gym6LabelEn; category = "gym"; variantKind = "version" }
        [ordered]@{ stageIndex = 20; stageKey = "marnieSpikemuth"; trainerIds = @(138); stageLabelFr = "Smashings - Rosemary"; stageLabelEn = "Spikemuth - Marnie"; category = "rival"; variantKind = "single" }
        [ordered]@{ stageIndex = 21; stageKey = "gym7Piers"; trainerIds = @(107); stageLabelFr = "7e arene - Peterson"; stageLabelEn = "Gym 7 - Piers"; category = "gym"; variantKind = "single" }
        [ordered]@{ stageIndex = 22; stageKey = "gym8Raihan"; trainerIds = @(144); stageLabelFr = "8e arene - Roy"; stageLabelEn = "Gym 8 - Raihan"; category = "gym"; variantKind = "single" }
        [ordered]@{ stageIndex = 23; stageKey = "marnieSemifinal"; trainerIds = @(145); stageLabelFr = "Tournoi final - Rosemary"; stageLabelEn = "Final tournament - Marnie"; category = "league"; variantKind = "single" }
        [ordered]@{ stageIndex = 24; stageKey = "hopSemifinal"; trainerIds = @(130, 131, 132); stageLabelFr = "Tournoi final - Nabil"; stageLabelEn = "Final tournament - Hop"; category = "rival"; variantKind = "starterChoice" }
        [ordered]@{ stageIndex = 25; stageKey = "oleanaRoseTower"; trainerIds = @(143); stageLabelFr = "Tour Rose - Liv"; stageLabelEn = "Rose Tower - Oleana"; category = "villain"; variantKind = "single" }
        [ordered]@{ stageIndex = 26; stageKey = "hopFinal"; trainerIds = @(153, 154, 155); stageLabelFr = "Fin d'histoire - Nabil"; stageLabelEn = "Late story - Hop"; category = "rival"; variantKind = "starterChoice" }
        [ordered]@{ stageIndex = 27; stageKey = "roseFinal"; trainerIds = @(175); stageLabelFr = "Fin d'histoire - Shehroz"; stageLabelEn = "Late story - Rose"; category = "villain"; variantKind = "single" }
        [ordered]@{ stageIndex = 28; stageKey = "championLeon"; trainerIds = @(149); stageLabelFr = "Maitre de la Ligue - Tarak"; stageLabelEn = "Champion Leon"; category = "champion"; variantKind = "single" }
    )
}

function Get-StoryMajorBattleTargetCatalog {
    param([string]$SourceRomfsRoot)

    $gameVersion = Get-SourceGameVersion -RomfsRoot $SourceRomfsRoot
    $metadata = Get-VanillaTrainerMetadata
    $targets = New-Object System.Collections.Generic.List[object]
    foreach ($spec in (Get-StoryMajorBattleProgressionSpecs -GameVersion $gameVersion)) {
        $trainerIds = @($spec.trainerIds)
        $variantCount = $trainerIds.Count
        foreach ($trainerId in $trainerIds) {
            $entry = $metadata[[int]$trainerId]
        $targets.Add([pscustomobject][ordered]@{
                stageIndex = [int]$spec.stageIndex
                stageKey = [string]$spec.stageKey
                category = [string]$spec.category
                variantKind = [string]$spec.variantKind
                variantCount = $variantCount
                trainerId = [int]$trainerId
                targetSources = @("storyMajorBattleOrderLevelCap")
                stageLabel = [ordered]@{
                    fr = [string]$spec.stageLabelFr
                    en = [string]$spec.stageLabelEn
                }
                names = [ordered]@{
                    fr = if ($entry) { [string]$entry["FrFull"] } else { [string]$spec.stageLabelFr }
                    en = if ($entry) { [string]$entry["EnFull"] } else { [string]$spec.stageLabelEn }
                }
                trainerClass = [ordered]@{
                    fr = if ($entry) { [string]$entry["FrClass"] } else { "" }
                    en = if ($entry) { [string]$entry["EnClass"] } else { "" }
                }
            })
        }
    }

    return [object[]]$targets.ToArray()
}

function Get-StoryMajorBattleCapEntries {
    param(
        [string]$SourceRomfsRoot,
        [string]$OutputRomfsRoot
    )

    $gameVersion = Get-SourceGameVersion -RomfsRoot $SourceRomfsRoot
    $entries = New-Object System.Collections.Generic.List[object]
    foreach ($spec in (Get-StoryMajorBattleProgressionSpecs -GameVersion $gameVersion)) {
        foreach ($trainerId in @($spec.trainerIds)) {
            $baseEntry = Get-TrainerLevelCapEntry `
                -RomfsRoot $OutputRomfsRoot `
                -TrainerId ([int]$trainerId) `
                -BadgeCount -1 `
                -PatchSpeciesId -1 `
                -StageKey ([string]$spec.stageKey) `
                -StageLabelFr ([string]$spec.stageLabelFr) `
                -StageLabelEn ([string]$spec.stageLabelEn)

            $entries.Add([ordered]@{
                stageIndex = [int]$spec.stageIndex
                stageKey = [string]$baseEntry.stageKey
                category = [string]$spec.category
                variantKind = [string]$spec.variantKind
                trainerId = [int]$baseEntry.trainerId
                names = $baseEntry.names
                trainerClass = $baseEntry.trainerClass
                stageLabel = $baseEntry.stageLabel
                capLevel = [int]$baseEntry.capLevel
                teamSize = [int]$baseEntry.teamSize
                party = @($baseEntry.party)
            })
        }
    }

    return [object[]]$entries.ToArray()
}

function Get-MainStorySoftStageLabels {
    param([int]$BadgeCount)

    switch ($BadgeCount) {
        0 { return [ordered]@{ fr = "Progression principale souple - avant la 1ere arène"; en = "Soft main-story progression - before Gym 1" } }
        1 { return [ordered]@{ fr = "Progression principale souple - apres 1 badge"; en = "Soft main-story progression - after 1 badge" } }
        2 { return [ordered]@{ fr = "Progression principale souple - apres 2 badges"; en = "Soft main-story progression - after 2 badges" } }
        3 { return [ordered]@{ fr = "Progression principale souple - apres 3 badges"; en = "Soft main-story progression - after 3 badges" } }
        4 { return [ordered]@{ fr = "Progression principale souple - apres 4 badges"; en = "Soft main-story progression - after 4 badges" } }
        5 { return [ordered]@{ fr = "Progression principale souple - apres 5 badges"; en = "Soft main-story progression - after 5 badges" } }
        6 { return [ordered]@{ fr = "Progression principale souple - apres 6 badges"; en = "Soft main-story progression - after 6 badges" } }
        7 { return [ordered]@{ fr = "Progression principale souple - apres 7 badges"; en = "Soft main-story progression - after 7 badges" } }
        default { return [ordered]@{ fr = "Progression principale souple - après 8 badges / fin du jeu"; en = "Soft main-story progression - after 8 badges / endgame" } }
    }
}

function Get-MainStorySoftProgressionSpecs {
    param([string]$GameVersion)

    $bucketSpecs = @{}
    for ($badgeCount = 0; $badgeCount -le 8; $badgeCount++) {
        $bucketSpecs[$badgeCount] = New-Object System.Collections.Generic.List[object]
    }

    $gymsCleared = 0
    foreach ($spec in (Get-StoryMajorBattleProgressionSpecs -GameVersion $GameVersion)) {
        $category = [string]$spec.category
        if ($category -notin @("gym", "villain", "champion")) {
            continue
        }

        $badgeCount = [Math]::Max(0, [Math]::Min(8, $gymsCleared))
        $bucketSpecs[$badgeCount].Add([pscustomobject][ordered]@{
            stageIndex = [int]$spec.stageIndex
            stageKey = [string]$spec.stageKey
            category = $category
            variantKind = [string]$spec.variantKind
            trainerIds = @($spec.trainerIds | ForEach-Object { [int]$_ })
            stageLabel = [ordered]@{
                fr = [string]$spec.stageLabelFr
                en = [string]$spec.stageLabelEn
            }
        })

        if ($category -eq "gym") {
            $gymsCleared++
        }
    }

    $results = New-Object System.Collections.Generic.List[object]
    for ($badgeCount = 0; $badgeCount -le 8; $badgeCount++) {
        $stageLabels = Get-MainStorySoftStageLabels -BadgeCount $badgeCount
        $results.Add([ordered]@{
            badgeCount = $badgeCount
            patchSpeciesId = $GymLeagueStoryCapPatchSpeciesBase + $badgeCount
            stageKey = ("mainStorySoftBadge{0}" -f $badgeCount)
            stageLabelFr = [string]$stageLabels.fr
            stageLabelEn = [string]$stageLabels.en
            referenceBattles = [object[]]$bucketSpecs[$badgeCount].ToArray()
        })
    }

    return [object[]]$results.ToArray()
}

function Get-MainStorySoftCapEntries {
    param(
        [string]$SourceRomfsRoot,
        [string]$OutputRomfsRoot
    )

    $gameVersion = Get-SourceGameVersion -RomfsRoot $SourceRomfsRoot
    $entries = New-Object System.Collections.Generic.List[object]
    foreach ($bucket in (Get-MainStorySoftProgressionSpecs -GameVersion $gameVersion)) {
        $referenceBattles = New-Object System.Collections.Generic.List[object]
        $primaryBattle = $null
        $capLevel = 0
        $primaryCategory = ""

        foreach ($battle in (Convert-ToObjectArray $bucket.referenceBattles)) {
            foreach ($trainerId in @($battle.trainerIds)) {
                $battleEntry = Get-TrainerLevelCapEntry `
                    -RomfsRoot $OutputRomfsRoot `
                    -TrainerId ([int]$trainerId) `
                    -BadgeCount ([int]$bucket.badgeCount) `
                    -PatchSpeciesId ([int]$bucket.patchSpeciesId) `
                    -StageKey ([string]$battle.stageKey) `
                    -StageLabelFr ([string]$battle.stageLabel.fr) `
                    -StageLabelEn ([string]$battle.stageLabel.en)

                $referenceBattles.Add([ordered]@{
                    stageIndex = [int]$battle.stageIndex
                    stageKey = [string]$battle.stageKey
                    category = [string]$battle.category
                    variantKind = [string]$battle.variantKind
                    trainerId = [int]$battleEntry.trainerId
                    names = $battleEntry.names
                    trainerClass = $battleEntry.trainerClass
                    stageLabel = $battleEntry.stageLabel
                    capLevel = [int]$battleEntry.capLevel
                    teamSize = [int]$battleEntry.teamSize
                    party = @($battleEntry.party)
                })

                if ((-not $primaryBattle) -or ([int]$battleEntry.capLevel -gt $capLevel)) {
                    $primaryBattle = $battleEntry
                    $capLevel = [int]$battleEntry.capLevel
                    $primaryCategory = [string]$battle.category
                }
            }
        }

        if (-not $primaryBattle) {
            throw ("Impossible de calculer un cap progression principale souple pour badge {0}." -f ([int]$bucket.badgeCount))
        }

        $referenceBattleArray = [object[]]$referenceBattles.ToArray()
        $entries.Add([ordered]@{
            badgeCount = [int]$bucket.badgeCount
            patchSpeciesId = [int]$bucket.patchSpeciesId
            stageKey = [string]$bucket.stageKey
            trainerId = [int]$primaryBattle.trainerId
            names = $primaryBattle.names
            trainerClass = $primaryBattle.trainerClass
            stageLabel = [ordered]@{
                fr = [string]$bucket.stageLabelFr
                en = [string]$bucket.stageLabelEn
            }
            capLevel = [int]$capLevel
            primaryCategory = [string]$primaryCategory
            teamSize = [int]$primaryBattle.teamSize
            party = @($primaryBattle.party)
            sourceBattleCount = Get-ObjectArrayCount $referenceBattleArray
            # Pas Select-Object -ExpandProperty : les elements sont des
            # [ordered]@{...}, et ExpandProperty passe par la table de proprietes
            # PSObject, ou une cle de dictionnaire n'apparait pas. Il levait
            # « la propriete category est introuvable » et emportait toute la
            # suite - y compris le deploiement du module, donc config.toml.
            sourceCategories = @($referenceBattleArray | ForEach-Object { [string]$_.category } | Select-Object -Unique)
            primaryBattle = [ordered]@{
                trainerId = [int]$primaryBattle.trainerId
                names = $primaryBattle.names
                trainerClass = $primaryBattle.trainerClass
                stageLabel = $primaryBattle.stageLabel
                capLevel = [int]$primaryBattle.capLevel
                teamSize = [int]$primaryBattle.teamSize
                party = @($primaryBattle.party)
            }
            referenceBattles = $referenceBattleArray
        })
    }

    $resultatEntries = [object[]]$entries.ToArray()

    # Dire si le mode souple retombe sur le cap arenes/ligue.
    #
    # Le module n'applique qu'une table de neuf caps indexee par le nombre de
    # badges (exp_level_cap.hpp, GetCurrentCap). Le mode souple prend le niveau
    # MAXIMAL des gros combats de chaque fenetre. Mesure du 2026-09-07 sur les
    # 50 combats majeurs d'Epee : le champion d'arene est le plus fort de sa
    # fenetre a chaque fois, les rivaux etant 1 a 4 niveaux en dessous (Nabil 33
    # et Travis 35 contre Faiza 36). Les neuf paliers tombent donc sur les memes
    # valeurs que le cap arenes/ligue.
    #
    # On ne le suppose pas : on regarde quelle categorie a gagne chaque palier.
    $paliersArene = @($resultatEntries | Where-Object { [int]$_.badgeCount -le 7 -and [string]$_.primaryCategory -eq "gym" })
    if ((Get-ObjectArrayCount $paliersArene) -eq 8) {
        $valeurs = @($resultatEntries | ForEach-Object { [int]$_.capLevel })
        Write-Warning ("Cap « progression principale souple » : les huit premiers paliers sont remportés par le champion d'arène, donc les neuf valeurs ({0}) sont identiques à celles du cap arènes/ligue. Les deux options donnent le même résultat en jeu." -f ($valeurs -join ", "))
    }

    return $resultatEntries
}

function Get-Rng {
    param([int]$SeedValue)
    return [System.Random]::new((Resolve-SeedValue -SeedValue $SeedValue))
}

function Resolve-SeedValue {
    param([long]$SeedValue)

    if ($SeedValue -lt 0) {
        $ticks = [DateTime]::UtcNow.Ticks
        $seed64 = $ticks -bxor ($ticks -shr 32)
        return [int]($seed64 -band 0x7FFFFFFF)
    }

    if ($SeedValue -gt [int]::MaxValue) {
        return [int]($SeedValue % [int]::MaxValue)
    }

    return [int]$SeedValue
}

function Copy-RomfsTree {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Le dossier source '$Source' est introuvable."
    }

    Ensure-Directory -Path $Destination
    $null = & robocopy $Source $Destination /MIR /NFL /NDL /NJH /NJS /NP /R:1 /W:1
    if ($LASTEXITCODE -gt 7) {
        throw "Robocopy a échoue avec le code $LASTEXITCODE."
    }
}

function Get-PersonalPath {
    param([string]$RomfsRoot)
    return Join-Path $RomfsRoot "bin\pml\personal\personal_total.bin"
}

function Get-LearnsetPath {
    param([string]$RomfsRoot)
    return Join-Path $RomfsRoot "bin\pml\waza_oboe\wazaoboe_total.bin"
}

function Get-MoveDir {
    param([string]$RomfsRoot)
    return Join-Path $RomfsRoot "bin\pml\waza"
}

function Get-TrainerPokeDir {
    param([string]$RomfsRoot)
    return Join-Path $RomfsRoot "bin\trainer\trainer_poke"
}

function Get-TrainerDataDir {
    param([string]$RomfsRoot)
    return Join-Path $RomfsRoot "bin\trainer\trainer_data"
}

function Get-EvolutionDir {
    param([string]$RomfsRoot)
    return Join-Path $RomfsRoot "bin\pml\evolution"
}

function Get-AddPokePath {
    param([string]$RomfsRoot)
    return Join-Path $RomfsRoot "bin\script_event_data\add_poke.bin"
}

function Get-FieldTradePath {
    param([string]$RomfsRoot)
    return Join-Path $RomfsRoot "bin\script_event_data\field_trade.bin"
}

function Get-EventEncounterPath {
    param([string]$RomfsRoot)
    return Join-Path $RomfsRoot "bin\script_event_data\event_encount_data.bin"
}

function Get-FieldResidentDataTablePath {
    param([string]$RomfsRoot)
    return Join-Path $RomfsRoot "bin\archive\field\resident\data_table.gfpak"
}

function Get-SymbolEncountMonsParamPath {
    param([string]$RomfsRoot)
    return Join-Path $RomfsRoot "bin\field\param\symbol_encount_mons_param\symbol_encount_mons_param.bin"
}

function Get-SymbolHitboxTable {
    <#
        Rayon de collision de chaque espece en tant que symbole overworld, lu
        dans symbol_encount_mons_param.bin. C'est la mesure du jeu lui-meme :
        combien de place le Pokemon occupe une fois pose dans le decor.

        Indices FlatBuffer verifies sur un dump Epee (774 entrees, 664 especes) :
        champ 6 = rayon de collision (float), champ 13 = espece. Une espece a
        parfois plusieurs entrees (formes) : on garde la plus encombrante.

        C'est un meilleur critere que la taille du Pokedex : Rayquaza est
        enroule et ne fait que 70, alors que Leviator en fait 220.
    #>
    param([string]$RomfsRoot)

    if ($null -ne $script:SymbolHitboxTable) {
        return $script:SymbolHitboxTable
    }

    $table = @{}
    $path = Get-SymbolEncountMonsParamPath -RomfsRoot $RomfsRoot
    if ([string]::IsNullOrWhiteSpace($RomfsRoot) -or (-not (Test-Path -LiteralPath $path))) {
        # Table absente : on ne filtre rien plutot que de tout filtrer.
        $script:SymbolHitboxTable = $table
        return $table
    }

    try {
        $data = [IO.File]::ReadAllBytes($path)
        $root = Get-FlatBufferRootTablePosition -Data $data
        $entrees = @(Get-FlatBufferTableVectorEntries -Data $data -TablePos $root -FieldIndex 0)
        if ($entrees.Count -eq 0) {
            $entrees = @(Get-FlatBufferTableVectorEntries -Data $data -TablePos $root -FieldIndex 1)
        }
        foreach ($entree in $entrees) {
            $adresseEspece = Get-FlatBufferFieldAddress -Data $data -TablePos $entree -FieldIndex 13
            $adresseRayon = Get-FlatBufferFieldAddress -Data $data -TablePos $entree -FieldIndex 6
            if ($adresseEspece -lt 0 -or $adresseRayon -lt 0) {
                continue
            }
            $espece = [int](Read-U32 -Data $data -Offset $adresseEspece)
            if ($espece -le 0 -or $espece -gt $BaseSpeciesMax) {
                continue
            }
            $rayon = [double][BitConverter]::ToSingle($data, $adresseRayon)
            if ((-not $table.ContainsKey($espece)) -or $rayon -gt $table[$espece]) {
                $table[$espece] = $rayon
            }
        }
    } catch {
        $table = @{}
    }

    $script:SymbolHitboxTable = $table
    return $table
}

function Select-SpeciesByOverworldHitbox {
    param(
        [int[]]$SpeciesIds,
        [string]$RomfsRoot,
        [int]$MaxHitbox
    )

    if ($MaxHitbox -le 0) {
        return [int[]]$SpeciesIds
    }

    $table = Get-SymbolHitboxTable -RomfsRoot $RomfsRoot
    if ($table.Count -lt 1) {
        return [int[]]$SpeciesIds
    }

    # Une espece sans rayon connu est GARDEE : mieux vaut laisser passer un
    # inconnu que vider le reservoir sur une table incomplete.
    $retenu = @($SpeciesIds | Where-Object {
        (-not $table.ContainsKey([int]$_)) -or ($table[[int]$_] -le $MaxHitbox)
    })

    if ((Get-ObjectArrayCount $retenu) -lt 8) {
        return [int[]]$SpeciesIds
    }
    return [int[]]$retenu
}

function Get-UndergroundExplorationPokePath {
    param([string]$RomfsRoot)
    return Join-Path $RomfsRoot "bin\appli\chika\data_table\underground_exploration_poke.bin"
}

function Normalize-Mode {
    param([string]$Value)
    return ([string]$Value).Trim().ToLowerInvariant()
}

function Test-TrainerModeUsesSmogon {
    <#
        « smogon » tout court est accepte comme alias de « smogonstrategic ».

        L'interface n'envoie que "SmogonStrategic", mais en ligne de commande
        la valeur evidente est "Smogon" - et elle etait rejetee en silence :
        aucune branche ne s'executait, les attaques restaient celles du Pokemon
        remplace, et rien ne le signalait. Mesure du 2026-09-07 : 0 attaque
        modifiee sur 1223 avec -TrainerMoveMode 'Smogon', contre 100 % avec
        'SmogonStrategic'.
    #>
    param([string]$Mode)
    return ((Normalize-Mode $Mode) -in @("smogon", "smogonstrategic", "smogonlegacy", "smogonhistory", "smogonhistorical", "smogonancien", "smogonanciennegen", "smogonanciennesgens"))
}

function Test-TrainerModeUsesSmogonLegacy {
    param([string]$Mode)
    return ((Normalize-Mode $Mode) -in @("smogonlegacy", "smogonhistory", "smogonhistorical", "smogonancien", "smogonanciennegen", "smogonanciennesgens"))
}

function Get-CanonicalSmogonTrainerMode {
    param([string]$Mode)

    $normalized = Normalize-Mode $Mode
    if ($normalized -in @("smogonlegacy", "smogonhistory", "smogonhistorical", "smogonancien", "smogonanciennegen", "smogonanciennesgens")) {
        return "smogonlegacy"
    }
    if ($normalized -eq "smogonstrategic") {
        return "smogonstrategic"
    }
    return $normalized
}

function Get-EffectiveTrainerNatureMode {
    param(
        [string]$Mode,
        [bool]$LegacyRandomize
    )

    $normalized = Normalize-Mode $Mode
    switch ($normalized) {
        "random" { return "random" }
        "randomnature" { return "random" }
        "randomnatures" { return "random" }
        "aleatoire" { return "random" }
        "alÃ©atoire" { return "random" }
        "smogon" { return "smogonstrategic" }
        "smogonstrategic" { return "smogonstrategic" }
        "strategicsmogon" { return "smogonstrategic" }
        "strategique" { return "smogonstrategic" }
        "strategiquesmogon" { return "smogonstrategic" }
        "stratÃ©gique" { return "smogonstrategic" }
        "stratÃ©giquesmogon" { return "smogonstrategic" }
        "smogonlegacy" { return "smogonlegacy" }
        "smogonhistory" { return "smogonlegacy" }
        "smogonhistorical" { return "smogonlegacy" }
        "smogonancien" { return "smogonlegacy" }
        "smogonanciennegen" { return "smogonlegacy" }
        "smogonanciennesgens" { return "smogonlegacy" }
        default {
            if ($LegacyRandomize) {
                return "random"
            }
            return "unchanged"
        }
    }
}

function Normalize-StableMappingMode {
    param([string]$Value)

    $normalized = ([string]$Value).Trim().ToLowerInvariant()
    switch ($normalized) {
        "random" { return "random" }
        "truerandom" { return "random" }
        "true-random" { return "random" }
        "vrairandom" { return "random" }
        "vrai-random" { return "random" }
        "none" { return "random" }
        "unstable" { return "random" }
        "species" { return "species" }
        "espece" { return "species" }
        "espÃ¨ce" { return "species" }
        "slot" { return "slot" }
        default { return "slot" }
    }
}

function Random-FromPool {
    param(
        [System.Random]$Rng,
        [int[]]$Pool
    )
    if (-not $Pool -or $Pool.Count -eq 0) {
        throw "Pool vide."
    }
    return $Pool[$Rng.Next(0, $Pool.Count)]
}

function Shuffle-Ints {
    param(
        [System.Random]$Rng,
        [int[]]$Values
    )

    for ($i = $Values.Length - 1; $i -gt 0; $i--) {
        $j = $Rng.Next(0, $i + 1)
        $tmp = $Values[$i]
        $Values[$i] = $Values[$j]
        $Values[$j] = $tmp
    }
    return $Values
}

function Test-IsLegendarySpecies {
    param([int]$SpeciesId)
    return $LegendarySpeciesIds.Contains($SpeciesId)
}

function Get-PersonalEntries {
    param([string]$RomfsRoot)

    $path = Get-PersonalPath -RomfsRoot $RomfsRoot
    $bytes = [IO.File]::ReadAllBytes($path)
    $count = [int]($bytes.Length / $PersonalRecordSize)
    $entries = New-Object System.Collections.Generic.List[object]

    for ($index = 0; $index -lt $count; $index++) {
        $offset = $index * $PersonalRecordSize
        $bst = [int]$bytes[$offset + 0] + [int]$bytes[$offset + 1] + [int]$bytes[$offset + 2] + [int]$bytes[$offset + 3] + [int]$bytes[$offset + 4] + [int]$bytes[$offset + 5]
        $entry = [pscustomobject]@{
            Index = $index
            HP = $bytes[$offset + 0]
            ATK = $bytes[$offset + 1]
            DEF = $bytes[$offset + 2]
            SPE = $bytes[$offset + 3]
            SPA = $bytes[$offset + 4]
            SPD = $bytes[$offset + 5]
            Type1 = $bytes[$offset + 6]
            Type2 = $bytes[$offset + 7]
            Ability1 = Read-U16 -Data $bytes -Offset ($offset + 0x18)
            Ability2 = Read-U16 -Data $bytes -Offset ($offset + 0x1A)
            AbilityH = Read-U16 -Data $bytes -Offset ($offset + 0x1C)
            FormStatsIndex = Read-U16 -Data $bytes -Offset ($offset + 0x1E)
            IsInGame = $bst -gt 0
            BST = $bst
        }
        $entries.Add($entry)
    }

    return $entries
}

function Get-LearnsetTable {
    param([string]$RomfsRoot)

    $path = Get-LearnsetPath -RomfsRoot $RomfsRoot
    if (-not (Test-Path -LiteralPath $path)) {
        return @()
    }

    $bytes = [IO.File]::ReadAllBytes($path)
    $count = [int]($bytes.Length / $LearnsetRecordSize)
    $table = New-Object System.Collections.Generic.List[object]

    for ($index = 0; $index -lt $count; $index++) {
        $offset = $index * $LearnsetRecordSize
        $moves = New-Object System.Collections.Generic.List[object]
        for ($cursor = 0; $cursor -lt $LearnsetRecordSize; $cursor += 4) {
            $moveId = Read-U16 -Data $bytes -Offset ($offset + $cursor)
            $level = Read-U16 -Data $bytes -Offset ($offset + $cursor + 2)
            if ($moveId -eq 0xFFFF -and $level -eq 0xFFFF) {
                break
            }
            if ($moveId -gt 0 -and $moveId -ne 0xFFFF) {
                $moves.Add([pscustomobject]@{ MoveId = $moveId; Level = $level })
            }
        }
        $table.Add(@($moves))
    }

    return @($table)
}

function Get-LearnsetBytes {
    param([string]$RomfsRoot)

    $path = Get-LearnsetPath -RomfsRoot $RomfsRoot
    if (-not (Test-Path -LiteralPath $path)) {
        return $null
    }

    return [IO.File]::ReadAllBytes($path)
}

# Une entree d'attaque dont l'enregistrement fait 64 octets ou moins est un
# CROUPION : la structure y est tronquee, l'attaque n'existe pas vraiment dans
# ce jeu. Sur Epee 1.3.2 il y en a 39, dont le bloc contigu 622-657 - les
# attaques Z, presentes en donnees mais retirees en 8e generation.
#
# Le seuil n'est pas devine, il est MESURE. En croisant la taille de chaque
# enregistrement avec l'usage reel du jeu - learnsets, equipes de dresseurs,
# table CT/DT - la coupure tombe exactement la :
#
#     <= 64 octets : 39 fichiers,   0 utilise par le jeu
#     >= 68 octets : 788 fichiers, l'usage commence
#
# Sans ce filtre, Get-MovePool rendait 1..826 en aveugle et le mode
# « 4 attaques aleatoires » distribuait ces croupions : 218 des 2622
# emplacements d'une generation chaos, soit 8 %. Trouve en relisant les sorties
# avec le dex du visualiseur de l'utilisateur, qui ne savait pas les nommer.
$MoveStubRecordMaxSize = 64

function Get-MovePool {
    param([string]$RomfsRoot)
    $moveDir = Get-MoveDir -RomfsRoot $RomfsRoot
    $fichiers = @(Get-ChildItem -LiteralPath $moveDir -Filter "*.wazabin" -File)
    $pool = New-Object System.Collections.Generic.List[int]
    foreach ($f in $fichiers) {
        if ($f.BaseName -notmatch '(\d+)\s*$') { continue }
        $id = [int]$Matches[1]
        if ($id -le 0) { continue }
        if ($f.Length -le $MoveStubRecordMaxSize) { continue }
        $pool.Add($id)
    }
    if ($pool.Count -lt 1) {
        # Repli sur l'ancien comportement plutot que de rendre un pool vide,
        # qui rendrait le mode « 4 attaques aleatoires » silencieusement inerte.
        return 1..([Math]::Max(1, $fichiers.Count - 1))
    }
    return [int[]]($pool.ToArray() | Sort-Object)
}

function Get-BaseSpeciesPool {
    param(
        [bool]$AllowLegendaries,
        [string]$RomfsRoot = ""
    )

    $pool = @()
    if (-not [string]::IsNullOrWhiteSpace($RomfsRoot) -and (Test-Path -LiteralPath (Get-PersonalPath -RomfsRoot $RomfsRoot))) {
        $entries = Get-PersonalEntries -RomfsRoot $RomfsRoot
        $max = [Math]::Min($BaseSpeciesMax, $entries.Count - 1)
        $playable = New-Object System.Collections.Generic.List[int]
        for ($i = 1; $i -le $max; $i++) {
            if ($entries[$i].IsInGame) {
                $playable.Add($i)
            }
        }
        $pool = [int[]]$playable.ToArray()
    } else {
        $pool = 1..$BaseSpeciesMax
    }

    if ($AllowLegendaries) {
        return $pool
    }
    return @($pool | Where-Object { -not (Test-IsLegendarySpecies $_) })
}

function Get-SymbolEncounterSpeciesPool {
    param(
        [string]$RomfsRoot,
        [bool]$AllowLegendaries
    )

    $speciesIds = [System.Collections.Generic.HashSet[int]]::new()
    if ([string]::IsNullOrWhiteSpace($RomfsRoot)) {
        return @()
    }

    $path = Get-FieldResidentDataTablePath -RomfsRoot $RomfsRoot
    if (-not (Test-Path -LiteralPath $path)) {
        return @()
    }

    try {
        $pack = Read-Gfpak -Path $path
        foreach ($internalFile in @("encount_symbol_k.bin", "encount_symbol_t.bin")) {
            $archiveData = Get-GfpakDataFileName -Pack $pack -Name $internalFile
            if ($null -eq $archiveData) {
                continue
            }

            $root = Get-FlatBufferRootTablePosition -Data $archiveData
            foreach ($tablePos in @(Get-FlatBufferTableVectorEntries -Data $archiveData -TablePos $root -FieldIndex 1)) {
                foreach ($subTablePos in @(Get-FlatBufferTableVectorEntries -Data $archiveData -TablePos $tablePos -FieldIndex 1)) {
                    foreach ($slotPos in @(Get-FlatBufferTableVectorEntries -Data $archiveData -TablePos $subTablePos -FieldIndex 2)) {
                        $speciesAddress = Get-FlatBufferFieldAddress -Data $archiveData -TablePos $slotPos -FieldIndex 1
                        if ($speciesAddress -lt 0) {
                            continue
                        }

                        $speciesId = [int](Read-U32 -Data $archiveData -Offset $speciesAddress)
                        if ($speciesId -gt 0 -and $speciesId -le $BaseSpeciesMax) {
                            $null = $speciesIds.Add($speciesId)
                        }
                    }
                }
            }
        }
    } catch {
        return @()
    }

    $pool = @($speciesIds | Sort-Object)
    if (-not $AllowLegendaries) {
        $pool = @($pool | Where-Object { -not (Test-IsLegendarySpecies $_) })
    }
    return [int[]]$pool
}

function Get-OverworldVisualSpeciesPool {
    param(
        [string]$RomfsRoot,
        [bool]$AllowLegendaries
    )

    $symbolPool = @(Get-SymbolEncounterSpeciesPool -RomfsRoot $RomfsRoot -AllowLegendaries $AllowLegendaries)
    if ($symbolPool.Count -gt 0) {
        return [int[]]$symbolPool
    }

    $speciesIds = [System.Collections.Generic.HashSet[int]]::new()
    if (-not [string]::IsNullOrWhiteSpace($RomfsRoot) -and (Test-Path -LiteralPath $RomfsRoot)) {
        $roots = @(
            (Join-Path $RomfsRoot "bin\pokemon"),
            (Join-Path $RomfsRoot "bin\archive\pokemon"),
            (Join-Path $RomfsRoot "bin\field\pokemon"),
            (Join-Path $RomfsRoot "bin\archive\field")
        )
        foreach ($root in $roots) {
            if (-not (Test-Path -LiteralPath $root)) {
                continue
            }
            Get-ChildItem -LiteralPath $root -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.Name -match 'pm(\d{4})_(\d{2})') {
                    $id = [int]$Matches[1]
                    if ($id -gt 0 -and $id -le $BaseSpeciesMax) {
                        $null = $speciesIds.Add($id)
                    }
                }
            }
        }
    }

    if ($speciesIds.Count -eq 0) {
        return @()
    }

    $pool = @($speciesIds | Sort-Object)
    if (-not $AllowLegendaries) {
        $pool = @($pool | Where-Object { -not (Test-IsLegendarySpecies $_) })
    }
    return [int[]]$pool
}

function Assert-PlayableSpeciesIds {
    param(
        [string]$RomfsRoot,
        [int[]]$SpeciesIds,
        [string]$Context = "Pokemon"
    )

    if (-not $SpeciesIds -or $SpeciesIds.Count -lt 1) {
        return
    }

    $entries = Get-PersonalEntries -RomfsRoot $RomfsRoot
    foreach ($speciesId in $SpeciesIds) {
        if ($speciesId -le 0 -or $speciesId -ge $entries.Count -or -not $entries[$speciesId].IsInGame) {
            throw ("{0}: {1} ({2}) n'est pas marque jouable dans les données Sword/Shield. Choisis une espèce présente dans le jeu pour éviter les oeufs/modeles invalides." -f $Context, (Get-SpeciesDisplayName -SpeciesId $speciesId -Language "fr"), $speciesId)
        }
    }
}

function Get-AbilityPool {
    param(
        [System.Collections.Generic.List[object]]$PersonalEntries,
        [bool]$AllowWonderGuard
    )

    $pool = New-Object System.Collections.Generic.HashSet[int]
    foreach ($entry in $PersonalEntries) {
        foreach ($ability in @($entry.Ability1, $entry.Ability2, $entry.AbilityH)) {
            if ($ability -gt 0) {
                if ($AllowWonderGuard -or $ability -ne $WonderGuardAbilityId) {
                    $null = $pool.Add($ability)
                }
            }
        }
    }
    return @($pool | Sort-Object)
}

function Get-TrainerItemPool {
    param(
        [string]$RomfsRoot,
        [string]$PoolMode = "Battle"
    )

    $poolModeValue = (Normalize-Mode $PoolMode)
    $itemData = Get-ItemData
    $estComplet = $poolModeValue -in @("full", "fullrandom", "all", "any", "complete", "complet")

    # Les deux modes different par leur SOURCE, pas par un filtre de categorie :
    #
    #   Complet  tout ce qui existe dans le jeu, sauf ce qu'un Pokemon ne peut
    #            pas tenir utilement (machines, objets cles, Balls)
    #   Combat   la liste curee d'objets a effet en combat, PURGEE de ce qui
    #            n'existe pas dans cette version
    #
    # Avant items.csv, les deux rendaient la meme liste de 139 identifiants dont
    # 45 designaient des objets absents du jeu. Le mode etait donc a la fois
    # inoperant et faux.
    $heldItems = New-Object System.Collections.Generic.HashSet[int]
    $poches = @{}
    foreach ($entry in @($itemData.Rows)) {
        if ($null -eq $entry) { continue }
        $itemId = [int]$entry.id
        if ($itemId -le 0) { continue }
        $poches[$itemId] = [int]$entry.categoryId
    }

    $candidats = if ($estComplet) { [int[]]@($poches.Keys) } else { Select-ExistingItemIds -Ids $FallbackTrainerHeldItemPool }
    # 300 des 964 objets du jeu portent un nom de debogage (« ★And390 ») : le
    # mode « complet » les prenait tous. Ils sont tous en poche 4.
    $sansNomTenus = Get-PlaceholderItemIds
    foreach ($itemId in $candidats) {
        if ($sansNomTenus.Contains([int]$itemId)) { continue }
        if ($poches.ContainsKey($itemId) -and $TrainerHeldItemExcludedPockets.Contains($poches[$itemId])) {
            continue
        }
        $null = $heldItems.Add([int]$itemId)
    }

    $pool = @($heldItems | Sort-Object)
    if ($pool.Count -gt 0) {
        return $pool
    }

    # Repli. Il ne depend pas de $PoolMode : le mode demande est donc ignore.
    # On le dit une fois par execution plutot que de laisser croire que le
    # reglage a ete pris en compte.
    if (-not $script:TrainerItemPoolFallbackWarned) {
        $script:TrainerItemPoolFallbackWarned = $true
        Write-Host ("[Données] Pool d'objets tenus construit a partir du repli code en dur ({0} objets) : items.csv est absent, donc le mode '{1}' est sans effet." -f (Get-ObjectArrayCount $FallbackTrainerHeldItemPool), $PoolMode)
    }

    if ((Get-ObjectArrayCount $FallbackTrainerHeldItemPool) -gt 0) {
        return $FallbackTrainerHeldItemPool
    }

    return @(211)
}

function Get-RandomTrainerHeldItem {
    param(
        [System.Random]$Rng,
        [int[]]$Pool,
        [System.Collections.Generic.HashSet[int]]$UsedItemIds = $null
    )

    if (-not $Pool -or $Pool.Count -lt 1) {
        throw "Pool d'objets tenu vide."
    }

    $candidatePool = @($Pool)
    if (($null -ne $UsedItemIds) -and $UsedItemIds.Count -lt $Pool.Count) {
        $filteredPool = @($Pool | Where-Object { -not $UsedItemIds.Contains([int]$_) })
        if ($filteredPool.Count -gt 0) {
            $candidatePool = $filteredPool
        }
    }

    $itemId = [int](Random-FromPool -Rng $Rng -Pool ([int[]]$candidatePool))
    if ($null -ne $UsedItemIds) {
        $null = $UsedItemIds.Add($itemId)
    }
    return $itemId
}

# ---------------------------------------------------------------------------
# REGLES SPECIALES DE DRESSEURS
#
# Trois classes, reprises de la terminologie du Universal Pokemon Randomizer :
#   Boss      : champions d'arene, Conseil 4, Maitre
#   Important : rivaux, admins et chefs d'equipe
#   Normal    : tous les autres
#
# Les regles (legendaires, total de statistiques minimum) se traduisent par un
# simple filtrage du reservoir d'especes. C'est volontairement le meme
# mecanisme que les equipes mono-type : on remplace le pool et le reste du code
# n'a pas besoin de savoir qu'une regle est active.
# ---------------------------------------------------------------------------

function Get-TrainerRulePoolContext {
    param(
        [int[]]$SourcePool,
        [int[]]$FallbackSourcePool = @(),
        [hashtable]$SpeciesEntries,
        [string]$LegendaryPolicy = "unchanged",
        [int]$MinBaseStatTotal = 0
    )

    $policy = Normalize-Mode $LegendaryPolicy
    $applyPool = {
        param([int[]]$Candidates)

        $pool = @($Candidates)
        if ($pool.Count -lt 1) {
            return @()
        }

        if ($policy -eq "all") {
            $pool = @($pool | Where-Object { Test-IsLegendarySpecies ([int]$_) })
        } elseif ($policy -eq "none") {
            $pool = @($pool | Where-Object { -not (Test-IsLegendarySpecies ([int]$_)) })
        }
        if ($pool.Count -lt 1) {
            return @()
        }

        if ($MinBaseStatTotal -gt 0) {
            $strong = @($pool | Where-Object {
                $entry = $SpeciesEntries[[int]$_]
                $entry -and ([int]$entry.BST) -ge $MinBaseStatTotal
            })
            # Un seuil trop haut viderait le reservoir. Plutot que de ne rien
            # pouvoir choisir, on garde les especes les plus fortes disponibles.
            if ($strong.Count -lt 3) {
                $strong = @($pool |
                    Sort-Object { - [int]$SpeciesEntries[[int]$_].BST } |
                    Select-Object -First 12)
            }
            $pool = $strong
        }

        return @($pool)
    }

    $result = @(& $applyPool ([int[]]$SourcePool))

    # Exiger des legendaires alors que le reservoir courant les exclut (case
    # "legendaires autorises" decochee, ou equipe mono-type) ne doit pas donner
    # un pool vide : on repart alors du reservoir complet.
    if ($result.Count -lt 1 -and $FallbackSourcePool -and $FallbackSourcePool.Count -gt 0) {
        $result = @(& $applyPool ([int[]]$FallbackSourcePool))
    }

    if ($result.Count -lt 1) {
        return $null
    }

    return @{
        BaseSpeciesPool = [int[]]$result
        BaseSpeciesEntries = $SpeciesEntries
        SimilarBstCache = @{}
    }
}

# Reservoir restreint aux especes dont AUCUN type n'est deja pris dans
# l'equipe. Rend $null quand plus rien ne convient : on cesse alors d'imposer
# la contrainte pour les emplacements restants, plutot que de ne rien pouvoir
# placer. Une equipe de six ne peut de toute facon pas couvrir douze types
# distincts sans finir par manquer de candidats.
function Get-DiverseTypeContext {
    param(
        [hashtable]$Context,
        [System.Collections.Generic.HashSet[int]]$UsedTypeIds
    )

    if ($null -eq $UsedTypeIds -or $UsedTypeIds.Count -lt 1) {
        return $null
    }

    $pool = @($Context.BaseSpeciesPool | Where-Object {
        $entry = $Context.BaseSpeciesEntries[[int]$_]
        $entry -and
            (-not $UsedTypeIds.Contains([int]$entry.Type1)) -and
            (-not $UsedTypeIds.Contains([int]$entry.Type2))
    })
    if ($pool.Count -lt 1) {
        return $null
    }

    return @{
        BaseSpeciesPool = [int[]]$pool
        BaseSpeciesEntries = $Context.BaseSpeciesEntries
        SimilarBstCache = @{}
    }
}

function Normalize-TrainerSpecialRuleScope {
    param([string]$Scope)

    switch (Normalize-Mode $Scope) {
        "everyone" { return "Everyone" }
        "all" { return "Everyone" }
        "alltrainers" { return "Everyone" }
        "allbosses" { return "AllBosses" }
        "majorbosses" { return "AllBosses" }
        default { return "GymLeague" }
    }
}

function Normalize-TrainerLegendaryPolicy {
    param([string]$Policy)

    switch (Normalize-Mode $Policy) {
        "none" { return "none" }
        "nolegendaries" { return "none" }
        "oneeach" { return "oneeach" }
        "one" { return "oneeach" }
        "all" { return "all" }
        "alllegendaries" { return "all" }
        default { return "unchanged" }
    }
}

# Contraintes appliquees aux cibles d'evolution : le remplacant doit etre plus
# fort que la forme de base, et/ou partager un de ses types.
#
# Le reservoir filtre est mis en cache par espece source : sans cela on
# refiltrerait 800 especes pour chacun des 1192 fichiers d'evolution.
#
# Si une contrainte ne laisse aucun candidat, on rend le reservoir d'origine
# plutot qu'un pool vide : mieux vaut une evolution non contrainte qu'une
# evolution impossible.
function Get-EvolutionConstrainedContext {
    <#
        Les regles d'evolution se CUMULENT : meme type, et gain minimal de
        statistiques. Un gain minimal de 0 veut dire « au moins equivalent ».

        Le repli est PROGRESSIF, et c'est important : si aucun Pokemon ne
        satisfait les deux regles a la fois, on relache la moins structurante
        (le seuil de statistiques) avant d'abandonner le type, puis seulement en
        dernier recours on rend le reservoir complet. Rendre tout de suite le
        reservoir complet - ce que faisait la version precedente - jetait la
        contrainte de type alors qu'elle etait souvent tenable seule.

        On ne boucle jamais : chaque etape est un filtre, pas un tirage repete.
    #>
    param(
        [hashtable]$Context,
        [int]$SourceSpeciesId,
        [bool]$ForceGrowth,
        [bool]$SameType,
        [int]$MinBstGain = -1,
        [hashtable]$Cache
    )

    # ForceGrowth est l'ancienne forme de « strictement mieux » : un gain de 1.
    $gainMinimal = if ($MinBstGain -ge 0) { [int]$MinBstGain } elseif ($ForceGrowth) { 1 } else { -1 }
    if ($gainMinimal -lt 0 -and -not $SameType) {
        return $Context
    }
    if ($Cache.ContainsKey($SourceSpeciesId)) {
        return $Cache[$SourceSpeciesId]
    }

    $source = $Context.BaseSpeciesEntries[$SourceSpeciesId]
    if (-not $source) {
        $Cache[$SourceSpeciesId] = $Context
        return $Context
    }

    $entrees = $Context.BaseSpeciesEntries
    $sourceBst = [int]$source.BST
    $t1 = [int]$source.Type1
    $t2 = [int]$source.Type2

    $filtreBst = {
        param($liste)
        if ($gainMinimal -lt 0) { return @($liste) }
        return @($liste | Where-Object {
            $entry = $entrees[[int]$_]
            $entry -and ([int]$entry.BST -ge ($sourceBst + $gainMinimal))
        })
    }
    $filtreType = {
        param($liste)
        if (-not $SameType) { return @($liste) }
        return @($liste | Where-Object {
            $entry = $entrees[[int]$_]
            $entry -and (
                ([int]$entry.Type1 -eq $t1) -or ([int]$entry.Type1 -eq $t2) -or
                ([int]$entry.Type2 -eq $t1) -or ([int]$entry.Type2 -eq $t2)
            )
        })
    }

    $complet = @($Context.BaseSpeciesPool)
    # Du plus contraint au moins contraint. Le type passe avant le seuil parce
    # qu'un Pikachu qui devient electrique reste lisible meme un peu plus faible,
    # alors qu'un Pikachu devenu Magicarpe casse la regle qu'on a demandee.
    $tentatives = @(
        @(& $filtreType (& $filtreBst $complet)),
        @(& $filtreType $complet),
        @(& $filtreBst $complet),
        $complet
    )

    $pool = $complet
    foreach ($tentative in $tentatives) {
        if ((Get-ObjectArrayCount $tentative) -ge 1) {
            $pool = @($tentative)
            break
        }
    }

    $result = if ($pool.Count -lt 1) {
        $Context
    } else {
        @{
            BaseSpeciesPool = [int[]]$pool
            BaseSpeciesEntries = $Context.BaseSpeciesEntries
            SimilarBstCache = @{}
        }
    }
    $Cache[$SourceSpeciesId] = $result
    return $result
}

function Get-SpeciesReplacementPool {
    param(
        [int]$CurrentSpeciesId,
        [string]$Mode,
        [hashtable]$Context
    )

    switch (Normalize-Mode $Mode) {
        "random" {
            return [int[]]$Context.BaseSpeciesPool
        }
        "similarbst" {
            if (-not $Context.SimilarBstCache.ContainsKey($CurrentSpeciesId)) {
                $targetBst = $Context.BaseSpeciesEntries[$CurrentSpeciesId].BST
                $candidates = New-Object System.Collections.Generic.List[int]
                foreach ($candidateSpeciesId in $Context.BaseSpeciesPool) {
                    if ([Math]::Abs($Context.BaseSpeciesEntries[$candidateSpeciesId].BST - $targetBst) -le 55) {
                        $candidates.Add($candidateSpeciesId)
                    }
                }
                if ($candidates.Count -eq 0) {
                    $ordered = $Context.BaseSpeciesPool | Sort-Object { [Math]::Abs($Context.BaseSpeciesEntries[$_].BST - $targetBst) }
                    $candidates = [System.Collections.Generic.List[int]]::new()
                    foreach ($candidateSpeciesId in ($ordered | Select-Object -First 40)) {
                        $candidates.Add([int]$candidateSpeciesId)
                    }
                }
                $Context.SimilarBstCache[$CurrentSpeciesId] = [int[]]$candidates.ToArray()
            }
            return [int[]]$Context.SimilarBstCache[$CurrentSpeciesId]
        }
        default {
            return [int[]]@($CurrentSpeciesId)
        }
    }
}

function Get-SpeciesReplacement {
    param(
        [System.Random]$Rng,
        [int]$CurrentSpeciesId,
        [string]$Mode,
        [hashtable]$Context,
        [System.Collections.Generic.HashSet[int]]$ExcludedSpeciesIds = $null
    )

    $candidatePool = @(Get-SpeciesReplacementPool -CurrentSpeciesId $CurrentSpeciesId -Mode $Mode -Context $Context)
    if ($ExcludedSpeciesIds -and $candidatePool.Count -gt 0) {
        $filteredPool = @($candidatePool | Where-Object { -not $ExcludedSpeciesIds.Contains([int]$_) })
        if ($filteredPool.Count -gt 0) {
            $candidatePool = $filteredPool
        }
    }

    return Random-FromPool -Rng $Rng -Pool $candidatePool
}

function Get-StableSpeciesReplacement {
    param(
        [System.Random]$Rng,
        [int]$CurrentSpeciesId,
        [string]$Mode,
        [hashtable]$Context,
        [hashtable]$StableMap,
        [string]$StableKey
    )

    if ([string]::IsNullOrWhiteSpace($StableKey)) {
        return Get-SpeciesReplacement -Rng $Rng -CurrentSpeciesId $CurrentSpeciesId -Mode $Mode -Context $Context
    }

    if (-not $StableMap.ContainsKey($StableKey)) {
        $StableMap[$StableKey] = Get-SpeciesReplacement -Rng $Rng -CurrentSpeciesId $CurrentSpeciesId -Mode $Mode -Context $Context
    }

    return [int]$StableMap[$StableKey]
}

function Get-EffectiveTrainerSpeciesId {
    param(
        [int]$SpeciesId,
        [int]$Level,
        [bool]$DoForceFullyEvolved,
        [int]$ForceEvolutionLevel,
        [hashtable]$EvolutionTargetsBySpecies,
        [System.Random]$Rng,
        [bool]$AllowLegendarySpecies
    )

    if (
        $DoForceFullyEvolved -and
        $Level -ge $ForceEvolutionLevel -and
        $SpeciesId -gt 0 -and
        $SpeciesId -le $BaseSpeciesMax
    ) {
        return Get-FinalEvolutionSpecies -SpeciesId $SpeciesId -TargetsBySpecies $EvolutionTargetsBySpecies -Rng $Rng -AllowLegendarySpecies $AllowLegendarySpecies
    }

    return $SpeciesId
}

function Test-SpeciesHasTypeId {
    param(
        [int]$SpeciesId,
        [int]$TypeId,
        [hashtable]$Context
    )

    if ($TypeId -lt 0) {
        return $true
    }
    if (-not $Context -or -not $Context.BaseSpeciesEntries.ContainsKey($SpeciesId)) {
        return $false
    }

    $entry = $Context.BaseSpeciesEntries[$SpeciesId]
    return ($entry -and ([int]$entry.Type1 -eq $TypeId -or [int]$entry.Type2 -eq $TypeId))
}

function Get-FinalEvolutionSpeciesCandidates {
    param(
        [int]$SpeciesId,
        [hashtable]$TargetsBySpecies,
        [bool]$AllowLegendarySpecies
    )

    $results = [System.Collections.Generic.HashSet[int]]::new()
    $visited = [System.Collections.Generic.HashSet[int]]::new()
    $stack = [System.Collections.Generic.Stack[int]]::new()
    $stack.Push($SpeciesId)

    while ($stack.Count -gt 0) {
        $current = [int]$stack.Pop()
        if (-not $visited.Add($current)) {
            continue
        }

        $next = @()
        if ($TargetsBySpecies.ContainsKey($current)) {
            $next = @($TargetsBySpecies[$current] | Where-Object { $AllowLegendarySpecies -or (-not $LegendarySpeciesIds.Contains([int]$_)) })
        }

        if ($next.Count -lt 1) {
            $null = $results.Add($current)
            continue
        }

        foreach ($target in $next) {
            $stack.Push([int]$target)
        }
    }

    return [int[]]@($results | Sort-Object)
}

function Get-FinalEvolutionSpeciesForRequiredType {
    param(
        [int]$SpeciesId,
        [hashtable]$TargetsBySpecies,
        [System.Random]$Rng,
        [bool]$AllowLegendarySpecies,
        [int]$RequiredTypeId,
        [hashtable]$Context
    )

    if ($RequiredTypeId -lt 0) {
        return Get-FinalEvolutionSpecies -SpeciesId $SpeciesId -TargetsBySpecies $TargetsBySpecies -Rng $Rng -AllowLegendarySpecies $AllowLegendarySpecies
    }

    $finals = @(Get-FinalEvolutionSpeciesCandidates -SpeciesId $SpeciesId -TargetsBySpecies $TargetsBySpecies -AllowLegendarySpecies $AllowLegendarySpecies)
    $matchingFinals = @($finals | Where-Object { Test-SpeciesHasTypeId -SpeciesId ([int]$_) -TypeId $RequiredTypeId -Context $Context })
    if ($matchingFinals.Count -gt 0) {
        return [int](Random-FromPool -Rng $Rng -Pool ([int[]]$matchingFinals))
    }
    if ($finals.Count -gt 0) {
        return [int](Random-FromPool -Rng $Rng -Pool ([int[]]$finals))
    }

    return $SpeciesId
}

function Test-TrainerSpeciesCandidateMatchesRequiredType {
    param(
        [int]$CandidateSpeciesId,
        [int]$Level,
        [int]$RequiredTypeId,
        [hashtable]$Context,
        [bool]$DoForceFullyEvolved,
        [int]$ForceEvolutionLevel,
        [hashtable]$EvolutionTargetsBySpecies,
        [bool]$AllowLegendarySpecies
    )

    if ($RequiredTypeId -lt 0) {
        return $true
    }

    if ($DoForceFullyEvolved -and $Level -ge $ForceEvolutionLevel) {
        $finals = @(Get-FinalEvolutionSpeciesCandidates -SpeciesId $CandidateSpeciesId -TargetsBySpecies $EvolutionTargetsBySpecies -AllowLegendarySpecies $AllowLegendarySpecies)
        foreach ($finalSpecies in $finals) {
            if (Test-SpeciesHasTypeId -SpeciesId ([int]$finalSpecies) -TypeId $RequiredTypeId -Context $Context) {
                return $true
            }
        }
        return $false
    }

    return Test-SpeciesHasTypeId -SpeciesId $CandidateSpeciesId -TypeId $RequiredTypeId -Context $Context
}

function Get-TrainerSpeciesPoolMatchingRequiredType {
    param(
        [int[]]$Pool,
        [int]$Level,
        [int]$RequiredTypeId,
        [hashtable]$Context,
        [bool]$DoForceFullyEvolved,
        [int]$ForceEvolutionLevel,
        [hashtable]$EvolutionTargetsBySpecies,
        [bool]$AllowLegendarySpecies
    )

    if ($RequiredTypeId -lt 0) {
        return [int[]]@($Pool)
    }

    $filtered = @($Pool | Where-Object {
        Test-TrainerSpeciesCandidateMatchesRequiredType `
            -CandidateSpeciesId ([int]$_) `
            -Level $Level `
            -RequiredTypeId $RequiredTypeId `
            -Context $Context `
            -DoForceFullyEvolved $DoForceFullyEvolved `
            -ForceEvolutionLevel $ForceEvolutionLevel `
            -EvolutionTargetsBySpecies $EvolutionTargetsBySpecies `
            -AllowLegendarySpecies $AllowLegendarySpecies
    })

    return [int[]]@($filtered)
}

function Get-TrainerSpeciesReplacement {
    param(
        [System.Random]$Rng,
        [int]$CurrentSpeciesId,
        [string]$Mode,
        [hashtable]$Context,
        [int]$Level,
        [bool]$DoForceFullyEvolved,
        [int]$ForceEvolutionLevel,
        [hashtable]$EvolutionTargetsBySpecies,
        [bool]$AllowLegendarySpecies,
        [int]$RequiredTypeId = -1,
        [hashtable]$FullContext = $null,
        [System.Collections.Generic.HashSet[int]]$ExcludedSpeciesIds = $null
    )

    $candidatePool = @(Get-SpeciesReplacementPool -CurrentSpeciesId $CurrentSpeciesId -Mode $Mode -Context $Context)
    if ($ExcludedSpeciesIds -and $candidatePool.Count -gt 0) {
        $filteredPool = @($candidatePool | Where-Object { -not $ExcludedSpeciesIds.Contains([int]$_) })
        if ($filteredPool.Count -gt 0) {
            $candidatePool = $filteredPool
        }
    }

    $typeContext = if ($FullContext) { $FullContext } else { $Context }
    if ($RequiredTypeId -ge 0 -and $candidatePool.Count -gt 0) {
        $typeSafePool = @(Get-TrainerSpeciesPoolMatchingRequiredType `
            -Pool ([int[]]$candidatePool) `
            -Level $Level `
            -RequiredTypeId $RequiredTypeId `
            -Context $typeContext `
            -DoForceFullyEvolved $DoForceFullyEvolved `
            -ForceEvolutionLevel $ForceEvolutionLevel `
            -EvolutionTargetsBySpecies $EvolutionTargetsBySpecies `
            -AllowLegendarySpecies $AllowLegendarySpecies)
        if ($typeSafePool.Count -gt 0) {
            $candidatePool = $typeSafePool
        } else {
            $typedFallbackPool = @(Get-TrainerSpeciesPoolMatchingRequiredType `
                -Pool ([int[]]@($Context.BaseSpeciesPool)) `
                -Level $Level `
                -RequiredTypeId $RequiredTypeId `
                -Context $typeContext `
                -DoForceFullyEvolved $DoForceFullyEvolved `
                -ForceEvolutionLevel $ForceEvolutionLevel `
                -EvolutionTargetsBySpecies $EvolutionTargetsBySpecies `
                -AllowLegendarySpecies $AllowLegendarySpecies)
            if ($ExcludedSpeciesIds -and $typedFallbackPool.Count -gt 0) {
                $typedFallbackPool = @($typedFallbackPool | Where-Object { -not $ExcludedSpeciesIds.Contains([int]$_) })
            }
            if ($typedFallbackPool.Count -gt 0) {
                $candidatePool = $typedFallbackPool
            }
        }
    }

    return Random-FromPool -Rng $Rng -Pool $candidatePool
}

function Get-LastLevelUpMoves {
    param(
        [byte[]]$LearnsetBytes,
        $PersonalEntries,
        [int]$SpeciesId,
        [int]$FormId,
        [int]$Level,
        [hashtable]$Cache
    )

    $baseEntry = $PersonalEntries[$SpeciesId]
    if (-not $baseEntry) {
        return @()
    }

    $learnsetIndex = $SpeciesId
    if ($FormId -gt 0 -and $baseEntry.FormStatsIndex -gt 0) {
        $learnsetIndex = $baseEntry.FormStatsIndex + $FormId - 1
    }

    $recordOffset = $learnsetIndex * $LearnsetRecordSize
    if (-not $LearnsetBytes -or ($recordOffset + $LearnsetRecordSize) -gt $LearnsetBytes.Length) {
        return @()
    }

    $cacheKey = "{0}|{1}" -f $learnsetIndex, $Level
    if ($Cache -and $Cache.ContainsKey($cacheKey)) {
        return $Cache[$cacheKey]
    }

    $moves = New-Object System.Collections.Generic.List[int]
    for ($cursor = 0; $cursor -lt $LearnsetRecordSize; $cursor += 4) {
        $moveId = Read-U16 -Data $LearnsetBytes -Offset ($recordOffset + $cursor)
        $moveLevel = Read-U16 -Data $LearnsetBytes -Offset ($recordOffset + $cursor + 2)
        if ($moveId -eq 0xFFFF -and $moveLevel -eq 0xFFFF) {
            break
        }
        if ($moveId -gt 0 -and $moveLevel -le $Level) {
            $moves.Add([int]$moveId)
        }
    }
    $result = if ($moves.Count -eq 0) {
        [int[]]@()
    } elseif ($moves.Count -le 4) {
        [int[]]$moves.ToArray()
    } else {
        [int[]]$moves.GetRange($moves.Count - 4, 4).ToArray()
    }
    if ($Cache) {
        $Cache[$cacheKey] = $result
    }
    return $result
}

function Get-RandomTrainerFillSpeciesId {
    param(
        [System.Random]$Rng,
        [int[]]$Pool,
        [byte[]]$Data,
        [int]$TeamSize,
        [int]$IgnoreSlot = -1
    )

    $excluded = [System.Collections.Generic.HashSet[int]]::new()
    for ($slot = 0; $slot -lt $TeamSize; $slot++) {
        if ($slot -eq $IgnoreSlot) {
            continue
        }

        $offset = $slot * $TrainerPokemonRecordSize
        if (($offset + $TrainerPokemonRecordSize) -gt $Data.Length) {
            break
        }

        $speciesId = [int](Read-U16 -Data $Data -Offset ($offset + 0x0C))
        if ($speciesId -gt 0 -and $speciesId -le $BaseSpeciesMax) {
            $null = $excluded.Add($speciesId)
        }
    }

    $candidatePool = @($Pool | Where-Object { -not $excluded.Contains([int]$_) })
    if ($candidatePool.Count -lt 1) {
        $candidatePool = @($Pool)
    }

    return Random-FromPool -Rng $Rng -Pool $candidatePool
}

function Get-UniqueTrainerSpeciesCandidate {
    param(
        [System.Random]$Rng,
        [int]$CurrentSpeciesId,
        [string]$Mode,
        [hashtable]$Context,
        [System.Collections.Generic.HashSet[int]]$ExcludedEffectiveSpeciesIds,
        [int]$Level,
        [bool]$DoForceFullyEvolved,
        [int]$ForceEvolutionLevel,
        [hashtable]$EvolutionTargetsBySpecies,
        [bool]$AllowLegendarySpecies,
        [byte[]]$Data = $null,
        [int]$TeamSize = 0,
        [int]$IgnoreSlot = -1,
        [int]$RequiredTypeId = -1,
        [hashtable]$FullContext = $null
    )

    $normalizedMode = Normalize-Mode $Mode
    $typeContext = if ($FullContext) { $FullContext } else { $Context }
    $candidatePools = New-Object System.Collections.Generic.List[int[]]
    if ($normalizedMode -eq "unchanged") {
        $initialPool = @($Context.BaseSpeciesPool)
        if ($Data -and $TeamSize -gt 0) {
            $excludedRaw = [System.Collections.Generic.HashSet[int]]::new()
            for ($slotIndex = 0; $slotIndex -lt $TeamSize; $slotIndex++) {
                if ($slotIndex -eq $IgnoreSlot) {
                    continue
                }

                $slotOffset = $slotIndex * $TrainerPokemonRecordSize
                if (($slotOffset + $TrainerPokemonRecordSize) -gt $Data.Length) {
                    break
                }

                $slotSpeciesId = [int](Read-U16 -Data $Data -Offset ($slotOffset + 0x0C))
                if ($slotSpeciesId -gt 0 -and $slotSpeciesId -le $BaseSpeciesMax) {
                    $null = $excludedRaw.Add($slotSpeciesId)
                }
            }

            $initialPool = @($initialPool | Where-Object { -not $excludedRaw.Contains([int]$_) })
        }

        if ($RequiredTypeId -ge 0 -and $initialPool.Count -gt 0) {
            $typedInitialPool = @(Get-TrainerSpeciesPoolMatchingRequiredType `
                -Pool ([int[]]$initialPool) `
                -Level $Level `
                -RequiredTypeId $RequiredTypeId `
                -Context $typeContext `
                -DoForceFullyEvolved $DoForceFullyEvolved `
                -ForceEvolutionLevel $ForceEvolutionLevel `
                -EvolutionTargetsBySpecies $EvolutionTargetsBySpecies `
                -AllowLegendarySpecies $AllowLegendarySpecies)
            if ($typedInitialPool.Count -gt 0) {
                $initialPool = $typedInitialPool
            } else {
                $initialPool = @()
            }
        }

        if ($initialPool.Count -gt 0) {
            $candidatePools.Add([int[]]$initialPool)
        }
    } else {
        $primaryPool = @(Get-SpeciesReplacementPool -CurrentSpeciesId $CurrentSpeciesId -Mode $normalizedMode -Context $Context)
        if ($RequiredTypeId -ge 0 -and $primaryPool.Count -gt 0) {
            $typedPrimaryPool = @(Get-TrainerSpeciesPoolMatchingRequiredType `
                -Pool ([int[]]$primaryPool) `
                -Level $Level `
                -RequiredTypeId $RequiredTypeId `
                -Context $typeContext `
                -DoForceFullyEvolved $DoForceFullyEvolved `
                -ForceEvolutionLevel $ForceEvolutionLevel `
                -EvolutionTargetsBySpecies $EvolutionTargetsBySpecies `
                -AllowLegendarySpecies $AllowLegendarySpecies)
            if ($typedPrimaryPool.Count -gt 0) {
                $primaryPool = $typedPrimaryPool
            } else {
                $primaryPool = @()
            }
        }
        if ($primaryPool.Count -gt 0) {
            $candidatePools.Add([int[]]$primaryPool)
        }
    }

    $basePool = @($Context.BaseSpeciesPool)
    if ($RequiredTypeId -ge 0 -and $basePool.Count -gt 0) {
        $typedBasePool = @(Get-TrainerSpeciesPoolMatchingRequiredType `
            -Pool ([int[]]$basePool) `
            -Level $Level `
            -RequiredTypeId $RequiredTypeId `
            -Context $typeContext `
            -DoForceFullyEvolved $DoForceFullyEvolved `
            -ForceEvolutionLevel $ForceEvolutionLevel `
            -EvolutionTargetsBySpecies $EvolutionTargetsBySpecies `
            -AllowLegendarySpecies $AllowLegendarySpecies)
        if ($typedBasePool.Count -gt 0) {
            $basePool = $typedBasePool
        } else {
            $basePool = @()
        }
    }
    if ($basePool.Count -gt 0) {
        $basePoolSignature = [string]::Join(",", @($basePool))
        $alreadyAddedBasePool = $false
        foreach ($existingPool in $candidatePools) {
            if ([string]::Join(",", @($existingPool)) -eq $basePoolSignature) {
                $alreadyAddedBasePool = $true
                break
            }
        }
        if (-not $alreadyAddedBasePool) {
            $candidatePools.Add([int[]]$basePool)
        }
    }

    if (-not $ExcludedEffectiveSpeciesIds -or $ExcludedEffectiveSpeciesIds.Count -lt 1) {
        foreach ($pool in $candidatePools) {
            if ((Get-ObjectArrayCount $pool) -gt 0) {
                return Random-FromPool -Rng $Rng -Pool $pool
            }
        }
        return $CurrentSpeciesId
    }

    foreach ($pool in $candidatePools) {
        $distinctCandidates = @($pool | Select-Object -Unique)
        if ($distinctCandidates.Count -lt 1) {
            continue
        }

        $shuffledCandidates = Shuffle-Ints -Rng $Rng -Values ([int[]]$distinctCandidates)
        foreach ($candidate in $shuffledCandidates) {
            $effectiveSpeciesId = Get-EffectiveTrainerSpeciesId `
                -SpeciesId $candidate `
                -Level $Level `
                -DoForceFullyEvolved $DoForceFullyEvolved `
                -ForceEvolutionLevel $ForceEvolutionLevel `
                -EvolutionTargetsBySpecies $EvolutionTargetsBySpecies `
                -Rng $Rng `
                -AllowLegendarySpecies $AllowLegendarySpecies
            if (-not $ExcludedEffectiveSpeciesIds.Contains([int]$effectiveSpeciesId)) {
                return [int]$candidate
            }
        }
    }

    # Aucun candidat unique. On NE LEVE PAS : l'unicite est une preference, une
    # generation avortee est un echec dur. Trouve par la campagne de tirage
    # aleatoire, sur la combinaison « equipes a theme de type + aucun doublon +
    # boss forces a 6 » : un type rare n'a pas six especes disponibles au niveau
    # voulu, et toute la generation s'arretait sur un throw.
    #
    # On rend donc un doublon plutot que rien, en preferant le premier pool
    # non vide - c'est le plus contraint, donc le plus proche de ce que
    # l'utilisateur a demande.
    foreach ($pool in $candidatePools) {
        if ((Get-ObjectArrayCount $pool) -gt 0) {
            return Random-FromPool -Rng $Rng -Pool $pool
        }
    }
    return $CurrentSpeciesId
}

function Get-ApproximateTrainerFillLevel {
    param(
        [System.Random]$Rng,
        [byte[]]$Data,
        [int]$ReferenceTeamSize
    )

    $levels = New-Object System.Collections.Generic.List[int]
    for ($slot = 0; $slot -lt $ReferenceTeamSize; $slot++) {
        $offset = $slot * $TrainerPokemonRecordSize
        if (($offset + $TrainerPokemonRecordSize) -gt $Data.Length) {
            break
        }

        $level = [int](Read-U16 -Data $Data -Offset ($offset + 0x0A))
        if ($level -gt 0) {
            $levels.Add($level)
        }
    }

    if ($levels.Count -lt 1) {
        return 1
    }

    $minLevel = [int](($levels | Measure-Object -Minimum).Minimum)
    $maxLevel = [int](($levels | Measure-Object -Maximum).Maximum)
    $averageLevel = [int][Math]::Round((($levels | Measure-Object -Average).Average))
    $spread = [Math]::Min(3, [Math]::Max(0, [int][Math]::Floor(([Math]::Abs($maxLevel - $minLevel)) / 2.0)))
    $candidate = $averageLevel
    if ($spread -gt 0) {
        $candidate += $Rng.Next(-$spread, $spread + 1)
    }

    if ($candidate -lt $minLevel) { $candidate = $minLevel }
    if ($candidate -gt $maxLevel) { $candidate = $maxLevel }
    if ($candidate -lt 1) { $candidate = 1 }
    if ($candidate -gt 100) { $candidate = 100 }
    return [int]$candidate
}

function Set-TrainerMovesRandomDistinct {
    <#
        Quatre attaques tirees au hasard, toutes DIFFERENTES, ecrites depuis la
        premiere case.

        Deux endroits du generateur ecrivaient ces quatre cases avec quatre
        tirages independants : la boucle principale des dresseurs et la passe
        qui rattrape les dresseurs lies aux starters. Le vanilla ne compte
        aucun doublon sur ses 1223 Pokemon de dresseur ; les lots generes en
        comptaient jusqu'a 23. Le code vit donc ici, une seule fois.

        Si le reservoir est trop petit pour quatre attaques distinctes, les
        cases restantes sont laissees vides plutot que remplies d'un doublon.
    #>
    param(
        [byte[]]$Data,
        [int]$Offset,
        [int[]]$MovePool,
        [System.Random]$Rng
    )

    if ((Get-ObjectArrayCount $MovePool) -lt 1) {
        return $false
    }

    $choisies = New-Object System.Collections.Generic.List[int]
    $essais = 0
    while ($choisies.Count -lt 4 -and $essais -lt 64) {
        $essais++
        $candidat = [int](Random-FromPool -Rng $Rng -Pool $MovePool)
        if ($candidat -gt 0 -and -not $choisies.Contains($candidat)) {
            $null = $choisies.Add($candidat)
        }
    }
    if ($choisies.Count -lt 1) {
        return $false
    }

    for ($index = 0; $index -lt 4; $index++) {
        $valeur = if ($index -lt $choisies.Count) { [int]$choisies[$index] } else { 0 }
        Write-U16 -Data $Data -Offset ($Offset + 0x12 + ($index * 2)) -Value $valeur
    }
    return $true
}

function Set-TrainerMovesFromSpeciesLevel {
    param(
        [byte[]]$Data,
        [int]$Offset,
        [byte[]]$LearnsetBytes,
        $PersonalEntries,
        [int]$SpeciesId,
        [int]$FormId,
        [int]$Level,
        [hashtable]$Cache
    )

    $movesRaw = Get-LastLevelUpMoves -LearnsetBytes $LearnsetBytes -PersonalEntries $PersonalEntries -SpeciesId $SpeciesId -FormId $FormId -Level $Level -Cache $Cache
    $moves = New-Object System.Collections.Generic.List[int]
    foreach ($moveValue in @($movesRaw)) {
        if ($moveValue -is [System.Array]) {
            foreach ($nestedMove in $moveValue) {
                $moves.Add([int]$nestedMove)
            }
        } elseif ($null -ne $moveValue) {
            $moves.Add([int]$moveValue)
        }
    }

    if ($moves.Count -lt 1) {
        return $false
    }

    # Une espece peut reapprendre la meme attaque a deux paliers : sans ce
    # filtre, le Pokemon la portait deux fois. Mesure du 2026-09-07 : un cas
    # par lot, alors que le vanilla n'en a aucun.
    $moveUniques = New-Object System.Collections.Generic.List[int]
    foreach ($moveId in $moves) {
        $valeur = [int]$moveId
        if ($valeur -gt 0 -and -not $moveUniques.Contains($valeur)) {
            $null = $moveUniques.Add($valeur)
        }
    }
    if ($moveUniques.Count -lt 1) {
        return $false
    }

    # Remplissage depuis la PREMIERE case. L'alignement a droite laissait un
    # trou devant les attaques quand l'espece en connaissait moins de quatre :
    # 49 Pokemon par lot, contre zero dans le vanilla.
    $filled = @(0, 0, 0, 0)
    $count = [Math]::Min(4, $moveUniques.Count)
    for ($i = 0; $i -lt $count; $i++) {
        $filled[$i] = [int]$moveUniques[$i]
    }

    foreach ($index in 0..3) {
        Write-U16 -Data $Data -Offset ($Offset + 0x12 + ($index * 2)) -Value $filled[$index]
    }

    return $true
}

function Add-UniqueMoveIds {
    param(
        [System.Collections.Generic.List[int]]$Target,
        [int[]]$MoveIds,
        [System.Collections.Generic.HashSet[int]]$AllowedMoveIds = $null
    )

    if ($null -eq $Target -or -not $MoveIds) {
        return
    }

    foreach ($moveIdRaw in @($MoveIds)) {
        $moveId = [int]$moveIdRaw
        if ($moveId -le 0) {
            continue
        }
        if ($AllowedMoveIds -and $AllowedMoveIds.Count -gt 0 -and -not $AllowedMoveIds.Contains($moveId)) {
            continue
        }
        if (-not $Target.Contains($moveId)) {
            $Target.Add($moveId)
        }
        if ($Target.Count -ge 4) {
            return
        }
    }
}

function Set-TrainerMovesSmogonStrategic {
    param(
        [byte[]]$Data,
        [int]$Offset,
        [object]$SmogonData,
        [object]$StrategicSet = $null,
        [int]$SpeciesId,
        [int]$FormId,
        [int]$Level,
        [System.Random]$Rng,
        [string]$FallbackMode = "LastLevelUp4",
        [int[]]$MovePool = @(),
        [System.Collections.Generic.HashSet[int]]$MovePoolSet = $null,
        [byte[]]$LearnsetBytes = $null,
        $PersonalEntries = $null,
        [hashtable]$Cache = $null
    )

    $selectedMoves = New-Object System.Collections.Generic.List[int]
    Add-SmogonSetMoveChoices -Target $selectedMoves -StrategicSet $StrategicSet -Rng $Rng -AllowedMoveIds $MovePoolSet

    $entry = Get-SmogonStrategicEntry -Data $SmogonData -SpeciesId $SpeciesId
    $strategicMovesRaw = if ($entry) { Get-DynamicPropertyValue -Object $entry -Name "moves" } else { @() }
    $strategicMoves = @()
    foreach ($move in @($strategicMovesRaw)) {
        if ($null -ne $move) {
            $moveId = [int]$move
            if ($moveId -gt 0) {
                $strategicMoves += $moveId
            }
        }
    }

    if ($selectedMoves.Count -lt 4 -and (Get-ObjectArrayCount $strategicMoves) -gt 0) {
        $strategicMoves = Shuffle-Ints -Rng $Rng -Values ([int[]]$strategicMoves)
        Add-UniqueMoveIds -Target $selectedMoves -MoveIds ([int[]]$strategicMoves) -AllowedMoveIds $MovePoolSet
    }

    if ($selectedMoves.Count -lt 4) {
        switch (Normalize-Mode $FallbackMode) {
            "random4" {
                if ((Get-ObjectArrayCount $MovePool) -gt 0) {
                    $fallbackMoves = Shuffle-Ints -Rng $Rng -Values ([int[]]$MovePool.Clone())
                    Add-UniqueMoveIds -Target $selectedMoves -MoveIds ([int[]]$fallbackMoves) -AllowedMoveIds $MovePoolSet
                }
            }
            "unchanged" {
                $currentMoves = New-Object System.Collections.Generic.List[int]
                foreach ($moveOffset in 0x12, 0x14, 0x16, 0x18) {
                    $currentMove = Read-U16 -Data $Data -Offset ($Offset + $moveOffset)
                    if ($currentMove -gt 0) {
                        $currentMoves.Add([int]$currentMove)
                    }
                }
                Add-UniqueMoveIds -Target $selectedMoves -MoveIds ([int[]]$currentMoves.ToArray()) -AllowedMoveIds $MovePoolSet
            }
            default {
                $levelMoves = Get-LastLevelUpMoves -LearnsetBytes $LearnsetBytes -PersonalEntries $PersonalEntries -SpeciesId $SpeciesId -FormId $FormId -Level $Level -Cache $Cache
                $flatMoves = New-Object System.Collections.Generic.List[int]
                foreach ($moveValue in @($levelMoves)) {
                    if ($moveValue -is [System.Array]) {
                        foreach ($nestedMove in $moveValue) {
                            if ($null -ne $nestedMove) { $flatMoves.Add([int]$nestedMove) }
                        }
                    } elseif ($null -ne $moveValue) {
                        $flatMoves.Add([int]$moveValue)
                    }
                }
                Add-UniqueMoveIds -Target $selectedMoves -MoveIds ([int[]]$flatMoves.ToArray()) -AllowedMoveIds $MovePoolSet
            }
        }
    }

    if ($selectedMoves.Count -lt 1) {
        return $false
    }

    # On remplit depuis la PREMIERE case. L'alignement a droite laissait une
    # case vide devant les attaques quand il y en avait moins de quatre :
    # mesure du 2026-09-07, six Pokemon par lot avec un trou, alors que le
    # vanilla remplit toujours depuis le debut - zero trou sur 1223 Pokemon.
    $filled = @(0, 0, 0, 0)
    $count = [Math]::Min(4, $selectedMoves.Count)
    for ($i = 0; $i -lt $count; $i++) {
        $filled[$i] = [int]$selectedMoves[$i]
    }

    foreach ($index in 0..3) {
        Write-U16 -Data $Data -Offset ($Offset + 0x12 + ($index * 2)) -Value $filled[$index]
    }

    return $true
}

function Get-SmogonStrategicHeldItem {
    param(
        [object]$SmogonData,
        [object]$StrategicSet = $null,
        [int]$SpeciesId,
        [System.Random]$Rng,
        [int[]]$FallbackPool,
        [System.Collections.Generic.HashSet[int]]$AllowedItemIds = $null,
        [System.Collections.Generic.HashSet[int]]$UsedItemIds = $null
    )

    $candidateItems = @()
    foreach ($item in @(Get-SmogonStrategicSetItems -StrategicSet $StrategicSet)) {
        if ($null -eq $item) {
            continue
        }
        $itemId = [int]$item
        if ($itemId -le 0) {
            continue
        }
        $candidateItems += $itemId
    }

    $entry = Get-SmogonStrategicEntry -Data $SmogonData -SpeciesId $SpeciesId
    if ($candidateItems.Count -lt 1) {
        $itemsRaw = if ($entry) { Get-DynamicPropertyValue -Object $entry -Name "items" } else { @() }
        foreach ($item in @($itemsRaw)) {
            if ($null -eq $item) {
                continue
            }
            $itemId = [int]$item
            if ($itemId -le 0) {
                continue
            }
            $candidateItems += $itemId
        }
    }

    # $AllowedItemIds etait declare, passe par les DEUX appelants, et jamais lu.
    # Un parametre qui a l'air de contraindre et qui est inerte : exactement le
    # defaut du COMBAT-CACHE §15. Mesure sur un lot de sorties relues avec le
    # decodage du visualiseur : 227 des 1222 emplacements de dresseurs (19 %)
    # portaient un objet ABSENT d'Epee - les identifiants viennent d'un jeu de
    # donnees Smogon qui couvre toutes les generations. En jeu, le Pokemon ne
    # tient rien, et rien ne le signale.
    #
    # Deux filtres, dans cet ordre. L'EXISTENCE d'abord, parce que c'est une
    # invariante : un objet absent du jeu n'est jamais acceptable. La liste
    # autorisee ensuite, et seulement si elle laisse quelque chose - sinon le
    # mode strategique se replierait systematiquement sur le tirage general et
    # perdrait tout son interet.
    if ($candidateItems.Count -gt 0) {
        $existants = Get-ExistingItemIds
        if ($existants.Count -gt 0) {
            $candidateItems = @($candidateItems | Where-Object { $existants.Contains([int]$_) })
        }
    }
    if ($candidateItems.Count -gt 0 -and $AllowedItemIds -and $AllowedItemIds.Count -gt 0) {
        $retenus = @($candidateItems | Where-Object { $AllowedItemIds.Contains([int]$_) })
        if ($retenus.Count -gt 0) {
            $candidateItems = $retenus
        }
    }

    if ($candidateItems.Count -gt 0) {
        $candidateItems = @($candidateItems | Select-Object -Unique)
        if ($UsedItemIds -and $UsedItemIds.Count -lt $candidateItems.Count) {
            $unused = @($candidateItems | Where-Object { -not $UsedItemIds.Contains([int]$_) })
            if ($unused.Count -gt 0) {
                $candidateItems = $unused
            }
        }
        $itemId = [int](Random-FromPool -Rng $Rng -Pool ([int[]]$candidateItems))
        if ($UsedItemIds) {
            $null = $UsedItemIds.Add($itemId)
        }
        return $itemId
    }

    return (Get-RandomTrainerHeldItem -Rng $Rng -Pool $FallbackPool -UsedItemIds $UsedItemIds)
}

function Get-SmogonStrategicAbilityChoice {
    param(
        [object]$SmogonData,
        [object]$StrategicSet = $null,
        [int]$SpeciesId,
        $PersonalEntries,
        [System.Random]$Rng
    )

    if ($null -eq $PersonalEntries -or $SpeciesId -le 0 -or $SpeciesId -ge $PersonalEntries.Count) {
        return $null
    }

    $personal = $PersonalEntries[$SpeciesId]
    if (-not $personal) {
        return $null
    }

    $strategicAbilities = @()
    foreach ($ability in @(Get-SmogonStrategicSetAbilities -StrategicSet $StrategicSet)) {
        if ($null -ne $ability -and [int]$ability -gt 0) {
            $strategicAbilities += [int]$ability
        }
    }

    $entry = Get-SmogonStrategicEntry -Data $SmogonData -SpeciesId $SpeciesId
    if ($strategicAbilities.Count -lt 1) {
        $abilitiesRaw = if ($entry) { Get-DynamicPropertyValue -Object $entry -Name "abilities" } else { @() }
        foreach ($ability in @($abilitiesRaw)) {
            if ($null -ne $ability -and [int]$ability -gt 0) {
                $strategicAbilities += [int]$ability
            }
        }
    }

    if ($strategicAbilities.Count -gt 0) {
        $strategicAbilities = Shuffle-Ints -Rng $Rng -Values ([int[]]($strategicAbilities | Select-Object -Unique))
        foreach ($abilityId in $strategicAbilities) {
            if ($personal.Ability1 -eq $abilityId) { return 1 }
            if ($personal.Ability2 -eq $abilityId) { return 2 }
            if ($personal.AbilityH -eq $abilityId) { return 3 }
        }
    }

    $legalChoices = New-Object System.Collections.Generic.List[int]
    if ([int]$personal.Ability1 -gt 0) { $legalChoices.Add(1) }
    if ([int]$personal.Ability2 -gt 0 -and [int]$personal.Ability2 -ne [int]$personal.Ability1) { $legalChoices.Add(2) }
    if ([int]$personal.AbilityH -gt 0 -and [int]$personal.AbilityH -ne [int]$personal.Ability1 -and [int]$personal.AbilityH -ne [int]$personal.Ability2) { $legalChoices.Add(3) }
    if ($legalChoices.Count -lt 1) {
        return $null
    }

    return [int]$legalChoices[$Rng.Next(0, $legalChoices.Count)]
}

function Set-TrainerNatureSmogonStrategic {
    param(
        [byte[]]$Data,
        [int]$Offset,
        [object]$SmogonData,
        [object]$StrategicSet = $null,
        [int]$SpeciesId,
        [System.Random]$Rng
    )

    $candidateNatures = @()
    foreach ($nature in @(Get-SmogonStrategicSetNatures -StrategicSet $StrategicSet)) {
        if ($null -ne $nature -and [int]$nature -ge 0 -and [int]$nature -le $TrainerNatureMax) {
            $candidateNatures += [int]$nature
        }
    }

    if ($candidateNatures.Count -lt 1) {
        $entry = Get-SmogonStrategicEntry -Data $SmogonData -SpeciesId $SpeciesId
        $naturesRaw = if ($entry) { Get-DynamicPropertyValue -Object $entry -Name "natures" -DefaultValue @() } else { @() }
        foreach ($nature in @($naturesRaw)) {
            if ($null -ne $nature -and [int]$nature -ge 0 -and [int]$nature -le $TrainerNatureMax) {
                $candidateNatures += [int]$nature
            }
        }
    }

    if ($candidateNatures.Count -gt 0) {
        $candidateNatures = @($candidateNatures | Select-Object -Unique)
        $Data[$Offset + 0x01] = [byte](Random-FromPool -Rng $Rng -Pool ([int[]]$candidateNatures))
        return $true
    }

    $Data[$Offset + 0x01] = [byte]$Rng.Next(0, $TrainerNatureMax + 1)
    return $true
}

function Set-TrainerEvs {
    param(
        [byte[]]$Data,
        [int]$Offset,
        [int[]]$Values
    )

    if (-not $Values -or $Values.Count -lt 6) {
        return $false
    }

    foreach ($i in 0..5) {
        $value = [int]$Values[$i]
        if ($value -lt 0) { $value = 0 }
        if ($value -gt 252) { $value = 252 }
        $Data[$Offset + 0x02 + $i] = [byte]$value
    }
    return $true
}

function Set-TrainerEvsRandomLegal {
    param(
        [byte[]]$Data,
        [int]$Offset,
        [System.Random]$Rng
    )

    $remaining = 510
    $evValues = @(0, 0, 0, 0, 0, 0)
    for ($i = 0; $i -lt 6; $i++) {
        if ($i -eq 5) {
            $value = [Math]::Min(252, $remaining)
        } else {
            $value = [Math]::Min(252, $Rng.Next(0, $remaining + 1))
        }
        $evValues[$i] = $value
        $remaining -= $value
    }
    $evValues = Shuffle-Ints -Rng $Rng -Values ([int[]]$evValues)
    return (Set-TrainerEvs -Data $Data -Offset $Offset -Values ([int[]]$evValues))
}

function Set-TrainerEvsSmogonStrategic {
    param(
        [byte[]]$Data,
        [int]$Offset,
        [object]$StrategicSet,
        [System.Random]$Rng
    )

    $evValues = Get-SmogonStrategicSetEvs -StrategicSet $StrategicSet
    if ((Get-ObjectArrayCount $evValues) -ge 6) {
        return (Set-TrainerEvs -Data $Data -Offset $Offset -Values ([int[]]$evValues))
    }

    return (Set-TrainerEvsRandomLegal -Data $Data -Offset $Offset -Rng $Rng)
}

function Get-StatsReplacement {
    param(
        [System.Random]$Rng,
        [int[]]$Stats,
        [string]$Mode
    )

    switch (Normalize-Mode $Mode) {
        "shuffle" {
            return @(Shuffle-Ints -Rng $Rng -Values ([int[]]$Stats.Clone()))
        }
        "redistribute" {
            $total = ($Stats | Measure-Object -Sum).Sum
            if ($total -le 0) {
                return [int[]]@(0, 0, 0, 0, 0, 0)
            }
            $baseValue = if ($total -ge 6) { 1 } else { 0 }
            $remaining = [Math]::Max(0, $total - ($baseValue * 6))
            $weights = 1..6 | ForEach-Object { $Rng.Next(10, 100) }
            $weightTotal = ($weights | Measure-Object -Sum).Sum
            $result = New-Object System.Collections.Generic.List[int]
            $allocated = 0
            for ($i = 0; $i -lt 6; $i++) {
                if ($i -eq 5) {
                    $value = $remaining - $allocated
                } else {
                    $value = [int][Math]::Floor($remaining * ($weights[$i] / $weightTotal))
                }
                $maxExtra = 255 - $baseValue
                if ($value -gt $maxExtra) {
                    $value = $maxExtra
                }
                $allocated += $value
                $result.Add($baseValue + $value)
            }

            $runningTotal = ($result | Measure-Object -Sum).Sum
            while ($runningTotal -lt $total) {
                $index = $Rng.Next(0, $result.Count)
                if ($result[$index] -lt 255) {
                    $result[$index]++
                    $runningTotal++
                }
            }
            while ($runningTotal -gt $total) {
                $index = $Rng.Next(0, $result.Count)
                if ($result[$index] -gt $baseValue) {
                    $result[$index]--
                    $runningTotal--
                }
            }
            return [int[]]$result.ToArray()
        }
        default {
            return $Stats
        }
    }
}

function Set-TrainerAbilityChoice {
    param(
        [byte[]]$Data,
        [int]$Offset,
        [int]$Choice
    )
    $packed = $Data[$Offset]
    $Data[$Offset] = [byte](($packed -band 0xCF) -bor (($Choice -band 0x03) -shl 4))
}

function Set-TrainerShinyFlag {
    param(
        [byte[]]$Data,
        [int]$Offset,
        [bool]$IsShiny
    )

    $ivOffset = $Offset + 0x1C
    $iv32 = Read-U32 -Data $Data -Offset $ivOffset
    if ($IsShiny) {
        $iv32 = $iv32 -bor 0x40000000
    } else {
        $iv32 = $iv32 -band 0xBFFFFFFF
    }
    Write-U32 -Data $Data -Offset $ivOffset -Value ([uint32]$iv32)
}

function Set-TrainerDynamaxFlag {
    param(
        [byte[]]$Data,
        [int]$Offset,
        [bool]$CanDynamax
    )

    $ivOffset = $Offset + 0x1C
    $iv32 = Read-U32 -Data $Data -Offset $ivOffset
    if ($CanDynamax) {
        $iv32 = $iv32 -bor 0x80000000
    } else {
        $iv32 = $iv32 -band 0x7FFFFFFF
    }
    Write-U32 -Data $Data -Offset $ivOffset -Value ([uint32]$iv32)
}

function Get-TrainerAbilityChoice {
    param(
        [byte[]]$Data,
        [int]$Offset
    )

    return (($Data[$Offset] -shr 4) -band 0x03)
}

function Get-TrainerIVSummary {
    param([uint32]$Value)

    return [ordered]@{
        raw = $Value
        hp = [int](($Value -shr 0) -band 0x1F)
        attack = [int](($Value -shr 5) -band 0x1F)
        defense = [int](($Value -shr 10) -band 0x1F)
        specialAttack = [int](($Value -shr 15) -band 0x1F)
        specialDefense = [int](($Value -shr 20) -band 0x1F)
        speed = [int](($Value -shr 25) -band 0x1F)
    }
}

function New-SpeciesReportObject {
    param([int]$SpeciesId)

    if ($SpeciesId -le 0) {
        return $null
    }

    return [ordered]@{
        id = $SpeciesId
        fr = Get-SpeciesDisplayName -SpeciesId $SpeciesId -Language "fr"
        en = Get-SpeciesDisplayName -SpeciesId $SpeciesId -Language "en"
    }
}

function New-ItemReportObject {
    param([int]$ItemId)

    if ($ItemId -le 0) {
        return [ordered]@{
            id = 0
            fr = ""
            en = ""
            isTechnicalRecord = $false
        }
    }

    $isTechnicalRecord = (($ItemId -ge 328 -and $ItemId -le 419) -or
        ($ItemId -ge 618 -and $ItemId -le 620) -or
        ($ItemId -ge 690 -and $ItemId -le 693) -or
        ($ItemId -ge 1130 -and $ItemId -le 1229) -or
        ($ItemId -eq 1230))

    return [ordered]@{
        id = $ItemId
        fr = Get-ItemDisplayName -ItemId $ItemId -Language "fr"
        en = Get-ItemDisplayName -ItemId $ItemId -Language "en"
        isTechnicalRecord = [bool]$isTechnicalRecord
    }
}

function New-MoveReportObject {
    param([int]$MoveId)

    if ($MoveId -le 0) {
        return [ordered]@{
            id = 0
            fr = ""
            en = ""
        }
    }

    return [ordered]@{
        id = $MoveId
        fr = Get-MoveDisplayName -MoveId $MoveId -Language "fr"
        en = Get-MoveDisplayName -MoveId $MoveId -Language "en"
    }
}

function Get-TrainerPokemonSnapshot {
    param(
        [byte[]]$Data,
        [int]$Slot
    )

    $offset = $Slot * $TrainerPokemonRecordSize
    if (-not $Data -or $offset -lt 0 -or ($offset + $TrainerPokemonRecordSize) -gt $Data.Length) {
        return $null
    }

    $speciesId = Read-U16 -Data $Data -Offset ($offset + 0x0C)
    $itemId = Read-U16 -Data $Data -Offset ($offset + 0x10)
    $iv32 = Read-U32 -Data $Data -Offset ($offset + 0x1C)
    $moves = @()
    foreach ($moveOffset in 0x12, 0x14, 0x16, 0x18) {
        $moves += New-MoveReportObject -MoveId (Read-U16 -Data $Data -Offset ($offset + $moveOffset))
    }

    return [ordered]@{
        slot = $Slot + 1
        species = New-SpeciesReportObject -SpeciesId $speciesId
        formId = Read-U16 -Data $Data -Offset ($offset + 0x0E)
        level = Read-U16 -Data $Data -Offset ($offset + 0x0A)
        item = New-ItemReportObject -ItemId $itemId
        moves = $moves
        natureId = [int]$Data[$offset + 0x01]
        abilityChoice = Get-TrainerAbilityChoice -Data $Data -Offset $offset
        evs = [ordered]@{
            hp = [int]$Data[$offset + 0x02]
            attack = [int]$Data[$offset + 0x03]
            defense = [int]$Data[$offset + 0x04]
            specialAttack = [int]$Data[$offset + 0x05]
            specialDefense = [int]$Data[$offset + 0x06]
            speed = [int]$Data[$offset + 0x07]
        }
        ivs = Get-TrainerIVSummary -Value $iv32
        shiny = [bool](($iv32 -band 0x40000000) -ne 0)
        canDynamax = [bool](($iv32 -band 0x80000000) -ne 0)
        dynamaxLevel = [int]$Data[$offset + 0x08]
    }
}

function New-TrainerSlotChange {
    param(
        [int]$Slot,
        [object]$Before,
        [object]$After
    )

    $changedFields = New-Object System.Collections.Generic.List[string]
    $changes = [ordered]@{}
    if ($null -eq $Before -and $null -ne $After) {
        $changedFields.Add("added")
        $changes["added"] = [ordered]@{ after = $After }
    } elseif ($null -ne $Before -and $null -eq $After) {
        $changedFields.Add("removed")
        $changes["removed"] = [ordered]@{ before = $Before }
    } elseif ($null -ne $Before -and $null -ne $After) {
        $beforeSpeciesId = if ($Before["species"]) { [int]$Before["species"]["id"] } else { 0 }
        $afterSpeciesId = if ($After["species"]) { [int]$After["species"]["id"] } else { 0 }
        if ($beforeSpeciesId -ne $afterSpeciesId) {
            $changedFields.Add("species")
            $changes["species"] = [ordered]@{ before = $Before["species"]; after = $After["species"] }
        }
        foreach ($field in @("formId", "level", "natureId", "abilityChoice", "shiny", "canDynamax", "dynamaxLevel")) {
            if ($Before[$field] -ne $After[$field]) {
                $changedFields.Add($field)
                $changes[$field] = [ordered]@{ before = $Before[$field]; after = $After[$field] }
            }
        }
        if ([int]$Before["item"]["id"] -ne [int]$After["item"]["id"]) {
            $changedFields.Add("item")
            $changes["item"] = [ordered]@{ before = $Before["item"]; after = $After["item"] }
        }

        $beforeMoves = @($Before["moves"] | ForEach-Object { [int]$_["id"] }) -join ","
        $afterMoves = @($After["moves"] | ForEach-Object { [int]$_["id"] }) -join ","
        if ($beforeMoves -ne $afterMoves) {
            $changedFields.Add("moves")
            $changes["moves"] = [ordered]@{ before = $Before["moves"]; after = $After["moves"] }
        }

        foreach ($stat in @("hp", "attack", "defense", "specialAttack", "specialDefense", "speed")) {
            if ([int]$Before["evs"][$stat] -ne [int]$After["evs"][$stat]) {
                $changedFields.Add("evs")
                $changes["evs"] = [ordered]@{ before = $Before["evs"]; after = $After["evs"] }
                break
            }
        }
        foreach ($stat in @("hp", "attack", "defense", "specialAttack", "specialDefense", "speed")) {
            if ([int]$Before["ivs"][$stat] -ne [int]$After["ivs"][$stat]) {
                $changedFields.Add("ivs")
                $changes["ivs"] = [ordered]@{ before = $Before["ivs"]; after = $After["ivs"] }
                break
            }
        }
    }

    if ($changedFields.Count -eq 0) {
        return $null
    }

    return [ordered]@{
        slot = $Slot + 1
        changedFields = [string[]]$changedFields.ToArray()
        changes = $changes
    }
}

function Get-EvolutionTargetsBySpecies {
    param([string]$RomfsRoot)

    $targetsBySpecies = @{}
    $evolutionDir = Get-EvolutionDir -RomfsRoot $RomfsRoot
    if (-not (Test-Path -LiteralPath $evolutionDir)) {
        return $targetsBySpecies
    }

    foreach ($file in Get-ChildItem -LiteralPath $evolutionDir -Filter "evo_*.bin" -File) {
        if ($file.BaseName -notmatch '^evo_(\d+)$') {
            continue
        }

        $speciesId = [int]$matches[1]
        if ($speciesId -le 0 -or $speciesId -gt $BaseSpeciesMax) {
            continue
        }

        $bytes = [IO.File]::ReadAllBytes($file.FullName)
        $targets = [System.Collections.Generic.HashSet[int]]::new()
        for ($slot = 0; $slot -lt $EvolutionRecordsPerSpecies; $slot++) {
            $slotOffset = $slot * $EvolutionRecordSize
            $method = Read-U16 -Data $bytes -Offset $slotOffset
            $targetSpecies = Read-U16 -Data $bytes -Offset ($slotOffset + 4)
            if ($method -ne 0 -and $targetSpecies -gt 0 -and $targetSpecies -le $BaseSpeciesMax) {
                $null = $targets.Add($targetSpecies)
            }
        }

        if ($targets.Count -gt 0) {
            $targetsBySpecies[$speciesId] = [int[]]@($targets | Sort-Object)
        }
    }

    return $targetsBySpecies
}

function Get-FinalEvolutionSpecies {
    param(
        [int]$SpeciesId,
        [hashtable]$TargetsBySpecies,
        [System.Random]$Rng,
        [bool]$AllowLegendarySpecies
    )

    $current = $SpeciesId
    $visited = [System.Collections.Generic.HashSet[int]]::new()

    while ($TargetsBySpecies.ContainsKey($current) -and $visited.Add($current)) {
        $candidates = @($TargetsBySpecies[$current] | Where-Object { $AllowLegendarySpecies -or (-not $LegendarySpeciesIds.Contains([int]$_)) })
        if ($candidates.Count -eq 0) {
            break
        }

        $current = [int]$candidates[$Rng.Next(0, $candidates.Count)]
    }

    return $current
}

function Get-OrCreate-TrainerRecordBytes {
    param(
        [byte[]]$Bytes,
        [int]$CurrentCount,
        [int]$Index,
        [int]$TemplateIndex = -1
    )

    if ($Index -lt $CurrentCount) {
        return $Bytes
    }

    $oldLength = $Bytes.Length
    $newLength = ($Index + 1) * $TrainerPokemonRecordSize
    [Array]::Resize([ref]$Bytes, $newLength)

    $templateSourceOffset = if ($TemplateIndex -ge 0 -and $TemplateIndex -lt $CurrentCount) {
        $TemplateIndex * $TrainerPokemonRecordSize
    } elseif ($CurrentCount -gt 0) {
        ($CurrentCount - 1) * $TrainerPokemonRecordSize
    } else {
        -1
    }
    $targetOffset = $Index * $TrainerPokemonRecordSize

    if ($templateSourceOffset -ge 0) {
        [Array]::Copy($Bytes, $templateSourceOffset, $Bytes, $targetOffset, $TrainerPokemonRecordSize)
    } else {
        for ($cursor = $oldLength; $cursor -lt $newLength; $cursor++) {
            $Bytes[$cursor] = 0
        }
    }

    Write-Output -NoEnumerate $Bytes
}

function Test-FlatBufferTablePosition {
    <#
        Une position se relit-elle comme une table FlatBuffers ? Sert a refuser
        un champ racine qui n'est pas un vecteur de tables, plutot que d'ecrire
        a l'aveugle dans un fichier mal interprete.
    #>
    param([byte[]]$Data, [int]$TablePos)

    if ($TablePos -le 0 -or ($TablePos + 4) -gt $Data.Length) { return $false }
    $vtablePos = $TablePos - [int](Read-I32 -Data $Data -Offset $TablePos)
    if ($vtablePos -lt 0 -or ($vtablePos + 4) -gt $Data.Length) { return $false }
    $vtableLength = [int](Read-U16 -Data $Data -Offset $vtablePos)
    if ($vtableLength -lt 4 -or ($vtableLength % 2) -ne 0) { return $false }
    if (($vtablePos + $vtableLength) -gt $Data.Length) { return $false }
    return $true
}

function Get-ShopInventorySlotAddresses {
    <#
        Structure REELLE de shop_data.bin, etablie le 2026-09-08 en relisant les
        faits de structure du lecteur de KM-Editor puis en les verifiant sur le
        dump :

            boutique.champ0 = hash u64
            boutique.champ1 -> table Inventory              (vecteur racine 0)
            boutique.champ1 -> vecteur de tables Inventory  (vecteur racine 1)
            Inventory.champ0 -> vecteur d'entiers = LES OBJETS

        Il y a donc UN niveau d'indirection de plus que ce que le generateur
        lisait. En s'arretant au champ 1 de la boutique, il prenait la table
        Inventory pour le vecteur d'objets. Consequences mesurees :

          - il ne voyait que 3 boutiques et 24 emplacements la ou il y en a
            165 et 1347 ;
          - il croyait 162 tables vides alors qu'elles contiennent des CT ;
          - et surtout il ECRIVAIT dans la structure du FlatBuffer au lieu des
            objets, ce qui vidait la liste d'une boutique et faisait planter le
            jeu a l'achat.

        Le champ 1 est lu des deux facons, en essayant d'abord la table
        Inventory : c'est la donnee qui tranche, pas une hypothese sur le
        vecteur racine d'origine.
    #>
    param([byte[]]$Data)

    $lireVecteur = {
        param([int]$Adresse)
        if ($Adresse -lt 0 -or ($Adresse + 4) -gt $Data.Length) { return $null }
        $brut = [uint32](Read-U32 -Data $Data -Offset $Adresse)
        if ($brut -gt [uint32][int]::MaxValue) { return $null }
        $pos = $Adresse + [int]$brut
        if ($pos -lt 0 -or ($pos + 4) -gt $Data.Length) { return $null }
        $compte = [uint32](Read-U32 -Data $Data -Offset $pos)
        if ($compte -gt 5000 -or ($pos + 4 + ([int]$compte * 4)) -gt $Data.Length) { return $null }
        return [pscustomobject]@{ Pos = $pos; Compte = [int]$compte }
    }

    $slotsInventaire = {
        param([int]$TablePos)
        if ($TablePos -lt 0 -or ($TablePos + 4) -gt $Data.Length) { return $null }
        $champ = Get-FlatBufferFieldAddress -Data $Data -TablePos $TablePos -FieldIndex 0
        if ($champ -lt 0) { return $null }
        $vec = & $lireVecteur $champ
        if (-not $vec -or $vec.Compte -le 0) { return $null }
        $liste = New-Object System.Collections.Generic.List[int]
        for ($j = 0; $j -lt $vec.Compte; $j++) { $null = $liste.Add($vec.Pos + 4 + ($j * 4)) }
        return $liste
    }

    $sortie = New-Object System.Collections.Generic.List[object]
    $indexBoutique = 0
    foreach ($tablePos in Get-FlatBufferRootTableEntries -Data $Data) {
        $indexBoutique++
        $champUn = Get-FlatBufferFieldAddress -Data $Data -TablePos $tablePos -FieldIndex 1
        if ($champUn -lt 0 -or ($champUn + 4) -gt $Data.Length) { continue }
        $brut = [uint32](Read-U32 -Data $Data -Offset $champUn)
        if ($brut -gt [uint32][int]::MaxValue) { continue }
        $cible = $champUn + [int]$brut

        $direct = & $slotsInventaire $cible
        if ($direct -and $direct.Count -gt 0) {
            $null = $sortie.Add([pscustomobject]@{
                ShopIndex = $indexBoutique
                InventoryIndex = 0
                Addresses = $direct
            })
            continue
        }

        $vec = & $lireVecteur $champUn
        if (-not $vec) { continue }
        for ($k = 0; $k -lt $vec.Compte; $k++) {
            $element = $vec.Pos + 4 + ($k * 4)
            if (($element + 4) -gt $Data.Length) { break }
            $brutInv = [uint32](Read-U32 -Data $Data -Offset $element)
            if ($brutInv -gt [uint32][int]::MaxValue) { continue }
            $slots = & $slotsInventaire ($element + [int]$brutInv)
            if ($slots -and $slots.Count -gt 0) {
                $null = $sortie.Add([pscustomobject]@{
                    ShopIndex = $indexBoutique
                    InventoryIndex = $k
                    Addresses = $slots
                })
            }
        }
    }

    return $sortie
}

function Get-FlatBufferRootTableEntries {
    <#
        Toutes les tables atteignables depuis la racine, en visitant CHAQUE
        champ de la table racine.

        Get-FlatBufferTableVectorPositions ne lit que le premier champ
        ($root + 4). shop_data.bin range ses boutiques dans deux vecteurs
        distincts : le champ 0 en porte 163 (une seule garnie, 6 emplacements)
        et le champ 1 en porte 2, garnies toutes les deux, 18 emplacements.
        Sur les 24 emplacements du fichier, 18 n'etaient donc jamais tires.

        Un champ dont les entrees ne se relisent pas toutes comme des tables
        valides est ignore en entier.
    #>
    param([byte[]]$Data)

    $positions = New-Object System.Collections.Generic.List[int]
    $root = [int](Read-U32 -Data $Data -Offset 0)
    if (-not (Test-FlatBufferTablePosition -Data $Data -TablePos $root)) {
        return @()
    }
    $vtablePos = $root - [int](Read-I32 -Data $Data -Offset $root)
    $vtableLength = [int](Read-U16 -Data $Data -Offset $vtablePos)
    $fieldCount = [int](($vtableLength - 4) / 2)

    for ($field = 0; $field -lt $fieldCount; $field++) {
        $fieldAddress = Get-FlatBufferFieldAddress -Data $Data -TablePos $root -FieldIndex $field
        if ($fieldAddress -lt 0 -or ($fieldAddress + 4) -gt $Data.Length) { continue }
        $vectorPos = $fieldAddress + [int](Read-U32 -Data $Data -Offset $fieldAddress)
        if ($vectorPos -le 0 -or ($vectorPos + 4) -gt $Data.Length) { continue }
        $rawCount = [uint32](Read-U32 -Data $Data -Offset $vectorPos)
        if ($rawCount -eq 0 -or $rawCount -gt 10000) { continue }
        $count = [int]$rawCount
        if (($vectorPos + 4 + ($count * 4)) -gt $Data.Length) { continue }

        $entrees = New-Object System.Collections.Generic.List[int]
        $valide = $true
        for ($index = 0; $index -lt $count; $index++) {
            $entryOffsetPos = $vectorPos + 4 + ($index * 4)
            $entryPos = $entryOffsetPos + [int](Read-U32 -Data $Data -Offset $entryOffsetPos)
            if (-not (Test-FlatBufferTablePosition -Data $Data -TablePos $entryPos)) {
                $valide = $false
                break
            }
            $entrees.Add($entryPos)
        }
        if ($valide) {
            foreach ($p in $entrees) { $positions.Add($p) }
        }
    }

    return $positions
}

function Get-FlatBufferTableVectorPositions {
    param([byte[]]$Data)

    $root = [int](Read-U32 -Data $Data -Offset 0)
    $vectorFieldPos = $root + 4
    $vectorPos = $vectorFieldPos + [int](Read-U32 -Data $Data -Offset $vectorFieldPos)
    $rawCount = [uint32](Read-U32 -Data $Data -Offset $vectorPos)
    if ($rawCount -gt 10000) {
        return @()
    }

    $count = [int]$rawCount
    if (($vectorPos + 4 + ($count * 4)) -gt $Data.Length) {
        return @()
    }
    $positions = New-Object System.Collections.Generic.List[int]

    for ($index = 0; $index -lt $count; $index++) {
        $entryOffsetPos = $vectorPos + 4 + ($index * 4)
        $entryPos = $entryOffsetPos + [int](Read-U32 -Data $Data -Offset $entryOffsetPos)
        $positions.Add($entryPos)
    }

    return $positions
}

function Get-FlatBufferFieldAddress {
    param(
        [byte[]]$Data,
        [int]$TablePos,
        [int]$FieldIndex
    )

    $vtablePos = $TablePos - (Read-I32 -Data $Data -Offset $TablePos)
    $vtableLength = [int](Read-U16 -Data $Data -Offset $vtablePos)
    $slotPos = $vtablePos + 4 + ($FieldIndex * 2)
    if (($slotPos + 2) -gt ($vtablePos + $vtableLength)) {
        return -1
    }

    $fieldOffset = [int](Read-U16 -Data $Data -Offset $slotPos)
    if ($fieldOffset -eq 0) {
        return -1
    }

    return $TablePos + $fieldOffset
}

function Set-FlatBufferByteField {
    param(
        [byte[]]$Data,
        [int]$TablePos,
        [int]$FieldIndex,
        [byte]$Value,
        [bool]$AllowAddMissing = $false
    )

    $address = Get-FlatBufferFieldAddress -Data $Data -TablePos $TablePos -FieldIndex $FieldIndex
    if ($address -ge 0) {
        $Data[$address] = $Value
        return $Data
    }

    if (-not $AllowAddMissing) {
        return $Data
    }

    $vtablePos = $TablePos - (Read-I32 -Data $Data -Offset $TablePos)
    $vtableLength = [int](Read-U16 -Data $Data -Offset $vtablePos)
    $slotPos = $vtablePos + 4 + ($FieldIndex * 2)
    if (($slotPos + 2) -gt ($vtablePos + $vtableLength)) {
        return $Data
    }

    $objectSize = [int](Read-U16 -Data $Data -Offset ($vtablePos + 2))
    if (($TablePos + $objectSize) -ne $Data.Length) {
        return $Data
    }

    $newData = New-Object byte[] ($Data.Length + 1)
    [Array]::Copy($Data, 0, $newData, 0, $Data.Length)
    $newData[$TablePos + $objectSize] = $Value
    Write-U16 -Data $newData -Offset ($vtablePos + 2) -Value ($objectSize + 1)
    Write-U16 -Data $newData -Offset $slotPos -Value $objectSize
    return $newData
}

function Get-FlatBufferRootTablePosition {
    param([byte[]]$Data)
    return [int](Read-U32 -Data $Data -Offset 0)
}

function Get-FlatBufferTableVectorEntries {
    param(
        [byte[]]$Data,
        [int]$TablePos,
        [int]$FieldIndex
    )

    $fieldAddress = Get-FlatBufferFieldAddress -Data $Data -TablePos $TablePos -FieldIndex $FieldIndex
    if ($fieldAddress -lt 0 -or ($fieldAddress + 4) -gt $Data.Length) {
        return @()
    }

    $vectorPos = $fieldAddress + [int](Read-U32 -Data $Data -Offset $fieldAddress)
    if ($vectorPos -lt 0 -or ($vectorPos + 4) -gt $Data.Length) {
        return @()
    }

    $count = [int](Read-U32 -Data $Data -Offset $vectorPos)
    $positions = New-Object System.Collections.Generic.List[int]
    for ($index = 0; $index -lt $count; $index++) {
        $entryOffsetPos = $vectorPos + 4 + ($index * 4)
        if (($entryOffsetPos + 4) -gt $Data.Length) {
            break
        }
        $entryPos = $entryOffsetPos + [int](Read-U32 -Data $Data -Offset $entryOffsetPos)
        if ($entryPos -ge 0 -and $entryPos -lt $Data.Length) {
            $positions.Add($entryPos)
        }
    }

    return $positions
}

function Initialize-BinaryCodec {
    if ("PokeFeurBinaryUtil" -as [type]) {
        return
    }

    Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;

public static class PokeFeurBinaryUtil
{
    private const ulong FnvOffset64 = 0xCBF29CE484222645UL;
    private const ulong FnvPrime64 = 0x00000100000001B3UL;

    public static ulong Fnv1a64(string text)
    {
        unchecked
        {
            ulong hash = FnvOffset64;
            foreach (char c in text)
            {
                hash ^= c;
                hash *= FnvPrime64;
            }
            return hash;
        }
    }

    public static byte[] Lz4Decompress(byte[] input, int decompressedLength)
    {
        byte[] output = new byte[decompressedLength];
        int ip = 0;
        int op = 0;

        while (ip < input.Length)
        {
            int token = input[ip++];
            int literalLength = token >> 4;
            if (literalLength == 15)
            {
                int b;
                do
                {
                    if (ip >= input.Length)
                        throw new ArgumentException("Invalid LZ4 literal length.");
                    b = input[ip++];
                    literalLength += b;
                }
                while (b == 255);
            }

            if (ip + literalLength > input.Length || op + literalLength > output.Length)
                throw new ArgumentException("Invalid LZ4 literal copy.");

            Buffer.BlockCopy(input, ip, output, op, literalLength);
            ip += literalLength;
            op += literalLength;

            if (ip >= input.Length)
                break;

            if (ip + 2 > input.Length)
                throw new ArgumentException("Invalid LZ4 match offset.");

            int offset = input[ip] | (input[ip + 1] << 8);
            ip += 2;
            if (offset <= 0 || offset > op)
                throw new ArgumentException("Invalid LZ4 match distance.");

            int matchLength = token & 0x0F;
            if (matchLength == 15)
            {
                int b;
                do
                {
                    if (ip >= input.Length)
                        throw new ArgumentException("Invalid LZ4 match length.");
                    b = input[ip++];
                    matchLength += b;
                }
                while (b == 255);
            }
            matchLength += 4;

            if (op + matchLength > output.Length)
                throw new ArgumentException("Invalid LZ4 match copy.");

            int match = op - offset;
            for (int i = 0; i < matchLength; i++)
                output[op++] = output[match + i];
        }

        if (op != output.Length)
            throw new ArgumentException("Decoded length mismatch.");

        return output;
    }

    public static byte[] Lz4CompressLiteral(byte[] input)
    {
        var output = new List<byte>(input.Length + (input.Length / 255) + 16);
        int literalLength = input.Length;
        int token = Math.Min(literalLength, 15) << 4;
        output.Add((byte)token);

        if (literalLength >= 15)
            WriteExtendedLength(output, literalLength - 15);

        output.AddRange(input);
        return output.ToArray();
    }

    private static void WriteExtendedLength(List<byte> output, int length)
    {
        while (length >= 255)
        {
            output.Add(255);
            length -= 255;
        }
        output.Add((byte)length);
    }
}
"@
}

function Get-Fnv1a64Hash {
    param([string]$Text)
    Initialize-BinaryCodec
    return [PokeFeurBinaryUtil]::Fnv1a64($Text)
}

function Read-Gfpak {
    param([string]$Path)

    $data = [IO.File]::ReadAllBytes($Path)
    $magic = Read-U64 -Data $data -Offset 0
    if ($magic -ne 0x4B434150584C4647) {
        throw "GFPak invalide: magic absent dans '$Path'."
    }

    $fileCount = Read-I32 -Data $data -Offset 16
    $folderCount = Read-I32 -Data $data -Offset 20
    $ptrFileTable = [BitConverter]::ToInt64($data, 24)
    $ptrHashPaths = [BitConverter]::ToInt64($data, 32)
    $ptrHashFolders = New-Object System.Collections.Generic.List[long]
    for ($i = 0; $i -lt $folderCount; $i++) {
        $ptrHashFolders.Add([BitConverter]::ToInt64($data, 40 + ($i * 8)))
    }

    $hashAbsolute = New-Object System.Collections.Generic.List[object]
    for ($i = 0; $i -lt $fileCount; $i++) {
        $hashAbsolute.Add((Read-U64 -Data $data -Offset ([int]($ptrHashPaths + ($i * 8)))))
    }

    $hashFolders = New-Object System.Collections.Generic.List[object]
    foreach ($folderPtr in $ptrHashFolders) {
        $folderOffset = [int]$folderPtr
        $folderFileCount = Read-I32 -Data $data -Offset ($folderOffset + 8)
        $folder = [ordered]@{
            Hash = Read-U64 -Data $data -Offset $folderOffset
            FileCount = $folderFileCount
            Padding = [BitConverter]::ToUInt32($data, $folderOffset + 12)
            Files = New-Object System.Collections.Generic.List[object]
        }

        $entryOffset = $folderOffset + 0x10
        for ($i = 0; $i -lt $folderFileCount; $i++) {
            $folder.Files.Add([ordered]@{
                Hash = Read-U64 -Data $data -Offset ($entryOffset + ($i * 0x10))
                Index = Read-I32 -Data $data -Offset ($entryOffset + ($i * 0x10) + 8)
                Padding = [BitConverter]::ToUInt32($data, $entryOffset + ($i * 0x10) + 12)
            })
        }
        $hashFolders.Add([pscustomobject]$folder)
    }

    $fileTable = New-Object 'object[]' $fileCount
    $compressedFiles = New-Object 'object[]' $fileCount
    for ($i = 0; $i -lt $fileCount; $i++) {
        $offset = [int]($ptrFileTable + ($i * 0x18))
        $entry = [pscustomobject]@{
            Level = Read-U16 -Data $data -Offset $offset
            Type = [int]$data[$offset + 2]
            Reserved = [int]$data[$offset + 3]
            SizeDecompressed = Read-I32 -Data $data -Offset ($offset + 4)
            SizeCompressed = Read-I32 -Data $data -Offset ($offset + 8)
            Padding = Read-I32 -Data $data -Offset ($offset + 12)
            OffsetPacked = Read-I32 -Data $data -Offset ($offset + 16)
            Unused = [BitConverter]::ToUInt32($data, $offset + 20)
        }
        $fileTable[$i] = $entry
        $compressed = New-Object byte[] $entry.SizeCompressed
        [Array]::Copy($data, $entry.OffsetPacked, $compressed, 0, $entry.SizeCompressed)
        $compressedFiles[$i] = $compressed
    }

    return [pscustomobject]@{
        Path = $Path
        Header = [pscustomobject]@{
            Magic = $magic
            Version = [BitConverter]::ToUInt32($data, 8)
            IsRelocated = [BitConverter]::ToUInt32($data, 12)
            CountFiles = $fileCount
            CountFolders = $folderCount
        }
        HashAbsolute = $hashAbsolute
        HashFolders = $hashFolders
        FileTable = $fileTable
        CompressedFiles = $compressedFiles
        ModifiedFiles = @{}
    }
}

function Get-GfpakFileIndexByName {
    param(
        [object]$Pack,
        [string]$Name
    )

    $hash = Get-Fnv1a64Hash -Text $Name
    foreach ($folder in $Pack.HashFolders) {
        foreach ($file in $folder.Files) {
            if ($file.Hash -eq $hash) {
                return [int]$file.Index
            }
        }
    }
    return -1
}

function Expand-GfpakData {
    param(
        [byte[]]$CompressedData,
        [int]$DecompressedLength,
        [int]$CompressionType
    )

    switch ($CompressionType) {
        0 {
            $copy = New-Object byte[] $CompressedData.Length
            [Array]::Copy($CompressedData, 0, $copy, 0, $CompressedData.Length)
            return ,$copy
        }
        2 {
            Initialize-BinaryCodec
            return ,[PokeFeurBinaryUtil]::Lz4Decompress($CompressedData, $DecompressedLength)
        }
        default {
            throw "Compression GFPak non supportee pour ce script: type $CompressionType."
        }
    }
}

function Compress-GfpakData {
    param(
        [byte[]]$Data,
        [int]$CompressionType
    )

    switch ($CompressionType) {
        0 {
            return ,$Data
        }
        2 {
            Initialize-BinaryCodec
            return ,[PokeFeurBinaryUtil]::Lz4CompressLiteral($Data)
        }
        default {
            throw "Compression GFPak non supportee pour ce script: type $CompressionType."
        }
    }
}

function Get-GfpakDataFileName {
    param(
        [object]$Pack,
        [string]$Name
    )

    $index = Get-GfpakFileIndexByName -Pack $Pack -Name $Name
    if ($index -lt 0) {
        return $null
    }

    if ($Pack.ModifiedFiles.ContainsKey($index)) {
        return ,[byte[]]$Pack.ModifiedFiles[$index]
    }

    $entry = $Pack.FileTable[$index]
    $expanded = Expand-GfpakData -CompressedData ([byte[]]$Pack.CompressedFiles[$index]) -DecompressedLength $entry.SizeDecompressed -CompressionType $entry.Type
    return ,$expanded
}

function Set-GfpakDataFileName {
    param(
        [object]$Pack,
        [string]$Name,
        [byte[]]$Data
    )

    $index = Get-GfpakFileIndexByName -Pack $Pack -Name $Name
    if ($index -lt 0) {
        throw "Fichier '$Name' introuvable dans le GFPak."
    }
    $Pack.ModifiedFiles[$index] = $Data
}

function Write-Gfpak {
    param(
        [object]$Pack,
        [string]$Path
    )

    $fileCount = [int]$Pack.Header.CountFiles
    $folderCount = [int]$Pack.Header.CountFolders
    $encodedFiles = New-Object 'object[]' $fileCount
    $newFileTable = New-Object 'object[]' $fileCount

    for ($i = 0; $i -lt $fileCount; $i++) {
        $oldEntry = $Pack.FileTable[$i]
        if ($Pack.ModifiedFiles.ContainsKey($i)) {
            $decompressed = [byte[]]$Pack.ModifiedFiles[$i]
            $compressed = Compress-GfpakData -Data $decompressed -CompressionType $oldEntry.Type
            $sizeDecompressed = $decompressed.Length
            $sizeCompressed = $compressed.Length
        } else {
            $compressed = [byte[]]$Pack.CompressedFiles[$i]
            $sizeDecompressed = $oldEntry.SizeDecompressed
            $sizeCompressed = $oldEntry.SizeCompressed
        }

        $encodedFiles[$i] = $compressed
        $newFileTable[$i] = [pscustomobject]@{
            Level = $oldEntry.Level
            Type = $oldEntry.Type
            Reserved = $oldEntry.Reserved
            SizeDecompressed = $sizeDecompressed
            SizeCompressed = $sizeCompressed
            Padding = $oldEntry.Padding
            OffsetPacked = 0
            Unused = $oldEntry.Unused
        }
    }

    $headerSize = 0x18
    $pointerSize = 0x10 + ($folderCount * 8)
    $ptrHashPaths = $headerSize + $pointerSize
    $cursor = $ptrHashPaths + ($fileCount * 8)
    $ptrHashFolders = New-Object System.Collections.Generic.List[long]
    foreach ($folder in $Pack.HashFolders) {
        $ptrHashFolders.Add([long]$cursor)
        $cursor += 0x10 + ($folder.Files.Count * 0x10)
    }
    $ptrFileTable = $cursor
    $payloadOffset = $ptrFileTable + ($fileCount * 0x18)
    $cursor = $payloadOffset

    for ($i = 0; $i -lt $fileCount; $i++) {
        $newFileTable[$i].OffsetPacked = [int]$cursor
        $cursor += ([byte[]]$encodedFiles[$i]).Length
        while (($cursor % 0x10) -ne 0) {
            $cursor++
        }
    }

    $ms = New-Object IO.MemoryStream
    $bw = New-Object IO.BinaryWriter($ms)
    try {
        $bw.Write([uint64]$Pack.Header.Magic)
        $bw.Write([uint32]$Pack.Header.Version)
        $bw.Write([uint32]$Pack.Header.IsRelocated)
        $bw.Write([int]$fileCount)
        $bw.Write([int]$folderCount)
        $bw.Write([int64]$ptrFileTable)
        $bw.Write([int64]$ptrHashPaths)
        foreach ($ptr in $ptrHashFolders) {
            $bw.Write([int64]$ptr)
        }

        foreach ($hash in $Pack.HashAbsolute) {
            $bw.Write([uint64]$hash)
        }

        foreach ($folder in $Pack.HashFolders) {
            $bw.Write([uint64]$folder.Hash)
            $bw.Write([int]$folder.Files.Count)
            $bw.Write([uint32]$folder.Padding)
            foreach ($file in $folder.Files) {
                $bw.Write([uint64]$file.Hash)
                $bw.Write([int]$file.Index)
                $bw.Write([uint32]$file.Padding)
            }
        }

        foreach ($entry in $newFileTable) {
            $bw.Write([uint16]$entry.Level)
            $bw.Write([byte]$entry.Type)
            $bw.Write([byte]$entry.Reserved)
            $bw.Write([int]$entry.SizeDecompressed)
            $bw.Write([int]$entry.SizeCompressed)
            $bw.Write([int]$entry.Padding)
            $bw.Write([int]$entry.OffsetPacked)
            $bw.Write([uint32]$entry.Unused)
        }

        for ($i = 0; $i -lt $fileCount; $i++) {
            $encoded = [byte[]]$encodedFiles[$i]
            $bw.Write($encoded)
            while (($bw.BaseStream.Position % 0x10) -ne 0) {
                $bw.Write([byte]0)
            }
        }

        $bw.Flush()
        [IO.File]::WriteAllBytes($Path, $ms.ToArray())
    } finally {
        $bw.Dispose()
        $ms.Dispose()
    }
}

function Get-SwShEncounterSubTableName {
    param([int]$Index)

    $names = @(
        "Normal Weather",
        "Overcast",
        "Raining",
        "Thunderstorm",
        "Intense Sun",
        "Snowing",
        "Snowstorm",
        "Sandstorm",
        "Heavy Fog",
        "Shaking Trees",
        "Fishing"
    )
    if ($Index -ge 0 -and $Index -lt $names.Count) {
        return $names[$Index]
    }
    return "SubTable $Index"
}

function Invoke-EncounterArchiveGrassRandomization {
    param(
        [string]$RomfsRoot,
        [byte[]]$Data,
        [System.Random]$Rng,
        [string]$ModeValue,
        [bool]$AllowLegendarySpecies,
        [string]$InternalFileName,
        [string]$StableMappingMode = "Slot",
        [hashtable]$StableMap = $null,
        [int[]]$VisualSpeciesPool = @(),
        [int[]]$RestrictToSpeciesPool = @(),
        [int[]]$RestrictVisibleToSpeciesPool = @()
    )

    $mode = Normalize-Mode $ModeValue
    if ($mode -eq "unchanged") {
        return [pscustomobject]@{
            Edited = 0
            Data = $Data
            Changes = @()
        }
    }

    $context = @{
        BaseSpeciesPool = Get-BaseSpeciesPool -AllowLegendaries $AllowLegendarySpecies -RomfsRoot $RomfsRoot
        BaseSpeciesEntries = @{}
        SimilarBstCache = @{}
    }
    $entries = Get-PersonalEntries -RomfsRoot $RomfsRoot
    for ($i = 1; $i -le $BaseSpeciesMax; $i++) {
        $context.BaseSpeciesEntries[$i] = $entries[$i]
    }

    $edited = 0
    $changes = New-Object System.Collections.Generic.List[object]
    $isSymbolEncounterTable = ([string]$InternalFileName).ToLowerInvariant().Contains("symbol")
    $changeBlockName = if ($isSymbolEncounterTable) { "symbolOverworldEncounter" } else { "grassEncounter" }
    $stableMode = Normalize-StableMappingMode -Value $StableMappingMode
    if ($null -eq $StableMap) {
        $StableMap = @{}
    }
    $root = Get-FlatBufferRootTablePosition -Data $Data
    $encounterTables = @(Get-FlatBufferTableVectorEntries -Data $Data -TablePos $root -FieldIndex 1)

    if ($isSymbolEncounterTable) {
        $visualPool = @($VisualSpeciesPool)
        if ($visualPool.Count -eq 0) {
            $symbolSpecies = [System.Collections.Generic.HashSet[int]]::new()
            foreach ($tablePosForPool in $encounterTables) {
                foreach ($subTablePosForPool in @(Get-FlatBufferTableVectorEntries -Data $Data -TablePos $tablePosForPool -FieldIndex 1)) {
                    foreach ($slotPosForPool in @(Get-FlatBufferTableVectorEntries -Data $Data -TablePos $subTablePosForPool -FieldIndex 2)) {
                        $speciesAddressForPool = Get-FlatBufferFieldAddress -Data $Data -TablePos $slotPosForPool -FieldIndex 1
                        if ($speciesAddressForPool -ge 0) {
                            $speciesForPool = [int](Read-U32 -Data $Data -Offset $speciesAddressForPool)
                            if ($speciesForPool -gt 0 -and $speciesForPool -le $BaseSpeciesMax) {
                                $null = $symbolSpecies.Add($speciesForPool)
                            }
                        }
                    }
                }
            }
            $visualPool = @($symbolSpecies | Sort-Object)
        }
        if ($visualPool.Count -gt 0) {
            $context.BaseSpeciesPool = [int[]]@($visualPool)
        }
    }

    # La table des SYMBOLES suit le filtre « visibles dehors », celle des herbes
    # hautes le filtre « affrontes ». Ce sont deux reglages independants : voir
    # un Pangoleon dehors ne doit rien dire de ce qu'on affrontera.
    $restrictionActive = if ($isSymbolEncounterTable -and (Get-ObjectArrayCount $RestrictVisibleToSpeciesPool) -gt 0) {
        [int[]]$RestrictVisibleToSpeciesPool
    } else {
        [int[]]$RestrictToSpeciesPool
    }
    if ((Get-ObjectArrayCount $restrictionActive) -gt 0) {
        $autoriseesHerbe = [System.Collections.Generic.HashSet[int]]::new()
        foreach ($espece in $restrictionActive) { $null = $autoriseesHerbe.Add([int]$espece) }
        $poolHerbe = @($context.BaseSpeciesPool | Where-Object { $autoriseesHerbe.Contains([int]$_) })
        # Une intersection vide viderait le tirage : on garde alors le reservoir
        # d'origine plutot que de ne rien pouvoir ecrire.
        if ($poolHerbe.Count -gt 0) {
            $context.BaseSpeciesPool = [int[]]$poolHerbe
        }
    }

    for ($tableIndex = 0; $tableIndex -lt $encounterTables.Count; $tableIndex++) {
        $tablePos = $encounterTables[$tableIndex]
        $zoneAddress = Get-FlatBufferFieldAddress -Data $Data -TablePos $tablePos -FieldIndex 0
        $zoneId = if ($zoneAddress -ge 0) { Read-U64 -Data $Data -Offset $zoneAddress } else { [uint64]0 }
        $subTables = @(Get-FlatBufferTableVectorEntries -Data $Data -TablePos $tablePos -FieldIndex 1)

        for ($subTableIndex = 0; $subTableIndex -lt $subTables.Count; $subTableIndex++) {
            if ($subTableIndex -ge 9) {
                continue
            }

            $subTablePos = $subTables[$subTableIndex]
            $levelMinAddress = Get-FlatBufferFieldAddress -Data $Data -TablePos $subTablePos -FieldIndex 0
            $levelMaxAddress = Get-FlatBufferFieldAddress -Data $Data -TablePos $subTablePos -FieldIndex 1
            $levelMin = if ($levelMinAddress -ge 0) { [int]$Data[$levelMinAddress] } else { 0 }
            $levelMax = if ($levelMaxAddress -ge 0) { [int]$Data[$levelMaxAddress] } else { 0 }
            $slots = @(Get-FlatBufferTableVectorEntries -Data $Data -TablePos $subTablePos -FieldIndex 2)

            for ($slotIndex = 0; $slotIndex -lt $slots.Count; $slotIndex++) {
                $slotPos = $slots[$slotIndex]
                $speciesAddress = Get-FlatBufferFieldAddress -Data $Data -TablePos $slotPos -FieldIndex 1
                if ($speciesAddress -lt 0) {
                    continue
                }

                $speciesId = [int](Read-U32 -Data $Data -Offset $speciesAddress)
                if ($speciesId -le 0 -or $speciesId -gt $BaseSpeciesMax) {
                    continue
                }

                $probabilityAddress = Get-FlatBufferFieldAddress -Data $Data -TablePos $slotPos -FieldIndex 0
                $formAddress = Get-FlatBufferFieldAddress -Data $Data -TablePos $slotPos -FieldIndex 2
                $probability = if ($probabilityAddress -ge 0) { [int]$Data[$probabilityAddress] } else { 0 }
                $formBefore = if ($formAddress -ge 0) { [int]$Data[$formAddress] } else { 0 }
                $stableKey = switch ($stableMode) {
                    "species" { "$InternalFileName|$tableIndex|$zoneId|species:$speciesId|form:$formBefore" }
                    "random" { "" }
                    default { "$InternalFileName|$tableIndex|$zoneId|$subTableIndex|$slotIndex|$speciesId|$formBefore" }
                }
                $replacement = Get-StableSpeciesReplacement -Rng $Rng -CurrentSpeciesId $speciesId -Mode $mode -Context $context -StableMap $StableMap -StableKey $stableKey
                if ($replacement -eq $speciesId) {
                    continue
                }

                Write-U32 -Data $Data -Offset $speciesAddress -Value ([uint32]$replacement)
                if ($formAddress -ge 0) {
                    $Data[$formAddress] = 0
                }

                $changes.Add([ordered]@{
                    block = $changeBlockName
                    mappingMode = $stableMode
                    visualMode = "romfsSpeciesChanged"
                    appliedToRomfs = $true
                    file = "data_table.gfpak"
                    internalFile = $InternalFileName
                    tableIndex = $tableIndex + 1
                    zoneId = ("0x{0:X16}" -f $zoneId)
                    subTableIndex = $subTableIndex + 1
                    subTable = Get-SwShEncounterSubTableName -Index $subTableIndex
                    slotIndex = $slotIndex + 1
                    probability = $probability
                    levelMin = $levelMin
                    levelMax = $levelMax
                    dataOffset = $speciesAddress
                    species = [ordered]@{
                        before = New-SpeciesReportObject -SpeciesId $speciesId
                        after = New-SpeciesReportObject -SpeciesId $replacement
                        visual = New-SpeciesReportObject -SpeciesId $replacement
                        battle = New-SpeciesReportObject -SpeciesId $replacement
                    }
                    form = [ordered]@{
                        before = $formBefore
                        after = 0
                    }
                })
                $edited++
            }
        }
    }

    return [pscustomobject]@{
        Edited = $edited
        Data = $Data
        Changes = [object[]]$changes.ToArray()
    }
}

# ---------------------------------------------------------------------------
# NIVEAUX DES POKEMON SAUVAGES
#
# Meme archive que les tables de rencontres :
#   bin\archive\field\resident\data_table.gfpak
#
# Structure verifiee (celle qu'utilise deja la randomisation des rencontres) :
#   racine     champ 1  vector<table de rencontres>
#   table      champ 1  vector<sous-tables>
#   sous-table champ 0  u8  niveau minimum
#              champ 1  u8  niveau maximum
#              champ 2  vector<emplacements>
#
# Les deux niveaux sont mis a l'echelle par le meme facteur, donc l'ordre
# minimum <= maximum est preserve. Bornes du jeu : 1 a 100.
# ---------------------------------------------------------------------------
function Invoke-WildLevelAdjustment {
    param(
        [string]$RomfsRoot,
        [int]$Percent
    )

    $result = [pscustomobject]@{ Edited = 0; Skipped = "" }
    if ($Percent -eq 0) {
        return $result
    }

    $path = Get-FieldResidentDataTablePath -RomfsRoot $RomfsRoot
    if (-not (Test-Path -LiteralPath $path)) {
        $result.Skipped = "data_table.gfpak absent"
        return $result
    }

    $factor = 1.0 + ([double]$Percent / 100.0)
    $pack = Read-Gfpak -Path $path
    $edited = 0

    foreach ($internalFile in @("encount_k.bin", "encount_t.bin", "encount_symbol_k.bin", "encount_symbol_t.bin")) {
        $data = Get-GfpakDataFileName -Pack $pack -Name $internalFile
        if ($null -eq $data) {
            continue
        }

        $fileEdited = 0
        $root = Get-FlatBufferRootTablePosition -Data $data
        if ($root -le 0 -or $root -ge $data.Length) {
            continue
        }

        foreach ($tablePos in (Get-FlatBufferTableVectorEntries -Data $data -TablePos $root -FieldIndex 1)) {
            foreach ($subTablePos in (Get-FlatBufferTableVectorEntries -Data $data -TablePos $tablePos -FieldIndex 1)) {
                foreach ($levelFieldIndex in @(0, 1)) {
                    $address = Get-FlatBufferFieldAddress -Data $data -TablePos $subTablePos -FieldIndex $levelFieldIndex
                    if ($address -lt 0 -or $address -ge $data.Length) {
                        continue
                    }
                    $level = [int]$data[$address]
                    if ($level -le 0 -or $level -gt 100) {
                        continue
                    }
                    $scaled = [int][Math]::Round($level * $factor)
                    if ($scaled -lt 1) { $scaled = 1 }
                    if ($scaled -gt 100) { $scaled = 100 }
                    if ($scaled -eq $level) {
                        continue
                    }
                    $data[$address] = [byte]$scaled
                    $fileEdited++
                }
            }
        }

        if ($fileEdited -gt 0) {
            Set-GfpakDataFileName -Pack $pack -Name $internalFile -Data $data
            $edited += $fileEdited
        }
    }

    if ($edited -gt 0) {
        Write-Gfpak -Pack $pack -Path $path
    }
    $result.Edited = $edited
    return $result
}

function Invoke-GrassEncounterRandomization {
    param(
        [string]$RomfsRoot,
        [System.Random]$Rng,
        [string]$ModeValue,
        [bool]$AllowLegendarySpecies,
        [string]$StableMappingMode = "Slot",
        [bool]$IncludeVisibleSymbols = $true,
        [hashtable]$StableMap = $null,
        [int[]]$VisualSpeciesPool = @(),
        [int[]]$RestrictToSpeciesPool = @(),
        [int[]]$RestrictVisibleToSpeciesPool = @()
    )

    $mode = Normalize-Mode $ModeValue
    $path = Get-FieldResidentDataTablePath -RomfsRoot $RomfsRoot
    if ($mode -eq "unchanged" -or (-not (Test-Path -LiteralPath $path))) {
        return [pscustomobject]@{
            Edited = 0
            Changes = @()
        }
    }

    $pack = Read-Gfpak -Path $path
    $edited = 0
    $changes = New-Object System.Collections.Generic.List[object]
    if ($null -eq $StableMap) {
        $StableMap = @{}
    }
    foreach ($internalFile in @("encount_k.bin", "encount_t.bin", "encount_symbol_k.bin", "encount_symbol_t.bin")) {
        if ((-not $IncludeVisibleSymbols) -and ([string]$internalFile).ToLowerInvariant().Contains("symbol")) {
            continue
        }

        $archiveData = Get-GfpakDataFileName -Pack $pack -Name $internalFile
        if ($null -eq $archiveData) {
            continue
        }

        $archiveResult = Invoke-EncounterArchiveGrassRandomization `
            -RomfsRoot $RomfsRoot `
            -Data $archiveData `
            -Rng $Rng `
            -ModeValue $ModeValue `
            -AllowLegendarySpecies $AllowLegendarySpecies `
            -InternalFileName $internalFile `
            -StableMappingMode $StableMappingMode `
            -StableMap $StableMap `
            -VisualSpeciesPool $VisualSpeciesPool `
            -RestrictToSpeciesPool $RestrictToSpeciesPool `
            -RestrictVisibleToSpeciesPool $RestrictVisibleToSpeciesPool

        if ($archiveResult.Edited -gt 0) {
            Set-GfpakDataFileName -Pack $pack -Name $internalFile -Data $archiveResult.Data
            $edited += $archiveResult.Edited
        }
        foreach ($change in $archiveResult.Changes) {
            $changes.Add($change)
        }
    }

    if ($edited -gt 0) {
        Write-Gfpak -Pack $pack -Path $path
    }

    return [pscustomobject]@{
        Edited = $edited
        Changes = [object[]]$changes.ToArray()
    }
}

function Invoke-FlatBufferSpeciesFieldRandomization {
    param(
        [string]$RomfsRoot,
        [string]$Path,
        [int[]]$FieldIndices,
        [System.Random]$Rng,
        [string]$ModeValue,
        [bool]$AllowLegendarySpecies,
        [string]$BlockName = "",
        [string]$StableMappingMode = "Slot",
        [hashtable]$StableMap = $null,
        [int[]]$RestrictToSpeciesPool = @()
    )

    $mode = Normalize-Mode $ModeValue
    if ($mode -eq "unchanged" -or (-not (Test-Path -LiteralPath $Path))) {
        return [pscustomobject]@{
            Edited = 0
            Changes = @()
        }
    }

    $data = [IO.File]::ReadAllBytes($Path)
    $context = $null
    if ($mode -ne "unchanged") {
        $context = @{
            BaseSpeciesPool = Get-BaseSpeciesPool -AllowLegendaries $AllowLegendarySpecies -RomfsRoot $RomfsRoot
            BaseSpeciesEntries = @{}
            SimilarBstCache = @{}
        }
        $entries = Get-PersonalEntries -RomfsRoot $RomfsRoot
        for ($i = 1; $i -le $BaseSpeciesMax; $i++) {
            $context.BaseSpeciesEntries[$i] = $entries[$i]
        }
        if ((Get-ObjectArrayCount $RestrictToSpeciesPool) -gt 0) {
            $autorisees = [System.Collections.Generic.HashSet[int]]::new()
            foreach ($espece in $RestrictToSpeciesPool) { $null = $autorisees.Add([int]$espece) }
            $poolRestreint = @($context.BaseSpeciesPool | Where-Object { $autorisees.Contains([int]$_) })
            # Une intersection vide voudrait dire « plus rien a tirer » : on
            # garde alors le reservoir complet plutot que de ne rien changer.
            if ($poolRestreint.Count -gt 0) {
                $context.BaseSpeciesPool = [int[]]$poolRestreint
            }
        }
    }

    $edited = 0
    $changes = New-Object System.Collections.Generic.List[object]
    $tableIndex = 0
    $stableMode = Normalize-StableMappingMode -Value $StableMappingMode
    if ($null -eq $StableMap) {
        $StableMap = @{}
    }
    foreach ($tablePos in Get-FlatBufferTableVectorPositions -Data $data) {
        $tableIndex++
        foreach ($fieldIndex in $FieldIndices) {
            $address = Get-FlatBufferFieldAddress -Data $data -TablePos $tablePos -FieldIndex $fieldIndex
            if ($address -lt 0) {
                continue
            }

            $speciesId = [int](Read-U32 -Data $data -Offset $address)
            if ($speciesId -le 0 -or $speciesId -gt $BaseSpeciesMax) {
                continue
            }

            $stableKey = switch ($stableMode) {
                "species" { "species:$speciesId" }
                "random" { "" }
                default { "$BlockName|$tableIndex|$fieldIndex|$speciesId" }
            }
            $replacement = Get-StableSpeciesReplacement -Rng $Rng -CurrentSpeciesId $speciesId -Mode $mode -Context $context -StableMap $StableMap -StableKey $stableKey
            if ($replacement -ne $speciesId) {
                Write-U32 -Data $data -Offset $address -Value ([uint32]$replacement)
                $changes.Add([ordered]@{
                    block = $BlockName
                    mappingMode = $stableMode
                    visualMode = "romfsSpeciesChanged"
                    appliedToRomfs = $true
                    file = Split-Path -Leaf $Path
                    tableIndex = $tableIndex
                    fieldIndex = $fieldIndex
                    dataOffset = $address
                    species = [ordered]@{
                        before = New-SpeciesReportObject -SpeciesId $speciesId
                        after = New-SpeciesReportObject -SpeciesId $replacement
                        visual = New-SpeciesReportObject -SpeciesId $replacement
                        battle = New-SpeciesReportObject -SpeciesId $replacement
                    }
                })
                $edited++
            }
        }
    }

    if ($edited -gt 0) {
        [IO.File]::WriteAllBytes($Path, $data)
    }

    return [pscustomobject]@{
        Edited = $edited
        Changes = [object[]]$changes.ToArray()
    }
}

function Get-FlatBufferUIntVectorAddresses {
    param(
        [byte[]]$Data,
        [int]$VectorFieldAddress
    )

    if ($VectorFieldAddress -lt 0 -or ($VectorFieldAddress + 4) -gt $Data.Length) {
        return @()
    }

    $rawVectorOffset = [uint32](Read-U32 -Data $Data -Offset $VectorFieldAddress)
    if ($rawVectorOffset -gt [uint32][int]::MaxValue) {
        return @()
    }

    $vectorPos = $VectorFieldAddress + [int]$rawVectorOffset
    if ($vectorPos -lt 0 -or ($vectorPos + 4) -gt $Data.Length) {
        return @()
    }

    $rawCount = [uint32](Read-U32 -Data $Data -Offset $vectorPos)
    if ($rawCount -gt 10000) {
        return @()
    }

    $count = [int]$rawCount
    if (($vectorPos + 4 + ($count * 4)) -gt $Data.Length) {
        return @()
    }
    $addresses = New-Object System.Collections.Generic.List[int]
    for ($index = 0; $index -lt $count; $index++) {
        $address = $vectorPos + 4 + ($index * 4)
        if (($address + 4) -gt $Data.Length) {
            break
        }
        $addresses.Add($address)
    }
    return $addresses
}

# ---------------------------------------------------------------------------
# PRIX DES OBJETS â€” bin\pml\item\item.dat
#
# Structure verifiee sur Epee 1.3.2 (50 972 octets) :
#   0x40                 u32        debut de la table d'enregistrements (4652)
#   0x44                 u16[1609]  itemId -> numero d'enregistrement
#   4652                 965 enregistrements de 48 octets
#       +0  u32  prix d'achat en Pokedollars
#       +4  u32  prix dans une devise secondaire (Watts ou PC, non confirme)
#
# Preuve arithmetique : 4652 + 965*48 = 50972, exactement la taille du fichier.
# Controle croise avec les prix reels du jeu : Poke Ball 200, Hyper Potion 1500,
# Super Bonbon 10000, DT00 4000.
#
# L'enregistrement numero 0 est partage par des centaines d'objets factices
# (None, objets inutilises). On ne le touche pas : une seule ecriture dessus
# changerait le prix de tout un paquet d'objets sans rapport.
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# OBJETS AU SOL ET OBJETS CACHES
#
# Les deux vivent dans le meme fichier :
#   bin\archive\field\resident\placement.gfpak
# Archive GFPAK -> une entree LZ4 par zone -> FlatBuffers.
#
# Chemin verifie sur Epee 1.3.2 :
#   racine        champ 0   vector<PlacementZone>
#   PlacementZone champ 6   vector<porteur d'objet au sol>
#       porteur   champ 0   table
#           champ 6   vector<u64>  hachages d'objets   <- objets au sol
#           champ 7   vector<u32>  quantites
#   PlacementZone champ 19  vector<porteur d'objet cache>
#       porteur   champ 0   table
#           champ 2   vector<table>  chaque entree :
#               champ 0   u64  hachage d'objet         <- objets caches
#               champ 1   i32  probabilite
#               champ 2   i32  quantite
#
# Les objets ne sont PAS stockes par identifiant mais par hachage FNV-1a 64
# (basis GameFreak 0xCBF29CE484222645). La correspondance se lit dans
# bin\pml\item\item_hash_to_index.dat : u32 nombre, puis N x { u64 hachage ;
# u32 identifiant ; u32 remplissage }.
#
# Le hachage de la chaine vide (0xCBF29CE484222645) sert de marqueur
# "emplacement vide" : on ne le remplace jamais, sinon on ferait apparaitre des
# objets la ou le jeu n'en prevoit pas.
#
# Toutes les ecritures sont faites sur place, sans changer la taille : aucune
# reconstruction de FlatBuffers necessaire.
# ---------------------------------------------------------------------------

# Hachage de la chaine vide = marqueur "emplacement sans objet".
# On NE peut PAS ecrire [uint64]0xCBF29CE484222645 : PowerShell 5.1 lit les
# litteraux hexadecimaux comme des entiers signes, la valeur depasse Int64 et
# devient negative, et le cast en UInt64 echoue.
$ItemHashEmptySlot = [uint64]::Parse("CBF29CE484222645", [Globalization.NumberStyles]::HexNumber)

function Get-FlatBufferNestedTablePosition {
    param(
        [byte[]]$Data,
        [int]$TablePos,
        [int]$FieldIndex
    )

    $fieldAddress = Get-FlatBufferFieldAddress -Data $Data -TablePos $TablePos -FieldIndex $FieldIndex
    if ($fieldAddress -lt 0 -or ($fieldAddress + 4) -gt $Data.Length) {
        return -1
    }
    $target = $fieldAddress + [int](Read-U32 -Data $Data -Offset $fieldAddress)
    if ($target -lt 0 -or $target -ge $Data.Length) {
        return -1
    }
    return $target
}

function Get-FlatBufferU64VectorAddresses {
    param(
        [byte[]]$Data,
        [int]$TablePos,
        [int]$FieldIndex
    )

    $fieldAddress = Get-FlatBufferFieldAddress -Data $Data -TablePos $TablePos -FieldIndex $FieldIndex
    if ($fieldAddress -lt 0 -or ($fieldAddress + 4) -gt $Data.Length) {
        return @()
    }
    $vectorPos = $fieldAddress + [int](Read-U32 -Data $Data -Offset $fieldAddress)
    if ($vectorPos -lt 0 -or ($vectorPos + 4) -gt $Data.Length) {
        return @()
    }
    $count = [int](Read-U32 -Data $Data -Offset $vectorPos)
    if ($count -lt 0 -or $count -gt 10000) {
        return @()
    }
    $addresses = New-Object System.Collections.Generic.List[int]
    for ($index = 0; $index -lt $count; $index++) {
        $address = $vectorPos + 4 + ($index * 8)
        if (($address + 8) -gt $Data.Length) {
            break
        }
        $addresses.Add($address)
    }
    return $addresses
}

function Get-ItemHashLookup {
    param([string]$RomfsRoot)

    if ($script:ItemHashLookup) {
        return $script:ItemHashLookup
    }

    $lookup = @{ HashByItemId = @{}; ItemIdByHash = @{} }
    $path = Join-Path $RomfsRoot "bin\pml\item\item_hash_to_index.dat"
    if (-not (Test-Path -LiteralPath $path)) {
        $script:ItemHashLookup = $lookup
        return $lookup
    }

    $data = [IO.File]::ReadAllBytes($path)
    if ($data.Length -lt 4) {
        $script:ItemHashLookup = $lookup
        return $lookup
    }

    $count = [int](Read-U32 -Data $data -Offset 0)
    # Verification de coherence : 4 + count*16 doit valoir exactement la taille.
    if ($count -le 0 -or (4 + ($count * 16)) -ne $data.Length) {
        $script:ItemHashLookup = $lookup
        return $lookup
    }

    for ($i = 0; $i -lt $count; $i++) {
        $offset = 4 + ($i * 16)
        $hash = [uint64](Read-U64 -Data $data -Offset $offset)
        $itemId = [int](Read-U32 -Data $data -Offset ($offset + 8))
        if (-not $lookup.HashByItemId.ContainsKey($itemId)) {
            $lookup.HashByItemId[$itemId] = $hash
        }
        $lookup.ItemIdByHash[$hash] = $itemId
    }

    $script:ItemHashLookup = $lookup
    return $lookup
}

# Reservoir de remplacement pour les objets du terrain.
#   "safe"  : tout sauf les objets cle (reservoir deja utilise par les boutiques)
#   "all"   : idem plus les CT et DT
function Get-FieldItemReplacementPool {
    param(
        [string]$PoolMode,
        [hashtable]$Lookup
    )

    $pool = switch (Normalize-Mode $PoolMode) {
        "all" { @((Get-GeneralRandomItemPool) + (Get-TechnicalRecordItemPool)); break }
        default { @(Get-GeneralRandomItemPool) }
    }

    # Un objet sans hachage connu ne peut pas etre ecrit dans le terrain :
    # le jeu ne saurait pas le resoudre.
    return [int[]]@($pool | Where-Object { $Lookup.HashByItemId.ContainsKey([int]$_) })
}

function Invoke-FieldItemRandomization {
    param(
        [string]$RomfsRoot,
        [System.Random]$Rng,
        [bool]$DoGroundItems,
        [bool]$DoHiddenItems,
        [string]$PoolMode = "Safe"
    )

    $result = [pscustomobject]@{ GroundEdited = 0; HiddenEdited = 0; Skipped = ""; Changes = @() }
    if (-not $DoGroundItems -and -not $DoHiddenItems) {
        return $result
    }

    $path = Join-Path $RomfsRoot "bin\archive\field\resident\placement.gfpak"
    if (-not (Test-Path -LiteralPath $path)) {
        $result.Skipped = "placement.gfpak absent"
        return $result
    }

    $lookup = Get-ItemHashLookup -RomfsRoot $RomfsRoot
    if ($lookup.HashByItemId.Count -lt 1) {
        $result.Skipped = "item_hash_to_index.dat illisible"
        return $result
    }

    $pool = Get-FieldItemReplacementPool -PoolMode $PoolMode -Lookup $lookup
    if ($pool.Count -lt 1) {
        $result.Skipped = "reservoir d'objets vide"
        return $result
    }

    $pack = Read-Gfpak -Path $path
    $changes = New-Object System.Collections.Generic.List[object]
    $groundEdited = 0
    $hiddenEdited = 0

    for ($fileIndex = 0; $fileIndex -lt [int]$pack.Header.CountFiles; $fileIndex++) {
        $entry = $pack.FileTable[$fileIndex]
        if ($entry.SizeDecompressed -lt 16) {
            continue
        }

        $zoneData = $null
        try {
            $zoneData = [byte[]](Expand-GfpakData -CompressedData ([byte[]]$pack.CompressedFiles[$fileIndex]) -DecompressedLength $entry.SizeDecompressed -CompressionType $entry.Type)
        } catch {
            continue
        }
        if ($null -eq $zoneData -or $zoneData.Length -lt 16) {
            continue
        }

        $fileEdited = 0
        try {
            $root = Get-FlatBufferRootTablePosition -Data $zoneData
            if ($root -le 0 -or $root -ge $zoneData.Length) {
                continue
            }

            foreach ($zonePos in (Get-FlatBufferTableVectorEntries -Data $zoneData -TablePos $root -FieldIndex 0)) {
                if ($DoGroundItems) {
                    foreach ($holderPos in (Get-FlatBufferTableVectorEntries -Data $zoneData -TablePos $zonePos -FieldIndex 6)) {
                        $itemTable = Get-FlatBufferNestedTablePosition -Data $zoneData -TablePos $holderPos -FieldIndex 0
                        if ($itemTable -lt 0) { continue }
                        foreach ($address in (Get-FlatBufferU64VectorAddresses -Data $zoneData -TablePos $itemTable -FieldIndex 6)) {
                            $currentHash = [uint64](Read-U64 -Data $zoneData -Offset $address)
                            if ($currentHash -eq $ItemHashEmptySlot -or -not $lookup.ItemIdByHash.ContainsKey($currentHash)) {
                                continue
                            }
                            $beforeId = [int]$lookup.ItemIdByHash[$currentHash]
                            $newId = [int](Random-FromPool -Rng $Rng -Pool $pool)
                            if ($newId -eq $beforeId) { continue }
                            Write-U64 -Data $zoneData -Offset $address -Value ([uint64]$lookup.HashByItemId[$newId])
                            $groundEdited++
                            $fileEdited++
                            if ($changes.Count -lt 4000) {
                                $changes.Add([ordered]@{
                                    source = "fieldItem"
                                    file = "bin\archive\field\resident\placement.gfpak"
                                    zoneFileIndex = $fileIndex
                                    dataOffset = $address
                                    item = [ordered]@{
                                        before = New-ItemReportObject -ItemId $beforeId
                                        after = New-ItemReportObject -ItemId $newId
                                    }
                                })
                            }
                        }
                    }
                }

                if ($DoHiddenItems) {
                    foreach ($holderPos in (Get-FlatBufferTableVectorEntries -Data $zoneData -TablePos $zonePos -FieldIndex 19)) {
                        $hiddenTable = Get-FlatBufferNestedTablePosition -Data $zoneData -TablePos $holderPos -FieldIndex 0
                        if ($hiddenTable -lt 0) { continue }
                        foreach ($chancePos in (Get-FlatBufferTableVectorEntries -Data $zoneData -TablePos $hiddenTable -FieldIndex 2)) {
                            $hashAddress = Get-FlatBufferFieldAddress -Data $zoneData -TablePos $chancePos -FieldIndex 0
                            if ($hashAddress -lt 0 -or ($hashAddress + 8) -gt $zoneData.Length) { continue }
                            $currentHash = [uint64](Read-U64 -Data $zoneData -Offset $hashAddress)
                            if ($currentHash -eq $ItemHashEmptySlot -or -not $lookup.ItemIdByHash.ContainsKey($currentHash)) {
                                continue
                            }
                            $beforeId = [int]$lookup.ItemIdByHash[$currentHash]
                            $newId = [int](Random-FromPool -Rng $Rng -Pool $pool)
                            if ($newId -eq $beforeId) { continue }
                            Write-U64 -Data $zoneData -Offset $hashAddress -Value ([uint64]$lookup.HashByItemId[$newId])
                            $hiddenEdited++
                            $fileEdited++
                            if ($changes.Count -lt 4000) {
                                $changes.Add([ordered]@{
                                    source = "hiddenItem"
                                    file = "bin\archive\field\resident\placement.gfpak"
                                    zoneFileIndex = $fileIndex
                                    dataOffset = $hashAddress
                                    item = [ordered]@{
                                        before = New-ItemReportObject -ItemId $beforeId
                                        after = New-ItemReportObject -ItemId $newId
                                    }
                                })
                            }
                        }
                    }
                }
            }
        } catch {
            # Une zone au format inattendu ne doit pas faire echouer toute la passe.
            continue
        }

        if ($fileEdited -gt 0) {
            $pack.ModifiedFiles[$fileIndex] = $zoneData
        }
    }

    if (($groundEdited + $hiddenEdited) -gt 0) {
        Write-Gfpak -Pack $pack -Path $path
    }

    $result.GroundEdited = $groundEdited
    $result.HiddenEdited = $hiddenEdited
    $result.Changes = [object[]]$changes.ToArray()
    return $result
}

# ---------------------------------------------------------------------------
# REGLAGES SUR LA TABLE POKEMON â€” bin\pml\personal\personal_total.bin
#
# Enregistrements de 0xB0 octets. Decalages **verifies empiriquement** contre
# des valeurs connues du jeu, pas repris d'une documentation :
#
#   0x08  u8         taux de capture
#                    verifie : Mewtwo 3, Leveinard 30, Chenipan 255,
#                    Bulbizarre 45, Pikachu 190, Metamorph 35
#   0x0C  u16        objet tenu 1
#   0x0E  u16        objet tenu 2   verifie : Pikachu tient 236 (Balle Lumiere)
#   0x10  u16        objet tenu 3
#   0x15  u8         courbe d'experience
#                    verifie : Bulbizarre 3 (lente), Pikachu 0 (moyenne),
#                    Mewtwo 5 (tres lente)
#   0x28  100 bits   compatibilite CT   (12,5 octets)
#   0x3C  100 bits   compatibilite DT   (12,5 octets)
#                    verifie : Mew a exactement 100 bits dans chaque zone,
#                    Metamorph zero, Dracaufeu 37 CT et 22 DT
#   0xA8   18 bits   compatibilite maitres de capacites (2,25 octets)
#                    Les 18 maitres de l'Ile solitaire de l'Armure.
#                    Localise par mesure, avec quatre temoins concordants :
#                    aucun des 1192 enregistrements du fichier n'utilise un
#                    bit au-dela du 18e ; le maximum observe est exactement
#                    18 ; Mew les a tous, Metamorph et Evoli aucun ; les
#                    comptes de Dracaufeu (3) et Ectoplasma (3) correspondent
#                    a leurs tuteurs connus. Les 6 bits hauts de 0xAA et tout
#                    ce qui suit restent intacts.
#
# On ne touche qu'aux especes reellement presentes dans le jeu (somme des
# statistiques non nulle) : les enregistrements de remplissage restent intacts.
# ---------------------------------------------------------------------------

$PersonalCatchRateOffset = 0x08
$PersonalHeldItemOffsets = @(0x0C, 0x0E, 0x10)
$PersonalExpCurveOffset = 0x15
$PersonalTmFlagsOffset = 0x28
$PersonalTrFlagsOffset = 0x3C
$PersonalMachineCount = 100
$PersonalTutorFlagsOffset = 0xA8
$PersonalTutorCount = 18

function Get-ExpCurveValue {
    param([string]$Mode)

    switch (Normalize-Mode $Mode) {
        "mediumfast" { return 0 }
        "erratic" { return 1 }
        "fluctuating" { return 2 }
        "mediumslow" { return 3 }
        "fast" { return 4 }
        "slow" { return 5 }
        default { return -1 }
    }
}

function Get-MoveTypeTable {
    <#
        Le type de chaque attaque, lu dans bin/pml/waza.

        Les enregistrements d'attaque sont des tables FlatBuffers : le champ 3
        porte le type. Ce n'est pas une supposition - le generateur ecrit deja
        dans ce champ pour l'option « randomiser les types d'attaques ». Je l'ai
        reconfirme independamment en croisant les 808 attaques connues avec un
        catalogue externe : concordance 808/808.

        Un champ absent vaut sa valeur par defaut, soit 0 (Normal) : c'est la
        convention FlatBuffers, et c'est pour ca que Danse Lames - de type
        Normal - n'a pas d'entree pour ce champ.
    #>
    param([string]$RomfsRoot)

    if ($null -ne $script:MoveTypeTable) {
        return $script:MoveTypeTable
    }
    $table = @{}
    $moveDir = Get-MoveDir -RomfsRoot $RomfsRoot
    if (Test-Path -LiteralPath $moveDir) {
        foreach ($f in (Get-ChildItem -LiteralPath $moveDir -Filter "*.wazabin" -File)) {
            if ($f.BaseName -notmatch '(\d+)\s*$') { continue }
            $id = [int]$Matches[1]
            if ($id -le 0) { continue }
            if ($f.Length -le $MoveStubRecordMaxSize) { continue }
            $bytes = [IO.File]::ReadAllBytes($f.FullName)
            $tablePos = [int](Read-U32 -Data $bytes -Offset 0)
            $addr = Get-FlatBufferFieldAddress -Data $bytes -TablePos $tablePos -FieldIndex 3
            $table[$id] = if ($addr -ge 0) { [int]$bytes[$addr] } else { 0 }
        }
    }
    $script:MoveTypeTable = $table
    return $table
}

function Get-MachineMoveTable {
    <#
        Quelle attaque enseigne chaque machine, dans l'ordre de la table CT/DT.
        Meme lecture que Invoke-MachineMoveRandomization : pointeur u16 en
        item.dat+0x02, table a 0x44 + pointeur*2, 200 entrees de 4 octets.
    #>
    param([string]$RomfsRoot)

    if ($null -ne $script:MachineMoveTable) {
        return $script:MachineMoveTable
    }
    $table = @()
    $chemin = Join-Path $RomfsRoot "bin\pml\item\item.dat"
    if (Test-Path -LiteralPath $chemin) {
        $d = [IO.File]::ReadAllBytes($chemin)
        $debut = 0x44 + ([int](Read-U16 -Data $d -Offset 0x02) * 2)
        if (($debut + 800) -le $d.Length) {
            $table = @(0..199 | ForEach-Object { [int](Read-U16 -Data $d -Offset ($debut + ($_ * 4) + 2)) })
        }
    }
    $script:MachineMoveTable = $table
    return $table
}

function Set-PersonalMachineFlags {
    param(
        [byte[]]$Data,
        [int]$RecordOffset,
        [int]$FlagsOffset,
        [int]$Count,
        [string]$Mode,
        [System.Random]$Rng,
        [object]$MachineMoves = $null,
        [hashtable]$MoveTypes = $null,
        [int]$SpeciesType1 = -1,
        [int]$SpeciesType2 = -1
    )

    $changed = 0
    for ($index = 0; $index -lt $Count; $index++) {
        $byteOffset = $RecordOffset + $FlagsOffset + [int][Math]::Floor($index / 8)
        $bit = 1 -shl ($index % 8)
        $current = ([int]$Data[$byteOffset] -band $bit) -ne 0
        $wanted = switch ($Mode) {
            "full" { $true; break }
            "sametype" {
                # « Preferer le meme type » : une machine dont l'attaque partage
                # un type avec l'espece passe presque toujours, les autres
                # presque jamais. Sans table des types (item.dat ou bin/pml/waza
                # absents), on retombe sur le tirage a pile ou face plutot que
                # de rendre l'option inerte.
                if ($null -eq $MachineMoves -or $MachineMoves.Count -le $index -or $null -eq $MoveTypes) {
                    $Rng.Next(0, 2) -eq 0
                } else {
                    $moveId = [int]$MachineMoves[$index]
                    $moveType = if ($MoveTypes.ContainsKey($moveId)) { [int]$MoveTypes[$moveId] } else { -1 }
                    $partage = ($moveType -ge 0) -and (($moveType -eq $SpeciesType1) -or ($moveType -eq $SpeciesType2))
                    if ($partage) { $Rng.Next(0, 10) -lt 9 } else { $Rng.Next(0, 10) -lt 1 }
                }
                break
            }
            default { $Rng.Next(0, 2) -eq 0 }
        }
        if ($wanted -eq $current) {
            continue
        }
        if ($wanted) {
            $Data[$byteOffset] = [byte](([int]$Data[$byteOffset]) -bor $bit)
        } else {
            $Data[$byteOffset] = [byte](([int]$Data[$byteOffset]) -band (-bnot $bit) -band 0xFF)
        }
        $changed++
    }
    return $changed
}

# ---------------------------------------------------------------------------
# SUIVRE LES EVOLUTIONS
#
# Une evolution reprend les types et/ou les talents tires pour sa forme de
# base, pour qu'une famille reste coherente : si Bulbizarre devient Feu, ses
# evolutions le deviennent aussi.
#
# Le graphe est lu dans le ROMFS **SOURCE**, pas dans la sortie : si les cibles
# d'evolution ont ete randomisees, on veut quand meme propager le long des
# familles d'origine, sinon la notion de famille disparait.
#
# Fichiers `evo_NNN.bin` : NNN = espece source, 9 enregistrements de 8 octets,
# methode en +0 et cible en +4.
# ---------------------------------------------------------------------------
function Get-SourceEvolutionGraph {
    param([string]$SourceRomfsRoot)

    $graph = @{}
    $isTarget = @{}
    $dir = Get-EvolutionDir -RomfsRoot $SourceRomfsRoot
    if (-not (Test-Path -LiteralPath $dir)) {
        return @{ Edges = $graph; IsTarget = $isTarget }
    }

    foreach ($file in Get-ChildItem -LiteralPath $dir -Filter "*.bin" -File) {
        if ($file.BaseName -notmatch '(\d+)\s*$') {
            continue
        }
        $source = [int]$Matches[1]
        if ($source -lt 1 -or $source -gt $BaseSpeciesMax) {
            continue
        }
        $bytes = [IO.File]::ReadAllBytes($file.FullName)
        for ($slot = 0; $slot -lt $EvolutionRecordsPerSpecies; $slot++) {
            $slotOffset = $slot * $EvolutionRecordSize
            if (($slotOffset + 6) -gt $bytes.Length) {
                break
            }
            $method = [int](Read-U16 -Data $bytes -Offset $slotOffset)
            $target = [int](Read-U16 -Data $bytes -Offset ($slotOffset + 4))
            if ($method -eq 0 -or $target -lt 1 -or $target -gt $BaseSpeciesMax -or $target -eq $source) {
                continue
            }
            if (-not $graph.ContainsKey($source)) {
                $graph[$source] = New-Object System.Collections.Generic.List[int]
            }
            if (-not $graph[$source].Contains($target)) {
                $graph[$source].Add($target)
            }
            $isTarget[$target] = $true
        }
    }

    return @{ Edges = $graph; IsTarget = $isTarget }
}

# ---------------------------------------------------------------------------
# LIMITER LES CHAINES D'EVOLUTION
#
# Une fois les cibles randomisees, plus rien n'empeche une chaine de dix
# maillons, voire une boucle. Cette passe calcule le stade de chaque espece par
# parcours en largeur depuis les formes de base, puis **efface** les
# enregistrements d'evolution qui depasseraient le nombre de stades autorise.
#
# Effacer = mettre la methode a 0 dans l'enregistrement, ce que le jeu
# interprete comme "pas d'evolution ici". La taille des fichiers ne bouge pas.
#
# Le graphe est lu dans la SORTIE : c'est bien la chaine finale qu'on veut
# borner, pas celle du jeu de base.
# ---------------------------------------------------------------------------
function Invoke-EvolutionChainLimit {
    param(
        [string]$RomfsRoot,
        [int]$MaxStages
    )

    $result = [pscustomobject]@{ Removed = 0; Skipped = "" }
    if ($MaxStages -lt 1) {
        return $result
    }

    $dir = Get-EvolutionDir -RomfsRoot $RomfsRoot
    if (-not (Test-Path -LiteralPath $dir)) {
        $result.Skipped = "dossier d'evolutions absent"
        return $result
    }

    # 1. Lecture du graphe et des octets, en une seule passe.
    $files = @{}
    $edges = @{}
    $isTarget = @{}
    foreach ($file in Get-ChildItem -LiteralPath $dir -Filter "*.bin" -File) {
        if ($file.BaseName -notmatch '(\d+)\s*$') {
            continue
        }
        $source = [int]$Matches[1]
        if ($source -lt 1 -or $source -gt $BaseSpeciesMax) {
            continue
        }
        $bytes = [IO.File]::ReadAllBytes($file.FullName)
        $files[$source] = @{ Path = $file.FullName; Bytes = $bytes }
        for ($slot = 0; $slot -lt $EvolutionRecordsPerSpecies; $slot++) {
            $slotOffset = $slot * $EvolutionRecordSize
            if (($slotOffset + 6) -gt $bytes.Length) {
                break
            }
            $method = [int](Read-U16 -Data $bytes -Offset $slotOffset)
            $target = [int](Read-U16 -Data $bytes -Offset ($slotOffset + 4))
            if ($method -eq 0 -or $target -lt 1 -or $target -gt $BaseSpeciesMax -or $target -eq $source) {
                continue
            }
            if (-not $edges.ContainsKey($source)) {
                $edges[$source] = New-Object System.Collections.Generic.List[int]
            }
            $edges[$source].Add($target)
            $isTarget[$target] = $true
        }
    }
    if ($edges.Count -lt 1) {
        $result.Skipped = "aucune évolution lue"
        return $result
    }

    # 2. Stade de chaque espece, au plus court depuis une forme de base.
    $stage = @{}
    $queue = New-Object System.Collections.Generic.Queue[int]
    foreach ($source in $edges.Keys) {
        if (-not $isTarget.ContainsKey([int]$source)) {
            $stage[[int]$source] = 1
            $queue.Enqueue([int]$source)
        }
    }
    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        if (-not $edges.ContainsKey($current)) {
            continue
        }
        foreach ($target in $edges[$current]) {
            if ($stage.ContainsKey([int]$target)) {
                continue
            }
            $stage[[int]$target] = $stage[$current] + 1
            $queue.Enqueue([int]$target)
        }
    }

    # 3. Effacement des enregistrements qui feraient depasser la limite.
    $removed = 0
    foreach ($source in $files.Keys) {
        $entry = $files[$source]
        $bytes = $entry.Bytes
        $changed = $false
        # Une espece jamais atteinte depuis une forme de base est dans une
        # boucle fermee : on la traite comme un premier stade.
        $sourceStage = if ($stage.ContainsKey([int]$source)) { $stage[[int]$source] } else { 1 }
        if ($sourceStage -lt $MaxStages) {
            continue
        }
        for ($slot = 0; $slot -lt $EvolutionRecordsPerSpecies; $slot++) {
            $slotOffset = $slot * $EvolutionRecordSize
            if (($slotOffset + 6) -gt $bytes.Length) {
                break
            }
            $method = [int](Read-U16 -Data $bytes -Offset $slotOffset)
            $target = [int](Read-U16 -Data $bytes -Offset ($slotOffset + 4))
            if ($method -eq 0 -or $target -lt 1 -or $target -gt $BaseSpeciesMax) {
                continue
            }
            Write-U16 -Data $bytes -Offset $slotOffset -Value 0
            Write-U16 -Data $bytes -Offset ($slotOffset + 2) -Value 0
            Write-U16 -Data $bytes -Offset ($slotOffset + 4) -Value 0
            Write-U16 -Data $bytes -Offset ($slotOffset + 6) -Value 0
            $changed = $true
            $removed++
        }
        if ($changed) {
            [IO.File]::WriteAllBytes($entry.Path, $bytes)
        }
    }

    $result.Removed = $removed
    return $result
}

function Invoke-PersonalFollowEvolutions {
    param(
        [string]$RomfsRoot,
        [string]$SourceRomfsRoot,
        [bool]$DoTypes,
        [bool]$DoAbilities
    )

    $result = [pscustomobject]@{ Propagated = 0; Skipped = "" }
    if (-not $DoTypes -and -not $DoAbilities) {
        return $result
    }

    $path = Get-PersonalPath -RomfsRoot $RomfsRoot
    if (-not (Test-Path -LiteralPath $path)) {
        $result.Skipped = "personal_total.bin absent"
        return $result
    }

    $graphInfo = Get-SourceEvolutionGraph -SourceRomfsRoot $SourceRomfsRoot
    $edges = $graphInfo.Edges
    if ($edges.Count -lt 1) {
        $result.Skipped = "aucune évolution lue"
        return $result
    }

    $data = [IO.File]::ReadAllBytes($path)
    $count = [int][Math]::Floor($data.Length / $PersonalRecordSize)
    $propagated = 0

    # Formes de base : especes qui evoluent sans etre elles-memes une cible.
    $baseForms = New-Object System.Collections.Generic.List[int]
    foreach ($source in $edges.Keys) {
        if (-not $graphInfo.IsTarget.ContainsKey($source)) {
            $baseForms.Add([int]$source)
        }
    }

    foreach ($baseForm in $baseForms) {
        if ($baseForm -ge $count) {
            continue
        }
        $baseOffset = $baseForm * $PersonalRecordSize

        # Parcours en largeur. Le jeu de visites protege des cycles, qui
        # deviennent possibles des que les cibles d'evolution sont randomisees.
        $visited = [System.Collections.Generic.HashSet[int]]::new()
        $null = $visited.Add($baseForm)
        $queue = New-Object System.Collections.Generic.Queue[int]
        $queue.Enqueue($baseForm)

        while ($queue.Count -gt 0) {
            $current = $queue.Dequeue()
            if (-not $edges.ContainsKey($current)) {
                continue
            }
            foreach ($target in $edges[$current]) {
                if (-not $visited.Add([int]$target)) {
                    continue
                }
                $queue.Enqueue([int]$target)
                if ($target -ge $count) {
                    continue
                }
                $targetOffset = $target * $PersonalRecordSize

                if ($DoTypes) {
                    $data[$targetOffset + 6] = $data[$baseOffset + 6]
                    $data[$targetOffset + 7] = $data[$baseOffset + 7]
                }
                if ($DoAbilities) {
                    foreach ($abilityOffset in @(0x18, 0x1A, 0x1C)) {
                        Write-U16 -Data $data -Offset ($targetOffset + $abilityOffset) -Value ([uint16](Read-U16 -Data $data -Offset ($baseOffset + $abilityOffset)))
                    }
                }
                $propagated++
            }
        }
    }

    if ($propagated -gt 0) {
        [IO.File]::WriteAllBytes($path, $data)
    }
    $result.Propagated = $propagated
    return $result
}

# ---------------------------------------------------------------------------
# CADEAUX D'OBJETS DES PNJ - bin/script/amx/*.amx
#
# Les scripts du jeu sont des modules Pawn 64 bits en encodage COMPACT. Le
# format a ete etabli par mesure (voir docs/offsets/swsh-1.3.2-epee.md) :
#
#   en-tete : u32 size (+0x00), u16 flags (+0x0A), u32 cod (+0x0C),
#             u32 dat (+0x10), u32 hea (+0x14)
#   zone compacte : de `cod` a `size`
#   cellules de 8 OCTETS - (hea - cod) / 8 donne exactement le nombre de
#   cellules decodees ; /4 en donnait le double
#   une cellule d'instruction vaut (operande << 32) | opcode
#   les cadeaux utilisent l'opcode 0xBC (push.c)
#
# On ne reecrit PAS tout le module : on remplace les octets de la SEULE cellule
# visee et on corrige `size`. Les autres octets restent identiques au bit pres,
# et l'image memoire etendue garde exactement le meme nombre de cellules, donc
# aucune cible de saut ne bouge.
# ---------------------------------------------------------------------------
$AmxOpcodePushConstant = 0xBC
$AmxHeaderSizeOffset = 0x00
$AmxHeaderCodeOffset = 0x0C

function ConvertTo-AmxCompactCell {
    <#
        Encode une valeur de cellule 64 bits en octets compacts.

        Groupes de 7 bits, du plus significatif au moins ; tous les octets sauf
        le dernier portent 0x80. Le decodeur etend le signe quand le PREMIER
        octet porte 0x40 : on prefixe donc un groupe nul dans ce cas, pour que
        la valeur relue soit exactement celle demandee.
    #>
    param([UInt64]$Value)

    $groupes = New-Object System.Collections.Generic.List[int]
    $reste = $Value
    do {
        $groupes.Add([int]($reste -band 0x7F))
        $reste = $reste -shr 7
    } while ($reste -ne 0)
    $groupes.Reverse()
    if (($groupes[0] -band 0x40) -ne 0) {
        $groupes.Insert(0, 0)
    }

    $octets = New-Object System.Collections.Generic.List[byte]
    for ($i = 0; $i -lt $groupes.Count; $i++) {
        $b = [int]$groupes[$i]
        if ($i -lt ($groupes.Count - 1)) { $b = $b -bor 0x80 }
        $octets.Add([byte]$b)
    }
    return $octets.ToArray()
}

function Get-NpcGiftCatalog {
    <#
        Le catalogue est produit par tools/build-npc-gifts.py, qui verifie
        CHAQUE entree contre le dump avant de l'ecrire : fichier present,
        cellule dans le module, opcode 0xBC, et objet lu egal a l'objet attendu.
        Les 120 entrees concordaient au moment de sa creation.
    #>
    if ($null -ne $script:NpcGiftCatalog) {
        return $script:NpcGiftCatalog
    }
    $rows = @()
    $path = Find-DataFile -RelativePath "npc-gifts.csv"
    if ($path) {
        foreach ($r in (Import-Csv -LiteralPath $path -Encoding UTF8)) {
            $rows += [pscustomobject]@{
                Amx = [string]$r.amx
                Cellule = [int]$r.cellule
                ItemId = [int]$r.item_id
                Debut = [int]$r.octet_debut
                Fin = [int]$r.octet_fin
                Nom = [string]$r.nom
            }
        }
    }
    $script:NpcGiftCatalog = $rows
    return $rows
}

function Invoke-NpcGiftItemRandomization {
    param(
        [string]$RomfsRoot,
        [System.Random]$Rng,
        [string]$Mode
    )

    $resultat = [pscustomobject]@{ Modifies = 0; Proteges = 0; Fichiers = 0; Ignore = "" }
    $normalise = Normalize-Mode $Mode
    if ($normalise -eq "unchanged" -or $normalise -eq "") {
        return $resultat
    }

    $catalogue = @(Get-NpcGiftCatalog)
    if ($catalogue.Count -eq 0) {
        $resultat.Ignore = "npc-gifts.csv absent"
        return $resultat
    }

    # Les objets CLES ne sont JAMAIS touches. Mesure : 38 des 120 cadeaux en
    # sont - Recommandation, Bracelet Dynamax, Velo Rotom, Lien Boite Pokemon,
    # Materiel de camping. En remplacer un rend la partie infinissable.
    $poches = @{}
    foreach ($entry in @((Get-ItemData).Rows)) {
        if ($null -ne $entry) { $poches[[int]$entry.id] = [int]$entry.categoryId }
    }
    if ($poches.Count -eq 0) {
        $resultat.Ignore = "items.csv absent : impossible de distinguer les objets clés"
        return $resultat
    }

    $modifiables = @($catalogue | Where-Object {
        $poches.ContainsKey([int]$_.ItemId) -and $poches[[int]$_.ItemId] -ne $ItemPocketKeyItems
    })
    $resultat.Proteges = $catalogue.Count - $modifiables.Count
    if ($modifiables.Count -eq 0) {
        $resultat.Ignore = "aucun cadeau modifiable"
        return $resultat
    }

    # Les nouvelles valeurs, tirees AVANT toute ecriture.
    $nouvelles = New-Object System.Collections.Generic.List[int]
    if ($normalise -eq "shuffle" -or $normalise -eq "melange") {
        $melange = [int[]]@($modifiables | ForEach-Object { [int]$_.ItemId })
        for ($i = $melange.Length - 1; $i -gt 0; $i--) {
            $j = $Rng.Next(0, $i + 1)
            $tmp = $melange[$i]; $melange[$i] = $melange[$j]; $melange[$j] = $tmp
        }
        $nouvelles.AddRange($melange)
    } else {
        $pool = [int[]](Get-GeneralRandomItemPool)
        if ($pool.Count -lt 2) {
            $resultat.Ignore = "pool d'objets trop petit"
            return $resultat
        }
        for ($i = 0; $i -lt $modifiables.Count; $i++) {
            $nouvelles.Add([int]$pool[$Rng.Next(0, $pool.Count)])
        }
    }

    # Regroupe par fichier, puis applique du dernier octet vers le premier :
    # une cellule reencodee peut changer de longueur, ce qui decalerait les
    # bornes des cellules suivantes si on ecrivait dans l'autre sens.
    $parFichier = @{}
    for ($i = 0; $i -lt $modifiables.Count; $i++) {
        $e = $modifiables[$i]
        if (-not $parFichier.ContainsKey($e.Amx)) {
            $parFichier[$e.Amx] = New-Object System.Collections.Generic.List[object]
        }
        $parFichier[$e.Amx].Add([pscustomobject]@{ Entree = $e; Nouveau = [int]$nouvelles[$i] })
    }

    foreach ($nomFichier in @($parFichier.Keys)) {
        $chemin = Join-Path $RomfsRoot (Join-Path "bin\script\amx" $nomFichier)
        if (-not (Test-Path -LiteralPath $chemin)) { continue }
        $data = [IO.File]::ReadAllBytes($chemin)
        $tailleAnnoncee = [int](Read-U32 -Data $data -Offset $AmxHeaderSizeOffset)
        if ($tailleAnnoncee -ne $data.Length) {
            # Un module dont l'en-tete ne decrit pas sa propre taille n'est pas
            # celui qu'on croit : on le laisse intact.
            continue
        }
        $cod = [int](Read-U32 -Data $data -Offset $AmxHeaderCodeOffset)

        $aFaire = @($parFichier[$nomFichier] | Sort-Object { $_.Entree.Debut } -Descending)
        $touche = $false
        foreach ($t in $aFaire) {
            if ([int]$t.Nouveau -eq [int]$t.Entree.ItemId) { continue }
            $valeur = ([UInt64][UInt32]$t.Nouveau -shl 32) -bor [UInt64]$AmxOpcodePushConstant
            $octets = ConvertTo-AmxCompactCell -Value $valeur
            $debut = $cod + [int]$t.Entree.Debut
            $fin = $cod + [int]$t.Entree.Fin
            if ($debut -lt 0 -or $fin -gt $data.Length -or $fin -le $debut) { continue }

            $nouveau = New-Object 'System.Collections.Generic.List[byte]'
            if ($debut -gt 0) { $nouveau.AddRange([byte[]]$data[0..($debut - 1)]) }
            $nouveau.AddRange([byte[]]$octets)
            if ($fin -lt $data.Length) { $nouveau.AddRange([byte[]]$data[$fin..($data.Length - 1)]) }
            $data = $nouveau.ToArray()
            $resultat.Modifies++
            $touche = $true
        }

        if ($touche) {
            # `size` decrit la fin de la zone compacte : il doit suivre.
            Write-U32 -Data $data -Offset $AmxHeaderSizeOffset -Value ([uint32]$data.Length)
            [IO.File]::WriteAllBytes($chemin, $data)
            $resultat.Fichiers++
        }
    }

    return $resultat
}

function Invoke-LearnsetRandomization {
    <#
        Randomise les attaques apprises en montant de niveau.

        Structure deja decodee par le generateur (Get-LearnsetTable) :

            bin/pml/waza_oboe/wazaoboe_total.bin
            enregistrements de 0x104 octets, un par entree de personal
            65 paires de 4 octets : u16 attaque, u16 niveau
            fin d'enregistrement marquee par FFFF FFFF

        Les NIVEAUX ne sont jamais touches : une espece apprend toujours autant
        d'attaques, aux memes paliers. Seule change l'attaque enseignee.

        Le tirage se fait dans les attaques deja presentes dans la table. Comme
        pour les CT/DT, ca garantit que toute attaque obtenue est une vraie
        attaque apprenable, sans avoir besoin d'une liste externe - et le projet
        n'en a pas : move_names.csv est absent (voir PROJECT_STATUS §4.1).
    #>
    param(
        [string]$RomfsRoot,
        [System.Random]$Rng,
        [string]$Mode,
        [string]$SourceRomfsRootValue = ""
    )

    $resultat = [pscustomobject]@{ Attaques = 0; Especes = 0; Ignore = "" }
    $normalise = Normalize-Mode $Mode
    if ($normalise -eq "unchanged" -or $normalise -eq "") {
        return $resultat
    }

    $chemin = Get-LearnsetPath -RomfsRoot $RomfsRoot
    if (-not (Test-Path -LiteralPath $chemin)) {
        $resultat.Ignore = "wazaoboe_total.bin absent"
        return $resultat
    }

    $donnees = [IO.File]::ReadAllBytes($chemin)
    if ($donnees.Length -lt $LearnsetRecordSize -or ($donnees.Length % $LearnsetRecordSize) -ne 0) {
        $resultat.Ignore = ("taille inattendue : {0} octets, pas un multiple de {1}" -f $donnees.Length, $LearnsetRecordSize)
        return $resultat
    }

    # Premier passage : relever toutes les attaques reellement presentes.
    $positions = New-Object System.Collections.Generic.List[int]
    $valeurs = New-Object System.Collections.Generic.List[int]
    $nombreEnregistrements = [int]($donnees.Length / $LearnsetRecordSize)
    for ($i = 0; $i -lt $nombreEnregistrements; $i++) {
        $base = $i * $LearnsetRecordSize
        $vue = $false
        for ($c = 0; $c -lt $LearnsetRecordSize; $c += 4) {
            $attaque = [BitConverter]::ToUInt16($donnees, $base + $c)
            $niveau = [BitConverter]::ToUInt16($donnees, $base + $c + 2)
            if ($attaque -eq 0xFFFF -and $niveau -eq 0xFFFF) { break }
            if ($attaque -eq 0) { continue }
            $positions.Add($base + $c)
            $valeurs.Add([int]$attaque)
            $vue = $true
        }
        if ($vue) { $resultat.Especes++ }
    }

    if ($positions.Count -eq 0) {
        $resultat.Ignore = "aucune attaque trouvee dans la table"
        return $resultat
    }

    $distinctes = @($valeurs | Sort-Object -Unique)
    if ($distinctes.Count -lt 2) {
        $resultat.Ignore = "moins de deux attaques distinctes"
        return $resultat
    }

    # « Tirage integral » : on pioche dans TOUTES les attaques du jeu, pas
    # seulement dans celles qui figurent deja dans la table des montees de
    # niveau. Mesure sur le dump : 610 attaques y figurent, alors que le jeu en
    # compte 787 hors croupions. 177 attaques - Poing Karate, Coupe-Vent,
    # Sonic Boom, Draco-Rage, Mimique... - ne pouvaient donc JAMAIS sortir du
    # mode « Tirage aleatoire ».
    #
    # Le pool se lit dans le ROMFS SOURCE, pas la sortie : bin/pml/waza n'y est
    # copie que si une option de donnees d'attaques le touche. Lire la sortie
    # rendrait ce mode silencieusement identique au precedent - c'est
    # exactement le piege dans lequel « preferer le meme type » est tombe.
    $poolIntegral = $null
    if ($normalise -eq "fullrandom") {
        $racinePool = if ($SourceRomfsRootValue) { $SourceRomfsRootValue } else { $RomfsRoot }
        $poolIntegral = [int[]]@(Get-MovePool -RomfsRoot $racinePool)
        if ($poolIntegral.Count -lt 2) {
            $resultat.Ignore = "table des attaques introuvable : le tirage intégral est impossible"
            return $resultat
        }
    }

    $nouvelles = New-Object System.Collections.Generic.List[int]
    if ($normalise -eq "fullrandom") {
        for ($i = 0; $i -lt $positions.Count; $i++) {
            $nouvelles.Add([int]$poolIntegral[$Rng.Next(0, $poolIntegral.Count)])
        }
    } elseif ($normalise -eq "shuffle" -or $normalise -eq "melange") {
        # Permutation globale : le jeu conserve exactement le meme multi-ensemble
        # d'attaques, redistribue entre les especes et les paliers.
        $melange = [int[]]$valeurs.ToArray()
        for ($i = $melange.Length - 1; $i -gt 0; $i--) {
            $j = $Rng.Next(0, $i + 1)
            $tmp = $melange[$i]; $melange[$i] = $melange[$j]; $melange[$j] = $tmp
        }
        $nouvelles.AddRange($melange)
    } else {
        for ($i = 0; $i -lt $positions.Count; $i++) {
            $nouvelles.Add([int]$distinctes[$Rng.Next(0, $distinctes.Count)])
        }
    }

    for ($i = 0; $i -lt $positions.Count; $i++) {
        if ($nouvelles[$i] -eq $valeurs[$i]) { continue }
        $octets = [BitConverter]::GetBytes([UInt16]$nouvelles[$i])
        $donnees[$positions[$i]] = $octets[0]
        $donnees[$positions[$i] + 1] = $octets[1]
        $resultat.Attaques++
    }

    if ($resultat.Attaques -gt 0) {
        [IO.File]::WriteAllBytes($chemin, $donnees)
    }
    return $resultat
}

function Invoke-MachineMoveRandomization {
    <#
        Randomise l'attaque enseignee par chaque CT et DT.

        Structure verifiee le 2026-09-04 sur le dump Epee, avec temoin
        concordant (voir docs/offsets/swsh-1.3.2-epee.md) :

            bin/pml/item/item.dat
            pointeur u16 a +0x02        (valeur 1608 sur Epee 1.3.2)
            table   a 0x44 + pointeur*2 (= 0xCD4)
            200 entrees de 4 octets : u16 identifiant d'objet, u16 attaque

        Les entrees 100 a 199 portent les objets 1130 a 1229, exactement
        contigus, ce qui correspond a DT00 -> DT99.

        Le tirage se fait UNIQUEMENT dans les attaques deja presentes dans la
        table. Deux raisons : toute attaque ainsi tiree est forcement
        enseignable par une machine, et ecrire hors de cette plage corromprait
        la table d'objets - prix compris.
    #>
    param(
        [string]$RomfsRoot,
        [System.Random]$Rng,
        [string]$Mode
    )

    $resultat = [pscustomobject]@{ Modifiees = 0; Total = 0; Ignore = "" }
    $normalise = Normalize-Mode $Mode
    if ($normalise -eq "unchanged" -or $normalise -eq "") {
        return $resultat
    }

    $chemin = Join-Path $RomfsRoot "bin\pml\item\item.dat"
    if (-not (Test-Path -LiteralPath $chemin)) {
        $resultat.Ignore = "bin\pml\item\item.dat absent"
        return $resultat
    }

    $donnees = [IO.File]::ReadAllBytes($chemin)
    $pointeur = [BitConverter]::ToUInt16($donnees, 0x02)
    $debut = 0x44 + ($pointeur * 2)
    $nombre = 200
    $taille = 4
    if (($debut + ($nombre * $taille)) -gt $donnees.Length) {
        # Garde-fou : sur un fichier inattendu, ne rien ecrire plutot que
        # d'ecraser des octets au hasard.
        $resultat.Ignore = ("table CT/DT hors limites (debut 0x{0:X}, fichier {1} octets)" -f $debut, $donnees.Length)
        return $resultat
    }

    $attaques = New-Object System.Collections.Generic.List[int]
    for ($i = 0; $i -lt $nombre; $i++) {
        $attaques.Add([int][BitConverter]::ToUInt16($donnees, $debut + ($i * $taille) + 2))
    }
    $resultat.Total = $nombre

    $distinctes = @($attaques | Where-Object { $_ -gt 0 } | Sort-Object -Unique)
    if ($distinctes.Count -lt 2) {
        $resultat.Ignore = "moins de deux attaques distinctes dans la table"
        return $resultat
    }

    $nouvelles = New-Object System.Collections.Generic.List[int]
    if ($normalise -eq "shuffle" -or $normalise -eq "melange") {
        # Permutation de Fisher-Yates sur les valeurs existantes : chaque
        # attaque reste presente exactement autant de fois qu'avant.
        $melange = [int[]]$attaques.ToArray()
        for ($i = $melange.Length - 1; $i -gt 0; $i--) {
            $j = $Rng.Next(0, $i + 1)
            $tmp = $melange[$i]; $melange[$i] = $melange[$j]; $melange[$j] = $tmp
        }
        $nouvelles.AddRange($melange)
    } else {
        for ($i = 0; $i -lt $nombre; $i++) {
            $nouvelles.Add([int]$distinctes[$Rng.Next(0, $distinctes.Count)])
        }
    }

    for ($i = 0; $i -lt $nombre; $i++) {
        if ($attaques[$i] -eq 0) {
            # Entree vide : on la laisse vide.
            continue
        }
        if ($nouvelles[$i] -eq $attaques[$i]) { continue }
        $octets = [BitConverter]::GetBytes([UInt16]$nouvelles[$i])
        $donnees[$debut + ($i * $taille) + 2] = $octets[0]
        $donnees[$debut + ($i * $taille) + 3] = $octets[1]
        $resultat.Modifiees++
    }

    if ($resultat.Modifiees -gt 0) {
        [IO.File]::WriteAllBytes($chemin, $donnees)
    }
    return $resultat
}

function Invoke-PersonalExtraTweaks {
    param(
        [string]$RomfsRoot,
        [System.Random]$Rng,
        [int]$MinimumCatchRateValue,
        [bool]$DoRandomizeHeldItems,
        [string]$ExpCurveModeValue,
        [string]$TmCompatibilityModeValue,
        [string]$TutorCompatibilityModeValue,
        [string]$SourceRomfsRootValue = ""
    )

    $result = [pscustomobject]@{ CatchRates = 0; HeldItems = 0; ExpCurves = 0; MachineFlags = 0; TutorFlags = 0; Skipped = "" }

    $minCatchRate = [Math]::Max(0, [Math]::Min(255, [int]$MinimumCatchRateValue))
    $expCurve = Get-ExpCurveValue -Mode $ExpCurveModeValue
    $machineMode = Normalize-Mode $TmCompatibilityModeValue
    if ($machineMode -notin @("random", "full", "sametype")) {
        $machineMode = "unchanged"
    }
    $tutorMode = Normalize-Mode $TutorCompatibilityModeValue
    # Pas de « meme type » pour les maitres : les attaques qu'ils enseignent
    # vivent dans l'executable, donc leur type est hors de portee. Le proposer
    # serait mentir - on retombe sur le tirage a pile ou face.
    if ($tutorMode -eq "sametype") { $tutorMode = "random" }
    if ($tutorMode -notin @("random", "full")) {
        $tutorMode = "unchanged"
    }
    $machineMoves = $null
    $moveTypes = $null
    if ($machineMode -eq "sametype") {
        # Lecture dans le ROMFS SOURCE, pas la sortie : item.dat et bin/pml/waza
        # n'y sont copies que si d'autres options les touchent. En lisant la
        # sortie, la table revenait vide et le mode retombait EN SILENCE sur le
        # tirage a pile ou face - mesure : 50 % des machines autorisees des deux
        # cotes, soit exactement le comportement de « Une chance sur deux ».
        $racineTables = if ($SourceRomfsRootValue) { $SourceRomfsRootValue } else { $RomfsRoot }
        $machineMoves = @(Get-MachineMoveTable -RomfsRoot $racineTables)
        $moveTypes = Get-MoveTypeTable -RomfsRoot $racineTables
        if ($machineMoves.Count -lt 1 -or $moveTypes.Count -lt 1) {
            # On le DIT au lieu de degrader sans bruit.
            $result.Skipped = "types d'attaques indisponibles : « préférer le même type » retombe sur une chance sur deux"
        }
    }

    if ($minCatchRate -le 0 -and -not $DoRandomizeHeldItems -and $expCurve -lt 0 -and $machineMode -eq "unchanged" -and $tutorMode -eq "unchanged") {
        return $result
    }

    $path = Get-PersonalPath -RomfsRoot $RomfsRoot
    if (-not (Test-Path -LiteralPath $path)) {
        $result.Skipped = "personal_total.bin absent"
        return $result
    }

    $data = [IO.File]::ReadAllBytes($path)
    $count = [int][Math]::Floor($data.Length / $PersonalRecordSize)
    if ($count -lt 2) {
        $result.Skipped = "table Pokemon trop courte"
        return $result
    }

    $itemPool = if ($DoRandomizeHeldItems) { [int[]](Get-GeneralRandomItemPool) } else { [int[]]@() }

    for ($index = 1; $index -lt $count; $index++) {
        $offset = $index * $PersonalRecordSize
        # Somme des six statistiques de base : nulle = enregistrement de
        # remplissage, l'espece n'existe pas dans le jeu.
        $bst = 0
        for ($s = 0; $s -lt 6; $s++) { $bst += [int]$data[$offset + $s] }
        if ($bst -le 0) {
            continue
        }

        if ($minCatchRate -gt 0) {
            $current = [int]$data[$offset + $PersonalCatchRateOffset]
            if ($current -lt $minCatchRate) {
                $data[$offset + $PersonalCatchRateOffset] = [byte]$minCatchRate
                $result.CatchRates++
            }
        }

        if ($expCurve -ge 0) {
            if ([int]$data[$offset + $PersonalExpCurveOffset] -ne $expCurve) {
                $data[$offset + $PersonalExpCurveOffset] = [byte]$expCurve
                $result.ExpCurves++
            }
        }

        if ($DoRandomizeHeldItems -and $itemPool.Count -gt 0) {
            foreach ($itemOffset in $PersonalHeldItemOffsets) {
                $currentItem = [int](Read-U16 -Data $data -Offset ($offset + $itemOffset))
                # On ne remplace que les emplacements deja occupes : donner un
                # objet a tout le monde rendrait chaque capture rentable.
                if ($currentItem -le 0) {
                    continue
                }
                $newItem = [int](Random-FromPool -Rng $Rng -Pool $itemPool)
                if ($newItem -eq $currentItem) {
                    continue
                }
                Write-U16 -Data $data -Offset ($offset + $itemOffset) -Value ([uint16]$newItem)
                $result.HeldItems++
            }
        }

        if ($machineMode -ne "unchanged") {
            $type1 = [int]$data[$offset + 6]
            $type2 = [int]$data[$offset + 7]
            # Les CT occupent les rangs 0-99 de la table machine, les DT 100-199.
            $ctMoves = if ($machineMoves) { @($machineMoves[0..99]) } else { $null }
            $dtMoves = if ($machineMoves) { @($machineMoves[100..199]) } else { $null }
            $result.MachineFlags += Set-PersonalMachineFlags -Data $data -RecordOffset $offset -FlagsOffset $PersonalTmFlagsOffset -Count $PersonalMachineCount -Mode $machineMode -Rng $Rng -MachineMoves $ctMoves -MoveTypes $moveTypes -SpeciesType1 $type1 -SpeciesType2 $type2
            $result.MachineFlags += Set-PersonalMachineFlags -Data $data -RecordOffset $offset -FlagsOffset $PersonalTrFlagsOffset -Count $PersonalMachineCount -Mode $machineMode -Rng $Rng -MachineMoves $dtMoves -MoveTypes $moveTypes -SpeciesType1 $type1 -SpeciesType2 $type2
        }

        if ($tutorMode -ne "unchanged") {
            # Meme routine, autre champ : 18 bits au lieu de 100. Elle n'ecrit
            # que dans les octets qu'elle parcourt, donc les 6 bits hauts de
            # 0xAA - dont on ignore la signification - ne bougent pas.
            $result.TutorFlags += Set-PersonalMachineFlags -Data $data -RecordOffset $offset -FlagsOffset $PersonalTutorFlagsOffset -Count $PersonalTutorCount -Mode $tutorMode -Rng $Rng
        }
    }

    if (($result.CatchRates + $result.HeldItems + $result.ExpCurves + $result.MachineFlags + $result.TutorFlags) -gt 0) {
        [IO.File]::WriteAllBytes($path, $data)
    }
    return $result
}

function Invoke-ItemPriceAdjustment {
    param(
        [string]$RomfsRoot,
        [double]$Multiplier,
        [string]$Mode = "multiplier",
        [int]$MinPrice = 100,
        [int]$MaxPrice = 20000,
        [System.Random]$Rng = $null
    )

    $result = [pscustomobject]@{ Edited = 0; Skipped = "" }

    $modeNormalise = Normalize-Mode $Mode
    if ($modeNormalise -eq "vanilla") {
        $result.Skipped = "prix vanilla"
        return $result
    }
    if ($modeNormalise -eq "random" -and $null -eq $Rng) {
        $result.Skipped = "mode aléatoire sans générateur"
        return $result
    }
    if ($modeNormalise -ne "random" -and [Math]::Abs($Multiplier - 1.0) -lt 0.0001) {
        $result.Skipped = "multiplicateur a 1"
        return $result
    }

    $path = Join-Path $RomfsRoot "bin\pml\item\item.dat"
    if (-not (Test-Path -LiteralPath $path)) {
        $result.Skipped = "bin\pml\item\item.dat absent"
        return $result
    }

    $itemIdCount = 1609
    $indexTableOffset = 0x44
    $recordSize = 48

    $data = [IO.File]::ReadAllBytes($path)
    if ($data.Length -lt ($indexTableOffset + ($itemIdCount * 2))) {
        $result.Skipped = "fichier trop court, structure inattendue"
        return $result
    }

    $recordsOffset = [int](Read-U32 -Data $data -Offset 0x40)
    if ($recordsOffset -le $indexTableOffset -or $recordsOffset -ge $data.Length) {
        $result.Skipped = "en-tete inattendu, prix non modifies"
        return $result
    }

    $recordCount = [int][Math]::Floor(($data.Length - $recordsOffset) / $recordSize)
    if ($recordCount -lt 1) {
        $result.Skipped = "aucun enregistrement"
        return $result
    }

    $seenRecords = [System.Collections.Generic.HashSet[int]]::new()
    $edited = 0
    for ($itemId = 0; $itemId -lt $itemIdCount; $itemId++) {
        $record = [int](Read-U16 -Data $data -Offset ($indexTableOffset + ($itemId * 2)))
        if ($record -le 0 -or $record -ge $recordCount) {
            continue
        }
        if (-not $seenRecords.Add($record)) {
            continue
        }

        $offset = $recordsOffset + ($record * $recordSize)
        $price = [double](Read-U32 -Data $data -Offset $offset)
        # Un objet non achetable le reste : 0 x n'importe quoi vaut 0, mais on
        # sort tot pour ne pas compter une ecriture inutile.
        if ($price -le 0.0) {
            continue
        }

        $scaled = if ($modeNormalise -eq "random") {
            $Rng.Next($MinPrice, $MaxPrice + 1)
        } else {
            [Math]::Round($price * $Multiplier)
        }
        if ($scaled -lt 0) { $scaled = 0 }
        if ($scaled -gt 999999) { $scaled = 999999 }
        $scaledValue = [uint32]$scaled
        if ($scaledValue -eq [uint32]$price) {
            continue
        }

        Write-U32 -Data $data -Offset $offset -Value $scaledValue
        $edited++
    }

    if ($edited -gt 0) {
        [IO.File]::WriteAllBytes($path, $data)
    }
    $result.Edited = $edited
    return $result
}

function Invoke-ItemTableRandomization {
    param(
        [string]$RomfsRoot,
        [System.Random]$Rng
    )

    $changes = New-Object System.Collections.Generic.List[object]
    $pickupEdited = 0
    $shopEdited = 0
    $technicalRecordEdited = 0

    if ($RandomizePickupItems.IsPresent) {
        $path = Join-Path $RomfsRoot "bin\appli\chika\data_table\underground_exploration_item.prmb"
        if (Test-Path -LiteralPath $path) {
            $data = [IO.File]::ReadAllBytes($path)
            $tableIndex = 0
            foreach ($tablePos in Get-FlatBufferTableVectorPositions -Data $data) {
                $tableIndex++
                foreach ($fieldIndex in @(0, 2, 3)) {
                    $address = Get-FlatBufferFieldAddress -Data $data -TablePos $tablePos -FieldIndex $fieldIndex
                    if ($address -lt 0 -or ($address + 4) -gt $data.Length) {
                        continue
                    }

                    $rawItemId = [uint32](Read-U32 -Data $data -Offset $address)
                    if ($rawItemId -eq [uint32]::MaxValue -or $rawItemId -le 0 -or $rawItemId -gt [uint32][int]::MaxValue) {
                        continue
                    }
                    $itemId = [int]$rawItemId

                    $isTechnical = Test-TechnicalRecordItemId -ItemId $itemId
                    if ($isTechnical -and -not $RandomizeTechnicalRecords.IsPresent) {
                        continue
                    }

                    $replacement = Get-RandomItemReplacement -CurrentItemId $itemId -Rng $Rng -PreferTechnicalRecord:($isTechnical -and $RandomizeTechnicalRecords.IsPresent)
                    if ($replacement -eq $itemId) {
                        continue
                    }

                    Write-U32 -Data $data -Offset $address -Value ([uint32]$replacement)
                    $pickupEdited++
                    if ((Test-TechnicalRecordItemId -ItemId $itemId) -or (Test-TechnicalRecordItemId -ItemId $replacement)) {
                        $technicalRecordEdited++
                    }
                    $changes.Add([ordered]@{
                        source = "pickup"
                        format = "flatbuffer"
                        file = "bin\appli\chika\data_table\underground_exploration_item.prmb"
                        tableIndex = $tableIndex
                        fieldIndex = $fieldIndex
                        dataOffset = $address
                        item = [ordered]@{
                            before = New-ItemReportObject -ItemId $itemId
                            after = New-ItemReportObject -ItemId $replacement
                        }
                    })
                }
            }

            if ($pickupEdited -gt 0) {
                [IO.File]::WriteAllBytes($path, $data)
            }
        }
    }

    if ($RandomizeShopItems.IsPresent -or $RandomizeTechnicalRecords.IsPresent) {
        $path = Join-Path $RomfsRoot "bin\appli\shop\bin\shop_data.bin"
        if (Test-Path -LiteralPath $path) {
            $data = [IO.File]::ReadAllBytes($path)
            $modeBoutiqueLarge = ((Normalize-Mode $ShopItemMode) -in @("fullrandom", "full", "random", "aleatoire", "complet"))
            foreach ($inventaireBoutique in (Get-ShopInventorySlotAddresses -Data $data)) {
                $shopIndex = $inventaireBoutique.ShopIndex
                $adressesBoutique = @($inventaireBoutique.Addresses)

                # Premiere passe : releve des poches que cette boutique vend.
                # Elle doit se faire AVANT toute ecriture, sinon les poches deja
                # remplacees fausseraient l'union pour les emplacements suivants.
                $pochesDeLaBoutique = New-Object System.Collections.Generic.List[int]
                if ($modeBoutiqueLarge) {
                    $carte = Get-ItemPocketMap
                    foreach ($a in $adressesBoutique) {
                        $brut = [uint32](Read-U32 -Data $data -Offset $a)
                        if ($brut -eq [uint32]::MaxValue -or $brut -le 0 -or $brut -gt [uint32][int]::MaxValue) { continue }
                        $ident = [int]$brut
                        if ($carte.ContainsKey($ident)) { $pochesDeLaBoutique.Add([int]$carte[$ident]) }
                    }
                }

                $slotIndex = 0
                foreach ($address in $adressesBoutique) {
                    $slotIndex++
                    $rawItemId = [uint32](Read-U32 -Data $data -Offset $address)
                    if ($rawItemId -eq [uint32]::MaxValue -or $rawItemId -le 0 -or $rawItemId -gt [uint32][int]::MaxValue) {
                        continue
                    }
                    $itemId = [int]$rawItemId

                    $isTechnical = Test-TechnicalRecordItemId -ItemId $itemId
                    if ($isTechnical) {
                        if (-not $RandomizeTechnicalRecords.IsPresent) {
                            continue
                        }
                    } elseif (-not $RandomizeShopItems.IsPresent) {
                        continue
                    }

                    $replacement = if ($modeBoutiqueLarge) {
                        Get-RandomItemReplacement -CurrentItemId $itemId -Rng $Rng -PreferTechnicalRecord:($isTechnical -and $RandomizeTechnicalRecords.IsPresent) -ShopPockets ([int[]]$pochesDeLaBoutique.ToArray())
                    } else {
                        Get-RandomItemReplacement -CurrentItemId $itemId -Rng $Rng -PreferTechnicalRecord:($isTechnical -and $RandomizeTechnicalRecords.IsPresent) -SamePocket
                    }
                    if ($replacement -eq $itemId) {
                        continue
                    }

                    Write-U32 -Data $data -Offset $address -Value ([uint32]$replacement)
                    $shopEdited++
                    if ($isTechnical -or (Test-TechnicalRecordItemId -ItemId $replacement)) {
                        $technicalRecordEdited++
                    }
                    $changes.Add([ordered]@{
                        source = "shop"
                        format = "flatbuffer"
                        file = "bin\appli\shop\bin\shop_data.bin"
                        shopIndex = $shopIndex
                        slotIndex = $slotIndex
                        dataOffset = $address
                        item = [ordered]@{
                            before = New-ItemReportObject -ItemId $itemId
                            after = New-ItemReportObject -ItemId $replacement
                        }
                    })
                }
            }

            if ($shopEdited -gt 0) {
                [IO.File]::WriteAllBytes($path, $data)
            }
        }
    }

    return [pscustomobject]@{
        PickupItemsEdited = $pickupEdited
        ShopItemsEdited = $shopEdited
        TechnicalRecordsEdited = $technicalRecordEdited
        Changes = [object[]]$changes.ToArray()
        Notes = @(
            "AMX field/shop scripts are not edited; this pass only touches decoded FlatBuffer tables.",
            "Technical machines/records are randomized when they appear as item IDs in the decoded tables."
        )
    }
}

function Write-ItemChangesReport {
    param(
        [object[]]$ItemChanges,
        [string]$OutputRomfsRoot,
        [long]$ResolvedSeed,
        [object[]]$Notes = @()
    )

    if (-not $ExportJsonReport) {
        return $null
    }

    $path = Get-OutputReportPath -OutputRomfsRoot $OutputRomfsRoot -FileName "item-changes.json"
    $changesArray = Convert-ToObjectArray $ItemChanges
    $report = [ordered]@{
        generatedAt = [DateTime]::UtcNow.ToString("o")
        seed = $ResolvedSeed
        count = Get-ObjectArrayCount $changesArray
        spoilerWarning = "Ce fichier liste les objets randomises et peut spoiler une run."
        notes = @($Notes)
        changes = $changesArray
    }
    Write-JsonFile -Value $report -Path $path -Depth 24
    return $path
}

function Invoke-MoveDataRandomization {
    param(
        [string]$RomfsRoot,
        [System.Random]$Rng,
        [bool]$DoRandomizeTypes,
        [bool]$DoRandomizePower,
        [int]$PowerMin,
        [int]$PowerMax,
        [bool]$DoRandomizePP,
        [int]$PPMin,
        [int]$PPMax,
        [bool]$DoRandomizeAccuracy,
        [int]$AccuracyMin,
        [int]$AccuracyMax,
        [bool]$DoRandomizeCategory
    )

    if ((-not $DoRandomizeTypes) -and (-not $DoRandomizePower) -and (-not $DoRandomizePP) -and (-not $DoRandomizeAccuracy) -and (-not $DoRandomizeCategory)) {
        return [pscustomobject]@{
            MovesEdited = 0
            MoveTypesEdited = 0
            MovePowersEdited = 0
            MovePPEdited = 0
            MoveAccuracyEdited = 0
            MoveCategoriesEdited = 0
        }
    }

    $moveDir = Get-MoveDir -RomfsRoot $RomfsRoot
    if (-not (Test-Path -LiteralPath $moveDir)) {
        throw "Dossier moves introuvable: $moveDir"
    }

    $minPower = [Math]::Max(1, [Math]::Min(255, $PowerMin))
    $maxPower = [Math]::Max(1, [Math]::Min(255, $PowerMax))
    if ($minPower -gt $maxPower) {
        $tmp = $minPower
        $minPower = $maxPower
        $maxPower = $tmp
    }

    $minPP = [Math]::Max(1, [Math]::Min(64, $PPMin))
    $maxPP = [Math]::Max(1, [Math]::Min(64, $PPMax))
    if ($minPP -gt $maxPP) {
        $tmp = $minPP
        $minPP = $maxPP
        $maxPP = $tmp
    }

    $minAccuracy = [Math]::Max(1, [Math]::Min(100, $AccuracyMin))
    $maxAccuracy = [Math]::Max(1, [Math]::Min(100, $AccuracyMax))
    if ($minAccuracy -gt $maxAccuracy) {
        $tmp = $minAccuracy
        $minAccuracy = $maxAccuracy
        $maxAccuracy = $tmp
    }

    $movesEdited = 0
    $typesEdited = 0
    $powersEdited = 0
    $ppEdited = 0
    $accuracyEdited = 0
    $categoriesEdited = 0

    foreach ($file in Get-ChildItem -LiteralPath $moveDir -Filter "*.wazabin" -File | Sort-Object Name) {
        if ($file.BaseName -match '^waza0+$') {
            continue
        }

        $bytes = [IO.File]::ReadAllBytes($file.FullName)
        $tablePos = [int](Read-U32 -Data $bytes -Offset 0)
        $changed = $false

        if ($DoRandomizeTypes) {
            $typeAddress = Get-FlatBufferFieldAddress -Data $bytes -TablePos $tablePos -FieldIndex 3
            $newType = [byte]$Rng.Next(0, 18)
            if ($typeAddress -ge 0) {
                $bytes = Set-FlatBufferByteField -Data $bytes -TablePos $tablePos -FieldIndex 3 -Value $newType -AllowAddMissing $false
                $changed = $true
                $typesEdited++
            } else {
                $bytes = Set-FlatBufferByteField -Data $bytes -TablePos $tablePos -FieldIndex 3 -Value $newType -AllowAddMissing $true
                $typeAddress = Get-FlatBufferFieldAddress -Data $bytes -TablePos $tablePos -FieldIndex 3
                if ($typeAddress -ge 0) {
                    $changed = $true
                    $typesEdited++
                }
            }
        }

        if ($DoRandomizePower) {
            $powerAddress = Get-FlatBufferFieldAddress -Data $bytes -TablePos $tablePos -FieldIndex 6
            if ($powerAddress -ge 0 -and $bytes[$powerAddress] -gt 0) {
                $bytes[$powerAddress] = [byte]$Rng.Next($minPower, $maxPower + 1)
                $changed = $true
                $powersEdited++
            }
        }

        if ($DoRandomizeAccuracy) {
            $accuracyAddress = Get-FlatBufferFieldAddress -Data $bytes -TablePos $tablePos -FieldIndex 7
            if ($accuracyAddress -ge 0 -and $bytes[$accuracyAddress] -gt 0) {
                $bytes[$accuracyAddress] = [byte]$Rng.Next($minAccuracy, $maxAccuracy + 1)
                $changed = $true
                $accuracyEdited++
            }
        }

        if ($DoRandomizePP) {
            $ppAddress = Get-FlatBufferFieldAddress -Data $bytes -TablePos $tablePos -FieldIndex 8
            if ($ppAddress -ge 0 -and $bytes[$ppAddress] -gt 0) {
                $bytes[$ppAddress] = [byte]$Rng.Next($minPP, $maxPP + 1)
                $changed = $true
                $ppEdited++
            }
        }

        if ($DoRandomizeCategory) {
            $powerAddress = Get-FlatBufferFieldAddress -Data $bytes -TablePos $tablePos -FieldIndex 6
            $categoryAddress = Get-FlatBufferFieldAddress -Data $bytes -TablePos $tablePos -FieldIndex 5
            if ($powerAddress -ge 0 -and $categoryAddress -ge 0 -and $bytes[$powerAddress] -gt 0) {
                $bytes[$categoryAddress] = [byte]$Rng.Next(1, 3)
                $changed = $true
                $categoriesEdited++
            }
        }

        if ($changed) {
            [IO.File]::WriteAllBytes($file.FullName, $bytes)
            $movesEdited++
        }
    }

    return [pscustomobject]@{
        MovesEdited = $movesEdited
        MoveTypesEdited = $typesEdited
        MovePowersEdited = $powersEdited
        MovePPEdited = $ppEdited
        MoveAccuracyEdited = $accuracyEdited
        MoveCategoriesEdited = $categoriesEdited
    }
}

function Test-GlobalMoveDataRandomizationRequested {
    return (
        $RandomizeMoveTypes.IsPresent -or
        $RandomizeMovePower.IsPresent -or
        $RandomizeMovePP.IsPresent -or
        $RandomizeMoveAccuracy.IsPresent -or
        $RandomizeMoveCategory.IsPresent
    )
}

function Remove-SourceOnlyMoveDataFromOutput {
    param(
        [string]$OutputRomfsRoot,
        [object]$MoveDataResult
    )

    $moveDir = Get-MoveDir -RomfsRoot $OutputRomfsRoot
    if (-not (Test-Path -LiteralPath $moveDir)) {
        return $false
    }

    $movesEdited = 0
    if ($MoveDataResult -and $MoveDataResult.PSObject.Properties["MovesEdited"]) {
        $movesEdited = [int]$MoveDataResult.MovesEdited
    }

    if ((Test-GlobalMoveDataRandomizationRequested) -and $movesEdited -gt 0) {
        return $false
    }

    $rootFull = [IO.Path]::GetFullPath($OutputRomfsRoot).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $moveDirFull = [IO.Path]::GetFullPath($moveDir).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $rootPrefix = $rootFull + [IO.Path]::DirectorySeparatorChar
    $altRootPrefix = $rootFull + [IO.Path]::AltDirectorySeparatorChar
    if (-not ($moveDirFull.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -or $moveDirFull.StartsWith($altRootPrefix, [StringComparison]::OrdinalIgnoreCase))) {
        throw "Refus de supprimer le dossier moves hors sortie ROMFS: $moveDirFull"
    }

    Remove-Item -LiteralPath $moveDirFull -Recurse -Force
    return $true
}

function Invoke-GiftAndEncounterRandomization {
    param(
        [string]$RomfsRoot,
        [System.Random]$Rng,
        [string]$GiftModeValue,
        [string]$StarterModeValue,
        [int]$StarterMinBaseStatTotalValue = 0,
        [int]$StarterMaxBaseStatTotalValue = 0,
        [bool]$AllowLegendaryGiftSpecies,
        [string]$TradeModeValue,
        [bool]$AllowLegendaryTradeSpecies,
        [string]$StaticEncounterModeValue,
        [bool]$AllowLegendaryStaticSpecies,
        [string]$StaticEncounterStableMapping,
        [string]$GrassEncounterModeValue,
        [bool]$AllowLegendaryGrassSpecies,
        [string]$GrassEncounterStableMapping,
        [string]$VisibleEncounterBehaviorValue,
        [string]$EncounterDrawModeValue = "SlotParEspece",
        [string]$UndergroundModeValue,
        [bool]$AllowLegendaryUndergroundSpecies
    )

    $giftMode = Normalize-Mode $GiftModeValue
    $starterMode = Normalize-Mode $StarterModeValue
    $tradeMode = Normalize-Mode $TradeModeValue
    $staticMode = Normalize-Mode $StaticEncounterModeValue
    $grassMode = Normalize-Mode $GrassEncounterModeValue
    $visibleBehavior = Get-NormalizedVisibleEncounterBehavior -Value $VisibleEncounterBehaviorValue
    $drawMode = Get-NormalizedEncounterDrawMode -Value $EncounterDrawModeValue -LegacyVisibleBehavior $VisibleEncounterBehaviorValue
    $includeVisibleSymbolsInRomfs = ($visibleBehavior -eq "RomfsMatch" -or $drawMode -eq "FullRandom")
    $effectiveGrassStableMapping = Get-EffectiveGrassEncounterStableMapping -DrawModeValue $EncounterDrawModeValue -LegacyVisibleBehavior $VisibleEncounterBehaviorValue -FallbackStableMapping $GrassEncounterStableMapping
    $undergroundMode = Normalize-Mode $UndergroundModeValue
    $sharedEncounterStableMap = @{}
    # Lu sur le romfs SOURCE, jamais sur la sortie. La sortie ne contient que
    # les fichiers deja synchronises : sans option de rencontre en herbe, le
    # gfpak des symboles n'y est pas, la liste revenait vide et la contrainte
    # « especes affichables » devenait silencieusement inerte. Mesure du
    # 2026-09-07 : 277 rencontres fixes et 444 souterraines non affichables
    # alors que la contrainte etait censee etre active. Meme piege que le mode
    # « preferer le meme type », qui lisait lui aussi la sortie.
    $visualSpeciesPoolSource = if (-not [string]::IsNullOrWhiteSpace($SourceRomfs)) { $SourceRomfs } else { $RomfsRoot }
    # Meme reglage que la couche runtime : sans ca, les tables ROMFS seraient
    # restees plafonnees a 330 pendant que le module en affichait 664.
    $visualSpeciesPool = Get-OverworldVisiblePoolForMode -RomfsRoot $visualSpeciesPoolSource -AllowLegendaries $AllowLegendaryGrassSpecies

    # Le reservoir impose aux tables ROMFS des rencontres : filtre de
    # generation, plus la restriction « especes que le vanilla affiche » si elle
    # est demandee. Un ensemble vide veut dire « aucune contrainte ».
    $poolCompletRencontres = @(Get-BaseSpeciesPool -AllowLegendaries $AllowLegendaryGrassSpecies -RomfsRoot $RomfsRoot)

    # Un reservoir par categorie. Vide = aucune contrainte.
    # Un filtre vide rend le pool complet, donc « pas de filtrage » : pas besoin
    # d'un interrupteur au-dessus, qui ne pourrait que mentir.
    $filtrer = {
        param([string]$categorie)
        $retenu = @(Select-SpeciesByGeneration -SpeciesIds ([int[]]$poolCompletRencontres) -Filter $categorie)
        if ((Get-ObjectArrayCount $retenu) -lt 1) { return @() }
        if ((Get-ObjectArrayCount $retenu) -ge (Get-ObjectArrayCount $poolCompletRencontres)) { return @() }
        return [int[]]$retenu
    }
    $restrictionRencontres = @(& $filtrer $GenerationFilterBattle)
    $restrictionVisible = @(& $filtrer $GenerationFilterVisible)
    $restrictionCadeaux = @(& $filtrer $GenerationFilterGifts)

    if ($OverworldModelSafeEncounters -and (Get-ObjectArrayCount $visualSpeciesPool) -gt 0) {
        $visibles = [System.Collections.Generic.HashSet[int]]::new()
        foreach ($espece in $visualSpeciesPool) { $null = $visibles.Add([int]$espece) }
        if ((Get-ObjectArrayCount $restrictionRencontres) -gt 0) {
            $croise = @($restrictionRencontres | Where-Object { $visibles.Contains([int]$_) })
            if ($croise.Count -gt 0) { $restrictionRencontres = [int[]]$croise }
        } else {
            $restrictionRencontres = [int[]]$visualSpeciesPool
        }
    }
    $configuredStarters = Get-ConfiguredStarterSpeciesIds
    if ($configuredStarters) {
        Assert-PlayableSpeciesIds -RomfsRoot $RomfsRoot -SpeciesIds ([int[]]$configuredStarters) -Context "Starters manuels"
        $starterMode = "custom"
    }

    $result = [ordered]@{
        Gifts = 0
        Starters = 0
        StarterSpeciesIds = @()
        TradeSpeciesSlots = 0
        StaticEncounters = 0
        GrassEncounterSlots = 0
        UndergroundSpeciesSlots = 0
        WildEncounterChanges = @()
    }

    if ($giftMode -ne "unchanged" -or $starterMode -ne "unchanged") {
        $path = Get-AddPokePath -RomfsRoot $RomfsRoot
        if (Test-Path -LiteralPath $path) {
            $data = [IO.File]::ReadAllBytes($path)
            $starterSpeciesIds = [System.Collections.Generic.HashSet[int]]::new()
            @(810, 813, 816) | ForEach-Object { $null = $starterSpeciesIds.Add($_) }
            $starterReplacementByOriginal = @{}

            # Les cadeaux et les starters suivent le filtre « donnes au joueur ».
            $poolCadeaux = @(Get-BaseSpeciesPool -AllowLegendaries $AllowLegendaryGiftSpecies -RomfsRoot $RomfsRoot)
            $retenuCadeaux = @(Select-SpeciesByGeneration -SpeciesIds ([int[]]$poolCadeaux) -Filter $GenerationFilterGifts)
            if ((Get-ObjectArrayCount $retenuCadeaux) -gt 0) { $poolCadeaux = [int[]]$retenuCadeaux }
            $giftContext = @{
                BaseSpeciesPool = [int[]]$poolCadeaux
                BaseSpeciesEntries = @{}
                SimilarBstCache = @{}
            }
            $entries = Get-PersonalEntries -RomfsRoot $RomfsRoot
            for ($i = 1; $i -le $BaseSpeciesMax; $i++) {
                $giftContext.BaseSpeciesEntries[$i] = $entries[$i]
            }

            # Reservoir dedie aux starters, borne par le total de statistiques.
            # On n'applique la borne que s'il reste au moins trois candidats :
            # il faut bien pouvoir remplir les trois emplacements.
            $starterMinBst = [Math]::Max(0, [int]$StarterMinBaseStatTotalValue)
            $starterMaxBst = [Math]::Max(0, [int]$StarterMaxBaseStatTotalValue)
            $starterContext = $giftContext
            if ($starterMinBst -gt 0 -or $starterMaxBst -gt 0) {
                $starterPool = @($giftContext.BaseSpeciesPool | Where-Object {
                    $entry = $giftContext.BaseSpeciesEntries[[int]$_]
                    $entry -and
                        ($starterMinBst -le 0 -or [int]$entry.BST -ge $starterMinBst) -and
                        ($starterMaxBst -le 0 -or [int]$entry.BST -le $starterMaxBst)
                })
                if ($starterPool.Count -ge 3) {
                    $starterContext = @{
                        BaseSpeciesPool = [int[]]$starterPool
                        BaseSpeciesEntries = $giftContext.BaseSpeciesEntries
                        SimilarBstCache = @{}
                    }
                }
            }

            foreach ($tablePos in Get-FlatBufferTableVectorPositions -Data $data) {
                $speciesAddress = Get-FlatBufferFieldAddress -Data $data -TablePos $tablePos -FieldIndex 9
                if ($speciesAddress -lt 0) {
                    continue
                }

                $speciesId = [int](Read-U32 -Data $data -Offset $speciesAddress)
                if ($speciesId -le 0 -or $speciesId -gt $BaseSpeciesMax) {
                    continue
                }

                $isStarter = $starterSpeciesIds.Contains($speciesId)
                $mode = if ($isStarter) { $starterMode } else { $giftMode }
                if ($mode -eq "unchanged") {
                    continue
                }

                if ($isStarter -and $mode -eq "custom") {
                    switch ($speciesId) {
                        810 { $replacement = $configuredStarters[0] }
                        813 { $replacement = $configuredStarters[1] }
                        816 { $replacement = $configuredStarters[2] }
                        default { $replacement = $speciesId }
                    }
                } else {
                    $slotContext = $giftContext
                    if ($isStarter) {
                        $slotContext = $starterContext
                    }
                    $replacement = Get-SpeciesReplacement -Rng $Rng -CurrentSpeciesId $speciesId -Mode $mode -Context $slotContext
                }

                if ($isStarter) {
                    $starterReplacementByOriginal[$speciesId] = [int]$replacement
                }

                if ($replacement -ne $speciesId) {
                    Write-U32 -Data $data -Offset $speciesAddress -Value ([uint32]$replacement)
                    if ($isStarter) {
                        $result.Starters++
                    } else {
                        $result.Gifts++
                    }
                }
            }

            if (($result.Gifts + $result.Starters) -gt 0) {
                [IO.File]::WriteAllBytes($path, $data)
            }

            if ($starterReplacementByOriginal.ContainsKey(810) -and
                $starterReplacementByOriginal.ContainsKey(813) -and
                $starterReplacementByOriginal.ContainsKey(816)) {
                $result.StarterSpeciesIds = [int[]]@(
                    [int]$starterReplacementByOriginal[810],
                    [int]$starterReplacementByOriginal[813],
                    [int]$starterReplacementByOriginal[816]
                )
            }
        }
    }

    $tradeSpeciesResult = Invoke-FlatBufferSpeciesFieldRandomization `
        -RomfsRoot $RomfsRoot `
        -Path (Get-FieldTradePath -RomfsRoot $RomfsRoot) `
        -FieldIndices @(8, 18) `
        -Rng $Rng `
        -ModeValue $TradeModeValue `
        -RestrictToSpeciesPool $restrictionCadeaux `
        -AllowLegendarySpecies $AllowLegendaryTradeSpecies `
        -BlockName "inGameTrade"
    $result.TradeSpeciesSlots = $tradeSpeciesResult.Edited

    $staticEncounterResult = Invoke-FlatBufferSpeciesFieldRandomization `
        -RomfsRoot $RomfsRoot `
        -Path (Get-EventEncounterPath -RomfsRoot $RomfsRoot) `
        -FieldIndices @(17) `
        -Rng $Rng `
        -ModeValue $StaticEncounterModeValue `
        -AllowLegendarySpecies $AllowLegendaryStaticSpecies `
        -BlockName "staticScriptedEncounter" `
        -StableMappingMode $StaticEncounterStableMapping `
        -StableMap $sharedEncounterStableMap `
        -RestrictToSpeciesPool $restrictionRencontres
    $result.StaticEncounters = $staticEncounterResult.Edited

    $grassResult = Invoke-GrassEncounterRandomization `
        -RomfsRoot $RomfsRoot `
        -Rng $Rng `
        -ModeValue $GrassEncounterModeValue `
        -AllowLegendarySpecies $AllowLegendaryGrassSpecies `
        -StableMappingMode $effectiveGrassStableMapping `
        -IncludeVisibleSymbols $includeVisibleSymbolsInRomfs `
        -StableMap $sharedEncounterStableMap `
        -VisualSpeciesPool $visualSpeciesPool `
        -RestrictToSpeciesPool $restrictionRencontres `
        -RestrictVisibleToSpeciesPool $restrictionVisible
    $result.GrassEncounterSlots = $grassResult.Edited

    # Apres la randomisation des especes : celle-ci reecrit l'archive, la mise a
    # l'echelle des niveaux doit donc repartir du fichier deja modifie.
    $wildLevelResult = Invoke-WildLevelAdjustment -RomfsRoot $RomfsRoot -Percent $WildLevelPercent
    if ($wildLevelResult.Edited -gt 0) {
        Write-Host ("[Wild] niveaux ajustes : {0} bornes modifiees ({1:+#;-#;0} %)" -f $wildLevelResult.Edited, [int]$WildLevelPercent)
    } elseif ($wildLevelResult.Skipped) {
        Write-Host ("[Wild] niveaux non modifies : {0}" -f $wildLevelResult.Skipped)
    }

    $undergroundResult = Invoke-FlatBufferSpeciesFieldRandomization `
        -RomfsRoot $RomfsRoot `
        -Path (Get-UndergroundExplorationPokePath -RomfsRoot $RomfsRoot) `
        -FieldIndices @(21, 22, 23, 24) `
        -Rng $Rng `
        -ModeValue $UndergroundModeValue `
        -AllowLegendarySpecies $AllowLegendaryUndergroundSpecies `
        -BlockName "undergroundEncounter" `
        -RestrictToSpeciesPool $restrictionRencontres
    $result.UndergroundSpeciesSlots = $undergroundResult.Edited
    $result.WildEncounterChanges = @($staticEncounterResult.Changes) + @($grassResult.Changes) + @($undergroundResult.Changes)

    return [pscustomobject]$result
}

function Update-StarterRelatedTrainerTeams {
    param(
        [string]$RomfsRoot,
        [int[]]$StarterSpeciesIds,
        [string]$TrainerMoveMode = "Unchanged",
        [string]$TrainerSmogonMoveFallbackMode = "LastLevelUp4",
        [System.Random]$Rng = $null
    )

    $emptyResult = [pscustomobject]@{
        FilesEdited = 0
        SlotsEdited = 0
        Changes = @()
    }

    if (-not $StarterSpeciesIds -or $StarterSpeciesIds.Count -ne 3) {
        return $emptyResult
    }

    $trainerPokeDir = Get-TrainerPokeDir -RomfsRoot $RomfsRoot
    $normalizedTrainerMoveMode = Normalize-Mode $TrainerMoveMode
    $normalizedSmogonMoveFallbackMode = Normalize-Mode $TrainerSmogonMoveFallbackMode
    if ($normalizedSmogonMoveFallbackMode -notin @("lastlevelup4", "random4", "unchanged")) {
        $normalizedSmogonMoveFallbackMode = "lastlevelup4"
    }
    $usesSmogonTrainerMoves = Test-TrainerModeUsesSmogon $normalizedTrainerMoveMode
    $shouldRebuildMoves = $normalizedTrainerMoveMode -in @("unchanged", "lastlevelup4", "random4", "smogonstrategic", "smogonlegacy", "smogonhistory", "smogonhistorical")
    if ($shouldRebuildMoves -and ($normalizedTrainerMoveMode -eq "random4" -or $usesSmogonTrainerMoves) -and $null -eq $Rng) {
        $Rng = [System.Random]::new()
    }
    $personalEntries = if ($shouldRebuildMoves) { Get-PersonalEntries -RomfsRoot $RomfsRoot } else { @() }
    $needsLevelMoves = $shouldRebuildMoves -and ($normalizedTrainerMoveMode -ne "random4") -and -not ($usesSmogonTrainerMoves -and $normalizedSmogonMoveFallbackMode -eq "random4")
    $learnsetBytes = if ($needsLevelMoves) { Get-LearnsetBytes -RomfsRoot $RomfsRoot } else { $null }
    $movePool = if ($shouldRebuildMoves -and ($normalizedTrainerMoveMode -eq "random4" -or $usesSmogonTrainerMoves)) { Get-MovePool -RomfsRoot $RomfsRoot } else { @() }
    $movePoolSet = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($moveId in @($movePool)) {
        if ([int]$moveId -gt 0) {
            $null = $movePoolSet.Add([int]$moveId)
        }
    }
    $smogonStrategicData = if ($usesSmogonTrainerMoves) {
        if (Test-TrainerModeUsesSmogonLegacy $normalizedTrainerMoveMode) { Get-SmogonStrategicLegacyData } else { Get-SmogonStrategicData }
    } else { $null }
    $levelUpMoveCache = @{}
    $replacements = @{
        810 = $StarterSpeciesIds[0]
        811 = $StarterSpeciesIds[0]
        812 = $StarterSpeciesIds[0]
        813 = $StarterSpeciesIds[1]
        814 = $StarterSpeciesIds[1]
        815 = $StarterSpeciesIds[1]
        816 = $StarterSpeciesIds[2]
        817 = $StarterSpeciesIds[2]
        818 = $StarterSpeciesIds[2]
    }

    $plannedSlotsByTrainerId = @{}
    foreach ($entry in (Get-VanillaTrainerMetadata).Values) {
        foreach ($mon in @($entry["Party"])) {
            $originalSpeciesId = [int]$mon["speciesId"]
            if (-not $replacements.ContainsKey($originalSpeciesId)) {
                continue
            }

            $trainerId = [int]$entry["Id"]
            if (-not $plannedSlotsByTrainerId.ContainsKey($trainerId)) {
                $plannedSlotsByTrainerId[$trainerId] = New-Object System.Collections.Generic.List[object]
            }
            $plannedSlotsByTrainerId[$trainerId].Add([ordered]@{
                slot = [int]$mon["slot"]
                originalSpeciesId = $originalSpeciesId
                replacementSpeciesId = [int]$replacements[$originalSpeciesId]
                vanillaLevel = [int]$mon["level"]
            })
        }
    }

    $edited = 0
    $slotsEdited = 0
    $changes = New-Object System.Collections.Generic.List[object]
    foreach ($trainerId in @($plannedSlotsByTrainerId.Keys | Sort-Object)) {
        $targetFile = "trainer_poke_{0:D3}.bin" -f [int]$trainerId
        $path = Join-Path $trainerPokeDir $targetFile
        if (-not (Test-Path -LiteralPath $path)) {
            continue
        }

        $file = Get-Item -LiteralPath $path
        $bytes = [IO.File]::ReadAllBytes($file.FullName)
        $changed = $false

        $plansForTrainer = [System.Collections.Generic.List[object]]$plannedSlotsByTrainerId[$trainerId]
        foreach ($plan in $plansForTrainer.ToArray()) {
            $slot = [int]$plan["slot"]
            $offset = $slot * $TrainerPokemonRecordSize
            if ($offset -lt 0 -or ($offset + $TrainerPokemonRecordSize) -gt $bytes.Length) {
                continue
            }

            $beforeSpeciesId = Read-U16 -Data $bytes -Offset ($offset + 0x0C)
            $beforeFormId = Read-U16 -Data $bytes -Offset ($offset + 0x0E)
            $replacement = [int]$plan["replacementSpeciesId"]
            if ($beforeSpeciesId -ne $replacement -or $beforeFormId -ne 0) {
                $beforeMoves = @()
                foreach ($moveOffset in 0x12, 0x14, 0x16, 0x18) {
                    $beforeMoves += New-MoveReportObject -MoveId (Read-U16 -Data $bytes -Offset ($offset + $moveOffset))
                }

                Write-U16 -Data $bytes -Offset ($offset + 0x0C) -Value $replacement
                Write-U16 -Data $bytes -Offset ($offset + 0x0E) -Value 0

                if ($shouldRebuildMoves) {
                    $level = [int](Read-U16 -Data $bytes -Offset ($offset + 0x0A))
                    if ($normalizedTrainerMoveMode -eq "random4" -and (Get-ObjectArrayCount $movePool) -gt 0) {
                        $null = Set-TrainerMovesRandomDistinct -Data $bytes -Offset $offset -MovePool $movePool -Rng $Rng
                    } elseif ($usesSmogonTrainerMoves) {
                        $null = Set-TrainerMovesSmogonStrategic -Data $bytes -Offset $offset -SmogonData $smogonStrategicData -SpeciesId $replacement -FormId 0 -Level $level -Rng $Rng -FallbackMode $normalizedSmogonMoveFallbackMode -MovePool $movePool -MovePoolSet $movePoolSet -LearnsetBytes $learnsetBytes -PersonalEntries $personalEntries -Cache $levelUpMoveCache
                    } else {
                        $null = Set-TrainerMovesFromSpeciesLevel -Data $bytes -Offset $offset -LearnsetBytes $learnsetBytes -PersonalEntries $personalEntries -SpeciesId $replacement -FormId 0 -Level $level -Cache $levelUpMoveCache
                    }
                }

                $afterMoves = @()
                foreach ($moveOffset in 0x12, 0x14, 0x16, 0x18) {
                    $afterMoves += New-MoveReportObject -MoveId (Read-U16 -Data $bytes -Offset ($offset + $moveOffset))
                }

                $changed = $true
                $slotsEdited++

                $trainerMeta = (Get-VanillaTrainerMetadata)[$trainerId]
                $changes.Add([ordered]@{
                    trainerId = [int]$trainerId
                    trainer = [ordered]@{
                        fr = if ($trainerMeta) { [string]$trainerMeta["FrFull"] } else { "" }
                        en = if ($trainerMeta) { [string]$trainerMeta["EnFull"] } else { "" }
                    }
                    file = $targetFile
                    slot = $slot + 1
                    vanillaStarterSpecies = New-SpeciesReportObject -SpeciesId ([int]$plan["originalSpeciesId"])
                    before = New-SpeciesReportObject -SpeciesId $beforeSpeciesId
                    after = New-SpeciesReportObject -SpeciesId $replacement
                    forcedFormId = 0
                    moveModeApplied = if ($shouldRebuildMoves) { $normalizedTrainerMoveMode } else { "unchanged" }
                    beforeMoves = $beforeMoves
                    afterMoves = $afterMoves
                })
            }
        }

        if ($changed) {
            [IO.File]::WriteAllBytes($file.FullName, $bytes)
            $edited++
        }
    }

    return [pscustomobject]@{
        FilesEdited = $edited
        SlotsEdited = $slotsEdited
        Changes = [object[]]$changes.ToArray()
    }
}

function Invoke-PersonalRandomization {
    param(
        [string]$RomfsRoot,
        [System.Random]$Rng,
        [string]$TypeModeValue,
        [bool]$TypesMonotype,
        [string]$AbilityModeValue,
        [bool]$AllowWonderGuardValue,
        [string]$StatModeValue,
        [double]$ExpMultiplierValue,
        [bool]$ForceOneExpYieldValue
    )

    $typeMode = Normalize-Mode $TypeModeValue
    $abilityMode = Normalize-Mode $AbilityModeValue
    $statMode = Normalize-Mode $StatModeValue
    if ($ExpMultiplierValue -lt 0.0 -or $ExpMultiplierValue -gt 100.0) {
        throw "Multiplicateur EXP invalide: utilise une valeur entre 0 et 100. Exemples: 0.6, 1.0, 5.0."
    }
    $doForceOneExp = $ForceOneExpYieldValue
    $doScaleExp = (-not $doForceOneExp) -and ([Math]::Abs($ExpMultiplierValue - 1.0) -gt 0.0001)

    if ($typeMode -eq "unchanged" -and $abilityMode -eq "unchanged" -and $statMode -eq "unchanged" -and -not $doScaleExp -and -not $doForceOneExp) {
        return [pscustomobject]@{ PersonalEntriesEdited = 0; ExpYieldsEdited = 0 }
    }

    $path = Get-PersonalPath -RomfsRoot $RomfsRoot
    $data = [IO.File]::ReadAllBytes($path)
    $entries = Get-PersonalEntries -RomfsRoot $RomfsRoot
    $abilityPool = Get-AbilityPool -PersonalEntries $entries -AllowWonderGuard $AllowWonderGuardValue
    $edited = 0
    $expYieldsEdited = 0

    for ($species = 1; $species -lt $entries.Count; $species++) {
        $offset = $species * $PersonalRecordSize
        $changed = $false

        if ($statMode -ne "unchanged") {
            $stats = @(
                [int]$data[$offset + 0],
                [int]$data[$offset + 1],
                [int]$data[$offset + 2],
                [int]$data[$offset + 3],
                [int]$data[$offset + 4],
                [int]$data[$offset + 5]
            )
            $newStats = Get-StatsReplacement -Rng $Rng -Stats $stats -Mode $statMode
            for ($i = 0; $i -lt 6; $i++) {
                $data[$offset + $i] = [byte]$newStats[$i]
            }
            $changed = $true
        }

        if ($typeMode -eq "random") {
            $type1 = $Rng.Next(0, 18)
            $type2 = if ($TypesMonotype -or $Rng.NextDouble() -lt 0.40) { $type1 } else { $Rng.Next(0, 18) }
            $data[$offset + 6] = [byte]$type1
            $data[$offset + 7] = [byte]$type2
            $changed = $true
        }

        if ($abilityMode -eq "random") {
            Write-U16 -Data $data -Offset ($offset + 0x18) -Value (Random-FromPool -Rng $Rng -Pool $abilityPool)
            Write-U16 -Data $data -Offset ($offset + 0x1A) -Value (Random-FromPool -Rng $Rng -Pool $abilityPool)
            Write-U16 -Data $data -Offset ($offset + 0x1C) -Value (Random-FromPool -Rng $Rng -Pool $abilityPool)
            $changed = $true
        }

        if ($doForceOneExp -or $doScaleExp) {
            $expOffset = $offset + $PersonalBaseExpOffset
            $baseExp = Read-U16 -Data $data -Offset $expOffset
            if ($baseExp -gt 0) {
                $scaledExp = if ($doForceOneExp) {
                    1
                } else {
                    [int][Math]::Round([double]$baseExp * $ExpMultiplierValue, [MidpointRounding]::AwayFromZero)
                }
                if ($scaledExp -lt 1) { $scaledExp = 1 }
                if ($scaledExp -gt [uint16]::MaxValue) { $scaledExp = [uint16]::MaxValue }
                if ($scaledExp -ne $baseExp) {
                    Write-U16 -Data $data -Offset $expOffset -Value $scaledExp
                    $expYieldsEdited++
                    $changed = $true
                }
            }
        }

        if ($changed) {
            $edited++
        }
    }

    [IO.File]::WriteAllBytes($path, $data)
    return [pscustomobject]@{
        PersonalEntriesEdited = $edited
        ExpYieldsEdited = $expYieldsEdited
    }
}

function Invoke-TrainerRandomization {
    param(
        [string]$RomfsRoot,
        [System.Random]$Rng,
        [string]$SpeciesModeValue,
        [string]$MoveModeValue,
        [string]$SmogonMoveFallbackModeValue = "LastLevelUp4",
        [string]$ItemModeValue,
        [string]$ItemPoolModeValue = "Battle",
        [string]$AddedSlotSpeciesModeValue = "Random",
        [string]$DuplicateModeValue = "NoDuplicates",
        [string]$BagItemModeValue = "Unchanged",
        [string]$AbilityModeValue,
        [string]$IVModeValue,
        [string]$EVModeValue,
        [string]$NatureModeValue = "Unchanged",
        [bool]$DoRandomizeNatures,
        [double]$LevelMultiplier,
        [int]$TeamMin,
        [int]$TeamMax,
        [bool]$DoTypeThemedTeams,
        [double]$ShinyChancePercent,
        [bool]$DoForceFullyEvolved,
        [int]$FullyEvolvedLevel,
        [bool]$DoMaxTrainerAI,
        [string]$DynamaxLevelModeValue,
        [bool]$DoForceCanDynamax,
        [bool]$DoForceAllTeamsToSix,
        [object[]]$BossTeamsToSixTargetCatalog = @(),
        [object[]]$TeamMaxNormalizationTargetCatalog = @(),
        [string]$TeamMaxNormalizationMode = "none",
        [bool]$AllowLegendarySpecies,
        # Regles speciales. Les deux catalogues servent a classer les dresseurs :
        # ceux du catalogue arenes+ligue sont des "Boss", ceux qui sont dans le
        # catalogue des boss majeurs sans etre dans le premier sont "Important",
        # le reste est "Normal".
        [object[]]$GymLeagueRuleTargetCatalog = @(),
        [object[]]$MajorBossRuleTargetCatalog = @(),
        [int]$ExtraPokemonBoss = 0,
        [int]$ExtraPokemonImportant = 0,
        [int]$ExtraPokemonRegular = 0,
        [string]$SpecialRuleScopeValue = "GymLeague",
        [string]$LegendaryPolicyValue = "Unchanged",
        [int]$MinBaseStatTotalValue = 0,
        [string]$ForceDiverseTypesScopeValue = "Off",
        [scriptblock]$ProgressCallback = $null
    )

    $speciesMode = Normalize-Mode $SpeciesModeValue
    $moveMode = Normalize-Mode $MoveModeValue
    $smogonMoveFallbackMode = Normalize-Mode $SmogonMoveFallbackModeValue
    if ($smogonMoveFallbackMode -notin @("lastlevelup4", "random4", "unchanged")) {
        $smogonMoveFallbackMode = "lastlevelup4"
    }
    $itemMode = Normalize-Mode $ItemModeValue
    $itemPoolMode = Normalize-Mode $ItemPoolModeValue
    $addedSlotSpeciesMode = Normalize-Mode $AddedSlotSpeciesModeValue
    if ($addedSlotSpeciesMode -notin @("random", "similarbst", "sametyperandom", "sametypebst", "randomsametype", "similarbstsametype", "typedrandom", "typedbst")) {
        $addedSlotSpeciesMode = "random"
    }
    $addedSlotBaseSpeciesMode = switch ($addedSlotSpeciesMode) {
        { $_ -in @("sametypebst", "similarbstsametype", "typedbst") } { "similarbst"; break }
        default { "random" }
    }
    $addedSlotNeedsGymLeagueType = ($addedSlotSpeciesMode -in @("sametyperandom", "sametypebst", "randomsametype", "similarbstsametype", "typedrandom", "typedbst"))
    $bagItemMode = Normalize-Mode $BagItemModeValue
    if ($bagItemMode -notin @("none", "vide", "empty", "random", "aleatoire")) {
        $bagItemMode = "unchanged"
    }
    if ($bagItemMode -in @("vide", "empty")) { $bagItemMode = "none" }
    if ($bagItemMode -eq "aleatoire") { $bagItemMode = "random" }
    # Le remplacant reste dans la MEME POCHE que l'objet remplace. On ne
    # pretend pas savoir laquelle est celle des soins : le code du projet
    # interdit d'inclure sur une poche supposee, et seules trois poches sont
    # prouvees. Rester dans la poche d'origine donne la garantie sans le pari,
    # et c'est deja la regle des boutiques.
    $bagItemsEdited = 0
    $duplicateMode = Normalize-Mode $DuplicateModeValue
    $preventTrainerDuplicates = $duplicateMode -notin @("normal", "allow", "allowduplicates", "duplicates", "vanilla")
    $abilityMode = Normalize-Mode $AbilityModeValue
    $ivMode = Normalize-Mode $IVModeValue
    $evMode = Normalize-Mode $EVModeValue
    $natureMode = Get-EffectiveTrainerNatureMode -Mode $NatureModeValue -LegacyRandomize $DoRandomizeNatures
    $bossTeamsToSixTargetArray = Convert-ToObjectArray $BossTeamsToSixTargetCatalog
    $teamMaxNormalizationTargetArray = Convert-ToObjectArray $TeamMaxNormalizationTargetCatalog

    # --- Regles speciales de dresseurs -------------------------------------
    $extraPokemonBoss = [Math]::Max(0, [Math]::Min(5, [int]$ExtraPokemonBoss))
    $extraPokemonImportant = [Math]::Max(0, [Math]::Min(5, [int]$ExtraPokemonImportant))
    $extraPokemonRegular = [Math]::Max(0, [Math]::Min(5, [int]$ExtraPokemonRegular))
    $extraPokemonMax = [Math]::Max($extraPokemonBoss, [Math]::Max($extraPokemonImportant, $extraPokemonRegular))
    $trainerRuleScope = Normalize-TrainerSpecialRuleScope -Scope $SpecialRuleScopeValue
    $trainerLegendaryPolicy = Normalize-TrainerLegendaryPolicy -Policy $LegendaryPolicyValue
    $trainerMinBst = [Math]::Max(0, [int]$MinBaseStatTotalValue)
    $trainerRulesActive = ($trainerLegendaryPolicy -ne "unchanged") -or ($trainerMinBst -gt 0)

    # "Types varies" : desactive si la valeur ne designe pas une portee.
    $diverseTypesRaw = Normalize-Mode $ForceDiverseTypesScopeValue
    $diverseTypesActive = $diverseTypesRaw -notin @("off", "", "unchanged", "none")
    $diverseTypesScope = if ($diverseTypesActive) { Normalize-TrainerSpecialRuleScope -Scope $ForceDiverseTypesScopeValue } else { "" }

    # Classement des dresseurs. Un identifiant present dans le catalogue
    # arenes+ligue est un Boss ; present seulement dans le catalogue des boss
    # majeurs, il est Important ; absent des deux, il est Normal.
    $gymLeagueRuleIds = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($target in (Convert-ToObjectArray $GymLeagueRuleTargetCatalog)) {
        $targetTrainerId = -1
        if ($null -ne $target -and $null -ne $target.trainerId -and [int]::TryParse([string]$target.trainerId, [ref]$targetTrainerId)) {
            $null = $gymLeagueRuleIds.Add($targetTrainerId)
        }
    }
    $majorBossRuleIds = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($target in (Convert-ToObjectArray $MajorBossRuleTargetCatalog)) {
        $targetTrainerId = -1
        if ($null -ne $target -and $null -ne $target.trainerId -and [int]::TryParse([string]$target.trainerId, [ref]$targetTrainerId)) {
            $null = $majorBossRuleIds.Add($targetTrainerId)
        }
    }

    if (
        $speciesMode -eq "unchanged" -and
        $moveMode -eq "unchanged" -and
        $itemMode -eq "unchanged" -and
        $abilityMode -eq "unchanged" -and
        $ivMode -eq "unchanged" -and
        $evMode -eq "unchanged" -and
        $natureMode -eq "unchanged" -and
        $LevelMultiplier -eq 1.0 -and
        $TeamMin -lt 0 -and
        $TeamMax -lt 0 -and
        (-not $DoTypeThemedTeams) -and
        $ShinyChancePercent -le 0.0 -and
        (-not $DoForceFullyEvolved) -and
        (-not $DoMaxTrainerAI) -and
        ($bagItemMode -eq "unchanged") -and
        (Normalize-Mode $DynamaxLevelModeValue) -eq "unchanged" -and
        (-not $DoForceCanDynamax) -and
        (-not $DoForceAllTeamsToSix) -and
        ((Get-ObjectArrayCount $bossTeamsToSixTargetArray) -lt 1) -and
        $extraPokemonMax -lt 1 -and
        (-not $trainerRulesActive) -and
        (([string]$TeamMaxNormalizationMode) -eq "none" -or (Get-ObjectArrayCount $teamMaxNormalizationTargetArray) -lt 1)
    ) {
        return [pscustomobject]@{ Trainers = 0; Pokemon = 0; BossTeamsExpanded = 0; BossTeamsLevelNormalized = 0; ShiniesForced = 0; SpeciesForceEvolved = 0; TrainerTypeThemedTrainers = 0; TrainerAIMaxed = 0; BagItemsEdited = 0; DynamaxLevelsEdited = 0; DynamaxFlagsForced = 0; BossTrainerTargets = @(); TrainerChanges = @() }
    }

    $mayExtendTrainerTeams = $DoForceAllTeamsToSix -or ((Get-ObjectArrayCount $bossTeamsToSixTargetArray) -gt 0) -or ($TeamMin -ge 0) -or ($extraPokemonMax -gt 0)
    # Les equipes adverses suivent leur PROPRE filtre de generation. Laisse-le
    # vide et elles suivent le filtre global ; renseigne-le pour « joueur en
    # generation 1, adversaires en tout ».
    $poolDresseurs = @(Get-BaseSpeciesPool -AllowLegendaries $AllowLegendarySpecies -RomfsRoot $RomfsRoot)
    $retenuDresseurs = @(Select-SpeciesByGeneration -SpeciesIds ([int[]]$poolDresseurs) -Filter $GenerationFilterTrainers)
    if ((Get-ObjectArrayCount $retenuDresseurs) -gt 0) { $poolDresseurs = [int[]]$retenuDresseurs }
    $context = @{
        BaseSpeciesPool = [int[]]$poolDresseurs
        BaseSpeciesEntries = @{}
        SimilarBstCache = @{}
    }
    $personalEntries = @()
    $usesSmogonStrategy = (Test-TrainerModeUsesSmogon $moveMode) -or (Test-TrainerModeUsesSmogon $itemMode) -or (Test-TrainerModeUsesSmogon $abilityMode) -or (Test-TrainerModeUsesSmogon $evMode) -or (Test-TrainerModeUsesSmogon $natureMode)
    $usesSmogonLegacyStrategy = (Test-TrainerModeUsesSmogonLegacy $moveMode) -or (Test-TrainerModeUsesSmogonLegacy $itemMode) -or (Test-TrainerModeUsesSmogonLegacy $abilityMode) -or (Test-TrainerModeUsesSmogonLegacy $evMode) -or (Test-TrainerModeUsesSmogonLegacy $natureMode)
    $usesStrictSmogonStrategy = $usesSmogonStrategy -and -not $usesSmogonLegacyStrategy
    $needsLevelMoveFallback = ($moveMode -eq "lastlevelup4") -or ((Test-TrainerModeUsesSmogon $moveMode) -and $smogonMoveFallbackMode -eq "lastlevelup4")
    # Les regles speciales lisent le total de statistiques : sans les entrees
    # personal, le filtre BST ne pourrait rien decider.
    $needsPersonalEntries = ($speciesMode -ne "unchanged") -or $needsLevelMoveFallback -or (Test-TrainerModeUsesSmogon $abilityMode) -or $mayExtendTrainerTeams -or $trainerRulesActive -or $diverseTypesActive
    if ($needsPersonalEntries) {
        $personalEntries = Get-PersonalEntries -RomfsRoot $RomfsRoot
        for ($i = 1; $i -le $BaseSpeciesMax; $i++) {
            $context.BaseSpeciesEntries[$i] = $personalEntries[$i]
        }
    }
    # Reservoir de secours pour les regles qui exigent des legendaires alors que
    # le reservoir courant les exclut. Calcule une seule fois, et seulement si
    # une regle en a besoin.
    $trainerRuleFallbackPool = [int[]]@()
    if ($trainerRulesActive -and $trainerLegendaryPolicy -in @("all", "oneeach")) {
        $trainerRuleFallbackPool = [int[]](Get-BaseSpeciesPool -AllowLegendaries $true -RomfsRoot $RomfsRoot)
    }

    $learnsetBytes = if ($needsLevelMoveFallback -or $mayExtendTrainerTeams) { Get-LearnsetBytes -RomfsRoot $RomfsRoot } else { $null }
    $levelUpMoveCache = @{}
    $movePool = if ($moveMode -eq "random4" -or (Test-TrainerModeUsesSmogon $moveMode)) { Get-MovePool -RomfsRoot $RomfsRoot } else { @() }
    $movePoolSet = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($moveId in @($movePool)) {
        if ([int]$moveId -gt 0) {
            $null = $movePoolSet.Add([int]$moveId)
        }
    }
    $itemPool = if ($itemMode -eq "randomwhenpresent" -or $itemMode -eq "forceall" -or (Test-TrainerModeUsesSmogon $itemMode)) { Get-TrainerItemPool -RomfsRoot $RomfsRoot -PoolMode $itemPoolMode } else { @() }
    $itemPoolSet = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($itemId in @($itemPool)) {
        if ([int]$itemId -gt 0) {
            $null = $itemPoolSet.Add([int]$itemId)
        }
    }
    $smogonStrategicData = if ($usesSmogonStrategy) {
        if ($usesSmogonLegacyStrategy) { Get-SmogonStrategicLegacyData } else { Get-SmogonStrategicData }
    } else { $null }
    $smogonTrainerSpeciesSet = $null
    if ($usesStrictSmogonStrategy) {
        $smogonTrainerSpeciesSet = Get-SmogonStrategicSpeciesIdSet -SmogonData $smogonStrategicData -PersonalEntries $personalEntries -RequireLegalAbility:(Test-TrainerModeUsesSmogon $abilityMode)
        if ($smogonTrainerSpeciesSet.Count -gt 0) {
            $smogonBaseSpeciesPool = @($context.BaseSpeciesPool | Where-Object { $smogonTrainerSpeciesSet.Contains([int]$_) })
            if ($smogonBaseSpeciesPool.Count -gt 0) {
                $context.BaseSpeciesPool = [int[]]$smogonBaseSpeciesPool
                $context.SimilarBstCache = @{}
            }
        }
    }

    $trainerDataDir = Get-TrainerDataDir -RomfsRoot $RomfsRoot
    $trainerPokeDir = Get-TrainerPokeDir -RomfsRoot $RomfsRoot
    $trainerFiles = Get-ChildItem -LiteralPath $trainerDataDir -Filter "*.bin" -File | Sort-Object Name
    $editedTrainers = 0
    $editedPokemon = 0
    $bossTeamsExpanded = 0
    $bossTeamsLevelNormalized = 0
    $shiniesForced = 0
    $speciesForceEvolved = 0
    $trainerTypeThemedTrainers = 0
    $trainerAIMaxed = 0
    $dynamaxLevelsEdited = 0
    $dynamaxFlagsForced = 0
    $trainerChangeLog = New-Object System.Collections.Generic.List[object]
    $bossTrainerTargets = New-Object System.Collections.Generic.List[object]
    $bossTeamsToSixTrainerIds = [System.Collections.Generic.HashSet[int]]::new()
    $bossTargetCatalogById = @{}
    foreach ($target in $bossTeamsToSixTargetArray) {
        if ($null -ne $target -and $target.PSObject.Properties.Name -contains "trainerId") {
            $targetTrainerId = [int]$target.trainerId
            $null = $bossTeamsToSixTrainerIds.Add($targetTrainerId)
            $bossTargetCatalogById[$targetTrainerId] = $target
        }
    }
    $teamMaxNormalizationTargetMap = @{}
    foreach ($target in $teamMaxNormalizationTargetArray) {
        if ($null -eq $target -or -not ($target.PSObject.Properties.Name -contains "trainerId")) {
            continue
        }
        $targetTrainerId = [int]$target.trainerId
        $teamMaxNormalizationTargetMap[$targetTrainerId] = $target
        if (-not $bossTargetCatalogById.ContainsKey($targetTrainerId)) {
            $bossTargetCatalogById[$targetTrainerId] = $target
        }
    }
    $shinyChance = [Math]::Max(0.0, [Math]::Min(100.0, $ShinyChancePercent))
    $dynamaxLevelMode = Normalize-Mode $DynamaxLevelModeValue
    $forceEvolutionLevel = [Math]::Max(1, [Math]::Min(100, $FullyEvolvedLevel))
    $evolutionTargetsBySpecies = if ($DoForceFullyEvolved) { Get-EvolutionTargetsBySpecies -RomfsRoot $RomfsRoot } else { @{} }
    $hasGlobalTrainerEdits = (
        $speciesMode -ne "unchanged" -or
        $moveMode -ne "unchanged" -or
        $itemMode -ne "unchanged" -or
        $abilityMode -ne "unchanged" -or
        $ivMode -ne "unchanged" -or
        $evMode -ne "unchanged" -or
        $natureMode -ne "unchanged" -or
        $LevelMultiplier -ne 1.0 -or
        $TeamMin -ge 0 -or
        $TeamMax -ge 0 -or
        $DoTypeThemedTeams -or
        $ShinyChancePercent -gt 0.0 -or
        $DoForceFullyEvolved -or
        $DoMaxTrainerAI -or
        $dynamaxLevelMode -ne "unchanged" -or
        $DoForceCanDynamax -or
        $DoForceAllTeamsToSix
    )

    $trainerIndex = 0
    foreach ($trainerDataFile in $trainerFiles) {
        $trainerIndex++
        if (($trainerIndex % 100) -eq 0) {
            Write-RandomizerProgress -Message ("[Trainers] {0}/{1}" -f $trainerIndex, $trainerFiles.Count) -ProgressCallback $ProgressCallback
        }
        $suffix = ($trainerDataFile.BaseName -split "_")[-1]
        $trainerPokeFile = Join-Path $trainerPokeDir ("trainer_poke_{0}.bin" -f $suffix)
        if (-not (Test-Path -LiteralPath $trainerPokeFile)) {
            continue
        }

        $trainerId = [int]$suffix
        $dataBytes = [IO.File]::ReadAllBytes($trainerDataFile.FullName)
        $partyBytes = [IO.File]::ReadAllBytes($trainerPokeFile)
        $beforeDataBytes = [byte[]]$dataBytes.Clone()
        $beforePartyBytes = [byte[]]$partyBytes.Clone()
        $beforeTeamSize = [int]$beforeDataBytes[3]
        $beforeRecordCount = [int]($beforePartyBytes.Length / $TrainerPokemonRecordSize)
        $beforeAI = if ($beforeDataBytes.Length -ge 0x10) { Read-U32 -Data $beforeDataBytes -Offset 0x0C } else { $null }
        $changedTrainer = $false
        if ($DoMaxTrainerAI -and $dataBytes.Length -ge 0x10) {
            $maxAIFlags = [uint32]::MaxValue
            $currentAI = Read-U32 -Data $dataBytes -Offset 0x0C
            if ($currentAI -ne $maxAIFlags) {
                Write-U32 -Data $dataBytes -Offset 0x0C -Value $maxAIFlags
                $trainerAIMaxed++
                $changedTrainer = $true
            }
        }
        # Le sac du dresseur : quatre emplacements d'objets a 0x04, 0x06, 0x08
        # et 0x0A d'un enregistrement de 20 octets. Ce sont les soins qu'il
        # utilise en plein combat.
        if ($bagItemMode -ne "unchanged" -and $dataBytes.Length -ge 0x0C) {
            foreach ($bagOffset in 0x04, 0x06, 0x08, 0x0A) {
                $actuel = [int](Read-U16 -Data $dataBytes -Offset $bagOffset)
                if ($actuel -le 0) { continue }
                $remplacant = if ($bagItemMode -eq "none") {
                    0
                } else {
                    [int](Get-RandomItemReplacement -CurrentItemId $actuel -Rng $Rng -SamePocket)
                }
                if ($remplacant -ne $actuel) {
                    Write-U16 -Data $dataBytes -Offset $bagOffset -Value ([uint16]$remplacant)
                    $bagItemsEdited++
                    $changedTrainer = $true
                }
            }
        }

        $currentTeamSize = [int]$dataBytes[3]
        $recordCount = [int]($partyBytes.Length / $TrainerPokemonRecordSize)
        $bossToSixTarget = $bossTeamsToSixTrainerIds.Contains($trainerId)
        $normalizationTarget = $teamMaxNormalizationTargetMap.ContainsKey($trainerId)
        $isBossTrainer = $bossToSixTarget -or $normalizationTarget
        $trainerMeta = (Get-VanillaTrainerMetadata)[$trainerId]
        $bossCatalogEntry = if ($bossTargetCatalogById.ContainsKey($trainerId)) { $bossTargetCatalogById[$trainerId] } else { $null }
        $bossCatalogNames = if ($bossCatalogEntry) { Get-DynamicPropertyValue -Object $bossCatalogEntry -Name "names" -DefaultValue $null } else { $null }
        $bossCatalogClass = if ($bossCatalogEntry) { Get-DynamicPropertyValue -Object $bossCatalogEntry -Name "trainerClass" -DefaultValue $null } else { $null }
        $bossNameFr = if ($trainerMeta) { [string]$trainerMeta["FrFull"] } else { [string](Get-DynamicPropertyValue -Object $bossCatalogNames -Name "fr" -DefaultValue "") }
        $bossNameEn = if ($trainerMeta) { [string]$trainerMeta["EnFull"] } else { [string](Get-DynamicPropertyValue -Object $bossCatalogNames -Name "en" -DefaultValue "") }
        $bossClassFr = if ($trainerMeta) { [string]$trainerMeta["FrClass"] } else { [string](Get-DynamicPropertyValue -Object $bossCatalogClass -Name "fr" -DefaultValue "") }
        $bossClassEn = if ($trainerMeta) { [string]$trainerMeta["EnClass"] } else { [string](Get-DynamicPropertyValue -Object $bossCatalogClass -Name "en" -DefaultValue "") }
        $addedSlotGymLeagueTypeId = -1
        if ($addedSlotNeedsGymLeagueType) {
            if (Test-IsGymLeagueBossTarget -Entry $trainerMeta) {
                $addedSlotGymLeagueTypeId = Get-GymLeagueTrainerThemeTypeId -Entry $trainerMeta
            }
            if ($addedSlotGymLeagueTypeId -lt 0 -and $bossToSixTarget) {
                $addedSlotGymLeagueTypeId = Get-GymLeagueTrainerThemeTypeIdByTrainerId -TrainerId $trainerId -GameVersionValue $GameVersion
            }
        }
        $addedSlotLeonFallback = [bool]($addedSlotNeedsGymLeagueType -and $addedSlotGymLeagueTypeId -lt 0 -and ($trainerId -eq 149 -or ((@($bossNameEn, $bossNameFr) -join " ") -match "Leon|Tarak")))
        $forceBossToSix = $bossToSixTarget
        $applyTeamMaxNormalization = (([string]$TeamMaxNormalizationMode) -ne "none") -and $normalizationTarget
        # Classe du dresseur, et regles qui en decoulent. Cette classification
        # doit venir AVANT les deux sorties anticipees ci-dessous : « N Pokemon
        # de plus » en depend, et le sauter revenait a rendre l'option inerte.
        $trainerRuleClass = if ($gymLeagueRuleIds.Contains($trainerId)) {
            "boss"
        } elseif ($majorBossRuleIds.Contains($trainerId)) {
            "important"
        } else {
            "regular"
        }
        $trainerRuleApplies = $trainerRulesActive -and (
            ($trainerRuleScope -eq "Everyone") -or
            ($trainerRuleScope -eq "AllBosses" -and $trainerRuleClass -in @("boss", "important")) -or
            ($trainerRuleScope -eq "GymLeague" -and $trainerRuleClass -eq "boss")
        )
        $extraPokemonForClass = switch ($trainerRuleClass) {
            "boss" { $extraPokemonBoss; break }
            "important" { $extraPokemonImportant; break }
            default { $extraPokemonRegular }
        }
        # $hasGlobalTrainerEdits enumere les options qui touchent TOUS les
        # dresseurs, et il oubliait « N Pokemon de plus ». Mesure du 2026-09-07
        # avec +2 sur les trois classes et la portee « tous » : 77 equipes
        # agrandies sur les 318 qui avaient la place. Les 77 etaient les boss,
        # traites par un autre chemin ; tous les autres sortaient ici avant
        # meme qu'on regarde leur equipe.
        if (-not $hasGlobalTrainerEdits -and -not $forceBossToSix -and
            -not $applyTeamMaxNormalization -and $extraPokemonForClass -lt 1) {
            continue
        }
        if ($currentTeamSize -lt 1 -and -not $DoForceAllTeamsToSix -and -not $forceBossToSix -and $TeamMin -lt 1) {
            continue
        }

        $targetTeamSize = if ($DoForceAllTeamsToSix -or $forceBossToSix) { 6 } else { $currentTeamSize }
        # "N Pokemon de plus" : on part de l'equipe d'origine et on plafonne a 6.
        # Un dresseur sans equipe n'en recoit pas, sinon on creerait des combats
        # la ou le jeu n'en prevoit aucun.
        if ($extraPokemonForClass -gt 0 -and $currentTeamSize -gt 0) {
            $withExtra = [Math]::Min(6, $currentTeamSize + $extraPokemonForClass)
            if ($withExtra -gt $targetTeamSize) { $targetTeamSize = $withExtra }
        }
        if ($TeamMin -ge 0 -and $targetTeamSize -lt $TeamMin) { $targetTeamSize = $TeamMin }
        if ($TeamMax -ge 0 -and $targetTeamSize -gt $TeamMax) { $targetTeamSize = $TeamMax }
        if ($targetTeamSize -lt 1) { $targetTeamSize = 1 }
        if ($targetTeamSize -gt 6) { $targetTeamSize = 6 }
        if ($forceBossToSix -and $currentTeamSize -lt 6 -and $targetTeamSize -eq 6) {
            $bossTeamsExpanded++
        }
        $bossTargetEntry = $null
        $bossNormalizationApplied = $false
        $bossNormalizationSlotsChanged = 0
        $bossCapLevel = $null
        $bossLevelsBefore = @()
        $bossLevelsAfter = @()
        if ($isBossTrainer) {
            $normalizationCatalogEntry = if ($normalizationTarget) { $teamMaxNormalizationTargetMap[$trainerId] } else { $null }
            $targetSources = New-Object System.Collections.Generic.List[string]
            if ($forceBossToSix) {
                $targetSources.Add("bossTeamsToSix")
            }
            if ($normalizationCatalogEntry -and $normalizationCatalogEntry.PSObject.Properties.Name -contains "targetSources") {
                foreach ($source in @($normalizationCatalogEntry.targetSources)) {
                    if (-not [string]::IsNullOrWhiteSpace([string]$source) -and -not $targetSources.Contains([string]$source)) {
                        $targetSources.Add([string]$source)
                    }
                }
            } elseif ($applyTeamMaxNormalization) {
                $targetSources.Add([string]$TeamMaxNormalizationMode)
            }
            $bossTargetEntry = [ordered]@{
                trainerId = $trainerId
                files = [ordered]@{
                    trainerData = $trainerDataFile.Name
                    trainerPoke = Split-Path -Leaf $trainerPokeFile
                }
                names = [ordered]@{
                    fr = $bossNameFr
                    en = $bossNameEn
                }
                trainerClass = [ordered]@{
                    fr = $bossClassFr
                    en = $bossClassEn
                }
                teamSize = [ordered]@{
                    before = $currentTeamSize
                    after = $targetTeamSize
                }
                forceBossRuleMatched = $isBossTrainer
                targetSources = @($targetSources.ToArray())
                addedSlotTheme = [ordered]@{
                    mode = [string]$addedSlotSpeciesMode
                    enabled = [bool]($addedSlotNeedsGymLeagueType -and $addedSlotGymLeagueTypeId -ge 0)
                    type = if ($addedSlotGymLeagueTypeId -ge 0) { Get-TypeThemeReportObject -TypeId $addedSlotGymLeagueTypeId } else { $null }
                    leonFallback = $addedSlotLeonFallback
                }
                bossTeamsToSixRequested = [bool]$forceBossToSix
                forcedToSix = [bool]($targetTeamSize -eq 6)
                expanded = [bool]($currentTeamSize -lt 6 -and $targetTeamSize -eq 6)
                teamMaxNormalization = [ordered]@{
                    enabled = [bool]$applyTeamMaxNormalization
                    mode = [string]$TeamMaxNormalizationMode
                    applied = $false
                    capLevel = $null
                    slotsChanged = 0
                    levelsBefore = @()
                    levelsAfter = @()
                }
                strictBossMaxLevelCap = [ordered]@{
                    enabled = [bool]($applyTeamMaxNormalization -and ([string]$TeamMaxNormalizationMode -eq "strictBossMaxLevel"))
                    requested = [bool]($applyTeamMaxNormalization -and ([string]$TeamMaxNormalizationMode -eq "strictBossMaxLevel"))
                    applied = $false
                    capLevel = $null
                    slotsChanged = 0
                    levelsBefore = @()
                    levelsAfter = @()
                }
                storyMajorBattleOrderLevelCap = [ordered]@{
                    enabled = [bool]($applyTeamMaxNormalization -and ([string]$TeamMaxNormalizationMode -eq "storyOrderedMajorBattles"))
                    requested = [bool]($applyTeamMaxNormalization -and ([string]$TeamMaxNormalizationMode -eq "storyOrderedMajorBattles"))
                    applied = $false
                    stageIndex = if ($normalizationCatalogEntry -and $normalizationCatalogEntry.PSObject.Properties.Name -contains "stageIndex") { [int]$normalizationCatalogEntry.stageIndex } else { $null }
                    stageKey = if ($normalizationCatalogEntry -and $normalizationCatalogEntry.PSObject.Properties.Name -contains "stageKey") { [string]$normalizationCatalogEntry.stageKey } else { "" }
                    category = if ($normalizationCatalogEntry -and $normalizationCatalogEntry.PSObject.Properties.Name -contains "category") { [string]$normalizationCatalogEntry.category } else { "" }
                    variantKind = if ($normalizationCatalogEntry -and $normalizationCatalogEntry.PSObject.Properties.Name -contains "variantKind") { [string]$normalizationCatalogEntry.variantKind } else { "" }
                    stageLabel = if ($normalizationCatalogEntry -and $normalizationCatalogEntry.PSObject.Properties.Name -contains "stageLabel") { $normalizationCatalogEntry.stageLabel } else { [ordered]@{ fr = ""; en = "" } }
                    capLevel = $null
                    slotsChanged = 0
                    levelsBefore = @()
                    levelsAfter = @()
                }
            }
            $bossTrainerTargets.Add($bossTargetEntry)
        }

        $templateRecordCount = if ($currentTeamSize -gt 0) { [Math]::Min($currentTeamSize, $recordCount) } else { $recordCount }
        while ($recordCount -lt $targetTeamSize) {
            $templateIndex = if ($templateRecordCount -gt 0) { $Rng.Next(0, $templateRecordCount) } else { -1 }
            $partyBytes = Get-OrCreate-TrainerRecordBytes -Bytes $partyBytes -CurrentCount $recordCount -Index $recordCount -TemplateIndex $templateIndex
            $recordCount++
        }

        $trainerContext = $context
        $themeType = $null
        if ($DoTypeThemedTeams -and $speciesMode -ne "unchanged") {
            $themeType = $Rng.Next(0, 18)
            $themePool = @($context.BaseSpeciesPool | Where-Object {
                $entry = $context.BaseSpeciesEntries[[int]$_]
                $entry -and ($entry.Type1 -eq $themeType -or $entry.Type2 -eq $themeType)
            })
            if ($themePool.Count -gt 0) {
                $trainerContext = @{
                    BaseSpeciesPool = [int[]]$themePool
                    BaseSpeciesEntries = $context.BaseSpeciesEntries
                    SimilarBstCache = @{}
                }
                $trainerTypeThemedTrainers++
            }
        }

        # Application des regles speciales. On ne touche qu'au reservoir
        # d'especes : tout le reste du traitement d'un dresseur est inchange.
        $legendarySlotIndex = -1
        $legendarySlotContext = $null
        if ($trainerRuleApplies) {
            if ($trainerLegendaryPolicy -eq "oneeach") {
                # Exactement un legendaire par equipe : un seul slot tire dans
                # un reservoir de legendaires, les autres restent normaux.
                $legendarySlotContext = Get-TrainerRulePoolContext `
                    -SourcePool $trainerContext.BaseSpeciesPool `
                    -FallbackSourcePool $trainerRuleFallbackPool `
                    -SpeciesEntries $context.BaseSpeciesEntries `
                    -LegendaryPolicy "all" `
                    -MinBaseStatTotal $trainerMinBst
                if ($null -ne $legendarySlotContext -and $targetTeamSize -gt 0) {
                    $legendarySlotIndex = $Rng.Next(0, $targetTeamSize)
                }
                if ($trainerMinBst -gt 0) {
                    $ruleContext = Get-TrainerRulePoolContext `
                        -SourcePool $trainerContext.BaseSpeciesPool `
                        -SpeciesEntries $context.BaseSpeciesEntries `
                        -LegendaryPolicy "unchanged" `
                        -MinBaseStatTotal $trainerMinBst
                    if ($null -ne $ruleContext) { $trainerContext = $ruleContext }
                }
            } else {
                $ruleContext = Get-TrainerRulePoolContext `
                    -SourcePool $trainerContext.BaseSpeciesPool `
                    -FallbackSourcePool $trainerRuleFallbackPool `
                    -SpeciesEntries $context.BaseSpeciesEntries `
                    -LegendaryPolicy $trainerLegendaryPolicy `
                    -MinBaseStatTotal $trainerMinBst
                if ($null -ne $ruleContext) { $trainerContext = $ruleContext }
            }
        }
        $baseTrainerContext = $trainerContext

        # "Types varies" : ignore si le dresseur a deja un theme de type, sinon
        # les deux regles se contrediraient.
        $diverseTypesApplies = $diverseTypesActive -and ($null -eq $themeType) -and (
            ($diverseTypesScope -eq "Everyone") -or
            ($diverseTypesScope -eq "AllBosses" -and $trainerRuleClass -in @("boss", "important")) -or
            ($diverseTypesScope -eq "GymLeague" -and $trainerRuleClass -eq "boss")
        )
        # NE PAS ecrire : $x = if (...) { [HashSet[int]]::new() } else { $null }
        # PowerShell enumere le resultat d'une expression, et une collection
        # VIDE s'enumere en zero element, donc la variable vaut $null. C'est la
        # forme ci-dessous, en deux temps, qui est correcte.
        $usedTrainerTypeIds = $null
        if ($diverseTypesApplies) {
            $usedTrainerTypeIds = [System.Collections.Generic.HashSet[int]]::new()
        }

        $requiredThemeType = if ($null -ne $themeType) { [int]$themeType } else { -1 }
        $shouldKeepTrainerSpeciesUnique = ($preventTrainerDuplicates -and ((($DoForceAllTeamsToSix -or $forceBossToSix) -or $speciesMode -ne "unchanged") -and $targetTeamSize -gt 1))
        $usedExpandedTeamSpeciesIds = $null
        if ($shouldKeepTrainerSpeciesUnique) {
            $usedExpandedTeamSpeciesIds = [System.Collections.Generic.HashSet[int]]::new()
        }
        $usedTrainerItemIds = $null
        if ($preventTrainerDuplicates -and ($itemMode -eq "randomwhenpresent" -or $itemMode -eq "forceall" -or (Test-TrainerModeUsesSmogon $itemMode)) -and $targetTeamSize -gt 1) {
            $usedTrainerItemIds = [System.Collections.Generic.HashSet[int]]::new()
        }

        for ($slot = 0; $slot -lt $targetTeamSize; $slot++) {
            try {
            # Regle "un legendaire chacun" : seul le slot designe pioche dans le
            # reservoir de legendaires. On reaffecte $trainerContext plutot que
            # de toucher aux dizaines d'appels qui l'utilisent ; il est restaure
            # apres la boucle.
            $trainerContext = if ($legendarySlotIndex -ge 0 -and $slot -eq $legendarySlotIndex -and $null -ne $legendarySlotContext) {
                $legendarySlotContext
            } else {
                $baseTrainerContext
            }
            if ($null -ne $usedTrainerTypeIds -and $usedTrainerTypeIds.Count -gt 0) {
                $diverseContext = Get-DiverseTypeContext -Context $trainerContext -UsedTypeIds $usedTrainerTypeIds
                if ($null -ne $diverseContext) {
                    $trainerContext = $diverseContext
                }
            }
            $offset = $slot * $TrainerPokemonRecordSize
            $isSyntheticAddedSlot = $slot -ge $currentTeamSize
            if ($isSyntheticAddedSlot) {
                $syntheticLevel = Get-ApproximateTrainerFillLevel -Rng $Rng -Data $partyBytes -ReferenceTeamSize $currentTeamSize
                $currentSyntheticLevel = [int](Read-U16 -Data $partyBytes -Offset ($offset + 0x0A))
                if ($currentSyntheticLevel -ne $syntheticLevel) {
                    Write-U16 -Data $partyBytes -Offset ($offset + 0x0A) -Value $syntheticLevel
                    $changedTrainer = $true
                }
            }
            $speciesId = Read-U16 -Data $partyBytes -Offset ($offset + 0x0C)
            if ($speciesId -le 0 -or $speciesId -gt $BaseSpeciesMax) {
                $speciesId = Random-FromPool -Rng $Rng -Pool $trainerContext.BaseSpeciesPool
                Write-U16 -Data $partyBytes -Offset ($offset + 0x0C) -Value $speciesId
                Write-U16 -Data $partyBytes -Offset ($offset + 0x0E) -Value 0
                $changedTrainer = $true
            }
            $slotLevel = [int](Read-U16 -Data $partyBytes -Offset ($offset + 0x0A))
            $slotRequiredTypeId = $requiredThemeType

            if ($isSyntheticAddedSlot -and $speciesMode -eq "unchanged") {
                if ($addedSlotNeedsGymLeagueType -and $addedSlotGymLeagueTypeId -ge 0) {
                    $slotRequiredTypeId = [int]$addedSlotGymLeagueTypeId
                }
                $fillSpecies = if ($shouldKeepTrainerSpeciesUnique) {
                    Get-UniqueTrainerSpeciesCandidate `
                        -Rng $Rng `
                        -CurrentSpeciesId $speciesId `
                        -Mode $addedSlotBaseSpeciesMode `
                        -Context $trainerContext `
                        -ExcludedEffectiveSpeciesIds $usedExpandedTeamSpeciesIds `
                        -Level $slotLevel `
                        -DoForceFullyEvolved $DoForceFullyEvolved `
                        -ForceEvolutionLevel $forceEvolutionLevel `
                        -EvolutionTargetsBySpecies $evolutionTargetsBySpecies `
                        -AllowLegendarySpecies $AllowLegendarySpecies `
                        -Data $partyBytes `
                        -TeamSize $targetTeamSize `
                        -IgnoreSlot $slot `
                        -RequiredTypeId $slotRequiredTypeId `
                        -FullContext $context
                } else {
                    Get-TrainerSpeciesReplacement `
                        -Rng $Rng `
                        -CurrentSpeciesId $speciesId `
                        -Mode $addedSlotBaseSpeciesMode `
                        -Context $trainerContext `
                        -Level $slotLevel `
                        -DoForceFullyEvolved $DoForceFullyEvolved `
                        -ForceEvolutionLevel $forceEvolutionLevel `
                        -EvolutionTargetsBySpecies $evolutionTargetsBySpecies `
                        -AllowLegendarySpecies $AllowLegendarySpecies `
                        -RequiredTypeId $slotRequiredTypeId `
                        -FullContext $context
                }
                if ($fillSpecies -ne $speciesId) {
                    Write-U16 -Data $partyBytes -Offset ($offset + 0x0C) -Value $fillSpecies
                    Write-U16 -Data $partyBytes -Offset ($offset + 0x0E) -Value 0
                    $speciesId = $fillSpecies
                    $changedTrainer = $true
                }

                if ($moveMode -eq "unchanged") {
                    $level = Read-U16 -Data $partyBytes -Offset ($offset + 0x0A)
                    if (Set-TrainerMovesFromSpeciesLevel -Data $partyBytes -Offset $offset -LearnsetBytes $learnsetBytes -PersonalEntries $personalEntries -SpeciesId $speciesId -FormId 0 -Level $level -Cache $levelUpMoveCache) {
                        $changedTrainer = $true
                    }
                }
            }

            if ($speciesMode -ne "unchanged") {
                $newSpecies = if ($shouldKeepTrainerSpeciesUnique) {
                    Get-UniqueTrainerSpeciesCandidate `
                        -Rng $Rng `
                        -CurrentSpeciesId $speciesId `
                        -Mode $speciesMode `
                        -Context $trainerContext `
                        -ExcludedEffectiveSpeciesIds $usedExpandedTeamSpeciesIds `
                        -Level $slotLevel `
                        -DoForceFullyEvolved $DoForceFullyEvolved `
                        -ForceEvolutionLevel $forceEvolutionLevel `
                        -EvolutionTargetsBySpecies $evolutionTargetsBySpecies `
                        -AllowLegendarySpecies $AllowLegendarySpecies `
                        -RequiredTypeId $slotRequiredTypeId `
                        -FullContext $context
                } else {
                    Get-TrainerSpeciesReplacement `
                        -Rng $Rng `
                        -CurrentSpeciesId $speciesId `
                        -Mode $speciesMode `
                        -Context $trainerContext `
                        -Level $slotLevel `
                        -DoForceFullyEvolved $DoForceFullyEvolved `
                        -ForceEvolutionLevel $forceEvolutionLevel `
                        -EvolutionTargetsBySpecies $evolutionTargetsBySpecies `
                        -AllowLegendarySpecies $AllowLegendarySpecies `
                        -RequiredTypeId $slotRequiredTypeId `
                        -FullContext $context
                }
                Write-U16 -Data $partyBytes -Offset ($offset + 0x0C) -Value $newSpecies
                Write-U16 -Data $partyBytes -Offset ($offset + 0x0E) -Value 0
                $speciesId = $newSpecies
                $changedTrainer = $true
            }

            if ($LevelMultiplier -ne 1.0) {
                $level = Read-U16 -Data $partyBytes -Offset ($offset + 0x0A)
                $scaled = [int][Math]::Round($level * $LevelMultiplier)
                if ($scaled -lt 1) { $scaled = 1 }
                if ($scaled -gt 100) { $scaled = 100 }
                Write-U16 -Data $partyBytes -Offset ($offset + 0x0A) -Value $scaled
                $slotLevel = $scaled
                $changedTrainer = $true
            }

            if ($DoForceFullyEvolved) {
                $level = $slotLevel
                if ($level -ge $forceEvolutionLevel) {
                    $finalSpecies = Get-FinalEvolutionSpeciesForRequiredType -SpeciesId $speciesId -TargetsBySpecies $evolutionTargetsBySpecies -Rng $Rng -AllowLegendarySpecies $AllowLegendarySpecies -RequiredTypeId $slotRequiredTypeId -Context $context
                    if ($finalSpecies -ne $speciesId) {
                        Write-U16 -Data $partyBytes -Offset ($offset + 0x0C) -Value $finalSpecies
                        Write-U16 -Data $partyBytes -Offset ($offset + 0x0E) -Value 0
                        $speciesId = $finalSpecies
                        $speciesForceEvolved++
                        $changedTrainer = $true
                    }
                }
            }

            if (
                $usesSmogonStrategy -and
                $null -ne $smogonTrainerSpeciesSet -and
                $smogonTrainerSpeciesSet.Count -gt 0 -and
                (-not $smogonTrainerSpeciesSet.Contains([int]$speciesId)) -and
                ($speciesMode -ne "unchanged" -or $isSyntheticAddedSlot)
            ) {
                $smogonReplacementSpecies = if ($shouldKeepTrainerSpeciesUnique) {
                    Get-UniqueTrainerSpeciesCandidate `
                        -Rng $Rng `
                        -CurrentSpeciesId $speciesId `
                        -Mode "Random" `
                        -Context $trainerContext `
                        -ExcludedEffectiveSpeciesIds $usedExpandedTeamSpeciesIds `
                        -Level $slotLevel `
                        -DoForceFullyEvolved $DoForceFullyEvolved `
                        -ForceEvolutionLevel $forceEvolutionLevel `
                        -EvolutionTargetsBySpecies $evolutionTargetsBySpecies `
                        -AllowLegendarySpecies $AllowLegendarySpecies `
                        -RequiredTypeId $slotRequiredTypeId `
                        -FullContext $context
                } else {
                    Get-TrainerSpeciesReplacement `
                        -Rng $Rng `
                        -CurrentSpeciesId $speciesId `
                        -Mode "Random" `
                        -Context $trainerContext `
                        -Level $slotLevel `
                        -DoForceFullyEvolved $DoForceFullyEvolved `
                        -ForceEvolutionLevel $forceEvolutionLevel `
                        -EvolutionTargetsBySpecies $evolutionTargetsBySpecies `
                        -AllowLegendarySpecies $AllowLegendarySpecies `
                        -RequiredTypeId $slotRequiredTypeId `
                        -FullContext $context
                }

                if ($smogonReplacementSpecies -ne $speciesId) {
                    Write-U16 -Data $partyBytes -Offset ($offset + 0x0C) -Value $smogonReplacementSpecies
                    Write-U16 -Data $partyBytes -Offset ($offset + 0x0E) -Value 0
                    $speciesId = $smogonReplacementSpecies
                    $changedTrainer = $true
                }
            }

            if ($shouldKeepTrainerSpeciesUnique) {
                $effectiveSpeciesId = Get-EffectiveTrainerSpeciesId `
                    -SpeciesId $speciesId `
                    -Level $slotLevel `
                    -DoForceFullyEvolved $false `
                    -ForceEvolutionLevel $forceEvolutionLevel `
                    -EvolutionTargetsBySpecies $evolutionTargetsBySpecies `
                    -Rng $Rng `
                    -AllowLegendarySpecies $AllowLegendarySpecies
                $null = $usedExpandedTeamSpeciesIds.Add([int]$effectiveSpeciesId)
            }

            $slotSmogonSet = if ($usesSmogonStrategy) { Get-SmogonStrategicSet -SmogonData $smogonStrategicData -SpeciesId $speciesId -Rng $Rng -PersonalEntries $personalEntries -RequireLegalAbility:(Test-TrainerModeUsesSmogon $abilityMode) } else { $null }

            if ($moveMode -eq "random4") {
                $null = Set-TrainerMovesRandomDistinct -Data $partyBytes -Offset $offset -MovePool $movePool -Rng $Rng
                $changedTrainer = $true
            } elseif ($moveMode -eq "lastlevelup4") {
                $level = Read-U16 -Data $partyBytes -Offset ($offset + 0x0A)
                if (Set-TrainerMovesFromSpeciesLevel -Data $partyBytes -Offset $offset -LearnsetBytes $learnsetBytes -PersonalEntries $personalEntries -SpeciesId $speciesId -FormId 0 -Level $level -Cache $levelUpMoveCache) {
                    $changedTrainer = $true
                }
            } elseif (Test-TrainerModeUsesSmogon $moveMode) {
                $level = Read-U16 -Data $partyBytes -Offset ($offset + 0x0A)
                if (Set-TrainerMovesSmogonStrategic -Data $partyBytes -Offset $offset -SmogonData $smogonStrategicData -StrategicSet $slotSmogonSet -SpeciesId $speciesId -FormId 0 -Level $level -Rng $Rng -FallbackMode $smogonMoveFallbackMode -MovePool $movePool -MovePoolSet $movePoolSet -LearnsetBytes $learnsetBytes -PersonalEntries $personalEntries -Cache $levelUpMoveCache) {
                    $changedTrainer = $true
                }
            }

            switch ($itemMode) {
                "randomwhenpresent" {
                    $currentItem = Read-U16 -Data $partyBytes -Offset ($offset + 0x10)
                    if ($currentItem -gt 0) {
                        $newItem = Get-RandomTrainerHeldItem -Rng $Rng -Pool $itemPool -UsedItemIds $usedTrainerItemIds
                        Write-U16 -Data $partyBytes -Offset ($offset + 0x10) -Value $newItem
                        $changedTrainer = $true
                    }
                }
                "forceall" {
                    $newItem = Get-RandomTrainerHeldItem -Rng $Rng -Pool $itemPool -UsedItemIds $usedTrainerItemIds
                    Write-U16 -Data $partyBytes -Offset ($offset + 0x10) -Value $newItem
                    $changedTrainer = $true
                }
                "removeall" {
                    Write-U16 -Data $partyBytes -Offset ($offset + 0x10) -Value 0
                    $changedTrainer = $true
                }
                { Test-TrainerModeUsesSmogon $_ } {
                    $newItem = Get-SmogonStrategicHeldItem -SmogonData $smogonStrategicData -StrategicSet $slotSmogonSet -SpeciesId $speciesId -Rng $Rng -FallbackPool $itemPool -AllowedItemIds $itemPoolSet -UsedItemIds $usedTrainerItemIds
                    Write-U16 -Data $partyBytes -Offset ($offset + 0x10) -Value $newItem
                    $changedTrainer = $true
                }
            }

            if ($abilityMode -eq "randomslot") {
                Set-TrainerAbilityChoice -Data $partyBytes -Offset $offset -Choice ($Rng.Next(0, 4))
                $changedTrainer = $true
            } elseif (Test-TrainerModeUsesSmogon $abilityMode) {
                $abilityChoice = Get-SmogonStrategicAbilityChoice -SmogonData $smogonStrategicData -StrategicSet $slotSmogonSet -SpeciesId $speciesId -PersonalEntries $personalEntries -Rng $Rng
                if ($null -ne $abilityChoice) {
                    Set-TrainerAbilityChoice -Data $partyBytes -Offset $offset -Choice ([int]$abilityChoice)
                    $changedTrainer = $true
                }
            }

            if ($natureMode -eq "random") {
                $partyBytes[$offset + 0x01] = [byte]$Rng.Next(0, $TrainerNatureMax + 1)
                $changedTrainer = $true
            } elseif (Test-TrainerModeUsesSmogon $natureMode) {
                $null = Set-TrainerNatureSmogonStrategic -Data $partyBytes -Offset $offset -SmogonData $smogonStrategicData -StrategicSet $slotSmogonSet -SpeciesId $speciesId -Rng $Rng
                $changedTrainer = $true
            }

            if ($ivMode -eq "max31") {
                $existingFlags = (Read-U32 -Data $partyBytes -Offset ($offset + 0x1C)) -band 0xC0000000
                Write-U32 -Data $partyBytes -Offset ($offset + 0x1C) -Value ([uint32]($existingFlags -bor 0x3FFFFFFF))
                $changedTrainer = $true
            } elseif ($ivMode -eq "random") {
                $ivValue = (Read-U32 -Data $partyBytes -Offset ($offset + 0x1C)) -band 0xC0000000
                foreach ($shift in 0, 5, 10, 15, 20, 25) {
                    $ivValue = $ivValue -bor ($Rng.Next(0, 32) -shl $shift)
                }
                Write-U32 -Data $partyBytes -Offset ($offset + 0x1C) -Value ([uint32]$ivValue)
                $changedTrainer = $true
            }

            if ($dynamaxLevelMode -eq "max10") {
                if ($partyBytes[$offset + 0x08] -ne 10) {
                    $partyBytes[$offset + 0x08] = 10
                    $dynamaxLevelsEdited++
                    $changedTrainer = $true
                }
            } elseif ($dynamaxLevelMode -eq "random0to10") {
                $partyBytes[$offset + 0x08] = [byte]$Rng.Next(0, 11)
                $dynamaxLevelsEdited++
                $changedTrainer = $true
            }

            if ($shinyChance -gt 0.0) {
                $isShiny = (($Rng.NextDouble() * 100.0) -lt $shinyChance)
                Set-TrainerShinyFlag -Data $partyBytes -Offset $offset -IsShiny $isShiny
                if ($isShiny) {
                    $shiniesForced++
                }
                $changedTrainer = $true
            }

            if ($DoForceCanDynamax) {
                Set-TrainerDynamaxFlag -Data $partyBytes -Offset $offset -CanDynamax $true
                $dynamaxFlagsForced++
                $changedTrainer = $true
            }

            if ($evMode -eq "zero") {
                foreach ($evOffset in 0x02, 0x03, 0x04, 0x05, 0x06, 0x07) {
                    $partyBytes[$offset + $evOffset] = 0
                }
                $changedTrainer = $true
            } elseif ($evMode -eq "randomlegal") {
                $null = Set-TrainerEvsRandomLegal -Data $partyBytes -Offset $offset -Rng $Rng
                $changedTrainer = $true
            } elseif (Test-TrainerModeUsesSmogon $evMode) {
                $null = Set-TrainerEvsSmogonStrategic -Data $partyBytes -Offset $offset -StrategicSet $slotSmogonSet -Rng $Rng
                $changedTrainer = $true
            }

            # Types de l'espece finalement retenue, pour l'emplacement suivant.
            if ($null -ne $usedTrainerTypeIds) {
                $placedSpeciesId = [int](Read-U16 -Data $partyBytes -Offset ($offset + 0x0C))
                $placedEntry = $null
                if ($placedSpeciesId -gt 0) {
                    $placedEntry = $context.BaseSpeciesEntries[$placedSpeciesId]
                }
                if ($placedEntry) {
                    $null = $usedTrainerTypeIds.Add([int]$placedEntry.Type1)
                    $null = $usedTrainerTypeIds.Add([int]$placedEntry.Type2)
                }
            }

            $editedPokemon++
            } catch {
                throw ("Erreur trainer {0} slot {1}: {2}" -f $trainerDataFile.Name, $slot, $_.Exception.Message)
            }
        }

        # La passe de reparation des doublons ci-dessous ne doit pas heriter du
        # reservoir de legendaires du dernier slot traite.
        $trainerContext = $baseTrainerContext

        $teamDuplicateRepairRequiredType = if ($requiredThemeType -ge 0) {
            [int]$requiredThemeType
        } elseif ($addedSlotNeedsGymLeagueType -and $addedSlotGymLeagueTypeId -ge 0) {
            [int]$addedSlotGymLeagueTypeId
        } else {
            -1
        }

        if ($shouldKeepTrainerSpeciesUnique -and $targetTeamSize -gt 1) {
            $finalSeenEffectiveSpeciesIds = [System.Collections.Generic.HashSet[int]]::new()
            for ($slot = 0; $slot -lt $targetTeamSize; $slot++) {
                $offset = $slot * $TrainerPokemonRecordSize
                if (($offset + $TrainerPokemonRecordSize) -gt $partyBytes.Length) {
                    break
                }

                $speciesId = [int](Read-U16 -Data $partyBytes -Offset ($offset + 0x0C))
                if ($speciesId -le 0 -or $speciesId -gt $BaseSpeciesMax) {
                    continue
                }

                $slotLevel = [int](Read-U16 -Data $partyBytes -Offset ($offset + 0x0A))
                $effectiveSpeciesId = Get-EffectiveTrainerSpeciesId `
                    -SpeciesId $speciesId `
                    -Level $slotLevel `
                    -DoForceFullyEvolved $false `
                    -ForceEvolutionLevel $forceEvolutionLevel `
                    -EvolutionTargetsBySpecies $evolutionTargetsBySpecies `
                    -Rng $Rng `
                    -AllowLegendarySpecies $AllowLegendarySpecies

                if ($finalSeenEffectiveSpeciesIds.Contains([int]$effectiveSpeciesId)) {
                    $replacementPool = @()
                    $repairSpeciesMode = if ($speciesMode -eq "unchanged") { $addedSlotBaseSpeciesMode } else { $speciesMode }
                    if ($repairSpeciesMode -eq "similarbst") {
                        $replacementPool = @(Get-SpeciesReplacementPool -CurrentSpeciesId $speciesId -Mode $repairSpeciesMode -Context $trainerContext)
                    } else {
                        $replacementPool = @($trainerContext.BaseSpeciesPool)
                    }
                    if ($teamDuplicateRepairRequiredType -ge 0 -and $replacementPool.Count -gt 0) {
                        $typeSafeReplacementPool = @(Get-TrainerSpeciesPoolMatchingRequiredType `
                            -Pool ([int[]]$replacementPool) `
                            -Level $slotLevel `
                            -RequiredTypeId $teamDuplicateRepairRequiredType `
                            -Context $context `
                            -DoForceFullyEvolved $DoForceFullyEvolved `
                            -ForceEvolutionLevel $forceEvolutionLevel `
                            -EvolutionTargetsBySpecies $evolutionTargetsBySpecies `
                            -AllowLegendarySpecies $AllowLegendarySpecies)
                        if ($typeSafeReplacementPool.Count -gt 0) {
                            $replacementPool = $typeSafeReplacementPool
                        } else {
                            $replacementPool = @()
                        }
                    }

                    $replacementPool = @($replacementPool | Where-Object { -not $finalSeenEffectiveSpeciesIds.Contains([int]$_) })
                    if ($replacementPool.Count -lt 1) {
                        $replacementPool = @($context.BaseSpeciesPool | Where-Object { -not $finalSeenEffectiveSpeciesIds.Contains([int]$_) })
                        if ($teamDuplicateRepairRequiredType -ge 0 -and $replacementPool.Count -gt 0) {
                            $typeSafeFallbackPool = @(Get-TrainerSpeciesPoolMatchingRequiredType `
                                -Pool ([int[]]$replacementPool) `
                                -Level $slotLevel `
                                -RequiredTypeId $teamDuplicateRepairRequiredType `
                                -Context $context `
                                -DoForceFullyEvolved $DoForceFullyEvolved `
                                -ForceEvolutionLevel $forceEvolutionLevel `
                                -EvolutionTargetsBySpecies $evolutionTargetsBySpecies `
                                -AllowLegendarySpecies $AllowLegendarySpecies)
                            if ($typeSafeFallbackPool.Count -gt 0) {
                                $replacementPool = $typeSafeFallbackPool
                            } else {
                                $replacementPool = @()
                            }
                        }
                    }
                    if ($replacementPool.Count -lt 1) {
                        if ($teamDuplicateRepairRequiredType -ge 0) {
                            $typedAnyFallbackPool = @(Get-TrainerSpeciesPoolMatchingRequiredType `
                                -Pool ([int[]]@($context.BaseSpeciesPool)) `
                                -Level $slotLevel `
                                -RequiredTypeId $teamDuplicateRepairRequiredType `
                                -Context $context `
                                -DoForceFullyEvolved $DoForceFullyEvolved `
                                -ForceEvolutionLevel $forceEvolutionLevel `
                                -EvolutionTargetsBySpecies $evolutionTargetsBySpecies `
                                -AllowLegendarySpecies $AllowLegendarySpecies)
                            if ($typedAnyFallbackPool.Count -gt 0) {
                                $replacementPool = $typedAnyFallbackPool
                            }
                        }
                    }
                    if ($replacementPool.Count -lt 1) {
                        $replacementPool = @($context.BaseSpeciesPool)
                    }

                    $replacementSpecies = [int](Random-FromPool -Rng $Rng -Pool ([int[]]$replacementPool))

                    if ($replacementSpecies -ne $speciesId) {
                        Write-U16 -Data $partyBytes -Offset ($offset + 0x0C) -Value $replacementSpecies
                        Write-U16 -Data $partyBytes -Offset ($offset + 0x0E) -Value 0
                        $speciesId = $replacementSpecies
                        $changedTrainer = $true

                        if ($DoForceFullyEvolved -and $slotLevel -ge $forceEvolutionLevel) {
                            $finalSpecies = Get-FinalEvolutionSpeciesForRequiredType -SpeciesId $speciesId -TargetsBySpecies $evolutionTargetsBySpecies -Rng $Rng -AllowLegendarySpecies $AllowLegendarySpecies -RequiredTypeId $teamDuplicateRepairRequiredType -Context $context
                            if ($finalSpecies -ne $speciesId) {
                                Write-U16 -Data $partyBytes -Offset ($offset + 0x0C) -Value $finalSpecies
                                Write-U16 -Data $partyBytes -Offset ($offset + 0x0E) -Value 0
                                $speciesId = $finalSpecies
                                $speciesForceEvolved++
                            }
                        }

                        $repairSmogonSet = if ($usesSmogonStrategy) { Get-SmogonStrategicSet -SmogonData $smogonStrategicData -SpeciesId $speciesId -Rng $Rng -PersonalEntries $personalEntries -RequireLegalAbility:(Test-TrainerModeUsesSmogon $abilityMode) } else { $null }

                        if ($moveMode -eq "lastlevelup4") {
                            $null = Set-TrainerMovesFromSpeciesLevel -Data $partyBytes -Offset $offset -LearnsetBytes $learnsetBytes -PersonalEntries $personalEntries -SpeciesId $speciesId -FormId 0 -Level $slotLevel -Cache $levelUpMoveCache
                        } elseif (Test-TrainerModeUsesSmogon $moveMode) {
                            $null = Set-TrainerMovesSmogonStrategic -Data $partyBytes -Offset $offset -SmogonData $smogonStrategicData -StrategicSet $repairSmogonSet -SpeciesId $speciesId -FormId 0 -Level $slotLevel -Rng $Rng -FallbackMode $smogonMoveFallbackMode -MovePool $movePool -MovePoolSet $movePoolSet -LearnsetBytes $learnsetBytes -PersonalEntries $personalEntries -Cache $levelUpMoveCache
                        }
                        if (Test-TrainerModeUsesSmogon $itemMode) {
                            $repairItem = Get-SmogonStrategicHeldItem -SmogonData $smogonStrategicData -StrategicSet $repairSmogonSet -SpeciesId $speciesId -Rng $Rng -FallbackPool $itemPool -AllowedItemIds $itemPoolSet -UsedItemIds $usedTrainerItemIds
                            Write-U16 -Data $partyBytes -Offset ($offset + 0x10) -Value $repairItem
                        }
                        if (Test-TrainerModeUsesSmogon $abilityMode) {
                            $repairAbilityChoice = Get-SmogonStrategicAbilityChoice -SmogonData $smogonStrategicData -StrategicSet $repairSmogonSet -SpeciesId $speciesId -PersonalEntries $personalEntries -Rng $Rng
                            if ($null -ne $repairAbilityChoice) {
                                Set-TrainerAbilityChoice -Data $partyBytes -Offset $offset -Choice ([int]$repairAbilityChoice)
                            }
                        }
                        if (Test-TrainerModeUsesSmogon $evMode) {
                            $null = Set-TrainerEvsSmogonStrategic -Data $partyBytes -Offset $offset -StrategicSet $repairSmogonSet -Rng $Rng
                        }
                        if (Test-TrainerModeUsesSmogon $natureMode) {
                            $null = Set-TrainerNatureSmogonStrategic -Data $partyBytes -Offset $offset -SmogonData $smogonStrategicData -StrategicSet $repairSmogonSet -SpeciesId $speciesId -Rng $Rng
                        }
                    }

                    $effectiveSpeciesId = Get-EffectiveTrainerSpeciesId `
                        -SpeciesId $speciesId `
                        -Level $slotLevel `
                        -DoForceFullyEvolved $false `
                        -ForceEvolutionLevel $forceEvolutionLevel `
                        -EvolutionTargetsBySpecies $evolutionTargetsBySpecies `
                        -Rng $Rng `
                        -AllowLegendarySpecies $AllowLegendarySpecies
                }

                $null = $finalSeenEffectiveSpeciesIds.Add([int]$effectiveSpeciesId)
            }
        }

        if ($preventTrainerDuplicates -and ($itemMode -eq "randomwhenpresent" -or $itemMode -eq "forceall") -and $targetTeamSize -gt 1 -and (Get-ObjectArrayCount $itemPool) -gt 1) {
            $finalSeenItemIds = [System.Collections.Generic.HashSet[int]]::new()
            for ($slot = 0; $slot -lt $targetTeamSize; $slot++) {
                $offset = $slot * $TrainerPokemonRecordSize
                if (($offset + $TrainerPokemonRecordSize) -gt $partyBytes.Length) {
                    break
                }

                $itemId = [int](Read-U16 -Data $partyBytes -Offset ($offset + 0x10))
                if ($itemId -le 0) {
                    continue
                }

                if ($finalSeenItemIds.Contains($itemId)) {
                    $replacementItemPool = @($itemPool | Where-Object { -not $finalSeenItemIds.Contains([int]$_) })
                    if ($replacementItemPool.Count -gt 0) {
                        $replacementItem = [int](Random-FromPool -Rng $Rng -Pool ([int[]]$replacementItemPool))
                        if ($replacementItem -ne $itemId) {
                            Write-U16 -Data $partyBytes -Offset ($offset + 0x10) -Value $replacementItem
                            $itemId = $replacementItem
                            $changedTrainer = $true
                        }
                    }
                }

                $null = $finalSeenItemIds.Add($itemId)
            }
        }

        if ($recordCount -gt $targetTeamSize) {
            [Array]::Resize([ref]$partyBytes, $targetTeamSize * $TrainerPokemonRecordSize)
            $changedTrainer = $true
        }

        if ($dataBytes[3] -ne $targetTeamSize) {
            $dataBytes[3] = [byte]$targetTeamSize
            $changedTrainer = $true
        }

        if ($applyTeamMaxNormalization -and $targetTeamSize -gt 0) {
            $teamCapLevel = 0
            for ($bossSlot = 0; $bossSlot -lt $targetTeamSize; $bossSlot++) {
                $bossOffset = $bossSlot * $TrainerPokemonRecordSize
                $bossLevel = [int](Read-U16 -Data $partyBytes -Offset ($bossOffset + 0x0A))
                $bossLevelsBefore += $bossLevel
                if ($bossLevel -gt $teamCapLevel) {
                    $teamCapLevel = $bossLevel
                }
            }
            $bossCapLevel = $teamCapLevel
            for ($bossSlot = 0; $bossSlot -lt $targetTeamSize; $bossSlot++) {
                $bossOffset = $bossSlot * $TrainerPokemonRecordSize
                $bossLevel = [int](Read-U16 -Data $partyBytes -Offset ($bossOffset + 0x0A))
                if ($bossLevel -ne $teamCapLevel) {
                    Write-U16 -Data $partyBytes -Offset ($bossOffset + 0x0A) -Value $teamCapLevel
                    $bossNormalizationApplied = $true
                    $bossNormalizationSlotsChanged++
                    $changedTrainer = $true
                }
                $bossLevelsAfter += $teamCapLevel
            }
            if (-not $bossNormalizationApplied) {
                $bossLevelsAfter = @($bossLevelsBefore)
            } else {
                $bossTeamsLevelNormalized++
            }
        }

        if ($bossTargetEntry) {
            $bossTargetEntry["teamSize"]["after"] = $targetTeamSize
            $bossTargetEntry["teamMaxNormalization"] = [ordered]@{
                enabled = [bool]$applyTeamMaxNormalization
                mode = [string]$TeamMaxNormalizationMode
                applied = [bool]$bossNormalizationApplied
                capLevel = $bossCapLevel
                slotsChanged = $bossNormalizationSlotsChanged
                levelsBefore = @($bossLevelsBefore)
                levelsAfter = @($bossLevelsAfter)
            }
            $bossTargetEntry["strictBossMaxLevelCap"] = [ordered]@{
                enabled = [bool]($applyTeamMaxNormalization -and ([string]$TeamMaxNormalizationMode -eq "strictBossMaxLevel"))
                requested = [bool]($applyTeamMaxNormalization -and ([string]$TeamMaxNormalizationMode -eq "strictBossMaxLevel"))
                applied = [bool]$bossNormalizationApplied
                capLevel = $bossCapLevel
                slotsChanged = $bossNormalizationSlotsChanged
                levelsBefore = @($bossLevelsBefore)
                levelsAfter = @($bossLevelsAfter)
            }
            $existingStoryMajorBattleMeta = $bossTargetEntry["storyMajorBattleOrderLevelCap"]
            $bossTargetEntry["storyMajorBattleOrderLevelCap"] = [ordered]@{
                enabled = [bool]($applyTeamMaxNormalization -and ([string]$TeamMaxNormalizationMode -eq "storyOrderedMajorBattles"))
                requested = [bool]($applyTeamMaxNormalization -and ([string]$TeamMaxNormalizationMode -eq "storyOrderedMajorBattles"))
                applied = [bool]$bossNormalizationApplied
                stageIndex = if ($existingStoryMajorBattleMeta) { $existingStoryMajorBattleMeta.stageIndex } else { $null }
                stageKey = if ($existingStoryMajorBattleMeta) { $existingStoryMajorBattleMeta.stageKey } else { "" }
                category = if ($existingStoryMajorBattleMeta) { $existingStoryMajorBattleMeta.category } else { "" }
                variantKind = if ($existingStoryMajorBattleMeta) { $existingStoryMajorBattleMeta.variantKind } else { "" }
                stageLabel = if ($existingStoryMajorBattleMeta) { $existingStoryMajorBattleMeta.stageLabel } else { [ordered]@{ fr = ""; en = "" } }
                capLevel = $bossCapLevel
                slotsChanged = $bossNormalizationSlotsChanged
                levelsBefore = @($bossLevelsBefore)
                levelsAfter = @($bossLevelsAfter)
            }
        }

        if ($changedTrainer) {
            $afterTeamSize = [int]$dataBytes[3]
            $afterRecordCount = [int]($partyBytes.Length / $TrainerPokemonRecordSize)
            $afterAI = if ($dataBytes.Length -ge 0x10) { Read-U32 -Data $dataBytes -Offset 0x0C } else { $null }
            $trainerLevelChanges = New-Object System.Collections.Generic.List[string]
            if ($beforeTeamSize -ne $afterTeamSize) {
                $trainerLevelChanges.Add("teamSize")
            }
            if ($beforeAI -ne $afterAI) {
                $trainerLevelChanges.Add("aiFlags")
            }
            if ($null -ne $themeType) {
                $trainerLevelChanges.Add("typeTheme")
            }
            if ($bossNormalizationApplied) {
                $trainerLevelChanges.Add("bossMaxLevelNormalization")
            }

            $slotChanges = New-Object System.Collections.Generic.List[object]
            $maxSlotCount = [Math]::Max($beforeTeamSize, $afterTeamSize)
            for ($changeSlot = 0; $changeSlot -lt $maxSlotCount; $changeSlot++) {
                $beforeSnapshot = if ($changeSlot -lt $beforeTeamSize -and $changeSlot -lt $beforeRecordCount) { Get-TrainerPokemonSnapshot -Data $beforePartyBytes -Slot $changeSlot } else { $null }
                $afterSnapshot = if ($changeSlot -lt $afterTeamSize -and $changeSlot -lt $afterRecordCount) { Get-TrainerPokemonSnapshot -Data $partyBytes -Slot $changeSlot } else { $null }
                $slotChange = New-TrainerSlotChange -Slot $changeSlot -Before $beforeSnapshot -After $afterSnapshot
                if ($slotChange) {
                    $slotChanges.Add($slotChange)
                }
            }

            $trainerMeta = (Get-VanillaTrainerMetadata)[$trainerId]
            $trainerChangeLog.Add([ordered]@{
                trainerId = $trainerId
                files = [ordered]@{
                    trainerData = $trainerDataFile.Name
                    trainerPoke = Split-Path -Leaf $trainerPokeFile
                }
                names = [ordered]@{
                    fr = if ($trainerMeta) { [string]$trainerMeta["FrFull"] } else { $bossNameFr }
                    en = if ($trainerMeta) { [string]$trainerMeta["EnFull"] } else { $bossNameEn }
                }
                trainerClass = [ordered]@{
                    fr = if ($trainerMeta) { [string]$trainerMeta["FrClass"] } else { $bossClassFr }
                    en = if ($trainerMeta) { [string]$trainerMeta["EnClass"] } else { $bossClassEn }
                }
                changedFields = [string[]]$trainerLevelChanges.ToArray()
                teamSize = [ordered]@{
                    before = $beforeTeamSize
                    after = $afterTeamSize
                }
                recordCount = [ordered]@{
                    before = $beforeRecordCount
                    after = $afterRecordCount
                }
                aiFlags = [ordered]@{
                    before = $beforeAI
                    after = $afterAI
                }
                typeTheme = if ($null -ne $themeType) { [ordered]@{ typeId = $themeType } } else { $null }
                pokemonChanges = [object[]]$slotChanges.ToArray()
            })
            [IO.File]::WriteAllBytes($trainerDataFile.FullName, $dataBytes)
            [IO.File]::WriteAllBytes($trainerPokeFile, $partyBytes)
            $editedTrainers++
        }
    }

    return [pscustomobject]@{
        Trainers = $editedTrainers
        Pokemon = $editedPokemon
        BossTeamsExpanded = $bossTeamsExpanded
        BossTeamsLevelNormalized = $bossTeamsLevelNormalized
        ShiniesForced = $shiniesForced
        SpeciesForceEvolved = $speciesForceEvolved
        TrainerTypeThemedTrainers = $trainerTypeThemedTrainers
        TrainerAIMaxed = $trainerAIMaxed
        BagItemsEdited = $bagItemsEdited
        DynamaxLevelsEdited = $dynamaxLevelsEdited
        DynamaxFlagsForced = $dynamaxFlagsForced
        BossTrainerTargets = [object[]]$bossTrainerTargets.ToArray()
        TrainerChanges = [object[]]$trainerChangeLog.ToArray()
    }
}

function Invoke-EvolutionRandomization {
    param(
        [string]$RomfsRoot,
        [System.Random]$Rng,
        [string]$ModeValue,
        [bool]$AllowLegendarySpecies,
        [bool]$DoNormalizeFriendship,
        [int]$FriendshipLevel,
        [bool]$DoNormalizeTrade,
        [int]$TradeLevel,
        [bool]$DoNormalizeSpecial,
        [int]$SpecialLevel,
        [bool]$DoForceGrowth = $false,
        [bool]$DoSameType = $false,
        [int]$MinBstGain = -1
    )

    $mode = Normalize-Mode $ModeValue
    if (
        $mode -eq "unchanged" -and
        (-not $DoNormalizeFriendship) -and
        (-not $DoNormalizeTrade) -and
        (-not $DoNormalizeSpecial)
    ) {
        return [pscustomobject]@{
            EvolutionsEdited = 0
            FriendshipNormalized = 0
            TradeNormalized = 0
            SpecialNormalized = 0
        }
    }

    $context = $null
    if ($mode -ne "unchanged") {
        $context = @{
            BaseSpeciesPool = Get-BaseSpeciesPool -AllowLegendaries $AllowLegendarySpecies -RomfsRoot $RomfsRoot
            BaseSpeciesEntries = @{}
            SimilarBstCache = @{}
        }
        $entries = Get-PersonalEntries -RomfsRoot $RomfsRoot
        for ($i = 1; $i -le $BaseSpeciesMax; $i++) {
            $context.BaseSpeciesEntries[$i] = $entries[$i]
        }
    }

    $edited = 0
    $friendshipNormalized = 0
    $tradeNormalized = 0
    $specialNormalized = 0
    $friendshipMethods = [System.Collections.Generic.HashSet[int]]::new()
    @(1, 2, 3) | ForEach-Object { $null = $friendshipMethods.Add($_) }
    $tradeMethods = [System.Collections.Generic.HashSet[int]]::new()
    @(5, 6, 7) | ForEach-Object { $null = $tradeMethods.Add($_) }
    $friendshipLevelValue = [Math]::Max(1, [Math]::Min(100, $FriendshipLevel))
    $tradeLevelValue = [Math]::Max(1, [Math]::Min(100, $TradeLevel))
    $specialLevelValue = [Math]::Max(1, [Math]::Min(100, $SpecialLevel))

    # Les fichiers sont nommes evo_NNN.bin, ou NNN est l'espece source : c'est
    # ce qui permet de comparer la cible tiree a la forme de base.
    $evolutionConstraintCache = @{}

    foreach ($file in Get-ChildItem -LiteralPath (Get-EvolutionDir -RomfsRoot $RomfsRoot) -Filter "*.bin" -File) {
        $bytes = [IO.File]::ReadAllBytes($file.FullName)
        $changed = $false

        $sourceSpeciesId = 0
        if ($file.BaseName -match '(\d+)\s*$') {
            $sourceSpeciesId = [int]$Matches[1]
        }
        $evolutionContext = $context
        if ($null -ne $context -and $sourceSpeciesId -gt 0 -and ($DoForceGrowth -or $DoSameType -or $MinBstGain -ge 0)) {
            $evolutionContext = Get-EvolutionConstrainedContext `
                -Context $context `
                -SourceSpeciesId $sourceSpeciesId `
                -ForceGrowth $DoForceGrowth `
                -SameType $DoSameType `
                -MinBstGain $MinBstGain `
                -Cache $evolutionConstraintCache
        }

        for ($slot = 0; $slot -lt $EvolutionRecordsPerSpecies; $slot++) {
            $slotOffset = $slot * $EvolutionRecordSize
            $method = Read-U16 -Data $bytes -Offset $slotOffset
            $targetSpecies = Read-U16 -Data $bytes -Offset ($slotOffset + 4)
            if ($method -eq 0 -or $targetSpecies -le 0 -or $targetSpecies -gt $BaseSpeciesMax) {
                continue
            }

            if ($DoNormalizeFriendship -and $friendshipMethods.Contains($method)) {
                Write-U16 -Data $bytes -Offset $slotOffset -Value 4
                Write-U16 -Data $bytes -Offset ($slotOffset + 2) -Value 0
                Write-U16 -Data $bytes -Offset ($slotOffset + 6) -Value ($friendshipLevelValue -shl 8)
                $changed = $true
                $friendshipNormalized++
            } elseif ($DoNormalizeTrade -and $tradeMethods.Contains($method)) {
                Write-U16 -Data $bytes -Offset $slotOffset -Value 4
                Write-U16 -Data $bytes -Offset ($slotOffset + 2) -Value 0
                Write-U16 -Data $bytes -Offset ($slotOffset + 6) -Value ($tradeLevelValue -shl 8)
                $changed = $true
                $tradeNormalized++
            } elseif ($DoNormalizeSpecial -and $method -ne 4) {
                Write-U16 -Data $bytes -Offset $slotOffset -Value 4
                Write-U16 -Data $bytes -Offset ($slotOffset + 2) -Value 0
                Write-U16 -Data $bytes -Offset ($slotOffset + 6) -Value ($specialLevelValue -shl 8)
                $changed = $true
                $specialNormalized++
            }

            if ($mode -ne "unchanged") {
                $replacement = Get-SpeciesReplacement -Rng $Rng -CurrentSpeciesId $targetSpecies -Mode $mode -Context $evolutionContext
                if ($replacement -ne $targetSpecies) {
                    Write-U16 -Data $bytes -Offset ($slotOffset + 4) -Value $replacement
                    $changed = $true
                    $edited++
                }
            }
        }

        if ($changed) {
            [IO.File]::WriteAllBytes($file.FullName, $bytes)
        }
    }

    return [pscustomobject]@{
        EvolutionsEdited = $edited
        FriendshipNormalized = $friendshipNormalized
        TradeNormalized = $tradeNormalized
        SpecialNormalized = $specialNormalized
    }
}

function Write-RandomizationReport {
    param(
        [pscustomobject]$Result,
        [string]$OutputRomfsRoot
    )

    if (-not $ExportJsonReport) {
        return $null
    }

    $reportLang = if (([string]$ReportLanguage).ToLowerInvariant() -eq "en") { "en" } else { "fr" }
    $configuredStarterIds = Get-ConfiguredStarterSpeciesIds
    $starterIdList = New-Object System.Collections.Generic.List[int]
    $configuredStarterIdList = New-Object System.Collections.Generic.List[int]
    foreach ($starterId in @($configuredStarterIds)) {
        if ($starterId) {
            $configuredStarterIdList.Add([int]$starterId)
        }
    }
    if ($Result.PSObject.Properties.Name -contains "StarterSpeciesIds") {
        foreach ($starterId in @($Result.StarterSpeciesIds)) {
            if ($starterId) {
                $starterIdList.Add([int]$starterId)
            }
        }
    }
    if ($starterIdList.Count -eq 0) {
        foreach ($starterId in $configuredStarterIdList.ToArray()) {
            $starterIdList.Add([int]$starterId)
        }
    }
    $starterIds = [int[]]$starterIdList.ToArray()
    $hasStarterIds = $starterIdList.Count -gt 0
    $hasConfiguredStarterIds = $configuredStarterIdList.Count -gt 0
    $starterModeReport = if ($hasConfiguredStarterIds) { "Custom" } else { $StarterMode }
    $starterSummary = @()
    if ($hasStarterIds) {
        foreach ($starterId in $starterIds) {
            $starterSummary += [pscustomobject]@{
                id = $starterId
                fr = Get-SpeciesDisplayName -SpeciesId $starterId -Language "fr"
                en = Get-SpeciesDisplayName -SpeciesId $starterId -Language "en"
            }
        }
    }

    $sourceGameVersion = Get-SourceGameVersion -RomfsRoot $SourceRomfs
    $bossTargetCatalog = Convert-ToObjectArray (Get-BossTrainerTargetCatalog -GameVersionValue $sourceGameVersion)
    $bossTeamsToSixConfiguredCatalog = Convert-ToObjectArray (Get-BossTrainerTargetCatalog -Scope $BossTeamsToSixScope -GameVersionValue $sourceGameVersion)
    $storyMajorBattleTargetCatalog = if ([bool]$StoryMajorBattleOrderLevelCap) { Get-StoryMajorBattleTargetCatalog -SourceRomfsRoot $SourceRomfs } else { @() }
    $bossAppliedTargets = Convert-ToObjectArray $Result.BossTrainerTargets
    $bossTeamsToSixAppliedTargets = Convert-ToObjectArray ($bossAppliedTargets | Where-Object { [bool]$_.bossTeamsToSixRequested })
    $strictBossCapAppliedTargets = Convert-ToObjectArray ($bossAppliedTargets | Where-Object { $_.strictBossMaxLevelCap -and [bool]$_.strictBossMaxLevelCap.enabled })
    $storyMajorBattleAppliedTargets = Convert-ToObjectArray ($bossAppliedTargets | Where-Object { $_.storyMajorBattleOrderLevelCap -and [bool]$_.storyMajorBattleOrderLevelCap.enabled })
    $mainStorySoftCaps = Convert-ToObjectArray $Result.MainStorySoftCaps
    $storyGymLeagueCaps = Convert-ToObjectArray $Result.StoryGymLeagueCaps
    $storyMajorBattleCaps = Convert-ToObjectArray $Result.StoryMajorBattleCaps
    $storyGymLeagueExpCapPatches = Convert-ToObjectArray $Result.StoryGymLeagueExpCapPatches
    $selectedExpLevelCapMode = [string](Get-SelectedExpLevelCapMode)
    $effectiveReceiverLevelExpCap = $selectedExpLevelCapMode -in @("receiverVsDefeatedPokemon", "strictBossMaxLevel", "storyOrderedMajorBattles")
    $effectiveMainStorySoftLevelCap = $selectedExpLevelCapMode -eq "storyMainProgressionSoft"
    $effectiveStoryGymLeagueExpCap = $selectedExpLevelCapMode -eq "storyGymLeague"
    $expLevelCapRequiresExLaunch = [bool]$Result.ExpLevelCapRequiresExLaunch
    $effectiveStoryMajorBattleOrderLevelCap = $selectedExpLevelCapMode -eq "storyOrderedMajorBattles"
    $effectiveAnyExpLevelCap = $selectedExpLevelCapMode -ne "none"
    $effectiveStrictBossMaxLevelCap = $selectedExpLevelCapMode -eq "strictBossMaxLevel"
    $bossCapEnforcementMode = Get-BossLevelCapEnforcementMode
    $dynamicExpCapNotesFr = "Le cap EXP dynamique n'est plus généré en IPS brut: le hook fiable passe par ExLaunch au point final du calcul EXP. Le multiplicateur EXP runtime et l'état EXP Share passent aussi par ExLaunch."
    $dynamicExpCapNotesEn = "Dynamic EXP cap is no longer emitted as a raw IPS patch: the reliable hook goes through ExLaunch at the final EXP calculation point. Runtime EXP multiplier and EXP Share state also go through ExLaunch."
    if ($effectiveStoryMajorBattleOrderLevelCap) {
        $dynamicExpCapNotesFr += " Avec le mode ordre histoire principale, le randomizer uniformise une liste ordonnée de gros combats (arènes, Nabil, Travis, Rosemary, Liv, Shehroz, Tarak) sur leur niveau max, mais le blocage EXP demande ExLaunch."
        $dynamicExpCapNotesEn += " With the ordered main-story mode, the randomizer normalizes an ordered list of major battles (gyms, Hop, Bede, Marnie, Oleana, Rose, Leon) to their max level, but EXP enforcement requires ExLaunch."
    } elseif ($effectiveStrictBossMaxLevelCap) {
        $dynamicExpCapNotesFr += " Avec l'option boss max strict, l'outil aligne chaque équipe boss listée sur son niveau max; le blocage EXP strict demande ExLaunch."
        $dynamicExpCapNotesEn += " With the strict boss max option, the tool normalizes each listed boss team to its highest level; strict EXP enforcement requires ExLaunch."
    }
    $mainStorySoftCapNotesFr = "Mode progression principale souple: calcule une table de 9 caps basée sur les badges, mais chaque palier prend le niveau max des gros combats de progression du même bloc. Les arènes restent l'ossature et les vrais boss antagonistes / fin d'histoire sont ajoutés quand ils tombent dans le même palier, pour reduire l'overlevel sans micro-caps trop frequents."
    $mainStorySoftCapNotesEn = "Soft main-story progression mode: computes a 9-step badge-based cap table, but each milestone takes the max level from the major progression fights in the same block. Gyms remain the backbone and the real villain / endgame bosses are folded in when they land in the same milestone, reducing overleveling without overly frequent micro-caps."
    $storyGymLeagueCapNotesFr = "Mode histoire arènes/champion: les 9 caps sont calculés après randomisation depuis les vraies équipes générées. L'application en jeu demande maintenant le module ExLaunch, pas un IPS brut."
    $storyGymLeagueCapNotesEn = "Gym/champion story mode: the 9 caps are computed after randomization from the actual generated teams. In-game enforcement now requires the ExLaunch module, not a raw IPS patch."
    $storyMajorBattleCapNotesFr = "Mode ordre histoire principale: l'outil prend une liste ordonnee des gros combats de l'histoire principale (arenes, Nabil, Travis, Rosemary, Liv, Shehroz, Tarak). Chaque equipe de cette liste est uniformisee sur son niveau max apres randomisation et exportee dans story-major-battle-caps.json. Le blocage EXP en jeu demande ExLaunch."
    $storyMajorBattleCapNotesEn = "Ordered main-story mode: the tool uses an ordered list of major main-story battles (gyms, Hop, Bede, Marnie, Oleana, Rose, Leon). Each listed team is normalized to its max level after randomization and exported to story-major-battle-caps.json. In-game EXP enforcement requires ExLaunch."
    $bossLevelCapNotesFr = if ($effectiveMainStorySoftLevelCap) {
        "Le JSON liste toujours les caps boss calculés depuis le niveau max des équipes boss après randomisation, mais le cap applique en jeu vient du mode progression principale souple. Ce mode utilise toujours 9 paliers par badge, enrichis avec les vrais boss antagonistes / fin d'histoire du même bloc."
    } elseif ($effectiveStoryGymLeagueExpCap) {
        "Le JSON liste toujours les caps boss calculés depuis le niveau max des équipes boss après randomisation, mais le cap applique en jeu vient du mode histoire arènes/champion. Ce mode lit 9 caps de progression bases sur le nombre de badges: arène 1 a 8 puis Tarak."
    } elseif ($effectiveStoryMajorBattleOrderLevelCap) {
        "Le JSON liste les caps calcules depuis le niveau max des boss apres randomisation. Avec le mode ordre histoire principale, le patch EXP dynamique reste global et les gros combats listes dans story-major-battle-caps.json sont aussi uniformises sur leur niveau max pour rendre leurs caps stricts."
    } elseif ($effectiveStrictBossMaxLevelCap) {
        "Le JSON liste les caps calculés depuis le niveau max des boss après randomisation. Le mode strict boss max active aussi le patch EXP dynamique puis aligne tous les Pokémon des boss listes sur le niveau max de leur équipe: pendant ces combats, le cap se comporte donc comme un vrai plafond boss max level. Ce n'est toujours pas un suivi de progression par badge."
    } elseif ($effectiveReceiverLevelExpCap) {
        "Le JSON liste les caps calculés depuis le niveau max des boss après randomisation. Avec le levelcap EXP dynamique actif, le jeu bloque a 1 EXP quand le Pokémon receveur est au niveau du Pokémon adverse vaincu ou au-dessus. Ce n'est pas un suivi de progression par badge: c'est un cap dynamique par Pokémon adverse battu."
    } elseif ($expLevelCapRequiresExLaunch) {
        "Le JSON liste les caps calcules. Le cap EXP en jeu passe maintenant par ExLaunch: il faut que main.npdm/subsdk9 soient presents dans exefs et que sdmc/config/swsh-mods-exl/config.toml contienne les caps generes. Le vieux patch IPS brut a ete retire car il ecrasait du code vivant."
    } else {
        "Le JSON liste les caps calculés depuis le niveau max des boss après randomisation. Sans patch ExeFS actif, ce fichier reste une référence des caps boss."
    }
    $bossLevelCapNotesEn = if ($effectiveMainStorySoftLevelCap) {
        "This JSON still lists boss caps computed from max team level after randomization, but the in-game cap now comes from soft main-story progression mode. That mode still uses 9 badge-count milestones, enriched with the real villain / endgame bosses that land in the same block."
    } elseif ($effectiveStoryGymLeagueExpCap) {
        "This JSON still lists boss caps computed from max team level after randomization, but the cap applied in game now comes from the gym/champion story mode. That mode uses 9 progression caps based on badge count: Gym 1 through Gym 8, then Leon."
    } elseif ($effectiveStoryMajorBattleOrderLevelCap) {
        "This JSON lists caps computed from each boss team's max level after randomization. With the ordered main-story mode, the dynamic EXP patch remains global and the major battles listed in story-major-battle-caps.json are also normalized to that max level so those fights behave like strict caps."
    } elseif ($effectiveStrictBossMaxLevelCap) {
        "The JSON lists caps computed from each boss team's max level after randomization. Strict boss max mode also enables the dynamic EXP patch and normalizes every listed boss Pokemon to that team's max level, so those fights behave like a real strict boss max-level cap. This is still not badge/story progression tracking."
    } elseif ($effectiveReceiverLevelExpCap) {
        "The JSON lists caps computed from each boss team's max level after randomization. With the dynamic EXP level cap enabled, the game clamps EXP to 1 when the receiver Pokemon is at or above the defeated opponent Pokemon's level. This is not badge/story progress tracking: it is a dynamic cap per defeated opponent Pokemon."
    } elseif ($expLevelCapRequiresExLaunch) {
        "The JSON lists computed caps. In-game EXP enforcement now goes through ExLaunch: main.npdm/subsdk9 must be present in exefs and sdmc/config/swsh-mods-exl/config.toml must contain the generated caps. The old raw IPS patch was removed because it overwrote live code."
    } else {
        "The JSON lists caps computed from each boss team's max level after randomization. Without an active ExeFS patch, this file remains a boss-cap reference only."
    }
    $starterPatchChanges = Convert-ToObjectArray $Result.StarterRelatedTrainerPatchChanges

    $report = [ordered]@{
        version = $AppVersion
        generatedAt = [DateTime]::UtcNow.ToString("o")
        reportLanguage = $reportLang
        sourceRomfs = $SourceRomfs
        sourceExefs = if ($Result.PSObject.Properties.Name -contains "SourceExefsRoot") { $Result.SourceExefsRoot } else { "" }
        outputPackage = if ($Result.PSObject.Properties.Name -contains "OutputPackageRoot") { $Result.OutputPackageRoot } else { Get-OutputPackageRoot -OutputRomfsRoot $OutputRomfsRoot }
        outputRomfs = $OutputRomfsRoot
        sourceGameVersion = $sourceGameVersion
        seed = $Result.Seed
        bstExplanation = @{
            fr = "BST = Base Stat Total, la somme des 6 stats de base d'un Pokémon."
            en = "BST = Base Stat Total, the sum of a Pokemon's 6 base stats."
        }
        options = [ordered]@{
            autoInstallToEmulators = [bool]$AutoInstallToEden
            installToRyujinx = [bool]$InstallToRyujinx
            modInstallName = Get-NormalizedModName -ModName $EdenModName
            trainerSpeciesMode = $TrainerSpeciesMode
            trainerMoveMode = $TrainerMoveMode
            trainerSmogonMoveFallbackMode = $TrainerSmogonMoveFallbackMode
            trainerItemMode = $TrainerItemMode
            trainerItemPoolMode = $TrainerItemPoolMode
            trainerAddedSlotSpeciesMode = $TrainerAddedSlotSpeciesMode
            trainerDuplicateMode = $TrainerDuplicateMode
            trainerBagItemMode = $TrainerBagItemMode
            trainerAbilityMode = $TrainerAbilityMode
            trainerIVMode = $TrainerIVMode
            trainerEVMode = $TrainerEVMode
            trainerNatureMode = Get-EffectiveTrainerNatureMode -Mode $TrainerNatureMode -LegacyRandomize $RandomizeTrainerNatures.IsPresent
            randomizeTrainerNatures = [bool]$RandomizeTrainerNatures
            trainerLevelMultiplier = $TrainerLevelMultiplier
            trainerTeamMin = $TrainerTeamMin
            trainerTeamMax = $TrainerTeamMax
            trainerTypeThemed = [bool]$TrainerTypeThemed
            trainerShinyChancePercent = $TrainerShinyChancePercent
            forceTrainerFullyEvolved = [bool]$ForceTrainerFullyEvolved
            trainerFullyEvolvedLevel = $TrainerFullyEvolvedLevel
            maxTrainerAI = [bool]$MaxTrainerAI
            trainerDynamaxLevelMode = $TrainerDynamaxLevelMode
            forceTrainerCanDynamax = [bool]$ForceTrainerCanDynamax
            forceAllTeamsToSix = [bool]$ForceAllTeamsToSix
            forceBossTeamsToSix = [bool]$ForceBossTeamsToSix
            bossTeamsToSixScope = (Normalize-BossTeamsToSixScope -Scope $BossTeamsToSixScope)
            allowLegendaryTrainers = [bool]$AllowLegendaryTrainers
            typeMode = $TypeMode
            typesMonotypeOnly = [bool]$TypesMonotypeOnly
            abilityMode = $AbilityMode
            allowWonderGuard = [bool]$AllowWonderGuard
            statMode = $StatMode
            expYieldMultiplier = $ExpYieldMultiplier
            forceOneExpYield = [bool]$ForceOneExpYield
            runtimePcControls = [bool]$RuntimePcControls
            randomizeMoveTypes = [bool]$RandomizeMoveTypes
            randomizeMovePower = [bool]$RandomizeMovePower
            movePowerMin = $MovePowerMin
            movePowerMax = $MovePowerMax
            randomizeMovePP = [bool]$RandomizeMovePP
            movePPMin = $MovePPMin
            movePPMax = $MovePPMax
            randomizeMoveAccuracy = [bool]$RandomizeMoveAccuracy
            moveAccuracyMin = $MoveAccuracyMin
            moveAccuracyMax = $MoveAccuracyMax
            randomizeMoveCategory = [bool]$RandomizeMoveCategory
            randomizePickupItems = [bool]$RandomizePickupItems
            randomizeShopItems = [bool]$RandomizeShopItems
            randomizeTechnicalRecords = [bool]$RandomizeTechnicalRecords
            shopItemMode = $ShopItemMode
            shopPriceMode = Get-ShopPriceModeValue
            shopPriceMultiplier = Get-ShopPriceMultiplierValue
            shopPriceMin = (Get-ShopPriceBounds).Min
            shopPriceMax = (Get-ShopPriceBounds).Max
            overworldModelSafeEncounters = [bool]$OverworldModelSafeEncounters
            writeInstallationPackage = [bool]$WriteInstallationPackage
            strictDataFiles = [bool]$StrictDataFiles
            evolutionMode = $EvolutionMode
            allowLegendaryEvolutions = [bool]$AllowLegendaryEvolutions
            normalizeFriendshipEvolutions = [bool]$NormalizeFriendshipEvolutions
            friendshipEvolutionLevel = $FriendshipEvolutionLevel
            normalizeTradeEvolutions = [bool]$NormalizeTradeEvolutions
            tradeEvolutionLevel = $TradeEvolutionLevel
            normalizeSpecialEvolutions = [bool]$NormalizeSpecialEvolutions
            specialEvolutionLevel = $SpecialEvolutionLevel
            giftMode = $GiftMode
            starterMode = $starterModeReport
            configuredStarters = $starterSummary
            finalStarterSpecies = $starterSummary
            patchStarterRelatedTrainers = [bool]$PatchStarterRelatedTrainers
            allowLegendaryGifts = [bool]$AllowLegendaryGifts
            tradeMode = $TradeMode
            allowLegendaryTrades = [bool]$AllowLegendaryTrades
            staticEncounterMode = $StaticEncounterMode
            allowLegendaryStaticEncounters = [bool]$AllowLegendaryStaticEncounters
            staticEncounterStableMapping = $StaticEncounterStableMapping
            grassEncounterMode = $GrassEncounterMode
            allowLegendaryGrassEncounters = [bool]$AllowLegendaryGrassEncounters
            grassEncounterStableMapping = $GrassEncounterStableMapping
            effectiveGrassEncounterStableMapping = (Get-EffectiveGrassEncounterStableMapping)
            visibleEncounterBehavior = (Get-NormalizedVisibleEncounterBehavior -Value $VisibleEncounterBehavior)
            encounterDrawMode = (Get-NormalizedEncounterDrawMode -Value $EncounterDrawMode -LegacyVisibleBehavior $VisibleEncounterBehavior)
            liveEncounterRandomizerMode = (Get-LiveEncounterRandomizerMode)
            liveEncounterVisibleBehavior = (Get-LiveEncounterVisibleBehaviorValue)
            liveEncounterDrawMode = (Get-LiveEncounterDrawModeValue)
            undergroundMode = $UndergroundMode
            allowLegendaryUnderground = [bool]$AllowLegendaryUnderground
            disableExpShare = [bool]$DisableExpShare
            earlyBike = [bool]$EarlyBike
            dynamicExpLevelCap = [bool]$DynamicExpLevelCap
            strictBossMaxLevelCap = [bool]$StrictBossMaxLevelCap
            mainStorySoftLevelCap = [bool]$MainStorySoftLevelCap
            gymLeagueStoryLevelCap = [bool]$GymLeagueStoryLevelCap
            storyMajorBattleOrderLevelCap = [bool]$StoryMajorBattleOrderLevelCap
            effectiveDynamicExpLevelCap = $effectiveReceiverLevelExpCap
            effectiveAnyExpLevelCap = $effectiveAnyExpLevelCap
            effectiveExpLevelCapMode = Get-SelectedExpLevelCapMode
            expLevelCapRequiresExLaunch = $expLevelCapRequiresExLaunch
            exportEncounterZoneReport = [bool]$ExportEncounterZoneReport
        }
        counts = [ordered]@{
            personalEntriesEdited = $Result.PersonalEntriesEdited
            expYieldsEdited = $Result.ExpYieldsEdited
            movesEdited = $Result.MovesEdited
            moveTypesEdited = $Result.MoveTypesEdited
            movePowersEdited = $Result.MovePowersEdited
            movePPEdited = $Result.MovePPEdited
            moveAccuracyEdited = $Result.MoveAccuracyEdited
            moveCategoriesEdited = $Result.MoveCategoriesEdited
            pickupItemsEdited = $Result.PickupItemsEdited
            shopItemsEdited = $Result.ShopItemsEdited
            technicalRecordsEdited = $Result.TechnicalRecordsEdited
            itemChangesLogged = $Result.ItemChangesLogged
            trainersEdited = $Result.TrainersEdited
            trainerPokemonProcessed = $Result.TrainerPokemonProcessed
            bossTeamsExpanded = $Result.BossTeamsExpanded
            bossTeamsLevelNormalized = $Result.BossTeamsLevelNormalized
            trainerShiniesForced = $Result.TrainerShiniesForced
            trainerSpeciesForceEvolved = $Result.TrainerSpeciesForceEvolved
            trainerTypeThemedTrainers = $Result.TrainerTypeThemedTrainers
            trainerAIMaxed = $Result.TrainerAIMaxed
            trainerBagItemsEdited = $Result.TrainerBagItemsEdited
            trainerDynamaxLevelsEdited = $Result.TrainerDynamaxLevelsEdited
            trainerDynamaxFlagsForced = $Result.TrainerDynamaxFlagsForced
            trainerChangesLogged = $Result.TrainerChangesLogged
            bossTrainerTargetsLogged = Get-ObjectArrayCount $bossAppliedTargets
            evolutionsEdited = $Result.EvolutionsEdited
            friendshipEvolutionsNormalized = $Result.FriendshipEvolutionsNormalized
            tradeEvolutionsNormalized = $Result.TradeEvolutionsNormalized
            specialEvolutionsNormalized = $Result.SpecialEvolutionsNormalized
            giftsEdited = $Result.GiftsEdited
            startersEdited = $Result.StartersEdited
            starterRelatedTrainerFilesEdited = $Result.StarterRelatedTrainerFilesEdited
            starterRelatedTrainerSlotsEdited = $Result.StarterRelatedTrainerSlotsEdited
            tradeSpeciesSlotsEdited = $Result.TradeSpeciesSlotsEdited
            staticEncountersEdited = $Result.StaticEncountersEdited
            grassEncounterSlotsEdited = $Result.GrassEncounterSlotsEdited
            undergroundSpeciesSlotsEdited = $Result.UndergroundSpeciesSlotsEdited
            wildChangesLogged = $Result.WildChangesLogged
            bossLevelCapsLogged = $Result.BossLevelCapsLogged
            mainStorySoftCapsLogged = $Result.MainStorySoftCapsLogged
            storyGymLeagueCapsLogged = $Result.StoryGymLeagueCapsLogged
            storyMajorBattleCapsLogged = $Result.StoryMajorBattleCapsLogged
            exefsPatchFilesWritten = $Result.ExeFsPatchFilesWritten
            disableExpSharePatchFilesWritten = $Result.DisableExpSharePatchFilesWritten
            dynamicExpLevelCapPatchFilesWritten = $Result.DynamicExpLevelCapPatchFilesWritten
            storyGymLeagueExpCapPatchFilesWritten = $Result.StoryGymLeagueExpCapPatchFilesWritten
            expLevelCapRequiresExLaunch = $Result.ExpLevelCapRequiresExLaunch
            expLevelCapExLaunchConfigPath = $Result.ExpLevelCapExLaunchConfigPath
            exLaunchModuleRequested = $Result.ExLaunchModuleRequested
            exLaunchModuleAvailable = $Result.ExLaunchModuleAvailable
            exLaunchModuleDeployed = $Result.ExLaunchModuleDeployed
            installationTargetsPrepared = @(Convert-ToObjectArray $Result.InstallationTargets).Length
            autoInstallRequested = $Result.AutoInstallRequested
            autoInstallSuccessCount = $Result.AutoInstallSuccessCount
            autoInstallFailureCount = $Result.AutoInstallFailureCount
            edenAutoInstallRequested = $Result.EdenAutoInstallRequested
            edenAutoInstallCompleted = $Result.EdenAutoInstallCompleted
        }
        exefsPatches = [ordered]@{
            enabled = $Result.ExeFsPatchEnabled
            patchRoot = $Result.ExeFsPatchRoot
            filesWritten = $Result.ExeFsPatchFilesWritten
            notes = [ordered]@{
                fr = "Les anciens IPS ExeFS générés par cet outil sont nettoyes. Le cap EXP, le multiplicateur EXP runtime et l'état EXP Share demandent maintenant le module ExLaunch."
                en = "Old ExeFS IPS files generated by this tool are cleaned up. EXP caps, runtime EXP multiplier, and EXP Share state now require the ExLaunch module."
            }
            all = @($Result.ExeFsPatches)
            disableExpShare = [ordered]@{
                enabled = $Result.DisableExpSharePatchEnabled
                patchRoot = $Result.DisableExpSharePatchRoot
                filesWritten = $Result.DisableExpSharePatchFilesWritten
                notes = [ordered]@{
                    fr = "L'EXP Share est controlee par le module ExLaunch via la config [exp_share]. Aucun IPS brut n'est emis; les anciens IPS de cette feature sont supprimes."
                    en = "EXP Share is controlled by the ExLaunch module through the [exp_share] config. No raw IPS is emitted; old IPS files for this feature are removed."
                }
                patches = @($Result.DisableExpSharePatches)
            }
            dynamicExpLevelCap = [ordered]@{
                enabled = $effectiveReceiverLevelExpCap
                patchRoot = $Result.DynamicExpLevelCapPatchRoot
                filesWritten = $Result.DynamicExpLevelCapPatchFilesWritten
                enforcementMode = "receiverLevelVsDefeatedPokemonLevel"
                requiresExLaunch = $Result.ExpLevelCapRequiresExLaunch
                exLaunchConfigPath = $Result.ExpLevelCapExLaunchConfigPath
                requestedDirectly = [bool]$DynamicExpLevelCap
                requiredByStrictBossMaxLevelCap = $effectiveStrictBossMaxLevelCap
                requiredByStoryMajorBattleOrderLevelCap = $effectiveStoryMajorBattleOrderLevelCap
                overriddenByMainStorySoftLevelCap = [bool]$MainStorySoftLevelCap
                overriddenByGymLeagueStoryLevelCap = ([bool]$GymLeagueStoryLevelCap -and (-not $effectiveMainStorySoftLevelCap))
                notes = [ordered]@{
                    fr = $dynamicExpCapNotesFr
                    en = $dynamicExpCapNotesEn
                }
                patches = @($Result.DynamicExpLevelCapPatches)
            }
            storyGymLeagueExpCap = [ordered]@{
                enabled = ($effectiveStoryGymLeagueExpCap -or $effectiveMainStorySoftLevelCap)
                patchRoot = $Result.StoryGymLeagueExpCapPatchRoot
                filesWritten = $Result.StoryGymLeagueExpCapPatchFilesWritten
                enforcementMode = if ($effectiveMainStorySoftLevelCap) { "mainStoryProgressionSoftByBadgeCount" } else { "nextGymLeaderOrChampionByBadgeCount" }
                requiresExLaunch = $Result.ExpLevelCapRequiresExLaunch
                exLaunchConfigPath = $Result.ExpLevelCapExLaunchConfigPath
                requestedDirectly = ([bool]$GymLeagueStoryLevelCap -or [bool]$MainStorySoftLevelCap)
                notes = [ordered]@{
                    fr = if ($effectiveMainStorySoftLevelCap) { $mainStorySoftCapNotesFr + " Techniquement, le module ExLaunch réutilise la même table interne de 9 caps par badge que le mode arènes/Tarak." } else { $storyGymLeagueCapNotesFr }
                    en = if ($effectiveMainStorySoftLevelCap) { $mainStorySoftCapNotesEn + " Technically, the ExLaunch module reuses the same internal 9-slot badge table backend as the gym/champion mode." } else { $storyGymLeagueCapNotesEn }
                }
                patches = @($storyGymLeagueExpCapPatches)
            }
            exLaunchModule = [ordered]@{
                requested = $Result.ExLaunchModuleRequested
                available = $Result.ExLaunchModuleAvailable
                deployed = $Result.ExLaunchModuleDeployed
                gameVersion = $Result.ExLaunchModuleGameVersion
                titleId = $Result.ExLaunchModuleTitleId
                sourceRoot = $Result.ExLaunchModuleSourceRoot
                subsdkSourceRoot = $Result.ExLaunchModuleSubsdkSourceRoot
                targetRoot = $Result.ExLaunchModuleTargetRoot
                mainNpdmPath = $Result.ExLaunchModuleMainNpdmPath
                subsdk9Path = $Result.ExLaunchModuleSubsdk9Path
                runtimePcControlsEnabled = $Result.RuntimePcControlsEnabled
                runtimePcScriptApplied = $Result.RuntimePcScriptApplied
                missingFiles = @($Result.ExLaunchModuleMissingFiles)
                notes = [ordered]@{
                    fr = "Le main.npdm ExLaunch-compatible fourni par le projet est deploye avec le module. Le subsdk9 est le module custom ExLaunch du randomizer. Les scripts ROMFS runtime sont ajoutes en patchant le script_id_record.bin copie depuis le dump utilisateur, sans utiliser de script_id_record vanilla embarque."
                    en = "The project's ExLaunch-compatible main.npdm is deployed with the module. subsdk9 is the randomizer's custom ExLaunch module. Runtime ROMFS scripts are added by patching script_id_record.bin copied from the user's dump, without using a bundled vanilla script_id_record."
                }
            }
        }
        autoInstall = [ordered]@{
            requested = $Result.AutoInstallRequested
            requestedTargetKeys = @($Result.AutoInstallRequestedTargetKeys)
            successCount = $Result.AutoInstallSuccessCount
            failureCount = $Result.AutoInstallFailureCount
            results = @($Result.AutoInstallResults)
            notes = [ordered]@{
                fr = "Si l'option est cochee, le randomizer tente de copier automatiquement romfs, exefs et le sous-arbre sdmc généré vers tous les émulateurs coches et detectes sur le PC: Eden, Ryujinx, Yuzu, Sudachi, Citron, Suyu et Citron Neo."
                en = "When enabled, the randomizer tries to copy the generated romfs, exefs and sdmc subtree into every checked and detected emulator on the PC: Eden, Ryujinx, Yuzu, Sudachi, Citron, Suyu, and Citron Neo."
            }
        }
        installationPackage = [ordered]@{
            root = $Result.InstallationPackageRoot
            readmePath = $Result.InstallationPackageReadmePath
            targets = @($Result.InstallationTargets)
            notes = [ordered]@{
                fr = "Le dossier Installation contient une arborescence déjà prete a copier pour Ryujinx, avec un README bilingue."
                en = "The Installation folder contains a ready-to-copy layout for Ryujinx, plus a bilingual README."
            }
        }
        starterRelatedTrainerPatches = [ordered]@{
            enabled = [bool]$PatchStarterRelatedTrainers
            filesEdited = $Result.StarterRelatedTrainerFilesEdited
            slotsEdited = $Result.StarterRelatedTrainerSlotsEdited
            notes = [ordered]@{
                fr = "Repatch robuste: les slots sont identifies depuis les données vanilla, puis forces vers le trio de starters final même si les dresseurs ont déjà été randomises. Les slots patches reconstruisent aussi leurs attaques selon le mode moves dresseurs actif."
                en = "Robust repatch: slots are identified from vanilla data, then forced to the final starter trio even if trainer teams were already randomized. Patched slots also rebuild their moves according to the active trainer move mode."
            }
            changes = @($starterPatchChanges)
        }
        bossTeamsToSix = [ordered]@{
            enabled = [bool]$ForceBossTeamsToSix
            scope = (Normalize-BossTeamsToSixScope -Scope $BossTeamsToSixScope)
            configuredTargetCount = Get-ObjectArrayCount $bossTeamsToSixConfiguredCatalog
            appliedTargetCount = Get-ObjectArrayCount $bossTeamsToSixAppliedTargets
            notes = [ordered]@{
                fr = "configuredTargets liste les combats retenus par le scope choisi pour l'option boss a 6. appliedTargets liste les combats effectivement traites pendant cette génération. forcedToSix peut être false si une limite de taille d'équipe bloque sous 6."
                en = "configuredTargets lists the battles selected by the chosen boss-to-6 scope. appliedTargets lists battles actually processed during this generation. forcedToSix can be false if a team-size clamp keeps the team below 6."
            }
            uniqueNames = [ordered]@{
                fr = @(Get-BossTrainerUniqueNames -Language "fr" -Scope $BossTeamsToSixScope)
                en = @(Get-BossTrainerUniqueNames -Language "en" -Scope $BossTeamsToSixScope)
            }
            configuredTargets = @($bossTeamsToSixConfiguredCatalog)
            appliedTargets = @($bossTeamsToSixAppliedTargets)
        }
        strictBossMaxLevelCap = [ordered]@{
            enabled = $effectiveStrictBossMaxLevelCap
            requested = [bool]$StrictBossMaxLevelCap
            overriddenByMainStorySoftLevelCap = [bool]$MainStorySoftLevelCap
            overriddenByGymLeagueStoryLevelCap = ([bool]$GymLeagueStoryLevelCap -and (-not $effectiveMainStorySoftLevelCap))
            overriddenByStoryMajorBattleOrderLevelCap = ([bool]$StoryMajorBattleOrderLevelCap -and (-not $effectiveMainStorySoftLevelCap) -and (-not $effectiveStoryGymLeagueExpCap))
            configuredTargetCount = Get-ObjectArrayCount $bossTargetCatalog
            appliedTargetCount = Get-ObjectArrayCount $strictBossCapAppliedTargets
            normalizedTeamCount = @($strictBossCapAppliedTargets | Where-Object { $_.strictBossMaxLevelCap -and [bool]$_.strictBossMaxLevelCap.applied }).Count
            notes = [ordered]@{
                fr = if ($effectiveMainStorySoftLevelCap) { "Cette option a été demandée mais le mode progression principale souple a la priorité pour l'EXP et ne lance pas la normalisation boss max stricte pendant cette génération." } elseif ([bool]$GymLeagueStoryLevelCap) { "Cette option a été demandée mais le mode histoire arènes/champion a la priorité pour l'EXP et désactivé la normalisation boss max strict pendant cette génération." } elseif ([bool]$StoryMajorBattleOrderLevelCap) { "Cette option a été demandée mais le mode ordre histoire principale prend la priorité et utilise sa propre liste ordonnée de combats." } else { "Utilise la même liste de boss que ci-dessus et aligne tous les Pokémon de ces équipes sur le niveau max de leur équipe. Le blocage EXP en jeu demande le module ExLaunch." }
                en = if ($effectiveMainStorySoftLevelCap) { "This option was requested, but soft main-story progression mode takes priority for EXP and does not run strict boss max normalization during this generation." } elseif ([bool]$GymLeagueStoryLevelCap) { "This option was requested, but the gym/champion story mode takes priority for EXP and disables strict boss max normalization during this run." } elseif ([bool]$StoryMajorBattleOrderLevelCap) { "This option was requested, but the ordered main-story mode takes priority and uses its own ordered battle list." } else { "Uses the same boss list as above and normalizes every Pokémon in those teams to that team's max level. In-game EXP enforcement requires the ExLaunch module." }
            }
            configuredTargets = @($bossTargetCatalog)
            appliedTargets = @($strictBossCapAppliedTargets)
        }
        mainStorySoftLevelCap = [ordered]@{
            enabled = $effectiveMainStorySoftLevelCap
            requested = [bool]$MainStorySoftLevelCap
            count = Get-ObjectArrayCount $mainStorySoftCaps
            reportPath = $Result.MainStorySoftCapsReportPath
            notes = [ordered]@{
                fr = $mainStorySoftCapNotesFr
                en = $mainStorySoftCapNotesEn
            }
            stages = @($mainStorySoftCaps)
        }
        storyMajorBattleOrderLevelCap = [ordered]@{
            enabled = $effectiveStoryMajorBattleOrderLevelCap
            requested = [bool]$StoryMajorBattleOrderLevelCap
            overriddenByMainStorySoftLevelCap = [bool]$MainStorySoftLevelCap
            overriddenByGymLeagueStoryLevelCap = ([bool]$GymLeagueStoryLevelCap -and (-not $effectiveMainStorySoftLevelCap))
            configuredTargetCount = @($storyMajorBattleTargetCatalog).Length
            appliedTargetCount = Get-ObjectArrayCount $storyMajorBattleAppliedTargets
            normalizedTeamCount = @($storyMajorBattleAppliedTargets | Where-Object { $_.storyMajorBattleOrderLevelCap -and [bool]$_.storyMajorBattleOrderLevelCap.applied }).Count
            reportPath = $Result.StoryMajorBattleCapsReportPath
            notes = [ordered]@{
                fr = if ($effectiveMainStorySoftLevelCap) { "Cette option a été demandée mais le mode progression principale souple garde la priorité pour l'EXP. Le mode ordre histoire principale n'est donc pas applique pendant cette génération." } elseif ([bool]$GymLeagueStoryLevelCap) { "Cette option a été demandée mais le mode histoire arènes/champion garde la priorité pour l'EXP. Le mode ordre histoire principale n'est donc pas applique pendant cette génération." } else { $storyMajorBattleCapNotesFr }
                en = if ($effectiveMainStorySoftLevelCap) { "This option was requested, but soft main-story progression mode keeps EXP priority. The ordered main-story mode is therefore not applied during this generation." } elseif ([bool]$GymLeagueStoryLevelCap) { "This option was requested, but gym/champion story mode keeps EXP priority. The ordered main-story mode is therefore not applied during this run." } else { $storyMajorBattleCapNotesEn }
            }
            configuredTargets = @($storyMajorBattleTargetCatalog)
            appliedTargets = @($storyMajorBattleAppliedTargets)
            battles = @($storyMajorBattleCaps)
        }
        storyGymLeagueLevelCap = [ordered]@{
            enabled = $effectiveStoryGymLeagueExpCap
            count = Get-ObjectArrayCount $storyGymLeagueCaps
            reportPath = $Result.StoryGymLeagueCapsReportPath
            notes = [ordered]@{
                fr = if ($effectiveMainStorySoftLevelCap) { "Cette option a été demandée mais le mode progression principale souple garde la priorité et utilise sa propre table de 9 caps enrichie avec les boss antagonistes." } else { $storyGymLeagueCapNotesFr }
                en = if ($effectiveMainStorySoftLevelCap) { "This option was requested, but soft main-story progression mode keeps priority and uses its own 9-step table enriched with villain bosses." } else { $storyGymLeagueCapNotesEn }
            }
            stages = @($storyGymLeagueCaps)
        }
        bossLevelCaps = [ordered]@{
            enforcedInGame = $false
            enforcementMode = $bossCapEnforcementMode
            requiresExeFsPatch = $false
            requiresExLaunch = $effectiveAnyExpLevelCap
            count = $Result.BossLevelCapsLogged
            reportPath = $Result.BossLevelCapsReportPath
            notes = [ordered]@{
                fr = $bossLevelCapNotesFr
                en = $bossLevelCapNotesEn
            }
        }
        evolutionMethodNotes = [ordered]@{
            fr = @(
                "Amitie convertie en niveau: methodes 1, 2, 3.",
                "Echange converti en niveau: methodes 5, 6, 7.",
                "Spécial converti en niveau: toutes les methodes non vides qui ne sont pas déjà niveau pur."
            )
            en = @(
                "Friendship converted to level-up: methods 1, 2, 3.",
                "Trade converted to level-up: methods 5, 6, 7.",
                "Special converted to level-up: every non-empty method that is not already plain level-up."
            )
        }
        detailedReports = [ordered]@{
            trainerChanges = $Result.TrainerChangesReportPath
            wildChanges = $Result.WildChangesReportPath
            itemChanges = $Result.ItemChangesReportPath
            encounterZones = $Result.EncounterZoneReportPath
            seedSummary = $Result.SeedSummaryReportPath
            spoilerLog = $Result.SpoilerLogReportPath
            levelCaps = $Result.BossLevelCapsReportPath
            mainStorySoftCaps = $Result.MainStorySoftCapsReportPath
            storyGymLeagueCaps = $Result.StoryGymLeagueCapsReportPath
            storyMajorBattleCaps = $Result.StoryMajorBattleCapsReportPath
        }
    }

    $reportPath = if ([string]::IsNullOrWhiteSpace($JsonReportPath)) {
        Get-OutputReportPath -OutputRomfsRoot $OutputRomfsRoot -FileName "randomizer-report.json"
    } else {
        $JsonReportPath
    }

    $reportDir = Split-Path -Parent $reportPath
    if ($reportDir) {
        Ensure-Directory -Path $reportDir
    }

    Write-JsonFile -Value $report -Path $reportPath -Depth 8
    return $reportPath
}

function Write-TrainerChangesReport {
    param(
        [object[]]$TrainerChanges,
        [string]$OutputRomfsRoot,
        [long]$ResolvedSeed,
        [object[]]$BossTrainerTargets = @()
    )

    if (-not $ExportJsonReport) {
        return $null
    }

    $reportPath = Get-OutputReportPath -OutputRomfsRoot $OutputRomfsRoot -FileName "trainer-changes.json"
    Ensure-ParentDirectory -Path $reportPath
    $trainerChangesArray = Convert-ToObjectArray $TrainerChanges
    $bossTrainerTargetsArray = Convert-ToObjectArray $BossTrainerTargets
    $bossTeamsToSixTargetsArray = Convert-ToObjectArray ($bossTrainerTargetsArray | Where-Object { [bool]$_.bossTeamsToSixRequested })
    $strictBossCapTargetsArray = Convert-ToObjectArray ($bossTrainerTargetsArray | Where-Object { $_.strictBossMaxLevelCap -and [bool]$_.strictBossMaxLevelCap.enabled })
    $storyMajorBattleTargetsArray = Convert-ToObjectArray ($bossTrainerTargetsArray |
        Where-Object { $_.storyMajorBattleOrderLevelCap -and [bool]$_.storyMajorBattleOrderLevelCap.enabled } |
        Sort-Object @{ Expression = { if ($_.storyMajorBattleOrderLevelCap) { [int]$_.storyMajorBattleOrderLevelCap.stageIndex } else { 0 } } }, @{ Expression = { [int]$_.trainerId } })

    $report = [ordered]@{
        version = $AppVersion
        generatedAt = [DateTime]::UtcNow.ToString("o")
        sourceRomfs = $SourceRomfs
        outputRomfs = $OutputRomfsRoot
        seed = $ResolvedSeed
        notes = [ordered]@{
            fr = "Detail avant/après pour chaque dresseur modifie. Les slots sont numerotes a partir de 1."
            en = "Before/after details for each edited trainer. Slots are numbered from 1."
        }
        bossTeamsToSixTargets = [ordered]@{
            count = Get-ObjectArrayCount $bossTeamsToSixTargetsArray
            notes = [ordered]@{
                fr = "Combats detectes comme boss et traites par l'option boss a 6 Pokémon pendant cette génération."
                en = "Battles detected as bosses and processed by the boss teams to 6 Pokemon option during this generation."
            }
            targets = @($bossTeamsToSixTargetsArray)
        }
        strictBossMaxLevelCapTargets = [ordered]@{
            count = Get-ObjectArrayCount $strictBossCapTargetsArray
            notes = [ordered]@{
                fr = "Combats detectes comme boss et traites par l'option boss max strict pendant cette génération. Chaque cible exporte le niveau cap retenu et les niveaux avant/après normalisation."
                en = "Battles detected as bosses and processed by the strict boss max option during this generation. Each target exports the selected cap level and the levels before/after normalization."
            }
            targets = @($strictBossCapTargetsArray)
        }
        storyMajorBattleOrderLevelCapTargets = [ordered]@{
            count = Get-ObjectArrayCount $storyMajorBattleTargetsArray
            notes = [ordered]@{
                fr = "Combats majeurs de l'histoire principale traites par le mode ordre histoire. Ils sont exportes dans l'ordre avec leur étape, leur catégorie et les niveaux avant/après normalisation."
                en = "Main-story major battles processed by the ordered story mode. They are exported in order with their stage, category, and levels before/after normalization."
            }
            targets = @($storyMajorBattleTargetsArray)
        }
        count = Get-ObjectArrayCount $trainerChangesArray
        trainers = @($trainerChangesArray)
    }

    Write-JsonFile -Value $report -Path $reportPath -Depth 30
    return $reportPath
}

function Write-WildChangesReport {
    param(
        [object[]]$WildChanges,
        [string]$OutputRomfsRoot,
        [long]$ResolvedSeed
    )

    if (-not $ExportJsonReport) {
        return $null
    }

    $reportPath = Get-OutputReportPath -OutputRomfsRoot $OutputRomfsRoot -FileName "wild-changes.json"
    Ensure-ParentDirectory -Path $reportPath
    $wildChangesArray = Convert-ToObjectArray $WildChanges
    $visibleBehavior = Get-NormalizedVisibleEncounterBehavior -Value $VisibleEncounterBehavior
    $drawMode = Get-NormalizedEncounterDrawMode -Value $EncounterDrawMode -LegacyVisibleBehavior $VisibleEncounterBehavior
    $visibleNotes = switch ($drawMode) {
        "FullRandom" {
            [ordered]@{
                fr = "Mode full_random: les tables visibles ROMFS utilisent un pool de modeles overworld detectes, et le combat runtime relance un tirage independant a chaque rencontre."
                en = "full_random mode: visible ROMFS tables use a detected overworld-model pool, and the runtime battle layer rolls an independent replacement for each encounter."
            }
        }
        "VisibleFixeTirageRandom" {
            [ordered]@{
                fr = "Mode visible_fixe_tirage_random: les modeles visibles restent ceux du ROMFS, mais le combat runtime relance un tirage a chaque rencontre."
                en = "visible_fixe_tirage_random mode: visible models stay as authored in ROMFS, but the runtime battle layer rolls again for each encounter."
            }
        }
        default {
            switch ($visibleBehavior) {
                "RevelationPermanente" {
                    [ordered]@{
                        fr = "Mode slot_par_espece + revelation permanente: une espèce visible de cette zone mene a un remplacement stable, puis le Pokémon révélé reste stable sans boucle."
                        en = "slot_par_espece + permanent reveal: a visible species in this zone maps to a stable replacement, then the revealed Pokemon stays stable without chaining."
                    }
                }
                "MasqueFixe" {
                    [ordered]@{
                        fr = "Mode slot_par_espece + masque fixe: le modèle overworld ne change pas; la copie de combat reçoit le remplacement stable par zone/espèce/form."
                        en = "slot_par_espece + fixed mask: the overworld model does not change; the battle copy receives the stable zone/species/form replacement."
                    }
                }
                default {
                    [ordered]@{
                        fr = "Mode classique: les Pokémon visibles et les combats suivent les tables ROMFS."
                        en = "Classic mode: visible Pokemon and battles follow ROMFS tables."
                    }
                }
            }
        }
    }

    $report = [ordered]@{
        version = $AppVersion
        generatedAt = [DateTime]::UtcNow.ToString("o")
        sourceRomfs = $SourceRomfs
        outputRomfs = $OutputRomfsRoot
        seed = $ResolvedSeed
        notes = [ordered]@{
            fr = "Detail avant/apres pour les rencontres sauvages supportees: rencontres fixes/scriptes, hautes herbes, Pokemon visibles en overworld et underground. mappingMode indique si le remplacement est stable par espece ou par slot. $($visibleNotes.fr)"
            en = "Before/after details for supported wild encounter blocks: static/scripted encounters, tall grass, visible overworld Pokemon, and underground. mappingMode says whether replacements are stable per species or per slot. $($visibleNotes.en)"
        }
        count = Get-ObjectArrayCount $wildChangesArray
        encounters = @($wildChangesArray)
    }

    Write-JsonFile -Value $report -Path $reportPath -Depth 20
    return $reportPath
}

function Get-EncounterAreaDisplayName {
    param(
        [object]$Change,
        [string]$Language = "fr"
    )

    $zoneId = [string](Get-DynamicPropertyValue -Object $Change -Name "zoneId" -DefaultValue "")
    $internalFile = [string](Get-DynamicPropertyValue -Object $Change -Name "internalFile" -DefaultValue "")
    $tableIndex = [int](Get-DynamicPropertyValue -Object $Change -Name "tableIndex" -DefaultValue 0)
    if (-not [string]::IsNullOrWhiteSpace($zoneId) -and $zoneId -ne "0x0000000000000000") {
        return $(if ($Language -eq "en") { "Encounter zone $zoneId" } else { "Zone de rencontre $zoneId" })
    }
    if (-not [string]::IsNullOrWhiteSpace($internalFile) -and $tableIndex -gt 0) {
        return $(if ($Language -eq "en") { "$internalFile table $tableIndex" } else { "$internalFile table $tableIndex" })
    }
    $blockName = [string](Get-DynamicPropertyValue -Object $Change -Name "block" -DefaultValue "")
    if (-not [string]::IsNullOrWhiteSpace($blockName)) { return $blockName }
    return $(if ($Language -eq "en") { "Unknown zone" } else { "Zone inconnue" })
}

function Get-EncounterMethodDisplayName {
    param(
        [object]$Change,
        [string]$Language = "fr"
    )

    $block = [string](Get-DynamicPropertyValue -Object $Change -Name "block" -DefaultValue "")
    $subTable = [string](Get-DynamicPropertyValue -Object $Change -Name "subTable" -DefaultValue "")
    switch ($block) {
        "grassEncounter" {
            if (-not [string]::IsNullOrWhiteSpace($subTable)) { return $subTable }
            return $(if ($Language -eq "en") { "Grass / field encounter" } else { "Hautes herbes / terrain" })
        }
        "symbolOverworldEncounter" {
            if (-not [string]::IsNullOrWhiteSpace($subTable)) { return "Visible overworld - $subTable" }
            return $(if ($Language -eq "en") { "Visible overworld" } else { "Pokémon visible overworld" })
        }
        "staticScriptedEncounter" { return $(if ($Language -eq "en") { "Static / scripted encounter" } else { "Rencontre fixe / script" }) }
        "undergroundEncounter" { return "Underground / chika" }
        "inGameTrade" { return $(if ($Language -eq "en") { "NPC trade" } else { "Échange PNJ" }) }
        default {
            if (-not [string]::IsNullOrWhiteSpace($block)) { return $block }
            return $(if ($Language -eq "en") { "Unknown method" } else { "Methode inconnue" })
        }
    }
}

function New-EncounterZoneSlotObject {
    param(
        [object]$Change,
        [string]$Language = "fr"
    )

    $species = Get-DynamicPropertyValue -Object $Change -Name "species" -DefaultValue $null
    $before = Get-DynamicPropertyValue -Object $species -Name "before" -DefaultValue $null
    $after = Get-DynamicPropertyValue -Object $species -Name "after" -DefaultValue $null
    $visual = Get-DynamicPropertyValue -Object $species -Name "visual" -DefaultValue $after
    $battle = Get-DynamicPropertyValue -Object $species -Name "battle" -DefaultValue $after
    $probability = Get-DynamicPropertyValue -Object $Change -Name "probability" -DefaultValue $null
    $levelMin = Get-DynamicPropertyValue -Object $Change -Name "levelMin" -DefaultValue $null
    $levelMax = Get-DynamicPropertyValue -Object $Change -Name "levelMax" -DefaultValue $null

    return [ordered]@{
        method = Get-EncounterMethodDisplayName -Change $Change -Language $Language
        block = [string](Get-DynamicPropertyValue -Object $Change -Name "block" -DefaultValue "")
        internalFile = [string](Get-DynamicPropertyValue -Object $Change -Name "internalFile" -DefaultValue "")
        tableIndex = Get-DynamicPropertyValue -Object $Change -Name "tableIndex" -DefaultValue $null
        subTableIndex = Get-DynamicPropertyValue -Object $Change -Name "subTableIndex" -DefaultValue $null
        slotIndex = Get-DynamicPropertyValue -Object $Change -Name "slotIndex" -DefaultValue $null
        chancePercent = $probability
        levelMin = $levelMin
        levelMax = $levelMax
        mappingMode = [string](Get-DynamicPropertyValue -Object $Change -Name "mappingMode" -DefaultValue "")
        visualMode = [string](Get-DynamicPropertyValue -Object $Change -Name "visualMode" -DefaultValue "")
        appliedToRomfs = [bool](Get-DynamicPropertyValue -Object $Change -Name "appliedToRomfs" -DefaultValue $false)
        species = [ordered]@{
            vanilla = $before
            randomized = $after
            visual = $visual
            battle = $battle
        }
    }
}

function Write-EncounterZoneReport {
    param(
        [object[]]$WildChanges,
        [string]$OutputRomfsRoot,
        [long]$ResolvedSeed
    )

    if (-not $ExportJsonReport -or -not $ExportEncounterZoneReport) {
        return $null
    }

    $reportLang = if (([string]$ReportLanguage).ToLowerInvariant() -eq "en") { "en" } else { "fr" }
    $wildChangesArray = Convert-ToObjectArray $WildChanges
    $groups = [ordered]@{}
    foreach ($change in @($wildChangesArray)) {
        $zoneId = [string](Get-DynamicPropertyValue -Object $change -Name "zoneId" -DefaultValue "")
        $internalFile = [string](Get-DynamicPropertyValue -Object $change -Name "internalFile" -DefaultValue "")
        $tableIndex = [int](Get-DynamicPropertyValue -Object $change -Name "tableIndex" -DefaultValue 0)
        $blockName = [string](Get-DynamicPropertyValue -Object $change -Name "block" -DefaultValue "")
        $key = if (-not [string]::IsNullOrWhiteSpace($zoneId)) { $zoneId } elseif (-not [string]::IsNullOrWhiteSpace($internalFile)) { "$internalFile#$tableIndex" } else { $blockName }
        if (-not $groups.Contains($key)) {
            $groups[$key] = New-Object System.Collections.Generic.List[object]
        }
        [void]$groups[$key].Add($change)
    }

    $zones = New-Object System.Collections.Generic.List[object]
    foreach ($key in $groups.Keys) {
        $items = @($groups[$key].ToArray())
        $first = $items | Select-Object -First 1
        $slots = @($items | ForEach-Object { New-EncounterZoneSlotObject -Change $_ -Language $reportLang })
        $methods = @($slots | ForEach-Object { [string]$_.method } | Select-Object -Unique)
        $zones.Add([ordered]@{
            id = [string]$key
            name = Get-EncounterAreaDisplayName -Change $first -Language $reportLang
            nameSource = "generatedFromEncounterTable"
            zoneId = [string](Get-DynamicPropertyValue -Object $first -Name "zoneId" -DefaultValue "")
            internalFile = [string](Get-DynamicPropertyValue -Object $first -Name "internalFile" -DefaultValue "")
            methods = @($methods)
            slotCount = $slots.Count
            slots = @($slots)
        })
    }

    $report = [ordered]@{
        version = $AppVersion
        generatedAt = [DateTime]::UtcNow.ToString("o")
        sourceRomfs = $SourceRomfs
        outputRomfs = $OutputRomfsRoot
        seed = $ResolvedSeed
        spoilerWarning = [ordered]@{
            fr = "Ce fichier révélé les rencontres randomisées par zone. Ne l'affiche pas automatiquement dans le viewer si le joueur ne veut pas être spoile."
            en = "This file reveals randomized encounters by zone. Do not auto-open it in the viewer if the player does not want spoilers."
        }
        schema = [ordered]@{
            intendedViewer = "PokeFeur Trainer Viewer / future encounter viewer"
            zoneNameNote = [ordered]@{
                fr = "Les noms sont générés depuis les identifiants de tables disponibles. Le viewer peut remplacer name via une table de correspondance zoneId -> nom de route/zone."
                en = "Names are generated from available table identifiers. The viewer can replace name through a zoneId -> route/area name mapping table."
            }
        }
        count = $zones.Count
        zones = @($zones.ToArray())
    }

    $reportPath = Get-OutputReportPath -OutputRomfsRoot $OutputRomfsRoot -FileName "encounter-zones.json"
    Write-JsonFile -Value $report -Path $reportPath -Depth 30
    return $reportPath
}

function New-RunSummaryObject {
    param(
        [object]$Result,
        [string]$OutputRomfsRoot
    )

    $trainerChanges = Convert-ToObjectArray $Result.TrainerChangesForReports
    $bossTargets = Convert-ToObjectArray $Result.BossTrainerTargets
    $starters = @()
    foreach ($starterId in @($Result.StarterSpeciesIds)) {
        if ($starterId) {
            $starters += New-SpeciesReportObject -SpeciesId ([int]$starterId)
        }
    }
    $importantTrainers = @($trainerChanges | Select-Object -First 20)
    $difficultySignals = [ordered]@{
        trainerLevelMultiplier = [double]$TrainerLevelMultiplier
        forceAllTeamsToSix = [bool]$ForceAllTeamsToSix
        forceBossTeamsToSix = [bool]$ForceBossTeamsToSix
        maxTrainerAI = [bool]$MaxTrainerAI
        trainerItems = [string]$TrainerItemMode
        trainerMoves = [string]$TrainerMoveMode
        allowLegendaryTrainers = [bool]$AllowLegendaryTrainers
        anyLevelCap = [bool](Get-AnyExpLevelCapEnabled)
    }
    $score = 0
    if ([double]$TrainerLevelMultiplier -gt 1.0) { $score += [Math]::Min(3, [int](([double]$TrainerLevelMultiplier - 1.0) * 10)) }
    if ([bool]$ForceAllTeamsToSix) { $score += 3 }
    if ([bool]$ForceBossTeamsToSix) { $score += 2 }
    if ([bool]$MaxTrainerAI) { $score += 2 }
    if (Test-TrainerModeUsesSmogon $TrainerMoveMode) { $score += 2 }
    if ([string]$TrainerItemMode -eq "ForceAll" -or (Test-TrainerModeUsesSmogon $TrainerItemMode)) { $score += 1 }
    if ([bool](Get-AnyExpLevelCapEnabled)) { $score += 2 }
    $difficultyEstimate = if ($score -ge 10) { "veryHard" } elseif ($score -ge 6) { "hard" } elseif ($score -ge 3) { "moderate" } else { "standard" }

    return [ordered]@{
        version = $AppVersion
        generatedAt = [DateTime]::UtcNow.ToString("o")
        seed = $Result.Seed
        sourceGameVersion = $Result.ExLaunchModuleGameVersion
        outputRomfs = $OutputRomfsRoot
        spoilerWarning = [ordered]@{
            fr = "Ce résumé peut spoiler les starters, dresseurs importants, objets, caps et rencontres. Affiche-le seulement si l'utilisateur le demande."
            en = "This summary can spoil starters, important trainers, items, caps, and encounters. Show it only when the user asks for it."
        }
        starters = @($starters)
        legendaryAllowed = [ordered]@{
            trainers = [bool]$AllowLegendaryTrainers
            gifts = [bool]$AllowLegendaryGifts
            trades = [bool]$AllowLegendaryTrades
            evolutions = [bool]$AllowLegendaryEvolutions
            staticEncounters = [bool]$AllowLegendaryStaticEncounters
            grassEncounters = [bool]$AllowLegendaryGrassEncounters
            underground = [bool]$AllowLegendaryUnderground
        }
        difficulty = [ordered]@{
            estimate = $difficultyEstimate
            score = $score
            signals = $difficultySignals
        }
        counts = [ordered]@{
            trainersEdited = $Result.TrainersEdited
            trainerPokemonProcessed = $Result.TrainerPokemonProcessed
            bossTeamsExpanded = $Result.BossTeamsExpanded
            pickupItemsEdited = $Result.PickupItemsEdited
            shopItemsEdited = $Result.ShopItemsEdited
            technicalRecordsEdited = $Result.TechnicalRecordsEdited
            grassEncounterSlotsEdited = $Result.GrassEncounterSlotsEdited
            staticEncountersEdited = $Result.StaticEncountersEdited
            undergroundSpeciesSlotsEdited = $Result.UndergroundSpeciesSlotsEdited
        }
        firstTrainerChanges = @($importantTrainers)
        bossTargets = @($bossTargets | Select-Object -First 40)
        dataFiles = @(foreach ($entry in @($script:DataFileDiagnostics)) {
            [ordered]@{
                path = $entry.RelativePath
                present = $entry.Present
                severity = $entry.Severity
                degradationIfMissing = $entry.Degradation
            }
        })
    }
}

function Write-SeedAndSpoilerReports {
    param(
        [object]$Result,
        [string]$OutputRomfsRoot
    )

    if (-not $ExportJsonReport) {
        return [pscustomobject]@{ SpoilerLogPath = ""; SeedSummaryPath = "" }
    }

    $summary = New-RunSummaryObject -Result $Result -OutputRomfsRoot $OutputRomfsRoot
    $seedSummaryPath = Get-OutputReportPath -OutputRomfsRoot $OutputRomfsRoot -FileName "seed-summary.json"
    Write-JsonFile -Value $summary -Path $seedSummaryPath -Depth 18

    $spoilerLog = [ordered]@{
        version = $AppVersion
        generatedAt = [DateTime]::UtcNow.ToString("o")
        seed = $Result.Seed
        spoilerWarning = [ordered]@{
            fr = "Spoiler log complet: starters, dresseurs, rencontres, objets et caps. Ne pas afficher automatiquement."
            en = "Full spoiler log: starters, trainers, encounters, items, and caps. Do not show automatically."
        }
        summary = $summary
        trainerChanges = @(Convert-ToObjectArray $Result.TrainerChangesForReports)
        wildChanges = @(Convert-ToObjectArray $Result.WildChangesForReports)
        itemChanges = @(Convert-ToObjectArray $Result.ItemChangesForReports)
        bossLevelCaps = @(Convert-ToObjectArray $Result.BossLevelCaps)
        storyGymLeagueCaps = @(Convert-ToObjectArray $Result.StoryGymLeagueCaps)
        storyMajorBattleCaps = @(Convert-ToObjectArray $Result.StoryMajorBattleCaps)
    }
    $spoilerLogPath = Get-OutputReportPath -OutputRomfsRoot $OutputRomfsRoot -FileName "spoiler-log.json"
    Write-JsonFile -Value $spoilerLog -Path $spoilerLogPath -Depth 30

    return [pscustomobject]@{
        SpoilerLogPath = $spoilerLogPath
        SeedSummaryPath = $seedSummaryPath
    }
}

function Write-LevelCapsReport {
    param(
        [object[]]$LevelCaps,
        [string]$OutputRomfsRoot,
        [long]$ResolvedSeed
    )

    if (-not $ExportJsonReport) {
        return $null
    }

    $reportPath = Get-OutputReportPath -OutputRomfsRoot $OutputRomfsRoot -FileName "level-caps.json"
    Ensure-ParentDirectory -Path $reportPath
    $levelCapsArray = Convert-ToObjectArray $LevelCaps

    $selectedExpLevelCapMode = [string](Get-SelectedExpLevelCapMode)
    $effectiveReceiverLevelExpCap = $selectedExpLevelCapMode -in @("receiverVsDefeatedPokemon", "strictBossMaxLevel", "storyOrderedMajorBattles")
    $effectiveMainStorySoftLevelCap = $selectedExpLevelCapMode -eq "storyMainProgressionSoft"
    $effectiveStoryGymLeagueExpCap = $selectedExpLevelCapMode -eq "storyGymLeague"
    $effectiveStoryMajorBattleOrderLevelCap = $selectedExpLevelCapMode -eq "storyOrderedMajorBattles"
    $effectiveAnyExpLevelCap = $selectedExpLevelCapMode -ne "none"
    $bossCapEnforcementMode = Get-BossLevelCapEnforcementMode
    $report = [ordered]@{
        version = $AppVersion
        generatedAt = [DateTime]::UtcNow.ToString("o")
        sourceRomfs = $SourceRomfs
        outputRomfs = $OutputRomfsRoot
        seed = $ResolvedSeed
        enforcedInGame = $false
        enforcementMode = $bossCapEnforcementMode
        requiresExeFsPatch = $false
        requiresExLaunch = $effectiveAnyExpLevelCap
        strictBossMaxLevelCap = [ordered]@{
            enabled = ($selectedExpLevelCapMode -eq "strictBossMaxLevel")
            requested = [bool]$StrictBossMaxLevelCap
            notes = [ordered]@{
                fr = if ($effectiveMainStorySoftLevelCap) { "Cette option est demandée, mais le mode progression principale souple prend la priorité pour le cap EXP et n'utilise pas la normalisation boss max stricte." } elseif ([bool]$GymLeagueStoryLevelCap) { "Cette option est demandée, mais le mode histoire arènes/champion prend la priorité et n'utilise pas la normalisation boss max stricte." } elseif ([bool]$StoryMajorBattleOrderLevelCap) { "Cette option est demandée, mais le mode ordre histoire principale prend la priorité et utilise sa propre liste ordonnée de combats." } else { "Quand cette option est activée, l'outil normalise chaque équipe boss listée sur son niveau max. Le blocage EXP en jeu demande le module ExLaunch." }
                en = if ($effectiveMainStorySoftLevelCap) { "This option is requested, but soft main-story progression mode takes priority for EXP and does not use strict boss max normalization." } elseif ([bool]$GymLeagueStoryLevelCap) { "This option is requested, but gym/champion story mode takes priority and does not use strict boss max normalization." } elseif ([bool]$StoryMajorBattleOrderLevelCap) { "This option is requested, but the ordered main-story mode takes priority and uses its own ordered battle list." } else { "When this option is enabled, the tool normalizes each listed boss team to its max level. In-game EXP enforcement requires the ExLaunch module." }
            }
        }
        mainStorySoftLevelCap = [ordered]@{
            enabled = $effectiveMainStorySoftLevelCap
            requested = [bool]$MainStorySoftLevelCap
            notes = [ordered]@{
                fr = "Quand cette option est activée, le randomizer calcule une table de 9 caps souples basée sur les badges, en gardant les arènes comme ossature et en ajoutant les gros boss antagonistes / fin d'histoire du même palier."
                en = "When this option is enabled, the randomizer computes a soft 9-step badge-based cap table, keeping gyms as the backbone and adding the villain / endgame bosses that land in the same milestone."
            }
        }
        storyMajorBattleOrderLevelCap = [ordered]@{
            enabled = $effectiveStoryMajorBattleOrderLevelCap
            requested = [bool]$StoryMajorBattleOrderLevelCap
            notes = [ordered]@{
                fr = if ($effectiveMainStorySoftLevelCap) { "Cette option est demandée, mais le mode progression principale souple garde la priorité et n'active donc pas cette liste ordonnée." } else { "Quand cette option est activée, une liste ordonnée de gros combats de l'histoire principale est uniformisee sur son niveau max. Le blocage EXP en jeu demande le module ExLaunch." }
                en = if ($effectiveMainStorySoftLevelCap) { "This option is requested, but soft main-story progression mode keeps priority and therefore does not enable this ordered battle list." } else { "When this option is enabled, an ordered list of main-story major battles is normalized to its max level. In-game EXP enforcement requires the ExLaunch module." }
            }
        }
        storyGymLeagueLevelCap = [ordered]@{
            enabled = $effectiveStoryGymLeagueExpCap
            notes = [ordered]@{
                fr = if ($effectiveMainStorySoftLevelCap) { "Cette option est demandée, mais le mode progression principale souple prend la priorité et utilise sa propre table de 9 caps par badge." } else { "Quand cette option est activee, les niveaux utilises viennent des equipes generees et sont exportes dans story-gym-league-caps.json. Le cap en jeu demande le module ExLaunch." }
                en = if ($effectiveMainStorySoftLevelCap) { "This option is requested, but soft main-story progression mode takes priority and uses its own 9-step badge table." } else { "When this option is enabled, the levels used come from the generated teams and are exported in story-gym-league-caps.json. In-game enforcement requires the ExLaunch module." }
            }
        }
        notes = [ordered]@{
            fr = if ($effectiveAnyExpLevelCap) { "Caps boss calculés depuis le niveau max de chaque équipe boss après randomisation. Le cap EXP en jeu n'est pas applique par IPS brut; il demande le module ExLaunch." } else { "Caps boss calculés depuis le niveau max de chaque équipe boss après randomisation. Sans patch ExeFS actif, ce fichier reste une référence de caps." }
            en = if ($effectiveAnyExpLevelCap) { "Boss caps computed from each boss team's max level after randomization. In-game EXP cap enforcement is not applied through raw IPS; it requires the ExLaunch module." } else { "Boss caps computed from each boss team's max level after randomization. Without an active ExeFS patch, this file remains a cap référence only." }
        }
        count = Get-ObjectArrayCount $levelCapsArray
        caps = @($levelCapsArray)
    }

    Write-JsonFile -Value $report -Path $reportPath -Depth 20
    return $reportPath
}

function Write-StoryGymLeagueCapsReport {
    param(
        [object[]]$StoryCaps,
        [string]$OutputRomfsRoot,
        [long]$ResolvedSeed
    )

    if (-not $ExportJsonReport) {
        return $null
    }

    $reportPath = Get-OutputReportPath -OutputRomfsRoot $OutputRomfsRoot -FileName "story-gym-league-caps.json"
    Ensure-ParentDirectory -Path $reportPath
    $storyCapsArray = Convert-ToObjectArray $StoryCaps
    $gameVersion = Get-SourceGameVersion -RomfsRoot $SourceRomfs
    $report = [ordered]@{
        version = $AppVersion
        generatedAt = [DateTime]::UtcNow.ToString("o")
        sourceRomfs = $SourceRomfs
        outputRomfs = $OutputRomfsRoot
        seed = $ResolvedSeed
        enabled = [bool]$GymLeagueStoryLevelCap
        gameVersion = $gameVersion
        enforcementMode = "nextGymLeaderOrChampionByBadgeCount"
        notes = [ordered]@{
            fr = "Cap histoire global base sur le nombre de badges. Les 9 entrées ci-dessous sont calculées depuis les équipes randomisées finales: 0 badge = prochaine arène 1, puis arène 2, ..., 8 badges = maitre de la Ligue. Le patch ExeFS ne lit pas ce JSON: il lit la même information injectee dans sa table interne."
            en = "Global story cap based on badge count. The 9 entries below are computed from the final randomized teams: 0 badges = next Gym 1, then Gym 2, ..., 8 badges = Champion. The ExeFS patch does not read this JSON: it reads the same information injected into its internal table."
        }
        count = Get-ObjectArrayCount $storyCapsArray
        stages = @($storyCapsArray)
    }

    Write-JsonFile -Value $report -Path $reportPath -Depth 20
    return $reportPath
}

function Write-MainStorySoftCapsReport {
    param(
        [object[]]$StoryCaps,
        [string]$OutputRomfsRoot,
        [long]$ResolvedSeed
    )

    if (-not $ExportJsonReport) {
        return $null
    }

    $reportPath = Get-OutputReportPath -OutputRomfsRoot $OutputRomfsRoot -FileName "story-main-progression-soft-caps.json"
    Ensure-ParentDirectory -Path $reportPath
    $storyCapsArray = Convert-ToObjectArray $StoryCaps
    $gameVersion = Get-SourceGameVersion -RomfsRoot $SourceRomfs
    $effectiveEnabled = ((Get-SelectedExpLevelCapMode) -eq "storyMainProgressionSoft")
    $report = [ordered]@{
        version = $AppVersion
        generatedAt = [DateTime]::UtcNow.ToString("o")
        sourceRomfs = $SourceRomfs
        outputRomfs = $OutputRomfsRoot
        seed = $ResolvedSeed
        enabled = $effectiveEnabled
        requested = [bool]$MainStorySoftLevelCap
        gameVersion = $gameVersion
        enforcementMode = "mainStoryProgressionSoftByBadgeCount"
        notes = [ordered]@{
            fr = if ($effectiveEnabled) { "Mode progression principale souple: les 9 caps suivent toujours les paliers de badges, mais chaque palier est calcule depuis un groupe de gros combats de l'histoire principale. Ce mode garde les arènes comme ossature et ajoute aussi les vrais boss antagonistes / fin d'histoire quand ils tombent dans le même palier, pour éviter l'overlevel sans changer le cap toutes les 10 minutes. Le jeu ne lit pas ce JSON: il lit la même table de 9 caps injectee dans la config ExLaunch." } else { "Cette option n'est pas effective sur cette génération. Si elle n'est pas cochee, ce JSON documente simplement la table qui aurait été utilisee." }
            en = if ($effectiveEnabled) { "Soft main-story progression mode: the 9 caps still follow badge-count milestones, but each milestone is computed from a grouped set of major main-story fights. This keeps gyms as the backbone and also folds in the real villain / endgame bosses that land in the same milestone, so overleveling is reduced without changing the cap every few minutes. The game does not read this JSON directly: it reads the same 9-cap table injected into the ExLaunch config." } else { "This option is not effective for this génération. If it is not checked, this JSON simply documents the table that would have been used." }
        }
        count = Get-ObjectArrayCount $storyCapsArray
        stages = @($storyCapsArray)
    }

    Write-JsonFile -Value $report -Path $reportPath -Depth 20
    return $reportPath
}

function Write-StoryMajorBattleCapsReport {
    param(
        [object[]]$StoryCaps,
        [string]$OutputRomfsRoot,
        [long]$ResolvedSeed
    )

    if (-not $ExportJsonReport) {
        return $null
    }

    $reportPath = Get-OutputReportPath -OutputRomfsRoot $OutputRomfsRoot -FileName "story-major-battle-caps.json"
    Ensure-ParentDirectory -Path $reportPath
    $storyCapsArray = Convert-ToObjectArray $StoryCaps
    $gameVersion = Get-SourceGameVersion -RomfsRoot $SourceRomfs
    $effectiveEnabled = ((Get-SelectedExpLevelCapMode) -eq "storyOrderedMajorBattles")
    $report = [ordered]@{
        version = $AppVersion
        generatedAt = [DateTime]::UtcNow.ToString("o")
        sourceRomfs = $SourceRomfs
        outputRomfs = $OutputRomfsRoot
        seed = $ResolvedSeed
        enabled = $effectiveEnabled
        requested = [bool]$StoryMajorBattleOrderLevelCap
        overriddenByGymLeagueStoryLevelCap = ([bool]$StoryMajorBattleOrderLevelCap -and [bool]$GymLeagueStoryLevelCap)
        gameVersion = $gameVersion
        enforcementMode = "orderedBaseStoryMajorBattlesStrictViaDynamicExpAndTeamNormalization"
        notes = [ordered]@{
            fr = if ($effectiveEnabled) { "Liste ordonnée des gros combats de l'histoire principale couverts par la nouvelle option. Le JSON suit l'ordre de progression et inclut les variantes dependantes du starter ou de la version. En jeu, cette option garde le patch EXP dynamique global puis uniformise seulement ces équipes majeures sur leur niveau max. Ce JSON n'est pas lu par le jeu: il documente la même sélection calculée par le randomizer." } else { "Cette option n'est pas effective sur cette génération. Si le mode histoire arènes/Tarak est coche en même temps, il garde la priorité pour le patch EXP global et cette liste ordonnée reste désactivée." }
            en = if ($effectiveEnabled) { "Ordered list of the main-story major battles covered by the new option. This JSON follows story order and includes starter-dependent or version-dependent variants. In game, this option keeps the global dynamic EXP patch and only normalizes these major teams to their own max level. The game does not read this JSON: it documents the same selection computed by the randomizer." } else { "This option is not effective for this génération. If gym/champion story mode is checked at the same time, it keeps priority for the global EXP patch and this ordered list stays disabled." }
        }
        count = Get-ObjectArrayCount $storyCapsArray
        battles = @($storyCapsArray)
    }

    Write-JsonFile -Value $report -Path $reportPath -Depth 20
    return $reportPath
}

function Invoke-Randomization {
    param(
        [string]$SourceRomfsRoot,
        [string]$SourceExefsRoot = "",
        [string]$OutputRomfsRoot,
        [scriptblock]$ProgressCallback = $null
    )

    # Le dump D'ABORD : les tables de noms se derivent de lui, il faut donc
    # l'avoir resolu avant de pouvoir les reconstruire.
    $SourceRomfsRoot = Resolve-RequiredSourceRomfsRoot -SourceRomfsRoot $SourceRomfsRoot

    # Puis, si des tables manquent, on les rebatit depuis CE dump plutot que de
    # les redistribuer : elles sont derivees du jeu.
    Restore-DataFilesFromDump -RomfsRoot $SourceRomfsRoot -ProgressCallback $ProgressCallback

    # Enfin : dire ce qui manque ENCORE. Un fichier absent ne fait pas echouer
    # la generation (sauf -StrictDataFiles) mais ne doit plus passer inapercu.
    $script:DataFileDiagnostics = @(Assert-DataFilesAvailable -ProgressCallback $ProgressCallback)
    $sourceGameVersion = Get-SourceGameVersion -RomfsRoot $SourceRomfsRoot
    $hasExplicitSourceExefs = -not [string]::IsNullOrWhiteSpace($SourceExefsRoot)
    $canGenerateExLaunchOutputs = ($hasExplicitSourceExefs -and (Get-AnyExLaunchRuntimeFeatureEnabled))
    $resolvedSourceExefsRoot = ""
    if ($canGenerateExLaunchOutputs) {
        $resolvedSourceExefsRoot = Resolve-RequiredSourceExefsRoot -SourceRomfsRoot $SourceRomfsRoot -SourceExefsRoot $SourceExefsRoot -GameVersion $sourceGameVersion
    } elseif ($hasExplicitSourceExefs) {
        try {
            $resolvedSourceExefsRoot = Resolve-SourceExefsRoot -SourceRomfsRoot $SourceRomfsRoot -SourceExefsRoot $SourceExefsRoot -GameVersion $sourceGameVersion
        } catch {
            $resolvedSourceExefsRoot = ""
        }
    }
    Assert-ValidSourceRomfsForRandomizer -RomfsRoot $SourceRomfsRoot
    $OutputRomfsRoot = Resolve-OutputRomfsRoot -OutputPath $OutputRomfsRoot
    $outputPackageRoot = Get-OutputPackageRoot -OutputRomfsRoot $OutputRomfsRoot

    $resolvedSeed = Resolve-SeedValue -SeedValue $Seed
    $rng = [System.Random]::new($resolvedSeed)
    $selectedExpLevelCapMode = [string](Get-SelectedExpLevelCapMode)
    $effectiveMainStorySoftLevelCap = $selectedExpLevelCapMode -eq "storyMainProgressionSoft"
    $effectiveGymLeagueStoryLevelCap = $selectedExpLevelCapMode -eq "storyGymLeague"
    $effectiveStoryMajorBattleOrderLevelCap = $selectedExpLevelCapMode -eq "storyOrderedMajorBattles"
    $effectiveStrictBossMaxLevelCap = $selectedExpLevelCapMode -eq "strictBossMaxLevel"
    $bossTeamsToSixTargetCatalog = if ([bool]$ForceBossTeamsToSix) { Convert-ToObjectArray (Get-BossTrainerTargetCatalog -Scope $BossTeamsToSixScope -GameVersionValue $sourceGameVersion) } else { @() }
    # Catalogues de classement des dresseurs, utilises par les regles speciales.
    # Ils ne sont construits que si une regle en a besoin : leur calcul lit les
    # fichiers de dresseurs.
    # Les catalogues sont necessaires des qu'un "Pokemon en plus" est demande,
    # meme pour la seule classe Normal : sans eux, tous les dresseurs seraient
    # classes Normal et les boss recevraient le bonus destine aux autres.
    $trainerRulesNeedCatalogs = ((Normalize-TrainerLegendaryPolicy -Policy $TrainerLegendaryPolicy) -ne "unchanged") -or
        ([int]$TrainerMinBaseStatTotal -gt 0) -or
        ([int]$TrainerExtraPokemonBoss -gt 0) -or
        ([int]$TrainerExtraPokemonImportant -gt 0) -or
        ([int]$TrainerExtraPokemonRegular -gt 0) -or
        ((Normalize-Mode $TrainerForceDiverseTypes) -notin @("off", "", "unchanged", "none"))
    $gymLeagueRuleTargetCatalog = if ($trainerRulesNeedCatalogs) { Convert-ToObjectArray (Get-BossTrainerTargetCatalog -Scope "GymLeague" -GameVersionValue $sourceGameVersion) } else { @() }
    $majorBossRuleTargetCatalog = if ($trainerRulesNeedCatalogs) { Convert-ToObjectArray (Get-BossTrainerTargetCatalog -Scope "MajorBosses" -GameVersionValue $sourceGameVersion) } else { @() }
    $storyMajorBattleTargetCatalog = if ($effectiveStoryMajorBattleOrderLevelCap) { Get-StoryMajorBattleTargetCatalog -SourceRomfsRoot $SourceRomfsRoot } else { @() }
    $teamMaxNormalizationMode = if ($effectiveStoryMajorBattleOrderLevelCap) { "storyOrderedMajorBattles" } elseif ($effectiveStrictBossMaxLevelCap) { "strictBossMaxLevel" } else { "none" }
    $teamMaxNormalizationTargetCatalog = if ($effectiveStoryMajorBattleOrderLevelCap) { $storyMajorBattleTargetCatalog } elseif ($effectiveStrictBossMaxLevelCap) { Convert-ToObjectArray (Get-BossTrainerTargetCatalog) } else { @() }
    if (-not $SkipInitialCopy.IsPresent) {
        Write-RandomizerProgress -Message "[Step] Sync selective du romfs" -ProgressCallback $ProgressCallback
        Sync-RequiredRomfsAssets -SourceRoot $SourceRomfsRoot -OutputRoot $OutputRomfsRoot
    }

    Write-RandomizerProgress -Message "[Step] Randomisation des données Pokémon" -ProgressCallback $ProgressCallback
    $personalExpMultiplier = if (Get-RuntimeExpMultiplierEnabled) { 1.0 } else { $ExpYieldMultiplier }
    $personalResult = Invoke-PersonalRandomization `
        -RomfsRoot $OutputRomfsRoot `
        -Rng $rng `
        -TypeModeValue $TypeMode `
        -TypesMonotype $TypesMonotypeOnly.IsPresent `
        -AbilityModeValue $AbilityMode `
        -AllowWonderGuardValue $AllowWonderGuard.IsPresent `
        -StatModeValue $StatMode `
        -ExpMultiplierValue $personalExpMultiplier `
        -ForceOneExpYieldValue $ForceOneExpYield.IsPresent

    # Apres la randomisation principale : elle reecrit le fichier, ces reglages
    # doivent donc s'appliquer par-dessus.
    $personalTweakResult = Invoke-PersonalExtraTweaks `
        -RomfsRoot $OutputRomfsRoot `
        -Rng $rng `
        -MinimumCatchRateValue $MinimumCatchRate `
        -DoRandomizeHeldItems $RandomizeWildHeldItems.IsPresent `
        -ExpCurveModeValue $ExpCurveMode `
        -TmCompatibilityModeValue $TmCompatibilityMode `
        -TutorCompatibilityModeValue $TutorCompatibilityMode `
        -SourceRomfsRootValue $SourceRomfsRoot
    if (($personalTweakResult.CatchRates + $personalTweakResult.HeldItems + $personalTweakResult.ExpCurves + $personalTweakResult.MachineFlags + $personalTweakResult.TutorFlags) -gt 0) {
        Write-RandomizerProgress -Message ("[Pokemon] captures {0}, objets tenus {1}, courbes EXP {2}, bits CT/DT {3}, bits maitres {4}" -f $personalTweakResult.CatchRates, $personalTweakResult.HeldItems, $personalTweakResult.ExpCurves, $personalTweakResult.MachineFlags, $personalTweakResult.TutorFlags) -ProgressCallback $ProgressCallback
    } elseif ($personalTweakResult.Skipped) {
        Write-RandomizerProgress -Message ("[Pokemon] reglages non appliques : {0}" -f $personalTweakResult.Skipped) -ProgressCallback $ProgressCallback
    }

    $giftItemResult = Invoke-NpcGiftItemRandomization `
        -RomfsRoot $OutputRomfsRoot -Rng $rng -Mode $NpcGiftItemMode
    if ($giftItemResult.Modifies -gt 0) {
        Write-RandomizerProgress -Message ("[Cadeaux PNJ] {0} cadeaux changes dans {1} scripts, {2} objets clés protégés" -f $giftItemResult.Modifies, $giftItemResult.Fichiers, $giftItemResult.Proteges) -ProgressCallback $ProgressCallback
    } elseif ($giftItemResult.Ignore) {
        Write-RandomizerProgress -Message ("[Cadeaux PNJ] non applique : {0}" -f $giftItemResult.Ignore) -ProgressCallback $ProgressCallback
    }

    $learnsetResult = Invoke-LearnsetRandomization `
        -RomfsRoot $OutputRomfsRoot -Rng $rng -Mode $LearnsetMoveMode -SourceRomfsRootValue $SourceRomfsRoot
    if ($learnsetResult.Attaques -gt 0) {
        Write-RandomizerProgress -Message ("[Attaques apprises] {0} attaques changees sur {1} espèces" -f $learnsetResult.Attaques, $learnsetResult.Especes) -ProgressCallback $ProgressCallback
    } elseif ($learnsetResult.Ignore) {
        Write-RandomizerProgress -Message ("[Attaques apprises] non applique : {0}" -f $learnsetResult.Ignore) -ProgressCallback $ProgressCallback
    }

    $machineMoveResult = Invoke-MachineMoveRandomization `
        -RomfsRoot $OutputRomfsRoot -Rng $rng -Mode $TmMoveMode
    if ($machineMoveResult.Modifiees -gt 0) {
        Write-RandomizerProgress -Message ("[CT/DT] {0} machines sur {1} enseignent une autre attaque" -f $machineMoveResult.Modifiees, $machineMoveResult.Total) -ProgressCallback $ProgressCallback
    } elseif ($machineMoveResult.Ignore) {
        Write-RandomizerProgress -Message ("[CT/DT] non applique : {0}" -f $machineMoveResult.Ignore) -ProgressCallback $ProgressCallback
    }

    # Doit passer apres la randomisation des types et talents, pour recopier le
    # resultat du tirage le long des familles.
    $followEvoResult = Invoke-PersonalFollowEvolutions `
        -RomfsRoot $OutputRomfsRoot `
        -SourceRomfsRoot $SourceRomfsRoot `
        -DoTypes ($FollowEvolutionsForTypes.IsPresent -and (Normalize-Mode $TypeMode) -ne "unchanged") `
        -DoAbilities ($FollowEvolutionsForAbilities.IsPresent -and (Normalize-Mode $AbilityMode) -ne "unchanged")
    if ($followEvoResult.Propagated -gt 0) {
        Write-RandomizerProgress -Message ("[Pokémon] familles : {0} évolutions alignees sur leur forme de base" -f $followEvoResult.Propagated) -ProgressCallback $ProgressCallback
    } elseif ($followEvoResult.Skipped) {
        Write-RandomizerProgress -Message ("[Pokemon] familles non alignees : {0}" -f $followEvoResult.Skipped) -ProgressCallback $ProgressCallback
    }

    Write-RandomizerProgress -Message "[Step] Randomisation des attaques globales" -ProgressCallback $ProgressCallback
    $moveDataResult = Invoke-MoveDataRandomization `
        -RomfsRoot $OutputRomfsRoot `
        -Rng $rng `
        -DoRandomizeTypes $RandomizeMoveTypes.IsPresent `
        -DoRandomizePower $RandomizeMovePower.IsPresent `
        -PowerMin $MovePowerMin `
        -PowerMax $MovePowerMax `
        -DoRandomizePP $RandomizeMovePP.IsPresent `
        -PPMin $MovePPMin `
        -PPMax $MovePPMax `
        -DoRandomizeAccuracy $RandomizeMoveAccuracy.IsPresent `
        -AccuracyMin $MoveAccuracyMin `
        -AccuracyMax $MoveAccuracyMax `
        -DoRandomizeCategory $RandomizeMoveCategory.IsPresent

    Write-RandomizerProgress -Message "[Step] Randomisation des objets / boutiques / CT-TR" -ProgressCallback $ProgressCallback
    $itemTableResult = Invoke-ItemTableRandomization `
        -RomfsRoot $OutputRomfsRoot `
        -Rng $rng

    $fieldItemResult = Invoke-FieldItemRandomization `
        -RomfsRoot $OutputRomfsRoot `
        -Rng $rng `
        -DoGroundItems $RandomizeFieldItems.IsPresent `
        -DoHiddenItems $RandomizeHiddenItems.IsPresent `
        -PoolMode $FieldItemPoolMode
    if (($fieldItemResult.GroundEdited + $fieldItemResult.HiddenEdited) -gt 0) {
        Write-RandomizerProgress -Message ("[Items] terrain : {0} objets au sol, {1} objets caches" -f $fieldItemResult.GroundEdited, $fieldItemResult.HiddenEdited) -ProgressCallback $ProgressCallback
    } elseif ($fieldItemResult.Skipped) {
        Write-RandomizerProgress -Message ("[Items] terrain non modifie : {0}" -f $fieldItemResult.Skipped) -ProgressCallback $ProgressCallback
    }

    $bornesPrix = Get-ShopPriceBounds
    $modePrix = Get-ShopPriceModeValue
    $itemPriceResult = Invoke-ItemPriceAdjustment `
        -RomfsRoot $OutputRomfsRoot `
        -Multiplier (Get-ShopPriceMultiplierValue) `
        -Mode $modePrix `
        -MinPrice $bornesPrix.Min `
        -MaxPrice $bornesPrix.Max `
        -Rng $rng
    if ($itemPriceResult.Edited -gt 0) {
        $detailPrix = if ($modePrix -eq "random") {
            "{0} a {1} P" -f $bornesPrix.Min, $bornesPrix.Max
        } else {
            "x{0}" -f (Get-ShopPriceMultiplierValue)
        }
        Write-RandomizerProgress -Message ("[Items] prix ajustes sur {0} objets ({1})" -f $itemPriceResult.Edited, $detailPrix) -ProgressCallback $ProgressCallback
    } elseif ($itemPriceResult.Skipped -and $modePrix -ne "vanilla") {
        Write-RandomizerProgress -Message ("[Items] prix non modifies : {0}" -f $itemPriceResult.Skipped) -ProgressCallback $ProgressCallback
    }

    Write-RandomizerProgress -Message "[Step] Randomisation des dresseurs" -ProgressCallback $ProgressCallback
    $trainerResult = Invoke-TrainerRandomization `
        -RomfsRoot $OutputRomfsRoot `
        -Rng $rng `
        -SpeciesModeValue $TrainerSpeciesMode `
        -MoveModeValue $TrainerMoveMode `
        -SmogonMoveFallbackModeValue $TrainerSmogonMoveFallbackMode `
        -ItemModeValue $TrainerItemMode `
        -ItemPoolModeValue $TrainerItemPoolMode `
        -AddedSlotSpeciesModeValue $TrainerAddedSlotSpeciesMode `
        -DuplicateModeValue $TrainerDuplicateMode `
        -BagItemModeValue $TrainerBagItemMode `
        -AbilityModeValue $TrainerAbilityMode `
        -IVModeValue $TrainerIVMode `
        -EVModeValue $TrainerEVMode `
        -NatureModeValue $TrainerNatureMode `
        -DoRandomizeNatures $RandomizeTrainerNatures.IsPresent `
        -LevelMultiplier $TrainerLevelMultiplier `
        -TeamMin $TrainerTeamMin `
        -TeamMax $TrainerTeamMax `
        -DoTypeThemedTeams $TrainerTypeThemed.IsPresent `
        -ShinyChancePercent $TrainerShinyChancePercent `
        -DoForceFullyEvolved $ForceTrainerFullyEvolved.IsPresent `
        -FullyEvolvedLevel $TrainerFullyEvolvedLevel `
        -DoMaxTrainerAI $MaxTrainerAI.IsPresent `
        -DynamaxLevelModeValue $TrainerDynamaxLevelMode `
        -DoForceCanDynamax $ForceTrainerCanDynamax.IsPresent `
        -DoForceAllTeamsToSix $ForceAllTeamsToSix.IsPresent `
        -BossTeamsToSixTargetCatalog $bossTeamsToSixTargetCatalog `
        -TeamMaxNormalizationTargetCatalog $teamMaxNormalizationTargetCatalog `
        -TeamMaxNormalizationMode $teamMaxNormalizationMode `
        -AllowLegendarySpecies $AllowLegendaryTrainers.IsPresent `
        -GymLeagueRuleTargetCatalog $gymLeagueRuleTargetCatalog `
        -MajorBossRuleTargetCatalog $majorBossRuleTargetCatalog `
        -ExtraPokemonBoss $TrainerExtraPokemonBoss `
        -ExtraPokemonImportant $TrainerExtraPokemonImportant `
        -ExtraPokemonRegular $TrainerExtraPokemonRegular `
        -SpecialRuleScopeValue $TrainerSpecialRuleScope `
        -LegendaryPolicyValue $TrainerLegendaryPolicy `
        -MinBaseStatTotalValue $TrainerMinBaseStatTotal `
        -ForceDiverseTypesScopeValue $TrainerForceDiverseTypes `
        -ProgressCallback $ProgressCallback

    Write-RandomizerProgress -Message "[Step] Randomisation des évolutions" -ProgressCallback $ProgressCallback
    $evoEdits = Invoke-EvolutionRandomization `
        -RomfsRoot $OutputRomfsRoot `
        -Rng $rng `
        -ModeValue $EvolutionMode `
        -AllowLegendarySpecies $AllowLegendaryEvolutions.IsPresent `
        -DoNormalizeFriendship $NormalizeFriendshipEvolutions `
        -FriendshipLevel $FriendshipEvolutionLevel `
        -DoNormalizeTrade $NormalizeTradeEvolutions `
        -TradeLevel $TradeEvolutionLevel `
        -DoNormalizeSpecial $NormalizeSpecialEvolutions `
        -SpecialLevel $SpecialEvolutionLevel `
        -DoForceGrowth $EvolutionForceGrowth.IsPresent `
        -DoSameType $EvolutionSameType.IsPresent `
        -MinBstGain $EvolutionMinBstGain

    # Apres la randomisation : c'est la chaine finale qu'on borne.
    if ($EvolutionLimitToThreeStages.IsPresent) {
        $chainLimitResult = Invoke-EvolutionChainLimit -RomfsRoot $OutputRomfsRoot -MaxStages 3
        if ($chainLimitResult.Removed -gt 0) {
            Write-RandomizerProgress -Message ("[Évolutions] {0} évolutions retirees au-dela du 3e stade" -f $chainLimitResult.Removed) -ProgressCallback $ProgressCallback
        } elseif ($chainLimitResult.Skipped) {
            Write-RandomizerProgress -Message ("[Evolutions] chaines non bornees : {0}" -f $chainLimitResult.Skipped) -ProgressCallback $ProgressCallback
        }
    }

    Write-RandomizerProgress -Message "[Step] Randomisation des gifts et rencontres scriptes" -ProgressCallback $ProgressCallback
    $giftEncounterResult = Invoke-GiftAndEncounterRandomization `
        -RomfsRoot $OutputRomfsRoot `
        -Rng $rng `
        -GiftModeValue $GiftMode `
        -StarterModeValue $StarterMode `
        -StarterMinBaseStatTotalValue $StarterMinBaseStatTotal `
        -StarterMaxBaseStatTotalValue $StarterMaxBaseStatTotal `
        -AllowLegendaryGiftSpecies $AllowLegendaryGifts.IsPresent `
        -TradeModeValue $TradeMode `
        -AllowLegendaryTradeSpecies $AllowLegendaryTrades.IsPresent `
        -StaticEncounterModeValue $StaticEncounterMode `
        -AllowLegendaryStaticSpecies $AllowLegendaryStaticEncounters.IsPresent `
        -StaticEncounterStableMapping $StaticEncounterStableMapping `
        -GrassEncounterModeValue $GrassEncounterMode `
        -AllowLegendaryGrassSpecies $AllowLegendaryGrassEncounters.IsPresent `
        -GrassEncounterStableMapping $GrassEncounterStableMapping `
        -VisibleEncounterBehaviorValue $VisibleEncounterBehavior `
        -EncounterDrawModeValue $EncounterDrawMode `
        -UndergroundModeValue $UndergroundMode `
        -AllowLegendaryUndergroundSpecies $AllowLegendaryUnderground.IsPresent

    $starterRelatedTrainerPatchResult = [pscustomobject]@{
        FilesEdited = 0
        SlotsEdited = 0
        Changes = @()
    }
    $configuredStarters = Get-ConfiguredStarterSpeciesIds
    $starterSpeciesForTrainerPatch = if (@($configuredStarters).Count -eq 3) {
        $configuredStarters
    } elseif (@($giftEncounterResult.StarterSpeciesIds).Count -eq 3) {
        [int[]]$giftEncounterResult.StarterSpeciesIds
    } else {
        $null
    }
    if ($PatchStarterRelatedTrainers -and @($starterSpeciesForTrainerPatch).Count -eq 3) {
        Write-RandomizerProgress -Message "[Step] Patch des starters visibles chez les dresseurs lies au choix initial" -ProgressCallback $ProgressCallback
        $starterRelatedTrainerPatchResult = Update-StarterRelatedTrainerTeams -RomfsRoot $OutputRomfsRoot -StarterSpeciesIds $starterSpeciesForTrainerPatch -TrainerMoveMode $TrainerMoveMode -TrainerSmogonMoveFallbackMode $TrainerSmogonMoveFallbackMode -Rng $rng
    }
    $sourceOnlyMoveDataPruned = Remove-SourceOnlyMoveDataFromOutput -OutputRomfsRoot $OutputRomfsRoot -MoveDataResult $moveDataResult
    if ($sourceOnlyMoveDataPruned) {
        Write-RandomizerProgress -Message "[Step] Nettoyage: suppression des donnees moves source-only non modifiees" -ProgressCallback $ProgressCallback
    }
    $mainStorySoftCaps = @()
    if ($effectiveMainStorySoftLevelCap) {
        Write-RandomizerProgress -Message "[Step] Calcul des caps progression principale souple" -ProgressCallback $ProgressCallback
        $mainStorySoftCaps = Get-MainStorySoftCapEntries -SourceRomfsRoot $SourceRomfsRoot -OutputRomfsRoot $OutputRomfsRoot
    }
    $storyGymLeagueCaps = @()
    if ($effectiveGymLeagueStoryLevelCap) {
        Write-RandomizerProgress -Message "[Step] Calcul des caps histoire arènes / champion" -ProgressCallback $ProgressCallback
        $storyGymLeagueCaps = Get-GymLeagueStoryCapEntries -SourceRomfsRoot $SourceRomfsRoot -OutputRomfsRoot $OutputRomfsRoot
    }
    $storyMajorBattleCaps = @()
    if ($effectiveStoryMajorBattleOrderLevelCap) {
        Write-RandomizerProgress -Message "[Step] Calcul des caps histoire majeurs ordonnes" -ProgressCallback $ProgressCallback
        $storyMajorBattleCaps = Get-StoryMajorBattleCapEntries -SourceRomfsRoot $SourceRomfsRoot -OutputRomfsRoot $OutputRomfsRoot
    }
    if ($canGenerateExLaunchOutputs) {
        Write-RandomizerProgress -Message "[Step] Options EXP runtime: ExLaunch requis, pas d'IPS brut écrit" -ProgressCallback $ProgressCallback
    } elseif (Get-AnyExLaunchRuntimeFeatureEnabled) {
        Write-RandomizerProgress -Message "[Step] Options runtime detectees mais aucun ExeFS explicite n'est fourni: génération ROMFS-only, ExLaunch ignore" -ProgressCallback $ProgressCallback
    }
    $exefsPatchResult = [pscustomobject]@{
        Enabled = $false
        PatchRoot = (Join-Path $outputPackageRoot "exefs")
        FilesWritten = 0
        DisableExpShareEnabled = $false
        DynamicExpLevelCapEnabled = $false
        StoryGymLeagueExpCapEnabled = $false
        ExpLevelCapRequiresExLaunch = $false
        Patches = @()
    }
    $expLevelCapExLaunchConfigPath = ""
    if ($canGenerateExLaunchOutputs) {
        $exefsPatchResult = Write-ExeFsPatches -OutputRomfsRoot $OutputRomfsRoot -GymLeagueStoryCaps $storyGymLeagueCaps
        $expLevelCapExLaunchConfigPath = Write-ExpLevelCapExLaunchConfig -OutputRomfsRoot $OutputRomfsRoot -MainStorySoftCaps $mainStorySoftCaps -GymLeagueStoryCaps $storyGymLeagueCaps
    } else {
        $staleExefsRoot = Join-Path $outputPackageRoot "exefs"
        $staleSdmcRoot = Join-Path $outputPackageRoot "sdmc"
        if (Test-Path -LiteralPath $staleExefsRoot) {
            Remove-Item -LiteralPath $staleExefsRoot -Recurse -Force
        }
        if (Test-Path -LiteralPath $staleSdmcRoot) {
            Remove-Item -LiteralPath $staleSdmcRoot -Recurse -Force
        }
    }
    $exLaunchModuleDeployment = [pscustomobject]@{
        Requested = $false
        Available = $false
        Deployed = $false
        RuntimePcControlsEnabled = (Get-RandomizerPcMenuEnabled)
        RuntimePcScriptApplied = $false
        GameVersion = $sourceGameVersion
        TitleId = Get-GameTitleId -GameVersion $sourceGameVersion
        SourceRoot = ""
        SubsdkSourceRoot = ""
        TargetRoot = ""
        MainNpdmPath = ""
        Subsdk9Path = ""
        MissingFiles = @()
    }
    if ($canGenerateExLaunchOutputs -and [bool]$exefsPatchResult.ExpLevelCapRequiresExLaunch) {
        Write-RandomizerProgress -Message "[Step] Deploiement auto du module ExLaunch" -ProgressCallback $ProgressCallback
        $exLaunchModuleDeployment = Deploy-ExLaunchModule -SourceRomfsRoot $SourceRomfsRoot -SourceExefsRoot $resolvedSourceExefsRoot -OutputRomfsRoot $OutputRomfsRoot -GameVersion $sourceGameVersion -RuntimePcControlsEnabled (Get-RandomizerPcMenuEnabled) -EarlyBikeEnabled ([bool]$EarlyBike) -DexAnimationsEnabled ([bool]$ModDexAnimations)
        if ($exLaunchModuleDeployment.Deployed) {
            Write-RandomizerProgress -Message ("[ExLaunch] Module {0} deploye dans {1}" -f $exLaunchModuleDeployment.GameVersion, $exLaunchModuleDeployment.TargetRoot) -ProgressCallback $ProgressCallback
        } elseif (-not $exLaunchModuleDeployment.Available) {
            $missingSummary = @($exLaunchModuleDeployment.MissingFiles | ForEach-Object { Split-Path -Leaf $_ }) -join ", "
            Write-RandomizerProgress -Message ("[ExLaunch] Build introuvable pour {0}: {1}" -f $exLaunchModuleDeployment.GameVersion, $missingSummary) -ProgressCallback $ProgressCallback
        }
    }
    $bossLevelCaps = Convert-ToObjectArray (Get-BossLevelCapEntries -RomfsRoot $OutputRomfsRoot)
    $mainStorySoftCapArray = Convert-ToObjectArray $mainStorySoftCaps
    $storyGymLeagueCapArray = Convert-ToObjectArray $storyGymLeagueCaps
    $storyMajorBattleCapArray = Convert-ToObjectArray $storyMajorBattleCaps
    $trainerBossTargetsArray = Convert-ToObjectArray $trainerResult.BossTrainerTargets
    $trainerChangesArray = Convert-ToObjectArray $trainerResult.TrainerChanges
    $starterPatchChangesArray = Convert-ToObjectArray $starterRelatedTrainerPatchResult.Changes
    $wildEncounterChangesArray = Convert-ToObjectArray $giftEncounterResult.WildEncounterChanges
    $itemChangesArray = Convert-ToObjectArray $itemTableResult.Changes
    $exefsPatchArray = Convert-ToObjectArray $exefsPatchResult.Patches
    $disableExpSharePatchArray = Convert-ToObjectArray ($exefsPatchArray | Where-Object { $_.feature -eq "disableExpShare" })
    $dynamicExpLevelCapPatchArray = Convert-ToObjectArray ($exefsPatchArray | Where-Object { $_.feature -eq "dynamicExpLevelCap" })
    $storyGymLeagueExpCapPatchArray = Convert-ToObjectArray ($exefsPatchArray | Where-Object { $_.feature -eq "storyGymLeagueExpCap" })
    $disableExpSharePatchFileCount = @($disableExpSharePatchArray | Select-Object -ExpandProperty file -Unique).Count
    $dynamicExpLevelCapPatchFileCount = @($dynamicExpLevelCapPatchArray | Select-Object -ExpandProperty file -Unique).Count
    $storyGymLeagueExpCapPatchFileCount = @($storyGymLeagueExpCapPatchArray | Select-Object -ExpandProperty file -Unique).Count
    $starterSpeciesForTrainerPatchArray = if (@($starterSpeciesForTrainerPatch).Count -gt 0) { [int[]]$starterSpeciesForTrainerPatch } else { @() }
    $rootRomfsReportsMoved = Move-RootRomfsReportsToReports -OutputRomfsRoot $OutputRomfsRoot
    $result = [pscustomobject]@{
        Seed = $resolvedSeed
        SourceExefsRoot = $resolvedSourceExefsRoot
        Output = $outputPackageRoot
        OutputPackageRoot = $outputPackageRoot
        OutputRomfsRoot = $OutputRomfsRoot
        OutputReportsRoot = Get-OutputReportsRoot -OutputRomfsRoot $OutputRomfsRoot
        RootRomfsReportsMoved = $rootRomfsReportsMoved
        PersonalEntriesEdited = $personalResult.PersonalEntriesEdited
        ExpYieldsEdited = $personalResult.ExpYieldsEdited
        MovesEdited = $moveDataResult.MovesEdited
        MoveTypesEdited = $moveDataResult.MoveTypesEdited
        MovePowersEdited = $moveDataResult.MovePowersEdited
        MovePPEdited = $moveDataResult.MovePPEdited
        MoveAccuracyEdited = $moveDataResult.MoveAccuracyEdited
        MoveCategoriesEdited = $moveDataResult.MoveCategoriesEdited
        SourceOnlyMoveDataPruned = [bool]$sourceOnlyMoveDataPruned
        PickupItemsEdited = $itemTableResult.PickupItemsEdited
        ShopItemsEdited = $itemTableResult.ShopItemsEdited
        TechnicalRecordsEdited = $itemTableResult.TechnicalRecordsEdited
        ItemChangesLogged = Get-ObjectArrayCount $itemChangesArray
        ItemChangesForReports = $itemChangesArray
        ItemChangesReportPath = ""
        ItemRandomizationNotes = @($itemTableResult.Notes)
        TrainersEdited = $trainerResult.Trainers
        TrainerPokemonProcessed = $trainerResult.Pokemon
        BossTeamsExpanded = $trainerResult.BossTeamsExpanded
        BossTeamsLevelNormalized = $trainerResult.BossTeamsLevelNormalized
        TrainerShiniesForced = $trainerResult.ShiniesForced
        TrainerBagItemsEdited = $trainerResult.BagItemsEdited
        TrainerSpeciesForceEvolved = $trainerResult.SpeciesForceEvolved
        TrainerTypeThemedTrainers = $trainerResult.TrainerTypeThemedTrainers
        TrainerAIMaxed = $trainerResult.TrainerAIMaxed
        TrainerDynamaxLevelsEdited = $trainerResult.DynamaxLevelsEdited
        TrainerDynamaxFlagsForced = $trainerResult.DynamaxFlagsForced
        BossTrainerTargets = $trainerBossTargetsArray
        TrainerChangesLogged = Get-ObjectArrayCount $trainerChangesArray
        TrainerChangesForReports = $trainerChangesArray
        TrainerChangesReportPath = ""
        EvolutionsEdited = $evoEdits.EvolutionsEdited
        FriendshipEvolutionsNormalized = $evoEdits.FriendshipNormalized
        TradeEvolutionsNormalized = $evoEdits.TradeNormalized
        SpecialEvolutionsNormalized = $evoEdits.SpecialNormalized
        GiftsEdited = $giftEncounterResult.Gifts
        StartersEdited = $giftEncounterResult.Starters
        StarterSpeciesIds = $starterSpeciesForTrainerPatchArray
        StarterRelatedTrainerFilesEdited = $starterRelatedTrainerPatchResult.FilesEdited
        StarterRelatedTrainerSlotsEdited = $starterRelatedTrainerPatchResult.SlotsEdited
        StarterRelatedTrainerPatchChanges = $starterPatchChangesArray
        TradeSpeciesSlotsEdited = $giftEncounterResult.TradeSpeciesSlots
        StaticEncountersEdited = $giftEncounterResult.StaticEncounters
        GrassEncounterSlotsEdited = $giftEncounterResult.GrassEncounterSlots
        UndergroundSpeciesSlotsEdited = $giftEncounterResult.UndergroundSpeciesSlots
        WildChangesLogged = Get-ObjectArrayCount $wildEncounterChangesArray
        WildChangesForReports = $wildEncounterChangesArray
        WildChangesReportPath = ""
        EncounterZoneReportPath = ""
        SeedSummaryReportPath = ""
        SpoilerLogReportPath = ""
        BossLevelCapsLogged = Get-ObjectArrayCount $bossLevelCaps
        BossLevelCaps = $bossLevelCaps
        BossLevelCapsReportPath = ""
        MainStorySoftCapsLogged = Get-ObjectArrayCount $mainStorySoftCapArray
        MainStorySoftCaps = $mainStorySoftCapArray
        MainStorySoftCapsReportPath = ""
        StoryGymLeagueCapsLogged = Get-ObjectArrayCount $storyGymLeagueCapArray
        StoryGymLeagueCaps = $storyGymLeagueCapArray
        StoryGymLeagueCapsReportPath = ""
        StoryMajorBattleCapsLogged = Get-ObjectArrayCount $storyMajorBattleCapArray
        StoryMajorBattleCaps = $storyMajorBattleCapArray
        StoryMajorBattleCapsReportPath = ""
        ExeFsPatchEnabled = $exefsPatchResult.Enabled
        ExeFsPatchRoot = $exefsPatchResult.PatchRoot
        ExeFsPatchFilesWritten = $exefsPatchResult.FilesWritten
        ExeFsPatches = $exefsPatchArray
        DisableExpSharePatchEnabled = $exefsPatchResult.DisableExpShareEnabled
        DisableExpSharePatchRoot = $exefsPatchResult.PatchRoot
        DisableExpSharePatchFilesWritten = $disableExpSharePatchFileCount
        DisableExpSharePatches = $disableExpSharePatchArray
        DynamicExpLevelCapPatchEnabled = $exefsPatchResult.DynamicExpLevelCapEnabled
        DynamicExpLevelCapPatchRoot = $exefsPatchResult.PatchRoot
        DynamicExpLevelCapPatchFilesWritten = $dynamicExpLevelCapPatchFileCount
        DynamicExpLevelCapPatches = $dynamicExpLevelCapPatchArray
        StoryGymLeagueExpCapPatchEnabled = $exefsPatchResult.StoryGymLeagueExpCapEnabled
        StoryGymLeagueExpCapPatchRoot = $exefsPatchResult.PatchRoot
        StoryGymLeagueExpCapPatchFilesWritten = $storyGymLeagueExpCapPatchFileCount
        StoryGymLeagueExpCapPatches = $storyGymLeagueExpCapPatchArray
        ExpLevelCapRequiresExLaunch = $exefsPatchResult.ExpLevelCapRequiresExLaunch
        ExpLevelCapExLaunchConfigPath = $expLevelCapExLaunchConfigPath
        ExLaunchModuleRequested = $exLaunchModuleDeployment.Requested
        ExLaunchModuleAvailable = $exLaunchModuleDeployment.Available
        ExLaunchModuleDeployed = $exLaunchModuleDeployment.Deployed
        RuntimePcControlsEnabled = $exLaunchModuleDeployment.RuntimePcControlsEnabled
        RuntimePcScriptApplied = $exLaunchModuleDeployment.RuntimePcScriptApplied
        ExLaunchModuleGameVersion = $exLaunchModuleDeployment.GameVersion
        ExLaunchModuleTitleId = $exLaunchModuleDeployment.TitleId
        ExLaunchModuleSourceRoot = $exLaunchModuleDeployment.SourceRoot
        ExLaunchModuleSubsdkSourceRoot = $exLaunchModuleDeployment.SubsdkSourceRoot
        ExLaunchModuleTargetRoot = $exLaunchModuleDeployment.TargetRoot
        ExLaunchModuleMainNpdmPath = $exLaunchModuleDeployment.MainNpdmPath
        ExLaunchModuleSubsdk9Path = $exLaunchModuleDeployment.Subsdk9Path
        ExLaunchVariantManifestPath = if ($exLaunchModuleDeployment.PSObject.Properties.Name -contains "VariantManifestPath") { $exLaunchModuleDeployment.VariantManifestPath } else { "" }
        ExLaunchModuleMissingFiles = @($exLaunchModuleDeployment.MissingFiles)
        InstallationPackageRoot = ""
        InstallationPackageReadmePath = ""
        InstallationTargets = @()
        AutoInstallRequested = [bool]$AutoInstallToEden
        AutoInstallRequestedTargetKeys = @(Get-RequestedEmulatorKeys)
        AutoInstallSuccessCount = 0
        AutoInstallFailureCount = 0
        AutoInstallResults = @()
        EdenAutoInstallRequested = [bool]$AutoInstallToEden
        EdenAutoInstallCompleted = $false
        EdenAutoInstallGameVersion = $sourceGameVersion
        EdenAutoInstallTitleId = Get-GameTitleId -GameVersion $sourceGameVersion
        EdenAutoInstallModName = Get-NormalizedModName -ModName $EdenModName
        EdenAutoInstallPackageRoot = $outputPackageRoot
        EdenAutoInstallModRoot = ""
        EdenAutoInstallSdmcRoot = ""
        EdenAutoInstallSdmcConfigPath = ""
        EdenAutoInstallAlreadyAtTarget = $false
        EdenAutoInstallRemovedExistingMod = $false
        EdenAutoInstallRemovedExistingSdmcPaths = @()
        EdenAutoInstallCopiedRomfs = $false
        EdenAutoInstallCopiedExefs = $false
        EdenAutoInstallCopiedSdmc = $false
        EdenAutoInstallError = ""
    }

    $trainerChangesPath = Write-TrainerChangesReport -TrainerChanges $trainerResult.TrainerChanges -OutputRomfsRoot $OutputRomfsRoot -ResolvedSeed $resolvedSeed -BossTrainerTargets $result.BossTrainerTargets
    if ($trainerChangesPath) {
        $result.TrainerChangesReportPath = $trainerChangesPath
    }

    $wildChangesPath = Write-WildChangesReport -WildChanges $giftEncounterResult.WildEncounterChanges -OutputRomfsRoot $OutputRomfsRoot -ResolvedSeed $resolvedSeed
    if ($wildChangesPath) {
        $result.WildChangesReportPath = $wildChangesPath
    }

    $allItemChanges = @($itemTableResult.Changes) + @($fieldItemResult.Changes)
    $itemChangesPath = Write-ItemChangesReport -ItemChanges $allItemChanges -OutputRomfsRoot $OutputRomfsRoot -ResolvedSeed $resolvedSeed -Notes $result.ItemRandomizationNotes
    if ($itemChangesPath) {
        $result.ItemChangesReportPath = $itemChangesPath
    }

    $encounterZonePath = Write-EncounterZoneReport -WildChanges $giftEncounterResult.WildEncounterChanges -OutputRomfsRoot $OutputRomfsRoot -ResolvedSeed $resolvedSeed
    if ($encounterZonePath) {
        $result.EncounterZoneReportPath = $encounterZonePath
    }

    $levelCapsPath = Write-LevelCapsReport -LevelCaps $result.BossLevelCaps -OutputRomfsRoot $OutputRomfsRoot -ResolvedSeed $resolvedSeed
    if ($levelCapsPath) {
        $result.BossLevelCapsReportPath = $levelCapsPath
    }

    $mainStorySoftCapsPath = Write-MainStorySoftCapsReport -StoryCaps $result.MainStorySoftCaps -OutputRomfsRoot $OutputRomfsRoot -ResolvedSeed $resolvedSeed
    if ($mainStorySoftCapsPath) {
        $result.MainStorySoftCapsReportPath = $mainStorySoftCapsPath
    }

    $storyGymLeagueCapsPath = Write-StoryGymLeagueCapsReport -StoryCaps $result.StoryGymLeagueCaps -OutputRomfsRoot $OutputRomfsRoot -ResolvedSeed $resolvedSeed
    if ($storyGymLeagueCapsPath) {
        $result.StoryGymLeagueCapsReportPath = $storyGymLeagueCapsPath
    }

    $storyMajorBattleCapsPath = Write-StoryMajorBattleCapsReport -StoryCaps $result.StoryMajorBattleCaps -OutputRomfsRoot $OutputRomfsRoot -ResolvedSeed $resolvedSeed
    if ($storyMajorBattleCapsPath) {
        $result.StoryMajorBattleCapsReportPath = $storyMajorBattleCapsPath
    }

    $seedReports = Write-SeedAndSpoilerReports -Result $result -OutputRomfsRoot $OutputRomfsRoot
    $result.SeedSummaryReportPath = [string]$seedReports.SeedSummaryPath
    $result.SpoilerLogReportPath = [string]$seedReports.SpoilerLogPath

    if ($WriteInstallationPackage) {
        Write-RandomizerProgress -Message "[Step] Preparation du dossier Installation" -ProgressCallback $ProgressCallback
        $installationPackage = Write-InstallationPackage -OutputRomfsRoot $OutputRomfsRoot -GameVersion $sourceGameVersion -ModName $EdenModName
        $result.InstallationPackageRoot = $installationPackage.Root
        $result.InstallationPackageReadmePath = $installationPackage.ReadmePath
        $result.InstallationTargets = Convert-ToObjectArray $installationPackage.Targets
    } else {
        Write-RandomizerProgress -Message "[Step] Dossier Installation non genere (demande)" -ProgressCallback $ProgressCallback
    }

    if ([bool]$AutoInstallToEden) {
        Write-RandomizerProgress -Message "[Step] Installation auto dans les émulateurs detectes" -ProgressCallback $ProgressCallback
        $autoInstallResults = Convert-ToObjectArray (Install-PackageToSelectedEmulators -OutputRomfsRoot $OutputRomfsRoot -GameVersion $sourceGameVersion -ModName $EdenModName)
        $result.AutoInstallResults = $autoInstallResults
        $result.AutoInstallSuccessCount = @($autoInstallResults | Where-Object { [bool]$_.Installed }).Count
        $result.AutoInstallFailureCount = @($autoInstallResults | Where-Object { -not [bool]$_.Installed }).Count

        foreach ($installResult in $autoInstallResults) {
            if ([bool]$installResult.Installed) {
                $installModeMessage = if ([bool]$installResult.AlreadyAtTarget) {
                    ("[{0}] La sortie est déjà dans le dossier cible, sync sdmc faite" -f [string]$installResult.Emulator)
                } else {
                    ("[{0}] Mod installe dans {1}" -f [string]$installResult.Emulator, [string]$installResult.ModRoot)
                }
                Write-RandomizerProgress -Message $installModeMessage -ProgressCallback $ProgressCallback
            } else {
                $installError = if ([string]::IsNullOrWhiteSpace([string]$installResult.Error)) { "installation incomplete" } else { [string]$installResult.Error }
                Write-RandomizerProgress -Message ("[{0}] Installation auto echouee: {1}" -f [string]$installResult.Emulator, $installError) -ProgressCallback $ProgressCallback
            }
        }

        $edenInstallResult = @($autoInstallResults | Where-Object { ([string]$_.Key) -eq "eden" } | Select-Object -First 1)
        if ($edenInstallResult.Count -gt 0) {
            $edenInstallResult = $edenInstallResult[0]
            $result.EdenAutoInstallCompleted = [bool]$edenInstallResult.Installed
            $result.EdenAutoInstallGameVersion = $sourceGameVersion
            $result.EdenAutoInstallTitleId = $edenInstallResult.TitleId
            $result.EdenAutoInstallModName = $edenInstallResult.ModName
            $result.EdenAutoInstallPackageRoot = $edenInstallResult.PackageRoot
            $result.EdenAutoInstallModRoot = $edenInstallResult.ModRoot
            $result.EdenAutoInstallSdmcRoot = $edenInstallResult.SdmcRoot
            $result.EdenAutoInstallSdmcConfigPath = $edenInstallResult.SdmcConfigPath
            $result.EdenAutoInstallAlreadyAtTarget = [bool]$edenInstallResult.AlreadyAtTarget
            $result.EdenAutoInstallRemovedExistingMod = [bool]$edenInstallResult.RemovedExistingMod
            $result.EdenAutoInstallRemovedExistingSdmcPaths = @($edenInstallResult.RemovedExistingSdmcPaths)
            $result.EdenAutoInstallCopiedRomfs = [bool]$edenInstallResult.CopiedRomfs
            $result.EdenAutoInstallCopiedExefs = [bool]$edenInstallResult.CopiedExefs
            $result.EdenAutoInstallCopiedSdmc = [bool]$edenInstallResult.CopiedSdmc
            $result.EdenAutoInstallError = [string]$edenInstallResult.Error
        }
    }

    $reportPath = Write-RandomizationReport -Result $result -OutputRomfsRoot $OutputRomfsRoot
    if ($reportPath) {
        $result | Add-Member -NotePropertyName "JsonReportPath" -NotePropertyValue $reportPath
        $outputReportsFullPath = [IO.Path]::GetFullPath((Get-OutputReportsRoot -OutputRomfsRoot $OutputRomfsRoot)).TrimEnd('\')
        $reportFullPath = [IO.Path]::GetFullPath($reportPath)
        if ($reportFullPath.StartsWith($outputReportsFullPath, [System.StringComparison]::OrdinalIgnoreCase)) {
            $relativeReportPath = $reportFullPath.Substring($outputReportsFullPath.Length).TrimStart('\')
            $installedAutoInstallResults = @(Convert-ToObjectArray $result.AutoInstallResults | Where-Object { [bool]$_.Installed -and (-not [bool]$_.AlreadyAtTarget) -and (-not [string]::IsNullOrWhiteSpace([string]$_.ModRoot)) })
            foreach ($installResult in $installedAutoInstallResults) {
                $installedReportPath = Join-Path (Join-Path $installResult.ModRoot "reports") $relativeReportPath
                Ensure-ParentDirectory -Path $installedReportPath
                Copy-Item -LiteralPath $reportPath -Destination $installedReportPath -Force
            }

            if (-not [string]::IsNullOrWhiteSpace([string]$result.InstallationPackageRoot)) {
                $installationTargets = @(Convert-ToObjectArray $result.InstallationTargets)
                foreach ($target in $installationTargets) {
                    $targetName = [string]$target.Name
                    $targetRelativeModPath = [string]$target.RelativeModPath
                    if ([string]::IsNullOrWhiteSpace($targetName) -or [string]::IsNullOrWhiteSpace($targetRelativeModPath)) {
                        continue
                    }

                    $installationReportPath = Join-Path (Join-Path (Join-Path ([string]$result.InstallationPackageRoot) $targetName) $targetRelativeModPath) ("reports\" + $relativeReportPath)
                    Ensure-ParentDirectory -Path $installationReportPath
                    Copy-Item -LiteralPath $reportPath -Destination $installationReportPath -Force
                }
            }
        }
    }

    Write-RandomizerProgress -Message "[Done] Generation terminee" -ProgressCallback $ProgressCallback
    return $result
}

function New-LauncherText {
    return @'
@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%"
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%CustomSwShRandomizer.ps1"
if errorlevel 1 (
    echo.
    echo Le randomizer a plante. Lis l'erreur ci-dessus puis envoie-moi le message si besoin.
    pause
)
popd
endlocal
'@
}

function Write-LauncherIfMissing {
    $launcherPath = Join-Path $PSScriptRoot "Launch-CustomSwShRandomizer.bat"
    if (-not (Test-Path -LiteralPath $launcherPath)) {
        [IO.File]::WriteAllText($launcherPath, (New-LauncherText))
    }
}

function Add-ComboBoxItem {
    param(
        [System.Windows.Forms.ComboBox]$Combo,
        [string]$Label,
        [string]$Value
    )
    $null = $Combo.Items.Add([pscustomobject]@{ Label = $Label; Value = $Value })
}

# L'interface vit dans src/Interface.ps1 : 6407 lignes qui ne servent qu'a
# l'affichage. Le point-source la charge dans CETTE portee, donc rien ne change
# pour les appelants - Show-Gui, les fabriques et la bibliotheque de controles
# restent visibles exactement comme avant.
. (Join-Path $PSScriptRoot 'src\Interface.ps1')

Write-LauncherIfMissing

if ($NoGui -or $PSBoundParameters.ContainsKey("SourceRomfs")) {
    if (-not $SourceRomfs) { throw "Dossier ROMFS obligatoire: passe -SourceRomfs avec le dossier romfs du dump utilisateur." }
    if (-not $OutputRomfs) { $OutputRomfs = Get-DefaultOutputRomfsPath -GameVersion $GameVersion }
    $result = Invoke-Randomization -SourceRomfsRoot $SourceRomfs -SourceExefsRoot $SourceExefs -OutputRomfsRoot $OutputRomfs
    $result | Format-List | Out-String | Write-Output
} else {
    Show-Gui
}
