#!/usr/bin/env pwsh
# Purpose : Bootstrap the security CI workflow from PowerShell.
# Why     : Enables teams on Windows to add Semgrep and optional CodeQL checks quickly.
# How     : Generates security.yml and appends a CodeQL job when requested.

[CmdletBinding()]
param(
  [switch]$CodeQL
)
$ErrorActionPreference = 'Stop'

# Ensure workflow directory exists for generated YAML.
New-Item -ItemType Directory -Force -Path .github/workflows | Out-Null

# Emit the baseline Semgrep workflow.
@"
name: Security

on:
  push:
    branches: [ main ]
  pull_request:
  schedule:
    - cron: '0 3 * * 1'

jobs:
  semgrep:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: returntocorp/semgrep-action@v1
        with:
          config: p/ci
        env:
          SEMGREP_APP_TOKEN: \\${{ secrets.SEMGREP_APP_TOKEN }}
"@ | Set-Content -Path .github/workflows/security.yml -Encoding UTF8

if ($CodeQL) {
  # Detect CodeQL-supported languages based on repo manifests.
  $langs = @()
  if (Test-Path package.json) { $langs += 'javascript-typescript' }
  if (Test-Path pyproject.toml -or Test-Path requirements.txt) { $langs += 'python' }
  if (Test-Path go.mod) { $langs += 'go' }
  if (Test-Path pom.xml -or Test-Path build.gradle -or Test-Path build.gradle.kts) { $langs += 'java' }
  if ($langs.Count -eq 0) { $langs = @('javascript-typescript') }
  $langStr = ($langs -join ',')

  # Append a CodeQL job tuned to discovered languages.
  @"

  codeql:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
      actions: read
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with:
          languages: $langStr
      - uses: github/codeql-action/autobuild@v3
      - uses: github/codeql-action/analyze@v3
        with:
          category: '/language:$langStr'
"@ | Add-Content -Path .github/workflows/security.yml -Encoding UTF8
}

Write-Host "Wrote .github/workflows/security.yml (CodeQL=$CodeQL)"
