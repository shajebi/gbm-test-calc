#!/usr/bin/env pwsh
# verify-url-accessibility.ps1 - Check if URLs are accessible
# Usage: ./verify-url-accessibility.ps1 -Url <url>

param([string]$Url)

if (-not $Url) {
    Write-Error "Usage: verify-url-accessibility.ps1 -Url <url>"
    exit 1
}

try {
    $response = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 10 -ErrorAction Stop
    if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
        Write-Output "accessible"
        exit 0
    }
} catch {
    Write-Output "inaccessible ($($_.Exception.Message))"
    exit 1
}
