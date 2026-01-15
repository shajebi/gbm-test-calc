#!/usr/bin/env pwsh
# Purpose : Apply formatters across ecosystems from PowerShell.
# Why     : Maintains code style consistency for users who rely on PowerShell.
# How     : Detects active stacks and runs available formatters best-effort.

[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

function Test-Cmd { param([string]$c) if (Get-Command $c -ErrorAction SilentlyContinue) { $true } else { $false } }

Write-Host '== Format: Python =='
if (Test-Path pyproject.toml -or (Get-ChildItem -Recurse -Include *.py -ErrorAction SilentlyContinue)) {
  if (Test-Cmd 'black') { black . } else { Write-Host 'black not found' }
  if (Test-Cmd 'ruff') { ruff check --fix . }
}

Write-Host '== Format: Node/TS =='
if (Test-Path package.json) {
  if (Test-Cmd 'pnpm') { pnpm format 2>$null } elseif (Test-Cmd 'yarn') { yarn format 2>$null } elseif (Test-Cmd 'npm') { npm run format 2>$null }
  if (Test-Cmd 'prettier') { prettier -w . }
}

Write-Host '== Format: PHP =='
if (Test-Path composer.json) {
  if (Test-Cmd 'php-cs-fixer') { php-cs-fixer fix } elseif (Test-Cmd 'phpcbf') { phpcbf } else { Write-Host 'php-cs-fixer/phpcbf not found' }
}

Write-Host '== Format: Go =='
if (Test-Path go.mod) { go fmt ./... }

Write-Host '== Format: Rust =='
if (Test-Path Cargo.toml) { if (Test-Cmd 'cargo') { cargo fmt } }

