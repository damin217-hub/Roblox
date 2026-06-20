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

if (-not $RunStudio) {
    Write-Host "Static verification complete. Use -RunStudio to run the four hidden Studio checks."
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
}
} finally {
    foreach ($launchedProcess in $launchedProcesses) {
        if ($launchedProcess -and -not $launchedProcess.HasExited) {
            Stop-Process -Id $launchedProcess.Id -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "Verification complete."
