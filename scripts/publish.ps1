param(
    [ValidateSet("Saved", "Published")]
    [string]$VersionType = "Saved"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

$required = @(
    "ROBLOX_API_KEY",
    "ROBLOX_ALL_AGES_UNIVERSE_ID",
    "ROBLOX_ALL_AGES_PLACE_ID"
)

foreach ($name in $required) {
    if (-not [Environment]::GetEnvironmentVariable($name)) {
        throw "Missing environment variable: $name"
    }
}

$apiKey = [Environment]::GetEnvironmentVariable("ROBLOX_API_KEY")
$targets = @(
    @{
        Name = "All Ages"
        UniverseId = [Environment]::GetEnvironmentVariable("ROBLOX_ALL_AGES_UNIVERSE_ID")
        PlaceId = [Environment]::GetEnvironmentVariable("ROBLOX_ALL_AGES_PLACE_ID")
        File = "$root\build\ArtAcademy-AllAges.rbxlx"
    }
)

foreach ($target in $targets) {
    if (-not (Test-Path $target.File)) {
        throw "Missing place build: $($target.File). Run scripts\verify.ps1 first."
    }
    $url = "https://apis.roblox.com/universes/v1/$($target.UniverseId)/places/$($target.PlaceId)/versions?versionType=$VersionType"
    $response = & curl.exe `
        --fail-with-body `
        --silent `
        --show-error `
        --request POST `
        --header "x-api-key: $apiKey" `
        --header "Content-Type: application/xml" `
        --data-binary "@$($target.File)" `
        $url
    if ($LASTEXITCODE -ne 0) {
        throw "$($target.Name) upload failed."
    }
    $result = $response | ConvertFrom-Json
    if (-not $result.versionNumber) {
        throw "$($target.Name) returned no version number."
    }
    Write-Host "$($target.Name): uploaded version $($result.versionNumber) as $VersionType."
}

Write-Host "The All Ages Roblox place uploaded successfully."
