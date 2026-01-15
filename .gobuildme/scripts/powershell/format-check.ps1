#!/usr/bin/env pwsh
# Purpose : Verify formatting in CI without modifying files.
# Why     : Offers Windows-friendly entry point for format enforcement pipelines.
# How     : Runs formatter `--check` commands and returns a combined exit code.

[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

$rc = 0
if (Get-Command black -ErrorAction SilentlyContinue) { & black --check .; if ($LASTEXITCODE -ne 0) { $rc = 1 } }
if (Get-Command ruff -ErrorAction SilentlyContinue) { & ruff check .; if ($LASTEXITCODE -ne 0) { $rc = 1 } }
if (Test-Path package.json -and (Get-Command prettier -ErrorAction SilentlyContinue)) { & prettier -c .; if ($LASTEXITCODE -ne 0) { $rc = 1 } }
if (Test-Path Cargo.toml -and (Get-Command cargo -ErrorAction SilentlyContinue)) { & cargo fmt --check; if ($LASTEXITCODE -ne 0) { $rc = 1 } }
exit $rc

