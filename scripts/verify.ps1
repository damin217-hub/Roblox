$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$rojo = Get-ChildItem "$root\tools\rojo-x64" -Filter rojo.exe -Recurse | Select-Object -First 1
$selene = Get-ChildItem "$root\tools\selene" -Filter selene.exe -Recurse | Select-Object -First 1
$studio = Get-ChildItem "$env:LOCALAPPDATA\Roblox\Versions" -Filter RobloxStudioBeta.exe -Recurse |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $rojo -or -not $selene -or -not $studio) {
    throw "Rojo, Selene, or Roblox Studio is missing."
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

foreach ($target in $targets) {
    Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 1
    Remove-Item $target.Output -ErrorAction SilentlyContinue
    Start-Process -FilePath $studio.FullName -WindowStyle Hidden -ArgumentList @(
        "--task", "RunScript",
        "--localPlaceFile", "`"$($target.Place)`"",
        "--runScriptFile", "`"$root\tests\studio_smoke.luau`"",
        "--outputFile", "`"$($target.Output)`"",
        "--quitAfterExecution"
    )

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
}

Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "Verification complete."
