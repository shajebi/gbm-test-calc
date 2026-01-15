#!/usr/bin/env pwsh
# Purpose : Emit format-check workflows from PowerShell.
# Why     : Allows Windows developers to add format enforcement CI quickly.
# How     : Writes format-check.yml pointing to the shared format-check script.

[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

New-Item -ItemType Directory -Force -Path .github/workflows | Out-Null

@"
name: Format Check

on:
  pull_request:
  push:
    branches: [ main ]

jobs:
  fmt:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run non-mutating format checks
        run: .gobuildme/scripts/bash/format-check.sh
"@ | Set-Content -Path .github/workflows/format-check.yml -Encoding UTF8

Write-Host 'Wrote .github/workflows/format-check.yml'
