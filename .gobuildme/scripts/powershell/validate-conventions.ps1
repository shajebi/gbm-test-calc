#!/usr/bin/env pwsh
# Purpose : Check lint/format conventions without mutating files.
# Why     : Supports `/review` gating on Windows shells.
# How     : Executes non-mutating formatter and linter checks, aggregating exit status.

[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

$fail = 0

function Try-Run { param([string[]]$cmd) try { & $cmd[0] $cmd[1..($cmd.Length-1)] } catch { $global:fail = 1 } }

if (Get-Command black -ErrorAction SilentlyContinue) { Try-Run @('black','--check','.') }
if (Get-Command ruff -ErrorAction SilentlyContinue) { Try-Run @('ruff','check','.') }
if (Test-Path package.json -and (Get-Command prettier -ErrorAction SilentlyContinue)) { Try-Run @('prettier','-c','.') }
if (Test-Path package.json -and (Get-Command eslint -ErrorAction SilentlyContinue)) { Try-Run @('eslint','.', '--ext', '.js,.jsx,.ts,.tsx') }
if (Test-Path composer.json -and (Get-Command phpcs -ErrorAction SilentlyContinue)) { Try-Run @('phpcs','-q') }
if (Test-Path go.mod -and (Get-Command golangci-lint -ErrorAction SilentlyContinue)) { Try-Run @('golangci-lint','run') }
if (Test-Path Cargo.toml -and (Get-Command cargo -ErrorAction SilentlyContinue)) { Try-Run @('cargo','fmt','--check'); Try-Run @('cargo','clippy','--all-targets','--','-D','warnings') }

if ($fail -eq 0) { Write-Host 'Conventions validation passed' } else { Write-Error 'Conventions validation failed' }
exit $fail

