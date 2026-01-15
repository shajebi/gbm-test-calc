#!/usr/bin/env pwsh
# Purpose : Run lint suites across ecosystems from PowerShell.
# Why     : Keeps lint parity with bash scripts so `/review` is consistent on Windows.
# How     : Detects manifests, runs per-language linters, and tolerates missing tools.

[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

function Test-Cmd { param([string]$c) if (Get-Command $c -ErrorAction SilentlyContinue) { $true } else { $false } }

Write-Host '== Lint: Python =='
if (Test-Path pyproject.toml -or (Get-ChildItem -Recurse -Include *.py -ErrorAction SilentlyContinue)) {
  if (Test-Cmd 'ruff') { ruff check . } else { Write-Host 'ruff not found' }
}

Write-Host '== Lint: Node/TS =='
if (Test-Path package.json) {
  if (Test-Cmd 'pnpm') { pnpm lint 2>$null } elseif (Test-Cmd 'yarn') { yarn lint 2>$null } elseif (Test-Cmd 'npm') { npm run lint 2>$null }
  if (Test-Cmd 'eslint') { eslint . --ext .js,.jsx,.ts,.tsx }
}

Write-Host '== Lint: PHP =='
if (Test-Path composer.json) {
  if (Test-Cmd 'phpcs') { phpcs -q } else { Write-Host 'phpcs not found' }
}

Write-Host '== Lint: Go =='
if (Test-Path go.mod) {
  if (Test-Cmd 'golangci-lint') { golangci-lint run } else { Write-Host 'golangci-lint not found' }
}

Write-Host '== Lint: Rust =='
if (Test-Path Cargo.toml) {
  if (Test-Cmd 'cargo') { cargo clippy --all-targets --quiet }
}

Write-Host '== Lint: Java =='
if (Test-Path pom.xml -or Test-Path build.gradle -or Test-Path build.gradle.kts) {
  Write-Host '(configure checkstyle/spotless in your build for full linting)'
}

