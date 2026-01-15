#!/usr/bin/env pwsh
# Purpose : Ensure baseline docs exist when invoked from PowerShell.
# Why     : Keeps quickstart documentation in sync for Windows-first teams.
# How     : Seeds docs/quickstart.md and updates README with cross-links and a Feature Docs Index.

[CmdletBinding()]
param([string]$Feature)
$ErrorActionPreference = 'Stop'

try { $repoRoot = (git rev-parse --show-toplevel) } catch { $repoRoot = (Get-Location).Path }
Set-Location $repoRoot

if (-not (Test-Path docs/quickstart.md)) {
  New-Item -ItemType Directory -Force -Path docs | Out-Null
  if (Test-Path templates/quickstart-template.md) { Copy-Item templates/quickstart-template.md docs/quickstart.md } else { '# Quickstart' | Set-Content -Path docs/quickstart.md -Encoding UTF8 }
  Write-Host 'Created docs/quickstart.md'
}

if (Test-Path README.md) {
  $readme = Get-Content README.md -Raw
  if ($readme -notmatch 'Quickstart') { "`n## Quickstart`nSee docs/quickstart.md`n" | Add-Content -Path README.md }
  # Insert Feature Docs Index (idempotent)
  if ($readme -notmatch 'gobuildme:feature-docs-index') {
    . "$PSScriptRoot/common.ps1"
    $paths = Get-FeaturePathsEnv
    $featureDir = $paths.FEATURE_DIR
    "`n<!-- gobuildme:feature-docs-index -->`n## Feature Docs Index" | Add-Content -Path README.md
    if (Test-Path $featureDir) {
      $links = @(
        @{name='PRD'; file=(Join-Path $featureDir 'prd.md')},
        @{name='Request'; file=(Join-Path $featureDir 'request.md')},
        @{name='Spec'; file=(Join-Path $featureDir 'spec.md')},
        @{name='Plan'; file=(Join-Path $featureDir 'plan.md')},
        @{name='Tasks'; file=(Join-Path $featureDir 'tasks.md')},
        @{name='Design'; file=(Join-Path $featureDir 'design.md')}
      )
      foreach ($l in $links) { if (Test-Path $l.file) { "- $($l.name): `$($l.file)`" | Add-Content -Path README.md } }
    } else {
      "- Run /request or /specify to initialize a feature directory." | Add-Content -Path README.md
    }
  }
  Write-Host 'Updated README.md with Quickstart and Feature Docs Index'
}

Write-Host 'DOCS: updated'
