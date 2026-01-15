#!/usr/bin/env pwsh
<#!
.SYNOPSIS
Advisory observability sanity check for OpenTelemetry + Coralogix

.DESCRIPTION
- Non-destructive, always exits 0
- Checks for collector config, ENV_VARS.md, SLO files, and Coralogix-based SLIs

.PARAMETER Repo
Target repository path (defaults to current directory or $env:GOBUILDME_TARGET_REPO)

.EXAMPLE
./observability-sanity.ps1 -Repo C:\src\my-service
#>
param(
  [string]$Repo,
  [switch]$Json
)

# Resolve target repo
if (-not $Repo -and $env:GOBUILDME_TARGET_REPO) { $Repo = $env:GOBUILDME_TARGET_REPO }
if (-not $Repo) { $Repo = (Get-Location).Path }

$hasCollector = $false
$collectorPath = Join-Path $Repo '.gobuildme/observability/collector/otel-collector.yaml'
$collectorHasKey = $false
$collectorHasDomain = $false
$hasEnvDoc = $false
$sloCount = 0
$coralogixSlis = 0
$alertsFiles = 0

# Collector
if (Test-Path $collectorPath) {
  $hasCollector = $true
  try {
    $content = Get-Content -LiteralPath $collectorPath -Raw -Encoding utf8
    if ($content -match 'CORALOGIX_PRIVATE_KEY') { $collectorHasKey = $true }
    if ($content -match 'CORALOGIX_DOMAIN') { $collectorHasDomain = $true }
  } catch {}
}

# ENV_VARS.md
$envDoc = Join-Path $Repo '.gobuildme/observability/ENV_VARS.md'
if (Test-Path $envDoc) { $hasEnvDoc = $true }

# SLO scan
$specs = Join-Path $Repo '.gobuildme/specs'
if (Test-Path $specs) {
  Get-ChildItem -Path $specs -Filter 'slo.yaml' -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
    $sloCount++
    try {
      $s = Get-Content -LiteralPath $_.FullName -Raw -Encoding utf8
      if ($s -match '(?im)^\s*backend:\s*coralogix\b') { $coralogixSlis++ }
      if ($s -match '(?m)^alerts:') { $alertsFiles++ }
    } catch {}
  }
}

if ($Json) {
  $obj = [pscustomobject]@{
    target = $Repo
    collector = $hasCollector
    collector_path = $collectorPath
    collector_has_key = $collectorHasKey
    collector_has_domain = $collectorHasDomain
    has_env_doc = $hasEnvDoc
    slo_files = $sloCount
    coralogix_slis = $coralogixSlis
    alerts_files = $alertsFiles
  }
  $obj | ConvertTo-Json -Compress
  exit 0
}

Write-Host "🔍 Observability Sanity Check"
Write-Host "Target: $Repo"; Write-Host
if ($hasCollector) { Write-Host "✓ Collector config: $collectorPath" } else { Write-Host "⚠️ Collector config not found" }
if ($hasCollector) {
  Write-Host "  - CORALOGIX_PRIVATE_KEY placeholder: " -NoNewline; Write-Host ($collectorHasKey ? 'OK' : 'MISSING')
  Write-Host "  - CORALOGIX_DOMAIN placeholder: " -NoNewline; Write-Host ($collectorHasDomain ? 'OK' : 'MISSING')
}
Write-Host ($(if ($hasEnvDoc) { '✓' } else { '⚠️' }) + ' ENV_VARS.md present')
if ($sloCount -gt 0) {
  Write-Host "✓ SLO files found: $sloCount"
  Write-Host "  - Coralogix-based SLIs: $coralogixSlis"
  Write-Host "  - SLO files with alerts: $alertsFiles"
} else {
  Write-Host "⚠️ No SLO files found under .gobuildme/specs"
}
Write-Host
Write-Host ('━' * 60)
Write-Host '✅ Advisory check complete (exit code always 0)'
exit 0

