#requires -Version 5.1
<#
    Premiers tests de la LOGIQUE de randomisation.

    Jusqu'ici, le seul filet du projet portait sur l'interface. Le coeur - ce
    que le generateur ecrit reellement dans le ROMFS - n'etait couvert par rien.
    C'est pourtant la que vit le defaut consigne dans COMBAT-CACHE §15 : une
    regle de dresseur rendue TOTALEMENT inoperante par une collection PowerShell
    vide devenue $null, qui rapportait pourtant « applies = True ». Elle n'a ete
    trouvee qu'en mesurant les fichiers de sortie.

    Trois proprietes, verifiees par comparaison de sorties completes :

      1. DETERMINISME - meme graine, memes options : sortie identique au bit
         pres. Sans ca, une seed partagee ne veut rien dire.
      2. SENSIBILITE A LA GRAINE - graine differente : sortie differente.
      3. EFFET REEL - chaque option touche LE fichier qu'elle est censee
         toucher. Pas « quelque chose a change » : le bon fichier a change.

    La troisieme est la plus severe, et c'est voulu. « Quelque chose a change »
    est un signal faible : le generateur tire ses nombres dans un flux unique,
    donc toute option qui consomme du hasard decale tout ce qui suit. Une option
    parfaitement inerte pourrait ainsi faire bouger la sortie sans rien faire.
    Nommer le fichier attendu ferme cette porte.

    LENT : chaque generation prend une quarantaine de secondes, et cette suite
    en fait trente-six. Elle porte l'etiquette « Lent » et ne tourne pas par defaut :

        powershell -ExecutionPolicy Bypass -File tools/run-tests.ps1 -Lentes
#>

. (Join-Path $PSScriptRoot '..\tools\gen-harness.ps1')

Describe "Randomisation" -Tag 'Lent' {

    $romfs = Get-PfDumpRomfs
    if (-not $romfs) {
        It "necessite un dump ROMFS" {
            Set-TestInconclusive -Message "Aucun dump : definis PF_TEST_ROMFS."
        }
        return
    }

    Write-Host ("  dump : " + $romfs)
    $reference = Invoke-PfGeneration -Options @{ Seed = 777 }
    Write-Host ("  reference : {0} fichiers en {1}s" -f $reference.Fichiers, $reference.Secondes)

    Context "La graine gouverne la sortie" {
        It "produit exactement la meme sortie pour la meme graine" {
            $bis = Invoke-PfGeneration -Options @{ Seed = 777 }
            try {
                Write-Host ("  {0} fichiers, {1}s" -f $bis.Fichiers, $bis.Secondes)
                $bis.CodeSortie | Should Be 0
                $bis.Fichiers | Should Be $reference.Fichiers
                $bis.Global | Should Be $reference.Global
            } finally { Remove-PfGeneration $bis }
        }

        It "produit une sortie differente pour une autre graine" {
            $autre = Invoke-PfGeneration -Options @{ Seed = 999 }
            try {
                $differents = Compare-PfGenerations -A $reference -B $autre
                Write-Host ("  {0} fichier(s) different(s)" -f $differents.Count)
                $differents.Count | Should BeGreaterThan 0
            } finally { Remove-PfGeneration $autre }
        }
    }

    Context "Chaque option touche le fichier qu'elle annonce" {
        # Motifs releves en mesurant, pas devines. Une option qui cesserait de
        # toucher son fichier - le defaut du COMBAT-CACHE §15 - fait echouer le
        # test meme si elle continue de decaler le reste de la sortie.
        $cas = @(
            @{ Nom = 'MinimumCatchRate';   Opt = @{ Seed = 777; MinimumCatchRate = 200 };            Motif = 'personal_total.bin'; Exact = $true },
            @{ Nom = 'TmCompatibilityMode'; Opt = @{ Seed = 777; TmCompatibilityMode = 'Full' };     Motif = 'personal_total.bin'; Exact = $true },
            @{ Nom = 'TrainerSpeciesMode'; Opt = @{ Seed = 777; TrainerSpeciesMode = 'Unchanged' };  Motif = 'trainer_poke';       Exact = $false },
            @{ Nom = 'EvolutionMode';      Opt = @{ Seed = 777; EvolutionMode = 'Random' };          Motif = 'evolution';          Exact = $false },
            @{ Nom = 'GrassEncounterMode'; Opt = @{ Seed = 777; GrassEncounterMode = 'Random' };     Motif = 'data_table.gfpak';   Exact = $false },
            @{ Nom = 'StarterMode';        Opt = @{ Seed = 777; StarterMode = 'Random' };            Motif = 'add_poke.bin';       Exact = $false },
            @{ Nom = 'TmMoveMode';         Opt = @{ Seed = 777; TmMoveMode = 'Shuffle' };            Motif = 'item.dat';           Exact = $false },
            @{ Nom = 'LearnsetMoveMode';   Opt = @{ Seed = 777; LearnsetMoveMode = 'Shuffle' };      Motif = 'wazaoboe_total.bin'; Exact = $false },
            @{ Nom = 'TutorCompatibilityMode'; Opt = @{ Seed = 777; TutorCompatibilityMode = 'Full' }; Motif = 'personal_total.bin'; Exact = $true },
            # Mesure, pas supposition : ces deux-la s appliquent AVANT les
            # dresseurs, donc elles decalent le flux aleatoire et font bouger les
            # 436 trainer_poke en plus de leur propre fichier. Les trois options
            # "Exact" ci-dessus passent apres, d ou leur unique fichier.
            @{ Nom = 'TypeMode';           Opt = @{ Seed = 777; TypeMode = 'Random' };               Motif = 'personal_total.bin'; Exact = $false },
            @{ Nom = 'AbilityMode';        Opt = @{ Seed = 777; AbilityMode = 'Random' };            Motif = 'personal_total.bin'; Exact = $false },
            @{ Nom = 'RandomizeMovePower'; Opt = @{ Seed = 777; RandomizeMovePower = $true };        Motif = 'pml\waza\';          Exact = $false },
            @{ Nom = 'GiftMode';           Opt = @{ Seed = 777; GiftMode = 'Random' };               Motif = 'add_poke.bin';       Exact = $false },
            @{ Nom = 'TradeMode';          Opt = @{ Seed = 777; TradeMode = 'Random' };              Motif = 'field_trade.bin';    Exact = $false },
            @{ Nom = 'StaticEncounterMode'; Opt = @{ Seed = 777; StaticEncounterMode = 'Random' };   Motif = 'event_encount_data.bin'; Exact = $false },
            @{ Nom = 'UndergroundMode';    Opt = @{ Seed = 777; UndergroundMode = 'Random' };        Motif = 'underground_exploration_poke.bin'; Exact = $false },
            @{ Nom = 'RandomizeShopItems'; Opt = @{ Seed = 777; RandomizeShopItems = $true };        Motif = 'shop_data.bin';      Exact = $false },
            @{ Nom = 'RandomizePickupItems'; Opt = @{ Seed = 777; RandomizePickupItems = $true };    Motif = 'underground_exploration_item.prmb'; Exact = $false },
            @{ Nom = 'RandomizeFieldItems'; Opt = @{ Seed = 777; RandomizeFieldItems = $true };      Motif = 'placement.gfpak';    Exact = $false },
            # Les regles speciales de dresseurs ne s'activent pas toutes seules :
            # elles sont conditionnees par $trainerRulesActive (ligne 10461), que
            # TrainerMinBaseStatTotal suffit a declencher.
            @{ Nom = 'TrainerMinBaseStatTotal'; Opt = @{ Seed = 777; TrainerMinBaseStatTotal = 400 }; Motif = 'trainer_poke';      Exact = $false },
            @{ Nom = 'NpcGiftItemMode';    Opt = @{ Seed = 777; NpcGiftItemMode = 'Shuffle' };       Motif = 'script\amx';         Exact = $false }
        )

        foreach ($c in $cas) {
            $nom = $c.Nom
            $opt = $c.Opt
            $motif = $c.Motif
            $exact = $c.Exact
            It "$nom modifie $motif" {
                $g = Invoke-PfGeneration -Options $opt
                try {
                    $g.CodeSortie | Should Be 0
                    $differents = @(Compare-PfGenerations -A $reference -B $g)
                    $vises = @($differents | Where-Object { $_ -like "*$motif*" })
                    Write-Host ("  {0} : {1} fichier(s) modifie(s), dont {2} correspondant a «{3}»" -f $nom, $differents.Count, $vises.Count, $motif)
                    $vises.Count | Should BeGreaterThan 0
                    if ($exact) {
                        # Ces options-la ne doivent rien toucher d'autre : elles
                        # ecrivent dans la table Pokemon, point.
                        $differents.Count | Should Be $vises.Count
                    }
                } finally { Remove-PfGeneration $g }
            }
        }
    }

    Context "Les CT et DT gardent une table valide" {
        It "permute les attaques sans toucher les objets ni la taille" {
            # La table des machines vit dans item.dat, juste apres l'en-tete de
            # la table des OBJETS. Ecrire un octet trop loin corromprait les
            # prix. On verifie donc trois choses, pas une : la taille du
            # fichier, la colonne des objets, et le fait que la permutation
            # preserve exactement le meme ensemble d'attaques - ce qui garantit
            # qu'aucune machine n'enseigne une attaque qu'elle ne pourrait pas
            # enseigner.
            $g = Invoke-PfGeneration -Options @{ Seed = 555; TmMoveMode = 'Shuffle' }
            try {
                $g.CodeSortie | Should Be 0
                $source = Join-Path (Get-PfDumpRomfs) 'bin\pml\item\item.dat'
                $cible = Join-Path $g.Sortie 'romfs\bin\pml\item\item.dat'
                (Test-Path -LiteralPath $cible) | Should Be $true

                $lireMachines = {
                    param([string]$chemin)
                    $d = [IO.File]::ReadAllBytes($chemin)
                    $ptr = [BitConverter]::ToUInt16($d, 2)
                    $off = 0x44 + $ptr * 2
                    $objets = @(); $attaques = @()
                    for ($i = 0; $i -lt 200; $i++) {
                        $objets += [int][BitConverter]::ToUInt16($d, $off + $i * 4)
                        $attaques += [int][BitConverter]::ToUInt16($d, $off + $i * 4 + 2)
                    }
                    return @{ Taille = $d.Length; Objets = $objets; Attaques = $attaques }
                }
                $avant = & $lireMachines $source
                $apres = & $lireMachines $cible

                $apres.Taille | Should Be $avant.Taille
                (($apres.Objets -join ',') -eq ($avant.Objets -join ',')) | Should Be $true
                $changees = @(0..199 | Where-Object { $avant.Attaques[$_] -ne $apres.Attaques[$_] }).Count
                Write-Host ("  {0} / 200 machines enseignent une autre attaque" -f $changees)
                $changees | Should BeGreaterThan 0
                $triAvant = ($avant.Attaques | Sort-Object) -join ','
                $triApres = ($apres.Attaques | Sort-Object) -join ','
                ($triApres -eq $triAvant) | Should Be $true
            } finally { Remove-PfGeneration $g }
        }
    }

    Context "Les attaques apprises gardent des paliers coherents" {
        It "permute les attaques sans deplacer un seul niveau" {
            # Un enregistrement de learnset est une suite de paires
            # (attaque, niveau) terminee par FFFF FFFF. Ecrire dans la mauvaise
            # moitie d'une paire ferait apprendre une attaque au niveau 300, ou
            # tronquerait l'enregistrement en fabriquant un FFFF prematur.
            #
            # Trois mesures, pas une : la taille du fichier, la colonne des
            # NIVEAUX prise palier par palier, et le fait que la permutation
            # preserve exactement le meme multi-ensemble d'attaques - ce qui
            # garantit que rien d'inapprenable n'apparait.
            $g = Invoke-PfGeneration -Options @{ Seed = 555; LearnsetMoveMode = 'Shuffle' }
            try {
                $g.CodeSortie | Should Be 0
                $source = Join-Path (Get-PfDumpRomfs) 'bin\pml\waza_oboe\wazaoboe_total.bin'
                $cible = Join-Path $g.Sortie 'romfs\bin\pml\waza_oboe\wazaoboe_total.bin'
                (Test-Path -LiteralPath $cible) | Should Be $true

                $taille = 0x104
                $lire = {
                    param([string]$chemin)
                    $d = [IO.File]::ReadAllBytes($chemin)
                    $attaques = New-Object System.Collections.Generic.List[int]
                    $niveaux = New-Object System.Collections.Generic.List[string]
                    $n = [int]($d.Length / $taille)
                    for ($i = 0; $i -lt $n; $i++) {
                        $base = $i * $taille
                        for ($c = 0; $c -lt $taille; $c += 4) {
                            $a = [BitConverter]::ToUInt16($d, $base + $c)
                            $lv = [BitConverter]::ToUInt16($d, $base + $c + 2)
                            if ($a -eq 0xFFFF -and $lv -eq 0xFFFF) { break }
                            # Le palier est repere par sa position : deux
                            # enregistrements de longueurs differentes ne
                            # peuvent pas se compenser l'un l'autre.
                            $niveaux.Add("$i.$c=$lv")
                            if ($a -ne 0) { $attaques.Add([int]$a) }
                        }
                    }
                    return @{ Taille = $d.Length; Enr = $n; Attaques = $attaques; Niveaux = $niveaux }
                }
                $avant = & $lire $source
                $apres = & $lire $cible

                $apres.Taille | Should Be $avant.Taille
                $apres.Enr | Should Be $avant.Enr
                (($apres.Niveaux -join '|') -eq ($avant.Niveaux -join '|')) | Should Be $true

                $apres.Attaques.Count | Should Be $avant.Attaques.Count
                $changees = 0
                for ($i = 0; $i -lt $avant.Attaques.Count; $i++) {
                    if ($avant.Attaques[$i] -ne $apres.Attaques[$i]) { $changees++ }
                }
                Write-Host ("  {0} / {1} paliers enseignent une autre attaque, sur {2} especes" -f $changees, $avant.Attaques.Count, $avant.Enr)
                $changees | Should BeGreaterThan 0

                $triAvant = ($avant.Attaques | Sort-Object) -join ','
                $triApres = ($apres.Attaques | Sort-Object) -join ','
                ($triApres -eq $triAvant) | Should Be $true
            } finally { Remove-PfGeneration $g }
        }
    }

    Context "Les maitres de capacites restent dans leurs 18 bits" {
        It "n'ecrit que les 18 bits de tuteur, et rien autour" {
            # Le champ des maitres vit a 0xA8 et ne fait que 18 bits : les 6
            # bits hauts de 0xAA et les cinq octets suivants appartiennent a
            # autre chose. Un decalage d'un bit corromprait ces champs sans
            # rien casser de visible. On mesure donc l'octet exact, et pas
            # seulement « le fichier a change ».
            $g = Invoke-PfGeneration -Options @{ Seed = 555; TutorCompatibilityMode = 'Full' }
            try {
                $g.CodeSortie | Should Be 0
                $source = Join-Path (Get-PfDumpRomfs) 'bin\pml\personal\personal_total.bin'
                $cible = Join-Path $g.Sortie 'romfs\bin\pml\personal\personal_total.bin'
                (Test-Path -LiteralPath $cible) | Should Be $true

                $avant = [IO.File]::ReadAllBytes($source)
                $apres = [IO.File]::ReadAllBytes($cible)
                $apres.Length | Should Be $avant.Length

                $taille = 0xB0
                $n = [int]($avant.Length / $taille)
                $horsChamp = 0
                $complets = 0
                $reels = 0
                for ($i = 0; $i -lt $n; $i++) {
                    $b = $i * $taille
                    # Tout ce qui n'est pas les trois octets du champ doit etre
                    # identique au bit pres.
                    for ($o = 0xA8; $o -lt $taille; $o++) {
                        if ($o -le 0xAA) { continue }
                        if ($avant[$b + $o] -ne $apres[$b + $o]) { $horsChamp++ }
                    }
                    # Les 6 bits hauts de 0xAA n'appartiennent pas au champ.
                    if (($avant[$b + 0xAA] -band 0xFC) -ne ($apres[$b + 0xAA] -band 0xFC)) { $horsChamp++ }

                    $vivant = $false
                    for ($o = 0; $o -lt 6; $o++) { if ($avant[$b + $o] -ne 0) { $vivant = $true } }
                    if (-not $vivant) { continue }
                    $reels++
                    if ($apres[$b + 0xA8] -eq 0xFF -and $apres[$b + 0xA9] -eq 0xFF -and ($apres[$b + 0xAA] -band 0x03) -eq 0x03) { $complets++ }
                }
                Write-Host ("  {0} / {1} especes reelles ouvertes aux 18 maitres, {2} octet(s) touche(s) hors champ" -f $complets, $reels, $horsChamp)
                $horsChamp | Should Be 0
                $complets | Should Be $reels
            } finally { Remove-PfGeneration $g }
        }
    }

    Context "Les objets donnes aux dresseurs existent" {
        It "ne distribue aucun objet absent du jeu, et les deux pools different" {
            # Sans items.csv, Get-TrainerItemPool retombait sur une liste codee
            # en dur de 139 identifiants. Mesure : 45 d'entre eux (32 %) ne
            # correspondent a AUCUN objet d'Epee - ce sont des objets d'autres
            # generations - et 7 sont des CT/DT, qu'un Pokemon ne peut pas tenir
            # utilement. Le repli ignorait en outre le mode demande, donc
            # « Combat » et « Complet » rendaient exactement la meme liste.
            #
            # Ce test verifie les trois proprietes d'un coup : tout objet donne
            # existe, aucun n'est une machine / un objet cle / une Ball, et les
            # deux modes ne rendent pas la meme chose.
            $csv = Join-Path (Split-Path -Parent $PSScriptRoot) 'items.csv'
            if (-not (Test-Path -LiteralPath $csv)) {
                Set-TestInconclusive -Message "items.csv absent : python tools/build-items-csv.py <romfs>"
                return
            }
            $poche = @{}
            foreach ($r in (Import-Csv -LiteralPath $csv -Encoding UTF8)) { $poche[[int]$r.id] = [int]$r.category_id }

            $lire = {
                param([string]$mode)
                $g = Invoke-PfGeneration -Options @{ Seed = 321; TrainerItemMode = 'ForceAll'; TrainerItemPoolMode = $mode }
                try {
                    if ($g.CodeSortie -ne 0) { throw ("generation en echec (code {0})" -f $g.CodeSortie) }
                    $vus = @{}
                    $dir = Join-Path $g.Sortie 'romfs\bin\trainer\trainer_poke'
                    foreach ($f in (Get-ChildItem -LiteralPath $dir -Filter '*.bin' -File)) {
                        $b = [IO.File]::ReadAllBytes($f.FullName)
                        for ($s = 0; $s -lt [int]($b.Length / 0x20); $s++) {
                            $it = [int][BitConverter]::ToUInt16($b, $s * 0x20 + 0x10)
                            if ($it -gt 0) { $vus[$it] = $true }
                        }
                    }
                    return @($vus.Keys | Sort-Object)
                } finally { Remove-PfGeneration $g }
            }

            $combat = @(& $lire 'Battle')
            $complet = @(& $lire 'FullRandom')
            foreach ($jeu in @(@{ N = 'Combat'; V = $combat }, @{ N = 'Complet'; V = $complet })) {
                $fantomes = @($jeu.V | Where-Object { -not $poche.ContainsKey([int]$_) })
                # 5 machines, 8 objets cles, 33 Poke Balls : les trois seules
                # poches dont build-items-csv.py prouve l'identite.
                $interdits = @($jeu.V | Where-Object { $poche.ContainsKey([int]$_) -and ($poche[[int]$_] -in @(5, 8, 33)) })
                Write-Host ("  {0,-8} : {1} objets distincts, {2} inexistant(s), {3} machine(s)/cle(s)/Ball(s)" -f $jeu.N, $jeu.V.Count, $fantomes.Count, $interdits.Count)
                $fantomes.Count | Should Be 0
                $interdits.Count | Should Be 0
            }
            ($combat.Count -eq $complet.Count) | Should Be $false
            $complet.Count | Should BeGreaterThan $combat.Count
        }
    }

    Context "Les cadeaux des PNJ restent jouables" {
        It "ne touche aucun objet cle et ne deplace aucune cellule" {
            # Les scripts du jeu sont des modules Pawn 64 bits en encodage
            # compact. Reecrire une cellule change sa longueur en octets, donc
            # la taille du fichier - mais PAS l'image memoire etendue, ou la
            # cellule N est toujours au meme rang. C'est cette propriete qui
            # rend le patch sur : si le nombre de cellules bougeait, toutes les
            # cibles de saut du script seraient decalees et le jeu planterait.
            #
            # Et surtout : 38 des 120 cadeaux sont des objets CLES - Velo Rotom,
            # Bracelet Dynamax, Recommandation, Lien Boite Pokemon. En remplacer
            # un rendrait la partie infinissable. Le test le verifie a l'octet.
            $racine = Split-Path -Parent $PSScriptRoot
            $cat = Join-Path $racine 'npc-gifts.csv'
            $items = Join-Path $racine 'items.csv'
            if (-not (Test-Path -LiteralPath $cat) -or -not (Test-Path -LiteralPath $items)) {
                Set-TestInconclusive -Message "npc-gifts.csv ou items.csv absent : voir tools/build-npc-gifts.py"
                return
            }
            $poche = @{}
            foreach ($r in (Import-Csv -LiteralPath $items -Encoding UTF8)) { $poche[[int]$r.id] = [int]$r.category_id }
            $cadeaux = @(Import-Csv -LiteralPath $cat -Encoding UTF8)

            $cellules = {
                param([string]$chemin)
                $d = [IO.File]::ReadAllBytes($chemin)
                $size = [BitConverter]::ToUInt32($d, 0)
                $cod = [BitConverter]::ToUInt32($d, 0x0C)
                $hea = [BitConverter]::ToUInt32($d, 0x14)
                if ($size -ne $d.Length) { throw ("en-tete incoherent : {0}" -f $chemin) }
                $out = New-Object System.Collections.Generic.List[UInt64]
                $i = [int]$size
                while ($i -gt [int]$cod) {
                    $c = [UInt64]0; $sh = 0
                    while ($true) {
                        $i--
                        $c = $c -bor ([UInt64]($d[$i] -band 0x7F) -shl $sh); $sh += 7
                        if ($i -le [int]$cod -or ($d[$i - 1] -band 0x80) -eq 0) { break }
                    }
                    if (($d[$i] -band 0x40) -ne 0) {
                        while ($sh -lt 64) { $c = $c -bor ([UInt64]0xFF -shl $sh); $sh += 8 }
                    }
                    $out.Add($c)
                }
                $out.Reverse()
                return @{ Cellules = $out; Attendu = [int](($hea - $cod) / 8) }
            }

            $g = Invoke-PfGeneration -Options @{ Seed = 909; NpcGiftItemMode = 'Shuffle' }
            try {
                $g.CodeSortie | Should Be 0
                $srcDir = Join-Path (Get-PfDumpRomfs) 'bin\script\amx'
                $dstDir = Join-Path $g.Sortie 'romfs\bin\script\amx'
                (Test-Path -LiteralPath $dstDir) | Should Be $true

                $cache = @{}
                $changes = 0; $clesTouchees = 0; $opcodes = 0; $comptes = 0; $examines = 0
                $avant = @{}; $apres = @{}
                foreach ($e in $cadeaux) {
                    $dst = Join-Path $dstDir $e.amx
                    if (-not (Test-Path -LiteralPath $dst)) { continue }
                    if (-not $cache.ContainsKey($e.amx)) {
                        $cache[$e.amx] = @{
                            A = (& $cellules (Join-Path $srcDir $e.amx))
                            B = (& $cellules $dst)
                        }
                    }
                    $a = $cache[$e.amx].A; $b = $cache[$e.amx].B
                    if ($a.Cellules.Count -ne $b.Cellules.Count -or $b.Cellules.Count -ne $b.Attendu) { $comptes++; continue }
                    $v = $b.Cellules[[int]$e.cellule]
                    # 0xFFFFFFFFL et non 0xFFFFFFFF : PowerShell interprete le
                    # second comme un [int] valant -1, donc le masque ne masque
                    # RIEN et l'opcode ne peut jamais tomber juste. Le test
                    # rapportait « 120 opcodes casses » sur des cellules
                    # parfaitement valides - le decodeur etait bon, le masque
                    # etait faux.
                    if (($v -band 0xFFFFFFFFL) -ne 0xBC) { $opcodes++; continue }
                    $examines++
                    $vieux = [int]$e.item_id
                    $neuf = [int](($v -shr 32) -band 0xFFFFFFFFL)
                    if (-not $avant.ContainsKey($vieux)) { $avant[$vieux] = 0 }
                    if (-not $apres.ContainsKey($neuf)) { $apres[$neuf] = 0 }
                    $avant[$vieux]++; $apres[$neuf]++
                    if ($neuf -ne $vieux) {
                        $changes++
                        # 8 = poche des objets cles, prouvee par le prix nul sur les 47.
                        if ($poche.ContainsKey($vieux) -and $poche[$vieux] -eq 8) { $clesTouchees++ }
                    }
                }
                Write-Host ("  {0} cadeaux examines, {1} changes, {2} objet(s) cle(s) touche(s), {3} opcode(s) casse(s), {4} module(s) au compte faux" -f $examines, $changes, $clesTouchees, $opcodes, $comptes)
                $examines | Should Be $cadeaux.Count
                $changes | Should BeGreaterThan 0
                $clesTouchees | Should Be 0
                $opcodes | Should Be 0
                $comptes | Should Be 0

                # « Permuter » redistribue : le multi-ensemble des objets NON cles
                # doit etre exactement le meme avant et apres.
                $triA = (($avant.Keys | Where-Object { $poche[$_] -ne 8 } | ForEach-Object { "$_x$($avant[$_])" }) | Sort-Object) -join ','
                $triB = (($apres.Keys | Where-Object { $poche[$_] -ne 8 } | ForEach-Object { "$_x$($apres[$_])" }) | Sort-Object) -join ','
                ($triA -eq $triB) | Should Be $true
            } finally { Remove-PfGeneration $g }
        }
    }

    Context "Les attaques distribuees existent vraiment" {
        It "ne donne jamais une entree croupion aux dresseurs" {
            # bin/pml/waza contient 827 entrees, mais 39 d'entre elles sont des
            # CROUPIONS : leur enregistrement fait 64 octets ou moins au lieu de
            # 68 au minimum pour une vraie attaque. Le bloc contigu 622-657 en
            # fait partie - ce sont les attaques Z, presentes en donnees et
            # retirees en 8e generation.
            #
            # Le seuil est mesure, pas devine : en croisant la taille de chaque
            # enregistrement avec l'usage reel du jeu (learnsets, equipes de
            # dresseurs, table CT/DT), AUCUNE des 39 entrees <= 64 octets n'est
            # utilisee nulle part, et l'usage commence exactement a 68 octets.
            #
            # Get-MovePool rendait 1..826 en aveugle : le mode « 4 attaques
            # aleatoires » distribuait donc ces croupions dans 8 % des
            # emplacements. Trouve en relisant les sorties avec le dex du
            # visualiseur PokeFeur, qui ne savait pas les nommer.
            $wazaDir = Join-Path (Get-PfDumpRomfs) 'bin\pml\waza'
            $croupions = [System.Collections.Generic.HashSet[int]]::new()
            foreach ($f in (Get-ChildItem -LiteralPath $wazaDir -Filter '*.wazabin' -File)) {
                if ($f.Length -le 64 -and $f.BaseName -match '(\d+)\s*$') {
                    $null = $croupions.Add([int]$Matches[1])
                }
            }
            Write-Host ("  {0} entrees croupion relevees dans le dump" -f $croupions.Count)
            $croupions.Count | Should BeGreaterThan 0

            $g = Invoke-PfGeneration -Options @{ Seed = 4321; TrainerMoveMode = 'Random4'; TrainerSpeciesMode = 'Random' }
            try {
                $g.CodeSortie | Should Be 0
                $dir = Join-Path $g.Sortie 'romfs\bin\trainer\trainer_poke'
                $mauvaises = 0
                $total = 0
                foreach ($f in (Get-ChildItem -LiteralPath $dir -Filter '*.bin' -File)) {
                    $b = [IO.File]::ReadAllBytes($f.FullName)
                    for ($s = 0; $s -lt [int]($b.Length / 0x20); $s++) {
                        foreach ($o in 0x12, 0x14, 0x16, 0x18) {
                            $m = [int][BitConverter]::ToUInt16($b, $s * 0x20 + $o)
                            if ($m -le 0) { continue }
                            $total++
                            if ($croupions.Contains($m)) { $mauvaises++ }
                        }
                    }
                }
                Write-Host ("  {0} attaques distribuees, dont {1} croupion(s)" -f $total, $mauvaises)
                $total | Should BeGreaterThan 0
                $mauvaises | Should Be 0
            } finally { Remove-PfGeneration $g }
        }
    }

    Context "« Preferer le meme type » fait ce qu il annonce" {
        It "autorise surtout les machines du type de l espece" {
            # Sans mesure, ce mode aurait pu rester INERTE sans que rien ne le
            # dise : sa premiere version lisait la table des machines dans le
            # ROMFS de SORTIE, ou item.dat n est copie que si une autre option
            # le touche. La table revenait vide et le code retombait en silence
            # sur le tirage a pile ou face - 50 % des deux cotes, soit
            # exactement « Une chance sur deux ». Corrige en lisant la source.
            #
            # Le test compare donc les DEUX populations : si l ecart disparait,
            # le mode est redevenu inerte.
            $romfs = Get-PfDumpRomfs
            $g = Invoke-PfGeneration -Options @{ Seed = 606; TmCompatibilityMode = 'SameType' }
            try {
                $g.CodeSortie | Should Be 0

                # Type de chaque attaque : table FlatBuffers, champ 3.
                $typeDe = @{}
                foreach ($f in (Get-ChildItem -LiteralPath (Join-Path $romfs 'bin\pml\waza') -Filter '*.wazabin' -File)) {
                    if ($f.Length -le 64 -or $f.BaseName -notmatch '(\d+)\s*$') { continue }
                    $id = [int]$Matches[1]
                    $d = [IO.File]::ReadAllBytes($f.FullName)
                    $t = [int][BitConverter]::ToUInt32($d, 0)
                    $vt = $t - [int][BitConverter]::ToInt32($d, $t)
                    $tvt = [int][BitConverter]::ToUInt16($d, $vt)
                    $v = 0
                    if ((4 + 3 * 2 + 2) -le $tvt) {
                        $o = [int][BitConverter]::ToUInt16($d, $vt + 4 + 3 * 2)
                        if ($o -ne 0) { $v = [int]$d[$t + $o] }
                    }
                    $typeDe[$id] = $v
                }

                $it = [IO.File]::ReadAllBytes((Join-Path $romfs 'bin\pml\item\item.dat'))
                $off = 0x44 + ([int][BitConverter]::ToUInt16($it, 2) * 2)
                $mach = @(0..199 | ForEach-Object { [int][BitConverter]::ToUInt16($it, $off + $_ * 4 + 2) })

                $p = [IO.File]::ReadAllBytes((Join-Path $g.Sortie 'romfs\bin\pml\personal\personal_total.bin'))
                $memeOk = 0; $memeTot = 0; $autreOk = 0; $autreTot = 0
                for ($i = 0; ($i + 0xB0) -le $p.Length; $i += 0xB0) {
                    $somme = 0
                    for ($o = 0; $o -lt 6; $o++) { $somme += $p[$i + $o] }
                    if ($somme -eq 0) { continue }
                    $t1 = [int]$p[$i + 6]; $t2 = [int]$p[$i + 7]
                    for ($k = 0; $k -lt 200; $k++) {
                        $base = $i + $(if ($k -lt 100) { 0x28 } else { 0x3C })
                        $idx = $k % 100
                        $bit = ([int]$p[$base + [int][Math]::Floor($idx / 8)] -shr ($idx % 8)) -band 1
                        $mt = if ($typeDe.ContainsKey($mach[$k])) { [int]$typeDe[$mach[$k]] } else { -1 }
                        if ($mt -ge 0 -and ($mt -eq $t1 -or $mt -eq $t2)) { $memeTot++; $memeOk += $bit }
                        else { $autreTot++; $autreOk += $bit }
                    }
                }
                $tauxMeme = [int](100 * $memeOk / [Math]::Max(1, $memeTot))
                $tauxAutre = [int](100 * $autreOk / [Math]::Max(1, $autreTot))
                Write-Host ("  meme type {0}% ({1}/{2})  |  autre type {3}% ({4}/{5})" -f $tauxMeme, $memeOk, $memeTot, $tauxAutre, $autreOk, $autreTot)
                $memeTot | Should BeGreaterThan 1000
                $tauxMeme | Should BeGreaterThan 80
                $tauxAutre | Should BeLessThan 20
            } finally { Remove-PfGeneration $g }
        }
    }

    Context "Le tirage integral ouvre tout le repertoire" {
        It "sort des attaques que le jeu n enseigne jamais par niveau" {
            # « Tirage aleatoire » pioche dans les attaques DEJA presentes dans
            # la table des montees de niveau : 610 sur les 787 que compte le jeu
            # hors croupions. 177 attaques - Poing Karate, Coupe-Vent, Sonic
            # Boom, Draco-Rage - ne pouvaient donc jamais en sortir.
            #
            # « Tirage integral » pioche dans tout. Le test compare les DEUX
            # modes : si le second cesse d apporter des attaques inedites, c est
            # qu il est retombe sur le premier - ce qui arriverait si le pool
            # etait lu dans le ROMFS de sortie, ou bin/pml/waza n est pas copie.
            $romfs = Get-PfDumpRomfs
            $lire = {
                param([string]$chemin)
                $b = [IO.File]::ReadAllBytes($chemin)
                $vus = New-Object System.Collections.Generic.HashSet[int]
                for ($i = 0; ($i + 0x104) -le $b.Length; $i += 0x104) {
                    for ($c = 0; $c -lt 0x104; $c += 4) {
                        $m = [int][BitConverter]::ToUInt16($b, $i + $c)
                        $l = [int][BitConverter]::ToUInt16($b, $i + $c + 2)
                        if ($m -eq 0xFFFF -and $l -eq 0xFFFF) { break }
                        if ($m -gt 0) { $null = $vus.Add($m) }
                    }
                }
                return $vus
            }
            $base = & $lire (Join-Path $romfs 'bin\pml\waza_oboe\wazaoboe_total.bin')

            $inedites = @{}
            foreach ($mode in @('Random', 'FullRandom')) {
                $g = Invoke-PfGeneration -Options @{ Seed = 808; LearnsetMoveMode = $mode }
                try {
                    $g.CodeSortie | Should Be 0
                    $vus = & $lire (Join-Path $g.Sortie 'romfs\bin\pml\waza_oboe\wazaoboe_total.bin')
                    $neuves = @($vus | Where-Object { -not $base.Contains([int]$_) })
                    $inedites[$mode] = $neuves.Count
                    Write-Host ("  {0,-11} {1} attaques distinctes, dont {2} inedites" -f $mode, $vus.Count, $neuves.Count)
                } finally { Remove-PfGeneration $g }
            }
            # Le mode restreint ne doit RIEN apporter d inedit, l integral si.
            $inedites['Random'] | Should Be 0
            $inedites['FullRandom'] | Should BeGreaterThan 100
        }
    }

    Context "Les caps d'EXP arrivent jusqu'au module" {
        # Seule famille d'options qui ne touche AUCUN fichier du ROMFS : elle
        # ecrit dans config.toml, que le module C++ relit avec .value_or(defaut).
        # C'est le mode de panne decrit dans ADR-001 : une cle mal nommee ou
        # absente ne provoque aucune erreur, le module retombe silencieusement
        # sur sa valeur par defaut et l'option est morte sans que rien ne le
        # dise. Comparer des fichiers ROMFS ne l'attraperait jamais.
        #
        # Il faut un ExeFS : sans lui le generateur ne produit pas de module,
        # donc pas de config.toml. Le temoin doit donc en avoir un lui aussi,
        # sinon la comparaison mesurerait la presence du module, pas le cap.
        $exefs = Join-Path (Split-Path -Parent (Get-PfDumpRomfs)) 'exefs'
        if (-not (Test-Path -LiteralPath (Join-Path $exefs 'main.npdm'))) {
            It "necessite un ExeFS" {
                Set-TestInconclusive -Message "ExeFS introuvable a cote du dump : $exefs"
            }
        } else {
            It "ecrit le cap dans config.toml et nulle part ailleurs" {
                $sans = Invoke-PfGeneration -Options @{ Seed = 777; SourceExefs = $exefs }
                try {
                    $sans.CodeSortie | Should Be 0
                    $avec = Invoke-PfGeneration -Options @{ Seed = 777; SourceExefs = $exefs; MainStorySoftLevelCap = $true }
                    try {
                        $avec.CodeSortie | Should Be 0
                        $differents = @(Compare-PfGenerations -A $sans -B $avec)
                        $vises = @($differents | Where-Object { $_ -like '*config.toml*' })
                        Write-Host ("  cap souple : {0} fichier(s) modifie(s), dont {1} config.toml" -f $differents.Count, $vises.Count)
                        $vises.Count | Should BeGreaterThan 0

                        # Le contenu, pas seulement le fait qu'il ait bouge : une
                        # cle presente mais vide passerait la comparaison binaire.
                        $toml = Get-ChildItem -LiteralPath $avec.Sortie -Recurse -Filter 'config.toml' |
                            Select-Object -First 1
                        $texte = [IO.File]::ReadAllText($toml.FullName)
                        ($texte -match '\[exp_level_cap\]') | Should Be $true
                        ($texte -match 'story_caps') | Should Be $true
                    } finally { Remove-PfGeneration $avec }
                } finally { Remove-PfGeneration $sans }
            }
        }
    }

    Remove-PfGeneration $reference
    Context "Les boutiques vendent ce qu'elles savent afficher" {
        It "remplace chaque objet par un objet de la MEME poche, dans les deux vecteurs racine" {
            # Mesure du 2026-09-07, en jeu : le marche de depart vendait des
            # Poke Ball (poche 33) et des soins (poche 32). Le tirage y a mis
            # une CT (poche 5) ; la liste s'affichait vide et le jeu plantait a
            # l'achat.
            #
            # Second defaut du meme fichier : shop_data.bin range ses boutiques
            # dans DEUX vecteurs racine, et seul le premier etait visite. Sur
            # les 24 emplacements du fichier, 6 seulement etaient tires.
            $csv = Join-Path (Split-Path -Parent $PSScriptRoot) 'items.csv'
            if (-not (Test-Path -LiteralPath $csv)) {
                Set-TestInconclusive -Message "items.csv absent : python tools/build-items-csv.py <romfs>"
                return
            }
            $poche = @{}
            foreach ($r in (Import-Csv -LiteralPath $csv -Encoding UTF8)) { $poche[[int]$r.id] = [int]$r.category_id }

            $g = Invoke-PfGeneration -Options @{
                Seed = 4242
                RandomizeShopItems = $true
                RandomizeTechnicalRecords = $true
            }
            try {
                $g.CodeSortie | Should Be 0
                $rapport = Join-Path $g.Sortie 'reports\item-changes.json'
                if (-not (Test-Path -LiteralPath $rapport)) {
                    Set-TestInconclusive -Message "item-changes.json absent"
                    return
                }
                $changements = @((Get-Content -LiteralPath $rapport -Raw | ConvertFrom-Json).changes | Where-Object { $_.source -eq 'shop' })
                $horsPoche = @($changements | Where-Object {
                    $avant = [int]$_.item.before.id
                    $apres = [int]$_.item.after.id
                    $poche.ContainsKey($avant) -and $poche.ContainsKey($apres) -and ($poche[$avant] -ne $poche[$apres])
                })
                Write-Host ("  boutiques : {0} emplacements tires, {1} hors poche" -f $changements.Count, $horsPoche.Count)
                $horsPoche.Count | Should Be 0
                # 6 emplacements = un seul vecteur racine visite. Le fichier en
                # porte 24 en tout, dont 7 designent des objets absents du jeu
                # qu'on laisse volontairement tranquilles.
                $changements.Count | Should BeGreaterThan 6
            } finally { Remove-PfGeneration $g }
        }
    }

    Context "Aucun objet sans nom lisible n'est distribue" {
        It "ecarte du tirage les 300 objets dont le jeu ne donne qu'un nom de debogage" {
            # « Vous trouvez 2 ★And390 ! », observe en jeu. La table de noms du
            # jeu porte 300 entrees de ce genre sur les 964 objets qui existent
            # - 31 % - toutes en poche 4. Elles fonctionnent, mais leur nom est
            # illisible.
            $csv = Join-Path (Split-Path -Parent $PSScriptRoot) 'item_names.csv'
            if (-not (Test-Path -LiteralPath $csv)) {
                Set-TestInconclusive -Message "item_names.csv absent : python tools/build-name-tables.py <romfs>"
                return
            }
            $illisible = @{}
            foreach ($r in (Import-Csv -LiteralPath $csv -Encoding UTF8)) {
                $nom = [string]$r.name
                if ([string]::IsNullOrWhiteSpace($nom) -or $nom[0] -eq [char]0x2605 -or $nom[0] -eq [char]0x2606) {
                    $illisible[[int]$r.item_id] = $true
                }
            }
            Write-Host ("  table de noms : {0} objets a nom illisible" -f $illisible.Count)
            $illisible.Count | Should BeGreaterThan 0

            $g = Invoke-PfGeneration -Options @{
                Seed = 4243
                RandomizeFieldItems = $true
                RandomizeHiddenItems = $true
                FieldItemPoolMode = 'All'
                RandomizeShopItems = $true
                TrainerItemMode = 'ForceAll'
                TrainerItemPoolMode = 'FullRandom'
            }
            try {
                $g.CodeSortie | Should Be 0
                # Objets tenus par les dresseurs.
                $mauvaisTenus = 0
                $total = 0
                $dir = Join-Path $g.Sortie 'romfs\bin\trainer\trainer_poke'
                foreach ($f in (Get-ChildItem -LiteralPath $dir -Filter '*.bin' -File)) {
                    $b = [IO.File]::ReadAllBytes($f.FullName)
                    for ($s = 0; $s -lt [int]($b.Length / 0x20); $s++) {
                        $it = [int][BitConverter]::ToUInt16($b, $s * 0x20 + 0x10)
                        if ($it -gt 0) {
                            $total++
                            if ($illisible.ContainsKey($it)) { $mauvaisTenus++ }
                        }
                    }
                }
                # Objets au sol, caches, boutiques et ramassage.
                $mauvaisTerrain = 0
                $rapport = Join-Path $g.Sortie 'reports\item-changes.json'
                if (Test-Path -LiteralPath $rapport) {
                    foreach ($c in @((Get-Content -LiteralPath $rapport -Raw | ConvertFrom-Json).changes)) {
                        if ($illisible.ContainsKey([int]$c.item.after.id)) { $mauvaisTerrain++ }
                    }
                }
                Write-Host ("  {0} objets tenus, {1} illisible(s) | terrain et boutiques : {2} illisible(s)" -f $total, $mauvaisTenus, $mauvaisTerrain)
                $mauvaisTenus | Should Be 0
                $mauvaisTerrain | Should Be 0
            } finally { Remove-PfGeneration $g }
        }
    }

    Context "Les rencontres visibles restent affichables" {
        # La liste des especes affichables n'est publiee que dans config.toml,
        # que le generateur n'ecrit qu'avec un ExeFS - meme dependance que le
        # test des caps d'EXP.
        $exefsRencontres = Join-Path (Split-Path -Parent (Get-PfDumpRomfs)) 'exefs'
        It "ne place dehors que des especes dont le jeu possede un modele" {
            if (-not (Test-Path -LiteralPath (Join-Path $exefsRencontres 'main.npdm'))) {
                Set-TestInconclusive -Message "ExeFS introuvable a cote du dump : $exefsRencontres"
                return
            }
            # Observe en jeu : un Elekable apparaissait dehors alors qu'il
            # n'etait dans aucun des pools annonces. Il venait des rencontres
            # FIXES et du SOUTERRAIN, deux passes qui font apparaitre un modele
            # dans le monde sans verifier que l'espece sait s'afficher. Le jeu
            # ne sait en afficher que 330.
            # L'option est desormais COUPEE par defaut : sa premisse - « le jeu
            # ne sait afficher que 330 especes » - s'est revelee fausse. On la
            # demande donc explicitement pour tester ce qu'elle fait.
            $g = Invoke-PfGeneration -Options @{
                Seed = 4244
                SourceExefs = $exefsRencontres
                StaticEncounterMode = 'Random'
                UndergroundMode = 'Random'
                OverworldModelSafeEncounters = $true
            }
            try {
                $g.CodeSortie | Should Be 0
                $config = Join-Path $g.Sortie 'sdmc\config\swsh-mods-exl\config.toml'
                $rapport = Join-Path $g.Sortie 'reports\wild-changes.json'
                if (-not (Test-Path -LiteralPath $config) -or -not (Test-Path -LiteralPath $rapport)) {
                    Set-TestInconclusive -Message "config.toml ou wild-changes.json absent"
                    return
                }
                $texte = Get-Content -LiteralPath $config -Raw
                if ($texte -notmatch '(?m)^visual_species = \[(.*?)\]') {
                    Set-TestInconclusive -Message "visual_species absent du config.toml"
                    return
                }
                $affichables = @{}
                foreach ($x in ($Matches[1] -split ',')) {
                    $v = 0
                    if ([int]::TryParse($x.Trim(), [ref]$v) -and $v -gt 0) { $affichables[$v] = $true }
                }
                Write-Host ("  especes affichables dehors : {0}" -f $affichables.Count)
                $affichables.Count | Should BeGreaterThan 0

                $rencontres = @((Get-Content -LiteralPath $rapport -Raw | ConvertFrom-Json).encounters)
                foreach ($bloc in @('staticScriptedEncounter', 'undergroundEncounter')) {
                    $ecritures = @($rencontres | Where-Object { $_.block -eq $bloc -and $null -ne $_.species.after.id })
                    $hors = @($ecritures | Where-Object { -not $affichables.ContainsKey([int]$_.species.after.id) })
                    Write-Host ("  {0,-26} {1} ecritures, {2} non affichable(s)" -f $bloc, $ecritures.Count, $hors.Count)
                    $ecritures.Count | Should BeGreaterThan 0
                    $hors.Count | Should Be 0
                }
            } finally { Remove-PfGeneration $g }
        }
    }

    Context "« N Pokemon de plus » agrandit vraiment les equipes" {
        It "agrandit les equipes meme sans aucune autre option de dresseur" {
            # L'option etait inerte seule : la boucle des dresseurs sortait
            # avant l'ajout quand aucune option « globale » n'etait active.
            # Mesure du 2026-09-07 avec +2 sur les trois classes : 77 equipes
            # agrandies sur les 318 qui avaient la place.
            $vanilla = Join-Path $romfs 'bin\trainer\trainer_poke'
            if (-not (Test-Path -LiteralPath $vanilla)) {
                Set-TestInconclusive -Message "romfs source indisponible"
                return
            }
            $tailleVanilla = @{}
            foreach ($f in (Get-ChildItem -LiteralPath $vanilla -Filter '*.bin' -File)) {
                $tailleVanilla[$f.Name] = [int]($f.Length / 0x20)
            }

            $g = Invoke-PfGeneration -Options @{
                Seed = 4245
                TrainerExtraPokemonRegular = 2
                TrainerExtraPokemonImportant = 2
                TrainerExtraPokemonBoss = 2
                TrainerSpecialRuleScope = 'All'
            }
            try {
                $g.CodeSortie | Should Be 0
                $dir = Join-Path $g.Sortie 'romfs\bin\trainer\trainer_poke'
                $agrandies = 0
                $pouvaient = 0
                $reduites = 0
                foreach ($f in (Get-ChildItem -LiteralPath $dir -Filter '*.bin' -File)) {
                    if (-not $tailleVanilla.ContainsKey($f.Name)) { continue }
                    $avant = $tailleVanilla[$f.Name]
                    $apres = [int]($f.Length / 0x20)
                    if ($avant -ge 1 -and $avant -lt 6) { $pouvaient++ }
                    if ($apres -gt $avant) { $agrandies++ }
                    if ($apres -lt $avant) { $reduites++ }
                }
                Write-Host ("  {0} equipes agrandies sur {1} qui avaient la place, {2} reduite(s)" -f $agrandies, $pouvaient, $reduites)
                $reduites | Should Be 0
                # Sans le correctif : 77. Avec : 413 sur 414.
                $agrandies | Should BeGreaterThan ([int]($pouvaient * 0.9))
            } finally { Remove-PfGeneration $g }
        }
    }

    Context "Les prix tires au hasard restent dans leurs bornes" {
        It "tire entre les deux bornes et laisse invendable ce qui l'etait" {
            $g = Invoke-PfGeneration -Options @{
                Seed = 4246
                ShopPriceMode = 'Random'
                ShopPriceMin = 300
                ShopPriceMax = 9000
            }
            try {
                $g.CodeSortie | Should Be 0
                $chemin = Join-Path $g.Sortie 'romfs\bin\pml\item\item.dat'
                if (-not (Test-Path -LiteralPath $chemin)) {
                    Set-TestInconclusive -Message "item.dat absent de la sortie"
                    return
                }
                $mod = [IO.File]::ReadAllBytes($chemin)
                $van = [IO.File]::ReadAllBytes((Join-Path $romfs 'bin\pml\item\item.dat'))
                $lire = {
                    param([byte[]]$d)
                    $recs = [int][BitConverter]::ToUInt32($d, 0x40)
                    $prix = @{}
                    $vus = @{}
                    for ($i = 0; $i -lt 1608; $i++) {
                        $rn = [int][BitConverter]::ToUInt16($d, 0x44 + $i * 2)
                        if ($rn -le 0 -or $vus.ContainsKey($rn)) { continue }
                        $vus[$rn] = $true
                        $prix[$i] = [int][BitConverter]::ToUInt32($d, $recs + $rn * 48)
                    }
                    return $prix
                }
                $pv = & $lire $van
                $pm = & $lire $mod
                $changes = 0
                $hors = 0
                $zeroCasse = 0
                foreach ($id in $pv.Keys) {
                    if (-not $pm.ContainsKey($id)) { continue }
                    if ($pv[$id] -eq 0 -and $pm[$id] -ne 0) { $zeroCasse++ }
                    if ($pv[$id] -ne $pm[$id]) {
                        $changes++
                        if ($pm[$id] -lt 300 -or $pm[$id] -gt 9000) { $hors++ }
                    }
                }
                Write-Host ("  {0} prix modifies, {1} hors bornes, {2} invendable(s) devenu(s) payant(s)" -f $changes, $hors, $zeroCasse)
                $changes | Should BeGreaterThan 0
                $hors | Should Be 0
                $zeroCasse | Should Be 0
            } finally { Remove-PfGeneration $g }
        }
    }

    Context "Les attaques des dresseurs sont propres" {
        # Trois ecrivains distincts posent les quatre attaques d'un Pokemon de
        # dresseur : Random4, LastLevelUp4 et le mode Smogon. Les trois avaient
        # le meme defaut de forme, invisible tant qu'on ne compare pas au
        # vanilla. Mesure du 2026-09-07 sur 1223 Pokemon :
        #
        #   vanilla            0 doublon, 0 trou
        #   Random4           23 doublons  (quatre tirages independants)
        #   LastLevelUp4      49 trous, 1 doublon  (alignement a droite, et une
        #                     espece peut reapprendre la meme attaque)
        #   SmogonStrategic    6 trous
        #
        # Un « trou » est une case vide suivie d'une case pleine : le vanilla
        # remplit toujours depuis la premiere case.
        foreach ($mode in @('Random4', 'LastLevelUp4')) {
            It "$mode ne pose ni doublon ni trou" {
                $g = Invoke-PfGeneration -Options @{
                    Seed = 4247
                    TrainerSpeciesMode = 'Random'
                    TrainerMoveMode = $mode
                }
                try {
                    $g.CodeSortie | Should Be 0
                    $doublons = 0
                    $trous = 0
                    $pokemon = 0
                    $dir = Join-Path $g.Sortie 'romfs\bin\trainer\trainer_poke'
                    foreach ($f in (Get-ChildItem -LiteralPath $dir -Filter '*.bin' -File)) {
                        $b = [IO.File]::ReadAllBytes($f.FullName)
                        for ($s = 0; $s -lt [int]($b.Length / 0x20); $s++) {
                            $pokemon++
                            $att = @(0, 1, 2, 3 | ForEach-Object {
                                [int][BitConverter]::ToUInt16($b, $s * 0x20 + 0x12 + ($_ * 2))
                            })
                            $connues = @($att | Where-Object { $_ -gt 0 })
                            if ($connues.Count -ne (@($connues | Select-Object -Unique)).Count) { $doublons++ }
                            $vuVide = $false
                            foreach ($m in $att) {
                                if ($m -eq 0) { $vuVide = $true }
                                elseif ($vuVide) { $trous++; break }
                            }
                        }
                    }
                    Write-Host ("  {0,-14} {1} pokemon, {2} doublon(s), {3} trou(s)" -f $mode, $pokemon, $doublons, $trous)
                    $doublons | Should Be 0
                    $trous | Should Be 0
                } finally { Remove-PfGeneration $g }
            }
        }
    }

}
