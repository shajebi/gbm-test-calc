#!/usr/bin/env pwsh
# Purpose : Run dependency/static security checks via PowerShell.
# Why     : Keeps `/security` parity when bash tooling is unavailable.
# How     : Detects installed security tools per stack and executes them best-effort.

[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

function Test-Cmd { param([string]$c) if (Get-Command $c -ErrorAction SilentlyContinue) { $true } else { $false } }

Write-Host '== Security: Python =='
if (Test-Path pyproject.toml -or Test-Path requirements.txt) {
  if (Test-Cmd 'safety') { safety check }
  if (Test-Cmd 'bandit') { bandit -r . }
  if (Test-Cmd 'pip-audit') { pip-audit -r requirements.txt 2>$null; if ($LASTEXITCODE -ne 0) { pip-audit } }
}

Write-Host '== Security: Node =='
if (Test-Path package.json) {
  if (Test-Cmd 'npm') { npm audit --audit-level=moderate }
  if (Test-Cmd 'pnpm') { pnpm audit }
  if (Test-Cmd 'yarn') { yarn audit }
}

Write-Host '== Security: PHP =='
if (Test-Path composer.json -and (Test-Cmd 'composer')) { composer audit }

Write-Host '== Security: Go =='
if (Test-Path go.mod -and (Test-Cmd 'govulncheck')) { govulncheck ./... }

Write-Host '== Security: Rust =='
if (Test-Path Cargo.toml -and (Test-Cmd 'cargo-audit')) { cargo audit }

Write-Host '== Security: Semgrep (if configured) =='
if ((Test-Cmd 'semgrep') -and (Test-Path .semgrep.yml -or Test-Path .semgrep.yaml)) { semgrep scan }

