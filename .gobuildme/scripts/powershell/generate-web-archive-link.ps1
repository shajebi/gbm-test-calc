#!/usr/bin/env pwsh
# generate-web-archive-link.ps1 - Generate Web Archive link for URL
# Usage: ./generate-web-archive-link.ps1 -Url <url>

param([string]$Url)

if (-not $Url) {
    Write-Error "Usage: generate-web-archive-link.ps1 -Url <url>"
    exit 1
}

$saveUrl = "https://web.archive.org/save/$Url"
$snapshotUrl = "https://web.archive.org/web/*/$Url"

Write-Output "save_url=$saveUrl"
Write-Output "snapshot_url=$snapshotUrl"
