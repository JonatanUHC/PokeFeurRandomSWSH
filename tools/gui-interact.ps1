#requires -Version 5.1
<#
    Sonde d'interaction : envoie de VRAIS clics a la fenetre et regarde ce qui
    se passe.

    Les tests de `tests/Interface.Tests.ps1` lisent un etat ; ils ne cliquent
    nulle part. Or la refonte a introduit trois points de non-retour :

      1. le bandeau d'onglets est masque — si le rail ne change pas d'onglet,
         huit onglets sur neuf deviennent INATTEIGNABLES ;
      2. la fenetre est sans bordure — si le bouton de fermeture maison ne
         marche pas, on ne peut plus fermer le logiciel normalement ;
      3. la fenetre est sans bordure — si le glisser ne marche pas, on ne peut
         plus la deplacer.

    On envoie donc de vrais messages Windows plutot que d'appeler les
    gestionnaires par reflexion : appeler OnMouseDown directement prouverait que
    le code du gestionnaire est bon, pas qu'un clic l'atteint.

    Execute a l'interieur du generateur (voir tools/gui-harness.ps1).
#>

$pfOut = $env:PF_TEST_REPORT
if (-not $pfOut) { throw "PF_TEST_REPORT non defini." }

if (-not ("PfClick.Win" -as [type])) {
    Add-Type -Namespace PfClick -Name Win -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern System.IntPtr SendMessage(System.IntPtr hWnd, int msg, System.IntPtr wParam, System.IntPtr lParam);
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern bool PostMessage(System.IntPtr hWnd, int msg, System.IntPtr wParam, System.IntPtr lParam);
'@
}

$WM_LBUTTONDOWN = 0x0201
$WM_LBUTTONUP = 0x0202

function Send-PfClick {
    param([System.Windows.Forms.Control]$Control, [int]$X, [int]$Y)
    $lp = [IntPtr](($Y -shl 16) -bor ($X -band 0xFFFF))
    [void][PfClick.Win]::SendMessage($Control.Handle, $WM_LBUTTONDOWN, [IntPtr]1, $lp)
    [System.Windows.Forms.Application]::DoEvents()
    [void][PfClick.Win]::SendMessage($Control.Handle, $WM_LBUTTONUP, [IntPtr]0, $lp)
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 120
    [System.Windows.Forms.Application]::DoEvents()
}

$form.StartPosition = 'Manual'
$form.Location = New-Object System.Drawing.Point(-4000, -4000)
$form.ShowInTaskbar = $false
$form.Show()
[System.Windows.Forms.Application]::DoEvents()
Start-Sleep -Milliseconds 900
[System.Windows.Forms.Application]::DoEvents()

$flat = New-Object System.Collections.Generic.List[System.Windows.Forms.Control]
$stack = New-Object System.Collections.Generic.Stack[System.Windows.Forms.Control]
$stack.Push($form)
while ($stack.Count -gt 0) {
    $n = $stack.Pop()
    foreach ($c in $n.Controls) { $flat.Add($c); $stack.Push($c) }
}

$rail = $flat | Where-Object { $_.GetType().Name -eq 'PfNavRail' } | Select-Object -First 1
$bar = $flat | Where-Object { $_.GetType().Name -eq 'PfTitleBar' } | Select-Object -First 1
$tabs = $flat | Where-Object { $_ -is [System.Windows.Forms.TabControl] } | Select-Object -First 1
$title = $flat | Where-Object { [string]$_.Name -eq 'PfPageTitle' } | Select-Object -First 1

$r = [ordered]@{}
$r.railTrouve = [bool]$rail
$r.barreTrouvee = [bool]$bar
$r.ongletsTrouves = [bool]$tabs

# --- 1. Navigation : un clic sur chaque entree du rail change-t-il l'onglet ?
$nav = New-Object System.Collections.Generic.List[object]
if ($rail -and $tabs) {
    # Le rail dessine ses entrees a partir de y=92, hauteur 40, pas 44, avec un
    # en-tete de groupe de 26 px avant chaque nouveau groupe.
    $y = 92
    $groupe = $null
    for ($i = 0; $i -lt $rail.Items.Count; $i++) {
        if ($rail.Items[$i].Group -ne $groupe) {
            $groupe = $rail.Items[$i].Group
            if ($groupe) { $y += 26 }
        }
        $avant = $tabs.SelectedIndex
        Send-PfClick -Control $rail -X 100 -Y ($y + 20)
        $nav.Add([pscustomobject]@{
            index      = $i
            libelle    = [string]$rail.Items[$i].Label
            y          = $y
            avant      = $avant
            apres      = $tabs.SelectedIndex
            railIndex  = $rail.SelectedIndex
            titre      = if ($title) { [string]$title.Text } else { "" }
            ok         = ($tabs.SelectedIndex -eq $i)
        })
        $y += 44
    }
}
$r.navigation = $nav.ToArray()
$r.navigationOk = (@($nav | Where-Object { -not $_.ok }).Count -eq 0)

# --- 2. Une case a cocher reagit-elle a un clic ? -------------------------
$case = $flat | Where-Object {
    $_.GetType().Name -eq 'PfCheckBox' -and $_.Visible -and $_.Enabled } | Select-Object -First 1
if ($case) {
    $avant = $case.Checked
    Send-PfClick -Control $case -X 10 -Y ([int]($case.Height / 2))
    $r.caseAvant = $avant
    $r.caseApres = $case.Checked
    $r.caseOk = ($case.Checked -ne $avant)
} else {
    $r.caseOk = $false
}

# --- 3. Le survol change-t-il l'apparence ? -------------------------------
# On envoie WM_MOUSEMOVE puis WM_MOUSELEAVE et on compare le rendu du controle.
# Un etat de survol qui ne se voit pas est un etat qui n'existe pas.
$WM_MOUSEMOVE = 0x0200
$WM_MOUSELEAVE = 0x02A3

function Get-PfRender {
    param([System.Windows.Forms.Control]$Control)
    if ($Control.Width -lt 2 -or $Control.Height -lt 2) { return 0 }
    $bmp = New-Object System.Drawing.Bitmap($Control.Width, $Control.Height)
    try {
        $Control.DrawToBitmap($bmp, (New-Object System.Drawing.Rectangle(0, 0, $Control.Width, $Control.Height)))
        $somme = 0
        for ($x = 0; $x -lt $bmp.Width; $x += 3) {
            for ($y = 0; $y -lt $bmp.Height; $y += 3) { $somme += $bmp.GetPixel($x, $y).ToArgb() }
        }
        return $somme
    } finally { $bmp.Dispose() }
}

$survol = New-Object System.Collections.Generic.List[object]
foreach ($paire in @(
    @{ Nom = 'case a cocher'; Type = 'PfCheckBox' },
    @{ Nom = 'bouton';        Type = 'PfButton' },
    @{ Nom = 'liste';         Type = 'PfComboBox' })) {
    $cible = $flat | Where-Object { $_.GetType().Name -eq $paire.Type -and $_.Visible -and $_.Enabled } | Select-Object -First 1
    if (-not $cible) { continue }
    $avant = Get-PfRender -Control $cible
    $lp = [IntPtr](((([int]($cible.Height / 2)) -shl 16)) -bor ([int]($cible.Width / 2) -band 0xFFFF))
    [void][PfClick.Win]::SendMessage($cible.Handle, $WM_MOUSEMOVE, [IntPtr]0, $lp)
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 120
    $pendant = Get-PfRender -Control $cible
    [void][PfClick.Win]::SendMessage($cible.Handle, $WM_MOUSELEAVE, [IntPtr]0, [IntPtr]0)
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 120
    $apres = Get-PfRender -Control $cible
    $survol.Add([pscustomobject]@{
        controle = $paire.Nom
        change   = ($pendant -ne $avant)
        revient  = ($apres -eq $avant)
    })
}
$r.survol = $survol.ToArray()
$r.survolOk = (@($survol | Where-Object { -not $_.change }).Count -eq 0)

# --- 4. Le glisser de fenetre est-il branche ? ----------------------------
# On ne peut pas verifier un vrai deplacement sans souris physique : on verifie
# que la barre repond au clic hors des boutons sans lever d'exception, et
# qu'elle ne ferme pas la fenetre par erreur.
if ($bar) {
    try {
        Send-PfClick -Control $bar -X 200 -Y 20
        $r.glisserSansErreur = -not $form.IsDisposed
    } catch {
        $r.glisserSansErreur = $false
        $r.glisserErreur = $_.Exception.Message
    }
} else {
    $r.glisserSansErreur = $false
}

# --- 5. Le bouton de fermeture ferme-t-il vraiment ? ----------------------
# En dernier : il ferme la fenetre. Les boutons occupent les 46 px de droite,
# la fermeture etant le dernier.
$r.fermetureOk = $false
if ($bar) {
    $x = $bar.Width - 23
    try {
        Send-PfClick -Control $bar -X $x -Y 20
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 300
        [System.Windows.Forms.Application]::DoEvents()
        $r.fermetureOk = ($form.IsDisposed -or -not $form.Visible)
    } catch {
        $r.fermetureErreur = $_.Exception.Message
    }
}

$dir = Split-Path -Parent $pfOut
if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[IO.File]::WriteAllText($pfOut, ([pscustomobject]$r | ConvertTo-Json -Depth 6), [Text.UTF8Encoding]::new($false))

if (-not $form.IsDisposed) {
    $form.Close()
    $form.Dispose()
}
[System.Windows.Forms.Application]::DoEvents()
