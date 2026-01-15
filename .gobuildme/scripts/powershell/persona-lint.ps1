#!/usr/bin/env pwsh
# persona-lint.ps1 — Advisory (exit 0) persona coverage checker
#
# Usage: persona-lint.ps1 [-Repo <path>] [-Feature <slug>] [-Json]

param(
  [string]$Repo = (Get-Location).Path,
  [string]$Feature = "",
  [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-TopLevelValue {
  param([string]$Path, [string]$Key)
  if (-not (Test-Path $Path)) { return "" }
  foreach ($line in (Get-Content -LiteralPath $Path -Encoding utf8 | Select-Object -First 80)) {
    $t = $line.TrimStart([char]0xFEFF)  # drop BOM
    if ($t -match "^$([Regex]::Escape($Key)):\s*(.*)$") { return $Matches[1].Trim().Trim('"') }
  }
  return ""
}

Push-Location $Repo
try {
  $specsRoot = Join-Path '.gobuildme' 'specs'
  if ($Feature) {
    $featureDir = Join-Path $specsRoot $Feature
  } elseif ($env:SPECIFY_FEATURE) {
    $featureDir = Join-Path $specsRoot $env:SPECIFY_FEATURE
  } else {
    $candidates = Get-ChildItem -LiteralPath $specsRoot -Recurse -Filter spec.md -ErrorAction SilentlyContinue | Select-Object -First 2
    if ($candidates.Count -eq 1) { $featureDir = $candidates[0].DirectoryName } else { $featureDir = '' }
  }

  $personaId = ''
  if ($featureDir) {
    $pf = Join-Path $featureDir 'persona.yaml'
    $personaId = Read-TopLevelValue -Path $pf -Key 'feature_persona'
  }
  if (-not $personaId) {
    $cfg = Join-Path (Join-Path '.gobuildme' 'config') 'personas.yaml'
    $personaId = Read-TopLevelValue -Path $cfg -Key 'default_persona'
  }

  $personaFile = Join-Path (Join-Path '.gobuildme' 'personas') ("{0}.yaml" -f $personaId)
  if (-not $personaId -or -not (Test-Path $personaFile)) {
    if ($Json) {
      Write-Output (ConvertTo-Json @{ ok=$true; reason='no-persona'; feature=$featureDir })
    } else {
      Write-Host '[persona-lint] No persona configured or file missing; skipping.'
    }
    exit 0
  }

  # Parse required_sections into an array of @{cmd=..; heading=..}
  $required = @()
  $inReq = $false; $current = ''
  foreach ($line in (Get-Content -LiteralPath $personaFile -Encoding utf8)) {
    if ($line -match '^required_sections:') { $inReq = $true; continue }
    if ($inReq -and $line -match '^[^ ]') { $inReq = $false }
    if (-not $inReq) { continue }
    if ($line -match '^[ ]{2}"/(.+)":') { $current = "/$($Matches[1])"; continue }
    if ($line -match '^[ ]{4}-[ ]*(.+)$') { $required += @{ cmd=$current; heading=$Matches[1].Trim() } }
  }

  $slug = if ($featureDir) { Split-Path $featureDir -Leaf } else { '' }
  $checks = @()
  foreach ($item in $required) {
    $cmd = $item.cmd; $heading = $item.heading
    $candidates = @()
    switch ($cmd) {
      '/request' { if ($featureDir) { $candidates += (Join-Path $featureDir 'request.md') } }
      '/specify' { if ($featureDir) { $candidates += (Join-Path $featureDir 'spec.md') } }
      '/plan'    { if ($featureDir) { $candidates += (Join-Path $featureDir 'plan.md') } }
      '/tests'   { if ($featureDir) { $candidates += (Join-Path $featureDir 'tests.md'); $candidates += (Join-Path $featureDir 'plan.md') } }
      '/review'  { if ($featureDir) { $candidates += (Join-Path $featureDir 'plan.md') }; if ($slug) { $candidates += (Join-Path (Join-Path '.docs/implementations' $slug) 'implementation-summary.md') } }
      default    { if ($featureDir) { $candidates += (Join-Path $featureDir 'plan.md') } }
    }
    $status = 'unknown'; $matchFile = $null
    foreach ($f in $candidates) {
      if (-not $f -or -not (Test-Path $f)) { continue }
      $content = Get-Content -LiteralPath $f -Encoding utf8 | Out-String
      if ($content -match [Regex]::Escape($heading)) { $status = 'present'; $matchFile = $f; break } else { $status = 'missing'; if (-not $matchFile) { $matchFile = $f } }
    }
    $checks += @{ command=$cmd; heading=$heading; file=$matchFile; status=$status }
  }

  if ($Json) {
    Write-Output (ConvertTo-Json @{ ok=$true; persona=$personaId; feature=$featureDir; checks=$checks })
  } else {
    foreach ($c in $checks) { Write-Host ("{0,-9} {1,-10} {2} ({3})" -f $c.command, $c.status, $c.heading, ($c.file ?? 'N/A')) }
  }
  exit 0
} finally {
  Pop-Location
}
