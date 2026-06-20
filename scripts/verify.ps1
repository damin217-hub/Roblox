param(
    [switch]$RunStudio
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$rojo = Get-ChildItem "$root\tools\rojo-x64" -Filter rojo.exe -Recurse | Select-Object -First 1
$selene = Get-ChildItem "$root\tools\selene" -Filter selene.exe -Recurse | Select-Object -First 1
$studio = $null
if ($RunStudio) {
    $studio = Get-ChildItem "$env:LOCALAPPDATA\Roblox\Versions" -Filter RobloxStudioBeta.exe -Recurse |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

if (-not $rojo -or -not $selene) {
    throw "Rojo or Selene is missing."
}
if ($RunStudio -and -not $studio) {
    throw "Roblox Studio is missing."
}

New-Item -ItemType Directory -Force "$root\build" | Out-Null

& $selene.FullName "$root\src" "$root\tests"
if ($LASTEXITCODE -ne 0) { throw "Selene failed." }

& $rojo.FullName build "$root\all-ages.project.json" -o "$root\build\ArtAcademy-AllAges.rbxlx"
if ($LASTEXITCODE -ne 0) { throw "All Ages build failed." }
& $rojo.FullName build "$root\free-draw.project.json" -o "$root\build\ArtAcademy-FreeDraw16Plus.rbxlx"
if ($LASTEXITCODE -ne 0) { throw "Free Draw build failed." }

$targets = @(
    @{ Name = "all-ages"; Place = "$root\build\ArtAcademy-AllAges.rbxlx"; Output = "$root\build\studio-smoke-all-ages.log" },
    @{ Name = "free-draw"; Place = "$root\build\ArtAcademy-FreeDraw16Plus.rbxlx"; Output = "$root\build\studio-smoke-free-draw.log" }
)

$launchedProcesses = @()
$baselineStudioProcessIds = @()
if ($RunStudio) {
    $baselineStudioProcessIds = @(
        Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty Id
    )
}

if (-not $RunStudio) {
    Write-Host "Static verification complete. Use -RunStudio to run the eight hidden Studio checks."
    return
}

try {
foreach ($target in $targets) {
    Remove-Item $target.Output -ErrorAction SilentlyContinue
    $smokeProcess = Start-Process -FilePath $studio.FullName -WindowStyle Hidden -PassThru -ArgumentList @(
        "--task", "RunScript",
        "--localPlaceFile", "`"$($target.Place)`"",
        "--runScriptFile", "`"$root\tests\studio_smoke.luau`"",
        "--outputFile", "`"$($target.Output)`"",
        "--quitAfterExecution"
    )
    $launchedProcesses += $smokeProcess

    $complete = $false
    for ($attempt = 0; $attempt -lt 90; $attempt++) {
        Start-Sleep -Seconds 1
        if (Test-Path $target.Output) {
            $content = Get-Content $target.Output -Raw
            $complete = $content -and [regex]::IsMatch($content, "(?m)^\[SMOKE COMPLETE\]")
            if ($complete) { break }
        }
    }
    if (-not $complete) { throw "$($target.Name) Studio smoke test did not complete." }
    if ([regex]::IsMatch($content, "(?m)^.*(Stack Begin|Requested module experienced).*$")) {
        throw "$($target.Name) Studio smoke test contains runtime errors."
    }
    $passes = ([regex]::Matches($content, "(?m)^\[PASS\]")).Count
    Write-Host "$($target.Name): $passes Studio smoke checks passed."
    if (-not $smokeProcess.HasExited) {
        $smokeProcess.WaitForExit(15000) | Out-Null
    }
    if (-not $smokeProcess.HasExited) {
        Stop-Process -Id $smokeProcess.Id -Force
    }

    $runtimeOutput = "$root\build\runtime-$($target.Name).log"
    Remove-Item $runtimeOutput -ErrorAction SilentlyContinue
    $runtimeProcess = Start-Process -FilePath $studio.FullName -WindowStyle Hidden -PassThru -ArgumentList @(
        "--task", "RunScript",
        "--localPlaceFile", "`"$($target.Place)`"",
        "--runScriptFile", "`"$root\tests\runtime_boot.luau`"",
        "--outputFile", "`"$runtimeOutput`"",
        "--quitAfterExecution"
    )
    $launchedProcesses += $runtimeProcess
    $runtimeComplete = $false
    for ($attempt = 0; $attempt -lt 90; $attempt++) {
        Start-Sleep -Seconds 1
        if (Test-Path $runtimeOutput) {
            $runtimeContent = Get-Content $runtimeOutput -Raw
            $runtimeComplete = $runtimeContent -and [regex]::IsMatch($runtimeContent, "(?m)^\[RUNTIME COMPLETE\]")
            if ($runtimeComplete) { break }
        }
    }
    if (-not $runtimeComplete) { throw "$($target.Name) runtime bootstrap test did not complete." }
    if (
        [regex]::IsMatch($runtimeContent, "(?m)^Stack Begin$") -or
        [regex]::IsMatch($runtimeContent, "(?m)^Requested module experienced") -or
        [regex]::IsMatch($runtimeContent, "(?m)^\[FAIL\]")
    ) {
        throw "$($target.Name) runtime bootstrap test contains errors."
    }
    $runtimePasses = ([regex]::Matches($runtimeContent, "(?m)^\[PASS\]")).Count
    Write-Host "$($target.Name): $runtimePasses runtime bootstrap checks passed."
    if (-not $runtimeProcess.HasExited) {
        $runtimeProcess.WaitForExit(15000) | Out-Null
    }
    if (-not $runtimeProcess.HasExited) {
        Stop-Process -Id $runtimeProcess.Id -Force
    }

    $scenarioOutput = "$root\build\scenario-$($target.Name).log"
    Remove-Item $scenarioOutput -ErrorAction SilentlyContinue
    $scenarioProcess = Start-Process -FilePath $studio.FullName -WindowStyle Hidden -PassThru -ArgumentList @(
        "--task", "RunScript",
        "--localPlaceFile", "`"$($target.Place)`"",
        "--runScriptFile", "`"$root\tests\match_scenario.luau`"",
        "--outputFile", "`"$scenarioOutput`"",
        "--quitAfterExecution"
    )
    $launchedProcesses += $scenarioProcess
    $scenarioComplete = $false
    for ($attempt = 0; $attempt -lt 90; $attempt++) {
        Start-Sleep -Seconds 1
        if (Test-Path $scenarioOutput) {
            $scenarioContent = Get-Content $scenarioOutput -Raw
            $scenarioComplete = $scenarioContent -and [regex]::IsMatch($scenarioContent, "(?m)^\[SCENARIO COMPLETE\]")
            if ($scenarioComplete) { break }
        }
    }
    if (-not $scenarioComplete) { throw "$($target.Name) match scenario test did not complete." }
    if (
        [regex]::IsMatch($scenarioContent, "(?m)^Stack Begin$") -or
        [regex]::IsMatch($scenarioContent, "(?m)^Requested module experienced") -or
        [regex]::IsMatch($scenarioContent, "(?m)^\[FAIL\]")
    ) {
        throw "$($target.Name) match scenario test contains errors."
    }
    $scenarioPasses = ([regex]::Matches($scenarioContent, "(?m)^\[PASS\]")).Count
    Write-Host "$($target.Name): $scenarioPasses full-match scenario checks passed."
    if (-not $scenarioProcess.HasExited) {
        $scenarioProcess.WaitForExit(15000) | Out-Null
    }
    if (-not $scenarioProcess.HasExited) {
        Stop-Process -Id $scenarioProcess.Id -Force
    }

    $departureOutput = "$root\build\departure-$($target.Name).log"
    Remove-Item $departureOutput -ErrorAction SilentlyContinue
    $departureProcess = Start-Process -FilePath $studio.FullName -WindowStyle Hidden -PassThru -ArgumentList @(
        "--task", "RunScript",
        "--localPlaceFile", "`"$($target.Place)`"",
        "--runScriptFile", "`"$root\tests\departure_scenario.luau`"",
        "--outputFile", "`"$departureOutput`"",
        "--quitAfterExecution"
    )
    $launchedProcesses += $departureProcess
    $departureComplete = $false
    for ($attempt = 0; $attempt -lt 90; $attempt++) {
        Start-Sleep -Seconds 1
        if (Test-Path $departureOutput) {
            $departureContent = Get-Content $departureOutput -Raw
            $departureComplete = $departureContent -and [regex]::IsMatch($departureContent, "(?m)^\[DEPARTURE COMPLETE\]")
            if ($departureComplete) { break }
        }
    }
    if (-not $departureComplete) { throw "$($target.Name) departure scenario test did not complete." }
    if (
        [regex]::IsMatch($departureContent, "(?m)^Stack Begin$") -or
        [regex]::IsMatch($departureContent, "(?m)^Requested module experienced") -or
        [regex]::IsMatch($departureContent, "(?m)^\[FAIL\]")
    ) {
        throw "$($target.Name) departure scenario test contains errors."
    }
    $departurePasses = ([regex]::Matches($departureContent, "(?m)^\[PASS\]")).Count
    Write-Host "$($target.Name): $departurePasses departure recovery checks passed."
    if (-not $departureProcess.HasExited) {
        $departureProcess.WaitForExit(15000) | Out-Null
    }
    if (-not $departureProcess.HasExited) {
        Stop-Process -Id $departureProcess.Id -Force
    }
}
} finally {
    foreach ($launchedProcess in $launchedProcesses) {
        if ($launchedProcess -and -not $launchedProcess.HasExited) {
            Stop-Process -Id $launchedProcess.Id -Force -ErrorAction SilentlyContinue
        }
    }
    Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue |
        Where-Object { $baselineStudioProcessIds -notcontains $_.Id } |
        Stop-Process -Force -ErrorAction SilentlyContinue
}

Write-Host "Verification complete."
