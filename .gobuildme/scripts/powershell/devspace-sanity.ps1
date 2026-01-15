#!/usr/bin/env pwsh
# Purpose: Non-destructive DevSpace sanity checks (optional advisory).
# Behavior: Never mutates cluster or devspace.yaml. Always exits 0.

param(
  [switch]$Json,
  [string]$Repo
)

$ErrorActionPreference = 'SilentlyContinue'

$hasCli = $false
$hasCfg = $false
$cliVersion = ''
$cfgPath = ''
$printOk = $false

if (-not $Repo -and $env:GOBUILDME_TARGET_REPO) { $Repo = $env:GOBUILDME_TARGET_REPO }
if (-not $Repo) { $Repo = (Get-Location).Path }

if (Get-Command devspace -ErrorAction SilentlyContinue) {
  $hasCli = $true
  $cliVersion = (devspace --version 2>$null | Select-Object -First 1)
}

foreach ($p in @('devspace.yaml','devspace.yml','.devspace/devspace.yaml')) {
  $candidate = Join-Path $Repo $p
  if (Test-Path $candidate -PathType Leaf) { $cfgPath = $candidate; $hasCfg = $true; break }
}

if ($hasCli -and $hasCfg) {
  try { Push-Location $Repo; devspace print config *> $null; Pop-Location; $printOk = $true } catch { try { Pop-Location } catch {}; $printOk = $false }
}

if ($Json) {
  $obj = [ordered]@{
    has_cli = $hasCli
    has_config = $hasCfg
    cli_version = "$cliVersion"
    config_path = "$cfgPath"
    print_config_ok = $printOk
  }
  $obj | ConvertTo-Json -Compress
} else {
  Write-Output ("DevSpace CLI: {0}{1}" -f ($hasCli ? 'present' : 'missing'), (if ($cliVersion) {" ($cliVersion)"} else {''}))
  Write-Output ("DevSpace config: {0}{1}" -f ($hasCfg ? 'found' : 'missing'), (if ($cfgPath) {" ($cfgPath)"} else {''}))
  if ($hasCli -and $hasCfg) {
    if ($printOk) { Write-Output 'Config parse: OK' } else { Write-Output 'Config parse: WARNING (devspace print config failed)' }
  }
}

exit 0
