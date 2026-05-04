[CmdletBinding()]
param(
    [string]$SourceRomfs,
    [string]$SourceExefs,
    [string]$OutputRomfs,
    [string]$GameVersion = "Sword",
    [switch]$AutoInstallToEden,
    [string]$EdenModName = "Randomizer",
    [bool]$InstallToEden = $true,
    [bool]$InstallToRyujinx = $true,
    [bool]$InstallToYuzu = $true,
    [bool]$InstallToSudachi = $true,
    [bool]$InstallToCitron = $true,
    [bool]$InstallToSuyu = $true,
    [bool]$InstallToCitronNeo = $true,
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
    [string]$TrainerDynamaxLevelMode = "Unchanged",
    [switch]$ForceTrainerCanDynamax,
    [switch]$ForceAllTeamsToSix,
    [switch]$AllowLegendaryTrainers,
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
    [string]$EvolutionMode = "Unchanged",
    [switch]$AllowLegendaryEvolutions,
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
    [switch]$AllowLegendaryGifts,
    [string]$TradeMode = "Unchanged",
    [switch]$AllowLegendaryTrades,
    [string]$StaticEncounterMode = "Unchanged",
    [switch]$AllowLegendaryStaticEncounters,
    [string]$StaticEncounterStableMapping = "Slot",
    [string]$GrassEncounterMode = "Unchanged",
    [switch]$AllowLegendaryGrassEncounters,
    [string]$GrassEncounterStableMapping = "Slot",
    [string]$VisibleEncounterBehavior = "VanillaVisualBattleRandom",
    [string]$UndergroundMode = "Unchanged",
    [switch]$AllowLegendaryUnderground,
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
    [switch]$RaceMode,
    [bool]$ExportEncounterZoneReport = $true,
    [string]$ReportLanguage = "fr",
    [string]$UiLanguage = "fr",
    [string]$GuiTheme = "Dark",
    [string]$JsonReportPath = "",
    [switch]$SkipInitialCopy,
    [switch]$NoGui
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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
$script:ApplyingUiLanguage = $false
$script:ApplyingCompatibilityUi = $false
$script:LastDetailsDescription = $null
$script:SpeciesNameData = $null
$script:ItemData = $null
$script:ItemNameData = $null
$script:MoveNameData = $null
$script:SmogonStrategicData = $null
$script:SmogonStrategicLegacyData = $null
$script:VanillaTrainerMetadata = $null
$TrainerHeldItemAllowedCategoryIds = [System.Collections.Generic.HashSet[int]]::new()
@(5, 6, 7, 12, 13, 15, 17, 19) | ForEach-Object { $null = $TrainerHeldItemAllowedCategoryIds.Add([int]$_) }
$TrainerHeldItemExcludedIdentifiers = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
@(
    "smoke-ball",
    "pass-orb",
    "red-nectar",
    "yellow-nectar",
    "pink-nectar",
    "purple-nectar"
) | ForEach-Object { $null = $TrainerHeldItemExcludedIdentifiers.Add([string]$_) }
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
        "vanillavisualbattlerandom" { return "VanillaVisualBattleRandom" }
        "vanilla_visual_battle_random" { return "VanillaVisualBattleRandom" }
        "vanilla" { return "VanillaVisualBattleRandom" }
        "randomvisualbattlerandom" { return "RandomVisualBattleRandom" }
        "random_visual_battle_random" { return "RandomVisualBattleRandom" }
        "separate" { return "RandomVisualBattleRandom" }
        "romfsmatch" { return "RomfsMatch" }
        "romfs_match" { return "RomfsMatch" }
        "match" { return "RomfsMatch" }
        default { return "RomfsMatch" }
    }
}

function Get-LiveEncounterRandomizerMode {
    $behavior = Get-NormalizedVisibleEncounterBehavior -Value $VisibleEncounterBehavior
    switch ($behavior) {
        # Live ExLaunch path: the visible Pokemon is randomized at spawn time
        # and the battle Pokemon is randomized separately from the same slot.
        "RandomVisualBattleRandom" { return "random_visual_battle_random" }
        # Battle-only ExLaunch path: keep the overworld model vanilla and swap
        # the species when the game copies the encounter object into battle data.
        "VanillaVisualBattleRandom" { return "vanilla_visual_battle_random" }
        default { return "off" }
    }
}

function Get-LiveEncounterRandomizerEnabled {
    return ((Get-LiveEncounterRandomizerMode) -ne "off")
}

function Get-AnyExLaunchRuntimeFeatureEnabled {
    return ((Get-RandomizerPcMenuEnabled) -or (Get-AnyExpLevelCapEnabled) -or (Get-RuntimeExpMultiplierEnabled) -or [bool]$DisableExpShare -or [bool]$EarlyBike -or (Get-LiveEncounterRandomizerEnabled))
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
        "épée" { return "Sword" }
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
            throw "$Kind invalide: '$Path' pointe vers une sortie generee ou un dossier interne du randomizer. Selectionne le $Kind original extrait de ton propre dump du jeu."
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

function Resolve-OutputRomfsRoot {
    param([string]$OutputPath)

    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        throw "Dossier de sortie obligatoire: selectionne le dossier du mod genere."
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

        throw "Dossier ExeFS invalide: '$SourceExefsRoot'. Selectionne le dossier exefs de ton dump, celui qui contient main.npdm."
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
        throw "Dossier ROMFS obligatoire: selectionne le dossier romfs de ton dump utilisateur."
    }

    $resolvedRomfs = [IO.Path]::GetFullPath($SourceRomfsRoot)
    if (-not (Test-Path -LiteralPath $resolvedRomfs)) {
        throw "Dossier ROMFS introuvable: '$SourceRomfsRoot'. Selectionne le dossier romfs de ton dump utilisateur."
    }

    if ((Split-Path -Leaf $resolvedRomfs) -ine "romfs") {
        $romfsChild = Join-Path $resolvedRomfs "romfs"
        if (Test-Path -LiteralPath $romfsChild) {
            $resolvedRomfs = [IO.Path]::GetFullPath($romfsChild)
        }
    }

    if ((Split-Path -Leaf $resolvedRomfs) -ine "romfs") {
        throw "Dossier ROMFS invalide: '$SourceRomfsRoot'. Selectionne le dossier romfs de ton dump utilisateur."
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
        throw "Dossier ExeFS obligatoire: selectionne le dossier exefs de ton dump utilisateur, celui qui contient main.npdm."
    }

    $resolvedExefs = Resolve-SourceExefsRoot -SourceRomfsRoot $SourceRomfsRoot -SourceExefsRoot $SourceExefsRoot -GameVersion $GameVersion
    if ([string]::IsNullOrWhiteSpace($resolvedExefs) -or (-not (Test-Path -LiteralPath (Join-Path $resolvedExefs "main.npdm")))) {
        throw "Dossier ExeFS invalide: '$SourceExefsRoot'. Selectionne le dossier exefs de ton dump utilisateur, celui qui contient main.npdm."
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

function Get-EdenRootPath {
    $appDataPath = [Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)
    if ([string]::IsNullOrWhiteSpace($appDataPath)) {
        return ""
    }

    return (Join-Path $appDataPath "eden")
}

function Get-PreferredExistingPath {
    param([string[]]$Candidates)

    foreach ($candidate in @($Candidates)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$candidate) -and (Test-Path -LiteralPath $candidate)) {
            return [string]$candidate
        }
    }

    foreach ($candidate in @($Candidates)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$candidate)) {
            return [string]$candidate
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

function Get-EdenModRoot {
    param(
        [string]$GameVersion,
        [string]$ModName
    )

    $edenRoot = Get-EdenRootPath
    if ([string]::IsNullOrWhiteSpace($edenRoot)) {
        return ""
    }

    $titleId = Get-GameTitleId -GameVersion $GameVersion
    $safeModName = Get-NormalizedModName -ModName $ModName
    return (Join-Path $edenRoot ("load\" + $titleId + "\" + $safeModName))
}

function Get-YuzuRootPath {
    $roamingRoot = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)) "yuzu"
    $localRoot = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)) "yuzu"
    if (Test-Path -LiteralPath $roamingRoot) {
        return $roamingRoot
    }
    if (Test-Path -LiteralPath $localRoot) {
        return $localRoot
    }
    return $roamingRoot
}

function Get-RyujinxRootPath {
    return (Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)) "Ryujinx")
}

function Get-SudachiRootPath {
    $roamingRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)
    $localRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
    return (Get-PreferredExistingPath -Candidates @(
        (Join-Path $roamingRoot "sudachi"),
        (Join-Path $roamingRoot "Sudachi"),
        (Join-Path $localRoot "sudachi"),
        (Join-Path $localRoot "Sudachi")
    ))
}

function Get-CitronRootPath {
    $roamingRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)
    $localRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
    return (Get-PreferredExistingPath -Candidates @(
        (Join-Path $roamingRoot "citron"),
        (Join-Path $roamingRoot "Citron"),
        (Join-Path $localRoot "citron"),
        (Join-Path $localRoot "Citron")
    ))
}

function Get-SuyuRootPath {
    $roamingRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)
    $localRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
    return (Get-PreferredExistingPath -Candidates @(
        (Join-Path $roamingRoot "suyu"),
        (Join-Path $roamingRoot "Suyu"),
        (Join-Path $localRoot "suyu"),
        (Join-Path $localRoot "Suyu")
    ))
}

function Get-CitronNeoRootPath {
    $roamingRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::ApplicationData)
    $localRoot = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
    return (Get-PreferredExistingPath -Candidates @(
        (Join-Path $roamingRoot "citron team"),
        (Join-Path $roamingRoot "Citron Team"),
        (Join-Path $roamingRoot "citron neo"),
        (Join-Path $roamingRoot "Citron Neo"),
        (Join-Path $roamingRoot "citron-neo"),
        (Join-Path $roamingRoot "Citron-Neo"),
        (Join-Path $roamingRoot "CitronNeo"),
        (Join-Path $localRoot "citron team"),
        (Join-Path $localRoot "Citron Team"),
        (Join-Path $localRoot "citron neo"),
        (Join-Path $localRoot "Citron Neo"),
        (Join-Path $localRoot "citron-neo"),
        (Join-Path $localRoot "Citron-Neo"),
        (Join-Path $localRoot "CitronNeo")
    ))
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
            Key = "eden"
            Name = "Eden"
            RootPath = Get-EdenRootPath
            RelativeModPath = ("load\" + $titleId + "\" + $safeModName)
            RelativeSdmcPath = "sdmc"
            TitleId = $titleId
            ModName = $safeModName
        },
        [pscustomobject]@{
            Key = "ryujinx"
            Name = "Ryujinx"
            RootPath = Get-RyujinxRootPath
            RelativeModPath = ("mods\contents\" + $titleId + "\" + $safeModName)
            RelativeSdmcPath = "sdcard"
            TitleId = $titleId
            ModName = $safeModName
        },
        [pscustomobject]@{
            Key = "yuzu"
            Name = "Yuzu"
            RootPath = Get-YuzuRootPath
            RelativeModPath = ("load\" + $titleId + "\" + $safeModName)
            RelativeSdmcPath = "sdmc"
            TitleId = $titleId
            ModName = $safeModName
        },
        [pscustomobject]@{
            Key = "sudachi"
            Name = "Sudachi"
            RootPath = Get-SudachiRootPath
            RelativeModPath = ("load\" + $titleId + "\" + $safeModName)
            RelativeSdmcPath = "sdmc"
            TitleId = $titleId
            ModName = $safeModName
        },
        [pscustomobject]@{
            Key = "citron"
            Name = "Citron"
            RootPath = Get-CitronRootPath
            RelativeModPath = ("load\" + $titleId + "\" + $safeModName)
            RelativeSdmcPath = "sdmc"
            TitleId = $titleId
            ModName = $safeModName
        },
        [pscustomobject]@{
            Key = "suyu"
            Name = "Suyu"
            RootPath = Get-SuyuRootPath
            RelativeModPath = ("load\" + $titleId + "\" + $safeModName)
            RelativeSdmcPath = "sdmc"
            TitleId = $titleId
            ModName = $safeModName
        },
        [pscustomobject]@{
            Key = "citronneo"
            Name = "Citron Neo"
            RootPath = Get-CitronNeoRootPath
            RelativeModPath = ("load\" + $titleId + "\" + $safeModName)
            RelativeSdmcPath = "sdmc"
            TitleId = $titleId
            ModName = $safeModName
        }
    ) | ForEach-Object {
        $rootPath = [string]$_.RootPath
        $relativeModPath = [string]$_.RelativeModPath
        $relativeSdmcPath = [string]$_.RelativeSdmcPath
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
            SdmcConfigRoot = if ([string]::IsNullOrWhiteSpace($sdmcRoot)) { "" } else { Join-Path $sdmcRoot "config\swsh-mods-exl" }
            SdmcConfigPath = if ([string]::IsNullOrWhiteSpace($sdmcRoot)) { "" } else { Join-Path $sdmcRoot "config\swsh-mods-exl\config.toml" }
            TitleId = [string]$_.TitleId
            ModName = [string]$_.ModName
        }
    }
}

function Get-RequestedEmulatorKeys {
    $keys = New-Object System.Collections.Generic.List[string]
    if ([bool]$InstallToEden) { $keys.Add("eden") }
    if ([bool]$InstallToRyujinx) { $keys.Add("ryujinx") }
    if ([bool]$InstallToYuzu) { $keys.Add("yuzu") }
    if ([bool]$InstallToSudachi) { $keys.Add("sudachi") }
    if ([bool]$InstallToCitron) { $keys.Add("citron") }
    if ([bool]$InstallToSuyu) { $keys.Add("suyu") }
    if ([bool]$InstallToCitronNeo) { $keys.Add("citronneo") }
    return [string[]]$keys.ToArray()
}

function Install-PackageToEmulatorTarget {
    param(
        [string]$OutputRomfsRoot,
        [pscustomobject]$Target
    )

    $packageRoot = Get-OutputPackageRoot -OutputRomfsRoot $OutputRomfsRoot
    $sourceRomfsPath = Join-Path $packageRoot "romfs"
    $sourceExefsPath = Join-Path $packageRoot "exefs"
    $sourceSdmcPath = Join-Path $packageRoot "sdmc"
    $sourcePackageFullPath = [IO.Path]::GetFullPath($packageRoot)
    $targetModFullPath = if ([string]::IsNullOrWhiteSpace([string]$Target.ModRoot)) { "" } else { [IO.Path]::GetFullPath([string]$Target.ModRoot) }
    $alreadyAtTarget = (-not [string]::IsNullOrWhiteSpace($targetModFullPath)) -and
        ($sourcePackageFullPath.TrimEnd('\') -ieq $targetModFullPath.TrimEnd('\'))
    $removedExistingSdmcPaths = New-Object System.Collections.Generic.List[string]

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
        RemovedExistingSdmcPaths = @()
        CopiedRomfs = $false
        CopiedExefs = $false
        CopiedSdmc = $false
        Error = ""
    }

    if (-not [bool]$Target.IsDetected) {
        $result.Error = ("{0} introuvable sur ce PC." -f [string]$Target.Name)
        return $result
    }

    if (-not (Test-Path -LiteralPath $sourceRomfsPath)) {
        $result.Error = "Le package genere ne contient pas de dossier romfs."
        return $result
    }

    try {
        if (-not $alreadyAtTarget) {
            if (Test-Path -LiteralPath $Target.ModRoot) {
                Remove-Item -LiteralPath $Target.ModRoot -Recurse -Force
                $result.RemovedExistingMod = $true
            }

            Ensure-Directory -Path (Split-Path -Parent $Target.ModRoot)
            Ensure-Directory -Path $Target.ModRoot
            Copy-DirectoryChildren -SourcePath $sourceRomfsPath -DestinationPath (Join-Path $Target.ModRoot "romfs")
            $result.CopiedRomfs = $true

            if (Test-Path -LiteralPath $sourceExefsPath) {
                Copy-DirectoryChildren -SourcePath $sourceExefsPath -DestinationPath (Join-Path $Target.ModRoot "exefs")
                $result.CopiedExefs = $true
            }
        } else {
            $result.CopiedRomfs = $true
            $result.CopiedExefs = (Test-Path -LiteralPath $sourceExefsPath)
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

        $result.RemovedExistingSdmcPaths = @($removedExistingSdmcPaths.ToArray())
        $result.Installed = $true
        return $result
    } catch {
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

        $results.Add((Install-PackageToEmulatorTarget -OutputRomfsRoot $OutputRomfsRoot -Target $target))
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
            if ($lang -eq "en") { "detected" } else { "detecte" }
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

Chemins manuels :
$(($manualPathLines -join "`r`n"))

Le dossier Installation contient des arborescences deja pretes a copier pour tous les emulateurs supportes.
L'onglet Reset retire seulement ce dossier de mod et le fichier config swsh-mods-exl quand cette config a ete generee par ce randomizer.
"@
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
    $installRoot = Get-InstallationFolderRoot -OutputRomfsRoot $OutputRomfsRoot
    $legacyInstallRoot = Join-Path $packageRoot "Installation"
    if (($legacyInstallRoot -ne $installRoot) -and (Test-Path -LiteralPath $legacyInstallRoot)) {
        Remove-Item -LiteralPath $legacyInstallRoot -Recurse -Force
    }
    if (Test-Path -LiteralPath $installRoot) {
        Remove-Item -LiteralPath $installRoot -Recurse -Force
    }
    Ensure-Directory -Path $installRoot

    $targets = @(Get-EmulatorInstallTargets -GameVersion $GameVersion -ModName $ModName)
    foreach ($target in $targets) {
        $targetRoot = Join-Path $installRoot ([string]$target.Name)
        $targetModRoot = Join-Path $targetRoot ([string]$target.RelativeModPath)
        $targetSdmcRoot = Join-Path $targetRoot ([string]$target.RelativeSdmcPath)
        Ensure-Directory -Path $targetModRoot
        Copy-DirectoryChildren -SourcePath $sourceRomfsPath -DestinationPath (Join-Path $targetModRoot "romfs")
        if (Test-Path -LiteralPath $sourceExefsPath) {
            Copy-DirectoryChildren -SourcePath $sourceExefsPath -DestinationPath (Join-Path $targetModRoot "exefs")
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

function Install-PackageToEden {
    param(
        [string]$OutputRomfsRoot,
        [string]$GameVersion,
        [string]$ModName
    )

    $target = @(Get-EmulatorInstallTargets -GameVersion $GameVersion -ModName $ModName | Where-Object { $_.Key -eq "eden" } | Select-Object -First 1)
    if ($target.Count -lt 1) {
        return [pscustomobject]@{
            Requested = $true
            Installed = $false
            GameVersion = $GameVersion
            TitleId = Get-GameTitleId -GameVersion $GameVersion
            EdenRoot = Get-EdenRootPath
            PackageRoot = Get-OutputPackageRoot -OutputRomfsRoot $OutputRomfsRoot
            ModName = Get-NormalizedModName -ModName $ModName
            ModRoot = ""
            SdmcRoot = ""
            SdmcConfigPath = ""
            AlreadyAtTarget = $false
            RemovedExistingMod = $false
            RemovedExistingSdmcPaths = @()
            CopiedRomfs = $false
            CopiedExefs = $false
            CopiedSdmc = $false
            Error = "Target Eden introuvable."
        }
    }

    $edenResult = Install-PackageToEmulatorTarget -OutputRomfsRoot $OutputRomfsRoot -Target $target[0]
    return [pscustomobject]@{
        Requested = $edenResult.Requested
        Installed = $edenResult.Installed
        GameVersion = $GameVersion
        TitleId = $edenResult.TitleId
        EdenRoot = $edenResult.RootPath
        PackageRoot = $edenResult.PackageRoot
        ModName = $edenResult.ModName
        ModRoot = $edenResult.ModRoot
        SdmcRoot = $edenResult.SdmcRoot
        SdmcConfigPath = $edenResult.SdmcConfigPath
        AlreadyAtTarget = $edenResult.AlreadyAtTarget
        RemovedExistingMod = $edenResult.RemovedExistingMod
        RemovedExistingSdmcPaths = @($edenResult.RemovedExistingSdmcPaths)
        CopiedRomfs = $edenResult.CopiedRomfs
        CopiedExefs = $edenResult.CopiedExefs
        CopiedSdmc = $edenResult.CopiedSdmc
        Error = $edenResult.Error
    }
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

function Get-ExLaunchArtifactRomfsRoot {
    param([string]$GameVersion)

    $titleId = Get-GameTitleId -GameVersion $GameVersion
    $scriptRoot = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $PSScriptRoot
    } elseif (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        Split-Path -Parent $PSCommandPath
    } else {
        (Get-Location).Path
    }
    return Join-Path $scriptRoot ("research\swsh-mods-exl\artifact\atmosphere\contents\" + $titleId + "\romfs")
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

    public static byte[] Patch(byte[] data, bool runtimePcControls)
    {
        List<Entry> entries = Parse(data);
        if (entries.Count == 0) throw new ArgumentException("script_id_record.bin is empty or invalid.");

        Upsert(entries, Fnv1a64("custom_message"), "bin/script/amx/custom_message.amx", "script/script_dummy.dat");
        Upsert(entries, Fnv1a64("dex_dialog"), "bin/script/amx/dex_animations.amx", "script/script_dummy.dat");
        Upsert(entries, Fnv1a64("grant_early_bike"), "bin/script/amx/early_bike.amx", "script/script_dummy.dat");
        Upsert(entries, Fnv1a64("randomizer_pc_menu"), "bin/script/amx/randomizer_pc_menu.amx", "script/script_dummy.dat");

        if (runtimePcControls)
        {
            Upsert(entries, 13435777772824609090UL, "bin/script/amx/randomizer_pc_menu.amx", "script/pokemoncenter.dat");
        }

        return Build(entries);
    }
}
"@
}

function Update-UserScriptRecordForExLaunch {
    param(
        [string]$OutputRomfsRoot,
        [bool]$RuntimePcControlsEnabled = $false
    )

    $scriptRecordPath = Join-Path $OutputRomfsRoot "bin\script\param\script_id\script_id_record.bin"
    if (-not (Test-Path -LiteralPath $scriptRecordPath)) {
        return $false
    }

    Initialize-ScriptRecordCodec
    $data = [IO.File]::ReadAllBytes($scriptRecordPath)
    $patched = [PokeFeurScriptRecordCodec]::Patch($data, $RuntimePcControlsEnabled)
    [IO.File]::WriteAllBytes($scriptRecordPath, $patched)
    return $RuntimePcControlsEnabled
}

function Copy-ExLaunchCustomRomfsFiles {
    param(
        [string]$SourceRomfsRoot,
        [string]$OutputRomfsRoot,
        [string]$GameVersion,
        [bool]$RuntimePcControlsEnabled = $false
    )

    $artifactRomfsRoot = Get-ExLaunchArtifactRomfsRoot -GameVersion $GameVersion
    $relativeFiles = @(
        "bin\message\English\script\string_format.dat",
        "bin\message\English\script\string_format.tbl",
        "bin\script\amx\custom_message.amx",
        "bin\script\amx\dex_animations.amx",
        "bin\script\amx\early_bike.amx",
        "bin\script\amx\randomizer_pc_menu.amx"
    )

    foreach ($relativePath in $relativeFiles) {
        $sourcePath = Join-Path $artifactRomfsRoot $relativePath
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            continue
        }
        $targetPath = Join-Path $OutputRomfsRoot $relativePath
        Ensure-ParentDirectory -Path $targetPath
        Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force
    }

    $sourceScriptRecordPath = Join-Path $SourceRomfsRoot "bin\script\param\script_id\script_id_record.bin"
    $targetScriptRecordPath = Join-Path $OutputRomfsRoot "bin\script\param\script_id\script_id_record.bin"
    if (Test-Path -LiteralPath $sourceScriptRecordPath) {
        Ensure-ParentDirectory -Path $targetScriptRecordPath
        Copy-Item -LiteralPath $sourceScriptRecordPath -Destination $targetScriptRecordPath -Force
    }

    return (Update-UserScriptRecordForExLaunch -OutputRomfsRoot $OutputRomfsRoot -RuntimePcControlsEnabled $RuntimePcControlsEnabled)
}

function Deploy-ExLaunchModule {
    param(
        [string]$SourceRomfsRoot,
        [string]$SourceExefsRoot,
        [string]$OutputRomfsRoot,
        [string]$GameVersion,
        [bool]$RuntimePcControlsEnabled = $false
    )

    $normalizedGameVersion = Get-NormalizedGameVersionSelection -Value $GameVersion
    if ($normalizedGameVersion -eq "Auto") {
        $normalizedGameVersion = "Sword"
    }
    $titleId = Get-GameTitleId -GameVersion $normalizedGameVersion
    $userExefsRoot = Resolve-SourceExefsRoot -SourceRomfsRoot $SourceRomfsRoot -SourceExefsRoot $SourceExefsRoot -GameVersion $normalizedGameVersion
    $subsdkSourceRoot = Get-ExLaunchArtifactExefsRoot -GameVersion $normalizedGameVersion
    $mainNpdmSourcePath = if (-not [string]::IsNullOrWhiteSpace($userExefsRoot)) { Join-Path $userExefsRoot "main.npdm" } else { "" }
    $subsdkSourcePath = Join-Path $subsdkSourceRoot "subsdk9"
    $missingFiles = New-Object System.Collections.Generic.List[string]
    if ([string]::IsNullOrWhiteSpace($mainNpdmSourcePath) -or (-not (Test-Path -LiteralPath $mainNpdmSourcePath))) {
        $missingFiles.Add("main.npdm depuis le dump utilisateur exefs")
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
            MissingFiles = @($missingFiles.ToArray())
        }
    }

    Ensure-Directory -Path $targetRoot
    Copy-Item -LiteralPath $mainNpdmSourcePath -Destination $mainNpdmTargetPath -Force
    Copy-Item -LiteralPath $subsdkSourcePath -Destination $subsdkTargetPath -Force
    $pcScriptApplied = Copy-ExLaunchCustomRomfsFiles -SourceRomfsRoot $SourceRomfsRoot -OutputRomfsRoot $OutputRomfsRoot -GameVersion $normalizedGameVersion -RuntimePcControlsEnabled $RuntimePcControlsEnabled

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
    $liveEncounterActiveText = if ($liveEncounterMode -ne "off") { "true" } else { "false" }
    $liveEncounterMapping = (Normalize-StableMappingMode -Value $GrassEncounterStableMapping).ToLowerInvariant()
    $liveEncounterSeedText = ([UInt64](Resolve-SeedValue -SeedValue $Seed)).ToString([Globalization.CultureInfo]::InvariantCulture)
    $runtimeMultiplierText = ([double]$ExpYieldMultiplier).ToString("0.###", [Globalization.CultureInfo]::InvariantCulture)
    $content = @"
# Generated by PokeFeurRandomSWSH.
# Managed-by: PokeFeurRandomSWSH
# Requested-exp-cap-mode: $requestedMode
# ExLaunch-exp-cap-mode: $mode
# Install this under Eden/Ryujinx/Yuzu sdmc-or-sdcard config/swsh-mods-exl/config.toml
# together with the built swsh-mods-exl ExLaunch module.

[overworld_shiny]
active = false
boosted_percentage = 0

[randomizer]
active = $liveEncounterActiveText
mode = "$liveEncounterMode"
mapping = "$liveEncounterMapping"
seed = $liveEncounterSeedText

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

    if ((Normalize-Mode $GrassEncounterMode) -ne "unchanged") {
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
            $missing.Add("bin\pml\personal\personal_total.bin (taille inattendue pour Sword/Shield)")
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
        throw "ROMFS invalide ou incomplet: $summary. Selectionne le dossier romfs original complet de ton dump Sword/Shield."
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
        throw ("Impossible de telecharger {0}: {1}" -f $Url, $_.Exception.Message)
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
        throw "Le generateur Smogon n'a pas produit le cache attendu: $strategicPath"
    }
    if (-not (Test-Path -LiteralPath $legacyStrategicPath)) {
        throw "Le generateur Smogon n'a pas produit le cache historique attendu: $legacyStrategicPath"
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
            Write-Warning "Cache Smogon ancien detecte, regeneration depuis les pages Strategy Dex Sword/Shield."
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
        Write-Warning ("Donnees strategiques Smogon indisponibles, les fallbacks seront utilises: {0}" -f $_.Exception.Message)
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
            Write-Warning "Cache Smogon historique ancien detecte, regeneration depuis les pages Strategy Dex."
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
        Write-Warning ("Donnees strategiques Smogon historiques indisponibles, les fallbacks seront utilises: {0}" -f $_.Exception.Message)
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

function Get-SmogonStrategicSetItems {
    param([object]$StrategicSet)

    if ($null -eq $StrategicSet) {
        return [int[]]@()
    }
    return [int[]](Convert-ToIntArraySafe -Value (Get-DynamicPropertyValue -Object $StrategicSet -Name "items" -DefaultValue @()))
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
    return [int[]]$pool.ToArray()
}

function Get-RandomItemReplacement {
    param(
        [int]$CurrentItemId,
        [System.Random]$Rng,
        [switch]$PreferTechnicalRecord
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
        throw "ID de Pokemon invalide: $text"
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
        throw ("Pokemon ambigu pour '{0}'. Precise le nom. Exemples: {1}" -f $text, ($examples -join ", "))
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
        throw "Les 3 starters manuels doivent etre differents."
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
    $title = if ($scopeValue -eq "GymLeague") { "Cibles arenes + ligue" } else { "Cibles boss importants" }
    return $title + " (noms uniques):`r`n" + $listText + "`r`n`r`nLes IDs exacts sont exportes dans le JSON."
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
    $gym4LabelFr = if ($isShield) { "4e arene - Alistair" } else { "4e arene - Faiza" }
    $gym4LabelEn = if ($isShield) { "Gym 4 - Allister" } else { "Gym 4 - Bea" }
    $gym6TrainerId = if ($isShield) { 136 } else { 135 }
    $gym6Key = if ($isShield) { "gym6Melony" } else { "gym6Gordie" }
    $gym6LabelFr = if ($isShield) { "6e arene - Melony" } else { "6e arene - Gordon" }
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
    $gym4LabelFr = if ($isShield) { "4e arene - Alistair" } else { "4e arene - Faiza" }
    $gym4LabelEn = if ($isShield) { "Gym 4 - Allister" } else { "Gym 4 - Bea" }
    $gym6TrainerIds = if ($isShield) { @(136) } else { @(135) }
    $gym6Key = if ($isShield) { "gym6Melony" } else { "gym6Gordie" }
    $gym6LabelFr = if ($isShield) { "6e arene - Melony" } else { "6e arene - Gordon" }
    $gym6LabelEn = if ($isShield) { "Gym 6 - Melony" } else { "Gym 6 - Gordie" }

    return @(
        [ordered]@{ stageIndex = 1; stageKey = "hopStarterChoice"; trainerIds = @(4, 5, 6); stageLabelFr = "Debut - Nabil choix du starter"; stageLabelEn = "Opening - Hop starter choice"; category = "rival"; variantKind = "starterChoice" }
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
        0 { return [ordered]@{ fr = "Progression principale souple - avant la 1ere arene"; en = "Soft main-story progression - before Gym 1" } }
        1 { return [ordered]@{ fr = "Progression principale souple - apres 1 badge"; en = "Soft main-story progression - after 1 badge" } }
        2 { return [ordered]@{ fr = "Progression principale souple - apres 2 badges"; en = "Soft main-story progression - after 2 badges" } }
        3 { return [ordered]@{ fr = "Progression principale souple - apres 3 badges"; en = "Soft main-story progression - after 3 badges" } }
        4 { return [ordered]@{ fr = "Progression principale souple - apres 4 badges"; en = "Soft main-story progression - after 4 badges" } }
        5 { return [ordered]@{ fr = "Progression principale souple - apres 5 badges"; en = "Soft main-story progression - after 5 badges" } }
        6 { return [ordered]@{ fr = "Progression principale souple - apres 6 badges"; en = "Soft main-story progression - after 6 badges" } }
        7 { return [ordered]@{ fr = "Progression principale souple - apres 7 badges"; en = "Soft main-story progression - after 7 badges" } }
        default { return [ordered]@{ fr = "Progression principale souple - apres 8 badges / fin du jeu"; en = "Soft main-story progression - after 8 badges / endgame" } }
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
            teamSize = [int]$primaryBattle.teamSize
            party = @($primaryBattle.party)
            sourceBattleCount = Get-ObjectArrayCount $referenceBattleArray
            sourceCategories = @($referenceBattleArray | Select-Object -ExpandProperty category -Unique)
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

    return [object[]]$entries.ToArray()
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
        throw "Robocopy a echoue avec le code $LASTEXITCODE."
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

function Get-UndergroundExplorationPokePath {
    param([string]$RomfsRoot)
    return Join-Path $RomfsRoot "bin\appli\chika\data_table\underground_exploration_poke.bin"
}

function Normalize-Mode {
    param([string]$Value)
    return ([string]$Value).Trim().ToLowerInvariant()
}

function Test-TrainerModeUsesSmogon {
    param([string]$Mode)
    return ((Normalize-Mode $Mode) -in @("smogonstrategic", "smogonlegacy", "smogonhistory", "smogonhistorical", "smogonancien", "smogonanciennegen", "smogonanciennesgens"))
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
        "aléatoire" { return "random" }
        "smogon" { return "smogonstrategic" }
        "smogonstrategic" { return "smogonstrategic" }
        "strategicsmogon" { return "smogonstrategic" }
        "strategique" { return "smogonstrategic" }
        "strategiquesmogon" { return "smogonstrategic" }
        "stratégique" { return "smogonstrategic" }
        "stratégiquesmogon" { return "smogonstrategic" }
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
        "espèce" { return "species" }
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

function Get-MovePool {
    param([string]$RomfsRoot)
    $moveDir = Get-MoveDir -RomfsRoot $RomfsRoot
    $count = (Get-ChildItem -LiteralPath $moveDir -Filter "*.wazabin" -File).Count
    return 1..($count - 1)
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
            throw ("{0}: {1} ({2}) n'est pas marque jouable dans les donnees Sword/Shield. Choisis une espece presente dans le jeu pour eviter les oeufs/modeles invalides." -f $Context, (Get-SpeciesDisplayName -SpeciesId $speciesId -Language "fr"), $speciesId)
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
    $heldItems = New-Object System.Collections.Generic.HashSet[int]
    foreach ($entry in @($itemData.Rows)) {
        if ($null -eq $entry) {
            continue
        }

        $itemId = [int]$entry.id
        $categoryId = [int]$entry.categoryId
        $identifier = [string]$entry.identifier
        if ($itemId -le 0) {
            continue
        }
        if ($TrainerHeldItemExcludedIdentifiers.Contains($identifier)) {
            continue
        }

        if ($poolModeValue -in @("full", "fullrandom", "all", "any", "complete", "complet")) {
            if ($categoryId -in @(20, 21, 22, 23, 40, 41, 46)) {
                continue
            }
        } elseif (-not $TrainerHeldItemAllowedCategoryIds.Contains($categoryId)) {
            continue
        }

        $null = $heldItems.Add($itemId)
    }

    $pool = @($heldItems | Sort-Object)
    if ($pool.Count -gt 0) {
        return $pool
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

    throw "Impossible de trouver une espece unique pour l'equipe dresseur avec le pool actuel."
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

    $filled = @(0, 0, 0, 0)
    $start = [Math]::Max(0, 4 - $moves.Count)
    for ($i = 0; $i -lt $moves.Count; $i++) {
        $filled[$start + $i] = $moves[$i]
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

    $filled = @(0, 0, 0, 0)
    $count = [Math]::Min(4, $selectedMoves.Count)
    $start = [Math]::Max(0, 4 - $count)
    for ($i = 0; $i -lt $count; $i++) {
        $filled[$start + $i] = [int]$selectedMoves[$i]
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
        [hashtable]$StableMap = $null
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

                $stableKey = switch ($stableMode) {
                    "species" { "species:$speciesId" }
                    "random" { "" }
                    default { "$InternalFileName|$tableIndex|$zoneId|$subTableIndex|$slotIndex|$speciesId" }
                }
                $replacement = Get-StableSpeciesReplacement -Rng $Rng -CurrentSpeciesId $speciesId -Mode $mode -Context $context -StableMap $StableMap -StableKey $stableKey
                if ($replacement -eq $speciesId) {
                    continue
                }

                $probabilityAddress = Get-FlatBufferFieldAddress -Data $Data -TablePos $slotPos -FieldIndex 0
                $formAddress = Get-FlatBufferFieldAddress -Data $Data -TablePos $slotPos -FieldIndex 2
                $probability = if ($probabilityAddress -ge 0) { [int]$Data[$probabilityAddress] } else { 0 }
                $formBefore = if ($formAddress -ge 0) { [int]$Data[$formAddress] } else { 0 }

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

function Invoke-GrassEncounterRandomization {
    param(
        [string]$RomfsRoot,
        [System.Random]$Rng,
        [string]$ModeValue,
        [bool]$AllowLegendarySpecies,
        [string]$StableMappingMode = "Slot",
        [bool]$IncludeVisibleSymbols = $true,
        [hashtable]$StableMap = $null
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
            -StableMap $StableMap

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
        [hashtable]$StableMap = $null
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
            $shopIndex = 0
            foreach ($tablePos in Get-FlatBufferTableVectorPositions -Data $data) {
                $shopIndex++
                $vectorFieldAddress = Get-FlatBufferFieldAddress -Data $data -TablePos $tablePos -FieldIndex 1
                $slotIndex = 0
                foreach ($address in Get-FlatBufferUIntVectorAddresses -Data $data -VectorFieldAddress $vectorFieldAddress) {
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

                    $replacement = Get-RandomItemReplacement -CurrentItemId $itemId -Rng $Rng -PreferTechnicalRecord:($isTechnical -and $RandomizeTechnicalRecords.IsPresent)
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

    $path = Join-Path $OutputRomfsRoot "item-changes.json"
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

function Invoke-GiftAndEncounterRandomization {
    param(
        [string]$RomfsRoot,
        [System.Random]$Rng,
        [string]$GiftModeValue,
        [string]$StarterModeValue,
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
        [string]$UndergroundModeValue,
        [bool]$AllowLegendaryUndergroundSpecies
    )

    $giftMode = Normalize-Mode $GiftModeValue
    $starterMode = Normalize-Mode $StarterModeValue
    $tradeMode = Normalize-Mode $TradeModeValue
    $staticMode = Normalize-Mode $StaticEncounterModeValue
    $grassMode = Normalize-Mode $GrassEncounterModeValue
    $visibleBehavior = Get-NormalizedVisibleEncounterBehavior -Value $VisibleEncounterBehaviorValue
    $includeVisibleSymbolsInRomfs = ($visibleBehavior -ne "VanillaVisualBattleRandom")
    $undergroundMode = Normalize-Mode $UndergroundModeValue
    $sharedEncounterStableMap = @{}
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

            $giftContext = @{
                BaseSpeciesPool = Get-BaseSpeciesPool -AllowLegendaries $AllowLegendaryGiftSpecies -RomfsRoot $RomfsRoot
                BaseSpeciesEntries = @{}
                SimilarBstCache = @{}
            }
            $entries = Get-PersonalEntries -RomfsRoot $RomfsRoot
            for ($i = 1; $i -le $BaseSpeciesMax; $i++) {
                $giftContext.BaseSpeciesEntries[$i] = $entries[$i]
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
                    $replacement = Get-SpeciesReplacement -Rng $Rng -CurrentSpeciesId $speciesId -Mode $mode -Context $giftContext
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
        -StableMap $sharedEncounterStableMap
    $result.StaticEncounters = $staticEncounterResult.Edited

    $grassResult = Invoke-GrassEncounterRandomization `
        -RomfsRoot $RomfsRoot `
        -Rng $Rng `
        -ModeValue $GrassEncounterModeValue `
        -AllowLegendarySpecies $AllowLegendaryGrassSpecies `
        -StableMappingMode $GrassEncounterStableMapping `
        -IncludeVisibleSymbols $includeVisibleSymbolsInRomfs `
        -StableMap $sharedEncounterStableMap
    $result.GrassEncounterSlots = $grassResult.Edited

    $undergroundResult = Invoke-FlatBufferSpeciesFieldRandomization `
        -RomfsRoot $RomfsRoot `
        -Path (Get-UndergroundExplorationPokePath -RomfsRoot $RomfsRoot) `
        -FieldIndices @(21, 22, 23, 24) `
        -Rng $Rng `
        -ModeValue $UndergroundModeValue `
        -AllowLegendarySpecies $AllowLegendaryUndergroundSpecies `
        -BlockName "undergroundEncounter"
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
                        foreach ($moveOffset in 0x12, 0x14, 0x16, 0x18) {
                            Write-U16 -Data $bytes -Offset ($offset + $moveOffset) -Value (Random-FromPool -Rng $Rng -Pool $movePool)
                        }
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
    $duplicateMode = Normalize-Mode $DuplicateModeValue
    $preventTrainerDuplicates = $duplicateMode -notin @("normal", "allow", "allowduplicates", "duplicates", "vanilla")
    $abilityMode = Normalize-Mode $AbilityModeValue
    $ivMode = Normalize-Mode $IVModeValue
    $evMode = Normalize-Mode $EVModeValue
    $natureMode = Get-EffectiveTrainerNatureMode -Mode $NatureModeValue -LegacyRandomize $DoRandomizeNatures
    $bossTeamsToSixTargetArray = Convert-ToObjectArray $BossTeamsToSixTargetCatalog
    $teamMaxNormalizationTargetArray = Convert-ToObjectArray $TeamMaxNormalizationTargetCatalog

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
        (Normalize-Mode $DynamaxLevelModeValue) -eq "unchanged" -and
        (-not $DoForceCanDynamax) -and
        (-not $DoForceAllTeamsToSix) -and
        ((Get-ObjectArrayCount $bossTeamsToSixTargetArray) -lt 1) -and
        (([string]$TeamMaxNormalizationMode) -eq "none" -or (Get-ObjectArrayCount $teamMaxNormalizationTargetArray) -lt 1)
    ) {
        return [pscustomobject]@{ Trainers = 0; Pokemon = 0; BossTeamsExpanded = 0; BossTeamsLevelNormalized = 0; ShiniesForced = 0; SpeciesForceEvolved = 0; TrainerTypeThemedTrainers = 0; TrainerAIMaxed = 0; DynamaxLevelsEdited = 0; DynamaxFlagsForced = 0; BossTrainerTargets = @(); TrainerChanges = @() }
    }

    $mayExtendTrainerTeams = $DoForceAllTeamsToSix -or ((Get-ObjectArrayCount $bossTeamsToSixTargetArray) -gt 0) -or ($TeamMin -ge 0)
    $context = @{
        BaseSpeciesPool = Get-BaseSpeciesPool -AllowLegendaries $AllowLegendarySpecies -RomfsRoot $RomfsRoot
        BaseSpeciesEntries = @{}
        SimilarBstCache = @{}
    }
    $personalEntries = @()
    $usesSmogonStrategy = (Test-TrainerModeUsesSmogon $moveMode) -or (Test-TrainerModeUsesSmogon $itemMode) -or (Test-TrainerModeUsesSmogon $abilityMode) -or (Test-TrainerModeUsesSmogon $evMode) -or (Test-TrainerModeUsesSmogon $natureMode)
    $usesSmogonLegacyStrategy = (Test-TrainerModeUsesSmogonLegacy $moveMode) -or (Test-TrainerModeUsesSmogonLegacy $itemMode) -or (Test-TrainerModeUsesSmogonLegacy $abilityMode) -or (Test-TrainerModeUsesSmogonLegacy $evMode) -or (Test-TrainerModeUsesSmogonLegacy $natureMode)
    $usesStrictSmogonStrategy = $usesSmogonStrategy -and -not $usesSmogonLegacyStrategy
    $needsLevelMoveFallback = ($moveMode -eq "lastlevelup4") -or ((Test-TrainerModeUsesSmogon $moveMode) -and $smogonMoveFallbackMode -eq "lastlevelup4")
    $needsPersonalEntries = ($speciesMode -ne "unchanged") -or $needsLevelMoveFallback -or (Test-TrainerModeUsesSmogon $abilityMode) -or $mayExtendTrainerTeams
    if ($needsPersonalEntries) {
        $personalEntries = Get-PersonalEntries -RomfsRoot $RomfsRoot
        for ($i = 1; $i -le $BaseSpeciesMax; $i++) {
            $context.BaseSpeciesEntries[$i] = $personalEntries[$i]
        }
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
        if (-not $hasGlobalTrainerEdits -and -not $forceBossToSix -and -not $applyTeamMaxNormalization) {
            continue
        }
        if ($currentTeamSize -lt 1 -and -not $DoForceAllTeamsToSix -and -not $forceBossToSix -and $TeamMin -lt 1) {
            continue
        }
        $targetTeamSize = if ($DoForceAllTeamsToSix -or $forceBossToSix) { 6 } else { $currentTeamSize }
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
                foreach ($moveOffset in 0x12, 0x14, 0x16, 0x18) {
                    Write-U16 -Data $partyBytes -Offset ($offset + $moveOffset) -Value (Random-FromPool -Rng $Rng -Pool $movePool)
                }
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

            $editedPokemon++
            } catch {
                throw ("Erreur trainer {0} slot {1}: {2}" -f $trainerDataFile.Name, $slot, $_.Exception.Message)
            }
        }

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
        [int]$SpecialLevel
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

    foreach ($file in Get-ChildItem -LiteralPath (Get-EvolutionDir -RomfsRoot $RomfsRoot) -Filter "*.bin" -File) {
        $bytes = [IO.File]::ReadAllBytes($file.FullName)
        $changed = $false

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
                $replacement = Get-SpeciesReplacement -Rng $Rng -CurrentSpeciesId $targetSpecies -Mode $mode -Context $context
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
    $dynamicExpCapNotesFr = "Le cap EXP dynamique n'est plus genere en IPS brut: le hook fiable passe par ExLaunch au point final du calcul EXP. Le multiplicateur EXP runtime et l'etat EXP Share passent aussi par ExLaunch."
    $dynamicExpCapNotesEn = "Dynamic EXP cap is no longer emitted as a raw IPS patch: the reliable hook goes through ExLaunch at the final EXP calculation point. Runtime EXP multiplier and EXP Share state also go through ExLaunch."
    if ($effectiveStoryMajorBattleOrderLevelCap) {
        $dynamicExpCapNotesFr += " Avec le mode ordre histoire principale, le randomizer uniformise une liste ordonnee de gros combats (arenes, Nabil, Travis, Rosemary, Liv, Shehroz, Tarak) sur leur niveau max, mais le blocage EXP demande ExLaunch."
        $dynamicExpCapNotesEn += " With the ordered main-story mode, the randomizer normalizes an ordered list of major battles (gyms, Hop, Bede, Marnie, Oleana, Rose, Leon) to their max level, but EXP enforcement requires ExLaunch."
    } elseif ($effectiveStrictBossMaxLevelCap) {
        $dynamicExpCapNotesFr += " Avec l'option boss max strict, l'outil aligne chaque equipe boss listee sur son niveau max; le blocage EXP strict demande ExLaunch."
        $dynamicExpCapNotesEn += " With the strict boss max option, the tool normalizes each listed boss team to its highest level; strict EXP enforcement requires ExLaunch."
    }
    $mainStorySoftCapNotesFr = "Mode progression principale souple: calcule une table de 9 caps basee sur les badges, mais chaque palier prend le niveau max des gros combats de progression du meme bloc. Les arenes restent l'ossature et les vrais boss antagonistes / fin d'histoire sont ajoutes quand ils tombent dans le meme palier, pour reduire l'overlevel sans micro-caps trop frequents."
    $mainStorySoftCapNotesEn = "Soft main-story progression mode: computes a 9-step badge-based cap table, but each milestone takes the max level from the major progression fights in the same block. Gyms remain the backbone and the real villain / endgame bosses are folded in when they land in the same milestone, reducing overleveling without overly frequent micro-caps."
    $storyGymLeagueCapNotesFr = "Mode histoire arenes/champion: les 9 caps sont calcules apres randomisation depuis les vraies equipes generees. L'application en jeu demande maintenant le module ExLaunch, pas un IPS brut."
    $storyGymLeagueCapNotesEn = "Gym/champion story mode: the 9 caps are computed after randomization from the actual generated teams. In-game enforcement now requires the ExLaunch module, not a raw IPS patch."
    $storyMajorBattleCapNotesFr = "Mode ordre histoire principale: l'outil prend une liste ordonnee des gros combats de l'histoire principale (arenes, Nabil, Travis, Rosemary, Liv, Shehroz, Tarak). Chaque equipe de cette liste est uniformisee sur son niveau max apres randomisation et exportee dans story-major-battle-caps.json. Le blocage EXP en jeu demande ExLaunch."
    $storyMajorBattleCapNotesEn = "Ordered main-story mode: the tool uses an ordered list of major main-story battles (gyms, Hop, Bede, Marnie, Oleana, Rose, Leon). Each listed team is normalized to its max level after randomization and exported to story-major-battle-caps.json. In-game EXP enforcement requires ExLaunch."
    $bossLevelCapNotesFr = if ($effectiveMainStorySoftLevelCap) {
        "Le JSON liste toujours les caps boss calcules depuis le niveau max des equipes boss apres randomisation, mais le cap applique en jeu vient du mode progression principale souple. Ce mode utilise toujours 9 paliers par badge, enrichis avec les vrais boss antagonistes / fin d'histoire du meme bloc."
    } elseif ($effectiveStoryGymLeagueExpCap) {
        "Le JSON liste toujours les caps boss calcules depuis le niveau max des equipes boss apres randomisation, mais le cap applique en jeu vient du mode histoire arenes/champion. Ce mode lit 9 caps de progression bases sur le nombre de badges: arene 1 a 8 puis Tarak."
    } elseif ($effectiveStoryMajorBattleOrderLevelCap) {
        "Le JSON liste les caps calcules depuis le niveau max des boss apres randomisation. Avec le mode ordre histoire principale, le patch EXP dynamique reste global et les gros combats listes dans story-major-battle-caps.json sont aussi uniformises sur leur niveau max pour rendre leurs caps stricts."
    } elseif ($effectiveStrictBossMaxLevelCap) {
        "Le JSON liste les caps calcules depuis le niveau max des boss apres randomisation. Le mode strict boss max active aussi le patch EXP dynamique puis aligne tous les Pokemon des boss listes sur le niveau max de leur equipe: pendant ces combats, le cap se comporte donc comme un vrai plafond boss max level. Ce n'est toujours pas un suivi de progression par badge."
    } elseif ($effectiveReceiverLevelExpCap) {
        "Le JSON liste les caps calcules depuis le niveau max des boss apres randomisation. Avec le levelcap EXP dynamique actif, le jeu bloque a 1 EXP quand le Pokemon receveur est au niveau du Pokemon adverse vaincu ou au-dessus. Ce n'est pas un suivi de progression par badge: c'est un cap dynamique par Pokemon adverse battu."
    } elseif ($expLevelCapRequiresExLaunch) {
        "Le JSON liste les caps calcules. Le cap EXP en jeu passe maintenant par ExLaunch: il faut que main.npdm/subsdk9 soient presents dans exefs et que sdmc/config/swsh-mods-exl/config.toml contienne les caps generes. Le vieux patch IPS brut a ete retire car il ecrasait du code vivant."
    } else {
        "Le JSON liste les caps calcules depuis le niveau max des boss apres randomisation. Sans patch ExeFS actif, ce fichier reste une reference des caps boss."
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
        version = "V4.17"
        generatedAt = [DateTime]::UtcNow.ToString("o")
        reportLanguage = $reportLang
        sourceRomfs = $SourceRomfs
        sourceExefs = if ($Result.PSObject.Properties.Name -contains "SourceExefsRoot") { $Result.SourceExefsRoot } else { "" }
        outputPackage = if ($Result.PSObject.Properties.Name -contains "OutputPackageRoot") { $Result.OutputPackageRoot } else { Get-OutputPackageRoot -OutputRomfsRoot $OutputRomfsRoot }
        outputRomfs = $OutputRomfsRoot
        sourceGameVersion = $sourceGameVersion
        seed = $Result.Seed
        bstExplanation = @{
            fr = "BST = Base Stat Total, la somme des 6 stats de base d'un Pokemon."
            en = "BST = Base Stat Total, the sum of a Pokemon's 6 base stats."
        }
        options = [ordered]@{
            autoInstallToEmulators = [bool]$AutoInstallToEden
            installToEden = [bool]$InstallToEden
            installToRyujinx = [bool]$InstallToRyujinx
            installToYuzu = [bool]$InstallToYuzu
            installToSudachi = [bool]$InstallToSudachi
            installToCitron = [bool]$InstallToCitron
            installToSuyu = [bool]$InstallToSuyu
            installToCitronNeo = [bool]$InstallToCitronNeo
            modInstallName = Get-NormalizedModName -ModName $EdenModName
            trainerSpeciesMode = $TrainerSpeciesMode
            trainerMoveMode = $TrainerMoveMode
            trainerSmogonMoveFallbackMode = $TrainerSmogonMoveFallbackMode
            trainerItemMode = $TrainerItemMode
            trainerItemPoolMode = $TrainerItemPoolMode
            trainerAddedSlotSpeciesMode = $TrainerAddedSlotSpeciesMode
            trainerDuplicateMode = $TrainerDuplicateMode
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
            visibleEncounterBehavior = (Get-NormalizedVisibleEncounterBehavior -Value $VisibleEncounterBehavior)
            liveEncounterRandomizerMode = (Get-LiveEncounterRandomizerMode)
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
            raceMode = [bool]$RaceMode
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
                fr = "Les anciens IPS ExeFS generes par cet outil sont nettoyes. Le cap EXP, le multiplicateur EXP runtime et l'etat EXP Share demandent maintenant le module ExLaunch."
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
                    fr = if ($effectiveMainStorySoftLevelCap) { $mainStorySoftCapNotesFr + " Techniquement, le module ExLaunch reutilise la meme table interne de 9 caps par badge que le mode arenes/Tarak." } else { $storyGymLeagueCapNotesFr }
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
                    fr = "Le main.npdm vient toujours du dump ExeFS utilisateur detecte a cote du ROMFS source. Le subsdk9 est le module custom ExLaunch du randomizer. Les scripts ROMFS runtime sont ajoutes en patchant le script_id_record.bin copie depuis le dump utilisateur, sans utiliser de script_id_record vanilla embarque."
                    en = "main.npdm always comes from the user's ExeFS dump detected next to the source ROMFS. subsdk9 is the randomizer's custom ExLaunch module. Runtime ROMFS scripts are added by patching script_id_record.bin copied from the user's dump, without using a bundled vanilla script_id_record."
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
                fr = "Si l'option est cochee, le randomizer tente de copier automatiquement romfs, exefs et le sous-arbre sdmc genere vers tous les emulateurs coches et detectes sur le PC: Eden, Ryujinx, Yuzu, Sudachi, Citron, Suyu et Citron Neo."
                en = "When enabled, the randomizer tries to copy the generated romfs, exefs and sdmc subtree into every checked and detected emulator on the PC: Eden, Ryujinx, Yuzu, Sudachi, Citron, Suyu, and Citron Neo."
            }
        }
        installationPackage = [ordered]@{
            root = $Result.InstallationPackageRoot
            readmePath = $Result.InstallationPackageReadmePath
            targets = @($Result.InstallationTargets)
            notes = [ordered]@{
                fr = "Le dossier Installation contient des arborescences deja pretes a copier pour Eden, Ryujinx, Yuzu, Sudachi, Citron, Suyu et Citron Neo, avec un README bilingue."
                en = "The Installation folder contains ready-to-copy layouts for Eden, Ryujinx, Yuzu, Sudachi, Citron, Suyu, and Citron Neo, plus a bilingual README."
            }
        }
        starterRelatedTrainerPatches = [ordered]@{
            enabled = [bool]$PatchStarterRelatedTrainers
            filesEdited = $Result.StarterRelatedTrainerFilesEdited
            slotsEdited = $Result.StarterRelatedTrainerSlotsEdited
            notes = [ordered]@{
                fr = "Repatch robuste: les slots sont identifies depuis les donnees vanilla, puis forces vers le trio de starters final meme si les dresseurs ont deja ete randomises. Les slots patches reconstruisent aussi leurs attaques selon le mode moves dresseurs actif."
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
                fr = "configuredTargets liste les combats retenus par le scope choisi pour l'option boss a 6. appliedTargets liste les combats effectivement traites pendant cette generation. forcedToSix peut etre false si une limite de taille d'equipe bloque sous 6."
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
                fr = if ($effectiveMainStorySoftLevelCap) { "Cette option a ete demandee mais le mode progression principale souple a la priorite pour l'EXP et ne lance pas la normalisation boss max stricte pendant cette generation." } elseif ([bool]$GymLeagueStoryLevelCap) { "Cette option a ete demandee mais le mode histoire arenes/champion a la priorite pour l'EXP et desactive la normalisation boss max strict pendant cette generation." } elseif ([bool]$StoryMajorBattleOrderLevelCap) { "Cette option a ete demandee mais le mode ordre histoire principale prend la priorite et utilise sa propre liste ordonnee de combats." } else { "Utilise la meme liste de boss que ci-dessus et aligne tous les Pokemon de ces equipes sur le niveau max de leur equipe. Le blocage EXP en jeu demande le module ExLaunch." }
                en = if ($effectiveMainStorySoftLevelCap) { "This option was requested, but soft main-story progression mode takes priority for EXP and does not run strict boss max normalization during this generation." } elseif ([bool]$GymLeagueStoryLevelCap) { "This option was requested, but the gym/champion story mode takes priority for EXP and disables strict boss max normalization during this run." } elseif ([bool]$StoryMajorBattleOrderLevelCap) { "This option was requested, but the ordered main-story mode takes priority and uses its own ordered battle list." } else { "Uses the same boss list as above and normalizes every Pokemon in those teams to that team's max level. In-game EXP enforcement requires the ExLaunch module." }
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
                fr = if ($effectiveMainStorySoftLevelCap) { "Cette option a ete demandee mais le mode progression principale souple garde la priorite pour l'EXP. Le mode ordre histoire principale n'est donc pas applique pendant cette generation." } elseif ([bool]$GymLeagueStoryLevelCap) { "Cette option a ete demandee mais le mode histoire arenes/champion garde la priorite pour l'EXP. Le mode ordre histoire principale n'est donc pas applique pendant cette generation." } else { $storyMajorBattleCapNotesFr }
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
                fr = if ($effectiveMainStorySoftLevelCap) { "Cette option a ete demandee mais le mode progression principale souple garde la priorite et utilise sa propre table de 9 caps enrichie avec les boss antagonistes." } else { $storyGymLeagueCapNotesFr }
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
                "Special converti en niveau: toutes les methodes non vides qui ne sont pas deja niveau pur."
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
            raceSummary = $Result.RaceSummaryReportPath
            spoilerLog = $Result.SpoilerLogReportPath
            levelCaps = $Result.BossLevelCapsReportPath
            mainStorySoftCaps = $Result.MainStorySoftCapsReportPath
            storyGymLeagueCaps = $Result.StoryGymLeagueCapsReportPath
            storyMajorBattleCaps = $Result.StoryMajorBattleCapsReportPath
        }
    }

    $reportPath = if ([string]::IsNullOrWhiteSpace($JsonReportPath)) {
        Join-Path $OutputRomfsRoot "randomizer-report.json"
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

    $reportPath = Join-Path $OutputRomfsRoot "trainer-changes.json"
    Ensure-ParentDirectory -Path $reportPath
    $trainerChangesArray = Convert-ToObjectArray $TrainerChanges
    $bossTrainerTargetsArray = Convert-ToObjectArray $BossTrainerTargets
    $bossTeamsToSixTargetsArray = Convert-ToObjectArray ($bossTrainerTargetsArray | Where-Object { [bool]$_.bossTeamsToSixRequested })
    $strictBossCapTargetsArray = Convert-ToObjectArray ($bossTrainerTargetsArray | Where-Object { $_.strictBossMaxLevelCap -and [bool]$_.strictBossMaxLevelCap.enabled })
    $storyMajorBattleTargetsArray = Convert-ToObjectArray ($bossTrainerTargetsArray |
        Where-Object { $_.storyMajorBattleOrderLevelCap -and [bool]$_.storyMajorBattleOrderLevelCap.enabled } |
        Sort-Object @{ Expression = { if ($_.storyMajorBattleOrderLevelCap) { [int]$_.storyMajorBattleOrderLevelCap.stageIndex } else { 0 } } }, @{ Expression = { [int]$_.trainerId } })

    $report = [ordered]@{
        version = "V4.17"
        generatedAt = [DateTime]::UtcNow.ToString("o")
        sourceRomfs = $SourceRomfs
        outputRomfs = $OutputRomfsRoot
        seed = $ResolvedSeed
        notes = [ordered]@{
            fr = "Detail avant/apres pour chaque dresseur modifie. Les slots sont numerotes a partir de 1."
            en = "Before/after details for each edited trainer. Slots are numbered from 1."
        }
        bossTeamsToSixTargets = [ordered]@{
            count = Get-ObjectArrayCount $bossTeamsToSixTargetsArray
            notes = [ordered]@{
                fr = "Combats detectes comme boss et traites par l'option boss a 6 Pokemon pendant cette generation."
                en = "Battles detected as bosses and processed by the boss teams to 6 Pokemon option during this generation."
            }
            targets = @($bossTeamsToSixTargetsArray)
        }
        strictBossMaxLevelCapTargets = [ordered]@{
            count = Get-ObjectArrayCount $strictBossCapTargetsArray
            notes = [ordered]@{
                fr = "Combats detectes comme boss et traites par l'option boss max strict pendant cette generation. Chaque cible exporte le niveau cap retenu et les niveaux avant/apres normalisation."
                en = "Battles detected as bosses and processed by the strict boss max option during this generation. Each target exports the selected cap level and the levels before/after normalization."
            }
            targets = @($strictBossCapTargetsArray)
        }
        storyMajorBattleOrderLevelCapTargets = [ordered]@{
            count = Get-ObjectArrayCount $storyMajorBattleTargetsArray
            notes = [ordered]@{
                fr = "Combats majeurs de l'histoire principale traites par le mode ordre histoire. Ils sont exportes dans l'ordre avec leur etape, leur categorie et les niveaux avant/apres normalisation."
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

    $reportPath = Join-Path $OutputRomfsRoot "wild-changes.json"
    Ensure-ParentDirectory -Path $reportPath
    $wildChangesArray = Convert-ToObjectArray $WildChanges
    $visibleBehavior = Get-NormalizedVisibleEncounterBehavior -Value $VisibleEncounterBehavior
    $visibleNotes = switch ($visibleBehavior) {
        "VanillaVisualBattleRandom" {
            [ordered]@{
                fr = "Les Pokemon visibles gardent leur modele vanilla dans le ROMFS. Le combat est remplace au runtime par ExLaunch, donc les remplacements visibles->combat sont documentes dans randomizer-report.json/config.toml plutot que comme edits ROMFS."
                en = "Visible Pokemon keep their vanilla ROMFS model. Battle species are swapped at runtime through ExLaunch, so visible->battle replacements are documented in randomizer-report.json/config.toml rather than as ROMFS edits."
            }
        }
        "RandomVisualBattleRandom" {
            [ordered]@{
                fr = "Les Pokemon visibles sont randomises dans les tables ROMFS, puis ExLaunch peut reroll le modele visible et tirer un Pokemon de combat cache separe. C'est le mode full random visible + combat cache, avec fallback ROMFS si une zone n'est pas couverte par le hook."
                en = "Visible Pokemon are randomized in the ROMFS tables, then ExLaunch can reroll the visible model and choose a separate hidden battle Pokemon. This is the full random visual + hidden battle mode, with a ROMFS fallback if one area is not covered by the hook."
            }
        }
        default {
            [ordered]@{
                fr = "Les Pokemon visibles sont reecrits dans le ROMFS: le visuel random et le combat random correspondent."
                en = "Visible Pokemon are rewritten in ROMFS: random visual and random battle match."
            }
        }
    }

    $report = [ordered]@{
        version = "V4.17"
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
            return $(if ($Language -eq "en") { "Visible overworld" } else { "Pokemon visible overworld" })
        }
        "staticScriptedEncounter" { return $(if ($Language -eq "en") { "Static / scripted encounter" } else { "Rencontre fixe / script" }) }
        "undergroundEncounter" { return "Underground / chika" }
        "inGameTrade" { return $(if ($Language -eq "en") { "NPC trade" } else { "Echange PNJ" }) }
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
        version = "V4.18"
        generatedAt = [DateTime]::UtcNow.ToString("o")
        sourceRomfs = $SourceRomfs
        outputRomfs = $OutputRomfsRoot
        seed = $ResolvedSeed
        spoilerWarning = [ordered]@{
            fr = "Ce fichier revele les rencontres randomisees par zone. Ne l'affiche pas automatiquement dans le viewer si le joueur ne veut pas etre spoile."
            en = "This file reveals randomized encounters by zone. Do not auto-open it in the viewer if the player does not want spoilers."
        }
        schema = [ordered]@{
            intendedViewer = "PokeFeur Trainer Viewer / future encounter viewer"
            zoneNameNote = [ordered]@{
                fr = "Les noms sont generes depuis les identifiants de tables disponibles. Le viewer peut remplacer name via une table de correspondance zoneId -> nom de route/zone."
                en = "Names are generated from available table identifiers. The viewer can replace name through a zoneId -> route/area name mapping table."
            }
        }
        count = $zones.Count
        zones = @($zones.ToArray())
    }

    $reportPath = Join-Path $OutputRomfsRoot "encounter-zones.json"
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
        version = "V4.18"
        generatedAt = [DateTime]::UtcNow.ToString("o")
        seed = $Result.Seed
        sourceGameVersion = $Result.ExLaunchModuleGameVersion
        outputRomfs = $OutputRomfsRoot
        spoilerWarning = [ordered]@{
            fr = "Ce resume peut spoiler les starters, dresseurs importants, objets, caps et rencontres. Affiche-le seulement si l'utilisateur le demande."
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
    }
}

function Write-RaceAndSpoilerReports {
    param(
        [object]$Result,
        [string]$OutputRomfsRoot
    )

    if (-not $ExportJsonReport) {
        return [pscustomobject]@{ RaceSummaryPath = ""; SpoilerLogPath = ""; SeedSummaryPath = "" }
    }

    $summary = New-RunSummaryObject -Result $Result -OutputRomfsRoot $OutputRomfsRoot
    $seedSummaryPath = Join-Path $OutputRomfsRoot "seed-summary.json"
    Write-JsonFile -Value $summary -Path $seedSummaryPath -Depth 18

    $raceSummaryPath = ""
    if ([bool]$RaceMode) {
        $raceSummary = [ordered]@{
            version = "V4.18"
            generatedAt = [DateTime]::UtcNow.ToString("o")
            raceMode = $true
            lockedSeed = $Result.Seed
            outputRomfs = $OutputRomfsRoot
            notes = [ordered]@{
                fr = "Mode race: partage ce fichier pour verifier la seed et les options principales sans ouvrir le spoiler log detaille."
                en = "Race mode: share this file to verify the seed and main options without opening the detailed spoiler log."
            }
            optionsFingerprint = [ordered]@{
                gameVersion = $GameVersion
                trainerSpeciesMode = $TrainerSpeciesMode
                trainerMoveMode = $TrainerMoveMode
                trainerItemMode = $TrainerItemMode
                grassEncounterMode = $GrassEncounterMode
                starterMode = $StarterMode
                levelCapMode = Get-SelectedExpLevelCapMode
            }
            counts = $summary.counts
            difficulty = $summary.difficulty
        }
        $raceSummaryPath = Join-Path $OutputRomfsRoot "race-summary.json"
        Write-JsonFile -Value $raceSummary -Path $raceSummaryPath -Depth 12
    }

    $spoilerLog = [ordered]@{
        version = "V4.18"
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
    $spoilerLogPath = Join-Path $OutputRomfsRoot "spoiler-log.json"
    Write-JsonFile -Value $spoilerLog -Path $spoilerLogPath -Depth 30

    return [pscustomobject]@{
        RaceSummaryPath = $raceSummaryPath
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

    $reportPath = Join-Path $OutputRomfsRoot "level-caps.json"
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
        version = "V4.17"
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
                fr = if ($effectiveMainStorySoftLevelCap) { "Cette option est demandee, mais le mode progression principale souple prend la priorite pour le cap EXP et n'utilise pas la normalisation boss max stricte." } elseif ([bool]$GymLeagueStoryLevelCap) { "Cette option est demandee, mais le mode histoire arenes/champion prend la priorite et n'utilise pas la normalisation boss max stricte." } elseif ([bool]$StoryMajorBattleOrderLevelCap) { "Cette option est demandee, mais le mode ordre histoire principale prend la priorite et utilise sa propre liste ordonnee de combats." } else { "Quand cette option est activee, l'outil normalise chaque equipe boss listee sur son niveau max. Le blocage EXP en jeu demande le module ExLaunch." }
                en = if ($effectiveMainStorySoftLevelCap) { "This option is requested, but soft main-story progression mode takes priority for EXP and does not use strict boss max normalization." } elseif ([bool]$GymLeagueStoryLevelCap) { "This option is requested, but gym/champion story mode takes priority and does not use strict boss max normalization." } elseif ([bool]$StoryMajorBattleOrderLevelCap) { "This option is requested, but the ordered main-story mode takes priority and uses its own ordered battle list." } else { "When this option is enabled, the tool normalizes each listed boss team to its max level. In-game EXP enforcement requires the ExLaunch module." }
            }
        }
        mainStorySoftLevelCap = [ordered]@{
            enabled = $effectiveMainStorySoftLevelCap
            requested = [bool]$MainStorySoftLevelCap
            notes = [ordered]@{
                fr = "Quand cette option est activee, le randomizer calcule une table de 9 caps souples basee sur les badges, en gardant les arenes comme ossature et en ajoutant les gros boss antagonistes / fin d'histoire du meme palier."
                en = "When this option is enabled, the randomizer computes a soft 9-step badge-based cap table, keeping gyms as the backbone and adding the villain / endgame bosses that land in the same milestone."
            }
        }
        storyMajorBattleOrderLevelCap = [ordered]@{
            enabled = $effectiveStoryMajorBattleOrderLevelCap
            requested = [bool]$StoryMajorBattleOrderLevelCap
            notes = [ordered]@{
                fr = if ($effectiveMainStorySoftLevelCap) { "Cette option est demandee, mais le mode progression principale souple garde la priorite et n'active donc pas cette liste ordonnee." } else { "Quand cette option est activee, une liste ordonnee de gros combats de l'histoire principale est uniformisee sur son niveau max. Le blocage EXP en jeu demande le module ExLaunch." }
                en = if ($effectiveMainStorySoftLevelCap) { "This option is requested, but soft main-story progression mode keeps priority and therefore does not enable this ordered battle list." } else { "When this option is enabled, an ordered list of main-story major battles is normalized to its max level. In-game EXP enforcement requires the ExLaunch module." }
            }
        }
        storyGymLeagueLevelCap = [ordered]@{
            enabled = $effectiveStoryGymLeagueExpCap
            notes = [ordered]@{
                fr = if ($effectiveMainStorySoftLevelCap) { "Cette option est demandee, mais le mode progression principale souple prend la priorite et utilise sa propre table de 9 caps par badge." } else { "Quand cette option est activee, les niveaux utilises viennent des equipes generees et sont exportes dans story-gym-league-caps.json. Le cap en jeu demande le module ExLaunch." }
                en = if ($effectiveMainStorySoftLevelCap) { "This option is requested, but soft main-story progression mode takes priority and uses its own 9-step badge table." } else { "When this option is enabled, the levels used come from the generated teams and are exported in story-gym-league-caps.json. In-game enforcement requires the ExLaunch module." }
            }
        }
        notes = [ordered]@{
            fr = if ($effectiveAnyExpLevelCap) { "Caps boss calcules depuis le niveau max de chaque equipe boss apres randomisation. Le cap EXP en jeu n'est pas applique par IPS brut; il demande le module ExLaunch." } else { "Caps boss calcules depuis le niveau max de chaque equipe boss apres randomisation. Sans patch ExeFS actif, ce fichier reste une reference de caps." }
            en = if ($effectiveAnyExpLevelCap) { "Boss caps computed from each boss team's max level after randomization. In-game EXP cap enforcement is not applied through raw IPS; it requires the ExLaunch module." } else { "Boss caps computed from each boss team's max level after randomization. Without an active ExeFS patch, this file remains a cap reference only." }
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

    $reportPath = Join-Path $OutputRomfsRoot "story-gym-league-caps.json"
    Ensure-ParentDirectory -Path $reportPath
    $storyCapsArray = Convert-ToObjectArray $StoryCaps
    $gameVersion = Get-SourceGameVersion -RomfsRoot $SourceRomfs
    $report = [ordered]@{
        version = "V4.17"
        generatedAt = [DateTime]::UtcNow.ToString("o")
        sourceRomfs = $SourceRomfs
        outputRomfs = $OutputRomfsRoot
        seed = $ResolvedSeed
        enabled = [bool]$GymLeagueStoryLevelCap
        gameVersion = $gameVersion
        enforcementMode = "nextGymLeaderOrChampionByBadgeCount"
        notes = [ordered]@{
            fr = "Cap histoire global base sur le nombre de badges. Les 9 entrees ci-dessous sont calculees depuis les equipes randomisees finales: 0 badge = prochaine arene 1, puis arene 2, ..., 8 badges = maitre de la Ligue. Le patch ExeFS ne lit pas ce JSON: il lit la meme information injectee dans sa table interne."
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

    $reportPath = Join-Path $OutputRomfsRoot "story-main-progression-soft-caps.json"
    Ensure-ParentDirectory -Path $reportPath
    $storyCapsArray = Convert-ToObjectArray $StoryCaps
    $gameVersion = Get-SourceGameVersion -RomfsRoot $SourceRomfs
    $effectiveEnabled = ((Get-SelectedExpLevelCapMode) -eq "storyMainProgressionSoft")
    $report = [ordered]@{
        version = "V4.17"
        generatedAt = [DateTime]::UtcNow.ToString("o")
        sourceRomfs = $SourceRomfs
        outputRomfs = $OutputRomfsRoot
        seed = $ResolvedSeed
        enabled = $effectiveEnabled
        requested = [bool]$MainStorySoftLevelCap
        gameVersion = $gameVersion
        enforcementMode = "mainStoryProgressionSoftByBadgeCount"
        notes = [ordered]@{
            fr = if ($effectiveEnabled) { "Mode progression principale souple: les 9 caps suivent toujours les paliers de badges, mais chaque palier est calcule depuis un groupe de gros combats de l'histoire principale. Ce mode garde les arenes comme ossature et ajoute aussi les vrais boss antagonistes / fin d'histoire quand ils tombent dans le meme palier, pour eviter l'overlevel sans changer le cap toutes les 10 minutes. Le jeu ne lit pas ce JSON: il lit la meme table de 9 caps injectee dans la config ExLaunch." } else { "Cette option n'est pas effective sur cette generation. Si elle n'est pas cochee, ce JSON documente simplement la table qui aurait ete utilisee." }
            en = if ($effectiveEnabled) { "Soft main-story progression mode: the 9 caps still follow badge-count milestones, but each milestone is computed from a grouped set of major main-story fights. This keeps gyms as the backbone and also folds in the real villain / endgame bosses that land in the same milestone, so overleveling is reduced without changing the cap every few minutes. The game does not read this JSON directly: it reads the same 9-cap table injected into the ExLaunch config." } else { "This option is not effective for this generation. If it is not checked, this JSON simply documents the table that would have been used." }
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

    $reportPath = Join-Path $OutputRomfsRoot "story-major-battle-caps.json"
    Ensure-ParentDirectory -Path $reportPath
    $storyCapsArray = Convert-ToObjectArray $StoryCaps
    $gameVersion = Get-SourceGameVersion -RomfsRoot $SourceRomfs
    $effectiveEnabled = ((Get-SelectedExpLevelCapMode) -eq "storyOrderedMajorBattles")
    $report = [ordered]@{
        version = "V4.17"
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
            fr = if ($effectiveEnabled) { "Liste ordonnee des gros combats de l'histoire principale couverts par la nouvelle option. Le JSON suit l'ordre de progression et inclut les variantes dependantes du starter ou de la version. En jeu, cette option garde le patch EXP dynamique global puis uniformise seulement ces equipes majeures sur leur niveau max. Ce JSON n'est pas lu par le jeu: il documente la meme selection calculee par le randomizer." } else { "Cette option n'est pas effective sur cette generation. Si le mode histoire arenes/Tarak est coche en meme temps, il garde la priorite pour le patch EXP global et cette liste ordonnee reste desactivee." }
            en = if ($effectiveEnabled) { "Ordered list of the main-story major battles covered by the new option. This JSON follows story order and includes starter-dependent or version-dependent variants. In game, this option keeps the global dynamic EXP patch and only normalizes these major teams to their own max level. The game does not read this JSON: it documents the same selection computed by the randomizer." } else { "This option is not effective for this generation. If gym/champion story mode is checked at the same time, it keeps priority for the global EXP patch and this ordered list stays disabled." }
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

    $SourceRomfsRoot = Resolve-RequiredSourceRomfsRoot -SourceRomfsRoot $SourceRomfsRoot
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
    $storyMajorBattleTargetCatalog = if ($effectiveStoryMajorBattleOrderLevelCap) { Get-StoryMajorBattleTargetCatalog -SourceRomfsRoot $SourceRomfsRoot } else { @() }
    $teamMaxNormalizationMode = if ($effectiveStoryMajorBattleOrderLevelCap) { "storyOrderedMajorBattles" } elseif ($effectiveStrictBossMaxLevelCap) { "strictBossMaxLevel" } else { "none" }
    $teamMaxNormalizationTargetCatalog = if ($effectiveStoryMajorBattleOrderLevelCap) { $storyMajorBattleTargetCatalog } elseif ($effectiveStrictBossMaxLevelCap) { Convert-ToObjectArray (Get-BossTrainerTargetCatalog) } else { @() }
    if (-not $SkipInitialCopy.IsPresent) {
        Write-RandomizerProgress -Message "[Step] Sync selective du romfs" -ProgressCallback $ProgressCallback
        Sync-RequiredRomfsAssets -SourceRoot $SourceRomfsRoot -OutputRoot $OutputRomfsRoot
    }

    Write-RandomizerProgress -Message "[Step] Randomisation des donnees Pokemon" -ProgressCallback $ProgressCallback
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
        -ProgressCallback $ProgressCallback

    Write-RandomizerProgress -Message "[Step] Randomisation des evolutions" -ProgressCallback $ProgressCallback
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
        -SpecialLevel $SpecialEvolutionLevel

    Write-RandomizerProgress -Message "[Step] Randomisation des gifts et rencontres scriptes" -ProgressCallback $ProgressCallback
    $giftEncounterResult = Invoke-GiftAndEncounterRandomization `
        -RomfsRoot $OutputRomfsRoot `
        -Rng $rng `
        -GiftModeValue $GiftMode `
        -StarterModeValue $StarterMode `
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
    $mainStorySoftCaps = @()
    if ($effectiveMainStorySoftLevelCap) {
        Write-RandomizerProgress -Message "[Step] Calcul des caps progression principale souple" -ProgressCallback $ProgressCallback
        $mainStorySoftCaps = Get-MainStorySoftCapEntries -SourceRomfsRoot $SourceRomfsRoot -OutputRomfsRoot $OutputRomfsRoot
    }
    $storyGymLeagueCaps = @()
    if ($effectiveGymLeagueStoryLevelCap) {
        Write-RandomizerProgress -Message "[Step] Calcul des caps histoire arenes / champion" -ProgressCallback $ProgressCallback
        $storyGymLeagueCaps = Get-GymLeagueStoryCapEntries -SourceRomfsRoot $SourceRomfsRoot -OutputRomfsRoot $OutputRomfsRoot
    }
    $storyMajorBattleCaps = @()
    if ($effectiveStoryMajorBattleOrderLevelCap) {
        Write-RandomizerProgress -Message "[Step] Calcul des caps histoire majeurs ordonnes" -ProgressCallback $ProgressCallback
        $storyMajorBattleCaps = Get-StoryMajorBattleCapEntries -SourceRomfsRoot $SourceRomfsRoot -OutputRomfsRoot $OutputRomfsRoot
    }
    if ($canGenerateExLaunchOutputs) {
        Write-RandomizerProgress -Message "[Step] Options EXP runtime: ExLaunch requis, pas d'IPS brut ecrit" -ProgressCallback $ProgressCallback
    } elseif (Get-AnyExLaunchRuntimeFeatureEnabled) {
        Write-RandomizerProgress -Message "[Step] Options runtime detectees mais aucun ExeFS explicite n'est fourni: generation ROMFS-only, ExLaunch ignore" -ProgressCallback $ProgressCallback
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
        $exLaunchModuleDeployment = Deploy-ExLaunchModule -SourceRomfsRoot $SourceRomfsRoot -SourceExefsRoot $resolvedSourceExefsRoot -OutputRomfsRoot $OutputRomfsRoot -GameVersion $sourceGameVersion -RuntimePcControlsEnabled (Get-RandomizerPcMenuEnabled)
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
    $result = [pscustomobject]@{
        Seed = $resolvedSeed
        SourceExefsRoot = $resolvedSourceExefsRoot
        Output = $outputPackageRoot
        OutputPackageRoot = $outputPackageRoot
        OutputRomfsRoot = $OutputRomfsRoot
        PersonalEntriesEdited = $personalResult.PersonalEntriesEdited
        ExpYieldsEdited = $personalResult.ExpYieldsEdited
        MovesEdited = $moveDataResult.MovesEdited
        MoveTypesEdited = $moveDataResult.MoveTypesEdited
        MovePowersEdited = $moveDataResult.MovePowersEdited
        MovePPEdited = $moveDataResult.MovePPEdited
        MoveAccuracyEdited = $moveDataResult.MoveAccuracyEdited
        MoveCategoriesEdited = $moveDataResult.MoveCategoriesEdited
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
        RaceSummaryReportPath = ""
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

    $itemChangesPath = Write-ItemChangesReport -ItemChanges $itemTableResult.Changes -OutputRomfsRoot $OutputRomfsRoot -ResolvedSeed $resolvedSeed -Notes $result.ItemRandomizationNotes
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

    $raceReports = Write-RaceAndSpoilerReports -Result $result -OutputRomfsRoot $OutputRomfsRoot
    $result.SeedSummaryReportPath = [string]$raceReports.SeedSummaryPath
    $result.RaceSummaryReportPath = [string]$raceReports.RaceSummaryPath
    $result.SpoilerLogReportPath = [string]$raceReports.SpoilerLogPath

    Write-RandomizerProgress -Message "[Step] Preparation du dossier Installation" -ProgressCallback $ProgressCallback
    $installationPackage = Write-InstallationPackage -OutputRomfsRoot $OutputRomfsRoot -GameVersion $sourceGameVersion -ModName $EdenModName
    $result.InstallationPackageRoot = $installationPackage.Root
    $result.InstallationPackageReadmePath = $installationPackage.ReadmePath
    $result.InstallationTargets = Convert-ToObjectArray $installationPackage.Targets

    if ([bool]$AutoInstallToEden) {
        Write-RandomizerProgress -Message "[Step] Installation auto dans les emulateurs detectes" -ProgressCallback $ProgressCallback
        $autoInstallResults = Convert-ToObjectArray (Install-PackageToSelectedEmulators -OutputRomfsRoot $OutputRomfsRoot -GameVersion $sourceGameVersion -ModName $EdenModName)
        $result.AutoInstallResults = $autoInstallResults
        $result.AutoInstallSuccessCount = @($autoInstallResults | Where-Object { [bool]$_.Installed }).Count
        $result.AutoInstallFailureCount = @($autoInstallResults | Where-Object { -not [bool]$_.Installed }).Count

        foreach ($installResult in $autoInstallResults) {
            if ([bool]$installResult.Installed) {
                $installModeMessage = if ([bool]$installResult.AlreadyAtTarget) {
                    ("[{0}] La sortie est deja dans le dossier cible, sync sdmc faite" -f [string]$installResult.Emulator)
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
        $outputRomfsFullPath = [IO.Path]::GetFullPath($OutputRomfsRoot).TrimEnd('\')
        $reportFullPath = [IO.Path]::GetFullPath($reportPath)
        if ($reportFullPath.StartsWith($outputRomfsFullPath, [System.StringComparison]::OrdinalIgnoreCase)) {
            $relativeReportPath = $reportFullPath.Substring($outputRomfsFullPath.Length).TrimStart('\')
            $installedAutoInstallResults = @(Convert-ToObjectArray $result.AutoInstallResults | Where-Object { [bool]$_.Installed -and (-not [bool]$_.AlreadyAtTarget) -and (-not [string]::IsNullOrWhiteSpace([string]$_.ModRoot)) })
            foreach ($installResult in $installedAutoInstallResults) {
                $installedReportPath = Join-Path (Join-Path $installResult.ModRoot "romfs") $relativeReportPath
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

                    $installationReportPath = Join-Path (Join-Path (Join-Path ([string]$result.InstallationPackageRoot) $targetName) $targetRelativeModPath) ("romfs\" + $relativeReportPath)
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

function New-GuiFont {
    param(
        [string]$Family = "Segoe UI",
        [single]$Size = 9.5,
        [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular
    )

    foreach ($candidate in @($Family, "Exo 2", "Segoe UI", "Arial")) {
        try {
            return New-Object System.Drawing.Font($candidate, $Size, $Style)
        } catch {
            continue
        }
    }

    return New-Object System.Drawing.Font([System.Drawing.FontFamily]::GenericSansSerif, $Size, $Style)
}

function New-GuiChromePanel {
    param(
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [string]$Tag = "ChromePanel"
    )

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point($X, $Y)
    $panel.Size = New-Object System.Drawing.Size($Width, $Height)
    $panel.Tag = $Tag
    $panel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    return $panel
}

function New-ComboBox {
    param(
        [System.Collections.Hashtable]$Controls,
        [string]$Name,
        [int]$X,
        [int]$Y,
        [int]$Width = 220
    )
    $combo = New-Object System.Windows.Forms.ComboBox
    $combo.DropDownStyle = "DropDownList"
    $combo.Location = New-Object System.Drawing.Point($X, $Y)
    $combo.Size = New-Object System.Drawing.Size($Width, 28)
    $combo.Font = New-GuiFont -Size 9.5
    $Controls[$Name] = $combo
    return $combo
}

function New-CheckBox {
    param(
        [System.Collections.Hashtable]$Controls,
        [string]$Name,
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width = 260,
        [bool]$Checked = $false
    )
    $check = New-Object System.Windows.Forms.CheckBox
    $check.Text = $Text
    $check.Checked = $Checked
    $check.Location = New-Object System.Drawing.Point($X, $Y)
    $check.Size = New-Object System.Drawing.Size($Width, 24)
    $check.Font = New-GuiFont -Size 9.35
    $check.AutoEllipsis = $true
    $Controls[$Name] = $check
    return $check
}

function New-Label {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width = 200,
        [int]$Height = 22
    )
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Location = New-Object System.Drawing.Point($X, $Y)
    $label.Size = New-Object System.Drawing.Size($Width, $Height)
    $label.Font = New-GuiFont -Size 9 -Style ([System.Drawing.FontStyle]::Bold)
    $label.Tag = "InputLabel"
    $label.AutoEllipsis = $true
    return $label
}

function New-TextBox {
    param(
        [System.Collections.Hashtable]$Controls,
        [string]$Name,
        [int]$X,
        [int]$Y,
        [int]$Width = 120,
        [string]$Text = ""
    )
    $box = New-Object System.Windows.Forms.TextBox
    $box.Location = New-Object System.Drawing.Point($X, $Y)
    $box.Size = New-Object System.Drawing.Size($Width, 28)
    $box.Text = $Text
    $box.Font = New-GuiFont -Size 9.5
    $Controls[$Name] = $box
    return $box
}

function Get-ComboValue {
    param([System.Windows.Forms.ComboBox]$Combo)
    if ($Combo.SelectedItem) {
        return $Combo.SelectedItem.Value
    }
    return ""
}

function Set-ComboValue {
    param(
        [System.Windows.Forms.ComboBox]$Combo,
        [string]$Value
    )

    if (-not $Combo) {
        return $false
    }

    for ($i = 0; $i -lt $Combo.Items.Count; $i++) {
        if ([string]$Combo.Items[$i].Value -eq [string]$Value) {
            $Combo.SelectedIndex = $i
            return $true
        }
    }
    return $false
}

function Get-GuiPresetOptionNames {
    return [string[]]@(
        "GameVersion",
        "Source",
        "SourceExefs",
        "Output",
        "Seed",
        "UiLanguage",
        "ReportLanguage",
        "GuiTheme",
        "DifficultyProfile",
        "DisableExpShare",
        "RuntimePcControls",
        "GymLeagueStoryLevelCap",
        "AutoInstallToEden",
        "EdenModName",
        "InstallToEden",
        "InstallToRyujinx",
        "InstallToYuzu",
        "InstallToSudachi",
        "InstallToCitron",
        "InstallToSuyu",
        "InstallToCitronNeo",
        "RaceMode",
        "ExportEncounterZoneReport",
        "TrainerSpeciesMode",
        "TrainerMoveMode",
        "TrainerSmogonMoveFallbackMode",
        "TrainerItemMode",
        "TrainerItemPoolMode",
        "TrainerAddedSlotSpeciesMode",
        "TrainerDuplicateMode",
        "TrainerAbilityMode",
        "TrainerIVMode",
        "TrainerEVMode",
        "TrainerNatureMode",
        "RandomizeTrainerNatures",
        "TrainerLevelMultiplier",
        "TrainerTeamMin",
        "TrainerTeamMax",
        "TrainerTypeThemed",
        "TrainerShinyChancePercent",
        "ForceTrainerFullyEvolved",
        "TrainerFullyEvolvedLevel",
        "MaxTrainerAI",
        "TrainerDynamaxLevelMode",
        "ForceTrainerCanDynamax",
        "ForceAllTeamsToSix",
        "ForceBossTeamsToSix",
        "BossTeamsToSixScope",
        "AllowLegendaryTrainers",
        "TypeMode",
        "TypesMonotypeOnly",
        "AbilityMode",
        "AllowWonderGuard",
        "StatMode",
        "ExpYieldMultiplier",
        "ForceOneExpYield",
        "RandomizeMoveTypes",
        "RandomizeMovePower",
        "MovePowerMin",
        "MovePowerMax",
        "RandomizeMovePP",
        "MovePPMin",
        "MovePPMax",
        "RandomizeMoveAccuracy",
        "MoveAccuracyMin",
        "MoveAccuracyMax",
        "RandomizeMoveCategory",
        "RandomizePickupItems",
        "RandomizeShopItems",
        "RandomizeTechnicalRecords",
        "EvolutionMode",
        "AllowLegendaryEvolutions",
        "NormalizeFriendshipEvolutions",
        "FriendshipEvolutionLevel",
        "NormalizeTradeEvolutions",
        "TradeEvolutionLevel",
        "NormalizeSpecialEvolutions",
        "SpecialEvolutionLevel",
        "GiftMode",
        "StarterMode",
        "Starter1",
        "Starter2",
        "Starter3",
        "PatchStarterRelatedTrainers",
        "AllowLegendaryGifts",
        "TradeMode",
        "AllowLegendaryTrades",
        "StaticEncounterMode",
        "AllowLegendaryStaticEncounters",
        "StaticEncounterStableMapping",
        "GrassEncounterMode",
        "AllowLegendaryGrassEncounters",
        "GrassEncounterStableMapping",
        "VisibleEncounterBehavior",
        "UndergroundMode",
        "AllowLegendaryUnderground"
    )
}

function Get-GuiPresetFromControls {
    param([System.Collections.Hashtable]$Controls)

    $options = [ordered]@{}
    foreach ($name in Get-GuiPresetOptionNames) {
        if (-not $Controls.ContainsKey($name)) {
            continue
        }

        $control = $Controls[$name]
        if ($control -is [System.Windows.Forms.ComboBox]) {
            $options[$name] = Get-ComboValue -Combo $control
        } elseif ($control -is [System.Windows.Forms.CheckBox]) {
            $options[$name] = [bool]$control.Checked
        } elseif ($control -is [System.Windows.Forms.TextBox]) {
            if ($name -eq "Output") {
                $options[$name] = Get-OutputPackageRoot -OutputRomfsRoot ([string]$control.Text)
            } else {
                $options[$name] = [string]$control.Text
            }
        }
    }

    return [pscustomobject][ordered]@{
        presetVersion = "PokeFeurRandomSWSH.GuiPreset.V1"
        appVersion = "V4.17"
        exportedAt = (Get-Date).ToString("o")
        options = $options
    }
}

function Set-GuiControlsFromPreset {
    param(
        [System.Collections.Hashtable]$Controls,
        [object]$Preset
    )

    if ($null -eq $Preset) {
        throw "Preset JSON vide."
    }

    $options = if ($Preset.PSObject.Properties.Name -contains "options") { $Preset.options } else { $Preset }
    if ($null -eq $options) {
        throw "Preset JSON invalide: bloc options introuvable."
    }

    $applied = 0
    foreach ($name in Get-GuiPresetOptionNames) {
        if (-not $Controls.ContainsKey($name)) {
            continue
        }
        if (-not ($options.PSObject.Properties.Name -contains $name)) {
            continue
        }

        $control = $Controls[$name]
        $value = $options.$name
        if ($control -is [System.Windows.Forms.ComboBox]) {
            if (Set-ComboValue -Combo $control -Value ([string]$value)) {
                $applied++
            }
        } elseif ($control -is [System.Windows.Forms.CheckBox]) {
            $control.Checked = [System.Convert]::ToBoolean($value)
            $applied++
        } elseif ($control -is [System.Windows.Forms.TextBox]) {
            if ($name -eq "Output") {
                $control.Text = Get-OutputPackageRoot -OutputRomfsRoot ([string]$value)
            } else {
                $control.Text = [string]$value
            }
            $applied++
        }
    }

    if ($applied -lt 1) {
        throw "Preset JSON invalide: aucune option reconnue."
    }

    if (
        $Controls.ContainsKey("TrainerNatureMode") -and
        -not ($options.PSObject.Properties.Name -contains "TrainerNatureMode") -and
        ($options.PSObject.Properties.Name -contains "RandomizeTrainerNatures") -and
        [System.Convert]::ToBoolean($options.RandomizeTrainerNatures)
    ) {
        if (Set-ComboValue -Combo $Controls.TrainerNatureMode -Value "Random") {
            $applied++
        }
    }

    return $applied
}

function Set-GuiControlValue {
    param(
        [System.Collections.Hashtable]$Controls,
        [string]$Name,
        [object]$Value
    )

    if (-not $Controls.ContainsKey($Name)) {
        return $false
    }

    $control = $Controls[$Name]
    if ($control -is [System.Windows.Forms.ComboBox]) {
        return (Set-ComboValue -Combo $control -Value ([string]$Value))
    }
    if ($control -is [System.Windows.Forms.CheckBox]) {
        $control.Checked = [System.Convert]::ToBoolean($Value)
        return $true
    }
    if ($control -is [System.Windows.Forms.TextBox]) {
        $control.Text = [string]$Value
        return $true
    }

    return $false
}

function Get-DifficultyProfileDefinitions {
    return [ordered]@{
        Custom = [pscustomobject]@{
            Key = "Custom"
            Labels = @{ fr = "Personnalise"; en = "Custom" }
            Descriptions = @{
                fr = "Ne change aucune option. Utilise ce mode quand tu veux regler chaque option a la main."
                en = "Does not change any option. Use it when you want to tune every setting manually."
            }
            Options = [ordered]@{}
        }
        VanillaPlus = [pscustomobject]@{
            Key = "VanillaPlus"
            Labels = @{ fr = "Vanilla+ equilibre"; en = "Balanced Vanilla+" }
            Descriptions = @{
                fr = "Random doux et lisible: puissance proche, rencontres sauvages legerement melangees, pas de hook visible cache par defaut."
                en = "Readable light randomizer: similar power, lightly mixed wild encounters, no hidden visible-encounter hook by default."
            }
            Options = [ordered]@{
                TrainerSpeciesMode = "SimilarBST"; TrainerMoveMode = "LastLevelUp4"; TrainerSmogonMoveFallbackMode = "LastLevelUp4"; TrainerItemMode = "RandomWhenPresent"; TrainerItemPoolMode = "Battle"; TrainerAbilityMode = "Unchanged"; TrainerIVMode = "Unchanged"; TrainerEVMode = "Unchanged"; TrainerNatureMode = "Unchanged"; TrainerDuplicateMode = "NoDuplicates"
                TrainerLevelMultiplier = "1.0"; TrainerTeamMin = "-1"; TrainerTeamMax = "-1"; TrainerShinyChancePercent = "0"; TrainerFullyEvolvedLevel = "40"; TrainerDynamaxLevelMode = "Unchanged"
                RandomizeTrainerNatures = $false; TrainerTypeThemed = $false; ForceTrainerFullyEvolved = $false; MaxTrainerAI = $false; ForceTrainerCanDynamax = $false; ForceAllTeamsToSix = $false; ForceBossTeamsToSix = $false; AllowLegendaryTrainers = $false
                TypeMode = "Unchanged"; AbilityMode = "Unchanged"; StatMode = "Unchanged"; ExpYieldMultiplier = "1.0"; ForceOneExpYield = $false; RandomizeMoveTypes = $false; RandomizeMovePower = $false; RandomizeMovePP = $false; RandomizeMoveAccuracy = $false; RandomizeMoveCategory = $false; RandomizePickupItems = $false; RandomizeShopItems = $false; RandomizeTechnicalRecords = $false
                EvolutionMode = "Unchanged"; GiftMode = "Unchanged"; StarterMode = "Unchanged"; TradeMode = "Unchanged"; PatchStarterRelatedTrainers = $true
                StaticEncounterMode = "Unchanged"; StaticEncounterStableMapping = "Slot"; GrassEncounterMode = "SimilarBST"; GrassEncounterStableMapping = "Slot"; VisibleEncounterBehavior = "RomfsMatch"; UndergroundMode = "SimilarBST"
                AllowLegendaryStaticEncounters = $false; AllowLegendaryGrassEncounters = $false; AllowLegendaryUnderground = $false; DisableExpShare = $false; RuntimePcControls = $false; GymLeagueStoryLevelCap = $false; RaceMode = $false; ExportEncounterZoneReport = $true
            }
        }
        BalancedRandom = [pscustomobject]@{
            Key = "BalancedRandom"
            Labels = @{ fr = "Random complet propre"; en = "Clean full random" }
            Descriptions = @{
                fr = "Random principal conseille: dresseurs et rencontres random, doublons bloques, niveaux et objets raisonnables."
                en = "Recommended full randomizer: randomized trainers and encounters, duplicates blocked, sane levels and items."
            }
            Options = [ordered]@{
                TrainerSpeciesMode = "SimilarBST"; TrainerMoveMode = "LastLevelUp4"; TrainerSmogonMoveFallbackMode = "LastLevelUp4"; TrainerItemMode = "RandomWhenPresent"; TrainerItemPoolMode = "Battle"; TrainerAbilityMode = "RandomSlot"; TrainerIVMode = "Unchanged"; TrainerEVMode = "Unchanged"; TrainerNatureMode = "Random"; TrainerDuplicateMode = "NoDuplicates"
                TrainerLevelMultiplier = "1.0"; TrainerTeamMin = "-1"; TrainerTeamMax = "-1"; TrainerShinyChancePercent = "0"; TrainerFullyEvolvedLevel = "40"; TrainerDynamaxLevelMode = "Unchanged"
                RandomizeTrainerNatures = $false; TrainerTypeThemed = $true; ForceTrainerFullyEvolved = $false; MaxTrainerAI = $false; ForceTrainerCanDynamax = $false; ForceAllTeamsToSix = $false; ForceBossTeamsToSix = $false; AllowLegendaryTrainers = $false
                TypeMode = "Unchanged"; AbilityMode = "Unchanged"; StatMode = "Unchanged"; ExpYieldMultiplier = "1.0"; ForceOneExpYield = $false; RandomizeMoveTypes = $false; RandomizeMovePower = $false; RandomizeMovePP = $false; RandomizeMoveAccuracy = $false; RandomizeMoveCategory = $false; RandomizePickupItems = $false; RandomizeShopItems = $false; RandomizeTechnicalRecords = $false
                EvolutionMode = "SimilarBST"; GiftMode = "SimilarBST"; StarterMode = "SimilarBST"; TradeMode = "SimilarBST"; PatchStarterRelatedTrainers = $true
                StaticEncounterMode = "SimilarBST"; StaticEncounterStableMapping = "Slot"; GrassEncounterMode = "Random"; GrassEncounterStableMapping = "Slot"; VisibleEncounterBehavior = "RomfsMatch"; UndergroundMode = "Random"
                AllowLegendaryStaticEncounters = $false; AllowLegendaryGrassEncounters = $false; AllowLegendaryUnderground = $false; DisableExpShare = $false; RuntimePcControls = $false; GymLeagueStoryLevelCap = $false; RaceMode = $false; ExportEncounterZoneReport = $true
            }
        }
        SmogonStrategic = [pscustomobject]@{
            Key = "SmogonStrategic"
            Labels = @{ fr = "Strategique Smogon"; en = "Smogon strategic" }
            Descriptions = @{
                fr = "Dresseurs plus intelligents: moves, talents et objets Smogon quand disponibles, backup propre sinon."
                en = "Smarter trainer battles: Smogon moves, abilities, and items when available, clean fallback otherwise."
            }
            Options = [ordered]@{
                TrainerSpeciesMode = "SimilarBST"; TrainerMoveMode = "SmogonStrategic"; TrainerSmogonMoveFallbackMode = "LastLevelUp4"; TrainerItemMode = "SmogonStrategic"; TrainerItemPoolMode = "Battle"; TrainerAbilityMode = "SmogonStrategic"; TrainerIVMode = "Max31"; TrainerEVMode = "SmogonStrategic"; TrainerNatureMode = "SmogonStrategic"; TrainerAddedSlotSpeciesMode = "SameTypeBST"; TrainerDuplicateMode = "NoDuplicates"
                TrainerLevelMultiplier = "1.0"; TrainerTeamMin = "-1"; TrainerTeamMax = "-1"; TrainerShinyChancePercent = "0"; TrainerFullyEvolvedLevel = "40"; TrainerDynamaxLevelMode = "Unchanged"
                RandomizeTrainerNatures = $false; TrainerTypeThemed = $true; ForceTrainerFullyEvolved = $true; MaxTrainerAI = $true; ForceTrainerCanDynamax = $false; ForceAllTeamsToSix = $false; ForceBossTeamsToSix = $true; BossTeamsToSixScope = "GymLeague"; AllowLegendaryTrainers = $false
                TypeMode = "Unchanged"; AbilityMode = "Unchanged"; StatMode = "Unchanged"; ExpYieldMultiplier = "1.0"; ForceOneExpYield = $false; RandomizePickupItems = $false; RandomizeShopItems = $false; RandomizeTechnicalRecords = $false
                EvolutionMode = "Unchanged"; GiftMode = "Unchanged"; StarterMode = "Unchanged"; TradeMode = "Unchanged"; PatchStarterRelatedTrainers = $true
                StaticEncounterMode = "Unchanged"; StaticEncounterStableMapping = "Slot"; GrassEncounterMode = "Unchanged"; GrassEncounterStableMapping = "Slot"; VisibleEncounterBehavior = "RomfsMatch"; UndergroundMode = "Unchanged"
                AllowLegendaryStaticEncounters = $false; AllowLegendaryGrassEncounters = $false; AllowLegendaryUnderground = $false; DisableExpShare = $false; RuntimePcControls = $false; GymLeagueStoryLevelCap = $false; RaceMode = $false; ExportEncounterZoneReport = $true
            }
        }
        HardcoreGymLeague = [pscustomobject]@{
            Key = "HardcoreGymLeague"
            Labels = @{ fr = "Hardcore arenes + ligue"; en = "Hardcore gyms + league" }
            Descriptions = @{
                fr = "Challenge centre sur champions et ligue: boss a 6, theme de type garde, IA forte, cap arenes/Tarak."
                en = "Gym and league challenge: 6-Pokemon bosses, preserved type themes, stronger AI, gym/Leon level cap."
            }
            Options = [ordered]@{
                TrainerSpeciesMode = "SimilarBST"; TrainerMoveMode = "SmogonStrategic"; TrainerSmogonMoveFallbackMode = "LastLevelUp4"; TrainerItemMode = "ForceAll"; TrainerItemPoolMode = "Battle"; TrainerAbilityMode = "SmogonStrategic"; TrainerIVMode = "Max31"; TrainerEVMode = "SmogonStrategic"; TrainerNatureMode = "SmogonStrategic"; TrainerAddedSlotSpeciesMode = "SameTypeBST"; TrainerDuplicateMode = "NoDuplicates"
                TrainerLevelMultiplier = "1.10"; TrainerTeamMin = "-1"; TrainerTeamMax = "-1"; TrainerShinyChancePercent = "0"; TrainerFullyEvolvedLevel = "35"; TrainerDynamaxLevelMode = "Max10"
                RandomizeTrainerNatures = $false; TrainerTypeThemed = $true; ForceTrainerFullyEvolved = $true; MaxTrainerAI = $true; ForceTrainerCanDynamax = $false; ForceAllTeamsToSix = $false; ForceBossTeamsToSix = $true; BossTeamsToSixScope = "GymLeague"; AllowLegendaryTrainers = $false
                TypeMode = "Unchanged"; AbilityMode = "Unchanged"; StatMode = "Unchanged"; ExpYieldMultiplier = "1.0"; ForceOneExpYield = $false; RandomizePickupItems = $false; RandomizeShopItems = $false; RandomizeTechnicalRecords = $false
                EvolutionMode = "Unchanged"; GiftMode = "Unchanged"; StarterMode = "Unchanged"; TradeMode = "Unchanged"; PatchStarterRelatedTrainers = $true
                StaticEncounterMode = "SimilarBST"; StaticEncounterStableMapping = "Slot"; GrassEncounterMode = "SimilarBST"; GrassEncounterStableMapping = "Slot"; VisibleEncounterBehavior = "RomfsMatch"; UndergroundMode = "SimilarBST"
                AllowLegendaryStaticEncounters = $false; AllowLegendaryGrassEncounters = $false; AllowLegendaryUnderground = $false; DisableExpShare = $false; RuntimePcControls = $false; GymLeagueStoryLevelCap = $true; RaceMode = $false; ExportEncounterZoneReport = $true
            }
        }
        Chaos = [pscustomobject]@{
            Key = "Chaos"
            Labels = @{ fr = "Chaos total"; en = "Full chaos" }
            Descriptions = @{
                fr = "Mode extreme: presque tout random, legendaires autorises, doublons possibles, visuel et combat separes."
                en = "Extreme mode: nearly everything random, legendaries allowed, duplicates possible, separate visible and battle rolls."
            }
            Options = [ordered]@{
                TrainerSpeciesMode = "Random"; TrainerMoveMode = "Random4"; TrainerSmogonMoveFallbackMode = "Random4"; TrainerItemMode = "ForceAll"; TrainerItemPoolMode = "FullRandom"; TrainerAbilityMode = "RandomSlot"; TrainerIVMode = "Random"; TrainerEVMode = "RandomLegal"; TrainerNatureMode = "Random"; TrainerAddedSlotSpeciesMode = "Random"; TrainerDuplicateMode = "Normal"
                TrainerLevelMultiplier = "1.0"; TrainerTeamMin = "-1"; TrainerTeamMax = "-1"; TrainerShinyChancePercent = "3"; TrainerFullyEvolvedLevel = "30"; TrainerDynamaxLevelMode = "Random0To10"
                RandomizeTrainerNatures = $false; TrainerTypeThemed = $false; ForceTrainerFullyEvolved = $true; MaxTrainerAI = $true; ForceTrainerCanDynamax = $true; ForceAllTeamsToSix = $true; ForceBossTeamsToSix = $false; BossTeamsToSixScope = "MajorBosses"; AllowLegendaryTrainers = $true
                TypeMode = "Random"; AbilityMode = "Random"; StatMode = "Shuffle"; ExpYieldMultiplier = "1.5"; ForceOneExpYield = $false; RandomizeMoveTypes = $true; RandomizeMovePower = $true; RandomizeMovePP = $true; RandomizeMoveAccuracy = $true; RandomizeMoveCategory = $true; RandomizePickupItems = $true; RandomizeShopItems = $true; RandomizeTechnicalRecords = $true
                EvolutionMode = "Random"; GiftMode = "Random"; StarterMode = "Random"; TradeMode = "Random"; PatchStarterRelatedTrainers = $true; AllowLegendaryEvolutions = $true; AllowLegendaryGifts = $true; AllowLegendaryTrades = $true
                StaticEncounterMode = "Random"; StaticEncounterStableMapping = "Random"; GrassEncounterMode = "Random"; GrassEncounterStableMapping = "Random"; VisibleEncounterBehavior = "RandomVisualBattleRandom"; UndergroundMode = "Random"
                AllowLegendaryStaticEncounters = $true; AllowLegendaryGrassEncounters = $true; AllowLegendaryUnderground = $true; DisableExpShare = $false; RuntimePcControls = $false; GymLeagueStoryLevelCap = $false; RaceMode = $false; ExportEncounterZoneReport = $true
            }
        }
    }
}

function Get-DifficultyProfileComboItems {
    param([string]$Language = "fr")

    $lang = if ($Language -eq "en") { "en" } else { "fr" }
    $items = New-Object System.Collections.Generic.List[object]
    foreach ($profile in (Get-DifficultyProfileDefinitions).Values) {
        $items.Add([pscustomobject]@{
            Label = [string]$profile.Labels[$lang]
            Value = [string]$profile.Key
        })
    }
    return [object[]]$items.ToArray()
}

function Get-DifficultyProfileBaselineOptions {
    return [ordered]@{
        TypesMonotypeOnly = $false
        AllowWonderGuard = $false
        AllowLegendaryEvolutions = $false
        AllowLegendaryGifts = $false
        AllowLegendaryTrades = $false
        NormalizeFriendshipEvolutions = $false
        FriendshipEvolutionLevel = "30"
        NormalizeTradeEvolutions = $false
        TradeEvolutionLevel = "37"
        NormalizeSpecialEvolutions = $false
        SpecialEvolutionLevel = "36"
        MovePowerMin = "20"
        MovePowerMax = "150"
        MovePPMin = "5"
        MovePPMax = "40"
        MoveAccuracyMin = "70"
        MoveAccuracyMax = "100"
    }
}

function Apply-DifficultyProfileToControls {
    param(
        [System.Collections.Hashtable]$Controls,
        [string]$ProfileKey
    )

    $definitions = Get-DifficultyProfileDefinitions
    if (-not $definitions.Contains($ProfileKey)) {
        throw "Profil de difficulte inconnu: $ProfileKey"
    }

    $profile = $definitions[$ProfileKey]
    $applied = 0
    if ($ProfileKey -ne "Custom") {
        foreach ($entry in (Get-DifficultyProfileBaselineOptions).GetEnumerator()) {
            if (Set-GuiControlValue -Controls $Controls -Name ([string]$entry.Key) -Value $entry.Value) {
                $applied++
            }
        }
    }
    foreach ($entry in $profile.Options.GetEnumerator()) {
        if (Set-GuiControlValue -Controls $Controls -Name ([string]$entry.Key) -Value $entry.Value) {
            $applied++
        }
    }

    return [pscustomobject]@{
        Profile = $profile
        Applied = $applied
    }
}

function Try-ParseInvariantDouble {
    param(
        [string]$Text,
        [ref]$Value
    )

    $styles = [System.Globalization.NumberStyles]::Float
    $culture = [System.Globalization.CultureInfo]::InvariantCulture
    $normalized = ([string]$Text).Trim().Replace(",", ".")
    return [double]::TryParse($normalized, $styles, $culture, $Value)
}

function Convert-GuiDoubleText {
    param(
        [string]$Text,
        [string]$Label,
        [string]$Language = "fr"
    )

    $value = 0.0
    if (-not (Try-ParseInvariantDouble -Text $Text -Value ([ref]$value))) {
        if ($Language -eq "en") {
            throw "$Label must be numeric."
        }
        throw "$Label doit etre numerique."
    }
    return $value
}

function Test-GuiBuildConfiguration {
    param(
        [System.Collections.Hashtable]$Controls,
        [string]$Language = "fr"
    )

    $lang = if ($Language -eq "en") { "en" } else { "fr" }
    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]
    $infos = New-Object System.Collections.Generic.List[string]

    $addError = { param([string]$Message) [void]$errors.Add($Message) }
    $addWarning = { param([string]$Message) [void]$warnings.Add($Message) }
    $addInfo = { param([string]$Message) [void]$infos.Add($Message) }

    $textOf = {
        param([string]$Name)
        if ($Controls.ContainsKey($Name) -and $Controls[$Name] -is [System.Windows.Forms.TextBox]) {
            return ([string]$Controls[$Name].Text).Trim()
        }
        return ""
    }
    $checkedOf = {
        param([string]$Name)
        return ($Controls.ContainsKey($Name) -and $Controls[$Name] -is [System.Windows.Forms.CheckBox] -and [bool]$Controls[$Name].Checked)
    }
    $comboOf = {
        param([string]$Name)
        if ($Controls.ContainsKey($Name) -and $Controls[$Name] -is [System.Windows.Forms.ComboBox]) {
            return [string](Get-ComboValue -Combo $Controls[$Name])
        }
        return ""
    }

    $sourceRomfs = ""
    $sourceExefs = ""
    $outputPackage = ""
    $sourceRomfsText = & $textOf "Source"
    $sourceExefsText = & $textOf "SourceExefs"
    $outputText = & $textOf "Output"
    $gameVersion = & $comboOf "GameVersion"

    try {
        $sourceRomfs = Resolve-RequiredSourceRomfsRoot -SourceRomfsRoot $sourceRomfsText
        Assert-ValidSourceRomfsForRandomizer -RomfsRoot $sourceRomfs
        & $addInfo $(if ($lang -eq "en") { "ROMFS source OK: $sourceRomfs" } else { "Source ROMFS OK: $sourceRomfs" })
    } catch {
        & $addError $_.Exception.Message
    }

    if ([string]::IsNullOrWhiteSpace($outputText)) {
        & $addError $(if ($lang -eq "en") { "Generated mod folder is required." } else { "Dossier du mod genere obligatoire." })
    } else {
        try {
            $outputPackage = Get-OutputPackageRoot -OutputRomfsRoot $outputText
            [void](Resolve-OutputRomfsRoot -OutputPath $outputText)
            if (-not [string]::IsNullOrWhiteSpace($sourceRomfs)) {
                if (Test-PathInsideRoot -Path $outputPackage -Root $sourceRomfs) {
                    & $addError $(if ($lang -eq "en") { "Output cannot be inside the source ROMFS folder." } else { "La sortie ne peut pas etre dans le dossier ROMFS source." })
                }
                if (Test-PathInsideRoot -Path $sourceRomfs -Root $outputPackage) {
                    & $addError $(if ($lang -eq "en") { "Source ROMFS cannot be inside the generated output folder." } else { "Le ROMFS source ne peut pas etre dans le dossier de sortie genere." })
                }
            }
            & $addInfo $(if ($lang -eq "en") { "Output root OK: $outputPackage" } else { "Dossier de sortie OK: $outputPackage" })
        } catch {
            & $addError $_.Exception.Message
        }
    }

    $seedText = & $textOf "Seed"
    $seedValue = 0L
    if (-not [long]::TryParse($seedText, [ref]$seedValue)) {
        & $addError $(if ($lang -eq "en") { "Seed must be a numeric integer. Use -1 for auto." } else { "Le seed doit etre un entier numerique. Utilise -1 pour auto." })
    }

    $needsRuntime = $false
    $runtimeReasons = New-Object System.Collections.Generic.List[string]
    $visibleBehavior = Get-NormalizedVisibleEncounterBehavior -Value (& $comboOf "VisibleEncounterBehavior")
    $expMultiplier = 1.0
    [void](Try-ParseInvariantDouble -Text (& $textOf "ExpYieldMultiplier") -Value ([ref]$expMultiplier))
    if (& $checkedOf "RuntimePcControls") { $needsRuntime = $true; [void]$runtimeReasons.Add("PC runtime") }
    if (& $checkedOf "DisableExpShare") { $needsRuntime = $true; [void]$runtimeReasons.Add("EXP Share runtime") }
    if (& $checkedOf "EarlyBike") { $needsRuntime = $true; [void]$runtimeReasons.Add("early bike") }
    if (& $checkedOf "DynamicExpLevelCap") { $needsRuntime = $true; [void]$runtimeReasons.Add("dynamic EXP cap") }
    if (& $checkedOf "StrictBossMaxLevelCap") { $needsRuntime = $true; [void]$runtimeReasons.Add("strict boss EXP cap") }
    if (& $checkedOf "MainStorySoftLevelCap") { $needsRuntime = $true; [void]$runtimeReasons.Add("soft story EXP cap") }
    if (& $checkedOf "GymLeagueStoryLevelCap") { $needsRuntime = $true; [void]$runtimeReasons.Add("gym/champion EXP cap") }
    if (& $checkedOf "StoryMajorBattleOrderLevelCap") { $needsRuntime = $true; [void]$runtimeReasons.Add("ordered major battle EXP cap") }
    if ((-not (& $checkedOf "ForceOneExpYield")) -and [Math]::Abs($expMultiplier - 1.0) -gt 0.0001) { $needsRuntime = $true; [void]$runtimeReasons.Add("EXP boost") }
    if ($visibleBehavior -ne "RomfsMatch") { $needsRuntime = $true; [void]$runtimeReasons.Add("visible/combat split") }

    if ($needsRuntime) {
        if ([string]::IsNullOrWhiteSpace($sourceExefsText)) {
            & $addWarning $(if ($lang -eq "en") { "Runtime/ExLaunch options are enabled, but no ExeFS folder was explicitly provided. The build will stay ROMFS-only and will not generate exefs or sdmc." } else { "Des options runtime/ExLaunch sont actives, mais aucun dossier ExeFS n'a ete explicitement fourni. La generation restera en mode ROMFS-only et ne produira ni exefs ni sdmc." })
        } else {
            try {
                $sourceExefs = Resolve-RequiredSourceExefsRoot -SourceRomfsRoot $sourceRomfsText -SourceExefsRoot $sourceExefsText -GameVersion $gameVersion
                & $addInfo $(if ($lang -eq "en") { "ExeFS source OK for runtime features: $sourceExefs" } else { "Source ExeFS OK pour les options runtime: $sourceExefs" })
            } catch {
                & $addError $_.Exception.Message
            }
        }
    } elseif (-not [string]::IsNullOrWhiteSpace($sourceExefsText)) {
        try {
            $sourceExefs = Resolve-SourceExefsRoot -SourceRomfsRoot $sourceRomfsText -SourceExefsRoot $sourceExefsText -GameVersion $gameVersion
            if (-not [string]::IsNullOrWhiteSpace($sourceExefs)) {
                & $addInfo $(if ($lang -eq "en") { "ExeFS source detected: $sourceExefs" } else { "Source ExeFS detectee: $sourceExefs" })
            }
        } catch {
            & $addWarning $_.Exception.Message
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($sourceExefs) -and -not [string]::IsNullOrWhiteSpace($outputPackage)) {
        if (Test-PathInsideRoot -Path $outputPackage -Root $sourceExefs) {
            & $addError $(if ($lang -eq "en") { "Output cannot be inside the source ExeFS folder." } else { "La sortie ne peut pas etre dans le dossier ExeFS source." })
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($sourceRomfs)) {
        $requiredFiles = New-Object System.Collections.Generic.HashSet[string]
        $requiredDirs = New-Object System.Collections.Generic.HashSet[string]
        [void]$requiredFiles.Add("bin\pml\personal\personal_total.bin")
        [void]$requiredDirs.Add("bin\trainer\trainer_data")
        [void]$requiredDirs.Add("bin\trainer\trainer_poke")

        $trainerMoveMode = Normalize-Mode (& $comboOf "TrainerMoveMode")
        $smogonFallback = Normalize-Mode (& $comboOf "TrainerSmogonMoveFallbackMode")
        if ($trainerMoveMode -eq "lastlevelup4" -or ((Test-TrainerModeUsesSmogon $trainerMoveMode) -and $smogonFallback -eq "lastlevelup4")) {
            [void]$requiredFiles.Add("bin\pml\waza_oboe\wazaoboe_total.bin")
        }
        if ($trainerMoveMode -eq "random4" -or (Test-TrainerModeUsesSmogon $trainerMoveMode) -or (& $checkedOf "RandomizeMoveTypes") -or (& $checkedOf "RandomizeMovePower") -or (& $checkedOf "RandomizeMovePP") -or (& $checkedOf "RandomizeMoveAccuracy") -or (& $checkedOf "RandomizeMoveCategory")) {
            [void]$requiredDirs.Add("bin\pml\waza")
        }
        if ((Normalize-Mode (& $comboOf "EvolutionMode")) -ne "unchanged" -or (& $checkedOf "NormalizeFriendshipEvolutions") -or (& $checkedOf "NormalizeTradeEvolutions") -or (& $checkedOf "NormalizeSpecialEvolutions") -or (& $checkedOf "ForceTrainerFullyEvolved")) {
            [void]$requiredDirs.Add("bin\pml\evolution")
        }
        if ((Normalize-Mode (& $comboOf "GiftMode")) -ne "unchanged" -or (Normalize-Mode (& $comboOf "StarterMode")) -ne "unchanged" -or -not [string]::IsNullOrWhiteSpace((& $textOf "Starter1") + (& $textOf "Starter2") + (& $textOf "Starter3"))) {
            [void]$requiredFiles.Add("bin\script_event_data\add_poke.bin")
        }
        if ((Normalize-Mode (& $comboOf "TradeMode")) -ne "unchanged") {
            [void]$requiredFiles.Add("bin\script_event_data\field_trade.bin")
        }
        if ((Normalize-Mode (& $comboOf "StaticEncounterMode")) -ne "unchanged") {
            [void]$requiredFiles.Add("bin\script_event_data\event_encount_data.bin")
        }
        if ((Normalize-Mode (& $comboOf "GrassEncounterMode")) -ne "unchanged" -or $visibleBehavior -ne "RomfsMatch") {
            [void]$requiredFiles.Add("bin\archive\field\resident\data_table.gfpak")
        }
        if ((Normalize-Mode (& $comboOf "UndergroundMode")) -ne "unchanged") {
            [void]$requiredFiles.Add("bin\appli\chika\data_table\underground_exploration_poke.bin")
        }
        if (& $checkedOf "RuntimePcControls") {
            [void]$requiredFiles.Add("bin\script\param\script_id\script_id_record.bin")
        }

        foreach ($relativeDir in @($requiredDirs)) {
            if (-not (Test-Path -LiteralPath (Join-Path $sourceRomfs $relativeDir) -PathType Container)) {
                & $addError $(if ($lang -eq "en") { "Missing required ROMFS folder: $relativeDir" } else { "Dossier ROMFS requis manquant: $relativeDir" })
            }
        }
        foreach ($relativeFile in @($requiredFiles)) {
            $path = Join-Path $sourceRomfs $relativeFile
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
                & $addError $(if ($lang -eq "en") { "Missing required ROMFS file: $relativeFile" } else { "Fichier ROMFS requis manquant: $relativeFile" })
            } elseif ((Get-Item -LiteralPath $path).Length -le 0) {
                & $addError $(if ($lang -eq "en") { "Required ROMFS file is empty: $relativeFile" } else { "Fichier ROMFS requis vide: $relativeFile" })
            }
        }
    }

    $validateDouble = {
        param([string]$Name, [string]$Label, [double]$Min, [double]$Max)
        $value = 0.0
        if (-not (Try-ParseInvariantDouble -Text (& $textOf $Name) -Value ([ref]$value))) {
            & $addError $(if ($lang -eq "en") { "$Label must be numeric." } else { "$Label doit etre numerique." })
            return $null
        }
        if ($value -lt $Min -or $value -gt $Max) {
            & $addError $(if ($lang -eq "en") { "$Label must be between $Min and $Max." } else { "$Label doit etre entre $Min et $Max." })
        }
        return $value
    }
    $validateInt = {
        param([string]$Name, [string]$Label, [int]$Min, [int]$Max, [bool]$AllowMinusOne)
        $value = 0
        if (-not [int]::TryParse((& $textOf $Name), [ref]$value)) {
            & $addError $(if ($lang -eq "en") { "$Label must be an integer." } else { "$Label doit etre un entier." })
            return $null
        }
        if ($AllowMinusOne -and $value -eq -1) {
            return $value
        }
        if ($value -lt $Min -or $value -gt $Max) {
            & $addError $(if ($lang -eq "en") { "$Label must be between $Min and $Max." } else { "$Label doit etre entre $Min et $Max." })
        }
        return $value
    }

    $levelMult = & $validateDouble "TrainerLevelMultiplier" $(if ($lang -eq "en") { "Trainer level multiplier" } else { "Multiplicateur des niveaux" }) 0.1 10.0
    if ($levelMult -and $levelMult -gt 3.0) {
        & $addWarning $(if ($lang -eq "en") { "Trainer level multiplier is very high; many teams may clamp to Lv.100." } else { "Le multiplicateur de niveau est tres haut; beaucoup d'equipes peuvent finir bloquees au niveau 100." })
    }
    $teamMin = & $validateInt "TrainerTeamMin" $(if ($lang -eq "en") { "Minimum team size" } else { "Taille equipe minimum" }) 1 6 $true
    $teamMax = & $validateInt "TrainerTeamMax" $(if ($lang -eq "en") { "Maximum team size" } else { "Taille equipe maximum" }) 1 6 $true
    if ($null -ne $teamMin -and $null -ne $teamMax -and $teamMin -ne -1 -and $teamMax -ne -1 -and $teamMin -gt $teamMax) {
        & $addError $(if ($lang -eq "en") { "Minimum team size cannot be higher than maximum team size." } else { "La taille equipe minimum ne peut pas etre superieure au maximum." })
    }
    [void](& $validateDouble "TrainerShinyChancePercent" $(if ($lang -eq "en") { "Trainer shiny rate" } else { "Taux shiny dresseurs" }) 0.0 100.0)
    [void](& $validateInt "TrainerFullyEvolvedLevel" $(if ($lang -eq "en") { "Final evolution level" } else { "Niveau evolution finale" }) 1 100 $false)
    [void](& $validateDouble "ExpYieldMultiplier" $(if ($lang -eq "en") { "EXP yield multiplier" } else { "Multiplicateur EXP" }) 0.01 50.0)
    [void](& $validateInt "MovePowerMin" $(if ($lang -eq "en") { "Move power min" } else { "Puissance min" }) 1 250 $false)
    $movePowerMax = & $validateInt "MovePowerMax" $(if ($lang -eq "en") { "Move power max" } else { "Puissance max" }) 1 250 $false
    $movePowerMin = 0
    [void][int]::TryParse((& $textOf "MovePowerMin"), [ref]$movePowerMin)
    if ($movePowerMax -and $movePowerMin -gt $movePowerMax) {
        & $addError $(if ($lang -eq "en") { "Move power min cannot be higher than move power max." } else { "La puissance min ne peut pas etre superieure a la puissance max." })
    }
    [void](& $validateInt "MovePPMin" $(if ($lang -eq "en") { "Move PP min" } else { "PP min" }) 1 64 $false)
    $movePPMax = & $validateInt "MovePPMax" $(if ($lang -eq "en") { "Move PP max" } else { "PP max" }) 1 64 $false
    $movePPMin = 0
    [void][int]::TryParse((& $textOf "MovePPMin"), [ref]$movePPMin)
    if ($movePPMax -and $movePPMin -gt $movePPMax) {
        & $addError $(if ($lang -eq "en") { "Move PP min cannot be higher than move PP max." } else { "Les PP min ne peuvent pas etre superieurs aux PP max." })
    }
    [void](& $validateInt "MoveAccuracyMin" $(if ($lang -eq "en") { "Move accuracy min" } else { "Precision min" }) 1 100 $false)
    $moveAccuracyMax = & $validateInt "MoveAccuracyMax" $(if ($lang -eq "en") { "Move accuracy max" } else { "Precision max" }) 1 100 $false
    $moveAccuracyMin = 0
    [void][int]::TryParse((& $textOf "MoveAccuracyMin"), [ref]$moveAccuracyMin)
    if ($moveAccuracyMax -and $moveAccuracyMin -gt $moveAccuracyMax) {
        & $addError $(if ($lang -eq "en") { "Move accuracy min cannot be higher than move accuracy max." } else { "La precision min ne peut pas etre superieure a la precision max." })
    }

    if ((& $checkedOf "ForceOneExpYield") -and [Math]::Abs($expMultiplier - 1.0) -gt 0.0001) {
        & $addWarning $(if ($lang -eq "en") { "No EXP mode overrides the EXP multiplier; the multiplier will not matter." } else { "Le mode No EXP prend le dessus sur le multiplicateur EXP; le multiplicateur ne servira pas." })
    }
    if ((& $checkedOf "ForceAllTeamsToSix") -and (& $checkedOf "ForceBossTeamsToSix")) {
        & $addWarning $(if ($lang -eq "en") { "All teams at 6 already includes boss teams; the boss-only option is redundant." } else { "Mettre tous les dresseurs a 6 inclut deja les boss; l'option boss seulement est redondante." })
    }
    if ((Normalize-Mode (& $comboOf "TrainerSpeciesMode")) -eq "unchanged" -and (& $checkedOf "TrainerTypeThemed")) {
        & $addWarning $(if ($lang -eq "en") { "Type-themed trainer teams only matters when trainer species are randomized." } else { "Les equipes themees par type servent surtout quand les especes des dresseurs sont randomisees." })
    }
    if ((Normalize-Mode (& $comboOf "TrainerItemMode")) -eq "removeall") {
        & $addWarning $(if ($lang -eq "en") { "Held item pool is ignored because held items are removed." } else { "Le pool d'objets est ignore car les objets tenus sont supprimes." })
    }
    $validationUsesSmogon = (Test-TrainerModeUsesSmogon (& $comboOf "TrainerMoveMode")) -or (Test-TrainerModeUsesSmogon (& $comboOf "TrainerItemMode")) -or (Test-TrainerModeUsesSmogon (& $comboOf "TrainerAbilityMode")) -or (Test-TrainerModeUsesSmogon (& $comboOf "TrainerEVMode")) -or (Test-TrainerModeUsesSmogon (& $comboOf "TrainerNatureMode"))
    $validationUsesLegacySmogon = (Test-TrainerModeUsesSmogonLegacy (& $comboOf "TrainerMoveMode")) -or (Test-TrainerModeUsesSmogonLegacy (& $comboOf "TrainerItemMode")) -or (Test-TrainerModeUsesSmogonLegacy (& $comboOf "TrainerAbilityMode")) -or (Test-TrainerModeUsesSmogonLegacy (& $comboOf "TrainerEVMode")) -or (Test-TrainerModeUsesSmogonLegacy (& $comboOf "TrainerNatureMode"))
    if ($validationUsesSmogon) {
        & $addInfo $(if ($lang -eq "en") { "Smogon strategic modes use one coherent cached set per Pokemon when present, then fall back to safe local choices if a set is missing." } else { "Les modes Strategique Smogon utilisent un meme set coherent en cache par Pokemon quand il existe, puis un backup propre si un set manque." })
    }
    if ($validationUsesLegacySmogon) {
        & $addInfo $(if ($lang -eq "en") { "Smogon historical mode tries SS first, then SM, XY, BW, DP, RS, GS and RB; if no set exists, the configured backup is used." } else { "Le mode Smogon anciennes gens essaie SS d'abord, puis SM, XY, BW, DP, RS, GS et RB; si aucun set n'existe, le backup configure est utilise." })
    }
    if ($needsRuntime) {
        & $addInfo $(if ($lang -eq "en") { "Runtime features enabled: $($runtimeReasons -join ', ')." } else { "Options runtime actives: $($runtimeReasons -join ', ')." })
    }
    if ((& $checkedOf "AutoInstallToEden") -and -not ((& $checkedOf "InstallToEden") -or (& $checkedOf "InstallToRyujinx") -or (& $checkedOf "InstallToYuzu") -or (& $checkedOf "InstallToSudachi") -or (& $checkedOf "InstallToCitron") -or (& $checkedOf "InstallToSuyu") -or (& $checkedOf "InstallToCitronNeo"))) {
        & $addError $(if ($lang -eq "en") { "Auto-install is enabled but no emulator target is selected." } else { "L'installation auto est activee mais aucune cible emulateur n'est cochee." })
    }

    return [pscustomobject]@{
        Errors = $errors
        Warnings = $warnings
        Infos = $infos
    }
}

function Format-GuiBuildValidationResult {
    param(
        [object]$Validation,
        [string]$Language = "fr"
    )

    $lang = if ($Language -eq "en") { "en" } else { "fr" }
    $lines = New-Object System.Collections.Generic.List[string]
    if ($Validation.Errors.Count -eq 0 -and $Validation.Warnings.Count -eq 0) {
        [void]$lines.Add($(if ($lang -eq "en") { "Validation OK: the build can start." } else { "Validation OK: la generation peut demarrer." }))
    } else {
        [void]$lines.Add($(if ($lang -eq "en") { "Validation result:" } else { "Resultat de validation:" }))
    }
    foreach ($message in @($Validation.Errors)) {
        [void]$lines.Add("ERREUR: $message")
    }
    foreach ($message in @($Validation.Warnings)) {
        [void]$lines.Add($(if ($lang -eq "en") { "WARNING: $message" } else { "AVERTISSEMENT: $message" }))
    }
    foreach ($message in @($Validation.Infos | Select-Object -First 8)) {
        [void]$lines.Add("OK: $message")
    }
    return ($lines -join [Environment]::NewLine)
}

function Confirm-GuiBuildValidationResult {
    param(
        [System.Windows.Forms.Form]$Owner,
        [object]$Validation,
        [string]$Language = "fr",
        [bool]$ConfirmWarnings = $true
    )

    $lang = if ($Language -eq "en") { "en" } else { "fr" }
    $text = Format-GuiBuildValidationResult -Validation $Validation -Language $lang
    if ($Validation.Errors.Count -gt 0) {
        $title = if ($lang -eq "en") { "Build blocked" } else { "Generation bloquee" }
        [void][System.Windows.Forms.MessageBox]::Show($Owner, $text, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return $false
    }
    if ($ConfirmWarnings -and $Validation.Warnings.Count -gt 0) {
        $title = if ($lang -eq "en") { "Continue with warnings?" } else { "Continuer avec avertissements ?" }
        $question = if ($lang -eq "en") { "$text`r`n`r`nContinue generation anyway?" } else { "$text`r`n`r`nContinuer la generation quand meme ?" }
        $answer = [System.Windows.Forms.MessageBox]::Show($Owner, $question, $title, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return ($answer -eq [System.Windows.Forms.DialogResult]::Yes)
    }
    return $true
}

function Get-GuiBuildSummaryText {
    param(
        [System.Collections.Hashtable]$Controls,
        [object]$Validation = $null,
        [string]$Language = "fr"
    )

    $lang = if ($Language -eq "en") { "en" } else { "fr" }
    $lines = New-Object System.Collections.Generic.List[string]
    $changed = 0

    $textOf = {
        param([string]$Name)
        if ($Controls.ContainsKey($Name) -and $Controls[$Name] -is [System.Windows.Forms.TextBox]) {
            return ([string]$Controls[$Name].Text).Trim()
        }
        return ""
    }
    $checkedOf = {
        param([string]$Name)
        return ($Controls.ContainsKey($Name) -and $Controls[$Name] -is [System.Windows.Forms.CheckBox] -and [bool]$Controls[$Name].Checked)
    }
    $comboValue = {
        param([string]$Name)
        if ($Controls.ContainsKey($Name) -and $Controls[$Name] -is [System.Windows.Forms.ComboBox]) {
            return [string](Get-ComboValue -Combo $Controls[$Name])
        }
        return ""
    }
    $comboLabel = {
        param([string]$Name)
        if ($Controls.ContainsKey($Name) -and $Controls[$Name] -is [System.Windows.Forms.ComboBox] -and $Controls[$Name].SelectedItem) {
            return [string]$Controls[$Name].SelectedItem.Label
        }
        return (& $comboValue $Name)
    }
    $yesNo = {
        param([bool]$Value)
        if ($lang -eq "en") {
            return $(if ($Value) { "YES" } else { "NO" })
        }
        return $(if ($Value) { "OUI" } else { "NON" })
    }
    $addLine = {
        param([string]$Text = "")
        [void]$lines.Add($Text)
    }
    $addSection = {
        param([string]$Title)
        & $addLine ""
        & $addLine ("=== {0} ===" -f $Title)
    }
    $addChange = {
        param(
            [string]$Label,
            [string]$Value
        )
        if (-not [string]::IsNullOrWhiteSpace($Label) -and -not [string]::IsNullOrWhiteSpace($Value)) {
            [void]$lines.Add(("- {0}: {1}" -f $Label, $Value))
            $script:GuiBuildSummaryChangedCount++
        }
    }
    $addIfComboChanged = {
        param(
            [string]$Name,
            [string]$Label,
            [string[]]$UnchangedValues = @("Unchanged")
        )
        $value = & $comboValue $Name
        if (-not [string]::IsNullOrWhiteSpace($value) -and ($UnchangedValues -notcontains $value)) {
            & $addChange $Label (& $comboLabel $Name)
        }
    }
    $addIfChecked = {
        param(
            [string]$Name,
            [string]$Label,
            [string]$Value = ""
        )
        if (& $checkedOf $Name) {
            if ([string]::IsNullOrWhiteSpace($Value)) {
                $Value = & $yesNo $true
            }
            & $addChange $Label $Value
        }
    }

    $script:GuiBuildSummaryChangedCount = 0
    $title = if ($lang -eq "en") { "What will be modified" } else { "Ce qui va etre modifie" }
    & $addLine $title
    & $addLine ("=" * $title.Length)

    & $addSection $(if ($lang -eq "en") { "Source and output" } else { "Source et sortie" })
    & $addChange $(if ($lang -eq "en") { "Target game" } else { "Jeu cible" }) (& $comboLabel "GameVersion")
    & $addChange "ROMFS" (& $textOf "Source")
    & $addChange "ExeFS" (& $textOf "SourceExefs")
    & $addChange $(if ($lang -eq "en") { "Generated mod folder" } else { "Dossier genere" }) (& $textOf "Output")
    & $addChange "Seed" (& $textOf "Seed")
    & $addChange $(if ($lang -eq "en") { "Difficulty profile" } else { "Profil de difficulte" }) (& $comboLabel "DifficultyProfile")

    & $addSection $(if ($lang -eq "en") { "Runtime / ExLaunch" } else { "Runtime / ExLaunch" })
    & $addIfChecked "DisableExpShare" $(if ($lang -eq "en") { "Default EXP Share" } else { "EXP Share par defaut" }) "OFF"
    & $addIfChecked "RuntimePcControls" $(if ($lang -eq "en") { "Pokemon Center PC menu" } else { "Menu PC Centre Pokemon" }) $(if ($lang -eq "en") { "runtime toggles enabled" } else { "options modifiables en jeu" })
    & $addIfChecked "GymLeagueStoryLevelCap" $(if ($lang -eq "en") { "Gym/Champion EXP cap" } else { "Cap EXP arenes/Tarak" }) $(if ($lang -eq "en") { "enabled" } else { "active" })
    $expMultiplierText = & $textOf "ExpYieldMultiplier"
    $expMultiplierValue = 1.0
    if ((Try-ParseInvariantDouble -Text $expMultiplierText -Value ([ref]$expMultiplierValue)) -and [Math]::Abs($expMultiplierValue - 1.0) -gt 0.0001 -and -not (& $checkedOf "ForceOneExpYield")) {
        & $addChange $(if ($lang -eq "en") { "Runtime EXP boost" } else { "Boost EXP runtime" }) ("x{0}" -f $expMultiplierValue.ToString("0.##", [System.Globalization.CultureInfo]::InvariantCulture))
    }
    $visibleBehavior = Get-NormalizedVisibleEncounterBehavior -Value (& $comboValue "VisibleEncounterBehavior")
    if ($visibleBehavior -ne "RomfsMatch") {
        & $addChange $(if ($lang -eq "en") { "Visible Pokemon hook" } else { "Hook Pokemon visibles" }) (& $comboLabel "VisibleEncounterBehavior")
    }
    if ($script:GuiBuildSummaryChangedCount -le 6) {
        & $addLine $(if ($lang -eq "en") { "- No runtime option selected, unless another tab requires ExLaunch." } else { "- Aucune option runtime selectionnee, sauf si une autre option exige ExLaunch." })
    }

    & $addSection $(if ($lang -eq "en") { "Trainer battles" } else { "Combats de dresseurs" })
    & $addIfComboChanged "TrainerSpeciesMode" $(if ($lang -eq "en") { "Trainer Pokemon" } else { "Pokemon des dresseurs" })
    & $addIfComboChanged "TrainerMoveMode" $(if ($lang -eq "en") { "Trainer moves" } else { "Attaques des dresseurs" })
    if (Test-TrainerModeUsesSmogon (& $comboValue "TrainerMoveMode")) {
        & $addChange $(if ($lang -eq "en") { "Smogon move fallback" } else { "Backup moves Smogon" }) (& $comboLabel "TrainerSmogonMoveFallbackMode")
    }
    & $addIfComboChanged "TrainerItemMode" $(if ($lang -eq "en") { "Trainer held items" } else { "Objets tenus dresseurs" })
    if ((Normalize-Mode (& $comboValue "TrainerItemMode")) -in @("randomwhenpresent", "forceall") -or (Test-TrainerModeUsesSmogon (& $comboValue "TrainerItemMode"))) {
        & $addChange $(if ($lang -eq "en") { "Held item pool" } else { "Pool objets tenus" }) (& $comboLabel "TrainerItemPoolMode")
    }
    & $addIfComboChanged "TrainerAbilityMode" $(if ($lang -eq "en") { "Trainer abilities" } else { "Talents dresseurs" })
    & $addIfComboChanged "TrainerIVMode" "IV"
    & $addIfComboChanged "TrainerEVMode" "EV"
    $levelMultiplierText = & $textOf "TrainerLevelMultiplier"
    $levelMultiplierValue = 1.0
    if ((Try-ParseInvariantDouble -Text $levelMultiplierText -Value ([ref]$levelMultiplierValue)) -and [Math]::Abs($levelMultiplierValue - 1.0) -gt 0.0001) {
        & $addChange $(if ($lang -eq "en") { "Trainer level multiplier" } else { "Multiplicateur niveaux dresseurs" }) ("x{0}" -f $levelMultiplierValue.ToString("0.##", [System.Globalization.CultureInfo]::InvariantCulture))
    }
    if ((& $textOf "TrainerTeamMin") -ne "-1" -or (& $textOf "TrainerTeamMax") -ne "-1") {
        & $addChange $(if ($lang -eq "en") { "Trainer team size clamp" } else { "Limite taille equipes" }) ("min {0} / max {1}" -f (& $textOf "TrainerTeamMin"), (& $textOf "TrainerTeamMax"))
    }
    & $addIfChecked "ForceAllTeamsToSix" $(if ($lang -eq "en") { "All trainer teams" } else { "Toutes les equipes dresseurs" }) "6 Pokemon"
    if (& $checkedOf "ForceBossTeamsToSix") {
        & $addChange $(if ($lang -eq "en") { "Selected boss teams" } else { "Boss selectionnes" }) ("6 Pokemon - {0}" -f (& $comboLabel "BossTeamsToSixScope"))
        & $addChange $(if ($lang -eq "en") { "Added boss slots" } else { "Slots boss ajoutes" }) (& $comboLabel "TrainerAddedSlotSpeciesMode")
    }
    & $addChange $(if ($lang -eq "en") { "Team duplicate rule" } else { "Regle doublons equipes" }) (& $comboLabel "TrainerDuplicateMode")
    & $addIfChecked "TrainerTypeThemed" $(if ($lang -eq "en") { "Type-themed teams" } else { "Equipes themees par type" })
    & $addIfChecked "ForceTrainerFullyEvolved" $(if ($lang -eq "en") { "Force final evolutions" } else { "Forcer evolutions finales" }) ("Lv. {0}+" -f (& $textOf "TrainerFullyEvolvedLevel"))
    & $addIfComboChanged "TrainerNatureMode" $(if ($lang -eq "en") { "Trainer natures" } else { "Natures dresseurs" })
    & $addIfChecked "MaxTrainerAI" $(if ($lang -eq "en") { "Trainer AI" } else { "IA dresseurs" }) $(if ($lang -eq "en") { "maximum" } else { "maximum" })
    & $addIfComboChanged "TrainerDynamaxLevelMode" $(if ($lang -eq "en") { "Trainer Dynamax level" } else { "Niveau Dynamax dresseurs" })
    & $addIfChecked "ForceTrainerCanDynamax" $(if ($lang -eq "en") { "Trainer Dynamax flag" } else { "Flag CanDynamax dresseurs" })
    & $addIfChecked "AllowLegendaryTrainers" $(if ($lang -eq "en") { "Trainer legendary pool" } else { "Legendaires chez les dresseurs" }) $(if ($lang -eq "en") { "allowed" } else { "autorises" })
    $trainerShinyText = & $textOf "TrainerShinyChancePercent"
    $trainerShinyValue = 0.0
    if ((Try-ParseInvariantDouble -Text $trainerShinyText -Value ([ref]$trainerShinyValue)) -and $trainerShinyValue -gt 0.0) {
        & $addChange $(if ($lang -eq "en") { "Trainer shiny rate" } else { "Taux shiny dresseurs" }) ("{0}%" -f $trainerShinyValue.ToString("0.##", [System.Globalization.CultureInfo]::InvariantCulture))
    }

    & $addSection $(if ($lang -eq "en") { "Pokemon species data and moves" } else { "Donnees Pokemon et attaques" })
    & $addIfComboChanged "TypeMode" $(if ($lang -eq "en") { "Species types" } else { "Types des especes" })
    & $addIfChecked "TypesMonotypeOnly" $(if ($lang -eq "en") { "Monotype types" } else { "Types monotype" })
    & $addIfComboChanged "AbilityMode" $(if ($lang -eq "en") { "Species abilities" } else { "Talents des especes" })
    & $addIfChecked "AllowWonderGuard" "Wonder Guard" $(if ($lang -eq "en") { "allowed" } else { "autorise" })
    & $addIfComboChanged "StatMode" $(if ($lang -eq "en") { "Base stats" } else { "Stats de base" })
    & $addIfChecked "ForceOneExpYield" $(if ($lang -eq "en") { "EXP yield" } else { "EXP donne" }) "1"
    & $addIfChecked "RandomizeMoveTypes" $(if ($lang -eq "en") { "Move types" } else { "Types d'attaques" })
    & $addIfChecked "RandomizeMovePower" $(if ($lang -eq "en") { "Move power" } else { "Puissance attaques" }) ("{0}-{1}" -f (& $textOf "MovePowerMin"), (& $textOf "MovePowerMax"))
    & $addIfChecked "RandomizeMovePP" "PP" ("{0}-{1}" -f (& $textOf "MovePPMin"), (& $textOf "MovePPMax"))
    & $addIfChecked "RandomizeMoveAccuracy" $(if ($lang -eq "en") { "Move accuracy" } else { "Precision attaques" }) ("{0}-{1}" -f (& $textOf "MoveAccuracyMin"), (& $textOf "MoveAccuracyMax"))
    & $addIfChecked "RandomizeMoveCategory" $(if ($lang -eq "en") { "Move category" } else { "Categorie physique/special" })
    & $addIfChecked "RandomizePickupItems" $(if ($lang -eq "en") { "Pickup / field items" } else { "Objets ramassables" })
    & $addIfChecked "RandomizeShopItems" $(if ($lang -eq "en") { "Shop items" } else { "Objets boutiques" })
    & $addIfChecked "RandomizeTechnicalRecords" $(if ($lang -eq "en") { "TM/TR item IDs" } else { "CT/TR objets" })

    & $addSection $(if ($lang -eq "en") { "Evolutions, gifts, starters, trades" } else { "Evolutions, cadeaux, starters, trades" })
    & $addIfComboChanged "EvolutionMode" $(if ($lang -eq "en") { "Evolution targets" } else { "Cibles d'evolution" })
    & $addIfChecked "AllowLegendaryEvolutions" $(if ($lang -eq "en") { "Legendary evolutions" } else { "Legendaires en evolution" }) $(if ($lang -eq "en") { "allowed" } else { "autorises" })
    & $addIfChecked "NormalizeFriendshipEvolutions" $(if ($lang -eq "en") { "Friendship evolutions" } else { "Evolutions amitie" }) ("Lv. {0}" -f (& $textOf "FriendshipEvolutionLevel"))
    & $addIfChecked "NormalizeTradeEvolutions" $(if ($lang -eq "en") { "Trade evolutions" } else { "Evolutions echange" }) ("Lv. {0}" -f (& $textOf "TradeEvolutionLevel"))
    & $addIfChecked "NormalizeSpecialEvolutions" $(if ($lang -eq "en") { "Special evolutions" } else { "Evolutions speciales" }) ("Lv. {0}" -f (& $textOf "SpecialEvolutionLevel"))
    & $addIfComboChanged "GiftMode" $(if ($lang -eq "en") { "Gift Pokemon" } else { "Pokemon cadeaux" })
    & $addIfComboChanged "StarterMode" $(if ($lang -eq "en") { "Starters" } else { "Starters" })
    $manualStarters = @(@((& $textOf "Starter1"), (& $textOf "Starter2"), (& $textOf "Starter3")) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($manualStarters.Count -gt 0) {
        & $addChange $(if ($lang -eq "en") { "Manual starters" } else { "Starters manuels" }) ($manualStarters -join " / ")
    }
    & $addIfChecked "PatchStarterRelatedTrainers" $(if ($lang -eq "en") { "Starter-related trainer patch" } else { "Patch dresseurs lies aux starters" })
    & $addIfChecked "AllowLegendaryGifts" $(if ($lang -eq "en") { "Legendary gifts/starters" } else { "Legendaires cadeaux/starters" }) $(if ($lang -eq "en") { "allowed" } else { "autorises" })
    & $addIfComboChanged "TradeMode" $(if ($lang -eq "en") { "NPC trades" } else { "Trades PNJ" })
    & $addIfChecked "AllowLegendaryTrades" $(if ($lang -eq "en") { "Legendary NPC trades" } else { "Legendaires trades PNJ" }) $(if ($lang -eq "en") { "allowed" } else { "autorises" })

    & $addSection $(if ($lang -eq "en") { "Encounters" } else { "Rencontres" })
    & $addIfComboChanged "StaticEncounterMode" $(if ($lang -eq "en") { "Static/scripted encounters" } else { "Rencontres fixes/scriptes" })
    if ((Normalize-Mode (& $comboValue "StaticEncounterMode")) -ne "unchanged") {
        & $addChange $(if ($lang -eq "en") { "Static mapping" } else { "Mapping statiques" }) (& $comboLabel "StaticEncounterStableMapping")
    }
    & $addIfChecked "AllowLegendaryStaticEncounters" $(if ($lang -eq "en") { "Static legendary pool" } else { "Legendaires rencontres fixes" }) $(if ($lang -eq "en") { "allowed" } else { "autorises" })
    & $addIfComboChanged "GrassEncounterMode" $(if ($lang -eq "en") { "Wild encounter species" } else { "Rencontres sauvages" })
    if ((Normalize-Mode (& $comboValue "GrassEncounterMode")) -ne "unchanged") {
        & $addChange $(if ($lang -eq "en") { "Wild mapping" } else { "Mapping sauvage" }) (& $comboLabel "GrassEncounterStableMapping")
    }
    & $addIfChecked "AllowLegendaryGrassEncounters" $(if ($lang -eq "en") { "Wild/visible legendary pool" } else { "Legendaires herbes/visibles" }) $(if ($lang -eq "en") { "allowed" } else { "autorises" })
    & $addIfComboChanged "VisibleEncounterBehavior" $(if ($lang -eq "en") { "Visible Pokemon behavior" } else { "Comportement Pokemon visibles" }) @("RomfsMatch")
    & $addIfComboChanged "UndergroundMode" $(if ($lang -eq "en") { "Underground encounters" } else { "Underground" })
    & $addIfChecked "AllowLegendaryUnderground" $(if ($lang -eq "en") { "Underground legendary pool" } else { "Legendaires underground" }) $(if ($lang -eq "en") { "allowed" } else { "autorises" })

    & $addSection $(if ($lang -eq "en") { "Installation" } else { "Installation" })
    if (& $checkedOf "AutoInstallToEden") {
        $targets = New-Object System.Collections.Generic.List[string]
        foreach ($target in @(
            @{ Name = "InstallToEden"; Label = "Eden" },
            @{ Name = "InstallToRyujinx"; Label = "Ryujinx" },
            @{ Name = "InstallToYuzu"; Label = "Yuzu" },
            @{ Name = "InstallToSudachi"; Label = "Sudachi" },
            @{ Name = "InstallToCitron"; Label = "Citron" },
            @{ Name = "InstallToSuyu"; Label = "Suyu" },
            @{ Name = "InstallToCitronNeo"; Label = "Citron Neo" }
        )) {
            if (& $checkedOf ([string]$target["Name"])) {
                [void]$targets.Add([string]$target["Label"])
            }
        }
        & $addChange $(if ($lang -eq "en") { "Auto-install targets" } else { "Cibles installation auto" }) ($targets.ToArray() -join ", ")
        & $addChange $(if ($lang -eq "en") { "Installed mod folder" } else { "Dossier de mod installe" }) (& $textOf "EdenModName")
    } else {
        & $addLine $(if ($lang -eq "en") { "- Auto-install disabled: files are generated only in the output folder." } else { "- Installation auto desactivee: les fichiers sont seulement generes dans le dossier de sortie." })
    }

    if ($Validation -and $Validation.Warnings.Count -gt 0) {
        & $addSection $(if ($lang -eq "en") { "Validation warnings" } else { "Avertissements de validation" })
        foreach ($warning in @($Validation.Warnings)) {
            & $addLine "- $warning"
        }
    }

    if ($script:GuiBuildSummaryChangedCount -lt 1) {
        & $addLine ""
        & $addLine $(if ($lang -eq "en") { "No major randomization option is enabled. The build will mostly copy required files and reports." } else { "Aucune option majeure de randomisation n'est activee. Le build va surtout copier les fichiers requis et les rapports." })
    }

    Remove-Variable -Name GuiBuildSummaryChangedCount -Scope Script -ErrorAction SilentlyContinue
    return ($lines -join [Environment]::NewLine)
}

function Show-GuiBuildSummaryDialog {
    param(
        [System.Windows.Forms.Form]$Owner,
        [string]$SummaryText,
        [string]$Language = "fr",
        [bool]$ConfirmGeneration = $true
    )

    $lang = if ($Language -eq "en") { "en" } else { "fr" }
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = if ($lang -eq "en") { "What will be modified" } else { "Ce qui va etre modifie" }
    $dialog.ClientSize = New-Object System.Drawing.Size(780, 620)
    $dialog.MinimumSize = New-Object System.Drawing.Size(720, 520)
    $dialog.StartPosition = "CenterParent"
    $dialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
    $dialog.Font = New-GuiFont -Size 9.5

    $summaryBox = New-Object System.Windows.Forms.TextBox
    $summaryBox.Multiline = $true
    $summaryBox.ReadOnly = $true
    $summaryBox.ScrollBars = "Vertical"
    $summaryBox.WordWrap = $false
    $summaryBox.Location = New-Object System.Drawing.Point(12, 12)
    $summaryBox.Size = New-Object System.Drawing.Size(756, 548)
    $summaryBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
    $summaryBox.Text = $SummaryText
    $dialog.Controls.Add($summaryBox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Size = New-Object System.Drawing.Size(170, 34)
    $okButton.Location = New-Object System.Drawing.Point(416, 574)
    $okButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
    $okButton.Text = if ($ConfirmGeneration) {
        if ($lang -eq "en") { "Generate" } else { "Generer" }
    } else {
        if ($lang -eq "en") { "Close" } else { "Fermer" }
    }
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $dialog.AcceptButton = $okButton
    $dialog.Controls.Add($okButton)

    if ($ConfirmGeneration) {
        $cancelButton = New-Object System.Windows.Forms.Button
        $cancelButton.Size = New-Object System.Drawing.Size(170, 34)
        $cancelButton.Location = New-Object System.Drawing.Point(598, 574)
        $cancelButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
        $cancelButton.Text = if ($lang -eq "en") { "Cancel" } else { "Annuler" }
        $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $dialog.CancelButton = $cancelButton
        $dialog.Controls.Add($cancelButton)
    }

    try {
        Apply-GuiTheme -Root $dialog -Theme $script:GuiTheme
    } catch {
    }

    return ($dialog.ShowDialog($Owner) -eq [System.Windows.Forms.DialogResult]::OK)
}

function Get-LocalizedDescriptionText {
    param([object]$Description)

    if ($Description -is [System.Collections.IDictionary]) {
        $lang = if ($script:UiLanguage -eq "en") { "en" } else { "fr" }
        if ($Description.ContainsKey($lang)) {
            return [string]$Description[$lang]
        }
        if ($Description.ContainsKey("fr")) {
            return [string]$Description["fr"]
        }
        if ($Description.ContainsKey("en")) {
            return [string]$Description["en"]
        }
        return [string]($Description.Values | Select-Object -First 1)
    }

    return [string]$Description
}

function Register-ControlDescription {
    param(
        [System.Windows.Forms.Control]$Control,
        [System.Windows.Forms.TextBox]$DetailsBox,
        [object]$Description
    )

    if (-not $Control -or -not $DetailsBox) {
        return
    }

    $update = {
        param($sender, $args)
        $script:LastDetailsDescription = $Description
        $DetailsBox.Text = Get-LocalizedDescriptionText -Description $Description
    }.GetNewClosure()

    $Control.Add_Enter($update)
    $Control.Add_MouseEnter($update)
}

function Add-ConcreteDescriptionExamples {
    param(
        [hashtable]$Ui,
        [string]$Language = "fr"
    )

    if (-not $Ui -or -not $Ui.Descriptions) {
        return
    }

    if ($Language -eq "en") {
        $Ui.Descriptions.TrainerSpecies = "Trainer Pokemon species. Example: if a trainer originally has Victreebel Lv.12, Full random can turn it into Empoleon; Balanced random tries to keep similar overall power; Keep vanilla leaves Victreebel."
        $Ui.Descriptions.TrainerMoves = "Trainer Pokemon moves. Example: Smogon strategic downloads and caches Gen 8 strategy sets, then gives Empoleon or Victreebel moves from those sets when available. If Smogon has several moves, the tool picks randomly; if no set exists, the fallback dropdown decides whether to use natural level-up moves, random moves, or the current vanilla moves."
        $Ui.Descriptions.TrainerSmogonMoveFallback = "Smogon move fallback. Example: if Empoleon has no usable Smogon moves in the local move list, Natural level uses level-up moves, Random gives four random legal moves, and Keep vanilla leaves its current trainer moves."
        $Ui.Descriptions.TrainerItems = "Trainer held items. Example: Smogon strategic gives Empoleon or Victreebel an item from Gen 8 Smogon sets when available; if no set item exists, it falls back to useful battle items such as berries, Leftovers, Choice items, plates or type boosters."
        $Ui.Descriptions.TrainerItemPool = "Held item pool. Example: Battle pool is curated for useful battle held items such as berries, Leftovers, Choice items, plates and type boosters. Wide safe pool is broader and can also roll balls, medicine, mints, candies, fossils and other non-key items for a more chaotic run."
        $Ui.Descriptions.TrainerAddedSlotSpecies = "Added slot species. Example: if a Gym or league boss stays vanilla and is expanded to 6 Pokemon, Full random can add Empoleon anywhere, Similar BST keeps comparable power, Same type keeps the leader theme such as Grass for Milo, and Same type + BST keeps both theme and similar power. Leon/Tarak stays balanced instead of being forced to one type."
        $Ui.Descriptions.TrainerDuplicateMode = "Duplicate handling. Example: Block duplicates prevents two Empoleon in the same generated team; Normal random allows that rare roll if the randomizer naturally lands on Empoleon twice."
        $Ui.Descriptions.TrainerAbility = "Trainer ability slot. Example: Smogon strategic tries to select the ability slot used by a Gen 8 Smogon set for Empoleon or Victreebel. If no matching Smogon ability is available, it chooses a legal ability slot for that species."
        $Ui.Descriptions.TrainerIV = "Trainer IVs. Example: Max31 makes every trainer Pokemon have perfect IVs; Random rolls each stat from 0 to 31. Special SWSH flags such as shiny and CanDynamax are preserved."
        $Ui.Descriptions.TrainerEV = "Trainer EVs. Example: Smogon strategic copies the EV spread from the same Gen 8 Smogon set used for moves/items when available, such as 56 HP / 236 Def / 216 Spe on Kyurem; Random legal falls back to a valid 510-EV spread, and Zero removes EV investment."
        $Ui.Descriptions.TrainerLevel = "Trainer level multiplier. Example: 1.20 turns a Lv.25 Victreebel into about Lv.30; 0.80 turns it into about Lv.20. Use 1.0 for vanilla levels."
        $Ui.Descriptions.TrainerTeamSize = "Trainer team size. Example: min 3 and max 6 forces tiny teams upward and prevents teams above 6. -1 means keep the vanilla size limit for that side."
        $Ui.Descriptions.TrainerTypeThemed = "Type-themed trainer teams. Example: a trainer can become Water-themed, so Empoleon fits that team while Victreebel would fit a Grass-themed team."
        $Ui.Descriptions.RandomizeNatures = "Trainer natures. Example: Smogon strategic can give Empoleon Modest or Victreebel Adamant when that exact Smogon set asks for it; if Smogon offers Adamant / Jolly, the tool picks one and keeps that same set for moves, item, ability and EVs. Random nature ignores Smogon and rolls any legal nature."
        $Ui.Descriptions.ForceAllTeams = "Force every trainer team to six Pokemon. Example: a route trainer with 2 Pokemon receives 4 added slots based on the original team's level range, then those added slots still follow your randomizer settings."
        $Ui.Descriptions.ForceBossTeams = "Enable the boss 6-Pokemon helper. Example: if this is checked, selected boss fights can be expanded to 6 Pokemon; the dropdown below decides which boss group is affected."
        $Ui.Descriptions.BossTeamsScope = "Choose which bosses are expanded when the boss 6-Pokemon helper is enabled. Example: Major bosses includes rivals and story bosses; Gyms + league focuses on Gym Leaders, Champion Cup / league-style fights and Leon."
        $Ui.Descriptions.TypeMode = "Pokemon types. Example: Empoleon can become Grass/Poison like Victreebel, or Victreebel can become pure Water if monotype is enabled."
        $Ui.Descriptions.TypesMonotypeOnly = "Force monotype. Example: instead of rolling Fire/Water, a Pokemon rolls only Fire/Fire, displayed as one Fire type in practice."
        $Ui.Descriptions.AbilityMode = "Species abilities. Example: Pikachu's ability slots can be replaced globally, so every Pikachu using that slot follows the new ability data."
        $Ui.Descriptions.StatMode = "Base stats. Example: Shuffle can swap a fast Pokemon's Speed with Defense; Redistribute keeps the same BST but builds a new stat spread."
        $Ui.Descriptions.ExpYieldMultiplier = "EXP multiplier. Example: 2.5 makes a 400 EXP gain become about 1000 EXP when the runtime boost is active. 1.0 is vanilla."
        $Ui.Descriptions.ForceOneExpYield = "No EXP mode. Example: a Pokemon that normally gives 350 EXP gives 1 EXP. Use this for challenge runs where levels should barely move."
        $Ui.Descriptions.MoveTypeMode = "Move types. Example: Thunderbolt can become Fire-type, so it uses the new type for effectiveness and STAB."
        $Ui.Descriptions.MovePowerMode = "Move power. Example: a 60-power move can roll 95 power if your selected range allows it. Status moves with 0 power stay non-damaging."
        $Ui.Descriptions.MovePPMode = "Move PP. Example: a move with 15 PP can become 8 or 30 PP depending on your min/max range."
        $Ui.Descriptions.MoveAccuracyMode = "Move accuracy. Example: Hydro Pump can become more reliable, or Tackle can become less accurate, within your selected range."
        $Ui.Descriptions.MoveCategoryMode = "Move category. Example: Flamethrower can become physical, or Iron Head can become special. Status moves stay status."
        $Ui.Descriptions.StarterMode = "Starter Pokemon mode. Example: Grookey / Scorbunny / Sobble can become Victreebel / Empoleon / Victreebel. Manual starter boxes override this if all three are filled."
        $Ui.Descriptions.Starter1 = "Manual starter slot 1. Example: type Victreebel here, Empoleon in slot 2 and Victreebel in slot 3 to force exactly that starter trio."
        $Ui.Descriptions.Starter2 = "Manual starter slot 2. Example: leave all three boxes empty to use random starter mode; fill all three boxes to force exact species."
        $Ui.Descriptions.Starter3 = "Manual starter slot 3. Example: French and English names are accepted, such as Evoli, Eevee, Bulbizarre or Bulbasaur."
        $Ui.Descriptions.PatchStarters = "Patch starter-linked trainer teams. Example: if Hop's team would normally react to your starter choice, this tries to keep that relationship coherent after your custom starter trio."
        $Ui.Descriptions.EvolutionMode = "Evolution targets. Example: Pikachu can evolve into Empoleon, and Victreebel can evolve into another random Pokemon, depending on the selected mode."
        $Ui.Descriptions.NormalizeFriendship = "Friendship evolutions. Example: instead of raising friendship for Eevee or Riolu, they evolve at the fixed level you choose."
        $Ui.Descriptions.NormalizeTrade = "Trade evolutions. Example: Machoke, Haunter or trade-with-item evolutions become regular level-up evolutions at the chosen level."
        $Ui.Descriptions.NormalizeSpecial = "Special evolutions. Example: location, time, weather, item/stone or known-move conditions become a simple fixed-level evolution."
        $Ui.Descriptions.GiftMode = "Gift Pokemon. Example: a gift Toxel can become a random Pokemon, while starters are controlled separately by the starter options."
        $Ui.Descriptions.TradeMode = "NPC trades. Example: an NPC asking for one Pokemon and giving another can have either side changed when the table exposes it."
        $Ui.Descriptions.StaticMode = "Static/scripted encounters. Example: a fixed overworld legendary or story encounter can stay unchanged, become balanced random, or become full random."
        $Ui.Descriptions.StaticStableMapping = "Static mapping. Example: Stable by species makes every static Pikachu become the same replacement; Stable by slot randomizes each fixed encounter separately."
        $Ui.Descriptions.GrassMode = "Wild encounter species. Example: if Route 1 has Skwovet and Rookidee in the table, this controls whether those table species are replaced in ROMFS."
        $Ui.Descriptions.GrassStableMapping = "Wild mapping rule. Example: Stable by species means every vanilla Victreebel becomes Empoleon everywhere. Stable by slot means a Victreebel in one area can become Empoleon while a Victreebel elsewhere can become another roll. True random per spawn rerolls visible/battle hooks with each spawn seed."
        $Ui.Descriptions.VisibleEncounterBehavior = "REQUIRES EXEFS outside Classic. Overworld Pokemon behavior. Example: Classic means seeing Victreebel starts a Victreebel battle. Vanilla visible + hidden battle keeps Victreebel visible everywhere but can start an Empoleon battle. Random visible + hidden battle randomizes visible tables too, so you can see Empoleon outside and still fight Victreebel or another hidden roll."
        $Ui.Descriptions.UndergroundMode = "Underground encounters. Example: underground species slots are separate from normal route grass, so this option controls that pool independently."
        $Ui.Descriptions.DisableExpShare = "REQUIRES EXEFS. Default EXP Share state. Example: checked means the generated config starts with EXP Share OFF, so only participating Pokemon should receive EXP. If the PC runtime menu is enabled, this remains the default state but you can toggle it in game."
        $Ui.Descriptions.EarlyBike = "REQUIRES EXEFS. Rotom Bike from the start. Example: after loading the field early in the save, the module grants the real Rotom Bike key item once."
        $Ui.Descriptions.RuntimePcControls = "REQUIRES EXEFS. Pokemon Center PC runtime menu. Example: this does not choose EXP Share by itself; it only adds the in-game PC menu that can toggle EXP Share / EXP boost without rebuilding the mod."
        $Ui.Descriptions.DynamicExpLevelCap = "REQUIRES EXEFS. Dynamic EXP cap. Example: if the current cap is 36, a Pokemon at level 36 receives 1 EXP instead of normal EXP, while lower-level Pokemon still gain EXP."
        $Ui.Descriptions.StrictBossMaxLevelCap = "REQUIRES EXEFS. Strict boss cap. Example: if the next listed boss's highest Pokemon is Lv.28, the cap can use 28 as the limit."
        $Ui.Descriptions.MainStorySoftLevelCap = "REQUIRES EXEFS. Soft story cap. Example: the cap follows badge/story blocks, so it changes at major milestones rather than after every small rival fight."
        $Ui.Descriptions.GymLeagueStoryLevelCap = "REQUIRES EXEFS. Gym/Champion story cap. Example: after teams are generated, the tool reads the actual gym and Leon levels and builds caps from those generated teams."
        $Ui.Descriptions.StoryMajorBattleOrderLevelCap = "REQUIRES EXEFS. Major battle order cap. Example: Hop, Bede, Marnie, Gym Leaders, Rose and Leon are placed in story order, then caps follow that sequence."
        $Ui.Descriptions.AutoInstallToEden = "Auto-install. Example: after generation, the tool can copy the finished mod to Eden/Ryujinx/Yuzu/Sudachi/Citron/Suyu/Citron Neo targets you checked, using the detected title ID."
        $Ui.Descriptions.EdenModName = "Installed mod folder name. Example: Randomizer replaces the previous Randomizer folder; MyRun_Seed123 keeps a separate named mod folder."
        foreach ($key in @($Ui.Descriptions.Keys)) {
            if ([string]$Ui.Descriptions[$key] -notmatch "Example:") {
                $Ui.Descriptions[$key] = ([string]$Ui.Descriptions[$key]).TrimEnd() + " Example: if the option affects a species, think Victreebel becoming Empoleon; if it affects a rule, Victreebel and Empoleon are the reference pair used to understand the result."
            }
        }
        return
    }

    $Ui.Descriptions.TrainerSpecies = "Especes des Pokemon de dresseurs. Exemple: un Empiflor niveau 12 peut devenir Pingoleon en Random complet; le mode BST proche cherche une puissance similaire; Garder vanilla laisse Empiflor."
    $Ui.Descriptions.TrainerMoves = "Attaques des dresseurs. Exemple: Strategique Smogon telecharge et met en cache les sets strategiques Gen 8, puis donne a Pingoleon ou Empiflor des attaques issues de ces sets quand elles existent. S'il y a plusieurs attaques Smogon, le logiciel tire au hasard; si aucun set n'existe, le menu backup choisit attaques naturelles, attaques random ou moves vanilla."
    $Ui.Descriptions.TrainerSmogonMoveFallback = "Backup des attaques Smogon. Exemple: si Pingoleon n'a aucune attaque Smogon utilisable dans les donnees du jeu, Backup niveau prend ses attaques naturelles, Backup random donne quatre attaques legales random, et Backup vanilla garde les attaques deja presentes sur le dresseur."
    $Ui.Descriptions.TrainerItems = "Objets tenus des dresseurs. Exemple: Strategique Smogon donne a Pingoleon ou Empiflor un objet tenu tire de ses sets Gen 8 quand il existe; s'il n'y a rien, le logiciel retombe sur des objets utiles comme baies, Restes, Choice items, plaques ou boosts de type."
    $Ui.Descriptions.TrainerItemPool = "Pool d'objets tenus. Exemple: le pool Combat est trie pour les objets utiles en combat comme baies, Restes, Choice items, plaques et boosts de type. Le pool large safe est plus large et peut aussi tirer balls, soins, mints, bonbons, fossiles et autres objets non-cle pour une run plus chaotique."
    $Ui.Descriptions.TrainerAddedSlotSpecies = "Especes des slots ajoutes. Exemple: si un champion d'arene ou de ligue reste vanilla et passe a 6 Pokemon, Random complet peut ajouter Pingoleon n'importe ou, BST proche garde une puissance comparable, Meme type garde le theme du champion comme Plante pour Milo, et Meme type + BST garde a la fois le theme et la puissance. Tarak reste equilibre au lieu d'etre force sur un seul type."
    $Ui.Descriptions.TrainerDuplicateMode = "Gestion des doublons. Exemple: Bloquer les doublons empeche deux Pingoleon dans la meme equipe generee; Random normal autorise ce tirage rare si le randomizer tombe naturellement deux fois sur Pingoleon."
    $Ui.Descriptions.TrainerAbility = "Slot de talent des dresseurs. Exemple: Strategique Smogon essaie d'utiliser le slot de talent conseille par un set Gen 8 pour Pingoleon ou Empiflor. Si aucun talent Smogon ne correspond a l'espece, il choisit un slot de talent legal de cette espece."
    $Ui.Descriptions.TrainerIV = "IV des dresseurs. Exemple: 31 partout rend les IV parfaits; Aleatoire tire chaque stat entre 0 et 31. Les flags speciaux SWSH comme shiny et CanDynamax sont preserves."
    $Ui.Descriptions.TrainerEV = "EV des dresseurs. Exemple: Strategique Smogon copie les EV du meme set Gen 8 Smogon que les moves/objets quand il existe, comme 56 PV / 236 Defense / 216 Vitesse sur Kyurem; EV legaux aleatoires sert de backup valide, et Zero retire les EV."
    $Ui.Descriptions.TrainerLevel = "Multiplicateur de niveau dresseurs. Exemple: 1.20 transforme un Empiflor niveau 25 en environ niveau 30; 0.80 le descend environ niveau 20. Mets 1.0 pour garder les niveaux vanilla."
    $Ui.Descriptions.TrainerTeamSize = "Taille des equipes. Exemple: min 3 et max 6 remonte les petites equipes et bloque tout au maximum legal de 6. -1 signifie garder la valeur vanilla de ce cote."
    $Ui.Descriptions.TrainerTypeThemed = "Equipes themees par type. Exemple: un dresseur theme Eau peut recevoir Pingoleon; un dresseur theme Plante peut recevoir Empiflor."
    $Ui.Descriptions.RandomizeNatures = "Natures des dresseurs. Exemple: Strategique Smogon peut donner Modeste a Pingoleon ou Rigide a Empiflor quand le set Smogon choisi le demande; si Smogon propose Rigide / Jovial, le logiciel en tire une et garde le meme set pour attaques, objet, talent et EV. Nature aleatoire ignore Smogon et tire une nature legale."
    $Ui.Descriptions.ForceAllTeams = "Forcer tous les dresseurs a 6 Pokemon. Exemple: un dresseur de route avec 2 Pokemon recoit 4 slots ajoutes autour de la plage de niveaux de son equipe, puis ces slots suivent aussi tes options de randomisation."
    $Ui.Descriptions.ForceBossTeams = "Active l'aide boss a 6 Pokemon. Exemple: si cette case est cochee, les combats boss selectionnes peuvent passer a 6 Pokemon; le menu juste a cote choisit quel groupe de boss est touche."
    $Ui.Descriptions.BossTeamsScope = "Choisit quels boss passent a 6 Pokemon quand l'aide boss a 6 est activee. Exemple: Boss importants inclut rivaux et boss d'histoire; Arenes + ligue vise surtout champions d'arene, combats type Champion Cup / ligue et Tarak."
    $Ui.Descriptions.TypeMode = "Types des Pokemon. Exemple: Pingoleon peut devenir Plante/Poison comme Empiflor, ou Empiflor peut devenir pur Eau si le monotype est active."
    $Ui.Descriptions.TypesMonotypeOnly = "Forcer monotype. Exemple: au lieu de tirer Feu/Eau, le Pokemon tire Feu/Feu, ce qui revient a un seul type Feu en jeu."
    $Ui.Descriptions.AbilityMode = "Talents des especes. Exemple: les slots de talent de Pikachu peuvent changer globalement; tous les Pikachu qui utilisent ce slot suivent ensuite la nouvelle donnee."
    $Ui.Descriptions.StatMode = "Stats de base. Exemple: Melanger peut echanger la Vitesse d'un Pokemon rapide avec sa Defense; Redistribuer garde le meme BST total mais cree une autre repartition."
    $Ui.Descriptions.ExpYieldMultiplier = "NECESSITE EXEFS si different de 1.0. Multiplicateur EXP. Exemple: 2.5 transforme environ 400 EXP en 1000 EXP quand le boost runtime est actif. 1.0 garde l'EXP vanilla."
    $Ui.Descriptions.ForceOneExpYield = "Mode No EXP. Exemple: un Pokemon qui donne normalement 350 EXP donne 1 EXP. Utile pour une run challenge ou les niveaux doivent tres peu monter."
    $Ui.Descriptions.MoveTypeMode = "Types des attaques. Exemple: Tonnerre peut devenir de type Feu, donc l'efficacite et le STAB suivent le nouveau type."
    $Ui.Descriptions.MovePowerMode = "Puissance des attaques. Exemple: une attaque a 60 de puissance peut passer a 95 si ta plage min/max l'autorise. Les attaques de statut a 0 restent non offensives."
    $Ui.Descriptions.MovePPMode = "PP des attaques. Exemple: une attaque a 15 PP peut devenir 8 ou 30 PP selon ta plage min/max."
    $Ui.Descriptions.MoveAccuracyMode = "Precision des attaques. Exemple: Hydrocanon peut devenir plus fiable, ou Charge peut devenir moins precise, toujours dans la plage choisie."
    $Ui.Descriptions.MoveCategoryMode = "Categorie des attaques. Exemple: Lance-Flammes peut devenir physique, ou Tete de Fer peut devenir special. Les attaques de statut restent statut."
    $Ui.Descriptions.StarterMode = "Mode starters. Exemple: Ouistempo / Flambino / Larmeleon peuvent devenir Empiflor / Pingoleon / Empiflor. Les trois champs manuels prennent le dessus s'ils sont tous remplis."
    $Ui.Descriptions.Starter1 = "Starter manuel slot 1. Exemple: tape Empiflor ici, Pingoleon en slot 2 et Empiflor en slot 3 pour forcer exactement ce trio."
    $Ui.Descriptions.Starter2 = "Starter manuel slot 2. Exemple: laisse les trois champs vides pour utiliser le mode random; remplis les trois champs pour imposer des especes precises."
    $Ui.Descriptions.Starter3 = "Starter manuel slot 3. Exemple: les noms FR et EN sont acceptes, comme Evoli, Eevee, Bulbizarre ou Bulbasaur."
    $Ui.Descriptions.PatchStarters = "Repatch des equipes liees aux starters. Exemple: si l'equipe de Nabil depend normalement de ton choix de starter, cette option essaie de garder cette logique coherente apres ton trio custom."
    $Ui.Descriptions.EvolutionMode = "Cibles d'evolution. Exemple: Pikachu peut evoluer en Pingoleon, et Empiflor peut evoluer vers un autre Pokemon random selon le mode choisi."
    $Ui.Descriptions.NormalizeFriendship = "Evolutions par amitie. Exemple: au lieu de monter l'amitie d'Evoli ou Riolu, ils evoluent au niveau fixe que tu choisis."
    $Ui.Descriptions.NormalizeTrade = "Evolutions par echange. Exemple: Machopeur, Spectrum ou les evolutions echange + objet deviennent des evolutions par niveau au niveau choisi."
    $Ui.Descriptions.NormalizeSpecial = "Evolutions speciales. Exemple: conditions de lieu, heure, meteo, pierre/objet ou attaque connue deviennent une evolution simple par niveau fixe."
    $Ui.Descriptions.GiftMode = "Pokemon cadeaux. Exemple: un Toxizap offert peut devenir un Pokemon random, tandis que les starters restent controles par les options starters."
    $Ui.Descriptions.TradeMode = "Trades PNJ. Exemple: un PNJ qui demande un Pokemon et en donne un autre peut voir le Pokemon demande ou recu changer quand la table l'expose."
    $Ui.Descriptions.StaticMode = "Rencontres fixes/scriptes. Exemple: un legendaire fixe ou une rencontre d'histoire peut rester vanilla, devenir random equilibre ou devenir random complet."
    $Ui.Descriptions.StaticStableMapping = "Mapping des rencontres fixes. Exemple: Stable par espece transforme tous les Pikachu fixes en meme remplacement; Stable par slot randomise chaque rencontre fixe separement."
    $Ui.Descriptions.GrassMode = "Especes des rencontres sauvages. Exemple: si la Route 1 contient Rongourmand et Minisange dans sa table, cette option controle si ces especes de table sont remplacees dans le ROMFS."
    $Ui.Descriptions.GrassStableMapping = "Regle de mapping sauvage. Exemple: Stable par espece veut dire que tous les Empiflor vanilla deviennent Pingoleon partout. Stable par slot permet a un Empiflor d'une zone de devenir Pingoleon et a un Empiflor d'une autre zone de tirer autre chose. Vrai random par spawn reroll les hooks visible/combat avec le seed de chaque apparition."
    $Ui.Descriptions.VisibleEncounterBehavior = "NECESSITE EXEFS hors mode Classique. Comportement des Pokemon visibles. Exemple: Classique signifie voir Empiflor puis combattre Empiflor. Visuel vanilla + combat cache garde Empiflor visible partout mais peut lancer un combat contre Pingoleon. Visuel random + combat cache randomise aussi les tables visibles: tu peux voir Pingoleon dehors et combattre Empiflor ou un autre tirage cache."
    $Ui.Descriptions.UndergroundMode = "Rencontres underground. Exemple: les slots du souterrain sont separes des hautes herbes classiques; cette option controle donc ce pool independamment."
    $Ui.Descriptions.DisableExpShare = "NECESSITE EXEFS. Etat par defaut de l'EXP Share. Exemple: coche = la config generee demarre avec EXP Share OFF, donc seuls les Pokemon participants doivent recevoir l'EXP. Si le menu PC runtime est actif, ca reste l'etat par defaut mais tu peux le changer en jeu."
    $Ui.Descriptions.EarlyBike = "NECESSITE EXEFS. Velo Rotom des le debut. Exemple: apres chargement du terrain au debut d'une sauvegarde, le module donne une seule fois le vrai objet rare Velo Rotom."
    $Ui.Descriptions.RuntimePcControls = "NECESSITE EXEFS. Menu runtime via le PC du Centre Pokemon. Exemple: cette option ne choisit pas l'etat EXP Share toute seule; elle ajoute seulement le menu en jeu pour changer EXP Share / boost EXP sans regenerer le mod."
    $Ui.Descriptions.DynamicExpLevelCap = "NECESSITE EXEFS. Cap EXP dynamique. Exemple: si le cap actuel est 36, un Pokemon niveau 36 recoit 1 EXP au lieu de l'EXP normale, tandis qu'un Pokemon sous le cap continue de gagner de l'EXP."
    $Ui.Descriptions.StrictBossMaxLevelCap = "NECESSITE EXEFS. Cap boss strict. Exemple: si le prochain boss liste a un Pokemon max niveau 28, le cap peut utiliser 28 comme limite."
    $Ui.Descriptions.MainStorySoftLevelCap = "NECESSITE EXEFS. Cap histoire souple. Exemple: le cap suit des blocs badges/histoire, donc il change aux gros paliers plutot qu'apres chaque petit combat rival."
    $Ui.Descriptions.GymLeagueStoryLevelCap = "NECESSITE EXEFS. Cap arenes/Tarak. Exemple: apres generation des equipes, l'outil lit les vrais niveaux generes des arenes et de Tarak, puis construit les caps depuis ces equipes."
    $Ui.Descriptions.StoryMajorBattleOrderLevelCap = "NECESSITE EXEFS. Cap ordre des combats majeurs. Exemple: Nabil, Travis, Rosemary, champions, Shehroz et Tarak sont places dans l'ordre de l'histoire, puis les caps suivent cette sequence."
    $Ui.Descriptions.AutoInstallToEden = "Installation auto. Exemple: apres generation, l'outil peut copier le mod fini vers Eden/Ryujinx/Yuzu/Sudachi/Citron/Suyu/Citron Neo selon les cibles cochees et detectees."
    $Ui.Descriptions.EdenModName = "Nom du dossier de mod installe. Exemple: Randomizer remplace l'ancien dossier Randomizer; MaRun_Seed123 garde un dossier de mod separe."
    $exampleNeedle = if ($Language -eq "en") { "Example:" } else { "Exemple:" }
    $genericExample = if ($Language -eq "en") {
        " Example: if the option changes a species, imagine Victreebel becoming Empoleon; if it changes a rule, Victreebel and Empoleon are the reference pair for understanding the result."
    } else {
        " Exemple: si l'option touche une espece, imagine Empiflor qui devient Pingoleon; si elle touche une regle, Empiflor et Pingoleon servent de duo de reference pour comprendre le resultat."
    }
    foreach ($key in @($Ui.Descriptions.Keys)) {
        if ([string]$Ui.Descriptions[$key] -notmatch [regex]::Escape($exampleNeedle)) {
            $Ui.Descriptions[$key] = ([string]$Ui.Descriptions[$key]).TrimEnd() + $genericExample
        }
    }
}

function Get-UiStrings {
    param([string]$Language = "fr")

    if ($Language -eq "en") {
        return @{
            FormTitle = "PokeFeur Randomizer SWSH V4.17"
            SourceLabel = "Original ROMFS folder"
            SourceExefsLabel = "Original ExeFS folder"
            OutputLabel = "Generated mod folder"
            GameVersion = "Target game"
            Browse = "Browse"
            Seed = "Seed (-1 = auto)"
            UiLanguage = "Software language"
            ReportLanguage = "JSON report language"
            Theme = "Theme"
            DifficultyProfile = "Difficulty profile"
            ApplyDifficultyProfile = "Apply profile"
            ValidateBuild = "Check config"
            BuildSummary = "Build summary"
            Generate = "Generate mod"
            Tabs = @{ General = "Build"; Trainers = "Trainers"; Pokemon = "Pokemon"; Evolutions = "Evolutions"; Gifts = "Starters / gifts"; Encounters = "Encounters"; Help = "Help"; Reset = "Clean install" }
            GeneralLines = @(
                "Complete build: user ROMFS + user ExeFS, ExLaunch, JSON presets, detailed reports, and emulator auto-install.",
                "BST = the sum of the 6 base stats. Similar BST keeps replacements in a comparable power range.",
                "Trainers: species, moves, items, IV/EV, shiny, AI, Dynamax, team size, and boss teams at 6.",
                "Pokemon: types, abilities, stats, EXP yield, global moves, and evolutions.",
                "Encounters: static, wild, visible, underground, stable mappings, and hidden battle rolls.",
                "Starters: French/English names accepted, example Victreebel / Empoleon / Victreebel.",
                "EXP caps: runtime modes require ExLaunch and export their JSON cap tables."
            )
            ModeRandom = "Full random"
            ModeSimilarBST = "Balanced random (similar BST)"
            ModeUnchanged = "Keep vanilla"
            MappingSlot = "Stable by slot"
            MappingSpecies = "Stable by species"
            MappingTrueRandom = "Fresh roll per encounter entry"
            TrainerMoveRandom4 = "4 random moves"
            TrainerMoveLevel4 = "Natural moves for its level"
            TrainerMoveSmogon = "Smogon strategic"
            TrainerMoveSmogonLegacy = "Smogon + older gens"
            TrainerSmogonMoveFallbackLevel = "Fallback: natural level moves"
            TrainerSmogonMoveFallbackRandom = "Fallback: random moves"
            TrainerSmogonMoveFallbackUnchanged = "Fallback: keep vanilla"
            TrainerItemRandomPresent = "Random when an item is already present"
            TrainerItemForceAll = "Random item on every trainer Pokemon"
            TrainerItemSmogon = "Smogon strategic item"
            TrainerItemSmogonLegacy = "Smogon item + older gens"
            TrainerItemRemoveAll = "Remove all held items"
            TrainerItemPoolBattle = "Battle pool (useful held items)"
            TrainerItemPoolFull = "Wide safe pool (chaotic)"
            TrainerAddedSlotRandom = "Added slots: full random"
            TrainerAddedSlotSimilarBST = "Added slots: similar BST"
            TrainerAddedSlotSameType = "Added slots: same type"
            TrainerAddedSlotSameTypeBST = "Added slots: same type + BST"
            TrainerDuplicateNoDuplicates = "Block duplicates"
            TrainerDuplicateNormal = "Normal random (duplicates possible)"
            BossScopeMajor = "Major bosses"
            BossScopeGymLeague = "Gyms + league only"
            TrainerAbilityRandom = "Randomize trainer ability slot"
            TrainerAbilitySmogon = "Smogon strategic ability"
            TrainerAbilitySmogonLegacy = "Smogon ability + older gens"
            TrainerIVMax = "31 in every IV"
            TrainerIVRandom = "Random"
            TrainerEVSmogon = "Smogon strategic EVs"
            TrainerEVSmogonLegacy = "Smogon EVs + older gens"
            TrainerEVRandom = "Random legal EVs"
            TrainerEVZero = "Set EVs to zero"
            TrainerNatureUnchanged = "Keep vanilla nature"
            TrainerNatureRandom = "Random nature"
            TrainerNatureSmogon = "Smogon strategic nature"
            TrainerNatureSmogonLegacy = "Smogon nature + older gens"
            StarterRandom = "Random starter Pokemon"
            StarterSimilarBST = "Similar BST starter Pokemon"
            StarterUnchanged = "Do not change starter Pokemon"
            StatShuffle = "Shuffle the 6 stats"
            StatRedistribute = "Redistribute BST"
            ReportLanguageFrench = "French"
            ReportLanguageEnglish = "English"
            UiLanguageFrench = "Francais"
            UiLanguageEnglish = "English"
            ThemeLight = "Light"
            ThemeDark = "Dark"
            Labels = @{
                TrainerSpecies = "Trainer Pokemon species"
                TrainerMoves = "Trainer Pokemon moves"
                TrainerSmogonMoveFallback = "Smogon move fallback"
                TrainerItems = "Trainer held items"
                TrainerItemPool = "Random item pool"
                TrainerAddedSlotSpecies = "Pokemon added to 6-slot teams"
                TrainerDuplicateMode = "Team duplicates"
                TrainerAbility = "Trainer Pokemon abilities"
                TrainerIV = "Trainer IVs"
                TrainerEV = "Trainer EVs"
                TrainerLevel = "Trainer level multiplier"
                TrainerTeamMin = "Minimum team size"
                TrainerTeamMax = "Maximum team size"
                TrainerTypeThemed = "Type-themed trainer teams"
                TrainerShinyChance = "Trainer shiny rate (%)"
                ForceTrainerFullyEvolved = "Force final evolutions"
                TrainerFullyEvolvedLevel = "Final evolution level"
                MaxTrainerAI = "Max trainer AI"
                TrainerDynamaxLevel = "Trainer Dynamax level"
                TrainerDynamaxUnchanged = "Do not change"
                TrainerDynamaxMax = "Dynamax level 10"
                TrainerDynamaxRandom = "Random 0-10"
                ForceTrainerCanDynamax = "Allow every trainer Pokemon to Dynamax"
                ForceAllTeams = "Set every trainer to 6 Pokemon"
                ForceBossTeams = "Set selected bosses to 6 Pokemon"
                BossTeamsScope = "Boss list used for 6v6"
                AllowLegendaryTrainers = "Allow legendary Pokemon for trainers"
                RandomizeNatures = "Trainer natures"
                TypeMode = "Species types"
                ForceMonotype = "Force one type only"
                AbilityMode = "Global species abilities"
                AllowWonderGuard = "Allow Wonder Guard in the pool"
                StatMode = "Species base stats"
                ExpYieldMultiplier = "EXP yield multiplier [REQUIRES EXEFS if not 1.0]"
                ForceOneExpYield = "No EXP mode: force 1 EXP from every Pokemon"
                MoveTypeMode = "Move type randomization"
                MovePowerMode = "Move power randomization"
                MovePPMode = "Move PP randomization"
                MovePowerMin = "Power min"
                MovePowerMax = "Power max"
                MovePPMin = "PP min"
                MovePPMax = "PP max"
                MoveAccuracyMode = "Move accuracy randomization"
                MoveAccuracyMin = "Accuracy min"
                MoveAccuracyMax = "Accuracy max"
                MoveCategoryMode = "Move physical/special split"
                EvolutionMode = "Evolution targets"
                AllowLegendaryEvo = "Allow legendary Pokemon in evolutions"
                NormalizeFriendship = "Convert friendship evolutions to a fixed level"
            FriendshipLevel = "Friendship level"
            NormalizeTrade = "Convert trade evolutions to a fixed level"
            TradeLevel = "Trade level"
            NormalizeSpecial = "Convert weird evolutions to a fixed level"
            SpecialLevel = "Special evolution level"
                GiftMode = "Gift Pokemon mode"
                StarterMode = "Starter Pokemon mode"
                AllowLegendaryGifts = "Allow legendary Pokemon for gifts and starters"
                ManualStarterGroup = "Manual starters: leave the 3 boxes empty for the mode above, or fill all 3 to force a trio."
                Slot1 = "Slot 1"
                Slot2 = "Slot 2"
                Slot3 = "Slot 3"
                PatchStarters = "May be broken, do not use Patch early trainer teams tied to the starter choice"
                TradeMode = "In-game trades"
                AllowLegendaryTrades = "Allow legendary Pokemon in in-game trades"
                StaticMode = "Static / scripted encounters"
                AllowLegendaryStatic = "Allow legendary Pokemon in static encounters"
                StaticStableMapping = "Static stable mapping"
                GrassMode = "Wild encounter species"
                AllowLegendaryGrass = "Allow legendary Pokemon in grass / visible encounters"
                GrassStableMapping = "Wild encounter mapping rule"
                VisibleEncounterBehavior = "Overworld Pokemon behavior [REQUIRES EXEFS outside Classic]"
                UndergroundMode = "Underground encounters"
                AllowLegendaryUnderground = "Allow legendary Pokemon in underground"
                DisableExpShare = "Default EXP Share: OFF [REQUIRES EXEFS]"
                EarlyBike = "Rotom Bike from the start [REQUIRES EXEFS]"
                RuntimePcControls = "PC menu: change options in game [REQUIRES EXEFS]"
                DynamicExpLevelCap = "Dynamic EXP cap (ExLaunch) [REQUIRES EXEFS]"
                StrictBossMaxLevelCap = "Strict boss max level cap for listed bosses [REQUIRES EXEFS]"
                MainStorySoftLevelCap = "Soft main-story progression EXP cap [REQUIRES EXEFS]"
                GymLeagueStoryLevelCap = "Gym/Champion EXP cap [REQUIRES EXEFS]"
                StoryMajorBattleOrderLevelCap = "Ordered main-story major battle mode [REQUIRES EXEFS]"
                AutoInstallToEden = "Auto-install"
                EdenModName = "Mod folder"
                InstallTargetEden = "Eden"
                InstallTargetRyujinx = "Ryujinx"
                InstallTargetYuzu = "Yuzu"
                InstallTargetSudachi = "Sudachi"
                InstallTargetCitron = "Citron"
                InstallTargetSuyu = "Suyu"
                InstallTargetCitronNeo = "Citron Neo"
                HelpBox = "Help"
                ResetTargets = "Reset targets"
                ResetButton = "Reset emulator install"
                ResetDefault = "This removes only the generated mod folder and the swsh-mods-exl config file when that config was generated by this randomizer."
                DetailsDefault = "Hover or focus any option to see exactly what it changes and where it is applied."
                StatusDefault = "Ready. Pick the user's ROMFS dump folder, add ExeFS only if a runtime/ExLaunch option needs it, choose your options, then generate the mod. The output includes ROMFS, ExLaunch files, config, and JSON reports when relevant."
                StatusRunning = "Building mod..."
                SeedError = "Seed must be a numeric integer. Use -1 for auto."
            }
            Descriptions = @{
                TrainerSpecies = "Trainer Pokemon: Completely random replaces each slot with any allowed Pokemon. Similar BST aims for comparable overall power using Base Stat Total. Do not change keeps vanilla species."
                TrainerMoves = "Trainer Pokemon moves: Random4 picks 4 attacks from the global move pool. Last 4 level-up moves uses the species' last 4 moves learned by level at the Pokemon's actual level."
                TrainerItems = "Items held by trainer Pokemon: Random only if present touches only slots that already had an item. Random item on everyone gives every trainer Pokemon one random held item. Remove all clears held items. Both random modes use the pool chosen on the right."
                TrainerItemPool = "Held item pool: Battle pool is curated for useful battle held items such as berries, Leftovers, Choice items, plates and type boosters. Wide safe pool is broader: it keeps key/problem items out, but can also roll balls, medicine, fossils, mints, candies and other safe non-key items for chaotic runs."
                TrainerAddedSlotSpecies = "Species for added slots: used only when a team is expanded to 6 while trainer species mode is Keep vanilla. Full random can add Empoleon to a Victreebel team; Similar BST tries comparable power; Same type keeps Gym/league themes such as Grass for Milo; Same type + BST keeps both. Leon/Tarak stays balanced."
                TrainerDuplicateMode = "Duplicate handling: Block duplicates is the current clean mode and repairs trainer teams so the same Pokemon or held item does not repeat. Normal random removes that repair; duplicates can happen naturally but are just random chance."
                TrainerAbility = "Trainer ability slot: randomizes the ability selector stored on each trainer Pokemon. It changes which normal/hidden ability slot is used, not the species' global ability data."
                TrainerIV = "IV mode: Max31 writes perfect IVs while preserving SWSH special flags. Random rolls each IV from 0 to 31 and also preserves shiny / CanDynamax flags."
                TrainerEV = "EV mode: Smogon strategic uses the EV spread from the selected Smogon set when available, then falls back to random legal EVs. Random legal distributes up to 510 EVs with the per-stat 252 cap. Zero removes EVs from every trainer Pokemon."
                TrainerLevel = "Level multiplier: multiplies trainer Pokemon levels and clamps the result to 1-100. Use 1.0 to leave levels untouched."
                TrainerTeamSize = "Team size: -1 means keep vanilla. Min / max clamp team size from 1 to 6. Force all teams to 6 overrides this by targeting 6 first, then the clamp still applies."
                TrainerTypeThemed = "Type-themed trainer teams: when trainer species are randomized, each trainer gets one random type and replacement Pokemon are pulled from that type's species pool. This is inspired by pkNX's TeamTypeThemed option."
                RandomizeNatures = "Trainer natures: Keep vanilla leaves each nature untouched, Random rolls one of the 25 legal natures, and Smogon strategic takes the nature from the same Smogon set as moves, item, ability and EVs."
                AllowLegendaryTrainers = "Allow legendary Pokemon for trainers: when disabled, legendary and mythical species are excluded from trainer replacement pools. This does not delete vanilla legendaries if species mode is unchanged."
                TrainerShinyChance = "Trainer shiny rate: 0 leaves trainer shininess untouched. Any value above 0 rolls that percentage on every trainer Pokemon and writes the verified SWSH shiny bit in trainer_poke."
                ForceTrainerFullyEvolved = "Force fully evolved after level: if a trainer Pokemon is at least this level, the tool follows its evolution chain and replaces it with a final-stage evolution. Branching evolutions pick one allowed branch."
                MaxTrainerAI = "Maximize trainer AI: sets the trainer AI flag field to all enabled flags. This is based on pkNX's TrainerMaxAI option and makes battles less passive."
                TrainerDynamaxLevel = "Trainer Dynamax level: changes the Dynamax level byte in each trainer Pokemon record. Max10 makes Dynamax HP boost strongest; Random0-10 varies it."
                ForceTrainerCanDynamax = "Allow every trainer Pokemon to Dynamax: sets the verified SWSH CanDynamax bit in trainer_poke. This does not force Gigantamax forms."
                ForceAllTeams = "Force all trainer teams to 6 Pokemon: expands every trainer party up to six slots by cloning a random existing slot to keep a coherent level/template. Added slots are then re-leveled toward the team's real level range and still go through the normal trainer options afterward: species mode, trainer move mode, held item mode, IV/EV mode, shiny rate, Dynamax settings, and so on. When trainer species randomization is active, duplicate species inside the final team are now blocked: uniqueness takes priority, and if the current mode pool runs out the randomizer broadens the candidate pool instead of accepting duplicates."
                ForceBossTeams = "Listed champion / league / major boss teams to 6 Pokemon: expands only the important fights detected from vanilla trainer metadata. Added slots no longer duplicate only the last Pokemon: each extra slot takes a random existing slot as level template, is re-leveled toward the real team range, then still follows the usual trainer options afterward, including species mode and trainer move mode. When trainer species randomization is active, duplicate species inside the final team are now blocked: uniqueness takes priority, and if the current mode pool runs out the randomizer broadens the candidate pool instead of accepting duplicates. The very first Hop starter-choice battle is intentionally excluded so that opening fight keeps its special 2-Pokemon structure. The visible list shows unique characters; randomizer-report.json and trainer-changes.json export the exact trainer IDs and before/after team sizes."
                BossTeamsScope = "Boss 6v6 scope: Major bosses is the broad mode and can include rivals plus story/DLC bosses such as Hop, Bede, Marnie, Leon, Rose, Oleana, Sordward, Shielbert, Mustard, Klara, Avery and Peony. Gyms + league only is narrower: it targets Gym Leaders, Champion Cup / league-style entries and Leon, so the 6-Pokemon helper behaves more like a classic Gyms + Elite Four style run."
                ForceBossTargets = "Boss target list: includes rivals and story bosses such as Hop, Bede, Marnie, Leon, Rose, Oleana, Sordward, Shielbert, DLC bosses such as Mustard, Klara, Avery, Peony, Peonia, plus Gym Leader / Champion Cup / league fights detected in vanilla data. The very first Hop starter-choice battle is intentionally excluded from the 6-Pokemon helper. Generic Macro Cosmos employees are intentionally not included."
                TypeMode = "Pokemon types: Random changes types for all species. With monotype enabled, type 2 is copied from type 1."
                TypesMonotypeOnly = "Force monotype: when Pokemon types are randomized, the second type is forced to match the first type instead of rolling a dual type."
                AbilityMode = "Pokemon abilities: randomizes species ability slots in personal data. Wonder Guard is blocked unless explicitly allowed."
                AllowWonderGuard = "Allow Wonder Guard: includes Wonder Guard in the ability pool. This can create very strong or unfair Pokemon, so it is opt-in."
                StatMode = "Base stats: Shuffle permutes the 6 stats. Redistribute keeps the same BST total but builds a different spread."
                ExpYieldMultiplier = "EXP yield multiplier: when different from 1.0, the generated ExLaunch config applies it to the final EXP gain at runtime instead of editing personal_total.bin. 0.6 matches the idea of the 60_sw mod, and 5.0 makes a true x5 multiplier. No EXP mode overrides this value."
                ForceOneExpYield = "No EXP mode: forces every Pokemon species that normally gives EXP to yield 1 EXP. This is the clean ROMFS version of the local no_exp_v132_ mod. It is global and static. Use Dynamic EXP level cap if you want the game to check the receiver Pokemon's level during battle."
                MoveTypeMode = "Move types: changes the elemental type of global moves. Example: Fire Fang can become Ice-type."
                MovePowerMode = "Move power: randomizes damaging move power only. Moves with base power 0 are left at 0 to avoid turning pure status moves into broken attacks."
                MovePPMode = "Move PP: randomizes base PP for global moves inside the selected range."
                MoveAccuracyMode = "Move accuracy: randomizes accuracy for moves that normally use an accuracy value. Perfect / special-case accuracy 0 is preserved."
                MoveCategoryMode = "Move category: randomizes damaging moves between physical and special. Status moves are preserved."
                StarterMode = "Starter Pokemon mode: Random starter Pokemon replaces only the three starter species. Similar BST keeps them close to Grookey / Scorbunny / Sobble power. This global mode is used only when all three manual starter boxes are left empty."
                Starter1 = "Manual starter slot 1. You can type a French or English species name, for example Pikachu, Bulbizarre or Eevee. If you force manual starters, all 3 boxes must be filled."
                Starter2 = "Manual starter slot 2. Leave the 3 boxes empty to keep using the starter mode above. Fill the 3 boxes to force an exact visible trio."
                Starter3 = "Manual starter slot 3. The JSON report exports the chosen trio with both French and English names."
                PatchStarters = "Patch trainer teams tied to the starter choice: after changing the three visible starters, the script reads vanilla trainer metadata, finds every Grookey / Scorbunny / Sobble family slot, and forces those exact slots to the final starter trio. This still works if trainer Pokemon were randomized first, and the patched slots now rebuild their moves so they stop keeping the previous species move set."
                ReportLanguage = "JSON report language: chooses the primary language for exported labels. Species name input still accepts French and English."
                UiLanguage = "Software language: instantly switches the interface text and help descriptions between French and English."
                EvolutionMode = "Pokemon Evolution: Completely random remaps evolution targets freely. Similar BST prefers targets with comparable power."
                AllowLegendaryEvo = "Allow legendary Pokemon in evolutions: includes legendary and mythical species in randomized evolution targets. Leave it off for a more regular progression."
                NormalizeFriendship = "Friendship normalization converts friendship methods into plain level-up evolution. Covered methods: 1, 2, 3."
                NormalizeTrade = "Trade normalization converts plain trade, trade-with-item, and trade-for-specific-Pokemon methods into plain level-up evolution. Covered methods: 5, 6, 7."
                NormalizeSpecial = "Weird evolution normalization converts every non-empty evolution method that is not already plain level-up into a fixed level-up evolution. This covers time, beauty, location, item/stone, move-known, gender/weather/party requirements and other special conditions. If you want to keep item or stone evolutions, leave this unchecked."
                GiftMode = "Gift Pokemon mode: edits non-starter gift Pokemon from add_poke.bin. Completely random ignores power; Similar BST keeps gifts closer to their original strength."
                AllowLegendaryGifts = "Allow legendary Pokemon for gifts and starters: includes legendary and mythical species in gift and starter replacement pools."
                TradeMode = "In-game trades: edits NPC trade species. Both the requested Pokemon and the received Pokemon can be randomized where the file exposes them."
                AllowLegendaryTrades = "Allow legendary Pokemon in in-game trades: includes legendary and mythical species in NPC trade replacement pools."
                StaticMode = "Static / scripted encounters: edits fixed in-world encounters from event_encount_data.bin."
                AllowLegendaryStatic = "Allow legendary Pokemon in static encounters: includes legendary and mythical species in fixed/scripted encounter replacement pools."
                GrassMode = "Wild encounter species: controls the ROMFS encounter tables used by grass, symbols and field encounters. Keep vanilla leaves the species tables untouched; the option below can still add a runtime split between what is seen outside and what starts in battle."
                AllowLegendaryGrass = "Allow legendary Pokemon in grass / visible encounters: includes legendary and mythical species in hidden grass and visible overworld replacement pools."
                StaticStableMapping = "Static mapping: Species maps every same vanilla species to the same replacement. Slot maps each static/script table entry independently. True random build rolls every ROMFS entry independently; it does not reroll encounters live in-game."
                GrassStableMapping = "Wild encounter mapping rule: Stable by species means every vanilla Pikachu becomes the same replacement everywhere. Stable by slot means Route 4 Pikachu and another area Pikachu can become different species. Fresh roll per table entry is less controlled and is mainly for chaotic runs."
                VisibleEncounterBehavior = "Overworld Pokemon behavior: Classic is what you see is what you fight. Vanilla visible + hidden battle keeps the original overworld model but replaces the battle species at encounter start. Random visible + hidden battle randomizes the visible model and also uses a separate battle roll, so seeing one species does not reveal the fight."
                UndergroundMode = "Underground encounters: edits the underground encounter species slots stored separately from normal field encounters."
                AllowLegendaryUnderground = "Allow legendary Pokemon in underground: includes legendary and mythical species in underground encounter replacement pools."
                DisableExpShare = "Default EXP Share: OFF: writes enabled=false to the generated ExLaunch [exp_share] config. If the PC runtime menu is enabled, this is only the starting state and the player can toggle it in game."
                EarlyBike = "Rotom Bike from the start: writes active=true to the generated ExLaunch [early_bike] config. The module grants the real Rotom Bike key item once the field is loaded."
                RuntimePcControls = "PC menu runtime controls: opt-in replacement of the Pokemon Center PC script. This option does not disable EXP Share by itself; it only allows changing runtime options in game. When unchecked, the vanilla PC menu stays intact and the generated config defaults are used directly."
                DynamicExpLevelCap = "Dynamic EXP level cap: no longer writes the old raw IPS. The reliable path uses ExLaunch at the final EXP calculation point. The tool copies main.npdm from the user's ExeFS dump and only adds the custom subsdk9 module."
                StrictBossMaxLevelCap = "Strict boss max level cap: still computes and normalizes the listed boss teams, but in-game EXP enforcement now requires the ExLaunch module. main.npdm is copied from the user's ExeFS dump; the randomizer only adds the custom subsdk9 module. Without that module, the JSON is a reference and EXP is not blocked."
                MainStorySoftLevelCap = "Soft main-story progression EXP cap: computes a 9-step badge-based cap table from grouped major progression fights instead of only the next gym. Gyms stay the backbone, and the real villain / endgame bosses in the same progression block are folded into that block's cap. This is meant to reduce overleveling without changing the cap every few minutes. In-game enforcement still requires the ExLaunch module; the generated details are exported in story-main-progression-soft-caps.json."
                GymLeagueStoryLevelCap = "Gym/champion story EXP cap: computes a 9-step cap table from generated gym/champion teams. In-game enforcement requires ExLaunch. main.npdm is copied from the user's ExeFS dump; the randomizer only provides the custom subsdk9 module."
                StoryMajorBattleOrderLevelCap = "Ordered main-story major battle mode: keeps the dynamic EXP patch globally, then normalizes a fixed ordered list of major base-story fights to each team's max level after randomization. It covers the gyms plus major Hop, Bede, Marnie, Oleana, Rose, and Leon battles from the main story, exports them to story-major-battle-caps.json, and uses every starter-dependent or version-dependent variant that exists in trainer data. This is still based on a curated ordered list, not a live hidden story-state reader."
                AutoInstallToEden = "Auto-install into selected detected emulators: after generation finishes, the tool tries to copy romfs, exefs and the generated sdmc subtree into every checked emulator found on the PC."
                EdenModName = "Installed mod folder name: controls the final mod folder name under the emulator-specific load/mods path. Keep Randomizer if you simply want the new build to replace the previous run."
                InstallTargetEden = "Install to Eden: this target uses %AppData%\\eden\\load\\<titleId>\\<modName> plus %AppData%\\eden\\sdmc\\config\\swsh-mods-exl\\config.toml."
                InstallTargetRyujinx = "Install to Ryujinx: this target uses %AppData%\\Ryujinx\\mods\\contents\\<titleId>\\<modName> plus %AppData%\\Ryujinx\\sdcard\\config\\swsh-mods-exl\\config.toml."
                InstallTargetYuzu = "Install to Yuzu: this target uses %AppData%\\yuzu\\load\\<titleId>\\<modName> plus %AppData%\\yuzu\\sdmc\\config\\swsh-mods-exl\\config.toml."
                InstallTargetSudachi = "Install to Sudachi: this target uses %AppData%\\sudachi\\load\\<titleId>\\<modName> plus %AppData%\\sudachi\\sdmc\\config\\swsh-mods-exl\\config.toml."
                InstallTargetCitron = "Install to Citron: this target uses %AppData%\\citron\\load\\<titleId>\\<modName> plus %AppData%\\citron\\sdmc\\config\\swsh-mods-exl\\config.toml."
                InstallTargetSuyu = "Install to Suyu: this target uses %AppData%\\suyu\\load\\<titleId>\\<modName> plus %AppData%\\suyu\\sdmc\\config\\swsh-mods-exl\\config.toml."
                InstallTargetCitronNeo = "Install to Citron Neo: this target checks Citron Neo / Citron Team style folders such as %AppData%\\citron team, then uses load\\<titleId>\\<modName> plus sdmc\\config\\swsh-mods-exl\\config.toml."
                DifficultyProfile = "Difficulty profile: applies a coherent preset of randomizer options without touching your ROMFS/ExeFS paths, output folder or emulator targets. Example: Smogon strategic switches trainer moves, abilities and held items to Smogon-based choices; Hardcore gyms + league expands selected bosses to 6 Pokemon."
                ValidateBuild = "Build validation: checks source folders, required ROMFS files, ExeFS needs for runtime options, numeric ranges and obvious option conflicts before generation. Example: if hidden visible battles are enabled without an ExeFS dump, the build is blocked before writing a broken mod."
                BuildSummary = "Build summary: opens the same 'what will be modified' page used before generation. Example: before writing files, it shows whether trainers, encounters, EXP Share, ExLaunch, Smogon options and emulator install targets will be changed."
            }
        }
    }

    return @{
        FormTitle = "PokeFeur Randomizer SWSH V4.17"
            SourceLabel = "Dossier ROMFS original"
            SourceExefsLabel = "Dossier ExeFS original"
            OutputLabel = "Dossier du mod genere"
            GameVersion = "Jeu cible"
        Browse = "Parcourir"
        Seed = "Seed (-1 = auto)"
        UiLanguage = "Langue du logiciel"
        ReportLanguage = "Langue rapport JSON"
        Theme = "Theme"
        DifficultyProfile = "Profil de difficulte"
        ApplyDifficultyProfile = "Appliquer profil"
        ValidateBuild = "Verifier config"
        BuildSummary = "Resume build"
        Generate = "Generer le mod"
        Tabs = @{ General = "Generation"; Trainers = "Dresseurs"; Pokemon = "Pokemon"; Evolutions = "Evolutions"; Gifts = "Starters / cadeaux"; Encounters = "Rencontres"; Help = "Aide"; Reset = "Nettoyage" }
        GeneralLines = @(
            "Build complet: ROMFS utilisateur + ExeFS utilisateur, ExLaunch, presets JSON, rapports detailles et installation auto emulateurs.",
            "BST = somme des 6 stats de base. Le mode BST proche garde une puissance comparable.",
            "Dresseurs: especes, moves, objets, IV/EV, shiny, IA, Dynamax, tailles d'equipe et boss a 6.",
            "Pokemon: types, talents, stats, EXP donne, attaques globales et evolutions.",
            "Rencontres: fixes, sauvages, visibles, underground, mappings stables et combats caches.",
            "Starters: noms FR/EN acceptes, exemple Empiflor / Pingoleon / Empiflor.",
            "Caps EXP: les modes runtime demandent ExLaunch et exportent leurs tables JSON."
        )
            ModeRandom = "Random complet"
            ModeSimilarBST = "Random equilibre (BST proche)"
            ModeUnchanged = "Garder vanilla"
            MappingSlot = "Stable par slot"
            MappingSpecies = "Stable par espece"
            MappingTrueRandom = "Tirage frais par entree"
        TrainerMoveRandom4 = "4 attaques aleatoires"
        TrainerMoveLevel4 = "Attaques naturelles au niveau"
        TrainerMoveSmogon = "Strategique Smogon"
        TrainerMoveSmogonLegacy = "Smogon + anciennes gens"
        TrainerSmogonMoveFallbackLevel = "Backup: attaques naturelles"
        TrainerSmogonMoveFallbackRandom = "Backup: attaques random"
        TrainerSmogonMoveFallbackUnchanged = "Backup: garder vanilla"
        TrainerItemRandomPresent = "Random si objet deja present"
        TrainerItemForceAll = "Objet random sur tous"
        TrainerItemSmogon = "Objet strategique Smogon"
        TrainerItemSmogonLegacy = "Objet Smogon + anciennes gens"
        TrainerItemRemoveAll = "Supprimer tous les objets"
        TrainerItemPoolBattle = "Pool combat (objets utiles)"
        TrainerItemPoolFull = "Pool large safe (chaotique)"
        TrainerAddedSlotRandom = "Slots ajoutes: random complet"
        TrainerAddedSlotSimilarBST = "Slots ajoutes: BST proche"
        TrainerAddedSlotSameType = "Slots ajoutes: meme type"
        TrainerAddedSlotSameTypeBST = "Slots ajoutes: meme type + BST"
        TrainerDuplicateNoDuplicates = "Bloquer les doublons"
        TrainerDuplicateNormal = "Random normal (doublons possibles)"
        BossScopeMajor = "Boss importants"
        BossScopeGymLeague = "Arenes + ligue uniquement"
        TrainerAbilityRandom = "Randomiser le slot talent dresseur"
        TrainerAbilitySmogon = "Talent strategique Smogon"
        TrainerAbilitySmogonLegacy = "Talent Smogon + anciennes gens"
        TrainerIVMax = "31 partout"
        TrainerIVRandom = "Aleatoire"
        TrainerEVSmogon = "EV strategiques Smogon"
        TrainerEVSmogonLegacy = "EV Smogon + anciennes gens"
        TrainerEVRandom = "EV legaux aleatoires"
        TrainerEVZero = "Mettre EV a zero"
        TrainerNatureUnchanged = "Garder nature vanilla"
        TrainerNatureRandom = "Nature aleatoire"
        TrainerNatureSmogon = "Nature strategique Smogon"
        TrainerNatureSmogonLegacy = "Nature Smogon + anciennes gens"
        StarterRandom = "Starters aleatoires"
        StarterSimilarBST = "Starters BST proche"
        StarterUnchanged = "Ne pas changer les starters"
        StatShuffle = "Melanger les 6 stats"
        StatRedistribute = "Redistribuer le BST"
        ReportLanguageFrench = "Francais"
        ReportLanguageEnglish = "English"
        UiLanguageFrench = "Francais"
        UiLanguageEnglish = "English"
        ThemeLight = "Clair"
        ThemeDark = "Sombre"
        Labels = @{
            TrainerSpecies = "Pokemon des dresseurs"
            TrainerMoves = "Attaques des dresseurs"
            TrainerSmogonMoveFallback = "Backup moves Smogon"
            TrainerItems = "Objets tenus des dresseurs"
            TrainerItemPool = "Pool des objets random"
            TrainerAddedSlotSpecies = "Pokemon ajoutes aux equipes a 6"
            TrainerDuplicateMode = "Doublons dans les equipes"
            TrainerAbility = "Talents des dresseurs"
            TrainerIV = "IV des dresseurs"
            TrainerEV = "EV des dresseurs"
            TrainerLevel = "Multiplicateur des niveaux"
            TrainerTeamMin = "Taille equipe minimum"
            TrainerTeamMax = "Taille equipe maximum"
            TrainerTypeThemed = "Equipes random par type"
            TrainerShinyChance = "Taux shiny dresseurs (%)"
            ForceTrainerFullyEvolved = "Forcer les evolutions finales"
            TrainerFullyEvolvedLevel = "Niveau minimum evolution finale"
            MaxTrainerAI = "IA dresseur au maximum"
            TrainerDynamaxLevel = "Niveau Dynamax dresseurs"
            TrainerDynamaxUnchanged = "Ne pas changer"
            TrainerDynamaxMax = "Dynamax niveau 10"
            TrainerDynamaxRandom = "Aleatoire 0-10"
            ForceTrainerCanDynamax = "Autoriser Dynamax chez tous les dresseurs"
            ForceAllTeams = "Mettre tous les dresseurs a 6 Pokemon"
            ForceBossTeams = "Mettre certains boss a 6 Pokemon"
            BossTeamsScope = "Liste de boss utilisee"
            AllowLegendaryTrainers = "Autoriser les legendaires chez les dresseurs"
            RandomizeNatures = "Natures des dresseurs"
            TypeMode = "Types des especes"
            ForceMonotype = "Forcer un seul type"
            AbilityMode = "Talents globaux des especes"
            AllowWonderGuard = "Autoriser Wonder Guard dans le pool"
            StatMode = "Stats de base des especes"
            ExpYieldMultiplier = "Multiplicateur EXP donne [NECESSITE EXEFS si != 1.0]"
            ForceOneExpYield = "Mode No EXP: forcer 1 EXP par Pokemon battu"
            MoveTypeMode = "Randomiser les types d'attaques"
            MovePowerMode = "Randomiser la puissance"
            MovePPMode = "Randomiser les PP"
            MovePowerMin = "Puissance min"
            MovePowerMax = "Puissance max"
            MovePPMin = "PP min"
            MovePPMax = "PP max"
            MoveAccuracyMode = "Randomiser la precision"
            MoveAccuracyMin = "Precision min"
            MoveAccuracyMax = "Precision max"
            MoveCategoryMode = "Randomiser physique/special"
            EvolutionMode = "Cibles d'evolution"
            AllowLegendaryEvo = "Autoriser legendaires en evolution"
            NormalizeFriendship = "Convertir les evolutions amitie en niveau fixe"
            FriendshipLevel = "Niveau amitie"
            NormalizeTrade = "Convertir les evolutions echange en niveau fixe"
            TradeLevel = "Niveau echange"
            NormalizeSpecial = "Convertir les evolutions chelou en niveau fixe"
            SpecialLevel = "Niveau special"
            GiftMode = "Pokemon cadeaux"
            StarterMode = "Starters"
            AllowLegendaryGifts = "Autoriser les legendaires pour gifts et starters"
            ManualStarterGroup = "Starters manuels: laisse les 3 champs vides pour le mode ci-dessus, ou remplis les 3 pour forcer un trio."
            Slot1 = "Slot 1"
            Slot2 = "Slot 2"
            Slot3 = "Slot 3"
            PatchStarters = "Repatcher les equipes liees au choix du starter"
            TradeMode = "Trades PNJ"
            AllowLegendaryTrades = "Autoriser legendaires dans les trades PNJ"
            StaticMode = "Rencontres fixes / scriptes"
            AllowLegendaryStatic = "Autoriser legendaires en rencontres fixes"
            StaticStableMapping = "Mapping stable statiques"
            GrassMode = "Especes des rencontres sauvages"
            AllowLegendaryGrass = "Autoriser legendaires en herbes / visibles"
            GrassStableMapping = "Regle de mapping sauvage"
            VisibleEncounterBehavior = "Pokemon visibles dehors [NECESSITE EXEFS hors Classique]"
            UndergroundMode = "Underground / chika"
            AllowLegendaryUnderground = "Autoriser legendaires en underground"
            DisableExpShare = "EXP Share par defaut: OFF [NECESSITE EXEFS]"
            EarlyBike = "Velo Rotom des le debut [NECESSITE EXEFS]"
            RuntimePcControls = "Menu PC: changer en jeu [NECESSITE EXEFS]"
            DynamicExpLevelCap = "Cap EXP dynamique (ExLaunch) [NECESSITE EXEFS]"
            StrictBossMaxLevelCap = "Cap boss max strict pour les boss listes [NECESSITE EXEFS]"
            MainStorySoftLevelCap = "Cap progression principale (souple) [NECESSITE EXEFS]"
            GymLeagueStoryLevelCap = "Cap EXP arenes/Tarak [NECESSITE EXEFS]"
            StoryMajorBattleOrderLevelCap = "Mode ordre histoire principale (boss majeurs) [NECESSITE EXEFS]"
            AutoInstallToEden = "Installation auto"
            EdenModName = "Dossier du mod"
            InstallTargetEden = "Eden"
            InstallTargetRyujinx = "Ryujinx"
            InstallTargetYuzu = "Yuzu"
            InstallTargetSudachi = "Sudachi"
            InstallTargetCitron = "Citron"
            InstallTargetSuyu = "Suyu"
            InstallTargetCitronNeo = "Citron Neo"
            HelpBox = "Aide"
            ResetTargets = "Cibles du reset"
            ResetButton = "Reset de l'installation emulateur"
            ResetDefault = "Le reset supprime seulement le dossier de mod genere et le fichier swsh-mods-exl quand cette config a ete generee par ce randomizer."
            DetailsDefault = "Survole ou selectionne une option pour voir exactement ce qu'elle modifie et ou c'est applique."
            StatusDefault = "Pret. Choisis le dossier ROMFS de ton dump, ajoute ExeFS seulement si une option runtime/ExLaunch en a besoin, regle tes options, puis genere le mod. La sortie contient ROMFS, fichiers ExLaunch, config et rapports JSON si necessaire."
            StatusRunning = "Generation en cours..."
            SeedError = "Le seed doit etre un entier numerique. Utilise -1 pour auto."
        }
        Descriptions = @{
            TrainerSpecies = "Pokemon des dresseurs: Random complet remplace chaque slot par n'importe quel Pokemon autorise. Random equilibre (BST proche) vise une puissance globale proche. Garder vanilla conserve les especes d'origine."
            TrainerMoves = "Attaques des dresseurs: 4 attaques aleatoires pioche dans le pool global. Attaques naturelles au niveau reconstruit les attaques apprises normalement par le Pokemon a son niveau."
            TrainerItems = "Objets tenus dresseurs: Random seulement si present respecte les slots qui ont deja un objet. Objet random sur tous donne un objet tenu aleatoire a chaque Pokemon de dresseur. Supprimer tous les objets vide les objets. Les deux modes random utilisent le pool choisi a droite."
            TrainerItemPool = "Pool d'objets tenus: Combat pioche surtout dans les objets utiles en combat comme baies, Restes, Choice items, plaques et boosts de type. Pool large safe est plus large: il evite les objets cles/problemes, mais peut aussi tirer balls, soins, fossiles, mints, bonbons et autres objets non-cle pour les runs chaotiques."
            TrainerAddedSlotSpecies = "Especes des slots ajoutes: utilise seulement quand une equipe passe a 6 alors que le mode Pokemon dresseurs est Garder vanilla. Random complet peut ajouter Pingoleon dans une equipe Empiflor; BST proche cherche une puissance comparable; Meme type garde le theme arene/ligue comme Plante pour Milo; Meme type + BST garde theme et puissance. Tarak reste equilibre."
            TrainerDuplicateMode = "Gestion des doublons: Bloquer les doublons est le mode propre actuel et repare les equipes pour eviter deux fois le meme Pokemon ou le meme objet tenu. Random normal retire cette reparation: un doublon peut arriver naturellement, mais seulement par hasard."
            TrainerAbility = "Slot talent dresseur: randomise le selecteur de talent stocke sur chaque Pokemon de dresseur. Ca change le slot utilise, pas les talents globaux de l'espece."
            TrainerIV = "Mode IV: 31 partout ecrit des IV parfaits tout en preservant les flags speciaux SWSH. Aleatoire lance chaque IV entre 0 et 31 et preserve aussi shiny / CanDynamax."
            TrainerEV = "Mode EV: Strategique Smogon utilise la repartition EV du set Smogon choisi quand elle existe, puis retombe sur EV legaux aleatoires. EV legaux aleatoires distribue jusqu'a 510 EV avec la limite 252 par stat. Zero retire les EV de tous les Pokemon de dresseurs."
            TrainerLevel = "Multiplicateur niveau: multiplie les niveaux des Pokemon de dresseurs et limite le resultat entre 1 et 100. Mets 1.0 pour ne pas toucher aux niveaux."
            TrainerTeamSize = "Taille equipe: -1 garde la valeur vanilla. Min / max limite la taille entre 1 et 6. Forcer toutes les equipes a 6 vise d'abord 6, puis la limite min/max s'applique."
            TrainerTypeThemed = "Equipes themees par type: quand les especes des dresseurs sont randomisees, chaque dresseur tire un type et les remplacements viennent du pool de ce type. Inspire de l'option TeamTypeThemed de pkNX."
            RandomizeNatures = "Natures dresseurs: Garder vanilla ne touche pas aux natures, Nature aleatoire tire une des 25 natures legales, et Nature strategique Smogon prend la nature du meme set Smogon que les attaques, l'objet, le talent et les EV."
            AllowLegendaryTrainers = "Legendaires chez les dresseurs: si cette option est decochee, les legendaires et mythiques sont exclus des pools de remplacement. Ca ne supprime pas les legendaires vanilla si le mode Pokemon reste Ne pas changer."
            TrainerShinyChance = "Taux shiny dresseurs: 0 ne touche pas au shiny. Une valeur au-dessus de 0 lance ce pourcentage sur chaque Pokemon de dresseur et ecrit le bit shiny SWSH verifie dans trainer_poke."
            ForceTrainerFullyEvolved = "Forcer stade final apres niveau: si un Pokemon de dresseur atteint au moins ce niveau, l'outil suit sa chaine d'evolution et le remplace par une evolution finale. Les evolutions a branches choisissent une branche autorisee."
            MaxTrainerAI = "IA dresseur au maximum: active tous les flags d'IA connus dans trainer_data, comme l'option TrainerMaxAI de pkNX. Les combats deviennent moins passifs."
            TrainerDynamaxLevel = "Niveau Dynamax dresseurs: modifie l'octet de niveau Dynamax de chaque Pokemon de dresseur. Niveau 10 maximise le bonus de PV Dynamax; aleatoire 0-10 varie selon les slots."
            ForceTrainerCanDynamax = "Autoriser tous les Pokemon de dresseurs a Dynamax: active le bit CanDynamax verifie dans trainer_poke. Ne force pas les formes Gigamax."
            ForceAllTeams = "Forcer toutes les equipes a 6 Pokemon: etend chaque equipe de dresseur jusqu'a six slots en clonant d'abord un slot existant choisi au hasard pour garder un modele coherent. Les slots ajoutes sont ensuite recales vers la vraie plage de niveaux de l'equipe, puis ils repassent dans les options normales du bloc dresseurs: mode espece, mode moves, objets tenus, IV/EV, shiny, Dynamax, etc. Si la randomisation des especes dresseurs est active, les doublons d'espece dans l'equipe finale sont maintenant bloques: l'unicite passe en priorite, et si le pool du mode courant est trop petit le randomizer elargit la selection au lieu d'accepter un doublon."
            ForceBossTeams = "Boss listes ci-contre a 6 Pokemon: etend seulement les combats importants detectes depuis les donnees dresseurs vanilla. Les slots ajoutes ne recopient plus juste le dernier Pokemon: chaque slot bonus prend un slot existant au hasard comme modele de niveau, est recale vers la vraie plage de niveaux de l'equipe, puis suit quand meme les options normales ensuite, y compris le mode espece et le mode moves dresseurs. Si la randomisation des especes dresseurs est active, les doublons d'espece dans l'equipe finale sont maintenant bloques: l'unicite passe en priorite, et si le pool du mode courant est trop petit le randomizer elargit la selection au lieu d'accepter un doublon. Le tout premier combat de Nabil au choix du starter est volontairement exclu pour garder sa structure speciale a 2 Pokemon. La liste visible affiche les personnages uniques; randomizer-report.json et trainer-changes.json exportent les IDs exacts des combats et les tailles d'equipe avant/apres."
            BossTeamsScope = "Liste de boss utilisee pour les equipes a 6: Boss importants est le mode large et peut inclure rivaux, boss histoire et DLC comme Nabil, Travis, Rosemary, Tarak, Shehroz, Liv, Jean-Fleuret, Jean-Targe, Mustar, Sophora, Saturnin et Dhilan. Arenes + ligue uniquement est plus strict: il cible champions d'arene, entrees type Champion Cup / ligue et Tarak, pour une run plus proche du style arenes + conseil 4."
            ForceBossTargets = "Liste des cibles boss: inclut les rivaux et boss d'histoire comme Nabil, Travis, Rosemary, Tarak, Shehroz, Liv, Jean-Fleuret, Jean-Targe, les boss DLC comme Mustar, Sophora, Saturnin, Dhilan, Pivonia, plus les champions d'arene / Champion Cup / ligue detectes dans les donnees vanilla. Le tout premier combat de Nabil au choix du starter est volontairement exclu de l'aide 6 Pokemon. Les employes Macro Cosmos generiques ne sont volontairement pas inclus."
            TypeMode = "Types: Random change les types de toutes les especes. Si monotype est coche, le type 2 recopie le type 1."
            TypesMonotypeOnly = "Forcer monotype: quand les types Pokemon sont randomises, le type 2 recopie le type 1 au lieu de tirer un double type."
            AbilityMode = "Talents Pokemon: randomise les slots de talents dans les donnees personal. Wonder Guard est bloque sauf si tu l'autorises explicitement."
            AllowWonderGuard = "Autoriser Wonder Guard: ajoute Wonder Guard au pool de talents. Ca peut creer des Pokemon tres forts ou injustes, donc c'est volontairement separe."
            StatMode = "Stats: Shuffle permute les 6 stats entre elles. Redistribute conserve le BST total mais recompose une repartition differente."
            ExpYieldMultiplier = "Multiplicateur EXP donne: quand il est different de 1.0, la config ExLaunch generee l'applique au gain EXP final en jeu au lieu de modifier personal_total.bin. 0.6 reproduit l'idee du mod 60_sw, 5.0 fait un vrai x5. Le mode No EXP prend le dessus sur cette valeur."
            ForceOneExpYield = "Mode No EXP: force toutes les especes qui donnent normalement de l'EXP a donner exactement 1 EXP. C'est la version ROMFS propre du mod local no_exp_v132_. C'est global et statique. Utilise le levelcap EXP dynamique si tu veux que le jeu verifie le niveau du Pokemon receveur pendant le combat."
            MoveTypeMode = "Types des attaques: change le type elementaire des attaques globales. Exemple: Crocs Feu peut devenir de type Glace."
            MovePowerMode = "Puissance attaques: randomise seulement la puissance des attaques offensives. Les attaques a puissance 0 restent a 0 pour eviter de casser les attaques de statut."
            MovePPMode = "PP attaques: randomise les PP de base des attaques globales dans la plage choisie."
            MoveAccuracyMode = "Precision attaques: randomise la precision des attaques qui utilisent une valeur de precision. Les cas speciaux a 0 restent a 0."
            MoveCategoryMode = "Categorie attaques: randomise les attaques offensives entre physique et special. Les attaques de statut sont conservees."
            StarterMode = "Mode starters: Starters aleatoires remplace uniquement les trois starters. Starters BST proche garde une puissance proche de Ouistempo / Flambino / Larmeleon. Ce mode global n'est utilise que si les 3 champs de starters manuels restent vides."
            Starter1 = "Starter manuel slot 1. Tu peux taper un nom FR ou EN, par exemple Pikachu, Bulbizarre ou Eevee. Si tu forces des starters manuels, les 3 champs doivent etre remplis."
            Starter2 = "Starter manuel slot 2. Laisse les 3 champs vides pour continuer a utiliser le mode starters ci-dessus. Renseigne les 3 champs pour imposer exactement le trio visible."
            Starter3 = "Starter manuel slot 3. Le rapport JSON exporte ensuite le trio choisi avec les noms FR et EN."
            PatchStarters = "Patch des equipes liees au choix du starter: apres avoir change les 3 starters visibles, le script lit les donnees vanilla, retrouve tous les slots des familles Ouistempo / Flambino / Larmeleon, puis force ces slots vers le trio final. Ca marche meme si les Pokemon des dresseurs ont ete randomises avant, et les slots patches reconstruisent maintenant aussi leurs attaques pour eviter de garder les moves de l'ancienne espece."
            ReportLanguage = "Langue du JSON: choisit la langue principale des libelles du rapport exporte. La saisie des noms de starters accepte toujours FR et EN."
            UiLanguage = "Langue du logiciel: change a chaud les textes de l'interface et les descriptions d'aide entre francais et anglais."
            EvolutionMode = "Cibles d'evolution: Random complet remappe les evolutions librement. Random equilibre (BST proche) garde des cibles de puissance proche. Exemple: Empiflor peut evoluer vers Pingoleon si le mode le permet."
            AllowLegendaryEvo = "Autoriser legendaires en evolution: ajoute les legendaires et mythiques dans les cibles d'evolution randomisees. Laisse decoche pour une progression plus classique."
            NormalizeFriendship = "Normalisation amitie: convertit les methodes d'amitie en evolution simple par niveau. Methodes couvertes: 1, 2, 3."
            NormalizeTrade = "Normalisation echange: convertit echange simple, echange avec objet et echange contre espece specifique en evolution simple par niveau. Methodes couvertes: 5, 6, 7."
            NormalizeSpecial = "Normalisation des evolutions chelou: convertit toutes les methodes non vides qui ne sont pas deja une evolution niveau pur en evolution par niveau fixe. Ca couvre temps, beaute, lieu, objet/pierre, attaque connue, sexe/meteo/equipe et autres conditions speciales. Si tu veux garder les evolutions par pierre/objet, ne coche pas cette option."
            GiftMode = "Pokemon cadeaux: modifie les cadeaux non starters dans add_poke.bin. Random complet ignore la puissance; Random equilibre (BST proche) garde une puissance proche."
            AllowLegendaryGifts = "Autoriser les legendaires pour gifts et starters: ajoute les legendaires et mythiques dans les pools de remplacement des cadeaux et starters."
            TradeMode = "Trades PNJ: modifie les especes des echanges PNJ. Le Pokemon demande et le Pokemon recu peuvent etre randomises quand le fichier les expose."
            AllowLegendaryTrades = "Autoriser legendaires dans les trades PNJ: ajoute les legendaires et mythiques dans les pools de remplacement des echanges PNJ."
            StaticMode = "Rencontres fixes: agit sur les rencontres scriptes et statiques du fichier event_encount_data.bin."
            AllowLegendaryStatic = "Autoriser legendaires en rencontres fixes: ajoute les legendaires et mythiques dans les pools des rencontres fixes/scriptes."
            GrassMode = "Especes des rencontres sauvages: controle les tables ROMFS utilisees par les hautes herbes, les symboles visibles et les rencontres de terrain. Garder vanilla ne touche pas aux especes des tables; l'option ci-dessous peut quand meme separer ce que tu vois dehors de ce que tu combats."
            AllowLegendaryGrass = "Autoriser legendaires en herbes / visibles: ajoute les legendaires et mythiques dans les pools de remplacement des hautes herbes cachees et des Pokemon visibles en overworld."
            StaticStableMapping = "Mapping statiques: Espece transforme toutes les memes especes vanilla vers le meme remplacement. Slot randomise chaque entree statique/script independamment. Vrai random build tire chaque entree ROMFS independamment; ca ne reroll pas les rencontres en direct dans le jeu."
            GrassStableMapping = "Regle de mapping sauvage: Stable par espece signifie que tous les Pikachu vanilla deviennent le meme remplacement partout. Stable par slot permet au Pikachu d'une route et au Pikachu d'une autre zone de devenir deux especes differentes. Tirage frais par entree est le mode chaotique: chaque entree ROMFS tire son remplacement."
            VisibleEncounterBehavior = "Pokemon visibles dehors: Classique veut dire que tu combats ce que tu vois. Visuel vanilla + combat cache garde le modele original dehors puis remplace l'espece au lancement du combat. Visuel random + combat cache randomise aussi le modele visible et utilise un tirage de combat distinct, donc voir une espece ne revele pas le combat."
            UndergroundMode = "Underground: modifie les slots d'especes du souterrain, stockes separement des rencontres normales de terrain."
            AllowLegendaryUnderground = "Autoriser legendaires en underground: ajoute les legendaires et mythiques dans les pools de remplacement du souterrain."
            DisableExpShare = "EXP Share par defaut: OFF: ecrit enabled=false dans la config ExLaunch [exp_share] generee. Si le menu PC runtime est active, c'est seulement l'etat de depart et le joueur peut le changer en jeu."
            EarlyBike = "Velo Rotom des le debut: ecrit active=true dans la config ExLaunch [early_bike]. Le module ajoute une fois le vrai objet rare Velo Rotom quand le terrain est charge."
            RuntimePcControls = "Menu PC pour changer en jeu: remplace le script du PC du Centre Pokemon uniquement si cette option est cochee. Cette option ne desactive pas l'EXP Share toute seule; elle permet seulement de modifier les options runtime en jeu. Decoche, le menu PC vanilla reste intact et les options du logiciel sont appliquees directement."
            DynamicExpLevelCap = "Levelcap EXP dynamique: n'ecrit plus l'ancien IPS brut. Le chemin fiable passe par ExLaunch a la fin du calcul EXP. L'outil copie main.npdm depuis le dump ExeFS utilisateur et ajoute seulement le module custom subsdk9."
            StrictBossMaxLevelCap = "Cap boss max strict: calcule toujours les caps et peut normaliser les equipes boss listees, mais le blocage EXP en jeu requiert maintenant le module ExLaunch. main.npdm vient du dump ExeFS utilisateur; le randomizer ajoute seulement le module custom subsdk9. Sans ce module, le JSON sert de reference et l'EXP n'est pas bloquee."
            MainStorySoftLevelCap = "Cap progression principale souple: calcule une table de 9 caps basee sur les badges, mais chaque palier prend le niveau max des gros combats de progression du meme bloc plutot que seulement la prochaine arene. Les arenes restent l'ossature, et les vrais boss antagonistes / fin d'histoire du meme bloc sont ajoutes pour eviter l'overlevel sans changer le cap toutes les 10 minutes. L'application en jeu demande le module ExLaunch; le detail est exporte dans story-main-progression-soft-caps.json."
            GymLeagueStoryLevelCap = "Cap EXP histoire arenes/Tarak: calcule une table de 9 caps depuis les vraies equipes generees. L'application en jeu requiert ExLaunch. main.npdm vient du dump ExeFS utilisateur; le randomizer fournit seulement le module custom subsdk9."
            StoryMajorBattleOrderLevelCap = "Mode ordre histoire principale: garde le patch EXP dynamique global puis normalise une liste fixe et ordonnee des gros combats de l'histoire principale sur le niveau max de chaque equipe apres randomisation. Ca couvre les arenes plus les combats majeurs de Nabil, Travis, Rosemary, Liv, Shehroz et Tarak, exportes dans story-major-battle-caps.json, avec toutes les variantes dependantes du starter ou de la version presentes dans les donnees dresseurs. Ca repose encore sur une liste ordonnee preparee a la main, pas sur un lecteur temps reel de l'etat cache du scenario."
            AutoInstallToEden = "Installation auto vers les emulateurs coches et detectes: apres la generation, l'outil tente de copier romfs, exefs et le sous-arbre sdmc genere vers tous les emulateurs coches et trouves sur le PC."
            EdenModName = "Nom du dossier de mod installe: controle le nom final du dossier de mod dans le chemin load/mods propre a chaque emulateur. Garde Randomizer si tu veux simplement remplacer la run precedente."
            InstallTargetEden = "Installer vers Eden: utilise %AppData%\\eden\\load\\<titleId>\\<nomDuMod> plus %AppData%\\eden\\sdmc\\config\\swsh-mods-exl\\config.toml."
            InstallTargetRyujinx = "Installer vers Ryujinx: utilise %AppData%\\Ryujinx\\mods\\contents\\<titleId>\\<nomDuMod> plus %AppData%\\Ryujinx\\sdcard\\config\\swsh-mods-exl\\config.toml."
            InstallTargetYuzu = "Installer vers Yuzu: utilise %AppData%\\yuzu\\load\\<titleId>\\<nomDuMod> plus %AppData%\\yuzu\\sdmc\\config\\swsh-mods-exl\\config.toml."
            InstallTargetSudachi = "Installer vers Sudachi: utilise %AppData%\\sudachi\\load\\<titleId>\\<nomDuMod> plus %AppData%\\sudachi\\sdmc\\config\\swsh-mods-exl\\config.toml."
            InstallTargetCitron = "Installer vers Citron: utilise %AppData%\\citron\\load\\<titleId>\\<nomDuMod> plus %AppData%\\citron\\sdmc\\config\\swsh-mods-exl\\config.toml."
            InstallTargetSuyu = "Installer vers Suyu: utilise %AppData%\\suyu\\load\\<titleId>\\<nomDuMod> plus %AppData%\\suyu\\sdmc\\config\\swsh-mods-exl\\config.toml."
            InstallTargetCitronNeo = "Installer vers Citron Neo: cherche les dossiers style Citron Neo / Citron Team comme %AppData%\\citron team, puis utilise load\\<titleId>\\<nomDuMod> et sdmc\\config\\swsh-mods-exl\\config.toml."
            DifficultyProfile = "Profil de difficulte: applique un preset coherent d'options de randomisation sans toucher aux chemins ROMFS/ExeFS, au dossier de sortie ou aux cibles emulateur. Exemple: Strategique Smogon passe les moves, talents et objets dresseurs en choix Smogon; Hardcore arenes + ligue met les boss selectionnes a 6 Pokemon."
            ValidateBuild = "Validation du build: verifie les dossiers source, les fichiers ROMFS requis, le besoin ExeFS pour les options runtime, les plages numeriques et les incompatibilites evidentes avant generation. Exemple: si les combats visibles caches sont actives sans dump ExeFS, la generation est bloquee avant d'ecrire un mod casse."
            BuildSummary = "Resume du build: ouvre la meme page 'ce qui va etre modifie' que celle affichee avant generation. Exemple: avant d'ecrire les fichiers, tu vois si dresseurs, rencontres, EXP Share, ExLaunch, options Smogon et installations emulateur seront changes."
        }
    }
}

function Get-RandomizerHelpText {
    param(
        [string]$Language = "fr",
        [string]$GameVersion = "Sword",
        [string]$ModName = "Randomizer",
        [string]$OutputRomfsRoot = ""
    )

    $lang = if ($Language -eq "en") { "en" } else { "fr" }
    $ui = Get-UiStrings -Language $lang
    Add-ConcreteDescriptionExamples -Ui $ui -Language $lang

    $labels = $ui.Labels
    $descriptions = $ui.Descriptions
    $lines = New-Object System.Collections.Generic.List[string]

    $addLine = {
        param([string]$Text = "")
        [void]$lines.Add($Text)
    }
    $addSection = {
        param([string]$Title)
        & $addLine ""
        & $addLine ("=== {0} ===" -f $Title)
    }
    $addOption = {
        param(
            [string]$Label,
            [string]$Description
        )
        if (-not [string]::IsNullOrWhiteSpace($Label) -and -not [string]::IsNullOrWhiteSpace($Description)) {
            & $addLine ("- {0}: {1}" -f $Label, $Description)
        }
    }
    $addKey = {
        param(
            [string]$Key,
            [string]$Fallback = ""
        )
        $label = [string]$labels[$Key]
        $description = [string]$descriptions[$Key]
        if ([string]::IsNullOrWhiteSpace($description)) {
            $description = $Fallback
        }
        & $addOption $label $description
    }

    if ($lang -eq "en") {
        & $addLine "PokeFeur Randomizer help"
        & $addLine "Every option below is generated from the same labels/descriptions used by the interface. Examples use Victreebel and Empoleon so the behavior stays concrete."
        & $addSection "Main build"
        & $addOption $ui.SourceLabel "Folder from the user's ROMFS dump. Example: select the romfs folder from Pokemon Sword/Shield; if the expected SWSH files are missing, generation must stop instead of producing a broken mod."
        & $addOption $ui.SourceExefsLabel "Folder from the user's ExeFS dump. Example: the tool copies main.npdm from this user dump when ExLaunch is needed; no Nintendo ExeFS file is bundled by the tool."
        & $addOption $ui.OutputLabel "Root folder where the generated mod is written. Example: choosing output\\Sword always creates romfs there; exefs and sdmc are added only when an ExeFS folder is explicitly provided for ExLaunch/runtime features."
        & $addOption $ui.GameVersion "Chooses the title ID and version-specific install paths. Example: Sword and Shield use different emulator content folders."
        & $addOption $ui.Seed "Controls repeatability. Example: seed 123 always produces the same Victreebel to Empoleon style mappings; -1 creates a new random seed."
        & $addOption $ui.UiLanguage "Changes the software language immediately."
        & $addOption $ui.ReportLanguage "Changes labels in JSON reports without changing the randomization itself."
        & $addOption $ui.Theme "Switches the interface theme."
        & $addOption $ui.DifficultyProfile $descriptions.DifficultyProfile
        & $addOption $ui.ValidateBuild $descriptions.ValidateBuild
        & $addOption $ui.BuildSummary $descriptions.BuildSummary
        & $addOption $ui.Generate "Builds the mod from the user ROMFS/ExeFS folders and current options."
        & $addOption "Export preset / Import preset" "Preset JSON saves and restores the software configuration only. Example: export your trainer/encounter settings, then import them later before generating another run."
    } else {
        & $addLine "Aide du PokeFeur Randomizer"
        & $addLine "Chaque option ci-dessous reprend les memes libelles/descriptions que l'interface. Les exemples utilisent Empiflor et Pingoleon pour que l'effet soit concret."
        & $addSection "Generation principale"
        & $addOption $ui.SourceLabel "Dossier romfs du dump utilisateur. Exemple: selectionne le dossier romfs de Pokemon Epee/Bouclier; si les fichiers SWSH attendus manquent, la generation doit s'arreter au lieu de sortir un mod casse."
        & $addOption $ui.SourceExefsLabel "Dossier exefs du dump utilisateur. Exemple: l'outil copie main.npdm depuis ce dump utilisateur quand ExLaunch est necessaire; aucun fichier ExeFS Nintendo n'est fourni avec le logiciel."
        & $addOption $ui.OutputLabel "Dossier racine ou le mod genere est ecrit. Exemple: choisir output\\Epee cree toujours romfs dedans; exefs et sdmc ne sont ajoutes que si un dossier ExeFS est explicitement fourni pour les options ExLaunch/runtime."
        & $addOption $ui.GameVersion "Choisit le title ID et les chemins d'installation selon le jeu. Exemple: Epee et Bouclier n'utilisent pas le meme dossier de contenu emulateur."
        & $addOption $ui.Seed "Controle la reproductibilite. Exemple: seed 123 redonne toujours les memes mappings du style Empiflor vers Pingoleon; -1 cree un nouveau tirage."
        & $addOption $ui.UiLanguage "Change immediatement la langue du logiciel."
        & $addOption $ui.ReportLanguage "Change la langue des libelles dans les rapports JSON sans changer la randomisation."
        & $addOption $ui.Theme "Change le theme visuel du logiciel."
        & $addOption $ui.DifficultyProfile $descriptions.DifficultyProfile
        & $addOption $ui.ValidateBuild $descriptions.ValidateBuild
        & $addOption $ui.BuildSummary $descriptions.BuildSummary
        & $addOption $ui.Generate "Genere le mod depuis les dossiers ROMFS/ExeFS utilisateur et les options actuelles."
        & $addOption "Exporter preset / Importer preset" "Le preset JSON sauvegarde et restaure seulement la configuration du logiciel. Exemple: exporte tes reglages dresseurs/rencontres, puis importe-les plus tard avant une autre generation."
    }

    & $addSection $ui.Tabs.General
    foreach ($key in @("DisableExpShare", "GymLeagueStoryLevelCap", "RuntimePcControls", "AutoInstallToEden", "EdenModName", "InstallTargetEden", "InstallTargetRyujinx", "InstallTargetYuzu", "InstallTargetSudachi", "InstallTargetCitron", "InstallTargetSuyu", "InstallTargetCitronNeo")) {
        & $addKey $key
    }

    & $addSection $ui.Tabs.Trainers
    foreach ($key in @(
        "TrainerSpecies", "TrainerMoves", "TrainerSmogonMoveFallback", "TrainerItems", "TrainerItemPool", "TrainerAbility", "TrainerIV", "TrainerEV", "TrainerAddedSlotSpecies", "TrainerDuplicateMode",
        "TrainerLevel", "TrainerTeamSize", "ForceAllTeams", "ForceBossTeams", "BossTeamsScope", "RandomizeNatures", "AllowLegendaryTrainers", "TrainerShinyChance",
        "TrainerTypeThemed", "ForceTrainerFullyEvolved", "TrainerDynamaxLevel", "ForceTrainerCanDynamax", "MaxTrainerAI"
    )) {
        & $addKey $key
    }
    if ($lang -eq "en") {
        & $addOption $labels.TrainerTeamMin "Minimum trainer party size. Example: 3 forces tiny teams upward to at least 3 Pokemon."
        & $addOption $labels.TrainerTeamMax "Maximum trainer party size. Example: 4 prevents regular trainers from going above 4 Pokemon unless a 6-Pokemon helper applies first."
        & $addOption $labels.TrainerFullyEvolvedLevel "Level used by Force final evolutions. Example: 40 means Empoleon-style final stages are forced from level 40 onward."
    } else {
        & $addOption $labels.TrainerTeamMin "Taille minimum des equipes de dresseurs. Exemple: 3 remonte les petites equipes a au moins 3 Pokemon."
        & $addOption $labels.TrainerTeamMax "Taille maximum des equipes de dresseurs. Exemple: 4 empeche les dresseurs classiques de depasser 4 Pokemon sauf si une aide equipe a 6 s'applique avant."
        & $addOption $labels.TrainerFullyEvolvedLevel "Niveau utilise par Forcer les evolutions finales. Exemple: 40 force les stades finaux comme Pingoleon a partir du niveau 40."
    }

    & $addSection $ui.Tabs.Pokemon
    foreach ($key in @(
        "TypeMode", "TypesMonotypeOnly", "AbilityMode", "AllowWonderGuard", "StatMode", "ExpYieldMultiplier", "ForceOneExpYield",
        "MoveTypeMode", "MovePowerMode", "MovePPMode", "MoveAccuracyMode", "MoveCategoryMode"
    )) {
        & $addKey $key
    }
    if ($lang -eq "en") {
        & $addOption $labels.MovePowerMin "Minimum power used when move power is randomized. Example: 40 prevents weak damaging moves from rolling below 40 power."
        & $addOption $labels.MovePowerMax "Maximum power used when move power is randomized. Example: 120 prevents random moves from becoming absurdly strong."
        & $addOption $labels.MovePPMin "Minimum PP used when move PP is randomized."
        & $addOption $labels.MovePPMax "Maximum PP used when move PP is randomized."
        & $addOption $labels.MoveAccuracyMin "Minimum accuracy used when move accuracy is randomized."
        & $addOption $labels.MoveAccuracyMax "Maximum accuracy used when move accuracy is randomized."
    } else {
        & $addOption $labels.MovePowerMin "Puissance minimum quand la puissance des attaques est randomisee. Exemple: 40 empeche les attaques offensives de tomber sous 40."
        & $addOption $labels.MovePowerMax "Puissance maximum quand la puissance des attaques est randomisee. Exemple: 120 evite des attaques random absurdes."
        & $addOption $labels.MovePPMin "PP minimum quand les PP des attaques sont randomises."
        & $addOption $labels.MovePPMax "PP maximum quand les PP des attaques sont randomises."
        & $addOption $labels.MoveAccuracyMin "Precision minimum quand la precision des attaques est randomisee."
        & $addOption $labels.MoveAccuracyMax "Precision maximum quand la precision des attaques est randomisee."
    }

    & $addSection $ui.Tabs.Evolutions
    foreach ($key in @("EvolutionMode", "AllowLegendaryEvo", "NormalizeFriendship", "NormalizeTrade", "NormalizeSpecial")) {
        & $addKey $key
    }
    if ($lang -eq "en") {
        & $addOption $labels.FriendshipLevel "Level used after converting friendship evolutions. Example: if set to 30, that evolution happens at level 30."
        & $addOption $labels.TradeLevel "Level used after converting trade evolutions. Example: if set to 36, the old trade evolution becomes level 36."
        & $addOption $labels.SpecialLevel "Level used after converting special evolutions such as location, weather or item conditions."
    } else {
        & $addOption $labels.FriendshipLevel "Niveau utilise apres conversion des evolutions par amitie. Exemple: si tu mets 30, l'evolution arrive au niveau 30."
        & $addOption $labels.TradeLevel "Niveau utilise apres conversion des evolutions par echange. Exemple: si tu mets 36, l'ancienne evolution par echange devient niveau 36."
        & $addOption $labels.SpecialLevel "Niveau utilise apres conversion des evolutions speciales comme lieu, meteo ou condition d'objet."
    }

    & $addSection $ui.Tabs.Gifts
    foreach ($key in @("StarterMode", "Starter1", "Starter2", "Starter3", "PatchStarters", "GiftMode", "AllowLegendaryGifts", "TradeMode", "AllowLegendaryTrades")) {
        & $addKey $key
    }
    if ($lang -eq "en") {
        & $addOption "Manual starters" "Leave all 3 boxes empty to use the starter mode. Fill all 3 boxes to force the exact trio, for example Victreebel / Empoleon / Victreebel."
    } else {
        & $addOption "Starters manuels" "Laisse les 3 champs vides pour utiliser le mode starters. Remplis les 3 champs pour imposer exactement le trio, par exemple Empiflor / Pingoleon / Empiflor."
    }

    & $addSection $ui.Tabs.Encounters
    foreach ($key in @(
        "StaticMode", "AllowLegendaryStatic", "StaticStableMapping", "GrassMode", "AllowLegendaryGrass", "GrassStableMapping",
        "VisibleEncounterBehavior", "UndergroundMode", "AllowLegendaryUnderground"
    )) {
        & $addKey $key
    }

    if ($lang -eq "en") {
        & $addSection "Mode values"
        & $addLine "- Full random: any allowed Pokemon can be picked. Example: Victreebel can become Empoleon."
        & $addLine "- Balanced random (similar BST): keeps replacements close in total base stats. Example: weak early Pokemon stay closer to early-game power."
        & $addLine "- Keep vanilla: leaves that data unchanged."
        & $addLine "- Stable by slot: each table slot gets its own stable result. Example: Route 4 Victreebel can map to Empoleon while another Victreebel elsewhere maps differently."
        & $addLine "- Stable by species: the same vanilla species maps to the same result everywhere. Example: every Victreebel becomes Empoleon."
        & $addLine "- Fresh roll per encounter entry: the build makes fresh rolls for encounter entries; it is the chaotic mode."
        & $addLine "- Classic visible = battle: what you see outside is what you fight."
        & $addLine "- Vanilla visible + hidden battle: outside visuals stay vanilla, but the battle species can be random."
        & $addLine "- Random visible + hidden battle: outside visuals are random and the battle roll is separate."
    } else {
        & $addSection "Valeurs des menus"
        & $addLine "- Random complet: n'importe quel Pokemon autorise peut etre tire. Exemple: Empiflor peut devenir Pingoleon."
        & $addLine "- Random equilibre (BST proche): garde une puissance globale proche. Exemple: un Pokemon faible de debut de jeu reste dans une puissance comparable."
        & $addLine "- Garder vanilla: ne modifie pas ces donnees."
        & $addLine "- Stable par slot: chaque slot de table garde son propre resultat. Exemple: l'Empiflor d'une route peut devenir Pingoleon pendant qu'un autre Empiflor ailleurs devient autre chose."
        & $addLine "- Stable par espece: la meme espece vanilla devient le meme remplacement partout. Exemple: tous les Empiflor deviennent Pingoleon."
        & $addLine "- Tirage frais par entree: la generation fait un tirage frais pour chaque entree de rencontre; c'est le mode chaotique."
        & $addLine "- Classique visible = combat: tu combats ce que tu vois dehors."
        & $addLine "- Visuel vanilla + combat cache: les visuels dehors restent vanilla, mais le combat peut etre random."
        & $addLine "- Visuel random + combat cache: les visuels dehors sont random et le combat utilise un tirage separe."
    }

    & $addSection $ui.Tabs.Reset
    if ($lang -eq "en") {
        & $addOption $labels.ResetTargets "Choose which detected emulator installs should be cleaned."
        & $addOption $labels.ResetButton "Deletes only generated mod files for the selected emulator targets."
    } else {
        & $addOption $labels.ResetTargets "Choisit quelles installations emulateur detectees doivent etre nettoyees."
        & $addOption $labels.ResetButton "Supprime uniquement les fichiers de mod generes pour les emulateurs selectionnes."
    }
    & $addLine $labels.ResetDefault

    $installTitle = if ($lang -eq "en") { "Install paths" } else { "Chemins d'installation" }
    & $addSection $installTitle
    & $addLine (Get-InstallationGuideText -Language $lang -GameVersion $GameVersion -ModName $ModName -OutputRomfsRoot $OutputRomfsRoot)

    return ($lines -join [Environment]::NewLine)
}

function Set-LocalizedComboItems {
    param(
        [System.Windows.Forms.ComboBox]$Combo,
        [array]$Items
    )

    $currentValue = Get-ComboValue -Combo $Combo
    $Combo.Items.Clear()
    foreach ($item in $Items) {
        Add-ComboBoxItem -Combo $Combo -Label $item.Label -Value $item.Value
    }
    $Combo.DisplayMember = "Label"

    if ($currentValue) {
        for ($i = 0; $i -lt $Combo.Items.Count; $i++) {
            if ($Combo.Items[$i].Value -eq $currentValue) {
                $Combo.SelectedIndex = $i
                return
            }
        }
    }

    if ($Combo.Items.Count -gt 0) {
        $Combo.SelectedIndex = 0
    }
}

function Get-NormalizedGuiTheme {
    param([string]$Theme)

    $value = ([string]$Theme).Trim().ToLowerInvariant()
    if ($value -in @("dark", "sombre", "noir")) {
        return "Dark"
    }

    return "Light"
}

function Get-GuiThemePalette {
    param([string]$Theme)

    if ((Get-NormalizedGuiTheme -Theme $Theme) -eq "Dark") {
        return @{
            Name = "Dark"
            Form = [System.Drawing.Color]::FromArgb(8, 12, 20)
            Panel = [System.Drawing.Color]::FromArgb(17, 29, 53)
            Surface = [System.Drawing.Color]::FromArgb(13, 22, 38)
            Input = [System.Drawing.Color]::FromArgb(11, 17, 29)
            InputReadOnly = [System.Drawing.Color]::FromArgb(16, 26, 45)
            Button = [System.Drawing.Color]::FromArgb(17, 29, 53)
            PrimaryButton = [System.Drawing.Color]::FromArgb(20, 82, 116)
            Text = [System.Drawing.Color]::FromArgb(226, 234, 248)
            MutedText = [System.Drawing.Color]::FromArgb(107, 135, 176)
            Border = [System.Drawing.Color]::FromArgb(30, 48, 88)
            SelectedTab = [System.Drawing.Color]::FromArgb(18, 42, 70)
            TabHeader = [System.Drawing.Color]::FromArgb(13, 22, 38)
            Accent = [System.Drawing.Color]::FromArgb(79, 195, 247)
            AccentSoft = [System.Drawing.Color]::FromArgb(21, 64, 92)
            Gold = [System.Drawing.Color]::FromArgb(247, 201, 72)
            Green = [System.Drawing.Color]::FromArgb(74, 222, 128)
            Red = [System.Drawing.Color]::FromArgb(248, 113, 113)
            Pink = [System.Drawing.Color]::FromArgb(244, 114, 182)
            Purple = [System.Drawing.Color]::FromArgb(167, 139, 250)
        }
    }

    return @{
        Name = "Light"
        Form = [System.Drawing.SystemColors]::Control
        Panel = [System.Drawing.SystemColors]::Control
        Surface = [System.Drawing.SystemColors]::Control
        Input = [System.Drawing.SystemColors]::Window
        InputReadOnly = [System.Drawing.SystemColors]::Window
        Button = [System.Drawing.SystemColors]::Control
        PrimaryButton = [System.Drawing.SystemColors]::Control
        Text = [System.Drawing.SystemColors]::ControlText
        MutedText = [System.Drawing.SystemColors]::ControlText
        Border = [System.Drawing.SystemColors]::ControlDark
        SelectedTab = [System.Drawing.SystemColors]::Window
        TabHeader = [System.Drawing.SystemColors]::Control
        Accent = [System.Drawing.Color]::FromArgb(49, 101, 205)
        AccentSoft = [System.Drawing.Color]::FromArgb(225, 235, 255)
        Gold = [System.Drawing.Color]::FromArgb(173, 125, 13)
        Green = [System.Drawing.Color]::FromArgb(38, 138, 79)
        Red = [System.Drawing.Color]::FromArgb(190, 60, 60)
        Pink = [System.Drawing.Color]::FromArgb(184, 69, 136)
        Purple = [System.Drawing.Color]::FromArgb(94, 70, 170)
    }
}

function Enable-GuiDoubleBuffer {
    param([System.Windows.Forms.Control]$Control)

    if (-not $Control) {
        return
    }

    try {
        $prop = [System.Windows.Forms.Control].GetProperty("DoubleBuffered", [System.Reflection.BindingFlags] "Instance, NonPublic")
        if ($prop) {
            $prop.SetValue($Control, $true, $null)
        }
    } catch {
    }
}

function Add-PokeFeurBackground {
    param([System.Windows.Forms.Form]$Form)

    $Form.Add_Paint({
        param($sender, $eventArgs)
        $palette = Get-GuiThemePalette -Theme $script:GuiTheme
        $g = $eventArgs.Graphics
        $g.Clear($palette.Form)

        $gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(18, $palette.Accent))
        $linePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(26, $palette.Border))
        $glowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(24, $palette.Accent))
        $goldBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(16, $palette.Gold))
        try {
            for ($x = 0; $x -lt $sender.ClientSize.Width; $x += 40) {
                $g.DrawLine($gridPen, $x, 0, $x, $sender.ClientSize.Height)
            }
            for ($y = 0; $y -lt $sender.ClientSize.Height; $y += 40) {
                $g.DrawLine($gridPen, 0, $y, $sender.ClientSize.Width, $y)
            }
            $g.FillRectangle($glowBrush, 0, 0, $sender.ClientSize.Width, 88)
            $g.FillEllipse($goldBrush, $sender.ClientSize.Width - 260, 14, 210, 120)
            $g.DrawLine($linePen, 0, 88, $sender.ClientSize.Width, 88)
        } finally {
            $gridPen.Dispose()
            $linePen.Dispose()
            $glowBrush.Dispose()
            $goldBrush.Dispose()
        }
    })
}

function Apply-GuiThemeToControl {
    param(
        [System.Windows.Forms.Control]$Control,
        [hashtable]$Palette
    )

    if (-not $Control) {
        return
    }

    if ($Control -is [System.Windows.Forms.Form]) {
        $Control.BackColor = $Palette.Form
        $Control.ForeColor = $Palette.Text
        $Control.Font = New-GuiFont -Size 9.5
    } elseif ($Control -is [System.Windows.Forms.TabPage] -or $Control -is [System.Windows.Forms.Panel] -or $Control -is [System.Windows.Forms.GroupBox]) {
        $tag = [string]$Control.Tag
        if ($tag -eq "HeaderPanel") {
            $Control.BackColor = $Palette.Surface
        } elseif ($tag -eq "ChromePanel") {
            $Control.BackColor = $Palette.Panel
        } elseif ($tag -eq "ActionPanel") {
            $Control.BackColor = $Palette.Surface
        } else {
            $Control.BackColor = $Palette.Panel
        }
        $Control.ForeColor = $Palette.Text
        if ($Control -is [System.Windows.Forms.GroupBox]) {
            $Control.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        }
    } elseif ($Control -is [System.Windows.Forms.TextBox]) {
        $Control.BackColor = if ($Control.ReadOnly) { $Palette.InputReadOnly } else { $Palette.Input }
        $Control.ForeColor = $Palette.Text
        $Control.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    } elseif ($Control -is [System.Windows.Forms.ComboBox]) {
        $Control.BackColor = $Palette.Input
        $Control.ForeColor = $Palette.Text
        $Control.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    } elseif ($Control -is [System.Windows.Forms.Button]) {
        $Control.UseVisualStyleBackColor = $false
        $Control.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $Control.BackColor = if ([string]$Control.Tag -eq "PrimaryButton") { $Palette.PrimaryButton } else { $Palette.Button }
        $Control.ForeColor = $Palette.Text
        $Control.FlatAppearance.BorderColor = if ([string]$Control.Tag -eq "PrimaryButton") { $Palette.Accent } else { $Palette.Border }
        $Control.FlatAppearance.MouseOverBackColor = if ([string]$Control.Tag -eq "PrimaryButton") { $Palette.AccentSoft } else { $Palette.SelectedTab }
        $Control.FlatAppearance.MouseDownBackColor = $Palette.Input
        $Control.FlatAppearance.BorderSize = 1
        if ([string]$Control.Tag -eq "PrimaryButton") {
            $Control.Font = New-GuiFont -Size 11 -Style ([System.Drawing.FontStyle]::Bold)
        } else {
            $Control.Font = New-GuiFont -Size 9.25 -Style ([System.Drawing.FontStyle]::Bold)
        }
    } elseif ($Control -is [System.Windows.Forms.CheckBox]) {
        $Control.UseVisualStyleBackColor = $false
        $Control.BackColor = $Palette.Panel
        $Control.ForeColor = $Palette.Text
    } elseif ($Control -is [System.Windows.Forms.Label]) {
        $Control.BackColor = [System.Drawing.Color]::Transparent
        $Control.ForeColor = $Palette.MutedText
        if ([string]$Control.Tag -eq "BrandPoke") {
            $Control.ForeColor = $Palette.Accent
            $Control.Font = New-GuiFont -Family "Segoe UI" -Size 22 -Style ([System.Drawing.FontStyle]::Bold)
        } elseif ([string]$Control.Tag -eq "BrandFeur") {
            $Control.ForeColor = $Palette.Gold
            $Control.Font = New-GuiFont -Family "Segoe UI" -Size 22 -Style ([System.Drawing.FontStyle]::Bold)
        } elseif ([string]$Control.Tag -eq "HeroSub") {
            $Control.ForeColor = $Palette.MutedText
            $Control.Font = New-GuiFont -Size 9.5 -Style ([System.Drawing.FontStyle]::Bold)
        } elseif ([string]$Control.Tag -eq "Title") {
            $Control.ForeColor = $Palette.Accent
            $Control.Font = New-GuiFont -Size 13 -Style ([System.Drawing.FontStyle]::Bold)
        } elseif ([string]$Control.Tag -eq "Accent") {
            $Control.ForeColor = $Palette.Purple
        } elseif ([string]$Control.Tag -eq "InputLabel") {
            $Control.ForeColor = $Palette.MutedText
            $Control.Font = New-GuiFont -Size 9 -Style ([System.Drawing.FontStyle]::Bold)
        }
    } elseif ($Control -is [System.Windows.Forms.TabControl]) {
        $Control.BackColor = $Palette.Form
        $Control.ForeColor = $Palette.Text
    } else {
        $Control.BackColor = $Palette.Form
        $Control.ForeColor = $Palette.Text
    }

    foreach ($child in $Control.Controls) {
        Apply-GuiThemeToControl -Control $child -Palette $Palette
    }
}

function Apply-GuiTheme {
    param(
        [System.Windows.Forms.Control]$Root,
        [string]$Theme
    )

    $script:GuiTheme = Get-NormalizedGuiTheme -Theme $Theme
    $palette = Get-GuiThemePalette -Theme $script:GuiTheme
    Apply-GuiThemeToControl -Control $Root -Palette $palette
    $Root.Refresh()
}

function Show-Gui {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $script:UiLanguage = if (([string]$UiLanguage).ToLowerInvariant() -eq "en") { "en" } else { "fr" }
    $script:GuiTheme = Get-NormalizedGuiTheme -Theme $GuiTheme

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "PokeFeur Randomizer SWSH V4.17"
    $form.ClientSize = New-Object System.Drawing.Size(1164, 980)
    $form.MinimumSize = New-Object System.Drawing.Size(1180, 1020)
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $form.MaximizeBox = $false
    $form.StartPosition = "CenterScreen"
    $form.Font = New-GuiFont -Size 9.5
    Enable-GuiDoubleBuffer -Control $form
    Add-PokeFeurBackground -Form $form

    $controls = @{}
    $initialGameVersion = Get-NormalizedGameVersionSelection -Value $GameVersion
    if ($initialGameVersion -eq "Auto") {
        $initialGameVersion = "Sword"
    }
    $initialSourceRomfs = if (-not [string]::IsNullOrWhiteSpace($SourceRomfs)) {
        $SourceRomfs
    } else {
        Get-ExistingDefaultPathOrEmpty -Path (Get-DefaultSourceRomfsPath -GameVersion $initialGameVersion)
    }
    $initialSourceExefs = if (-not [string]::IsNullOrWhiteSpace($SourceExefs)) {
        $SourceExefs
    } else {
        ""
    }
    $initialOutputRomfs = if (-not [string]::IsNullOrWhiteSpace($OutputRomfs)) { $OutputRomfs } else { Get-DefaultOutputRomfsPath -GameVersion $initialGameVersion }

    $headerPanel = New-GuiChromePanel -X 0 -Y 0 -Width 1164 -Height 90 -Tag "HeaderPanel"
    $form.Controls.Add($headerPanel)
    $heroPanel = New-GuiChromePanel -X 18 -Y 100 -Width 748 -Height 204 -Tag "ChromePanel"
    $form.Controls.Add($heroPanel)
    $versionPanel = New-GuiChromePanel -X 778 -Y 100 -Width 160 -Height 80 -Tag "ChromePanel"
    $form.Controls.Add($versionPanel)
    $actionPanel = New-GuiChromePanel -X 958 -Y 100 -Width 190 -Height 204 -Tag "ActionPanel"
    $form.Controls.Add($actionPanel)
    $headerPanel.SendToBack()
    $heroPanel.SendToBack()
    $versionPanel.SendToBack()
    $actionPanel.SendToBack()

    $brandPoke = New-Label -Text "Poke" -X 24 -Y 16 -Width 96
    $brandPoke.Size = New-Object System.Drawing.Size(96, 40)
    $brandPoke.Tag = "BrandPoke"
    $form.Controls.Add($brandPoke)
    $brandFeur = New-Label -Text "Feur" -X 116 -Y 16 -Width 88
    $brandFeur.Size = New-Object System.Drawing.Size(88, 40)
    $brandFeur.Tag = "BrandFeur"
    $form.Controls.Add($brandFeur)
    $heroSub = New-Label -Text "Randomizer Sword / Shield - ROMFS, ExLaunch, presets et installation emulateur" -X 218 -Y 24 -Width 740
    $heroSub.Tag = "HeroSub"
    $form.Controls.Add($heroSub)

    $sourceLabel = New-Label -Text "" -X 32 -Y 112
    $form.Controls.Add($sourceLabel)
    $sourceBox = New-TextBox -Controls $controls -Name "Source" -X 32 -Y 136 -Width 600 -Text $initialSourceRomfs
    $form.Controls.Add($sourceBox)
    $browseSource = New-Object System.Windows.Forms.Button
    $browseSource.Location = New-Object System.Drawing.Point(642, 134)
    $browseSource.Size = New-Object System.Drawing.Size(100, 30)
    $form.Controls.Add($browseSource)

    $gameVersionLabel = New-Label -Text "" -X 790 -Y 112 -Width 120
    $form.Controls.Add($gameVersionLabel)
    $gameVersionCombo = New-ComboBox -Controls $controls -Name "GameVersion" -X 790 -Y 136 -Width 140
    Add-ComboBoxItem -Combo $gameVersionCombo -Label "Bouclier" -Value "Shield"
    Add-ComboBoxItem -Combo $gameVersionCombo -Label "Epee" -Value "Sword"
    $gameVersionCombo.DisplayMember = "Label"
    $gameVersionCombo.SelectedIndex = if ($initialGameVersion -eq "Sword") { 1 } else { 0 }
    $form.Controls.Add($gameVersionCombo)

    $outputLabel = New-Label -Text "" -X 32 -Y 174 -Width 260
    $form.Controls.Add($outputLabel)
    $outputBox = New-TextBox -Controls $controls -Name "Output" -X 32 -Y 198 -Width 280 -Text $initialOutputRomfs
    $form.Controls.Add($outputBox)
    $browseOutput = New-Object System.Windows.Forms.Button
    $browseOutput.Location = New-Object System.Drawing.Point(322, 196)
    $browseOutput.Size = New-Object System.Drawing.Size(88, 30)
    $form.Controls.Add($browseOutput)

    $sourceExefsLabel = New-Label -Text "" -X 430 -Y 174 -Width 260
    $form.Controls.Add($sourceExefsLabel)
    $sourceExefsBox = New-TextBox -Controls $controls -Name "SourceExefs" -X 430 -Y 198 -Width 220 -Text $initialSourceExefs
    $form.Controls.Add($sourceExefsBox)
    $browseSourceExefs = New-Object System.Windows.Forms.Button
    $browseSourceExefs.Location = New-Object System.Drawing.Point(660, 196)
    $browseSourceExefs.Size = New-Object System.Drawing.Size(82, 30)
    $form.Controls.Add($browseSourceExefs)

    $seedLabel = New-Label -Text "" -X 32 -Y 254
    $form.Controls.Add($seedLabel)
    $seedBox = New-TextBox -Controls $controls -Name "Seed" -X 32 -Y 278 -Width 120 -Text "-1"
    $form.Controls.Add($seedBox)

    $uiLangLabel = New-Label -Text "" -X 176 -Y 254 -Width 160
    $form.Controls.Add($uiLangLabel)
    $uiLangCombo = New-ComboBox -Controls $controls -Name "UiLanguage" -X 176 -Y 278 -Width 150
    Add-ComboBoxItem -Combo $uiLangCombo -Label "Francais" -Value "fr"
    Add-ComboBoxItem -Combo $uiLangCombo -Label "English" -Value "en"
    $uiLangCombo.DisplayMember = "Label"
    $uiLangCombo.SelectedIndex = if ($script:UiLanguage -eq "en") { 1 } else { 0 }
    $form.Controls.Add($uiLangCombo)

    $reportLangLabel = New-Label -Text "" -X 352 -Y 254 -Width 170
    $form.Controls.Add($reportLangLabel)
    $reportLangCombo = New-ComboBox -Controls $controls -Name "ReportLanguage" -X 352 -Y 278 -Width 150
    Add-ComboBoxItem -Combo $reportLangCombo -Label "Francais" -Value "fr"
    Add-ComboBoxItem -Combo $reportLangCombo -Label "English" -Value "en"
    $reportLangCombo.DisplayMember = "Label"
    $reportLangCombo.SelectedIndex = if (([string]$ReportLanguage).ToLowerInvariant() -eq "en") { 1 } else { 0 }
    $form.Controls.Add($reportLangCombo)

    $themeLabel = New-Label -Text "" -X 528 -Y 254 -Width 120
    $form.Controls.Add($themeLabel)
    $themeCombo = New-ComboBox -Controls $controls -Name "GuiTheme" -X 528 -Y 278 -Width 130
    Add-ComboBoxItem -Combo $themeCombo -Label "Clair" -Value "Light"
    Add-ComboBoxItem -Combo $themeCombo -Label "Sombre" -Value "Dark"
    $themeCombo.DisplayMember = "Label"
    $themeCombo.SelectedIndex = if ($script:GuiTheme -eq "Dark") { 1 } else { 0 }
    $form.Controls.Add($themeCombo)

    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $browseSource.Add_Click({
        if ($folderDialog.ShowDialog() -eq "OK") {
            $selectedPath = $folderDialog.SelectedPath
            $selectedRoot = $selectedPath
            $romfsChild = Join-Path $selectedPath "romfs"
            if (Test-Path -LiteralPath $romfsChild) {
                $selectedPath = $romfsChild
            }
            $controls.Source.Text = $selectedPath
            $detectedVersion = Get-SourceGameVersion -RomfsRoot $selectedPath
            [void](Set-ComboValue -Combo $controls.GameVersion -Value $detectedVersion)
        }
    })
    $browseSourceExefs.Add_Click({
        if ($folderDialog.ShowDialog() -eq "OK") {
            $selectedPath = $folderDialog.SelectedPath
            $exefsChild = Join-Path $selectedPath "exefs"
            if (Test-Path -LiteralPath (Join-Path $exefsChild "main.npdm")) {
                $selectedPath = $exefsChild
            }
            $controls.SourceExefs.Text = $selectedPath
        }
    })
    $browseOutput.Add_Click({
        if ($folderDialog.ShowDialog() -eq "OK") { $controls.Output.Text = $folderDialog.SelectedPath }
    })
    $controls.GameVersion.Add_SelectedIndexChanged({
        $selectedVersion = Get-ComboValue -Combo $controls.GameVersion
        $controls.Source.Text = Get-ExistingDefaultPathOrEmpty -Path (Get-DefaultSourceRomfsPath -GameVersion $selectedVersion)
        $controls.SourceExefs.Text = ""
        $controls.Output.Text = Get-DefaultOutputRomfsPath -GameVersion $selectedVersion
    })

    $runButton = New-Object System.Windows.Forms.Button
    $runButton.Location = New-Object System.Drawing.Point(974, 116)
    $runButton.Size = New-Object System.Drawing.Size(160, 94)
    $runButton.Tag = "PrimaryButton"
    $form.Controls.Add($runButton)

    $exportPresetButton = New-Object System.Windows.Forms.Button
    $exportPresetButton.Location = New-Object System.Drawing.Point(974, 220)
    $exportPresetButton.Size = New-Object System.Drawing.Size(160, 28)
    $form.Controls.Add($exportPresetButton)

    $importPresetButton = New-Object System.Windows.Forms.Button
    $importPresetButton.Location = New-Object System.Drawing.Point(974, 254)
    $importPresetButton.Size = New-Object System.Drawing.Size(160, 28)
    $form.Controls.Add($importPresetButton)

    function Bring-TopChromeToFront {
        foreach ($control in @(
            $brandPoke,
            $brandFeur,
            $heroSub,
            $sourceLabel,
            $sourceBox,
            $browseSource,
            $gameVersionLabel,
            $gameVersionCombo,
            $outputLabel,
            $outputBox,
            $browseOutput,
            $sourceExefsLabel,
            $sourceExefsBox,
            $browseSourceExefs,
            $seedLabel,
            $seedBox,
            $uiLangLabel,
            $uiLangCombo,
            $reportLangLabel,
            $reportLangCombo,
            $themeLabel,
            $themeCombo,
            $runButton,
            $exportPresetButton,
            $importPresetButton
        )) {
            if ($control) {
                $control.BringToFront()
            }
        }
    }

    $tabs = New-Object System.Windows.Forms.TabControl
    $tabs.Location = New-Object System.Drawing.Point(18, 318)
    $tabs.Size = New-Object System.Drawing.Size(1130, 520)
    $tabs.DrawMode = [System.Windows.Forms.TabDrawMode]::OwnerDrawFixed
    $tabs.SizeMode = [System.Windows.Forms.TabSizeMode]::Fixed
    $tabs.ItemSize = New-Object System.Drawing.Size(136, 30)
    $tabs.Add_DrawItem({
        param($sender, $eventArgs)
        $palette = Get-GuiThemePalette -Theme $script:GuiTheme
        $isSelected = ($eventArgs.Index -eq $sender.SelectedIndex)
        $backColor = if ($isSelected) { $palette.SelectedTab } else { $palette.TabHeader }
        $textColor = if ($isSelected) { $palette.Accent } else { $palette.Text }
        $backBrush = New-Object System.Drawing.SolidBrush($backColor)
        $borderPen = New-Object System.Drawing.Pen($palette.Border)
        $accentPen = New-Object System.Drawing.Pen($palette.Accent, 2)
        try {
            $eventArgs.Graphics.FillRectangle($backBrush, $eventArgs.Bounds)
            $eventArgs.Graphics.DrawRectangle($borderPen, $eventArgs.Bounds.X, $eventArgs.Bounds.Y, ($eventArgs.Bounds.Width - 1), ($eventArgs.Bounds.Height - 1))
            if ($isSelected) {
                $eventArgs.Graphics.DrawLine($accentPen, $eventArgs.Bounds.Left + 8, $eventArgs.Bounds.Bottom - 3, $eventArgs.Bounds.Right - 8, $eventArgs.Bounds.Bottom - 3)
            }
            $flags = [System.Windows.Forms.TextFormatFlags]::HorizontalCenter -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter -bor [System.Windows.Forms.TextFormatFlags]::EndEllipsis
            [System.Windows.Forms.TextRenderer]::DrawText($eventArgs.Graphics, $sender.TabPages[$eventArgs.Index].Text, $sender.Font, $eventArgs.Bounds, $textColor, $flags)
        } finally {
            $backBrush.Dispose()
            $borderPen.Dispose()
            $accentPen.Dispose()
        }
    })
    $form.Controls.Add($tabs)

    $generalTab = New-Object System.Windows.Forms.TabPage
    $tabs.TabPages.Add($generalTab)

    $trainerTab = New-Object System.Windows.Forms.TabPage
    $tabs.TabPages.Add($trainerTab)

    $pokemonTab = New-Object System.Windows.Forms.TabPage
    $tabs.TabPages.Add($pokemonTab)

    $evoTab = New-Object System.Windows.Forms.TabPage
    $tabs.TabPages.Add($evoTab)

    $giftTab = New-Object System.Windows.Forms.TabPage
    $tabs.TabPages.Add($giftTab)

    $encounterTab = New-Object System.Windows.Forms.TabPage
    $tabs.TabPages.Add($encounterTab)

    $helpTab = New-Object System.Windows.Forms.TabPage
    $tabs.TabPages.Add($helpTab)

    $resetTab = New-Object System.Windows.Forms.TabPage
    $tabs.TabPages.Add($resetTab)

    $generalInfoLabels = @()
    for ($i = 0; $i -lt 7; $i++) {
        $generalInfoLabel = New-Label -Text "" -X 18 -Y (18 + (25 * $i)) -Width 1060
        $generalInfoLabel.ForeColor = (Get-GuiThemePalette -Theme $script:GuiTheme).MutedText
        $generalInfoLabels += $generalInfoLabel
        $generalTab.Controls.Add($generalInfoLabel)
    }

    function Add-HiddenRemovedBuildOption {
        param(
            [System.Windows.Forms.Control]$Parent,
            [System.Collections.Hashtable]$Controls,
            [string]$Name
        )

        $hidden = New-CheckBox -Controls $Controls -Name $Name -Text "" -X 0 -Y 0 -Width 1 -Checked $false
        $hidden.Visible = $false
        $hidden.Enabled = $false
        $Parent.Controls.Add($hidden)
    }

    function Disable-RemovedBuildOptions {
        param([System.Collections.Hashtable]$Controls)

        foreach ($name in @(
            "EarlyBike",
            "DynamicExpLevelCap",
            "StrictBossMaxLevelCap",
            "MainStorySoftLevelCap",
            "StoryMajorBattleOrderLevelCap"
        )) {
            if ($Controls.ContainsKey($name)) {
                $Controls[$name].Checked = $false
                $Controls[$name].Visible = $false
                $Controls[$name].Enabled = $false
            }
        }
    }

    foreach ($removedOptionName in @(
        "EarlyBike",
        "DynamicExpLevelCap",
        "StrictBossMaxLevelCap",
        "MainStorySoftLevelCap",
        "StoryMajorBattleOrderLevelCap"
    )) {
        Add-HiddenRemovedBuildOption -Parent $generalTab -Controls $controls -Name $removedOptionName
    }

    $generalTab.Controls.Add((New-CheckBox -Controls $controls -Name "DisableExpShare" -Text "" -X 18 -Y 202 -Width 520 -Checked $false))
    $generalTab.Controls.Add((New-CheckBox -Controls $controls -Name "GymLeagueStoryLevelCap" -Text "" -X 18 -Y 232 -Width 860 -Checked $false))
    $generalTab.Controls.Add((New-CheckBox -Controls $controls -Name "RuntimePcControls" -Text "" -X 18 -Y 262 -Width 520 -Checked $RuntimePcControls))
    $generalTab.Controls.Add((New-CheckBox -Controls $controls -Name "AutoInstallToEden" -Text "" -X 18 -Y 292 -Width 390 -Checked ([bool]$AutoInstallToEden)))
    $edenModNameLabel = New-Label -Text "" -X 430 -Y 294 -Width 150
    $generalTab.Controls.Add($edenModNameLabel)
    $edenModNameBox = New-TextBox -Controls $controls -Name "EdenModName" -X 590 -Y 290 -Width 220 -Text $EdenModName
    $generalTab.Controls.Add($edenModNameBox)
    $generalTab.Controls.Add((New-CheckBox -Controls $controls -Name "InstallToEden" -Text "" -X 18 -Y 324 -Width 300 -Checked $InstallToEden))
    $generalTab.Controls.Add((New-CheckBox -Controls $controls -Name "InstallToRyujinx" -Text "" -X 330 -Y 324 -Width 300 -Checked $InstallToRyujinx))
    $generalTab.Controls.Add((New-CheckBox -Controls $controls -Name "InstallToYuzu" -Text "" -X 642 -Y 324 -Width 300 -Checked $InstallToYuzu))
    $generalTab.Controls.Add((New-CheckBox -Controls $controls -Name "InstallToSudachi" -Text "" -X 18 -Y 354 -Width 300 -Checked $InstallToSudachi))
    $generalTab.Controls.Add((New-CheckBox -Controls $controls -Name "InstallToCitron" -Text "" -X 330 -Y 354 -Width 300 -Checked $InstallToCitron))
    $generalTab.Controls.Add((New-CheckBox -Controls $controls -Name "InstallToSuyu" -Text "" -X 642 -Y 354 -Width 300 -Checked $InstallToSuyu))
    $generalTab.Controls.Add((New-CheckBox -Controls $controls -Name "InstallToCitronNeo" -Text "" -X 18 -Y 384 -Width 300 -Checked $InstallToCitronNeo))
    $generalTab.Controls.Add((New-CheckBox -Controls $controls -Name "RaceMode" -Text "Race mode (seed/logs separes)" -X 330 -Y 384 -Width 300 -Checked ([bool]$RaceMode)))
    $generalTab.Controls.Add((New-CheckBox -Controls $controls -Name "ExportEncounterZoneReport" -Text "JSON zones rencontres" -X 642 -Y 384 -Width 300 -Checked ([bool]$ExportEncounterZoneReport)))
    $difficultyProfileLabel = New-Label -Text "" -X 330 -Y 414 -Width 170
    $generalTab.Controls.Add($difficultyProfileLabel)
    $difficultyProfileCombo = New-ComboBox -Controls $controls -Name "DifficultyProfile" -X 500 -Y 410 -Width 220
    foreach ($profileItem in Get-DifficultyProfileComboItems -Language $script:UiLanguage) {
        Add-ComboBoxItem -Combo $difficultyProfileCombo -Label $profileItem.Label -Value $profileItem.Value
    }
    $difficultyProfileCombo.DisplayMember = "Label"
    [void](Set-ComboValue -Combo $difficultyProfileCombo -Value "Custom")
    $generalTab.Controls.Add($difficultyProfileCombo)
    $applyDifficultyProfileButton = New-Object System.Windows.Forms.Button
    $applyDifficultyProfileButton.Location = New-Object System.Drawing.Point(712, 408)
    $applyDifficultyProfileButton.Size = New-Object System.Drawing.Size(126, 32)
    $generalTab.Controls.Add($applyDifficultyProfileButton)
    $validateBuildButton = New-Object System.Windows.Forms.Button
    $validateBuildButton.Location = New-Object System.Drawing.Point(848, 408)
    $validateBuildButton.Size = New-Object System.Drawing.Size(126, 32)
    $generalTab.Controls.Add($validateBuildButton)
    $buildSummaryButton = New-Object System.Windows.Forms.Button
    $buildSummaryButton.Location = New-Object System.Drawing.Point(984, 408)
    $buildSummaryButton.Size = New-Object System.Drawing.Size(126, 32)
    $generalTab.Controls.Add($buildSummaryButton)
    Disable-RemovedBuildOptions -Controls $controls

    $helpBox = New-Object System.Windows.Forms.TextBox
    $helpBox.Multiline = $true
    $helpBox.ReadOnly = $true
    $helpBox.ScrollBars = "Vertical"
    $helpBox.Location = New-Object System.Drawing.Point(18, 18)
    $helpBox.Size = New-Object System.Drawing.Size(1092, 448)
    $helpBox.BackColor = [System.Drawing.SystemColors]::Window
    $helpTab.Controls.Add($helpBox)

    $resetInfoLabel = New-Label -Text "" -X 18 -Y 18 -Width 860
    $resetTab.Controls.Add($resetInfoLabel)
    $resetTab.Controls.Add((New-CheckBox -Controls $controls -Name "ResetInstallToEden" -Text "Eden" -X 18 -Y 56 -Width 220 -Checked $InstallToEden))
    $resetTab.Controls.Add((New-CheckBox -Controls $controls -Name "ResetInstallToRyujinx" -Text "Ryujinx" -X 250 -Y 56 -Width 220 -Checked $InstallToRyujinx))
    $resetTab.Controls.Add((New-CheckBox -Controls $controls -Name "ResetInstallToYuzu" -Text "Yuzu" -X 482 -Y 56 -Width 220 -Checked $InstallToYuzu))
    $resetTab.Controls.Add((New-CheckBox -Controls $controls -Name "ResetInstallToSudachi" -Text "Sudachi" -X 18 -Y 84 -Width 220 -Checked $InstallToSudachi))
    $resetTab.Controls.Add((New-CheckBox -Controls $controls -Name "ResetInstallToCitron" -Text "Citron" -X 250 -Y 84 -Width 220 -Checked $InstallToCitron))
    $resetTab.Controls.Add((New-CheckBox -Controls $controls -Name "ResetInstallToSuyu" -Text "Suyu" -X 482 -Y 84 -Width 220 -Checked $InstallToSuyu))
    $resetTab.Controls.Add((New-CheckBox -Controls $controls -Name "ResetInstallToCitronNeo" -Text "Citron Neo" -X 18 -Y 112 -Width 220 -Checked $InstallToCitronNeo))
    $resetButton = New-Object System.Windows.Forms.Button
    $resetButton.Location = New-Object System.Drawing.Point(18, 148)
    $resetButton.Size = New-Object System.Drawing.Size(240, 34)
    $resetTab.Controls.Add($resetButton)
    $resetStatusBox = New-Object System.Windows.Forms.TextBox
    $resetStatusBox.Multiline = $true
    $resetStatusBox.ReadOnly = $true
    $resetStatusBox.ScrollBars = "Vertical"
    $resetStatusBox.Location = New-Object System.Drawing.Point(18, 198)
    $resetStatusBox.Size = New-Object System.Drawing.Size(892, 248)
    $resetStatusBox.BackColor = [System.Drawing.SystemColors]::Window
    $resetTab.Controls.Add($resetStatusBox)

    $trainerSpeciesLabel = New-Label -Text "" -X 18 -Y 18 -Width 220
    $trainerTab.Controls.Add($trainerSpeciesLabel)
    $trainerSpeciesCombo = New-ComboBox -Controls $controls -Name "TrainerSpeciesMode" -X 18 -Y 42
    Add-ComboBoxItem -Combo $trainerSpeciesCombo -Label "Aleatoire complet" -Value "Random"
    Add-ComboBoxItem -Combo $trainerSpeciesCombo -Label "Aleatoire BST proche" -Value "SimilarBST"
    Add-ComboBoxItem -Combo $trainerSpeciesCombo -Label "Ne pas changer" -Value "Unchanged"
    $trainerSpeciesCombo.DisplayMember = "Label"
    $trainerSpeciesCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($trainerSpeciesCombo)

    $trainerMovesLabel = New-Label -Text "" -X 270 -Y 18 -Width 180
    $trainerTab.Controls.Add($trainerMovesLabel)
    $trainerMoveCombo = New-ComboBox -Controls $controls -Name "TrainerMoveMode" -X 270 -Y 42
    Add-ComboBoxItem -Combo $trainerMoveCombo -Label "4 attaques aleatoires" -Value "Random4"
    Add-ComboBoxItem -Combo $trainerMoveCombo -Label "Attaques naturelles au niveau" -Value "LastLevelUp4"
    Add-ComboBoxItem -Combo $trainerMoveCombo -Label "Strategique Smogon" -Value "SmogonStrategic"
    Add-ComboBoxItem -Combo $trainerMoveCombo -Label "Smogon + anciennes gens" -Value "SmogonLegacy"
    Add-ComboBoxItem -Combo $trainerMoveCombo -Label "Ne pas changer" -Value "Unchanged"
    $trainerMoveCombo.DisplayMember = "Label"
    $trainerMoveCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($trainerMoveCombo)

    $trainerSmogonMoveFallbackLabel = New-Label -Text "" -X 270 -Y 68 -Width 150
    $trainerTab.Controls.Add($trainerSmogonMoveFallbackLabel)
    $trainerSmogonMoveFallbackCombo = New-ComboBox -Controls $controls -Name "TrainerSmogonMoveFallbackMode" -X 430 -Y 66 -Width 190
    Add-ComboBoxItem -Combo $trainerSmogonMoveFallbackCombo -Label "Backup niveau" -Value "LastLevelUp4"
    Add-ComboBoxItem -Combo $trainerSmogonMoveFallbackCombo -Label "Backup random" -Value "Random4"
    Add-ComboBoxItem -Combo $trainerSmogonMoveFallbackCombo -Label "Backup vanilla" -Value "Unchanged"
    $trainerSmogonMoveFallbackCombo.DisplayMember = "Label"
    $trainerSmogonMoveFallbackCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($trainerSmogonMoveFallbackCombo)

    $trainerItemsLabel = New-Label -Text "" -X 522 -Y 18 -Width 220
    $trainerTab.Controls.Add($trainerItemsLabel)
    $trainerItemCombo = New-ComboBox -Controls $controls -Name "TrainerItemMode" -X 522 -Y 42
    Add-ComboBoxItem -Combo $trainerItemCombo -Label "Random si objet deja present" -Value "RandomWhenPresent"
    Add-ComboBoxItem -Combo $trainerItemCombo -Label "Objet random sur tous" -Value "ForceAll"
    Add-ComboBoxItem -Combo $trainerItemCombo -Label "Strategique Smogon" -Value "SmogonStrategic"
    Add-ComboBoxItem -Combo $trainerItemCombo -Label "Smogon + anciennes gens" -Value "SmogonLegacy"
    Add-ComboBoxItem -Combo $trainerItemCombo -Label "Supprimer tous les objets" -Value "RemoveAll"
    Add-ComboBoxItem -Combo $trainerItemCombo -Label "Ne pas changer" -Value "Unchanged"
    $trainerItemCombo.DisplayMember = "Label"
    $trainerItemCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($trainerItemCombo)

    $trainerItemPoolLabel = New-Label -Text "" -X 774 -Y 18 -Width 180
    $trainerTab.Controls.Add($trainerItemPoolLabel)
    $trainerItemPoolCombo = New-ComboBox -Controls $controls -Name "TrainerItemPoolMode" -X 774 -Y 42 -Width 220
    Add-ComboBoxItem -Combo $trainerItemPoolCombo -Label "Pool combat (objets utiles)" -Value "Battle"
    Add-ComboBoxItem -Combo $trainerItemPoolCombo -Label "Pool large safe (chaotique)" -Value "FullRandom"
    $trainerItemPoolCombo.DisplayMember = "Label"
    $trainerItemPoolCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($trainerItemPoolCombo)

    $trainerAbilityLabel = New-Label -Text "" -X 18 -Y 92 -Width 230
    $trainerTab.Controls.Add($trainerAbilityLabel)
    $trainerAbilityCombo = New-ComboBox -Controls $controls -Name "TrainerAbilityMode" -X 18 -Y 116
    Add-ComboBoxItem -Combo $trainerAbilityCombo -Label "Randomiser le slot de talent" -Value "RandomSlot"
    Add-ComboBoxItem -Combo $trainerAbilityCombo -Label "Strategique Smogon" -Value "SmogonStrategic"
    Add-ComboBoxItem -Combo $trainerAbilityCombo -Label "Smogon + anciennes gens" -Value "SmogonLegacy"
    Add-ComboBoxItem -Combo $trainerAbilityCombo -Label "Ne pas changer" -Value "Unchanged"
    $trainerAbilityCombo.DisplayMember = "Label"
    $trainerAbilityCombo.SelectedIndex = 1
    $trainerTab.Controls.Add($trainerAbilityCombo)

    $trainerIvLabel = New-Label -Text "" -X 270 -Y 92 -Width 120
    $trainerTab.Controls.Add($trainerIvLabel)
    $trainerIvCombo = New-ComboBox -Controls $controls -Name "TrainerIVMode" -X 270 -Y 116
    Add-ComboBoxItem -Combo $trainerIvCombo -Label "31 partout" -Value "Max31"
    Add-ComboBoxItem -Combo $trainerIvCombo -Label "Aleatoire" -Value "Random"
    Add-ComboBoxItem -Combo $trainerIvCombo -Label "Ne pas changer" -Value "Unchanged"
    $trainerIvCombo.DisplayMember = "Label"
    $trainerIvCombo.SelectedIndex = 2
    $trainerTab.Controls.Add($trainerIvCombo)

    $trainerEvLabel = New-Label -Text "" -X 522 -Y 92 -Width 120
    $trainerTab.Controls.Add($trainerEvLabel)
    $trainerEvCombo = New-ComboBox -Controls $controls -Name "TrainerEVMode" -X 522 -Y 116
    Add-ComboBoxItem -Combo $trainerEvCombo -Label "EV strategiques Smogon" -Value "SmogonStrategic"
    Add-ComboBoxItem -Combo $trainerEvCombo -Label "EV Smogon + anciennes gens" -Value "SmogonLegacy"
    Add-ComboBoxItem -Combo $trainerEvCombo -Label "EV legaux aleatoires" -Value "RandomLegal"
    Add-ComboBoxItem -Combo $trainerEvCombo -Label "Mettre EV a zero" -Value "Zero"
    Add-ComboBoxItem -Combo $trainerEvCombo -Label "Ne pas changer" -Value "Unchanged"
    $trainerEvCombo.DisplayMember = "Label"
    $trainerEvCombo.SelectedIndex = 3
    $trainerTab.Controls.Add($trainerEvCombo)

    $trainerAddedSlotSpeciesLabel = New-Label -Text "" -X 774 -Y 92 -Width 220
    $trainerTab.Controls.Add($trainerAddedSlotSpeciesLabel)
    $trainerAddedSlotSpeciesCombo = New-ComboBox -Controls $controls -Name "TrainerAddedSlotSpeciesMode" -X 774 -Y 116 -Width 220
    Add-ComboBoxItem -Combo $trainerAddedSlotSpeciesCombo -Label "Slots ajoutes: random complet" -Value "Random"
    Add-ComboBoxItem -Combo $trainerAddedSlotSpeciesCombo -Label "Slots ajoutes: BST proche" -Value "SimilarBST"
    Add-ComboBoxItem -Combo $trainerAddedSlotSpeciesCombo -Label "Slots ajoutes: meme type" -Value "SameTypeRandom"
    Add-ComboBoxItem -Combo $trainerAddedSlotSpeciesCombo -Label "Slots ajoutes: meme type + BST" -Value "SameTypeBST"
    $trainerAddedSlotSpeciesCombo.DisplayMember = "Label"
    $trainerAddedSlotSpeciesCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($trainerAddedSlotSpeciesCombo)

    $trainerDuplicateModeLabel = New-Label -Text "" -X 774 -Y 166 -Width 220
    $trainerTab.Controls.Add($trainerDuplicateModeLabel)
    $trainerDuplicateModeCombo = New-ComboBox -Controls $controls -Name "TrainerDuplicateMode" -X 774 -Y 190 -Width 220
    Add-ComboBoxItem -Combo $trainerDuplicateModeCombo -Label "Bloquer les doublons" -Value "NoDuplicates"
    Add-ComboBoxItem -Combo $trainerDuplicateModeCombo -Label "Random normal" -Value "Normal"
    $trainerDuplicateModeCombo.DisplayMember = "Label"
    $trainerDuplicateModeCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($trainerDuplicateModeCombo)

    $bossTeamsScopeLabel = New-Label -Text "" -X 774 -Y 218 -Width 220
    $trainerTab.Controls.Add($bossTeamsScopeLabel)
    $bossTeamsScopeCombo = New-ComboBox -Controls $controls -Name "BossTeamsToSixScope" -X 774 -Y 242 -Width 220
    Add-ComboBoxItem -Combo $bossTeamsScopeCombo -Label "Boss importants" -Value "MajorBosses"
    Add-ComboBoxItem -Combo $bossTeamsScopeCombo -Label "Arenes + ligue uniquement" -Value "GymLeague"
    $bossTeamsScopeCombo.DisplayMember = "Label"
    $bossTeamsScopeCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($bossTeamsScopeCombo)

    $trainerLevelLabel = New-Label -Text "" -X 18 -Y 166 -Width 150
    $trainerTab.Controls.Add($trainerLevelLabel)
    $trainerLevelBox = New-TextBox -Controls $controls -Name "TrainerLevelMultiplier" -X 18 -Y 190 -Width 100 -Text "1.0"
    $trainerTab.Controls.Add($trainerLevelBox)

    $trainerTeamMinLabel = New-Label -Text "" -X 214 -Y 166 -Width 110
    $trainerTab.Controls.Add($trainerTeamMinLabel)
    $trainerTeamMinBox = New-TextBox -Controls $controls -Name "TrainerTeamMin" -X 214 -Y 190 -Width 60 -Text "-1"
    $trainerTab.Controls.Add($trainerTeamMinBox)

    $trainerTeamMaxLabel = New-Label -Text "" -X 324 -Y 166 -Width 110
    $trainerTab.Controls.Add($trainerTeamMaxLabel)
    $trainerTeamMaxBox = New-TextBox -Controls $controls -Name "TrainerTeamMax" -X 324 -Y 190 -Width 60 -Text "-1"
    $trainerTab.Controls.Add($trainerTeamMaxBox)

    $trainerTab.Controls.Add((New-CheckBox -Controls $controls -Name "ForceAllTeamsToSix" -Text "" -X 420 -Y 190 -Width 300 -Checked $false))
    $trainerTab.Controls.Add((New-CheckBox -Controls $controls -Name "ForceBossTeamsToSix" -Text "" -X 420 -Y 220 -Width 340 -Checked $false))
    $trainerNatureModeLabel = New-Label -Text "" -X 18 -Y 204 -Width 220
    $trainerTab.Controls.Add($trainerNatureModeLabel)
    $trainerNatureModeCombo = New-ComboBox -Controls $controls -Name "TrainerNatureMode" -X 18 -Y 228 -Width 220
    Add-ComboBoxItem -Combo $trainerNatureModeCombo -Label "Garder vanilla" -Value "Unchanged"
    Add-ComboBoxItem -Combo $trainerNatureModeCombo -Label "Nature aleatoire" -Value "Random"
    Add-ComboBoxItem -Combo $trainerNatureModeCombo -Label "Nature strategique Smogon" -Value "SmogonStrategic"
    Add-ComboBoxItem -Combo $trainerNatureModeCombo -Label "Nature Smogon + anciennes gens" -Value "SmogonLegacy"
    $trainerNatureModeCombo.DisplayMember = "Label"
    $trainerNatureModeCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($trainerNatureModeCombo)
    $legacyNatureCheck = New-CheckBox -Controls $controls -Name "RandomizeTrainerNatures" -Text "" -X 18 -Y 228 -Width 280 -Checked $false
    $legacyNatureCheck.Visible = $false
    $trainerTab.Controls.Add((New-CheckBox -Controls $controls -Name "AllowLegendaryTrainers" -Text "" -X 18 -Y 258 -Width 420 -Checked $false))
    $trainerTab.Controls.Add((New-CheckBox -Controls $controls -Name "MaxTrainerAI" -Text "" -X 522 -Y 258 -Width 260 -Checked $false))
    $trainerTab.Controls.Add((New-CheckBox -Controls $controls -Name "TrainerTypeThemed" -Text "" -X 270 -Y 286 -Width 230 -Checked $false))
    $trainerShinyLabel = New-Label -Text "" -X 18 -Y 292 -Width 220
    $trainerTab.Controls.Add($trainerShinyLabel)
    $trainerShinyBox = New-TextBox -Controls $controls -Name "TrainerShinyChancePercent" -X 18 -Y 316 -Width 80 -Text "0"
    $trainerTab.Controls.Add($trainerShinyBox)
    $trainerTab.Controls.Add((New-CheckBox -Controls $controls -Name "ForceTrainerFullyEvolved" -Text "" -X 154 -Y 316 -Width 330 -Checked $false))
    $trainerFullyEvolvedLevelLabel = New-Label -Text "" -X 510 -Y 292 -Width 190
    $trainerTab.Controls.Add($trainerFullyEvolvedLevelLabel)
    $trainerFullyEvolvedLevelBox = New-TextBox -Controls $controls -Name "TrainerFullyEvolvedLevel" -X 510 -Y 316 -Width 70 -Text "40"
    $trainerTab.Controls.Add($trainerFullyEvolvedLevelBox)
    $trainerDynamaxLevelLabel = New-Label -Text "" -X 18 -Y 360 -Width 220
    $trainerTab.Controls.Add($trainerDynamaxLevelLabel)
    $trainerDynamaxLevelCombo = New-ComboBox -Controls $controls -Name "TrainerDynamaxLevelMode" -X 18 -Y 384 -Width 300
    Add-ComboBoxItem -Combo $trainerDynamaxLevelCombo -Label "Ne pas changer" -Value "Unchanged"
    Add-ComboBoxItem -Combo $trainerDynamaxLevelCombo -Label "Niveau Dynamax 10" -Value "Max10"
    Add-ComboBoxItem -Combo $trainerDynamaxLevelCombo -Label "Niveau Dynamax aleatoire 0-10" -Value "Random0To10"
    $trainerDynamaxLevelCombo.DisplayMember = "Label"
    $trainerDynamaxLevelCombo.SelectedIndex = 0
    $trainerTab.Controls.Add($trainerDynamaxLevelCombo)
    $trainerTab.Controls.Add((New-CheckBox -Controls $controls -Name "ForceTrainerCanDynamax" -Text "" -X 340 -Y 386 -Width 430 -Checked $false))
    $bossTargetsBox = New-Object System.Windows.Forms.TextBox
    $bossTargetsBox.Multiline = $true
    $bossTargetsBox.ReadOnly = $true
    $bossTargetsBox.ScrollBars = "Vertical"
    $bossTargetsBox.WordWrap = $false
    $bossTargetsBox.Location = New-Object System.Drawing.Point(790, 292)
    $bossTargetsBox.Size = New-Object System.Drawing.Size(320, 162)
    $bossTargetsBox.BackColor = [System.Drawing.SystemColors]::Window
    $trainerTab.Controls.Add($bossTargetsBox)

    $typeModeLabel = New-Label -Text "" -X 18 -Y 18 -Width 120
    $pokemonTab.Controls.Add($typeModeLabel)
    $typeModeCombo = New-ComboBox -Controls $controls -Name "TypeMode" -X 18 -Y 42
    Add-ComboBoxItem -Combo $typeModeCombo -Label "Randomiser les types" -Value "Random"
    Add-ComboBoxItem -Combo $typeModeCombo -Label "Ne pas changer" -Value "Unchanged"
    $typeModeCombo.DisplayMember = "Label"
    $typeModeCombo.SelectedIndex = 1
    $pokemonTab.Controls.Add($typeModeCombo)

    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "TypesMonotypeOnly" -Text "" -X 270 -Y 44 -Width 320 -Checked $false))

    $abilityModeLabel = New-Label -Text "" -X 18 -Y 92 -Width 230
    $pokemonTab.Controls.Add($abilityModeLabel)
    $abilityModeCombo = New-ComboBox -Controls $controls -Name "AbilityMode" -X 18 -Y 116
    Add-ComboBoxItem -Combo $abilityModeCombo -Label "Randomiser les talents" -Value "Random"
    Add-ComboBoxItem -Combo $abilityModeCombo -Label "Ne pas changer" -Value "Unchanged"
    $abilityModeCombo.DisplayMember = "Label"
    $abilityModeCombo.SelectedIndex = 1
    $pokemonTab.Controls.Add($abilityModeCombo)
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "AllowWonderGuard" -Text "" -X 270 -Y 118 -Width 280 -Checked $false))

    $statModeLabel = New-Label -Text "" -X 18 -Y 166 -Width 120
    $pokemonTab.Controls.Add($statModeLabel)
    $statModeCombo = New-ComboBox -Controls $controls -Name "StatMode" -X 18 -Y 190
    Add-ComboBoxItem -Combo $statModeCombo -Label "Melanger les 6 stats" -Value "Shuffle"
    Add-ComboBoxItem -Combo $statModeCombo -Label "Redistribuer le BST" -Value "Redistribute"
    Add-ComboBoxItem -Combo $statModeCombo -Label "Ne pas changer" -Value "Unchanged"
    $statModeCombo.DisplayMember = "Label"
    $statModeCombo.SelectedIndex = 2
    $pokemonTab.Controls.Add($statModeCombo)

    $expYieldMultiplierLabel = New-Label -Text "" -X 510 -Y 166 -Width 190
    $pokemonTab.Controls.Add($expYieldMultiplierLabel)
    $expYieldMultiplierBox = New-TextBox -Controls $controls -Name "ExpYieldMultiplier" -X 510 -Y 190 -Width 80 -Text "1.0"
    $pokemonTab.Controls.Add($expYieldMultiplierBox)
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "ForceOneExpYield" -Text "" -X 610 -Y 190 -Width 320 -Checked $false))

    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "RandomizeMoveTypes" -Text "" -X 270 -Y 190 -Width 260 -Checked $false))
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "RandomizeMovePower" -Text "" -X 18 -Y 246 -Width 220 -Checked $false))
    $movePowerMinLabel = New-Label -Text "" -X 270 -Y 224 -Width 110
    $pokemonTab.Controls.Add($movePowerMinLabel)
    $movePowerMinBox = New-TextBox -Controls $controls -Name "MovePowerMin" -X 270 -Y 248 -Width 70 -Text "20"
    $pokemonTab.Controls.Add($movePowerMinBox)
    $movePowerMaxLabel = New-Label -Text "" -X 360 -Y 224 -Width 110
    $pokemonTab.Controls.Add($movePowerMaxLabel)
    $movePowerMaxBox = New-TextBox -Controls $controls -Name "MovePowerMax" -X 360 -Y 248 -Width 70 -Text "150"
    $pokemonTab.Controls.Add($movePowerMaxBox)
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "RandomizeMovePP" -Text "" -X 18 -Y 312 -Width 220 -Checked $false))
    $movePPMinLabel = New-Label -Text "" -X 270 -Y 290 -Width 110
    $pokemonTab.Controls.Add($movePPMinLabel)
    $movePPMinBox = New-TextBox -Controls $controls -Name "MovePPMin" -X 270 -Y 314 -Width 70 -Text "5"
    $pokemonTab.Controls.Add($movePPMinBox)
    $movePPMaxLabel = New-Label -Text "" -X 360 -Y 290 -Width 110
    $pokemonTab.Controls.Add($movePPMaxLabel)
    $movePPMaxBox = New-TextBox -Controls $controls -Name "MovePPMax" -X 360 -Y 314 -Width 70 -Text "40"
    $pokemonTab.Controls.Add($movePPMaxBox)
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "RandomizeMoveAccuracy" -Text "" -X 18 -Y 378 -Width 220 -Checked $false))
    $moveAccuracyMinLabel = New-Label -Text "" -X 270 -Y 356 -Width 120
    $pokemonTab.Controls.Add($moveAccuracyMinLabel)
    $moveAccuracyMinBox = New-TextBox -Controls $controls -Name "MoveAccuracyMin" -X 270 -Y 380 -Width 70 -Text "70"
    $pokemonTab.Controls.Add($moveAccuracyMinBox)
    $moveAccuracyMaxLabel = New-Label -Text "" -X 360 -Y 356 -Width 120
    $pokemonTab.Controls.Add($moveAccuracyMaxLabel)
    $moveAccuracyMaxBox = New-TextBox -Controls $controls -Name "MoveAccuracyMax" -X 360 -Y 380 -Width 70 -Text "100"
    $pokemonTab.Controls.Add($moveAccuracyMaxBox)
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "RandomizeMoveCategory" -Text "" -X 510 -Y 248 -Width 360 -Checked $false))
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "RandomizePickupItems" -Text "" -X 510 -Y 300 -Width 360 -Checked ([bool]$RandomizePickupItems)))
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "RandomizeShopItems" -Text "" -X 510 -Y 330 -Width 360 -Checked ([bool]$RandomizeShopItems)))
    $pokemonTab.Controls.Add((New-CheckBox -Controls $controls -Name "RandomizeTechnicalRecords" -Text "" -X 510 -Y 360 -Width 360 -Checked ([bool]$RandomizeTechnicalRecords)))

    $evoModeLabel = New-Label -Text "" -X 18 -Y 18 -Width 140
    $evoTab.Controls.Add($evoModeLabel)
    $evoModeCombo = New-ComboBox -Controls $controls -Name "EvolutionMode" -X 18 -Y 42
    Add-ComboBoxItem -Combo $evoModeCombo -Label "Aleatoire complet" -Value "Random"
    Add-ComboBoxItem -Combo $evoModeCombo -Label "Aleatoire BST proche" -Value "SimilarBST"
    Add-ComboBoxItem -Combo $evoModeCombo -Label "Ne pas changer" -Value "Unchanged"
    $evoModeCombo.DisplayMember = "Label"
    $evoModeCombo.SelectedIndex = 2
    $evoTab.Controls.Add($evoModeCombo)
    $evoTab.Controls.Add((New-CheckBox -Controls $controls -Name "AllowLegendaryEvolutions" -Text "" -X 270 -Y 44 -Width 300 -Checked $false))
    $evoTab.Controls.Add((New-CheckBox -Controls $controls -Name "NormalizeFriendshipEvolutions" -Text "" -X 18 -Y 92 -Width 340 -Checked $false))
    $friendshipLevelLabel = New-Label -Text "" -X 370 -Y 92 -Width 120
    $evoTab.Controls.Add($friendshipLevelLabel)
    $friendshipLevelBox = New-TextBox -Controls $controls -Name "FriendshipEvolutionLevel" -X 370 -Y 116 -Width 70 -Text "30"
    $evoTab.Controls.Add($friendshipLevelBox)
    $evoTab.Controls.Add((New-CheckBox -Controls $controls -Name "NormalizeTradeEvolutions" -Text "" -X 18 -Y 154 -Width 340 -Checked $false))
    $tradeLevelLabelEvo = New-Label -Text "" -X 370 -Y 154 -Width 120
    $evoTab.Controls.Add($tradeLevelLabelEvo)
    $tradeLevelBox = New-TextBox -Controls $controls -Name "TradeEvolutionLevel" -X 370 -Y 178 -Width 70 -Text "37"
    $evoTab.Controls.Add($tradeLevelBox)
    $evoTab.Controls.Add((New-CheckBox -Controls $controls -Name "NormalizeSpecialEvolutions" -Text "" -X 18 -Y 216 -Width 420 -Checked $false))
    $specialLevelLabelEvo = New-Label -Text "" -X 470 -Y 216 -Width 140
    $evoTab.Controls.Add($specialLevelLabelEvo)
    $specialLevelBox = New-TextBox -Controls $controls -Name "SpecialEvolutionLevel" -X 470 -Y 240 -Width 70 -Text "36"
    $evoTab.Controls.Add($specialLevelBox)

    $giftModeLabel = New-Label -Text "" -X 18 -Y 18 -Width 190
    $giftTab.Controls.Add($giftModeLabel)
    $giftModeCombo = New-ComboBox -Controls $controls -Name "GiftMode" -X 18 -Y 42
    Add-ComboBoxItem -Combo $giftModeCombo -Label "Aleatoire complet" -Value "Random"
    Add-ComboBoxItem -Combo $giftModeCombo -Label "Aleatoire BST proche" -Value "SimilarBST"
    Add-ComboBoxItem -Combo $giftModeCombo -Label "Ne pas changer" -Value "Unchanged"
    $giftModeCombo.DisplayMember = "Label"
    $giftModeCombo.SelectedIndex = 2
    $giftTab.Controls.Add($giftModeCombo)

    $starterModeLabel = New-Label -Text "" -X 270 -Y 18 -Width 180
    $giftTab.Controls.Add($starterModeLabel)
    $starterModeCombo = New-ComboBox -Controls $controls -Name "StarterMode" -X 270 -Y 42
    Add-ComboBoxItem -Combo $starterModeCombo -Label "Aleatoire complet" -Value "Random"
    Add-ComboBoxItem -Combo $starterModeCombo -Label "Aleatoire BST proche" -Value "SimilarBST"
    Add-ComboBoxItem -Combo $starterModeCombo -Label "Ne pas changer" -Value "Unchanged"
    $starterModeCombo.DisplayMember = "Label"
    $starterModeCombo.SelectedIndex = 2
    $giftTab.Controls.Add($starterModeCombo)

    $giftTab.Controls.Add((New-CheckBox -Controls $controls -Name "AllowLegendaryGifts" -Text "" -X 522 -Y 44 -Width 340 -Checked $false))

    $manualStarterGroupLabel = New-Label -Text "" -X 18 -Y 90 -Width 1040 -Height 34
    $giftTab.Controls.Add($manualStarterGroupLabel)
    $starter1Label = New-Label -Text "" -X 18 -Y 126 -Width 60
    $giftTab.Controls.Add($starter1Label)
    $starter1Box = New-TextBox -Controls $controls -Name "Starter1" -X 18 -Y 150 -Width 180 -Text ""
    $giftTab.Controls.Add($starter1Box)
    $starter2Label = New-Label -Text "" -X 214 -Y 126 -Width 60
    $giftTab.Controls.Add($starter2Label)
    $starter2Box = New-TextBox -Controls $controls -Name "Starter2" -X 214 -Y 150 -Width 180 -Text ""
    $giftTab.Controls.Add($starter2Box)
    $starter3Label = New-Label -Text "" -X 410 -Y 126 -Width 60
    $giftTab.Controls.Add($starter3Label)
    $starter3Box = New-TextBox -Controls $controls -Name "Starter3" -X 410 -Y 150 -Width 180 -Text ""
    $giftTab.Controls.Add($starter3Box)
    $starterAutoComplete = New-SpeciesAutoCompleteSource
    foreach ($starterBox in @($starter1Box, $starter2Box, $starter3Box)) {
        $starterBox.AutoCompleteMode = "SuggestAppend"
        $starterBox.AutoCompleteSource = "CustomSource"
        $starterBox.AutoCompleteCustomSource = $starterAutoComplete
        $starterBox.Add_Leave({
            param($sender, $eventArgs)
            Complete-SpeciesTextBoxValue -TextBox $sender -Language $script:UiLanguage
        })
        $starterBox.Add_KeyDown({
            param($sender, $eventArgs)
            if ($eventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                Complete-SpeciesTextBoxValue -TextBox $sender -Language $script:UiLanguage
                $eventArgs.SuppressKeyPress = $true
            }
        })
    }
    $giftTab.Controls.Add((New-CheckBox -Controls $controls -Name "PatchStarterRelatedTrainers" -Text "" -X 606 -Y 152 -Width 430 -Checked $true))

    $tradeModeLabel = New-Label -Text "" -X 18 -Y 196 -Width 160
    $giftTab.Controls.Add($tradeModeLabel)
    $tradeModeCombo = New-ComboBox -Controls $controls -Name "TradeMode" -X 18 -Y 220
    Add-ComboBoxItem -Combo $tradeModeCombo -Label "Aleatoire complet" -Value "Random"
    Add-ComboBoxItem -Combo $tradeModeCombo -Label "Aleatoire BST proche" -Value "SimilarBST"
    Add-ComboBoxItem -Combo $tradeModeCombo -Label "Ne pas changer" -Value "Unchanged"
    $tradeModeCombo.DisplayMember = "Label"
    $tradeModeCombo.SelectedIndex = 2
    $giftTab.Controls.Add($tradeModeCombo)
    $giftTab.Controls.Add((New-CheckBox -Controls $controls -Name "AllowLegendaryTrades" -Text "" -X 270 -Y 222 -Width 320 -Checked $false))

    $staticModeLabel = New-Label -Text "" -X 18 -Y 18 -Width 220
    $encounterTab.Controls.Add($staticModeLabel)
    $staticEncounterCombo = New-ComboBox -Controls $controls -Name "StaticEncounterMode" -X 18 -Y 42
    Add-ComboBoxItem -Combo $staticEncounterCombo -Label "Aleatoire complet" -Value "Random"
    Add-ComboBoxItem -Combo $staticEncounterCombo -Label "Aleatoire BST proche" -Value "SimilarBST"
    Add-ComboBoxItem -Combo $staticEncounterCombo -Label "Ne pas changer" -Value "Unchanged"
    $staticEncounterCombo.DisplayMember = "Label"
    $staticEncounterCombo.SelectedIndex = 2
    $encounterTab.Controls.Add($staticEncounterCombo)
    $encounterTab.Controls.Add((New-CheckBox -Controls $controls -Name "AllowLegendaryStaticEncounters" -Text "" -X 270 -Y 44 -Width 340 -Checked $false))
    $staticStableMappingLabel = New-Label -Text "" -X 18 -Y 74 -Width 220
    $encounterTab.Controls.Add($staticStableMappingLabel)
    $staticStableMappingCombo = New-ComboBox -Controls $controls -Name "StaticEncounterStableMapping" -X 270 -Y 70 -Width 170
    Add-ComboBoxItem -Combo $staticStableMappingCombo -Label "Par slot" -Value "Slot"
    Add-ComboBoxItem -Combo $staticStableMappingCombo -Label "Par espece" -Value "Species"
    Add-ComboBoxItem -Combo $staticStableMappingCombo -Label "Vrai random build" -Value "Random"
    $staticStableMappingCombo.DisplayMember = "Label"
    $staticStableMappingCombo.SelectedIndex = 0
    $encounterTab.Controls.Add($staticStableMappingCombo)

    $grassModeLabel = New-Label -Text "" -X 18 -Y 126 -Width 220
    $encounterTab.Controls.Add($grassModeLabel)
    $grassEncounterCombo = New-ComboBox -Controls $controls -Name "GrassEncounterMode" -X 18 -Y 150
    Add-ComboBoxItem -Combo $grassEncounterCombo -Label "Aleatoire complet" -Value "Random"
    Add-ComboBoxItem -Combo $grassEncounterCombo -Label "Aleatoire BST proche" -Value "SimilarBST"
    Add-ComboBoxItem -Combo $grassEncounterCombo -Label "Ne pas changer" -Value "Unchanged"
    $grassEncounterCombo.DisplayMember = "Label"
    $grassEncounterCombo.SelectedIndex = 2
    $encounterTab.Controls.Add($grassEncounterCombo)
    $encounterTab.Controls.Add((New-CheckBox -Controls $controls -Name "AllowLegendaryGrassEncounters" -Text "" -X 270 -Y 152 -Width 340 -Checked $false))
    $grassStableMappingLabel = New-Label -Text "" -X 18 -Y 182 -Width 220
    $encounterTab.Controls.Add($grassStableMappingLabel)
    $grassStableMappingCombo = New-ComboBox -Controls $controls -Name "GrassEncounterStableMapping" -X 270 -Y 178 -Width 170
    Add-ComboBoxItem -Combo $grassStableMappingCombo -Label "Par slot" -Value "Slot"
    Add-ComboBoxItem -Combo $grassStableMappingCombo -Label "Par espece" -Value "Species"
    Add-ComboBoxItem -Combo $grassStableMappingCombo -Label "Vrai random build" -Value "Random"
    $grassStableMappingCombo.DisplayMember = "Label"
    $grassStableMappingCombo.SelectedIndex = 0
    $encounterTab.Controls.Add($grassStableMappingCombo)

    $visibleBehaviorLabel = New-Label -Text "" -X 18 -Y 226 -Width 220
    $encounterTab.Controls.Add($visibleBehaviorLabel)
    $visibleBehaviorCombo = New-ComboBox -Controls $controls -Name "VisibleEncounterBehavior" -X 270 -Y 222 -Width 430
    Add-ComboBoxItem -Combo $visibleBehaviorCombo -Label "Classique: visible = combat" -Value "RomfsMatch"
    Add-ComboBoxItem -Combo $visibleBehaviorCombo -Label "Full random visible + combat cache" -Value "RandomVisualBattleRandom"
    Add-ComboBoxItem -Combo $visibleBehaviorCombo -Label "Full vanilla visible + combat cache" -Value "VanillaVisualBattleRandom"
    $visibleBehaviorCombo.DisplayMember = "Label"
    $visibleBehaviorCombo.SelectedIndex = 2
    $encounterTab.Controls.Add($visibleBehaviorCombo)

    $undergroundModeLabel = New-Label -Text "" -X 18 -Y 286 -Width 180
    $encounterTab.Controls.Add($undergroundModeLabel)
    $undergroundModeCombo = New-ComboBox -Controls $controls -Name "UndergroundMode" -X 18 -Y 310
    Add-ComboBoxItem -Combo $undergroundModeCombo -Label "Aleatoire complet" -Value "Random"
    Add-ComboBoxItem -Combo $undergroundModeCombo -Label "Aleatoire BST proche" -Value "SimilarBST"
    Add-ComboBoxItem -Combo $undergroundModeCombo -Label "Ne pas changer" -Value "Unchanged"
    $undergroundModeCombo.DisplayMember = "Label"
    $undergroundModeCombo.SelectedIndex = 2
    $encounterTab.Controls.Add($undergroundModeCombo)
    $encounterTab.Controls.Add((New-CheckBox -Controls $controls -Name "AllowLegendaryUnderground" -Text "" -X 270 -Y 312 -Width 300 -Checked $false))

    $statusBox = New-Object System.Windows.Forms.TextBox
    $statusBox.Multiline = $true
    $statusBox.ReadOnly = $true
    $statusBox.ScrollBars = "Vertical"
    $detailsBox = New-Object System.Windows.Forms.TextBox
    $detailsBox.Multiline = $true
    $detailsBox.ReadOnly = $true
    $detailsBox.ScrollBars = "Vertical"
    $detailsBox.Location = New-Object System.Drawing.Point(18, 852)
    $detailsBox.Size = New-Object System.Drawing.Size(1130, 58)
    $detailsBox.Text = ""
    $form.Controls.Add($detailsBox)

    $uiDescFr = Get-UiStrings -Language "fr"
    $uiDescEn = Get-UiStrings -Language "en"
    Add-ConcreteDescriptionExamples -Ui $uiDescFr -Language "fr"
    Add-ConcreteDescriptionExamples -Ui $uiDescEn -Language "en"
    Register-ControlDescription -Control $trainerSpeciesCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerSpecies; en = $uiDescEn.Descriptions.TrainerSpecies }
    Register-ControlDescription -Control $trainerMoveCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerMoves; en = $uiDescEn.Descriptions.TrainerMoves }
    Register-ControlDescription -Control $trainerSmogonMoveFallbackCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerSmogonMoveFallback; en = $uiDescEn.Descriptions.TrainerSmogonMoveFallback }
    Register-ControlDescription -Control $trainerItemCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerItems; en = $uiDescEn.Descriptions.TrainerItems }
    Register-ControlDescription -Control $trainerItemPoolCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerItemPool; en = $uiDescEn.Descriptions.TrainerItemPool }
    Register-ControlDescription -Control $trainerAddedSlotSpeciesCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerAddedSlotSpecies; en = $uiDescEn.Descriptions.TrainerAddedSlotSpecies }
    Register-ControlDescription -Control $trainerDuplicateModeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerDuplicateMode; en = $uiDescEn.Descriptions.TrainerDuplicateMode }
    Register-ControlDescription -Control $bossTeamsScopeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.BossTeamsScope; en = $uiDescEn.Descriptions.BossTeamsScope }
    Register-ControlDescription -Control $trainerAbilityCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerAbility; en = $uiDescEn.Descriptions.TrainerAbility }
    Register-ControlDescription -Control $trainerIvCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerIV; en = $uiDescEn.Descriptions.TrainerIV }
    Register-ControlDescription -Control $trainerEvCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerEV; en = $uiDescEn.Descriptions.TrainerEV }
    Register-ControlDescription -Control $trainerLevelBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerLevel; en = $uiDescEn.Descriptions.TrainerLevel }
    Register-ControlDescription -Control $trainerTeamMinBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerTeamSize; en = $uiDescEn.Descriptions.TrainerTeamSize }
    Register-ControlDescription -Control $trainerTeamMaxBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerTeamSize; en = $uiDescEn.Descriptions.TrainerTeamSize }
    Register-ControlDescription -Control $controls.TrainerTypeThemed -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerTypeThemed; en = $uiDescEn.Descriptions.TrainerTypeThemed }
    Register-ControlDescription -Control $controls.TrainerNatureMode -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.RandomizeNatures; en = $uiDescEn.Descriptions.RandomizeNatures }
    Register-ControlDescription -Control $controls.AllowLegendaryTrainers -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AllowLegendaryTrainers; en = $uiDescEn.Descriptions.AllowLegendaryTrainers }
    Register-ControlDescription -Control $trainerShinyBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerShinyChance; en = $uiDescEn.Descriptions.TrainerShinyChance }
    Register-ControlDescription -Control $controls.ForceTrainerFullyEvolved -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ForceTrainerFullyEvolved; en = $uiDescEn.Descriptions.ForceTrainerFullyEvolved }
    Register-ControlDescription -Control $trainerFullyEvolvedLevelBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ForceTrainerFullyEvolved; en = $uiDescEn.Descriptions.ForceTrainerFullyEvolved }
    Register-ControlDescription -Control $controls.MaxTrainerAI -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MaxTrainerAI; en = $uiDescEn.Descriptions.MaxTrainerAI }
    Register-ControlDescription -Control $trainerDynamaxLevelCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TrainerDynamaxLevel; en = $uiDescEn.Descriptions.TrainerDynamaxLevel }
    Register-ControlDescription -Control $controls.ForceTrainerCanDynamax -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ForceTrainerCanDynamax; en = $uiDescEn.Descriptions.ForceTrainerCanDynamax }
    Register-ControlDescription -Control $controls.ForceAllTeamsToSix -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ForceAllTeams; en = $uiDescEn.Descriptions.ForceAllTeams }
    Register-ControlDescription -Control $controls.ForceBossTeamsToSix -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ForceBossTeams; en = $uiDescEn.Descriptions.ForceBossTeams }
    Register-ControlDescription -Control $bossTargetsBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ForceBossTargets; en = $uiDescEn.Descriptions.ForceBossTargets }
    Register-ControlDescription -Control $typeModeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TypeMode; en = $uiDescEn.Descriptions.TypeMode }
    Register-ControlDescription -Control $controls.TypesMonotypeOnly -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TypesMonotypeOnly; en = $uiDescEn.Descriptions.TypesMonotypeOnly }
    Register-ControlDescription -Control $abilityModeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AbilityMode; en = $uiDescEn.Descriptions.AbilityMode }
    Register-ControlDescription -Control $controls.AllowWonderGuard -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AllowWonderGuard; en = $uiDescEn.Descriptions.AllowWonderGuard }
    Register-ControlDescription -Control $statModeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.StatMode; en = $uiDescEn.Descriptions.StatMode }
    Register-ControlDescription -Control $expYieldMultiplierBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ExpYieldMultiplier; en = $uiDescEn.Descriptions.ExpYieldMultiplier }
    Register-ControlDescription -Control $controls.ForceOneExpYield -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ForceOneExpYield; en = $uiDescEn.Descriptions.ForceOneExpYield }
    Register-ControlDescription -Control $controls.RandomizeMoveTypes -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MoveTypeMode; en = $uiDescEn.Descriptions.MoveTypeMode }
    Register-ControlDescription -Control $controls.RandomizeMovePower -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MovePowerMode; en = $uiDescEn.Descriptions.MovePowerMode }
    Register-ControlDescription -Control $movePowerMinBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MovePowerMode; en = $uiDescEn.Descriptions.MovePowerMode }
    Register-ControlDescription -Control $movePowerMaxBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MovePowerMode; en = $uiDescEn.Descriptions.MovePowerMode }
    Register-ControlDescription -Control $controls.RandomizeMovePP -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MovePPMode; en = $uiDescEn.Descriptions.MovePPMode }
    Register-ControlDescription -Control $movePPMinBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MovePPMode; en = $uiDescEn.Descriptions.MovePPMode }
    Register-ControlDescription -Control $movePPMaxBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MovePPMode; en = $uiDescEn.Descriptions.MovePPMode }
    Register-ControlDescription -Control $controls.RandomizeMoveAccuracy -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MoveAccuracyMode; en = $uiDescEn.Descriptions.MoveAccuracyMode }
    Register-ControlDescription -Control $moveAccuracyMinBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MoveAccuracyMode; en = $uiDescEn.Descriptions.MoveAccuracyMode }
    Register-ControlDescription -Control $moveAccuracyMaxBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MoveAccuracyMode; en = $uiDescEn.Descriptions.MoveAccuracyMode }
    Register-ControlDescription -Control $controls.RandomizeMoveCategory -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MoveCategoryMode; en = $uiDescEn.Descriptions.MoveCategoryMode }
    Register-ControlDescription -Control $controls.RandomizePickupItems -DetailsBox $detailsBox -Description @{ fr = "Randomise les objets du tableau structure d'exploration souterraine. Les scripts AMX d'objets au sol ne sont pas modifies."; en = "Randomizes items in the decoded underground exploration item table. Field-item AMX scripts are not edited." }
    Register-ControlDescription -Control $controls.RandomizeShopItems -DetailsBox $detailsBox -Description @{ fr = "Randomise les objets des boutiques decodees dans shop_data.bin. Les scripts AMX de boutique restent intacts."; en = "Randomizes decoded shop inventory items in shop_data.bin. Shop AMX scripts remain untouched." }
    Register-ControlDescription -Control $controls.RandomizeTechnicalRecords -DetailsBox $detailsBox -Description @{ fr = "Randomise les IDs d'objets CT/TR quand ils apparaissent dans les tables decodees. Ne change pas encore les attaques enseignees par item.dat."; en = "Randomizes TM/TR item IDs when they appear in decoded tables. It does not yet change item.dat taught moves." }
    Register-ControlDescription -Control $starterModeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.StarterMode; en = $uiDescEn.Descriptions.StarterMode }
    Register-ControlDescription -Control $starter1Box -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.Starter1; en = $uiDescEn.Descriptions.Starter1 }
    Register-ControlDescription -Control $starter2Box -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.Starter2; en = $uiDescEn.Descriptions.Starter2 }
    Register-ControlDescription -Control $starter3Box -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.Starter3; en = $uiDescEn.Descriptions.Starter3 }
    Register-ControlDescription -Control $controls.PatchStarterRelatedTrainers -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.PatchStarters; en = $uiDescEn.Descriptions.PatchStarters }
    Register-ControlDescription -Control $reportLangCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ReportLanguage; en = $uiDescEn.Descriptions.ReportLanguage }
    Register-ControlDescription -Control $uiLangCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.UiLanguage; en = $uiDescEn.Descriptions.UiLanguage }
    Register-ControlDescription -Control $themeCombo -DetailsBox $detailsBox -Description @{ fr = "Theme de l'interface: clair ou sombre. Le choix est aussi sauvegarde dans les presets JSON."; en = "Interface theme: light or dark. This choice is also saved in JSON presets." }
    Register-ControlDescription -Control $difficultyProfileCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.DifficultyProfile; en = $uiDescEn.Descriptions.DifficultyProfile }
    Register-ControlDescription -Control $applyDifficultyProfileButton -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.DifficultyProfile; en = $uiDescEn.Descriptions.DifficultyProfile }
    Register-ControlDescription -Control $validateBuildButton -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.ValidateBuild; en = $uiDescEn.Descriptions.ValidateBuild }
    Register-ControlDescription -Control $buildSummaryButton -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.BuildSummary; en = $uiDescEn.Descriptions.BuildSummary }
    Register-ControlDescription -Control $sourceBox -DetailsBox $detailsBox -Description @{ fr = "Dossier ROMFS original du dump utilisateur. Exemple: selectionne ...\\Epee\\romfs; le logiciel copie seulement les fichiers necessaires puis modifie les tables ROMFS en sortie."; en = "Original ROMFS folder from the user's dump. Example: select ...\\Sword\\romfs; the tool copies only needed files and edits ROMFS tables in the generated output." }
    Register-ControlDescription -Control $sourceExefsBox -DetailsBox $detailsBox -Description @{ fr = "Dossier ExeFS original du dump utilisateur. Exemple: selectionne ...\\Epee\\exefs, le dossier qui contient main.npdm. Le logiciel copie ce main.npdm utilisateur et ajoute seulement son subsdk9 custom fourni avec le projet."; en = "Original ExeFS folder from the user's dump. Example: select ...\\Sword\\exefs, the folder containing main.npdm. The tool copies that user-provided main.npdm and only adds its custom subsdk9 shipped with the project." }
    Register-ControlDescription -Control $outputBox -DetailsBox $detailsBox -Description @{ fr = "Dossier de sortie du mod. Exemple: ...\\output\\Epee. Le logiciel cree toujours romfs dedans. Il n'ajoute exefs\\subsdk9, exefs\\main.npdm copie depuis ton dump et sdmc\\config que si un dossier ExeFS est explicitement fourni pour les options ExLaunch/runtime."; en = "Generated mod folder. Example: ...\\output\\Sword. The tool always creates romfs there. It only adds exefs\\subsdk9, exefs\\main.npdm copied from your dump, and sdmc\\config when an ExeFS folder is explicitly provided for ExLaunch/runtime features." }
    Register-ControlDescription -Control $controls.DisableExpShare -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.DisableExpShare; en = $uiDescEn.Descriptions.DisableExpShare }
    Register-ControlDescription -Control $controls.EarlyBike -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.EarlyBike; en = $uiDescEn.Descriptions.EarlyBike }
    Register-ControlDescription -Control $controls.RuntimePcControls -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.RuntimePcControls; en = $uiDescEn.Descriptions.RuntimePcControls }
    Register-ControlDescription -Control $controls.DynamicExpLevelCap -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.DynamicExpLevelCap; en = $uiDescEn.Descriptions.DynamicExpLevelCap }
    Register-ControlDescription -Control $controls.StrictBossMaxLevelCap -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.StrictBossMaxLevelCap; en = $uiDescEn.Descriptions.StrictBossMaxLevelCap }
    Register-ControlDescription -Control $controls.MainStorySoftLevelCap -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.MainStorySoftLevelCap; en = $uiDescEn.Descriptions.MainStorySoftLevelCap }
    Register-ControlDescription -Control $controls.GymLeagueStoryLevelCap -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.GymLeagueStoryLevelCap; en = $uiDescEn.Descriptions.GymLeagueStoryLevelCap }
    Register-ControlDescription -Control $controls.StoryMajorBattleOrderLevelCap -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.StoryMajorBattleOrderLevelCap; en = $uiDescEn.Descriptions.StoryMajorBattleOrderLevelCap }
    Register-ControlDescription -Control $controls.AutoInstallToEden -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AutoInstallToEden; en = $uiDescEn.Descriptions.AutoInstallToEden }
    Register-ControlDescription -Control $edenModNameBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.EdenModName; en = $uiDescEn.Descriptions.EdenModName }
    Register-ControlDescription -Control $controls.InstallToEden -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.InstallTargetEden; en = $uiDescEn.Descriptions.InstallTargetEden }
    Register-ControlDescription -Control $controls.InstallToRyujinx -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.InstallTargetRyujinx; en = $uiDescEn.Descriptions.InstallTargetRyujinx }
    Register-ControlDescription -Control $controls.InstallToYuzu -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.InstallTargetYuzu; en = $uiDescEn.Descriptions.InstallTargetYuzu }
    Register-ControlDescription -Control $controls.InstallToSudachi -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.InstallTargetSudachi; en = $uiDescEn.Descriptions.InstallTargetSudachi }
    Register-ControlDescription -Control $controls.InstallToCitron -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.InstallTargetCitron; en = $uiDescEn.Descriptions.InstallTargetCitron }
    Register-ControlDescription -Control $controls.InstallToSuyu -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.InstallTargetSuyu; en = $uiDescEn.Descriptions.InstallTargetSuyu }
    Register-ControlDescription -Control $controls.InstallToCitronNeo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.InstallTargetCitronNeo; en = $uiDescEn.Descriptions.InstallTargetCitronNeo }
    Register-ControlDescription -Control $controls.RaceMode -DetailsBox $detailsBox -Description @{ fr = "Mode race: garde la seed finale dans un fichier race-summary.json non detaille et ecrit les spoilers complets dans spoiler-log.json. Le resume de seed peut spoiler; ne l'ouvre que si tu veux voir le contenu de la run."; en = "Race mode: keeps the final seed in a non-detailed race-summary.json and writes full spoilers into spoiler-log.json. The seed summary can spoil the run; open it only if you want to see run contents." }
    Register-ControlDescription -Control $controls.ExportEncounterZoneReport -DetailsBox $detailsBox -Description @{ fr = "Exporte encounter-zones.json pour le viewer: zones, methodes d'apparition, chances, niveaux et especes avant/apres. Ce fichier peut spoiler les rencontres."; en = "Exports encounter-zones.json for the viewer: zones, encounter methods, chances, levels, and before/after species. This file can spoil encounters." }
    Register-ControlDescription -Control $evoModeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.EvolutionMode; en = $uiDescEn.Descriptions.EvolutionMode }
    Register-ControlDescription -Control $controls.AllowLegendaryEvolutions -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AllowLegendaryEvo; en = $uiDescEn.Descriptions.AllowLegendaryEvo }
    Register-ControlDescription -Control $controls.NormalizeFriendshipEvolutions -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.NormalizeFriendship; en = $uiDescEn.Descriptions.NormalizeFriendship }
    Register-ControlDescription -Control $friendshipLevelBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.NormalizeFriendship; en = $uiDescEn.Descriptions.NormalizeFriendship }
    Register-ControlDescription -Control $controls.NormalizeTradeEvolutions -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.NormalizeTrade; en = $uiDescEn.Descriptions.NormalizeTrade }
    Register-ControlDescription -Control $tradeLevelBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.NormalizeTrade; en = $uiDescEn.Descriptions.NormalizeTrade }
    Register-ControlDescription -Control $controls.NormalizeSpecialEvolutions -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.NormalizeSpecial; en = $uiDescEn.Descriptions.NormalizeSpecial }
    Register-ControlDescription -Control $specialLevelBox -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.NormalizeSpecial; en = $uiDescEn.Descriptions.NormalizeSpecial }
    Register-ControlDescription -Control $giftModeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.GiftMode; en = $uiDescEn.Descriptions.GiftMode }
    Register-ControlDescription -Control $controls.AllowLegendaryGifts -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AllowLegendaryGifts; en = $uiDescEn.Descriptions.AllowLegendaryGifts }
    Register-ControlDescription -Control $tradeModeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.TradeMode; en = $uiDescEn.Descriptions.TradeMode }
    Register-ControlDescription -Control $controls.AllowLegendaryTrades -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AllowLegendaryTrades; en = $uiDescEn.Descriptions.AllowLegendaryTrades }
    Register-ControlDescription -Control $staticEncounterCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.StaticMode; en = $uiDescEn.Descriptions.StaticMode }
    Register-ControlDescription -Control $controls.AllowLegendaryStaticEncounters -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AllowLegendaryStatic; en = $uiDescEn.Descriptions.AllowLegendaryStatic }
    Register-ControlDescription -Control $staticStableMappingCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.StaticStableMapping; en = $uiDescEn.Descriptions.StaticStableMapping }
    Register-ControlDescription -Control $grassEncounterCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.GrassMode; en = $uiDescEn.Descriptions.GrassMode }
    Register-ControlDescription -Control $controls.AllowLegendaryGrassEncounters -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AllowLegendaryGrass; en = $uiDescEn.Descriptions.AllowLegendaryGrass }
    Register-ControlDescription -Control $grassStableMappingCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.GrassStableMapping; en = $uiDescEn.Descriptions.GrassStableMapping }
    Register-ControlDescription -Control $visibleBehaviorCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.VisibleEncounterBehavior; en = $uiDescEn.Descriptions.VisibleEncounterBehavior }
    Register-ControlDescription -Control $undergroundModeCombo -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.UndergroundMode; en = $uiDescEn.Descriptions.UndergroundMode }
    Register-ControlDescription -Control $controls.AllowLegendaryUnderground -DetailsBox $detailsBox -Description @{ fr = $uiDescFr.Descriptions.AllowLegendaryUnderground; en = $uiDescEn.Descriptions.AllowLegendaryUnderground }

    $statusBox.Location = New-Object System.Drawing.Point(18, 918)
    $statusBox.Size = New-Object System.Drawing.Size(1130, 62)
    $statusBox.Text = ""
    $form.Controls.Add($statusBox)

    $script:ApplyingUiLanguage = $false
    $script:ApplyingCompatibilityUi = $false
    $script:LastDetailsDescription = $null
    function Apply-UiLanguage {
        param([string]$Language)

        if ($script:ApplyingUiLanguage) {
            return
        }
        $script:ApplyingUiLanguage = $true

        $script:UiLanguage = if ($Language -eq "en") { "en" } else { "fr" }
        $ui = Get-UiStrings -Language $script:UiLanguage

        $form.Text = $ui.FormTitle
        $sourceLabel.Text = $ui.SourceLabel
        $sourceExefsLabel.Text = $ui.SourceExefsLabel
        $outputLabel.Text = $ui.OutputLabel
        $gameVersionLabel.Text = $ui.GameVersion
        $seedLabel.Text = $ui.Seed
        $uiLangLabel.Text = $ui.UiLanguage
        $reportLangLabel.Text = $ui.ReportLanguage
        $themeLabel.Text = $ui.Theme
        $difficultyProfileLabel.Text = $ui.DifficultyProfile
        $browseSource.Text = $ui.Browse
        $browseSourceExefs.Text = $ui.Browse
        $browseOutput.Text = $ui.Browse
        $runButton.Text = $ui.Generate
        $applyDifficultyProfileButton.Text = $ui.ApplyDifficultyProfile
        $validateBuildButton.Text = $ui.ValidateBuild
        $buildSummaryButton.Text = $ui.BuildSummary
        $exportPresetButton.Text = if ($script:UiLanguage -eq "en") { "Export preset" } else { "Exporter preset" }
        $importPresetButton.Text = if ($script:UiLanguage -eq "en") { "Import preset" } else { "Importer preset" }
        $generalTab.Text = $ui.Tabs.General
        $trainerTab.Text = $ui.Tabs.Trainers
        $pokemonTab.Text = $ui.Tabs.Pokemon
        $evoTab.Text = $ui.Tabs.Evolutions
        $giftTab.Text = $ui.Tabs.Gifts
        $encounterTab.Text = $ui.Tabs.Encounters
        $helpTab.Text = $ui.Tabs.Help
        $resetTab.Text = $ui.Tabs.Reset

        for ($i = 0; $i -lt $generalInfoLabels.Count; $i++) {
            $generalInfoLabels[$i].Text = $ui.GeneralLines[$i]
        }
        $controls.DisableExpShare.Text = $ui.Labels.DisableExpShare
        $controls.EarlyBike.Text = $ui.Labels.EarlyBike
        $controls.RuntimePcControls.Text = $ui.Labels.RuntimePcControls
        $controls.DynamicExpLevelCap.Text = $ui.Labels.DynamicExpLevelCap
        $controls.StrictBossMaxLevelCap.Text = $ui.Labels.StrictBossMaxLevelCap
        $controls.MainStorySoftLevelCap.Text = $ui.Labels.MainStorySoftLevelCap
        $controls.GymLeagueStoryLevelCap.Text = $ui.Labels.GymLeagueStoryLevelCap
        $controls.StoryMajorBattleOrderLevelCap.Text = $ui.Labels.StoryMajorBattleOrderLevelCap
        $controls.AutoInstallToEden.Text = $ui.Labels.AutoInstallToEden
        $edenModNameLabel.Text = $ui.Labels.EdenModName
        $controls.InstallToEden.Text = $ui.Labels.InstallTargetEden
        $controls.InstallToRyujinx.Text = $ui.Labels.InstallTargetRyujinx
        $controls.InstallToYuzu.Text = $ui.Labels.InstallTargetYuzu
        $controls.InstallToSudachi.Text = $ui.Labels.InstallTargetSudachi
        $controls.InstallToCitron.Text = $ui.Labels.InstallTargetCitron
        $controls.InstallToSuyu.Text = $ui.Labels.InstallTargetSuyu
        $controls.InstallToCitronNeo.Text = $ui.Labels.InstallTargetCitronNeo
        $controls.RaceMode.Text = if ($script:UiLanguage -eq "en") { "Race mode (locked seed / separate logs)" } else { "Race mode (seed fixe / logs separes)" }
        $controls.ExportEncounterZoneReport.Text = if ($script:UiLanguage -eq "en") { "Encounter zones JSON" } else { "JSON zones rencontres" }
        $resetInfoLabel.Text = $ui.Labels.ResetDefault
        $resetButton.Text = $ui.Labels.ResetButton

        $trainerSpeciesLabel.Text = $ui.Labels.TrainerSpecies
        $trainerMovesLabel.Text = $ui.Labels.TrainerMoves
        $trainerItemsLabel.Text = $ui.Labels.TrainerItems
        $trainerItemPoolLabel.Text = $ui.Labels.TrainerItemPool
        $trainerAbilityLabel.Text = $ui.Labels.TrainerAbility
        $trainerIvLabel.Text = $ui.Labels.TrainerIV
        $trainerEvLabel.Text = $ui.Labels.TrainerEV
        $trainerAddedSlotSpeciesLabel.Text = $ui.Labels.TrainerAddedSlotSpecies
        $trainerDuplicateModeLabel.Text = $ui.Labels.TrainerDuplicateMode
        $bossTeamsScopeLabel.Text = $ui.Labels.BossTeamsScope
        $trainerLevelLabel.Text = $ui.Labels.TrainerLevel
        $trainerTeamMinLabel.Text = $ui.Labels.TrainerTeamMin
        $trainerTeamMaxLabel.Text = $ui.Labels.TrainerTeamMax
        $trainerNatureModeLabel.Text = $ui.Labels.RandomizeNatures
        $controls.TrainerTypeThemed.Text = $ui.Labels.TrainerTypeThemed
        $trainerShinyLabel.Text = $ui.Labels.TrainerShinyChance
        $controls.ForceTrainerFullyEvolved.Text = $ui.Labels.ForceTrainerFullyEvolved
        $trainerFullyEvolvedLevelLabel.Text = $ui.Labels.TrainerFullyEvolvedLevel
        $controls.MaxTrainerAI.Text = $ui.Labels.MaxTrainerAI
        $trainerDynamaxLevelLabel.Text = $ui.Labels.TrainerDynamaxLevel
        $controls.ForceTrainerCanDynamax.Text = $ui.Labels.ForceTrainerCanDynamax
        $controls.ForceAllTeamsToSix.Text = $ui.Labels.ForceAllTeams
        $controls.ForceBossTeamsToSix.Text = $ui.Labels.ForceBossTeams
        $controls.AllowLegendaryTrainers.Text = $ui.Labels.AllowLegendaryTrainers
        $bossScopeValue = if ($controls.BossTeamsToSixScope) { Get-ComboValue -Combo $controls.BossTeamsToSixScope } else { $script:BossTeamsToSixScope }
        $bossTargetsBox.Text = Get-BossTrainerUniqueNamesText -Language $script:UiLanguage -Scope $bossScopeValue
        $typeModeLabel.Text = $ui.Labels.TypeMode
        $controls.TypesMonotypeOnly.Text = $ui.Labels.ForceMonotype
        $abilityModeLabel.Text = $ui.Labels.AbilityMode
        $controls.AllowWonderGuard.Text = $ui.Labels.AllowWonderGuard
        $statModeLabel.Text = $ui.Labels.StatMode
        $expYieldMultiplierLabel.Text = $ui.Labels.ExpYieldMultiplier
        $controls.ForceOneExpYield.Text = $ui.Labels.ForceOneExpYield
        $controls.RandomizeMoveTypes.Text = $ui.Labels.MoveTypeMode
        $controls.RandomizeMovePower.Text = $ui.Labels.MovePowerMode
        $movePowerMinLabel.Text = $ui.Labels.MovePowerMin
        $movePowerMaxLabel.Text = $ui.Labels.MovePowerMax
        $controls.RandomizeMovePP.Text = $ui.Labels.MovePPMode
        $movePPMinLabel.Text = $ui.Labels.MovePPMin
        $movePPMaxLabel.Text = $ui.Labels.MovePPMax
        $controls.RandomizeMoveAccuracy.Text = $ui.Labels.MoveAccuracyMode
        $moveAccuracyMinLabel.Text = $ui.Labels.MoveAccuracyMin
        $moveAccuracyMaxLabel.Text = $ui.Labels.MoveAccuracyMax
        $controls.RandomizeMoveCategory.Text = $ui.Labels.MoveCategoryMode
        $controls.RandomizePickupItems.Text = if ($script:UiLanguage -eq "en") { "Pickup / field items" } else { "Objets ramassables" }
        $controls.RandomizeShopItems.Text = if ($script:UiLanguage -eq "en") { "Shop items" } else { "Objets boutiques" }
        $controls.RandomizeTechnicalRecords.Text = if ($script:UiLanguage -eq "en") { "TM/TR item IDs" } else { "Objets CT/TR" }
        $evoModeLabel.Text = $ui.Labels.EvolutionMode
        $controls.AllowLegendaryEvolutions.Text = $ui.Labels.AllowLegendaryEvo
        $controls.NormalizeFriendshipEvolutions.Text = $ui.Labels.NormalizeFriendship
        $friendshipLevelLabel.Text = $ui.Labels.FriendshipLevel
        $controls.NormalizeTradeEvolutions.Text = $ui.Labels.NormalizeTrade
        $tradeLevelLabelEvo.Text = $ui.Labels.TradeLevel
        $controls.NormalizeSpecialEvolutions.Text = $ui.Labels.NormalizeSpecial
        $specialLevelLabelEvo.Text = $ui.Labels.SpecialLevel
        $giftModeLabel.Text = $ui.Labels.GiftMode
        $starterModeLabel.Text = $ui.Labels.StarterMode
        $controls.AllowLegendaryGifts.Text = $ui.Labels.AllowLegendaryGifts
        $manualStarterGroupLabel.Text = $ui.Labels.ManualStarterGroup
        $starter1Label.Text = $ui.Labels.Slot1
        $starter2Label.Text = $ui.Labels.Slot2
        $starter3Label.Text = $ui.Labels.Slot3
        $controls.PatchStarterRelatedTrainers.Text = $ui.Labels.PatchStarters
        $tradeModeLabel.Text = $ui.Labels.TradeMode
        $controls.AllowLegendaryTrades.Text = $ui.Labels.AllowLegendaryTrades
        $staticModeLabel.Text = $ui.Labels.StaticMode
        $controls.AllowLegendaryStaticEncounters.Text = $ui.Labels.AllowLegendaryStatic
        $staticStableMappingLabel.Text = $ui.Labels.StaticStableMapping
        $grassModeLabel.Text = $ui.Labels.GrassMode
        $controls.AllowLegendaryGrassEncounters.Text = $ui.Labels.AllowLegendaryGrass
        $grassStableMappingLabel.Text = $ui.Labels.GrassStableMapping
        $visibleBehaviorLabel.Text = $ui.Labels.VisibleEncounterBehavior
        $undergroundModeLabel.Text = $ui.Labels.UndergroundMode
        $controls.AllowLegendaryUnderground.Text = $ui.Labels.AllowLegendaryUnderground

        Set-LocalizedComboItems -Combo $uiLangCombo -Items @(
            @{ Label = $ui.UiLanguageFrench; Value = "fr" },
            @{ Label = $ui.UiLanguageEnglish; Value = "en" }
        )
        Set-LocalizedComboItems -Combo $reportLangCombo -Items @(
            @{ Label = $ui.ReportLanguageFrench; Value = "fr" },
            @{ Label = $ui.ReportLanguageEnglish; Value = "en" }
        )
        Set-LocalizedComboItems -Combo $themeCombo -Items @(
            @{ Label = $ui.ThemeLight; Value = "Light" },
            @{ Label = $ui.ThemeDark; Value = "Dark" }
        )
        Set-LocalizedComboItems -Combo $difficultyProfileCombo -Items (Get-DifficultyProfileComboItems -Language $script:UiLanguage)
        Set-LocalizedComboItems -Combo $trainerSpeciesCombo -Items @(
            @{ Label = $ui.ModeRandom; Value = "Random" },
            @{ Label = $ui.ModeSimilarBST; Value = "SimilarBST" },
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" }
        )
        Set-LocalizedComboItems -Combo $trainerMoveCombo -Items @(
            @{ Label = $ui.TrainerMoveRandom4; Value = "Random4" },
            @{ Label = $ui.TrainerMoveLevel4; Value = "LastLevelUp4" },
            @{ Label = $ui.TrainerMoveSmogon; Value = "SmogonStrategic" },
            @{ Label = $ui.TrainerMoveSmogonLegacy; Value = "SmogonLegacy" },
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" }
        )
        $trainerSmogonMoveFallbackLabel.Text = $ui.Labels.TrainerSmogonMoveFallback
        Set-LocalizedComboItems -Combo $trainerSmogonMoveFallbackCombo -Items @(
            @{ Label = $ui.TrainerSmogonMoveFallbackLevel; Value = "LastLevelUp4" },
            @{ Label = $ui.TrainerSmogonMoveFallbackRandom; Value = "Random4" },
            @{ Label = $ui.TrainerSmogonMoveFallbackUnchanged; Value = "Unchanged" }
        )
        Set-LocalizedComboItems -Combo $trainerItemCombo -Items @(
            @{ Label = $ui.TrainerItemRandomPresent; Value = "RandomWhenPresent" },
            @{ Label = $ui.TrainerItemForceAll; Value = "ForceAll" },
            @{ Label = $ui.TrainerItemSmogon; Value = "SmogonStrategic" },
            @{ Label = $ui.TrainerItemSmogonLegacy; Value = "SmogonLegacy" },
            @{ Label = $ui.TrainerItemRemoveAll; Value = "RemoveAll" },
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" }
        )
        Set-LocalizedComboItems -Combo $trainerItemPoolCombo -Items @(
            @{ Label = $ui.TrainerItemPoolBattle; Value = "Battle" },
            @{ Label = $ui.TrainerItemPoolFull; Value = "FullRandom" }
        )
        Set-LocalizedComboItems -Combo $trainerAbilityCombo -Items @(
            @{ Label = $ui.TrainerAbilityRandom; Value = "RandomSlot" },
            @{ Label = $ui.TrainerAbilitySmogon; Value = "SmogonStrategic" },
            @{ Label = $ui.TrainerAbilitySmogonLegacy; Value = "SmogonLegacy" },
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" }
        )
        Set-LocalizedComboItems -Combo $trainerIvCombo -Items @(
            @{ Label = $ui.TrainerIVMax; Value = "Max31" },
            @{ Label = $ui.TrainerIVRandom; Value = "Random" },
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" }
        )
        Set-LocalizedComboItems -Combo $trainerEvCombo -Items @(
            @{ Label = $ui.TrainerEVSmogon; Value = "SmogonStrategic" },
            @{ Label = $ui.TrainerEVSmogonLegacy; Value = "SmogonLegacy" },
            @{ Label = $ui.TrainerEVRandom; Value = "RandomLegal" },
            @{ Label = $ui.TrainerEVZero; Value = "Zero" },
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" }
        )
        Set-LocalizedComboItems -Combo $trainerNatureModeCombo -Items @(
            @{ Label = $ui.TrainerNatureUnchanged; Value = "Unchanged" },
            @{ Label = $ui.TrainerNatureRandom; Value = "Random" },
            @{ Label = $ui.TrainerNatureSmogon; Value = "SmogonStrategic" },
            @{ Label = $ui.TrainerNatureSmogonLegacy; Value = "SmogonLegacy" }
        )
        Set-LocalizedComboItems -Combo $trainerAddedSlotSpeciesCombo -Items @(
            @{ Label = $ui.TrainerAddedSlotRandom; Value = "Random" },
            @{ Label = $ui.TrainerAddedSlotSimilarBST; Value = "SimilarBST" },
            @{ Label = $ui.TrainerAddedSlotSameType; Value = "SameTypeRandom" },
            @{ Label = $ui.TrainerAddedSlotSameTypeBST; Value = "SameTypeBST" }
        )
        Set-LocalizedComboItems -Combo $trainerDuplicateModeCombo -Items @(
            @{ Label = $ui.TrainerDuplicateNoDuplicates; Value = "NoDuplicates" },
            @{ Label = $ui.TrainerDuplicateNormal; Value = "Normal" }
        )
        Set-LocalizedComboItems -Combo $bossTeamsScopeCombo -Items @(
            @{ Label = $ui.BossScopeMajor; Value = "MajorBosses" },
            @{ Label = $ui.BossScopeGymLeague; Value = "GymLeague" }
        )
        Set-LocalizedComboItems -Combo $trainerDynamaxLevelCombo -Items @(
            @{ Label = $ui.Labels.TrainerDynamaxUnchanged; Value = "Unchanged" },
            @{ Label = $ui.Labels.TrainerDynamaxMax; Value = "Max10" },
            @{ Label = $ui.Labels.TrainerDynamaxRandom; Value = "Random0To10" }
        )
        Set-LocalizedComboItems -Combo $typeModeCombo -Items @(
            @{ Label = if ($script:UiLanguage -eq "en") { "Randomize Pokemon types" } else { "Randomiser les types" }; Value = "Random" },
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" }
        )
        Set-LocalizedComboItems -Combo $abilityModeCombo -Items @(
            @{ Label = if ($script:UiLanguage -eq "en") { "Randomize species abilities" } else { "Randomiser les talents des especes" }; Value = "Random" },
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" }
        )
        Set-LocalizedComboItems -Combo $statModeCombo -Items @(
            @{ Label = $ui.StatShuffle; Value = "Shuffle" },
            @{ Label = $ui.StatRedistribute; Value = "Redistribute" },
            @{ Label = $ui.ModeUnchanged; Value = "Unchanged" }
        )
        foreach ($combo in @($evoModeCombo, $giftModeCombo, $tradeModeCombo, $staticEncounterCombo, $grassEncounterCombo, $undergroundModeCombo)) {
            Set-LocalizedComboItems -Combo $combo -Items @(
                @{ Label = $ui.ModeRandom; Value = "Random" },
                @{ Label = $ui.ModeSimilarBST; Value = "SimilarBST" },
                @{ Label = $ui.ModeUnchanged; Value = "Unchanged" }
            )
        }
        Set-LocalizedComboItems -Combo $starterModeCombo -Items @(
            @{ Label = $ui.StarterRandom; Value = "Random" },
            @{ Label = $ui.StarterSimilarBST; Value = "SimilarBST" },
            @{ Label = $ui.StarterUnchanged; Value = "Unchanged" }
        )
        foreach ($combo in @($staticStableMappingCombo, $grassStableMappingCombo)) {
            Set-LocalizedComboItems -Combo $combo -Items @(
                @{ Label = $ui.MappingSlot; Value = "Slot" },
                @{ Label = $ui.MappingSpecies; Value = "Species" },
                @{ Label = $ui.MappingTrueRandom; Value = "Random" }
            )
        }
        Set-LocalizedComboItems -Combo $visibleBehaviorCombo -Items @(
            @{ Label = if ($script:UiLanguage -eq "en") { "Classic: visible = battle" } else { "Classique: visible = combat" }; Value = "RomfsMatch" },
            @{ Label = if ($script:UiLanguage -eq "en") { "Random visible + hidden battle" } else { "Visuel random + combat cache" }; Value = "RandomVisualBattleRandom" },
            @{ Label = if ($script:UiLanguage -eq "en") { "Vanilla visible + hidden battle" } else { "Visuel vanilla + combat cache" }; Value = "VanillaVisualBattleRandom" }
        )

        if ($script:LastDetailsDescription) {
            $detailsBox.Text = Get-LocalizedDescriptionText -Description $script:LastDetailsDescription
        } elseif ([string]::IsNullOrWhiteSpace($detailsBox.Text) -or
            $detailsBox.Text -eq (Get-UiStrings -Language "fr").Labels.DetailsDefault -or
            $detailsBox.Text -eq (Get-UiStrings -Language "en").Labels.DetailsDefault) {
            $detailsBox.Text = $ui.Labels.DetailsDefault
        }
        if ([string]::IsNullOrWhiteSpace($statusBox.Text)) {
            $statusBox.Text = $ui.Labels.StatusDefault
        }
        $script:ApplyingUiLanguage = $false
    }

    function Update-InstallationUi {
        $gameVersion = Get-SourceGameVersion -RomfsRoot $controls.Source.Text
        $modName = Get-NormalizedModName -ModName $controls.EdenModName.Text
        $ui = Get-UiStrings -Language $script:UiLanguage
        $targetMap = @{}
        foreach ($target in @(Get-EmulatorInstallTargets -GameVersion $gameVersion -ModName $modName)) {
            $targetMap[[string]$target.Key] = $target
        }

        foreach ($pair in @(
            @{ Control = $controls.InstallToEden; ResetControl = $controls.ResetInstallToEden; Key = "eden"; Label = $ui.Labels.InstallTargetEden },
            @{ Control = $controls.InstallToRyujinx; ResetControl = $controls.ResetInstallToRyujinx; Key = "ryujinx"; Label = $ui.Labels.InstallTargetRyujinx },
            @{ Control = $controls.InstallToYuzu; ResetControl = $controls.ResetInstallToYuzu; Key = "yuzu"; Label = $ui.Labels.InstallTargetYuzu },
            @{ Control = $controls.InstallToSudachi; ResetControl = $controls.ResetInstallToSudachi; Key = "sudachi"; Label = $ui.Labels.InstallTargetSudachi },
            @{ Control = $controls.InstallToCitron; ResetControl = $controls.ResetInstallToCitron; Key = "citron"; Label = $ui.Labels.InstallTargetCitron },
            @{ Control = $controls.InstallToSuyu; ResetControl = $controls.ResetInstallToSuyu; Key = "suyu"; Label = $ui.Labels.InstallTargetSuyu },
            @{ Control = $controls.InstallToCitronNeo; ResetControl = $controls.ResetInstallToCitronNeo; Key = "citronneo"; Label = $ui.Labels.InstallTargetCitronNeo }
        )) {
            $target = $targetMap[$pair.Key]
            $statusText = if ($target -and [bool]$target.IsDetected) {
                if ($script:UiLanguage -eq "en") { "detected" } else { "detecte" }
            } else {
                if ($script:UiLanguage -eq "en") { "not found" } else { "introuvable" }
            }
            $pair.Control.Text = ("{0} [{1}]" -f $pair.Label, $statusText)
            $pair.ResetControl.Text = $pair.Control.Text
            if ($controls.AutoInstallToEden) {
                $pair.Control.Enabled = ([bool]$controls.AutoInstallToEden.Checked -and $target -and [bool]$target.IsDetected)
            }
            if ($pair.ResetControl) {
                $pair.ResetControl.Enabled = ($target -and [bool]$target.IsDetected)
            }
        }

        $helpBox.Text = Get-RandomizerHelpText -Language $script:UiLanguage -GameVersion $gameVersion -ModName $modName -OutputRomfsRoot $controls.Output.Text
        if ([string]::IsNullOrWhiteSpace($resetStatusBox.Text)) {
            $resetStatusBox.Text = $ui.Labels.ResetDefault
        }
    }

    function Set-OptionControlsEnabled {
        param(
            [bool]$Enabled,
            [object[]]$ControlList
        )

        foreach ($control in @($ControlList)) {
            if ($null -ne $control) {
                $control.Enabled = $Enabled
            }
        }
    }

    function Update-CompatibilityUi {
        if ($script:ApplyingCompatibilityUi) {
            return
        }

        $script:ApplyingCompatibilityUi = $true
        try {
            $trainerSpeciesModeValue = Normalize-Mode (Get-ComboValue -Combo $controls.TrainerSpeciesMode)
            $trainerMoveModeValue = Normalize-Mode (Get-ComboValue -Combo $controls.TrainerMoveMode)
            $trainerItemModeValue = Normalize-Mode (Get-ComboValue -Combo $controls.TrainerItemMode)
            $forceAllTeams = [bool]$controls.ForceAllTeamsToSix.Checked
            if ($forceAllTeams -and [bool]$controls.ForceBossTeamsToSix.Checked) {
                $controls.ForceBossTeamsToSix.Checked = $false
            }

            $forceBossTeams = ([bool]$controls.ForceBossTeamsToSix.Checked -and -not $forceAllTeams)
            $teamExpansionEnabled = ($forceAllTeams -or $forceBossTeams)
            $smogonItemModeEnabled = Test-TrainerModeUsesSmogon $trainerItemModeValue
            $itemRandomEnabled = ($trainerItemModeValue -in @("randomwhenpresent", "forceall"))
            $smogonMoveFallbackEnabled = Test-TrainerModeUsesSmogon $trainerMoveModeValue
            $speciesRandomEnabled = ($trainerSpeciesModeValue -ne "unchanged")
            $addedSlotSpeciesChoiceEnabled = ($teamExpansionEnabled -and -not $speciesRandomEnabled)
            $duplicateModeUseful = ($speciesRandomEnabled -or $itemRandomEnabled -or $smogonItemModeEnabled -or $teamExpansionEnabled)

            if ($smogonItemModeEnabled) {
                [void](Set-ComboValue -Combo $controls.TrainerItemPoolMode -Value "Battle")
            }

            Set-OptionControlsEnabled -Enabled $itemRandomEnabled -ControlList @($trainerItemPoolLabel, $trainerItemPoolCombo)
            Set-OptionControlsEnabled -Enabled $smogonMoveFallbackEnabled -ControlList @($trainerSmogonMoveFallbackLabel, $trainerSmogonMoveFallbackCombo)
            Set-OptionControlsEnabled -Enabled $addedSlotSpeciesChoiceEnabled -ControlList @($trainerAddedSlotSpeciesLabel, $trainerAddedSlotSpeciesCombo)
            Set-OptionControlsEnabled -Enabled $duplicateModeUseful -ControlList @($trainerDuplicateModeLabel, $trainerDuplicateModeCombo)
            Set-OptionControlsEnabled -Enabled $speciesRandomEnabled -ControlList @($controls.TrainerTypeThemed)
            Set-OptionControlsEnabled -Enabled ($speciesRandomEnabled -or $addedSlotSpeciesChoiceEnabled) -ControlList @($controls.AllowLegendaryTrainers)
            Set-OptionControlsEnabled -Enabled (-not $forceAllTeams) -ControlList @($controls.ForceBossTeamsToSix)
            Set-OptionControlsEnabled -Enabled $forceBossTeams -ControlList @($bossTeamsScopeLabel, $bossTeamsScopeCombo, $bossTargetsBox)

            if (-not $forceBossTeams) {
                $bossTargetsBox.Text = if ($script:UiLanguage -eq "en") {
                    "Enable boss teams at 6 Pokemon to use this target list."
                } else {
                    "Active boss a 6 Pokemon pour utiliser cette liste de cibles."
                }
            } else {
                $bossTargetsBox.Text = Get-BossTrainerUniqueNamesText -Language $script:UiLanguage -Scope (Get-ComboValue -Combo $controls.BossTeamsToSixScope)
            }

            Update-InstallationUi
        } finally {
            $script:ApplyingCompatibilityUi = $false
        }
    }

    $uiLangCombo.Add_SelectedIndexChanged({
        Apply-UiLanguage -Language (Get-ComboValue -Combo $controls.UiLanguage)
        Update-InstallationUi
        Update-CompatibilityUi
        Bring-TopChromeToFront
    })

    $themeCombo.Add_SelectedIndexChanged({
        Apply-GuiTheme -Root $form -Theme (Get-ComboValue -Combo $controls.GuiTheme)
        Bring-TopChromeToFront
    })

    $bossTeamsScopeCombo.Add_SelectedIndexChanged({
        if (-not $script:ApplyingUiLanguage) {
            $bossTargetsBox.Text = Get-BossTrainerUniqueNamesText -Language $script:UiLanguage -Scope (Get-ComboValue -Combo $controls.BossTeamsToSixScope)
        }
    })

    foreach ($combo in @(
        $trainerSpeciesCombo,
        $trainerMoveCombo,
        $trainerItemCombo,
        $trainerAddedSlotSpeciesCombo,
        $trainerDuplicateModeCombo
    )) {
        $combo.Add_SelectedIndexChanged({ Update-CompatibilityUi })
    }

    foreach ($checkBox in @(
        $controls.ForceAllTeamsToSix,
        $controls.ForceBossTeamsToSix,
        $controls.AutoInstallToEden
    )) {
        $checkBox.Add_CheckedChanged({ Update-CompatibilityUi })
    }

    $controls.Source.Add_TextChanged({ Update-InstallationUi; Update-CompatibilityUi })
    $controls.Output.Add_TextChanged({ Update-InstallationUi })
    $controls.EdenModName.Add_TextChanged({ Update-InstallationUi; Update-CompatibilityUi })

    $applyDifficultyProfileButton.Add_Click({
        try {
            $profileKey = Get-ComboValue -Combo $controls.DifficultyProfile
            $result = Apply-DifficultyProfileToControls -Controls $controls -ProfileKey $profileKey
            Disable-RemovedBuildOptions -Controls $controls
            Update-InstallationUi
            Update-CompatibilityUi
            $profile = $result.Profile
            $label = [string]$profile.Labels[$script:UiLanguage]
            $description = [string]$profile.Descriptions[$script:UiLanguage]
            $statusBox.Text = if ($script:UiLanguage -eq "en") {
                "Difficulty profile applied: $label`r`nOptions changed: $($result.Applied)`r`n$description"
            } else {
                "Profil de difficulte applique: $label`r`nOptions modifiees: $($result.Applied)`r`n$description"
            }
        } catch {
            $statusBox.Text = if ($script:UiLanguage -eq "en") {
                "Profile error: $($_.Exception.Message)"
            } else {
                "Erreur profil: $($_.Exception.Message)"
            }
        }
    })

    $validateBuildButton.Add_Click({
        try {
            Disable-RemovedBuildOptions -Controls $controls
            $validation = Test-GuiBuildConfiguration -Controls $controls -Language $script:UiLanguage
            $statusBox.Text = Format-GuiBuildValidationResult -Validation $validation -Language $script:UiLanguage
            if ($validation.Errors.Count -gt 0) {
                [void](Confirm-GuiBuildValidationResult -Owner $form -Validation $validation -Language $script:UiLanguage -ConfirmWarnings $false)
            } elseif ($validation.Warnings.Count -gt 0) {
                $title = if ($script:UiLanguage -eq "en") { "Config warnings" } else { "Avertissements config" }
                [void][System.Windows.Forms.MessageBox]::Show($form, $statusBox.Text, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            } else {
                $title = if ($script:UiLanguage -eq "en") { "Config OK" } else { "Config OK" }
                [void][System.Windows.Forms.MessageBox]::Show($form, $statusBox.Text, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        } catch {
            $statusBox.Text = "Erreur: $($_.Exception.Message)"
        }
    })

    $buildSummaryButton.Add_Click({
        try {
            Disable-RemovedBuildOptions -Controls $controls
            $validation = Test-GuiBuildConfiguration -Controls $controls -Language $script:UiLanguage
            $statusBox.Text = Format-GuiBuildValidationResult -Validation $validation -Language $script:UiLanguage
            if ($validation.Errors.Count -gt 0) {
                [void](Confirm-GuiBuildValidationResult -Owner $form -Validation $validation -Language $script:UiLanguage -ConfirmWarnings $false)
                return
            }
            $summary = Get-GuiBuildSummaryText -Controls $controls -Validation $validation -Language $script:UiLanguage
            $statusBox.Text = $summary
            [void](Show-GuiBuildSummaryDialog -Owner $form -SummaryText $summary -Language $script:UiLanguage -ConfirmGeneration $false)
        } catch {
            $statusBox.Text = "Erreur: $($_.Exception.Message)"
        }
    })

    Apply-UiLanguage -Language $script:UiLanguage
    Update-InstallationUi
    Update-CompatibilityUi
    Apply-GuiTheme -Root $form -Theme $script:GuiTheme
    Bring-TopChromeToFront
    $form.Add_Shown({ Bring-TopChromeToFront })

    $exportPresetButton.Add_Click({
        try {
            $dialog = New-Object System.Windows.Forms.SaveFileDialog
            $dialog.Filter = "JSON preset (*.json)|*.json|All files (*.*)|*.*"
            $dialog.Title = if ($script:UiLanguage -eq "en") { "Export randomizer preset" } else { "Exporter le preset du randomizer" }
            $dialog.FileName = "PokeFeurRandomSWSH-preset.json"
            if ($dialog.ShowDialog($form) -ne [System.Windows.Forms.DialogResult]::OK) {
                return
            }

            $preset = Get-GuiPresetFromControls -Controls $controls
            $json = $preset | ConvertTo-Json -Depth 8
            [IO.File]::WriteAllText($dialog.FileName, $json, [Text.UTF8Encoding]::new($false))
            $statusBox.Text = if ($script:UiLanguage -eq "en") {
                "Preset exported: $($dialog.FileName)"
            } else {
                "Preset exporte: $($dialog.FileName)"
            }
        } catch {
            $statusBox.Text = if ($script:UiLanguage -eq "en") {
                "Preset export error: $($_.Exception.Message)"
            } else {
                "Erreur export preset: $($_.Exception.Message)"
            }
        }
    })

    $importPresetButton.Add_Click({
        try {
            $dialog = New-Object System.Windows.Forms.OpenFileDialog
            $dialog.Filter = "JSON preset (*.json)|*.json|All files (*.*)|*.*"
            $dialog.Title = if ($script:UiLanguage -eq "en") { "Import randomizer preset" } else { "Importer un preset du randomizer" }
            if ($dialog.ShowDialog($form) -ne [System.Windows.Forms.DialogResult]::OK) {
                return
            }

            $preset = Get-Content -LiteralPath $dialog.FileName -Raw -Encoding UTF8 | ConvertFrom-Json
            $applied = Set-GuiControlsFromPreset -Controls $controls -Preset $preset
            Disable-RemovedBuildOptions -Controls $controls
            Apply-UiLanguage -Language (Get-ComboValue -Combo $controls.UiLanguage)
            Update-InstallationUi
            Update-CompatibilityUi
            Apply-GuiTheme -Root $form -Theme (Get-ComboValue -Combo $controls.GuiTheme)
            Bring-TopChromeToFront
            $statusBox.Text = if ($script:UiLanguage -eq "en") {
                "Preset imported: $($dialog.FileName)`r`nOptions applied: $applied"
            } else {
                "Preset importe: $($dialog.FileName)`r`nOptions appliquees: $applied"
            }
        } catch {
            $statusBox.Text = if ($script:UiLanguage -eq "en") {
                "Preset import error: $($_.Exception.Message)"
            } else {
                "Erreur import preset: $($_.Exception.Message)"
            }
        }
    })

    $resetButton.Add_Click({
        $previousInstallToEden = $script:InstallToEden
        $previousInstallToRyujinx = $script:InstallToRyujinx
        $previousInstallToYuzu = $script:InstallToYuzu
        $previousInstallToSudachi = $script:InstallToSudachi
        $previousInstallToCitron = $script:InstallToCitron
        $previousInstallToSuyu = $script:InstallToSuyu
        $previousInstallToCitronNeo = $script:InstallToCitronNeo
        try {
            $script:InstallToEden = [bool]$controls.ResetInstallToEden.Checked
            $script:InstallToRyujinx = [bool]$controls.ResetInstallToRyujinx.Checked
            $script:InstallToYuzu = [bool]$controls.ResetInstallToYuzu.Checked
            $script:InstallToSudachi = [bool]$controls.ResetInstallToSudachi.Checked
            $script:InstallToCitron = [bool]$controls.ResetInstallToCitron.Checked
            $script:InstallToSuyu = [bool]$controls.ResetInstallToSuyu.Checked
            $script:InstallToCitronNeo = [bool]$controls.ResetInstallToCitronNeo.Checked
            if (@(Get-RequestedEmulatorKeys).Count -lt 1) {
                throw $(if ($script:UiLanguage -eq "en") { "Select at least one emulator target for reset." } else { "Coche au moins une cible emulateur pour le reset." })
            }

            $gameVersion = Get-SourceGameVersion -RomfsRoot $controls.Source.Text
            $resetResults = @(Reset-SelectedEmulatorInstallations -GameVersion $gameVersion -ModName $controls.EdenModName.Text)
            if ($script:UiLanguage -eq "en") {
                $lines = @("Reset finished.")
                foreach ($entry in $resetResults) {
                    if ([string]::IsNullOrWhiteSpace([string]$entry.Error)) {
                        $lines += ("{0}: mod removed={1}, config removed={2}" -f $entry.Emulator, $entry.RemovedMod, $entry.RemovedConfig)
                        if (-not [string]::IsNullOrWhiteSpace([string]$entry.Note)) {
                            $lines += ("{0}: {1}" -f $entry.Emulator, [string]$entry.Note)
                        }
                    } else {
                        $lines += ("{0}: {1}" -f $entry.Emulator, $entry.Error)
                    }
                }
                $resetStatusBox.Text = ($lines -join [Environment]::NewLine)
            } else {
                $lines = @("Reset termine.")
                foreach ($entry in $resetResults) {
                    if ([string]::IsNullOrWhiteSpace([string]$entry.Error)) {
                        $lines += ("{0}: mod supprime={1}, config supprimee={2}" -f $entry.Emulator, $entry.RemovedMod, $entry.RemovedConfig)
                        if (-not [string]::IsNullOrWhiteSpace([string]$entry.Note)) {
                            $lines += ("{0}: {1}" -f $entry.Emulator, [string]$entry.Note)
                        }
                    } else {
                        $lines += ("{0}: {1}" -f $entry.Emulator, $entry.Error)
                    }
                }
                $resetStatusBox.Text = ($lines -join [Environment]::NewLine)
            }
        } catch {
            if ($script:UiLanguage -eq "en") {
                $resetStatusBox.Text = ("Error: {0}" -f $_.Exception.Message)
            } else {
                $resetStatusBox.Text = ("Erreur: {0}" -f $_.Exception.Message)
            }
        } finally {
            $script:InstallToEden = $previousInstallToEden
            $script:InstallToRyujinx = $previousInstallToRyujinx
            $script:InstallToYuzu = $previousInstallToYuzu
            $script:InstallToSudachi = $previousInstallToSudachi
            $script:InstallToCitron = $previousInstallToCitron
            $script:InstallToSuyu = $previousInstallToSuyu
            $script:InstallToCitronNeo = $previousInstallToCitronNeo
            Update-InstallationUi
        }
    })

    $runButton.Add_Click({
        try {
            $ui = Get-UiStrings -Language $script:UiLanguage
            $runButton.Enabled = $false
            $statusBox.Text = if ($script:UiLanguage -eq "en") { "Validating configuration..." } else { "Validation de la configuration..." }
            $form.Refresh()

            Disable-RemovedBuildOptions -Controls $controls
            $validation = Test-GuiBuildConfiguration -Controls $controls -Language $script:UiLanguage
            $statusBox.Text = Format-GuiBuildValidationResult -Validation $validation -Language $script:UiLanguage
            if (-not (Confirm-GuiBuildValidationResult -Owner $form -Validation $validation -Language $script:UiLanguage -ConfirmWarnings $true)) {
                return
            }

            $summary = Get-GuiBuildSummaryText -Controls $controls -Validation $validation -Language $script:UiLanguage
            $statusBox.Text = $summary
            if (-not (Show-GuiBuildSummaryDialog -Owner $form -SummaryText $summary -Language $script:UiLanguage -ConfirmGeneration $true)) {
                return
            }

            $statusBox.Text = $ui.Labels.StatusRunning
            $form.Refresh()

            $seedText = ([string]$controls.Seed.Text).Trim()
            $parsedSeed = 0L
            if (-not [long]::TryParse($seedText, [ref]$parsedSeed)) {
                throw $ui.Labels.SeedError
            }

            $script:SourceRomfs = $controls.Source.Text
            $script:SourceExefs = $controls.SourceExefs.Text
            $script:OutputRomfs = $controls.Output.Text
            $script:GameVersion = Get-ComboValue -Combo $controls.GameVersion
            $script:Seed = Resolve-SeedValue -SeedValue $parsedSeed
            $script:UiLanguage = Get-ComboValue -Combo $controls.UiLanguage
            $script:ReportLanguage = Get-ComboValue -Combo $controls.ReportLanguage
            $script:DisableExpShare = [switch]$controls.DisableExpShare.Checked
            $script:EarlyBike = [switch]$controls.EarlyBike.Checked
            $script:RuntimePcControls = [bool]$controls.RuntimePcControls.Checked
            $script:DynamicExpLevelCap = [switch]$controls.DynamicExpLevelCap.Checked
            $script:StrictBossMaxLevelCap = [switch]$controls.StrictBossMaxLevelCap.Checked
            $script:MainStorySoftLevelCap = [switch]$controls.MainStorySoftLevelCap.Checked
            $script:GymLeagueStoryLevelCap = [switch]$controls.GymLeagueStoryLevelCap.Checked
            $script:StoryMajorBattleOrderLevelCap = [switch]$controls.StoryMajorBattleOrderLevelCap.Checked
            $script:AutoInstallToEden = [switch]$controls.AutoInstallToEden.Checked
            $script:EdenModName = $controls.EdenModName.Text
            $script:InstallToEden = [bool]$controls.InstallToEden.Checked
            $script:InstallToRyujinx = [bool]$controls.InstallToRyujinx.Checked
            $script:InstallToYuzu = [bool]$controls.InstallToYuzu.Checked
            $script:InstallToSudachi = [bool]$controls.InstallToSudachi.Checked
            $script:InstallToCitron = [bool]$controls.InstallToCitron.Checked
            $script:InstallToSuyu = [bool]$controls.InstallToSuyu.Checked
            $script:InstallToCitronNeo = [bool]$controls.InstallToCitronNeo.Checked
            $script:RaceMode = [switch]$controls.RaceMode.Checked
            $script:ExportEncounterZoneReport = [bool]$controls.ExportEncounterZoneReport.Checked
            $script:TrainerSpeciesMode = Get-ComboValue -Combo $controls.TrainerSpeciesMode
            $script:TrainerMoveMode = Get-ComboValue -Combo $controls.TrainerMoveMode
            $script:TrainerSmogonMoveFallbackMode = Get-ComboValue -Combo $controls.TrainerSmogonMoveFallbackMode
            $script:TrainerItemMode = Get-ComboValue -Combo $controls.TrainerItemMode
            $script:TrainerItemPoolMode = Get-ComboValue -Combo $controls.TrainerItemPoolMode
            $script:TrainerAddedSlotSpeciesMode = Get-ComboValue -Combo $controls.TrainerAddedSlotSpeciesMode
            $script:TrainerDuplicateMode = Get-ComboValue -Combo $controls.TrainerDuplicateMode
            $script:TrainerAbilityMode = Get-ComboValue -Combo $controls.TrainerAbilityMode
            $script:TrainerIVMode = Get-ComboValue -Combo $controls.TrainerIVMode
            $script:TrainerEVMode = Get-ComboValue -Combo $controls.TrainerEVMode
            $script:TrainerNatureMode = Get-ComboValue -Combo $controls.TrainerNatureMode
            $script:RandomizeTrainerNatures = [switch]((Get-EffectiveTrainerNatureMode -Mode $script:TrainerNatureMode -LegacyRandomize $false) -eq "random")
            $script:TrainerLevelMultiplier = Convert-GuiDoubleText -Text $controls.TrainerLevelMultiplier.Text -Label $ui.Labels.TrainerLevel -Language $script:UiLanguage
            $script:TrainerTeamMin = [int]$controls.TrainerTeamMin.Text
            $script:TrainerTeamMax = [int]$controls.TrainerTeamMax.Text
            $script:TrainerTypeThemed = [switch]$controls.TrainerTypeThemed.Checked
            $script:TrainerShinyChancePercent = Convert-GuiDoubleText -Text $controls.TrainerShinyChancePercent.Text -Label $ui.Labels.TrainerShinyChance -Language $script:UiLanguage
            $script:ForceTrainerFullyEvolved = [switch]$controls.ForceTrainerFullyEvolved.Checked
            $script:TrainerFullyEvolvedLevel = [int]$controls.TrainerFullyEvolvedLevel.Text
            $script:MaxTrainerAI = [switch]$controls.MaxTrainerAI.Checked
            $script:TrainerDynamaxLevelMode = Get-ComboValue -Combo $controls.TrainerDynamaxLevelMode
            $script:ForceTrainerCanDynamax = [switch]$controls.ForceTrainerCanDynamax.Checked
            $script:ForceAllTeamsToSix = [switch]$controls.ForceAllTeamsToSix.Checked
            $script:ForceBossTeamsToSix = [bool]$controls.ForceBossTeamsToSix.Checked
            $script:BossTeamsToSixScope = Get-ComboValue -Combo $controls.BossTeamsToSixScope
            $script:AllowLegendaryTrainers = [switch]$controls.AllowLegendaryTrainers.Checked
            $script:TypeMode = Get-ComboValue -Combo $controls.TypeMode
            $script:TypesMonotypeOnly = [switch]$controls.TypesMonotypeOnly.Checked
            $script:AbilityMode = Get-ComboValue -Combo $controls.AbilityMode
            $script:AllowWonderGuard = [switch]$controls.AllowWonderGuard.Checked
            $script:StatMode = Get-ComboValue -Combo $controls.StatMode
            $script:ExpYieldMultiplier = Convert-GuiDoubleText -Text $controls.ExpYieldMultiplier.Text -Label $ui.Labels.ExpYieldMultiplier -Language $script:UiLanguage
            $script:ForceOneExpYield = [switch]$controls.ForceOneExpYield.Checked
            $script:RandomizeMoveTypes = [switch]$controls.RandomizeMoveTypes.Checked
            $script:RandomizeMovePower = [switch]$controls.RandomizeMovePower.Checked
            $script:MovePowerMin = [int]$controls.MovePowerMin.Text
            $script:MovePowerMax = [int]$controls.MovePowerMax.Text
            $script:RandomizeMovePP = [switch]$controls.RandomizeMovePP.Checked
            $script:MovePPMin = [int]$controls.MovePPMin.Text
            $script:MovePPMax = [int]$controls.MovePPMax.Text
            $script:RandomizeMoveAccuracy = [switch]$controls.RandomizeMoveAccuracy.Checked
            $script:MoveAccuracyMin = [int]$controls.MoveAccuracyMin.Text
            $script:MoveAccuracyMax = [int]$controls.MoveAccuracyMax.Text
            $script:RandomizeMoveCategory = [switch]$controls.RandomizeMoveCategory.Checked
            $script:RandomizePickupItems = [switch]$controls.RandomizePickupItems.Checked
            $script:RandomizeShopItems = [switch]$controls.RandomizeShopItems.Checked
            $script:RandomizeTechnicalRecords = [switch]$controls.RandomizeTechnicalRecords.Checked
            $script:EvolutionMode = Get-ComboValue -Combo $controls.EvolutionMode
            $script:AllowLegendaryEvolutions = [switch]$controls.AllowLegendaryEvolutions.Checked
            $script:NormalizeFriendshipEvolutions = [bool]$controls.NormalizeFriendshipEvolutions.Checked
            $script:FriendshipEvolutionLevel = [int]$controls.FriendshipEvolutionLevel.Text
            $script:NormalizeTradeEvolutions = [bool]$controls.NormalizeTradeEvolutions.Checked
            $script:TradeEvolutionLevel = [int]$controls.TradeEvolutionLevel.Text
            $script:NormalizeSpecialEvolutions = [bool]$controls.NormalizeSpecialEvolutions.Checked
            $script:SpecialEvolutionLevel = [int]$controls.SpecialEvolutionLevel.Text
            $script:GiftMode = Get-ComboValue -Combo $controls.GiftMode
            $script:StarterMode = Get-ComboValue -Combo $controls.StarterMode
            $script:Starter1 = $controls.Starter1.Text
            $script:Starter2 = $controls.Starter2.Text
            $script:Starter3 = $controls.Starter3.Text
            $script:PatchStarterRelatedTrainers = [bool]$controls.PatchStarterRelatedTrainers.Checked
            $script:AllowLegendaryGifts = [switch]$controls.AllowLegendaryGifts.Checked
            $script:TradeMode = Get-ComboValue -Combo $controls.TradeMode
            $script:AllowLegendaryTrades = [switch]$controls.AllowLegendaryTrades.Checked
            $script:StaticEncounterMode = Get-ComboValue -Combo $controls.StaticEncounterMode
            $script:AllowLegendaryStaticEncounters = [switch]$controls.AllowLegendaryStaticEncounters.Checked
            $script:StaticEncounterStableMapping = Get-ComboValue -Combo $controls.StaticEncounterStableMapping
            $script:GrassEncounterMode = Get-ComboValue -Combo $controls.GrassEncounterMode
            $script:AllowLegendaryGrassEncounters = [switch]$controls.AllowLegendaryGrassEncounters.Checked
            $script:GrassEncounterStableMapping = Get-ComboValue -Combo $controls.GrassEncounterStableMapping
            $script:VisibleEncounterBehavior = Get-ComboValue -Combo $controls.VisibleEncounterBehavior
            $script:UndergroundMode = Get-ComboValue -Combo $controls.UndergroundMode
            $script:AllowLegendaryUnderground = [switch]$controls.AllowLegendaryUnderground.Checked

            $progressLines = New-Object System.Collections.Generic.List[string]
            $progressCallback = {
                param([string]$Message)
                $progressLines.Add($Message)
                while ($progressLines.Count -gt 10) {
                    $progressLines.RemoveAt(0)
                }
                $statusBox.Text = ($progressLines -join [Environment]::NewLine)
                $statusBox.SelectionStart = $statusBox.Text.Length
                $statusBox.ScrollToCaret()
                [System.Windows.Forms.Application]::DoEvents()
            }

            $result = Invoke-Randomization -SourceRomfsRoot $controls.Source.Text -SourceExefsRoot $controls.SourceExefs.Text -OutputRomfsRoot $controls.Output.Text -ProgressCallback $progressCallback

            if ($script:UiLanguage -eq "en") {
                $statusBox.Text = @"
Done.
Output: $($result.Output)
Seed: $($result.Seed)
Personal edited: $($result.PersonalEntriesEdited)
EXP yields edited: $($result.ExpYieldsEdited)
Moves edited: $($result.MovesEdited)
Move types edited: $($result.MoveTypesEdited)
Move powers edited: $($result.MovePowersEdited)
Move PP edited: $($result.MovePPEdited)
Move accuracy edited: $($result.MoveAccuracyEdited)
Move categories edited: $($result.MoveCategoriesEdited)
Pickup items edited: $($result.PickupItemsEdited)
Shop items edited: $($result.ShopItemsEdited)
TM/TR item IDs edited: $($result.TechnicalRecordsEdited)
Trainers edited: $($result.TrainersEdited)
Trainer Pokemon processed: $($result.TrainerPokemonProcessed)
Boss teams expanded to 6: $($result.BossTeamsExpanded)
Boss teams normalized to strict cap: $($result.BossTeamsLevelNormalized)
Trainer shinies forced: $($result.TrainerShiniesForced)
Trainer Pokemon force-evolved: $($result.TrainerSpeciesForceEvolved)
Type-themed trainer teams: $($result.TrainerTypeThemedTrainers)
Trainer AI maxed: $($result.TrainerAIMaxed)
Trainer Dynamax levels edited: $($result.TrainerDynamaxLevelsEdited)
Trainer CanDynamax flags forced: $($result.TrainerDynamaxFlagsForced)
Trainer detailed changes logged: $($result.TrainerChangesLogged)
Evolutions edited: $($result.EvolutionsEdited)
Friendship evolutions normalized: $($result.FriendshipEvolutionsNormalized)
Trade evolutions normalized: $($result.TradeEvolutionsNormalized)
Special evolutions normalized: $($result.SpecialEvolutionsNormalized)
Gifts edited: $($result.GiftsEdited)
Starters edited: $($result.StartersEdited)
Starter-related trainer files patched: $($result.StarterRelatedTrainerFilesEdited)
Starter-related trainer slots patched: $($result.StarterRelatedTrainerSlotsEdited)
In-game trade slots edited: $($result.TradeSpeciesSlotsEdited)
Static encounters edited: $($result.StaticEncountersEdited)
Tall grass slots edited: $($result.GrassEncounterSlotsEdited)
Underground slots edited: $($result.UndergroundSpeciesSlotsEdited)
Wild detailed changes logged: $($result.WildChangesLogged)
JSON: $($result.JsonReportPath)
Trainer changes JSON: $($result.TrainerChangesReportPath)
Wild changes JSON: $($result.WildChangesReportPath)
Item changes JSON: $($result.ItemChangesReportPath)
Encounter zones JSON: $($result.EncounterZoneReportPath)
Seed summary JSON: $($result.SeedSummaryReportPath)
Race summary JSON: $($result.RaceSummaryReportPath)
Spoiler log JSON: $($result.SpoilerLogReportPath)
Level caps JSON: $($result.BossLevelCapsReportPath)
Story gym/champion caps JSON: $($result.StoryGymLeagueCapsReportPath)
Ordered main-story battles JSON: $($result.StoryMajorBattleCapsReportPath)
Disable EXP Share via ExLaunch: $($result.DisableExpSharePatchEnabled)
Dynamic EXP cap IPS files: $($result.DynamicExpLevelCapPatchFilesWritten)
Story gym/champion EXP cap IPS files: $($result.StoryGymLeagueExpCapPatchFilesWritten)
EXP cap requires ExLaunch: $($result.ExpLevelCapRequiresExLaunch)
EXP cap ExLaunch config: $($result.ExpLevelCapExLaunchConfigPath)
ExLaunch module available: $($result.ExLaunchModuleAvailable)
ExLaunch module auto-deployed: $($result.ExLaunchModuleDeployed)
PC runtime controls: $($result.RuntimePcScriptApplied)
ExLaunch module target: $($result.ExLaunchModuleTargetRoot)
Installation folder: $($result.InstallationPackageRoot)
Installation guide: $($result.InstallationPackageReadmePath)
Auto-install requested: $($result.AutoInstallRequested)
Auto-install success count: $($result.AutoInstallSuccessCount)
Auto-install failure count: $($result.AutoInstallFailureCount)
ExeFS IPS files total: $($result.ExeFsPatchFilesWritten)
ExeFS patch root: $($result.ExeFsPatchRoot)
"@
            } else {
                $statusBox.Text = @"
Termine.
Sortie: $($result.Output)
Seed: $($result.Seed)
Personal modifies: $($result.PersonalEntriesEdited)
EXP donnees modifiees: $($result.ExpYieldsEdited)
Attaques modifiees: $($result.MovesEdited)
Types d'attaques modifies: $($result.MoveTypesEdited)
Puissances d'attaques modifiees: $($result.MovePowersEdited)
PP d'attaques modifies: $($result.MovePPEdited)
Precisions d'attaques modifiees: $($result.MoveAccuracyEdited)
Categories d'attaques modifiees: $($result.MoveCategoriesEdited)
Objets ramassables modifies: $($result.PickupItemsEdited)
Objets boutiques modifies: $($result.ShopItemsEdited)
Objets CT/TR modifies: $($result.TechnicalRecordsEdited)
Trainers modifies: $($result.TrainersEdited)
Pokemon de dresseurs traites: $($result.TrainerPokemonProcessed)
Boss etendus a 6: $($result.BossTeamsExpanded)
Equipes boss normalisees au cap strict: $($result.BossTeamsLevelNormalized)
Shinies dresseurs forces: $($result.TrainerShiniesForced)
Pokemon de dresseurs forces au stade final: $($result.TrainerSpeciesForceEvolved)
Equipes dresseurs themees par type: $($result.TrainerTypeThemedTrainers)
IA dresseurs maxees: $($result.TrainerAIMaxed)
Niveaux Dynamax dresseurs modifies: $($result.TrainerDynamaxLevelsEdited)
Flags CanDynamax dresseurs forces: $($result.TrainerDynamaxFlagsForced)
Changements detailles dresseurs journalises: $($result.TrainerChangesLogged)
Evolutions modifiees: $($result.EvolutionsEdited)
Evolutions amitie normalisees: $($result.FriendshipEvolutionsNormalized)
Evolutions echange normalisees: $($result.TradeEvolutionsNormalized)
Evolutions speciales normalisees: $($result.SpecialEvolutionsNormalized)
Gifts modifies: $($result.GiftsEdited)
Starters modifies: $($result.StartersEdited)
Fichiers dresseurs lies aux starters patches: $($result.StarterRelatedTrainerFilesEdited)
Slots dresseurs lies aux starters patches: $($result.StarterRelatedTrainerSlotsEdited)
Slots trades PNJ modifies: $($result.TradeSpeciesSlotsEdited)
Rencontres fixes modifiees: $($result.StaticEncountersEdited)
Slots hautes herbes modifies: $($result.GrassEncounterSlotsEdited)
Slots underground modifies: $($result.UndergroundSpeciesSlotsEdited)
Changements detailles nature journalises: $($result.WildChangesLogged)
JSON: $($result.JsonReportPath)
JSON changements dresseurs: $($result.TrainerChangesReportPath)
JSON changements nature: $($result.WildChangesReportPath)
JSON changements objets: $($result.ItemChangesReportPath)
JSON zones rencontres: $($result.EncounterZoneReportPath)
JSON resume seed: $($result.SeedSummaryReportPath)
JSON race: $($result.RaceSummaryReportPath)
JSON spoiler log: $($result.SpoilerLogReportPath)
JSON caps boss: $($result.BossLevelCapsReportPath)
JSON caps histoire arenes/Tarak: $($result.StoryGymLeagueCapsReportPath)
JSON combats majeurs ordre histoire: $($result.StoryMajorBattleCapsReportPath)
EXP Share via ExLaunch: $($result.DisableExpSharePatchEnabled)
Fichiers IPS levelcap EXP dynamique: $($result.DynamicExpLevelCapPatchFilesWritten)
Fichiers IPS cap EXP histoire arenes/Tarak: $($result.StoryGymLeagueExpCapPatchFilesWritten)
Cap EXP requiert ExLaunch: $($result.ExpLevelCapRequiresExLaunch)
Config ExLaunch cap EXP: $($result.ExpLevelCapExLaunchConfigPath)
Module ExLaunch disponible: $($result.ExLaunchModuleAvailable)
Module ExLaunch auto-deploye: $($result.ExLaunchModuleDeployed)
Controle runtime via PC: $($result.RuntimePcScriptApplied)
Destination module ExLaunch: $($result.ExLaunchModuleTargetRoot)
Dossier Installation: $($result.InstallationPackageRoot)
Guide Installation: $($result.InstallationPackageReadmePath)
Installation auto demandee: $($result.AutoInstallRequested)
Installations auto reussies: $($result.AutoInstallSuccessCount)
Installations auto en echec: $($result.AutoInstallFailureCount)
Fichiers IPS ExeFS total: $($result.ExeFsPatchFilesWritten)
Dossier patchs ExeFS: $($result.ExeFsPatchRoot)
"@
            }
            $message = if ($script:UiLanguage -eq "en") { "Generation complete." } else { "Generation terminee." }
            [void][System.Windows.Forms.MessageBox]::Show($form, $message, $form.Text, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            $statusBox.Text = "Erreur: $($_.Exception.Message)"
        } finally {
            $runButton.Enabled = $true
        }
    })

    [void]$form.ShowDialog()
}

Write-LauncherIfMissing

if ($NoGui -or $PSBoundParameters.ContainsKey("SourceRomfs")) {
    if (-not $SourceRomfs) { throw "Dossier ROMFS obligatoire: passe -SourceRomfs avec le dossier romfs du dump utilisateur." }
    if (-not $OutputRomfs) { $OutputRomfs = Get-DefaultOutputRomfsPath -GameVersion $GameVersion }
    $result = Invoke-Randomization -SourceRomfsRoot $SourceRomfs -SourceExefsRoot $SourceExefs -OutputRomfsRoot $OutputRomfs
    $result | Format-List | Out-String | Write-Output
} else {
    Show-Gui
}
