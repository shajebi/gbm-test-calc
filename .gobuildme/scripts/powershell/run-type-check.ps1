#!/usr/bin/env pwsh
# Purpose : Execute type/static analysis from PowerShell.
# Why     : Keeps `/tests` companions accessible on Windows machines.
# How     : Detects languages, runs ecosystem-specific tools, and logs missing dependencies.

[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

function Test-Cmd { param([string]$c) if (Get-Command $c -ErrorAction SilentlyContinue) { $true } else { $false } }

Write-Host '== Type Check: Python =='
if (Test-Path pyproject.toml -or (Get-ChildItem -Recurse -Include *.py -ErrorAction SilentlyContinue)) {
  if (Test-Cmd 'mypy') { mypy . } elseif (Test-Cmd 'pyright') { pyright } else { Write-Host 'mypy/pyright not found' }
}

Write-Host '== Type Check: TypeScript =='
if (Test-Path tsconfig.json -or (Get-ChildItem -Recurse -Include *.ts,*.tsx -ErrorAction SilentlyContinue)) {
  if (Test-Cmd 'pnpm') { pnpm type-check 2>$null } elseif (Test-Cmd 'yarn') { yarn type-check 2>$null } elseif (Test-Cmd 'npm') { npm run type-check 2>$null } else { npx tsc --noEmit --skipLibCheck }
}

Write-Host '== Type Check: PHP =='
if (Test-Path composer.json) {
  if (Test-Cmd 'phpstan') { phpstan analyse } elseif (Test-Cmd 'psalm') { psalm } else { Write-Host 'phpstan/psalm not found' }
}

Write-Host '== Type Check: Go =='
if (Test-Path go.mod) { go vet ./... }

Write-Host '== Type Check: Rust =='
if (Test-Path Cargo.toml) { cargo check --quiet }

Write-Host '== Type Check: Java =='
if (Test-Path pom.xml) { mvn -q -DskipTests verify }
if (Test-Path build.gradle -or Test-Path build.gradle.kts) { ./gradlew check --console=plain }

