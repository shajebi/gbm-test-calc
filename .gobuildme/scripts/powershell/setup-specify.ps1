#!/usr/bin/env pwsh
# Purpose : Prepare the `/specify` phase for PowerShell users.
# Why     : Respects existing requests and seeds spec templates without relying on bash.
# How     : Detects/reuses feature folders, copies spec templates, and outputs file paths.

[CmdletBinding()]
param(
  [switch]$Json,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FeatureDescription
)
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/common.ps1"
$repoRoot = Get-RepoRoot
Set-Location $repoRoot
$current = Get-CurrentBranch
$specsDir = Join-Path $repoRoot '.gobuildme/specs'
New-Item -ItemType Directory -Path $specsDir -Force | Out-Null

function Test-SpecMissingOrEmpty {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return $true }
  $content = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
  if (-not $content) { return $true }
  if ($content -match '\S') { return $false } else { return $true }
}

function Find-ReusableFeature {
  $candidate = $null
  $highest = -1
  if (Test-Path $specsDir) {
    Get-ChildItem -Path $specsDir -Directory | ForEach-Object {
      if ($_.Name -match '^(\d{3})-') {
        $num = [int]$matches[1]
        $dir = $_.FullName
        $requestFile = Join-Path $dir 'request.md'
        $specFile = Join-Path $dir 'spec.md'
        if ((Test-Path $requestFile) -and (Test-SpecMissingOrEmpty $specFile)) {
          if ($num -gt $highest) { $highest = $num; $candidate = $_.Name }
        }
      }
    }
  }
  return $candidate
}

# Prefer current feature branch when on one (check if feature directory exists)
$branch = $current
$featureDirFromBranch = Get-FeatureDir -RepoRoot $repoRoot -Branch $branch
if (-not (Test-Path $featureDirFromBranch -PathType Container)) {
  # Not on a feature branch with existing specs; try to reuse latest request-only folder
  $reuse = Find-ReusableFeature
  if ($reuse) {
    $branch = $reuse
  } else {
    # No reusable folder; create new feature via existing generator
    $argsJoined = ($FeatureDescription -join ' ')
    try {
      $jsonOutput = & "$PSScriptRoot/create-new-feature.ps1" -Json $argsJoined
      if (-not $jsonOutput) { throw "create-new-feature.ps1 returned empty output." }
      $o = $jsonOutput | ConvertFrom-Json
    } catch {
      throw "create-new-feature.ps1 failed: $_"
    }
    $newBranch = $o.BRANCH_NAME
    if (-not $newBranch) { throw "Failed to parse new branch name from create-new-feature output." }
    # Only verify/checkout if we're in a git repo
    $isGitRepo = git rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -eq 0) {
      git rev-parse --verify $newBranch 2>$null | Out-Null
      if ($LASTEXITCODE -ne 0) { throw "New branch '$newBranch' not found after creation." }
      if (-not (git checkout $newBranch 2>$null)) { throw "Failed to switch to new branch '$newBranch'." }
    }
    if ($Json) { $jsonOutput; exit 0 }
    Write-Output "BRANCH_NAME: $($o.BRANCH_NAME)"
    Write-Output "SPEC_FILE: $($o.SPEC_FILE)"
    Write-Output "REQUEST_FILE: $($o.REQUEST_FILE)"
    Write-Output "FEATURE_DIR: $($o.FEATURE_DIR)"
    exit 0
  }
}

$featureDir = Get-FeatureDir -RepoRoot $repoRoot -Branch $branch
New-Item -ItemType Directory -Path $featureDir -Force | Out-Null
$requestFile = Join-Path $featureDir 'request.md'
$specFile = Join-Path $featureDir 'spec.md'

# Ensure spec.md exists when missing/empty; seed from template
if (Test-SpecMissingOrEmpty $specFile) {
  $tpl = Join-Path $repoRoot '.gobuildme/templates/spec-template.md'
  if (-not (Test-Path $tpl)) { $tpl = Join-Path $repoRoot 'templates/spec-template.md' }
  if (Test-Path $tpl) { Copy-Item $tpl $specFile -Force } else { New-Item -ItemType File -Path $specFile | Out-Null }
}

# Run architecture analysis to support specification creation
# This ensures architectural context is available when creating specifications
$archScript = Join-Path $PSScriptRoot 'analyze-architecture.ps1'
if (Test-Path $archScript) {
  # Only run if we're on a feature branch (check if feature directory exists)
  if (Test-Path $featureDir -PathType Container) {
    # Switch to the feature branch if not already on it
    $currentBranchCheck = Get-CurrentBranch
    if ($currentBranchCheck -ne $branch) {
      git checkout $branch *>$null
    }

    # Run architecture analysis
    try {
      & $archScript *>$null
    } catch {
      # Ignore errors in architecture analysis to not block specification creation
    }

    # Switch back to original branch if needed
    if ($currentBranchCheck -ne $branch) {
      git checkout $currentBranchCheck *>$null
    }
  }
}

if ($Json) {
  [PSCustomObject]@{ BRANCH_NAME=$branch; SPEC_FILE=$specFile; REQUEST_FILE=$requestFile; FEATURE_DIR=$featureDir } | ConvertTo-Json -Compress
} else {
  Write-Output "BRANCH_NAME: $branch"
  Write-Output "SPEC_FILE: $specFile"
  Write-Output "REQUEST_FILE: $requestFile"
  Write-Output "FEATURE_DIR: $featureDir"
}
