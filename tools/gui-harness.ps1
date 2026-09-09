#requires -Version 5.1
<#
    Harnais d'interface : fait construire la VRAIE fenetre du generateur, la
    fait inspecter de l'interieur, et renvoie le rapport.

    `Show-Gui` se termine par `$form.ShowDialog()`, qui bloque jusqu'a la
    fermeture par l'utilisateur. On lit donc le generateur, on remplace cette
    seule ligne par un appel a `tools/gui-inspect.ps1`, et on execute la copie.
    Le projet n'est jamais modifie : la substitution vit dans un temporaire.

    L'inspection tourne DANS le scope du generateur, et non depuis ici.
    Rendre la fenetre a l'exterieur puis laisser le script se terminer detruit
    le scope auquel sont lies ses gestionnaires : au premier repaint,
    `Get-GuiThemePalette` n'existe plus, WinForms ouvre une boite modale et
    tout se bloque. Constate, puis corrige ainsi.
#>

function Get-PfGeneratorPath {
    return (Join-Path (Split-Path -Parent $PSScriptRoot) 'CustomSwShRandomizer.ps1')
}

function Invoke-PfGuiInspection {
    <#
        Renvoie l'objet rapport. Lance un processus separe : si l'interface
        plante, elle n'emporte pas la session de test avec elle.
    #>
    param(
        [string]$Theme = 'Dark',
        [string]$Language = 'fr',
        [string]$ImageDir = "",
        [int]$TimeoutSeconds = 180
    )

    $toolsDir = $PSScriptRoot
    $racine = Split-Path -Parent $PSScriptRoot
    $src = Get-PfGeneratorPath
    $srcUi = Join-Path $racine 'src\Interface.ps1'
    if (-not (Test-Path -LiteralPath $src)) { throw "Generateur introuvable : $src" }
    if (-not (Test-Path -LiteralPath $srcUi)) { throw "Couche interface introuvable : $srcUi" }

    $sansBom = {
        param([string]$chemin)
        $t = [IO.File]::ReadAllText($chemin)
        if ($t.Length -gt 0 -and [int]$t[0] -eq 0xFEFF) { $t = $t.Substring(1) }
        return $t
    }
    $text = & $sansBom $src
    $textUi = & $sansBom $srcUi

    # Show-Gui vit desormais dans src/Interface.ps1. On patche donc DEUX
    # fichiers : l'interface, pour remplacer ShowDialog par l'inspecteur, et le
    # script principal, pour qu'il charge la copie patchee au lieu de
    # l'originale.
    $mark = '    [void]$form.ShowDialog()'
    $count = ([regex]::Matches($textUi, [regex]::Escape($mark))).Count
    if ($count -ne 1) { throw "Ancre ShowDialog trouvee $count fois : le harnais doit etre mis a jour." }

    $inspector = (Join-Path $toolsDir 'gui-inspect.ps1')
    $patchedUi = $textUi.Replace($mark, ("    . '" + $inspector + "'"))

    $stamp = [Guid]::NewGuid().ToString('N')
    # Les deux copies restent DANS le projet, pas dans %TEMP% : le script
    # principal se sert de $PSScriptRoot pour trouver items.csv, npc-gifts.csv
    # et son dossier de sortie. Le deplacer casserait toutes ces resolutions.
    $tmpUi = Join-Path $racine ("src\pf-harness-" + $stamp + ".ps1")
    $tmpScript = Join-Path $racine ("pf-harness-" + $stamp + ".ps1")

    $ancre = ". (Join-Path `$PSScriptRoot 'src\Interface.ps1')"
    if ($text.IndexOf($ancre) -lt 0) { throw "Ancre du point-source introuvable dans le script principal." }
    $patched = $text.Replace($ancre, (". (Join-Path `$PSScriptRoot 'src\pf-harness-" + $stamp + ".ps1')"))

    $report = Join-Path ([IO.Path]::GetTempPath()) ("pf-gui-" + $stamp + ".json")
    if (-not $ImageDir) { $ImageDir = Join-Path ([IO.Path]::GetTempPath()) ("pf-gui-" + $stamp) }
    [IO.File]::WriteAllText($tmpUi, $patchedUi, [Text.UTF8Encoding]::new($true))
    [IO.File]::WriteAllText($tmpScript, $patched, [Text.UTF8Encoding]::new($true))

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe')
    $psi.Arguments = ('-NoProfile -ExecutionPolicy Bypass -File "{0}" -GuiTheme {1} -UiLanguage {2}' -f $tmpScript, $Theme, $Language)
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $psi.EnvironmentVariables['PF_TEST_REPORT'] = $report
    $psi.EnvironmentVariables['PF_TEST_IMAGES'] = $ImageDir

    $proc = [System.Diagnostics.Process]::Start($psi)
    $out = $proc.StandardOutput.ReadToEndAsync()
    $err = $proc.StandardError.ReadToEndAsync()
    if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
        try { $proc.Kill() } catch { }
        Remove-Item -LiteralPath $tmpScript -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $tmpUi -Force -ErrorAction SilentlyContinue
        throw "L'interface n'a pas rendu la main en $TimeoutSeconds s."
    }
    $stdout = $out.Result
    $stderr = $err.Result
    Remove-Item -LiteralPath $tmpUi -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tmpScript -Force -ErrorAction SilentlyContinue

    if (-not (Test-Path -LiteralPath $report)) {
        throw ("Aucun rapport produit (code {0}).`n{1}`n{2}" -f $proc.ExitCode, $stdout, $stderr)
    }
    $json = [IO.File]::ReadAllText($report)
    Remove-Item -LiteralPath $report -Force -ErrorAction SilentlyContinue

    $obj = $json | ConvertFrom-Json
    Add-Member -InputObject $obj -NotePropertyName 'exitCode' -NotePropertyValue $proc.ExitCode -Force
    Add-Member -InputObject $obj -NotePropertyName 'stderr' -NotePropertyValue $stderr -Force
    Add-Member -InputObject $obj -NotePropertyName 'imageDir' -NotePropertyValue $ImageDir -Force
    return $obj
}
