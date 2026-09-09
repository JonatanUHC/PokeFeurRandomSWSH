#requires -Version 5.1
<#
    Inspecteur d'interface, execute A L'INTERIEUR du generateur.

    Pourquoi ici et pas depuis les tests
    ------------------------------------
    `Show-Gui` attache des gestionnaires qui appellent des fonctions du script,
    par exemple `$form.Add_Paint({ ... Get-GuiThemePalette ... })`. Ces
    scriptblocks sont lies au scope du script. Rendre la fenetre a un appelant
    exterieur puis laisser le script se terminer detruit ce scope : le premier
    repaint leve alors « Get-GuiThemePalette n'est pas reconnu », que WinForms
    affiche en boite modale — et le test se bloque dessus.

    On collecte donc les faits ici, tant que le scope est vivant, et on les
    ecrit en JSON. Les tests n'ont plus qu'a affirmer sur ce JSON.

    Attendu dans le scope appelant : $form, et $controls si disponible.
    Chemins passes par variables d'environnement, insensibles au scope.
#>

$pfOut = $env:PF_TEST_REPORT
$pfImg = $env:PF_TEST_IMAGES
if (-not $pfOut) { throw "PF_TEST_REPORT non defini." }

$form.StartPosition = 'Manual'
$form.Location = New-Object System.Drawing.Point(-4000, -4000)
$form.ShowInTaskbar = $false
$form.Show()
[System.Windows.Forms.Application]::DoEvents()
Start-Sleep -Milliseconds 900
[System.Windows.Forms.Application]::DoEvents()

if (-not ("PfInspect.Win" -as [type])) {
    Add-Type -Namespace PfInspect -Name Win -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern bool PrintWindow(System.IntPtr hwnd, System.IntPtr hdc, uint flags);
'@
}

# --- aplatissement de l'arbre ---------------------------------------------
$flat = New-Object System.Collections.Generic.List[object]
$stack = New-Object System.Collections.Generic.Stack[System.Windows.Forms.Control]
$stack.Push($form)
while ($stack.Count -gt 0) {
    $node = $stack.Pop()
    foreach ($child in $node.Controls) {
        $flat.Add($child)
        $stack.Push($child)
    }
}


function Measure-PfControlPaint {
    <#
        Fait dessiner le controle LUI-MEME et compte les couleurs obtenues.

        C'est un signal bien plus sur que la capture de la fenetre entiere :
        PrintWindow a un angle mort sur certains enfants profondement imbriques
        et les rend noirs alors qu'ils se peignent parfaitement. Constate le
        2026-09-05 sur les trois boutons de la rangee « profil de difficulte »,
        qui rendaient 29 a 35 couleurs une fois interroges directement.
    #>
    param([System.Windows.Forms.Control]$Control)

    if ($Control.Width -lt 2 -or $Control.Height -lt 2) { return -1 }
    $bmp = New-Object System.Drawing.Bitmap($Control.Width, $Control.Height)
    try {
        $Control.DrawToBitmap($bmp, (New-Object System.Drawing.Rectangle(0, 0, $Control.Width, $Control.Height)))
        $seen = New-Object System.Collections.Generic.HashSet[int]
        for ($x = 0; $x -lt $bmp.Width; $x += 3) {
            for ($y = 0; $y -lt $bmp.Height; $y += 3) { [void]$seen.Add($bmp.GetPixel($x, $y).ToArgb()) }
        }
        return $seen.Count
    } catch {
        return -1
    } finally {
        $bmp.Dispose()
    }
}

# Visibilite reelle, onglet par onglet. On active chaque onglet a tour de role
# et on note ce qui devient visible ; sinon huit onglets sur neuf passent pour
# invisibles et echappent a toute verification.
$visibleQuelquePart = New-Object System.Collections.Generic.HashSet[int]
$peinture = @{}
$tabControlPrepass = $null
foreach ($c in $flat) { if ($c -is [System.Windows.Forms.TabControl]) { $tabControlPrepass = $c; break } }
if ($tabControlPrepass) {
    $indexInitial = $tabControlPrepass.SelectedIndex
    for ($i = 0; $i -lt $tabControlPrepass.TabPages.Count; $i++) {
        $tabControlPrepass.SelectedIndex = $i
        [System.Windows.Forms.Application]::DoEvents()
        foreach ($c in $flat) {
            if (-not $c.Visible) { continue }
            [void]$visibleQuelquePart.Add($c.GetHashCode())
            # On mesure la peinture ICI, pendant que l'onglet est actif :
            # DrawToBitmap sur un controle d'onglet inactif rend une surface
            # vide, et neuf champs passaient pour non peints.
            $h = $c.GetHashCode()
            if (-not $peinture.ContainsKey($h)) {
                $peinture[$h] = (Measure-PfControlPaint -Control $c)
            }
        }
    }
    if ($indexInitial -ge 0) { $tabControlPrepass.SelectedIndex = $indexInitial }
    [System.Windows.Forms.Application]::DoEvents()
} else {
    foreach ($c in $flat) { if ($c.Visible) { [void]$visibleQuelquePart.Add($c.GetHashCode()) } }
}

$rows = New-Object System.Collections.Generic.List[object]
foreach ($c in $flat) {
    $entry = [ordered]@{
        name       = [string]$c.Name
        type       = $c.GetType().FullName
        parentType = if ($c.Parent) { $c.Parent.GetType().FullName } else { "" }
        parentName = if ($c.Parent) { [string]$c.Parent.Name } else { "" }
        parentId   = if ($c.Parent) { $c.Parent.GetHashCode() } else { 0 }
        selfId     = $c.GetHashCode()
        parentW    = if ($c.Parent) { $c.Parent.ClientSize.Width } else { 0 }
        parentH    = if ($c.Parent) { $c.Parent.ClientSize.Height } else { 0 }
        visible    = [bool]$c.Visible
        visibleUnJour = $visibleQuelquePart.Contains($c.GetHashCode())
        x          = $c.Left
        y          = $c.Top
        w          = $c.Width
        h          = $c.Height
        text       = [string]$c.Text
        interactive = ($c -is [System.Windows.Forms.CheckBox] -or
                       $c -is [System.Windows.Forms.ComboBox] -or
                       $c -is [System.Windows.Forms.TextBox] -or
                       $c -is [System.Windows.Forms.Button])
    }
    # Largeur reellement necessaire au texte. Un libelle plus etroit que ca est
    # tronque a l'ecran, ce qu'aucun test ne voyait : les captures de
    # l'utilisateur ont montre « Multiplicateur des ni... » et « Taille
    # equipe... » alors que la suite etait au vert.
    $entry.needW = 0
    if (-not [string]::IsNullOrEmpty($c.Text) -and
        ($c -is [System.Windows.Forms.Label] -or $c -is [System.Windows.Forms.CheckBox])) {
        try {
            $sz = [System.Windows.Forms.TextRenderer]::MeasureText($c.Text, $c.Font)
            # Une case a cocher est souvent declaree bien plus large que son
            # texte, pour offrir une grande zone cliquable. Sa surface VISIBLE
            # est la case (18 px) plus l'ecart (13) plus le texte.
            $entry.needW = [int]$sz.Width
            if ($c -is [System.Windows.Forms.CheckBox]) { $entry.needW += 31 }
            # Un PfToggle dessine sa piste au BORD DROIT : son emprise visible
            # est toute sa largeur, pas celle de son texte. L'estimer au texte
            # laissait passer un recouvrement de 200 px sur l'onglet Confort.
            if ($c.GetType().Name -eq 'PfToggle') { $entry.needW = $c.Width }
        } catch { }
    }
    $entry.isLabel = ($c -is [System.Windows.Forms.Label])
    $entry.isCard = ($c.GetType().Name -eq 'PfCard')
    $entry.cardTitle = ""
    $entry.cardSubtitle = ""
    if ($entry.isCard) {
        $entry.cardTitle = [string]$c.Title
        $entry.cardSubtitle = [string]$c.Subtitle
    }
    if ($entry.interactive -and $peinture.ContainsKey($c.GetHashCode())) {
        $entry.paintColors = [int]$peinture[$c.GetHashCode()]
    } else {
        $entry.paintColors = -1
    }
    if ($c -is [System.Windows.Forms.ComboBox]) {
        $entry.kind = "combo"
        $entry.itemCount = $c.Items.Count
        $entry.selectedIndex = $c.SelectedIndex
        $entry.firstItemText = if ($c.Items.Count -gt 0) { [string]$c.GetItemText($c.Items[0]) } else { "" }
    } elseif ($c -is [System.Windows.Forms.TextBox]) {
        $entry.kind = "text"
        $entry.multiline = [bool]$c.Multiline
        $entry.readOnly = [bool]$c.ReadOnly
        $entry.selectionLength = [int]$c.SelectionLength
        # Luminance perceptuelle du fond : c'est elle qui dit si un champ est
        # lisible dans le theme courant, pas la valeur brute des composantes.
        $bc = $c.BackColor
        $entry.backLuma = [int](0.299 * $bc.R + 0.587 * $bc.G + 0.114 * $bc.B)
        $fc = $c.ForeColor
        $entry.foreLuma = [int](0.299 * $fc.R + 0.587 * $fc.G + 0.114 * $fc.B)
    } elseif ($c -is [System.Windows.Forms.CheckBox]) {
        $entry.kind = "check"
        $entry.checked = [bool]$c.Checked
    } elseif ($c -is [System.Windows.Forms.Button]) {
        $entry.kind = "button"
    } else {
        $entry.kind = "other"
    }
    $rows.Add([pscustomobject]$entry)
}

# --- rendu de chaque onglet ------------------------------------------------
function Save-PfShot {
    param([System.Windows.Forms.Form]$F, [string]$Path)
    $bmp = New-Object System.Drawing.Bitmap($F.Width, $F.Height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $hdc = $g.GetHdc()
    $null = [PfInspect.Win]::PrintWindow($F.Handle, $hdc, 2)
    $g.ReleaseHdc($hdc); $g.Dispose()
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

function Measure-PfColors {
    param([string]$Path)
    # L'image est reduite avant lecture : GetPixel depuis PowerShell coute
    # cher, et la question posee — « cette page est-elle peinte ou unie ? » —
    # ne demande pas la pleine resolution.
    $src = New-Object System.Drawing.Bitmap($Path)
    try {
        $small = New-Object System.Drawing.Bitmap(64, 44)
        try {
            $g = [System.Drawing.Graphics]::FromImage($small)
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
            $g.DrawImage($src, 0, 0, 64, 44)
            $g.Dispose()
            $seen = New-Object System.Collections.Generic.HashSet[int]
            for ($x = 0; $x -lt 64; $x++) {
                for ($y = 0; $y -lt 44; $y++) { [void]$seen.Add($small.GetPixel($x, $y).ToArgb()) }
            }
            return $seen.Count
        } finally { $small.Dispose() }
    } finally { $src.Dispose() }
}

$tabsReport = New-Object System.Collections.Generic.List[object]
$tabControl = $null
foreach ($c in $flat) { if ($c -is [System.Windows.Forms.TabControl]) { $tabControl = $c; break } }
if ($tabControl -and $pfImg) {
    for ($i = 0; $i -lt $tabControl.TabPages.Count; $i++) {
        $tabControl.SelectedIndex = $i
        [System.Windows.Forms.Application]::DoEvents()
        # Reparenter un controle recree son handle : sans invalidation
        # explicite, certains enfants ne se repeignent pas et PrintWindow les
        # capture en noir.
        $form.Invalidate($true)
        $form.Update()
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 260
        [System.Windows.Forms.Application]::DoEvents()
        $path = Join-Path $pfImg ("onglet-{0:D2}.png" -f $i)
        Save-PfShot -F $form -Path $path
        $tabsReport.Add([pscustomobject]@{
            index  = $i
            title  = [string]$tabControl.TabPages[$i].Text
            image  = $path
            colors = (Measure-PfColors -Path $path)
        })
    }
    $tabControl.SelectedIndex = 0
}

# --- Le contenu reste-t-il atteignable sur un ecran plus petit ? ----------
# La fenetre est sans bordure et non redimensionnable : ce qui depasse de
# l'ecran serait definitivement hors d'atteinte. On retrecit donc la fenetre a
# une taille de portable et on verifie que le defilement prend le relais.
$contentHost = $null
foreach ($c in $form.Controls) {
    if ($c -is [System.Windows.Forms.Panel] -and $c.AutoScroll) { $contentHost = $c; break }
}
$retrecissement = [ordered]@{ teste = $false }
if ($contentHost) {
    $tailleAvant = $form.ClientSize
    $miniW = 1000
    $miniH = 700
    $form.MinimumSize = New-Object System.Drawing.Size(600, 400)
    $form.ClientSize = New-Object System.Drawing.Size($miniW, $miniH)
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 250
    [System.Windows.Forms.Application]::DoEvents()
    $retrecissement = [ordered]@{
        teste          = $true
        largeurReduite = $form.ClientSize.Width
        hauteurReduite = $form.ClientSize.Height
        autoScroll     = [bool]$contentHost.AutoScroll
        barreVerticale = [bool]$contentHost.VerticalScroll.Visible
        barreHorizontale = [bool]$contentHost.HorizontalScroll.Visible
        zoneDefilableW = [int]$contentHost.DisplayRectangle.Width
        zoneDefilableH = [int]$contentHost.DisplayRectangle.Height
        contenuW       = [int]$contentHost.PreferredSize.Width
        contenuH       = [int]$contentHost.PreferredSize.Height
    }
    $form.ClientSize = $tailleAvant
    [System.Windows.Forms.Application]::DoEvents()
}

$pageTitleText = ""
foreach ($c in $flat) { if ([string]$c.Name -eq 'PfPageTitle') { $pageTitleText = [string]$c.Text } }
$selectedTitle = ""
if ($tabControl -and $tabControl.SelectedIndex -ge 0) {
    $selectedTitle = [string]$tabControl.TabPages[$tabControl.SelectedIndex].Text
}

$report = [pscustomobject]@{
    retrecissement = [pscustomobject]$retrecissement
    fenetreW      = $form.ClientSize.Width
    fenetreH      = $form.ClientSize.Height
    zoneTravailW  = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Width
    zoneTravailH  = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height
    pageTitle     = $pageTitleText
    selectedTab   = $selectedTitle
    theme      = [string]$script:GuiTheme
    language   = [string]$script:UiLanguage
    formWidth  = $form.Width
    formHeight = $form.Height
    controls   = $rows.ToArray()
    tabs       = $tabsReport.ToArray()
}

$dir = Split-Path -Parent $pfOut
if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[IO.File]::WriteAllText($pfOut, ($report | ConvertTo-Json -Depth 6), [Text.UTF8Encoding]::new($false))

# Fermer AVANT la fin du script : une fenetre encore vivante quand le scope
# disparait leve une exception au premier repaint.
$form.Close()
$form.Dispose()
[System.Windows.Forms.Application]::DoEvents()
