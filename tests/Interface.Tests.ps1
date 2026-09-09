#requires -Version 5.1
<#
    Premiers tests automatises du projet.

    Ils ne disent pas si l'interface est belle : ca, seul un humain le juge.
    Ils verrouillent les classes de defaut REELLEMENT rencontrees pendant la
    refonte, qui etaient toutes silencieuses :

      - une liste deroulante affichant un nom de type au lieu du libelle
        (ToString au lieu de GetItemText ; 42 sites utilisent DisplayMember) ;
      - un controle rendu a une taille differente de celle demandee
        (TextBox 36 demandes -> 18 rendus ; ComboBox 36 -> 32) ;
      - deux controles qui se chevauchent, ou qui debordent de leur parent ;
      - un onglet qui ne se peint pas.

    La fenetre est construite UNE fois, dans un processus separe, et s'inspecte
    elle-meme (voir tools/gui-inspect.ps1). Le rapport est du JSON : les tests
    ci-dessous ne touchent aucun objet WinForms.

    Lancer :  powershell -ExecutionPolicy Bypass -File tools/run-tests.ps1
#>

. (Join-Path $PSScriptRoot '..\tools\gui-harness.ps1')

$imgDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'docs\images\onglets'
$sw = [Diagnostics.Stopwatch]::StartNew()
$R = Invoke-PfGuiInspection -Theme 'Dark' -Language 'fr' -ImageDir $imgDir
$sw.Stop()
Write-Host ("Interface inspectee en {0} ms : {1} controles, {2} onglets." -f $sw.ElapsedMilliseconds, $R.controls.Count, $R.tabs.Count)

$Combos = @($R.controls | Where-Object { $_.kind -eq 'combo' })
$Texts  = @($R.controls | Where-Object { $_.kind -eq 'text' })
$Checks = @($R.controls | Where-Object { $_.kind -eq 'check' })

function Show-Failures {
    param([string]$Titre, [string[]]$Lignes)
    if ($Lignes.Count -gt 0) {
        Write-Host ("  {0} :" -f $Titre)
        foreach ($l in ($Lignes | Select-Object -First 12)) { Write-Host ("    " + $l) }
        if ($Lignes.Count -gt 12) { Write-Host ("    ... et {0} autres" -f ($Lignes.Count - 12)) }
    }
}

Describe "Interface du generateur" {

    Context "La fenetre se construit" {
        It "le processus rend la main sans erreur" {
            $R.exitCode | Should Be 0
        }
        It "contient un nombre plausible de controles" {
            # 265 releves ; borne basse large pour ne pas casser a chaque
            # option ajoutee.
            $R.controls.Count | Should BeGreaterThan 200
        }
        It "expose les neuf onglets" {
            $R.tabs.Count | Should Be 9
        }
    }

    Context "Le titre de page suit la navigation" {
        It "le titre affiche l'onglet reellement selectionne" {
            # Constate le 2026-09-05 : le titre affichait « Nettoyage » alors
            # que le rail montrait « Generation ». Deplacer un TabControl entre
            # parents perd sa selection, et la restaurer ne tenait pas.
            Write-Host ("  titre='{0}'  onglet='{1}'" -f $R.pageTitle, $R.selectedTab)
            $R.pageTitle | Should Be $R.selectedTab
        }
    }

    Context "La fenetre tient sur l'ecran" {
        It "ne depasse pas la zone de travail" {
            # Sans bordure et non redimensionnable : ce qui depasse de l'ecran
            # serait DEFINITIVEMENT hors d'atteinte. Mesure du 2026-09-06 : la
            # taille voulue, 1412x1021, ne laissait que 11 px de marge sur un
            # 1920x1080, et ne tenait pas du tout sur un portable 1366x768.
            Write-Host ("  fenetre {0}x{1}  zone de travail {2}x{3}" -f $R.fenetreW, $R.fenetreH, $R.zoneTravailW, $R.zoneTravailH)
            $R.fenetreW | Should BeLessThan ($R.zoneTravailW + 1)
            $R.fenetreH | Should BeLessThan ($R.zoneTravailH + 1)
        }

        It "reste entierement atteignable une fois retrecie" {
            $s = $R.retrecissement
            $s.teste | Should Be $true
            $s.autoScroll | Should Be $true
            Write-Host ("  a {0}x{1} : defilement V={2} H={3}, zone {4}x{5}" -f
                $s.largeurReduite, $s.hauteurReduite, $s.barreVerticale, $s.barreHorizontale,
                $s.zoneDefilableW, $s.zoneDefilableH)
            # Le contenu complet doit rester joignable par defilement.
            $s.zoneDefilableW | Should BeGreaterThan 1100
            $s.zoneDefilableH | Should BeGreaterThan 900
        }
    }

    Context "Plus aucun controle systeme visible" {
        It "n'a aucune case a cocher d'origine" {
            $bad = @($Checks | Where-Object { $_.type -notlike 'PokeFeur.Ui.*' } | ForEach-Object { "$($_.name) [$($_.type)]" })
            Show-Failures "cases systeme" $bad
            $bad.Count | Should Be 0
        }
        It "n'a aucune liste deroulante d'origine" {
            $bad = @($Combos | Where-Object { $_.type -notlike 'PokeFeur.Ui.*' } | ForEach-Object { "$($_.name) [$($_.type)]" })
            Show-Failures "listes systeme" $bad
            $bad.Count | Should Be 0
        }
        It "n'a aucun bouton d'origine" {
            $bad = @($R.controls | Where-Object { $_.kind -eq 'button' -and $_.type -notlike 'PokeFeur.Ui.*' } |
                ForEach-Object { "$($_.text) [$($_.type)]" })
            Show-Failures "boutons systeme" $bad
            $bad.Count | Should Be 0
        }
        It "n'a aucun champ de saisie d'origine" {
            $bad = @($Texts | Where-Object { $_.type -notlike 'PokeFeur.Ui.*' } | ForEach-Object { "$($_.name) [$($_.type)]" })
            Show-Failures "champs systeme" $bad
            $bad.Count | Should Be 0
        }
    }

    Context "Les listes deroulantes montrent des libelles, pas des types" {
        It "aucune liste ne rend un nom de type" {
            # Le defaut exact evite : Items contient des objets, DisplayMember
            # nomme la propriete a afficher, et ToString aurait rendu
            # 'System.Management.Automation.PSCustomObject'.
            $bad = @($Combos |
                Where-Object { $_.itemCount -gt 0 -and
                    ([string]::IsNullOrWhiteSpace($_.firstItemText) -or $_.firstItemText -like 'System.*') } |
                ForEach-Object { "$($_.name) -> '$($_.firstItemText)'" })
            Show-Failures "listes fautives" $bad
            $bad.Count | Should Be 0
        }
        It "toute liste non vide a une selection" {
            $bad = @($Combos | Where-Object { $_.itemCount -gt 0 -and $_.selectedIndex -lt 0 } | ForEach-Object { $_.name })
            Show-Failures "listes sans selection" $bad
            $bad.Count | Should Be 0
        }
    }

    Context "Les controles rendent a la taille demandee" {
        It "aucun champ de saisie n'est ecrase en hauteur" {
            $bad = @($Texts | Where-Object { (-not $_.multiline) -and $_.h -lt 22 } |
                ForEach-Object { "$($_.name) h=$($_.h)" })
            Show-Failures "champs trop bas" $bad
            $bad.Count | Should Be 0
        }
        It "aucune liste deroulante n'est ecrasee en hauteur" {
            $bad = @($Combos | Where-Object { $_.h -lt 22 } | ForEach-Object { "$($_.name) h=$($_.h)" })
            Show-Failures "listes trop basses" $bad
            $bad.Count | Should Be 0
        }
    }

    Context "Les zones de lecture seule ne sont pas surlignees" {
        It "aucune zone en lecture seule n'a de texte selectionne" {
            # Constate le 2026-09-05 : le panneau d'aide s'ouvrait entierement
            # surligne en blanc, parce qu'une TextBox en lecture seule
            # selectionne tout son contenu quand elle prend le focus.
            $bad = @($Texts | Where-Object { $_.readOnly -and $_.selectionLength -gt 0 } |
                ForEach-Object { "$($_.name) selection=$($_.selectionLength)" })
            Show-Failures "zones surlignees" $bad
            $bad.Count | Should Be 0
        }
    }

    Context "Les champs restent lisibles" {
        It "aucun champ n'a un fond clair en theme sombre" {
            # Constate le 2026-09-05 : passer une TextBox en lecture seule
            # reinitialise BackColor sur la couleur systeme. Le panneau d'aide
            # s'affichait en gris clair sur blanc.
            $bad = @($Texts | Where-Object { $_.backLuma -gt 120 } |
                ForEach-Object { "$($_.name) fond=$($_.backLuma)" })
            Show-Failures "fonds clairs" $bad
            $bad.Count | Should Be 0
        }
        It "le texte contraste avec son fond" {
            $bad = @($Texts | Where-Object { [Math]::Abs($_.foreLuma - $_.backLuma) -lt 60 } |
                ForEach-Object { "$($_.name) texte=$($_.foreLuma) fond=$($_.backLuma)" })
            Show-Failures "contraste insuffisant" $bad
            $bad.Count | Should Be 0
        }
    }

    Context "La disposition tient" {
        It "aucun controle ne deborde de son parent" {
            $bad = @()
            foreach ($c in $R.controls) {
                if (-not $c.visibleUnJour -or $c.parentW -le 0) { continue }
                # Le TabControl deborde volontairement de son panneau de
                # rognage : c'est ainsi qu'on masque son bandeau, remplace par
                # le rail de navigation.
                if ($c.parentName -eq 'PfTabClip') { continue }
                if ($c.x -lt -2 -or $c.y -lt -2 -or
                    (($c.x + $c.w) - $c.parentW) -gt 2 -or (($c.y + $c.h) - $c.parentH) -gt 2) {
                    $bad += ("{0} ({1},{2} {3}x{4}) hors de {5}x{6}" -f $c.name, $c.x, $c.y, $c.w, $c.h, $c.parentW, $c.parentH)
                }
            }
            Show-Failures "debordements" $bad
            $bad.Count | Should Be 0
        }

        It "aucun controle interactif n'en recouvre un autre" {
            # C'est ce test qui aurait signale la collision de disposition
            # rencontree en ajoutant la case dex_animations.
            $bad = @()
            $groups = $R.controls | Where-Object { $_.visibleUnJour -and $_.interactive } | Group-Object parentId
            foreach ($g in $groups) {
                $items = @($g.Group)
                for ($i = 0; $i -lt $items.Count; $i++) {
                    for ($j = $i + 1; $j -lt $items.Count; $j++) {
                        $a = $items[$i]; $b = $items[$j]
                        # Surface VISIBLE, pas boite declaree : une case a
                        # cocher est volontairement large pour etre facile a
                        # viser, et sa moitie droite est vide.
                        $aw = if ($a.needW -gt 0) { [Math]::Min($a.w, $a.needW) } else { $a.w }
                        $bw = if ($b.needW -gt 0) { [Math]::Min($b.w, $b.needW) } else { $b.w }
                        if ($a.x -lt ($b.x + $bw) -and $b.x -lt ($a.x + $aw) -and
                            $a.y -lt ($b.y + $b.h) -and $b.y -lt ($a.y + $a.h)) {
                            $bad += ("{0} ({1},{2} {3}x{4}) / {5} ({6},{7} {8}x{9})" -f
                                $a.name, $a.x, $a.y, $a.w, $a.h, $b.name, $b.x, $b.y, $b.w, $b.h)
                        }
                    }
                }
            }
            Show-Failures "chevauchements" $bad
            $bad.Count | Should Be 0
        }
    }

    Context "Les libelles tiennent dans la place qu'on leur donne" {
        It "aucun libelle n'est tronque" {
            # Constate sur les captures de l'utilisateur, alors que les 21 tests
            # precedents passaient : la police des libelles a change et elle est
            # plus large, donc des textes calibres pour l'ancienne debordent.
            $bad = @($R.controls |
                Where-Object { $_.isLabel -and $_.visibleUnJour -and $_.needW -gt 0 -and $_.needW -gt $_.w } |
                ForEach-Object { "«{0}» {1}px dans {2}px" -f $_.text, $_.needW, $_.w })
            Show-Failures "libelles tronques" $bad
            $bad.Count | Should Be 0
        }

        It "aucun libelle n'en recouvre un autre" {
            # Le test de chevauchement ne regardait que les controles
            # interactifs. Les libelles s'empilaient donc sans que rien ne le
            # signale.
            $bad = @()
            $groups = $R.controls |
                Where-Object { $_.visibleUnJour -and $_.isLabel -and -not [string]::IsNullOrEmpty($_.text) } |
                Group-Object parentId
            foreach ($g in $groups) {
                $items = @($g.Group)
                for ($i = 0; $i -lt $items.Count; $i++) {
                    for ($j = $i + 1; $j -lt $items.Count; $j++) {
                        $a = $items[$i]; $b = $items[$j]
                        # On compare la surface REELLEMENT occupee par le texte,
                        # pas la boite du controle : beaucoup de libelles sont
                        # volontairement larges et vides a droite.
                        # Limite connue : l'ordre de superposition n'est pas
                        # modelise. Un recouvrement de boites est signale meme
                        # si le libelle recouvert est dessine par-dessus. Une
                        # boite qui deborde dans la colonne voisine reste un
                        # defaut de disposition, donc le signal est utile.
                        #
                        # Les libelles ont un fond OPAQUE : une boite large et
                        # vide repeint le texte de sa voisine. On compare donc
                        # la boite de l'un au texte de l'autre, dans les deux
                        # sens - « Precision max » s'affichait « recision max ».
                        $at = [Math]::Max($a.needW, 1)
                        $bt = [Math]::Max($b.needW, 1)
                        $memeLigne = ($a.y -lt ($b.y + $b.h) -and $b.y -lt ($a.y + $a.h))
                        if ($memeLigne -and
                            (($a.x -lt ($b.x + $bt) -and $b.x -lt ($a.x + $a.w)) -or
                             ($b.x -lt ($a.x + $at) -and $a.x -lt ($b.x + $b.w)))) {
                            $bad += ("«{0}» / «{1}»" -f $a.text, $b.text)
                        }
                    }
                }
            }
            Show-Failures "libelles superposes" $bad
            $bad.Count | Should Be 0
        }
    }

    Context "Les cartes ne se chevauchent pas" {
        It "deux cartes du meme onglet ne se recouvrent jamais" {
            # Trou constate le 2026-09-06 : le test de chevauchement compare
            # les controles d'un MEME parent. Deux cartes sont des parents
            # differents, donc leur superposition n'etait vue par personne. Un
            # essai de decoupage en colonnes de l'onglet Pokemon a produit deux
            # cartes l'une sur l'autre, tests au vert.
            $bad = @()
            $groupes = $R.controls | Where-Object { $_.isCard } | Group-Object parentId
            foreach ($g in $groupes) {
                $cartes = @($g.Group)
                for ($i = 0; $i -lt $cartes.Count; $i++) {
                    for ($j = $i + 1; $j -lt $cartes.Count; $j++) {
                        $a = $cartes[$i]; $b = $cartes[$j]
                        if ($a.x -lt ($b.x + $b.w) -and $b.x -lt ($a.x + $a.w) -and
                            $a.y -lt ($b.y + $b.h) -and $b.y -lt ($a.y + $a.h)) {
                            $bad += ("«{0}» ({1},{2} {3}x{4}) / «{5}» ({6},{7} {8}x{9})" -f
                                $a.cardTitle, $a.x, $a.y, $a.w, $a.h,
                                $b.cardTitle, $b.x, $b.y, $b.w, $b.h)
                        }
                    }
                }
            }
            Show-Failures "cartes superposees" $bad
            $bad.Count | Should Be 0
        }
    }

    Context "Aucun libelle ne passe sous un controle" {
        It "aucun libelle n'est recouvert par une liste, un champ ou une case" {
            # Troisieme croisement, et le dernier manquant : un test comparait
            # les libelles entre eux, un autre les controles entre eux, mais
            # personne ne regardait un libelle CONTRE un controle. Les captures
            # de l'utilisateur montraient « Backup moves Smogon » et « Liste de
            # boss utilisee » a moitie caches sous une liste deroulante.
            $bad = @()
            $labels = @($R.controls | Where-Object {
                $_.visibleUnJour -and $_.isLabel -and -not [string]::IsNullOrEmpty($_.text) })
            # Les cartes comptent : un libelle laisse hors d'une carte passe
            # par-dessus son titre. Constate sur l'onglet Starters, ou
            # « Pokémon cadeaux » recouvrait « Cadeaux et starters ». Un libelle
            # POSE DANS une carte a la carte pour parent, donc il n'est pas
            # compare avec elle : seuls les rescapes le sont.
            # Volontairement limite aux controles interactifs. Une tentative
            # d'y ajouter le bandeau de titre des cartes a produit des
            # correspondances que je n'ai pas su justifier : un test qu'on ne
            # sait pas expliquer vaut moins que pas de test. Le chevauchement
            # d'une carte par un libelle reste couvert par le test « deux
            # cartes ne se recouvrent jamais » et par la relecture des captures.
            $widgets = @($R.controls | Where-Object { $_.visibleUnJour -and $_.interactive })
            $parWidget = @{}
            foreach ($w in $widgets) {
                if (-not $parWidget.ContainsKey($w.parentId)) { $parWidget[$w.parentId] = New-Object System.Collections.ArrayList }
                [void]$parWidget[$w.parentId].Add($w)
            }
            foreach ($l in $labels) {
                if (-not $parWidget.ContainsKey($l.parentId)) { continue }
                # La BOITE du libelle, pas la largeur de son texte. C'est son
                # fond OPAQUE qui repeint la voisine, et ce fond couvre toute la
                # boite meme quand le texte s'arrete avant. Mesurer le texte
                # laissait passer « Backup moves Smogon » : declare sur 180 px a
                # partir de 270, il n'en remplissait que 151 - donc aucun
                # chevauchement de TEXTE - mais son fond mordait de 20 px sur la
                # liste commencant a 430, dont la premiere lettre disparaissait.
                # La capture le montrait, le test ne le voyait pas.
                # Verifie avant de resserrer : sur les neuf onglets, la regle
                # stricte ne releve QUE ce cas. Zero faux positif.
                $lw = $l.w
                foreach ($w in $parWidget[$l.parentId]) {
                    $ww = $w.w
                    if ($l.x -lt ($w.x + $ww) -and $w.x -lt ($l.x + $lw) -and
                        $l.y -lt ($w.y + $w.h) -and $w.y -lt ($l.y + $l.h)) {
                        $bad += ("«{0}» ({1},{2} {3}x{4}) sous {5} ({6},{7} {8}x{9})" -f
                            $l.text, $l.x, $l.y, $lw, $l.h, $w.kind, $w.x, $w.y, $ww, $w.h)
                    }
                }
            }
            Show-Failures "libelles caches" $bad
            $bad.Count | Should Be 0
        }
    }

    Context "Le contenu des cartes passe sous leur titre" {
        It "aucun enfant de carte ne remonte dans la zone du titre" {
            # PfCard peint son titre a y=20 et son sous-titre a y=44..64 : ce
            # sont des dessins, pas des controles, donc aucun test de geometrie
            # ne les voyait. La seconde carte de l'onglet Confort commencait a
            # y=56 et son sous-titre passait par-dessus la premiere rangee.
            $cartes = @($R.controls | Where-Object { $_.isCard })
            $bad = @()
            foreach ($carte in $cartes) {
                # Geometrie reelle de PfCard.OnPaint : titre dans 20..44,
                # sous-titre dans 44..64. Le plancher est donc 46 sans
                # sous-titre et 66 avec - pas une marge choisie au jugé.
                $planche = if ([string]::IsNullOrEmpty($carte.cardSubtitle)) { 46 } else { 66 }
                foreach ($c in $R.controls) {
                    if ($c.parentId -ne $carte.selfId) { continue }
                    if ($c.y -lt $planche) {
                        $bad += ("«{0}» a y={1}, or la carte «{2}» ecrit jusqu'a y={3}" -f
                            $c.text, $c.y, $carte.cardTitle, $planche)
                    }
                }
            }
            Show-Failures "contenu sous le titre" $bad
            $bad.Count | Should Be 0
        }
    }

    Context "Chaque controle se peint" {
        It "aucun controle interactif visible ne rend une surface unie" {
            # On interroge chaque controle plutot que la fenetre : PrintWindow a
            # un angle mort sur certains enfants imbriques et les rend noirs
            # alors qu'ils se peignent tres bien.
            # Un champ de saisie vide n'a rien a dessiner, et DrawToBitmap
            # passe par WM_PRINTCLIENT : la bordure non cliente de PfTextBox
            # n'y figure pas. Deux couleurs y sont donc normales.
            $bad = @($R.controls |
                Where-Object { $_.interactive -and $_.visibleUnJour -and $_.paintColors -ge 0 -and
                    $_.paintColors -lt 3 -and -not ($_.kind -eq 'text' -and [string]::IsNullOrEmpty($_.text)) } |
                ForEach-Object { "$($_.text) [$($_.type)] couleurs=$($_.paintColors)" })
            Show-Failures "controles non peints" $bad
            $bad.Count | Should Be 0
        }
    }

    Context "Chaque onglet se peint" {
        It "aucun onglet ne rend une image unie" {
            # Une page qui ne s'est pas peinte est unie. Le seuil separe
            # « peinte » de « vide » ; il ne juge pas l'esthetique.
            $bad = @($R.tabs | Where-Object { $_.colors -lt 8 } | ForEach-Object { "$($_.title) ($($_.colors) couleurs)" })
            foreach ($t in $R.tabs) { Write-Host ("  {0,-22} {1,4} couleurs" -f $t.title, $t.colors) }
            Write-Host ("  images : " + $R.imageDir)
            Show-Failures "onglets suspects" $bad
            $bad.Count | Should Be 0
        }
    }
}

Describe "Version du logiciel" {
    It "n'existe qu'a un seul endroit" {
        # La version etait recopiee dans quinze chaines litterales, et elles
        # avaient derive : l'interface annoncait V4.17 pendant que quatre
        # rapports JSON ecrivaient V4.18. Un rapport qui ment sur sa propre
        # version rend tout diagnostic a posteriori impossible - on ne sait plus
        # quelle build a produit quoi.
        #
        # La regle : un seul litteral, celui de la definition. Partout ailleurs,
        # $AppVersion. Ce test relit le fichier source, pas l'interface : il
        # attrape la recopie meme si elle n'est jamais affichee.
        # Les DEUX fichiers du generateur : depuis le decoupage du monolithe,
        # l'interface vit dans src/Interface.ps1, et c'est elle qui porte le
        # titre de la fenetre. N'en lire qu'un rendrait ce test aveugle a la
        # moitie du code, SANS que rien ne le signale.
        $racine = Split-Path -Parent $PSScriptRoot
        $sources = @(
            (Join-Path $racine 'CustomSwShRandomizer.ps1'),
            (Join-Path $racine 'src\Interface.ps1')
        ) | Where-Object { Test-Path -LiteralPath $_ }
        $definitions = @()
        $litteraux = @()
        foreach ($source in $sources) {
            $nom = Split-Path -Leaf $source
            $lignes = [IO.File]::ReadAllLines($source)
            for ($i = 0; $i -lt $lignes.Length; $i++) {
                $l = $lignes[$i]
                if ($l.TrimStart().StartsWith('#')) { continue }
                if ($l -match '^\s*\$AppVersion\s*=\s*"') { $definitions += ("{0} L{1}" -f $nom, ($i + 1)); continue }
                if ($l -match '"[^"]*\bV\d+\.\d+') { $litteraux += ("{0} L{1} : {2}" -f $nom, ($i + 1), $l.Trim()) }
            }
        }
        Write-Host ("  fichiers lus  : {0}" -f (($sources | ForEach-Object { Split-Path -Leaf $_ }) -join ', '))
        Write-Host ("  definition(s) : {0}, recopie(s) : {1}" -f $definitions.Count, $litteraux.Count)
        Show-Failures "versions recopiees" $litteraux
        $definitions.Count | Should Be 1
        $litteraux.Count | Should Be 0
    }
}

Describe "Textes de l'interface" {
    It "toutes les chaines francaises sont accentuees" {
        # Le generateur n'a jamais eu de BOM UTF-8 : PowerShell 5.1 le lisait en
        # ANSI, donc l'auteur avait retire tous les accents (« Reglages »,
        # « peche », « Metamorph »). Le BOM est pose, les accents sont revenus,
        # et ce test empeche la dette de se reconstituer.
        $py = (Get-Command python -ErrorAction SilentlyContinue)
        if (-not $py) {
            Set-TestInconclusive -Message "python introuvable"
            return
        }
        $tool = Join-Path (Split-Path -Parent $PSScriptRoot) 'tools\extract-ui-strings.py'
        $out = & $py.Source $tool --check 2>&1 | Out-String
        Write-Host ("  " + ($out -split "`r?`n" | Where-Object { $_ -match 'accentuees|ECHEC|a accentuer' } | Select-Object -First 2) -join ' | ')
        $LASTEXITCODE | Should Be 0
    }
}

Describe "Interface du generateur - theme clair" {
    It "se construit aussi en clair" {
        $light = Invoke-PfGuiInspection -Theme 'Light' -Language 'fr'
        $light.exitCode | Should Be 0
        $light.controls.Count | Should BeGreaterThan 200
    }
}
