#requires -Version 5.1
<#
    Harnais de generation : lance le generateur en ligne de commande et rend une
    empreinte de sa sortie.

    Pourquoi une empreinte plutot qu'une inspection fine : les proprietes qui
    comptent pour un randomiseur se verifient par comparaison.

      - meme graine, memes options  -> sortie IDENTIQUE ;
      - graine differente           -> sortie DIFFERENTE ;
      - une option qui s'annonce active -> sortie DIFFERENTE de la meme
        generation sans elle.

    La troisieme est la plus importante. C'est exactement la classe de defaut
    consignee dans COMBAT-CACHE §15 : une regle de dresseur rendue TOTALEMENT
    inoperante par une collection PowerShell vide devenue $null, qui rapportait
    pourtant « applies = True ». Elle n'a ete trouvee qu'en mesurant les
    fichiers de sortie. Le meme defaut a frappe dex_animations.

    Une generation prend une quarantaine de secondes : cette suite est
    volontairement separee de celle de l'interface, qui doit rester rapide.
#>

$script:PfGenRoot = Split-Path -Parent $PSScriptRoot

function Get-PfDumpRomfs {
    <#
        Le dump de l'utilisateur. Rien n'en sort : il sert de source de lecture.
    #>
    $candidats = @(
        $env:PF_TEST_ROMFS,
        "C:\Users\Jonatan\Documents\sword\romfs"
    )
    foreach ($c in $candidats) {
        if ($c -and (Test-Path -LiteralPath $c)) { return $c }
    }
    return $null
}

function Invoke-PfGeneration {
    <#
        Lance une generation complete dans un dossier temporaire et rend son
        empreinte. `Options` est une table de parametres passes tels quels au
        generateur.
    #>
    param(
        [hashtable]$Options = @{},
        [int]$TimeoutSeconds = 600
    )

    $romfs = Get-PfDumpRomfs
    if (-not $romfs) { throw "Aucun dump ROMFS disponible (PF_TEST_ROMFS)." }

    $sortie = Join-Path ([IO.Path]::GetTempPath()) ("pf-gen-" + [Guid]::NewGuid().ToString('N'))

    # Invocation par -Command et NON par -File.
    #
    # Fait mesure : `powershell -File script.ps1 -Option:True` ECHOUE sur un
    # parametre declare [bool]. Aucune des quatre formes ne passe - `:True`,
    # ` True`, `:1`, ` 1` - parce que -File transmet des chaines litterales et
    # que PowerShell n'accepte pour un booleen que $True, $False, 1 ou 0
    # EVALUES. Or le generateur declare treize options en [bool] et non en
    # [switch] : NormalizeFriendshipEvolutions, NormalizeTradeEvolutions,
    # PatchStarterRelatedTrainers, EarlyBike, RuntimePcControls, les sept
    # InstallTo* et ExportJsonReport / ExportEncounterZoneReport.
    #
    # Ces treize options etaient donc impilotables depuis les tests - et depuis
    # tout raccourci ou script qui lance le generateur avec -File. Trouve en
    # generant un lot varie, pas par relecture.
    $arguments = New-Object System.Collections.Generic.List[string]
    $arguments.Add('-NoGui')
    $arguments.Add("-SourceRomfs '$romfs'")
    $arguments.Add("-OutputRomfs '$sortie'")
    $arguments.Add("-GameVersion 'Sword'")
    # Pas de dossier Installation pour les tests : c'est une copie de confort de
    # 6210 fichiers, elle ne prouve rien et ses poignees ouvertes faisaient
    # echouer les generations suivantes en cascade.
    $arguments.Add('-WriteInstallationPackage:$false')
    foreach ($cle in $Options.Keys) {
        $valeur = $Options[$cle]
        if ($valeur -is [bool] -or $valeur -is [switch]) {
            $arguments.Add(('-{0}:${1}' -f $cle, ([string][bool]$valeur).ToLowerInvariant()))
        } else {
            $arguments.Add(("-{0} '{1}'" -f $cle, ([string]$valeur).Replace("'", "''")))
        }
    }
    $script:PfGenScript = Join-Path $script:PfGenRoot 'CustomSwShRandomizer.ps1'
    $ligne = "& '{0}' {1}" -f $script:PfGenScript, ($arguments -join ' ')

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe')
    # Les guillemets internes sont doubles : la ligne entiere voyage entre
    # guillemets, et c'est le seul echappement que cmd/CreateProcess accepte ici.
    $psi.Arguments = '-NoProfile -ExecutionPolicy Bypass -Command "' + $ligne.Replace('"', '\"') + '"'
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $chrono = [Diagnostics.Stopwatch]::StartNew()
    $proc = [System.Diagnostics.Process]::Start($psi)
    $sortieStd = $proc.StandardOutput.ReadToEndAsync()
    $sortieErr = $proc.StandardError.ReadToEndAsync()
    if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
        try { $proc.Kill() } catch { }
        throw "La generation n'a pas rendu la main en $TimeoutSeconds s."
    }
    $chrono.Stop()

    $empreintes = @{}
    if (Test-Path -LiteralPath $sortie) {
        foreach ($f in (Get-ChildItem -LiteralPath $sortie -Recurse -File)) {
            $relatif = $f.FullName.Substring($sortie.Length + 1)
            # Les rapports portent un horodatage et des chemins absolus : ils
            # differeraient a chaque execution sans que la randomisation change.
            if ($relatif -like 'reports\*') { continue }
            $empreintes[$relatif] = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
        }
    }

    return [pscustomobject]@{
        Sortie      = $sortie
        CodeSortie  = $proc.ExitCode
        Secondes    = [math]::Round($chrono.Elapsed.TotalSeconds, 1)
        Fichiers    = $empreintes.Count
        Empreintes  = $empreintes
        Global      = (Get-PfGlobalHash -Empreintes $empreintes)
        Stderr      = $sortieErr.Result
    }
}

function Get-PfGlobalHash {
    <#
        Une seule empreinte pour toute la sortie : les chemins tries, chacun
        suivi de son hash. Deux sorties identiques donnent la meme chaine.
    #>
    param([hashtable]$Empreintes)
    if ($Empreintes.Count -eq 0) { return "" }
    $texte = ($Empreintes.Keys | Sort-Object | ForEach-Object { $_ + '=' + $Empreintes[$_] }) -join "`n"
    $octets = [Text.Encoding]::UTF8.GetBytes($texte)
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($octets)) -replace '-', '')
    } finally { $sha.Dispose() }
}

function Compare-PfGenerations {
    <#
        Renvoie les fichiers qui different entre deux generations. C'est ce qui
        permet de dire non seulement QU'une option change quelque chose, mais
        QUOI - et donc de reperer une option qui touche le mauvais fichier.
    #>
    param([object]$A, [object]$B)
    $differents = New-Object System.Collections.Generic.List[string]
    foreach ($cle in $A.Empreintes.Keys) {
        if (-not $B.Empreintes.ContainsKey($cle)) { $differents.Add("absent de B : $cle"); continue }
        if ($A.Empreintes[$cle] -ne $B.Empreintes[$cle]) { $differents.Add($cle) }
    }
    foreach ($cle in $B.Empreintes.Keys) {
        if (-not $A.Empreintes.ContainsKey($cle)) { $differents.Add("absent de A : $cle") }
    }
    return $differents.ToArray()
}

function Remove-PfGeneration {
    param([object]$Generation)
    if ($Generation -and $Generation.Sortie -and (Test-Path -LiteralPath $Generation.Sortie)) {
        Remove-Item -LiteralPath $Generation.Sortie -Recurse -Force -ErrorAction SilentlyContinue
    }
}
