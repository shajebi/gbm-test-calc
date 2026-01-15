#!/usr/bin/env pwsh
# Purpose : Summarize git branch health from PowerShell.
# Why     : Mirrors the bash branch-status helper so `/review` works on Windows.
# How     : Prints current branch, status, recent commits, and divergence from main.

[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

try { $branch = git branch --show-current } catch { $branch = '(no branch)' }
Write-Host "Current branch: $branch"

Write-Host "`nGit status:"
git status --porcelain | ForEach-Object { $_ }

Write-Host "`nRecent commits:"
git log --oneline -5 | ForEach-Object { $_ }

Write-Host "`nSync with main:"
try {
  git remote get-url origin *> $null
  git fetch origin main *> $null
  git show-ref --verify --quiet refs/remotes/origin/main
  $behind = git rev-list --count HEAD..origin/main
  $ahead  = git rev-list --count origin/main..HEAD
  Write-Host "Ahead: $ahead, Behind: $behind"
} catch {
  Write-Host "No 'origin/main' to compare or offline."
}

