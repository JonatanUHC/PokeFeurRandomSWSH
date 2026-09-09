#requires -Version 5.1
<#
    Lance la suite de tests et renvoie un code de sortie utilisable par un
    script ou une chaine de build.

    Pester 3.4 est livre avec Windows : rien a installer.

        powershell -ExecutionPolicy Bypass -File tools/run-tests.ps1
        powershell -ExecutionPolicy Bypass -File tools/run-tests.ps1 -Lentes

    Par defaut, les tests etiquetes « Lent » sont ecartes. Ce sont ceux de la
    randomisation : chacun lance une generation complete d'une quarantaine de
    secondes, et il y en a trente-six. Les garder dans le passage courant rendrait la
    suite trop lente pour etre lancee souvent - et une suite qu'on ne lance pas
    ne sert a rien.
#>
param(
    [string]$Path = "",
    [switch]$Lentes,
    [switch]$SeulementLentes
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not $Path) { $Path = Join-Path $root 'tests' }

$pester = Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending | Select-Object -First 1
if (-not $pester) {
    Write-Host "ECHEC: Pester introuvable. Install-Module Pester -Scope CurrentUser"
    exit 1
}
Import-Module $pester.Path -Force
Write-Host ("Pester {0}" -f $pester.Version)
Write-Host ("Tests  {0}" -f $Path)

$parametres = @{ Path = $Path; PassThru = $true }
if ($SeulementLentes) {
    $parametres.Tag = 'Lent'
    Write-Host "Portee : tests lents uniquement (generations completes)"
} elseif ($Lentes) {
    Write-Host "Portee : tout, tests lents compris (comptez plusieurs minutes)"
} else {
    $parametres.ExcludeTag = 'Lent'
    Write-Host "Portee : rapide. -Lentes pour ajouter les tests de randomisation."
}
Write-Host ""

$result = Invoke-Pester @parametres

Write-Host ""
Write-Host ("Reussis {0}  Echoues {1}  Ignores {2}" -f $result.PassedCount, $result.FailedCount, $result.SkippedCount)
if ($result.FailedCount -gt 0) { exit 1 }
exit 0
