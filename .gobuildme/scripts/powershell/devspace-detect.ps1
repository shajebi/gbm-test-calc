#!/usr/bin/env pwsh
# Purpose: Minimal DevSpace detection emitting JSON booleans. Always exits 0.

param(
  [string]$Repo
)

if (-not $Repo -and $env:GOBUILDME_TARGET_REPO) { $Repo = $env:GOBUILDME_TARGET_REPO }
if (-not $Repo) { $Repo = (Get-Location).Path }

$hasCli = [bool](Get-Command devspace -ErrorAction SilentlyContinue)
$hasCfg = $false
$cfgPath = ''

foreach ($p in @('devspace.yaml','devspace.yml','.devspace/devspace.yaml')) {
  $candidate = Join-Path $Repo $p
  if (Test-Path $candidate -PathType Leaf) { $cfgPath = $candidate; $hasCfg = $true; break }
}

@{
  has_cli = $hasCli
  has_config = $hasCfg
  config_path = $cfgPath
} | ConvertTo-Json -Compress

exit 0
