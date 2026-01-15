#!/usr/bin/env pwsh
# Purpose : Scaffold a PR review workflow for Windows users.
# Why     : Mirrors the GoBuildMe quality gate in environments that prefer PowerShell.
# How     : Writes a GitHub Actions workflow wired to the shared review scripts.

[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

# Ensure the workflow directory exists before writing the definition.
New-Item -ItemType Directory -Force -Path .github/workflows | Out-Null

# Emit the review workflow that calls the shared bash scripts.
@"
name: Basic PR Review

on:
  pull_request:

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Lint
        run: .gobuildme/scripts/bash/run-lint.sh || true
      - name: Type Check
        run: .gobuildme/scripts/bash/run-type-check.sh || true
      - name: Tests
        run: .gobuildme/scripts/bash/run-tests.sh --json | tee tests.json
      - name: Security
        run: .gobuildme/scripts/bash/security-scan.sh || true
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: pr-review-artifacts
          path: |
            tests.json
"@ | Set-Content -Path .github/workflows/basic-pr-review.yml -Encoding UTF8

Write-Host 'Wrote .github/workflows/basic-pr-review.yml'
