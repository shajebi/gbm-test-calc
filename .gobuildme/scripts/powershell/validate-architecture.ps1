#!/usr/bin/env pwsh
# Purpose : Enforce architecture constraints from PowerShell.
# Why     : Keeps boundary checks available when bash is unavailable.
# How     : Delegates to Augment when present then performs heuristic import scans.

[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

try { $repoRoot = (git rev-parse --show-toplevel) } catch { $repoRoot = (Get-Location).Path }
Set-Location $repoRoot

$errors = 0
if (Get-Command augment -ErrorAction SilentlyContinue) {
  try { augment validate architecture } catch { $errors++ }
}

if (Test-Path services -and Test-Path api) {
  try {
    $first = rg -n "from\s+api|import\s+api" services 2>$null | Select-Object -First 1
    if ($first) { Write-Error 'Boundary violation: services -> api import detected'; $errors++ }
  } catch {}
}

# Additional boundary checks
if (Test-Path frontend -and Test-Path backend) {
  try {
    $first = rg -n "from\s+backend|import\s+backend" frontend 2>$null | Select-Object -First 1
    if ($first) { Write-Error 'Boundary violation: frontend -> backend import detected'; $errors++ }
  } catch {}
}

# Check for direct database access from presentation layer
if (Test-Path controllers -and Test-Path models) {
  try {
    $first = rg -n "SELECT|INSERT|UPDATE|DELETE" controllers --type py --type js --type ts 2>$null | Select-Object -First 1
    if ($first) { Write-Error 'Boundary violation: Direct SQL in controllers detected (should use models/services)'; $errors++ }
  } catch {}
}

if ($errors -gt 0) { Write-Error "Architecture validation failed ($errors issue(s))"; exit 1 }
Write-Host 'Architecture validation passed'

