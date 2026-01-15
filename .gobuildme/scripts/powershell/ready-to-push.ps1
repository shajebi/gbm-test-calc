#!/usr/bin/env pwsh
# Purpose : Execute the readiness checklist before `/push`.
# Why     : Gives Windows users the same preflight coverage as the bash helper.
# How     : Invokes format, lint, type, test, security, and branch status scripts sequentially.

[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

Write-Host '== Pre-commit: format =='; ./scripts/powershell/run-format.ps1
Write-Host '== Lint =='; ./scripts/powershell/run-lint.ps1
Write-Host '== Type check =='; ./scripts/powershell/run-type-check.ps1
Write-Host '== Tests =='; ./scripts/powershell/run-tests.ps1 -Json:$false
Write-Host '== Security =='; ./scripts/powershell/security-scan.ps1
Write-Host '== Branch status =='; ./scripts/powershell/branch-status.ps1

try {
  # Advisory PRD presence (non-blocking)
  . "$PSScriptRoot/common.ps1"
  $paths = Get-FeaturePathsEnv
  Write-Host '== PRD status =='
  if (Test-Path $paths.PRD) {
    Write-Host "PRD found: $($paths.PRD)"
  } else {
    Write-Host "PRD not found for current feature ($($paths.FEATURE_DIR)) — optional unless changing user behavior/commitments."
  }
} catch { }

Write-Host "`nAll checks executed. Review outputs above; if clean, you're ready to push."
