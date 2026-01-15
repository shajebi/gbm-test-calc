#!/usr/bin/env pwsh
# Purpose : Scaffold the baseline tests workflow using PowerShell.
# Why     : Keeps the GoBuildMe CI bootstrap accessible on Windows.
# How     : Creates tests.yml pointing at shared lint, type, test, and security scripts.

[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

New-Item -ItemType Directory -Force -Path .github/workflows | Out-Null
$target = '.github/workflows/tests.yml'
@"
name: Tests

on:
  push:
    branches: [ main ]
  pull_request:

jobs:
  tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Python
      - name: Set up Python
        if: \\${{ hashFiles('pyproject.toml', 'requirements.txt') != '' }}
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - name: Install Python deps
        if: \\${{ hashFiles('pyproject.toml', 'requirements.txt') != '' }}
        run: |
          python -m pip install --upgrade pip
          if [ -f pyproject.toml ]; then pip install . || true; fi
          if [ -f requirements.txt ]; then pip install -r requirements.txt || true; fi

      # Node/TS
      - name: Set up Node
        if: \\${{ hashFiles('package.json') != '' }}
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - name: Install Node deps
        if: \\${{ hashFiles('package.json') != '' }}
        run: |
          if [ -f pnpm-lock.yaml ]; then corepack enable && pnpm i; \\
          elif [ -f yarn.lock ]; then corepack enable && yarn install; \\
          else npm ci; fi

      # PHP
      - name: Set up PHP
        if: \\${{ hashFiles('composer.json') != '' }}
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          tools: composer
      - name: Install PHP deps
        if: \\${{ hashFiles('composer.json') != '' }}
        run: composer install --no-interaction --prefer-dist

      # Go
      - name: Set up Go
        if: \\${{ hashFiles('go.mod') != '' }}
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      # Rust
      - name: Set up Rust
        if: \\${{ hashFiles('Cargo.toml') != '' }}
        uses: dtolnay/rust-toolchain@stable

      # Java
      - name: Set up Java
        if: \\${{ hashFiles('pom.xml', 'build.gradle', 'build.gradle.kts') != '' }}
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '21'

      # Run checks via repo scripts
      - name: Lint
        run: .gobuildme/scripts/bash/run-lint.sh || true
      - name: Type Check
        run: .gobuildme/scripts/bash/run-type-check.sh || true
      - name: Tests
        run: .gobuildme/scripts/bash/run-tests.sh --json | tee tests.json
      - name: Security Scan
        run: .gobuildme/scripts/bash/security-scan.sh || true
"@ | Set-Content -Path $target -Encoding UTF8

Write-Host "Wrote $target"

if (-not (Test-Path Makefile) -and (Test-Path templates/Makefile.example)) {
  Copy-Item templates/Makefile.example Makefile
  Write-Host 'Copied templates/Makefile.example -> Makefile'
}
