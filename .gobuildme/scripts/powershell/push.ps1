#!/usr/bin/env pwsh
# Purpose : Automate the `/push` step for PowerShell workflows.
# Why     : Ensures Windows developers run the same preflight gating before creating PRs.
# How     : Validates git state, pushes the branch, crafts a PR body, and calls `gh pr create`.

param(
  [string]$Base = 'main',
  [switch]$Draft,
  [string]$Labels = '',
  [string]$Reviewers = '',
  [string]$TeamReviewers = '',
  [string]$Title = '',
  [string]$BodyFile = '',
  [switch]$NoVerify
)
$ErrorActionPreference = 'Stop'

# Load shared helpers for repo/feature resolution.
. "$PSScriptRoot/common.ps1"
$repoRoot = Get-RepoRoot
Set-Location $repoRoot

if (-not (git rev-parse --is-inside-work-tree 2>$null)) { throw 'Not inside a git repository.' }
$branch = Get-CurrentBranch
if (-not (Test-FeatureBranch -Branch $branch -HasGit $true)) { throw "Current branch '$branch' is not a feature branch." }
$dirty = git status --porcelain
if ($dirty) { throw 'Working tree is not clean. Commit or stash changes.' }
if (-not (git remote get-url origin 2>$null)) { throw "Remote 'origin' not configured." }
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw "GitHub CLI 'gh' is required: https://cli.github.com/" }
if (-not (gh auth status 2>$null)) { throw "'gh' is not authenticated. Run: gh auth login" }

if (-not $NoVerify) {
  # Run preflight readiness checks unless explicitly skipped.
  $preflight = Join-Path $repoRoot '.gobuildme/scripts/bash/ready-to-push.sh'
  if (Test-Path $preflight) {
    Write-Host "Running preflight: $preflight"
    bash $preflight
  } else {
    Write-Warning "Preflight script not found; skipping."
  }

  $reviewGate = Join-Path $repoRoot '.gobuildme/scripts/bash/comprehensive-review.sh'
  if (Test-Path $reviewGate) {
    Write-Host "Running review gate: $reviewGate"
    bash $reviewGate | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Review gate failed. Resolve blocking issues reported by /review before pushing.' }
  } else {
    Write-Warning "Review gate script not found; skipping."
  }
}

try {
  git rev-parse --abbrev-ref --symbolic-full-name '@{u}' | Out-Null
  git push | Out-Null
} catch {
  Write-Host "Pushing branch '$branch' to origin..."
  git push -u origin $branch | Out-Null
}

if (-not $BodyFile) {
  # Generate a default PR body summarizing key artifacts.
  $paths = Get-FeaturePathsEnv
  $request = $paths.REQUEST_FILE
  $spec = $paths.FEATURE_SPEC
  $plan = $paths.IMPL_PLAN
  $tmp = New-TemporaryFile
  "## Summary" | Out-File -FilePath $tmp -Encoding utf8
  if ($request -and (Test-Path $request)) {
    Get-Content $request -TotalCount 40 | ForEach-Object { "> $_" } | Out-File -Append -FilePath $tmp -Encoding utf8
  } elseif ($spec -and (Test-Path $spec)) {
    Get-Content $spec -TotalCount 40 | ForEach-Object { "> $_" } | Out-File -Append -FilePath $tmp -Encoding utf8
  } else {
    "> No ask/spec found; summarize the change here." | Out-File -Append -FilePath $tmp -Encoding utf8
  }
  "`n## Plan Highlights" | Out-File -Append -FilePath $tmp -Encoding utf8
  if ($plan -and (Test-Path $plan)) {
    # Light extract of Technical Context block
    $lines = Get-Content $plan
    $start = ($lines | Select-String '^## Technical Context' | Select-Object -First 1).LineNumber
    if ($start) {
      $rest = $lines[$start-1..($lines.Length-1)]
      foreach ($l in $rest) { if ($l -match '^## ' -and $l -ne '## Technical Context') { break } else { $l | Out-File -Append -FilePath $tmp -Encoding utf8 } }
    }
  }
  "`n## Files`n- request: $request`n- spec: $spec`n- plan: $plan" | Out-File -Append -FilePath $tmp -Encoding utf8
  "`n## Checks`n- Preflight: $([bool](-not $NoVerify) -as [string])" | Out-File -Append -FilePath $tmp -Encoding utf8
  $BodyFile = $tmp
}

if (-not $Title) { $Title = "$branch → $Base" }

$args = @('pr','create','--base', $Base,'--head',$branch,'--title',$Title,'--body-file',$BodyFile)
if ($Draft) { $args += '--draft' }
if ($Labels) { $Labels.Split(',') | Where-Object { $_ } | ForEach-Object { $args += @('--label', $_) } }
if ($Reviewers) { $Reviewers.Split(',') | Where-Object { $_ } | ForEach-Object { $args += @('--reviewer', $_) } }
if ($TeamReviewers) { $TeamReviewers.Split(',') | Where-Object { $_ } | ForEach-Object { $args += @('--team-reviewer', $_) } }

Write-Host "Creating PR: gh $($args -join ' ')"
gh @args
Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "- Assign reviewers if not set; monitor CI checks."
Write-Host "- Optionally run /gbm.preflight for an automated summary."
