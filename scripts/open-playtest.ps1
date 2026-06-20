param(
    [ValidateSet("AllAges", "FreeDraw")]
    [string]$Experience = "AllAges"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

$existing = Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue
if ($existing) {
    throw "Roblox Studio is already running. Save and close it before starting a clean local playtest."
}

$studio = Get-ChildItem "$env:LOCALAPPDATA\Roblox\Versions" -Filter RobloxStudioBeta.exe -Recurse |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
if (-not $studio) {
    throw "Roblox Studio is not installed."
}

$placeName = if ($Experience -eq "AllAges") {
    "ArtAcademy-AllAges.rbxlx"
} else {
    "ArtAcademy-FreeDraw16Plus.rbxlx"
}
$place = Join-Path "$root\build" $placeName
if (-not (Test-Path -LiteralPath $place)) {
    throw "Missing $placeName. Run scripts\verify.ps1 first."
}

$process = Start-Process -FilePath $studio.FullName -PassThru -ArgumentList @(
    "--task", "EditFile",
    "--localPlaceFile", "`"$place`""
)

Write-Host "Opened one local Studio session for $Experience."
Write-Host "Place: $place"
Write-Host "Studio process ID: $($process.Id)"
Write-Host "Press Play in Studio and follow docs\MANUAL_PLAYTEST.md."
