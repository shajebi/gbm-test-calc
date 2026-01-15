#!/usr/bin/env pwsh
# Purpose : Power the `/request` command for Windows/PowerShell environments.
# Why     : Aligns feature folder creation and metadata emission for teams using
#           PowerShell so the Spec-Driven workflow behaves identically across OSs.
# How     : Normalizes the raw request input, respects slug overrides, ensures
#           template files exist, then outputs structured metadata in JSON/text.
[CmdletBinding()]
param(
  [switch]$Json,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$RequestDescription
)
$ErrorActionPreference = 'Stop'

if (-not $RequestDescription -or $RequestDescription.Count -eq 0) {
  # Guard against empty invocations so callers know how to recover.
  Write-Error "Usage: ./create-request.ps1 [-Json] <request description>"
  exit 1
}

$raw = ($RequestDescription -join ' ')
$raw = $raw -replace "\r", ''
$customSlug = $null
$keptLines = @()
foreach ($line in $raw -split "\n") {
  if ($line -match '^\s*(slug|branch)\s*[:=]\s*(.+)$') {
    $customSlug = $matches[2].Trim().Trim('"').Trim("'")
  } else {
    $keptLines += $line
  }
}

$reqDesc = ($keptLines -join ' ').Trim()
if ([string]::IsNullOrWhiteSpace($reqDesc)) { $reqDesc = $raw.Trim() }

# Normalize / to -- for epic/slice format (backward compatibility)
if ($customSlug -and $customSlug.Contains('/')) {
  $originalSlug = $customSlug
  $customSlug = $customSlug.Replace('/', '--')
  Write-Host "📝 Slug normalized: $originalSlug → $customSlug" -ForegroundColor Cyan
}

. "$PSScriptRoot/common.ps1"
$repoRoot = Get-RepoRoot
Set-Location $repoRoot
$branch = Get-CurrentBranch
$needsNewBranch = $false

# Always branch off protected branches.
$protectedBranches = @('main', 'master', 'develop', 'dev', 'staging', 'production', 'prod')
if ($protectedBranches -contains $branch) {
  $needsNewBranch = $true
}

# Honor explicit slug overrides unless already on that branch.
# Normalize both to lowercase for comparison (create-new-feature normalizes slugs)
if ($customSlug) {
  $customSlugLower = $customSlug.ToLower()
  $branchLower = $branch.ToLower()
  if ($branchLower -ne $customSlugLower) {
    $needsNewBranch = $true
  }
}

# If current branch already has a request.md, create a new branch unless user explicitly reuses it.
if (-not $needsNewBranch -and -not $customSlug) {
  $currentFeatureDir = Get-FeatureDir -RepoRoot $repoRoot -Branch $branch
  $currentRequest = Join-Path $currentFeatureDir 'request.md'
  if (Test-Path $currentRequest) {
    Write-Host "⚠️  Existing request.md found for branch '$branch' - creating a new feature branch to avoid mixing requests." -ForegroundColor Yellow
    Write-Host "ℹ️  If you intended to reuse this branch, re-run with: slug: $branch" -ForegroundColor Cyan
    $needsNewBranch = $true
  }
}

if ($needsNewBranch) {
  Write-Host "ℹ️  Creating feature branch from '$branch'..." -ForegroundColor Cyan
  try {
    if ($customSlug) {
      $jsonOutput = & "$PSScriptRoot/create-new-feature.ps1" -Json -Slug $customSlug $reqDesc
    } else {
      $jsonOutput = & "$PSScriptRoot/create-new-feature.ps1" -Json $reqDesc
    }
    if (-not $jsonOutput) { throw "create-new-feature.ps1 returned empty output." }
    $json = $jsonOutput | ConvertFrom-Json
  } catch {
    throw "create-new-feature.ps1 failed: $_"
  }
  $newBranch = $json.BRANCH_NAME

  if (-not $newBranch) {
    throw "Failed to parse new branch name from create-new-feature output."
  }

  # Only verify/checkout if we're in a git repo
  $isGitRepo = git rev-parse --is-inside-work-tree 2>$null
  if ($LASTEXITCODE -eq 0) {
    git rev-parse --verify $newBranch 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
      throw "New branch '$newBranch' not found after creation."
    }

    if (-not (git checkout $newBranch 2>$null)) {
      throw "Failed to switch to new branch '$newBranch'."
    }
    Write-Host "✅ Switched to feature branch: $newBranch" -ForegroundColor Green
  } else {
    Write-Host "ℹ️  Non-git mode: using feature name '$newBranch'" -ForegroundColor Cyan
  }

  $branch = $newBranch
}

$featureDir = Get-FeatureDir -RepoRoot $repoRoot -Branch $branch
New-Item -ItemType Directory -Path $featureDir -Force | Out-Null

$requestFile = Join-Path $featureDir 'request.md'
if (-not (Test-Path $requestFile)) {
  $tpl = Join-Path $repoRoot '.gobuildme/templates/request-template.md'
  if (-not (Test-Path $tpl)) { $tpl = Join-Path $repoRoot 'templates/request-template.md' }
  if (Test-Path $tpl) { Copy-Item $tpl $requestFile -Force } else { Set-Content -Path $requestFile -Value "# Request`n`n> Describe the user request, context, and open questions." }
}

# Note: spec.md should only be created by /specify command, not /request
$specFile = Join-Path $featureDir 'spec.md'

if ($Json) {
  [PSCustomObject]@{ BRANCH_NAME=$branch; REQUEST_FILE=$requestFile; SPEC_FILE=$specFile; FEATURE_DIR=$featureDir } | ConvertTo-Json -Compress
} else {
  Write-Output "BRANCH_NAME: $branch"
  Write-Output "REQUEST_FILE: $requestFile"
  Write-Output "SPEC_FILE: $specFile"
  Write-Output "FEATURE_DIR: $featureDir"
}
