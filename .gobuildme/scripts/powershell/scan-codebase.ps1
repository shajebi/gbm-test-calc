#!/usr/bin/env pwsh
# Purpose : Emit repository fingerprints from PowerShell.
# Why     : Gives planning steps insight into active stacks without requiring bash.
# How     : Collects manifest/config signals, counts extensions, and outputs JSON or text summaries.

[CmdletBinding()]
param(
  [switch]$Json
)
$ErrorActionPreference = 'Stop'

try { $repoRoot = (git rev-parse --show-toplevel) } catch { $repoRoot = (Get-Location).Path }
Set-Location $repoRoot

function Test-File { param([string]$p) if (Test-Path $p -PathType Leaf) { $p } }
function Test-Dir  { param([string]$p) if (Test-Path $p -PathType Container) { $p } }

$files = @(
  (Test-File 'pyproject.toml'), (Test-File 'requirements.txt'), (Test-File 'poetry.lock'), (Test-File 'uv.lock'),
  (Test-File 'package.json'), (Test-File 'yarn.lock'), (Test-File 'pnpm-lock.yaml'), (Test-File 'bun.lockb'),
  (Test-File 'go.mod'), (Test-File 'Cargo.toml'), (Test-File 'Gemfile'), (Test-File 'composer.json'),
  (Test-File 'build.gradle'), (Test-File 'build.gradle.kts'), (Test-File 'pom.xml'),
  (Test-File '.pre-commit-config.yaml'), (Test-File '.editorconfig'), (Test-File '.flake8'), (Test-File 'setup.cfg'),
  (Test-File '.eslintrc'), (Test-File '.eslintrc.js'), (Test-File '.eslintrc.cjs'), (Test-File '.eslintrc.json'), (Test-File 'eslint.config.js'), (Test-File 'eslint.config.mjs'), (Test-File 'eslint.config.cjs'),
  (Test-File '.pylintrc'), (Test-File 'pytest.ini'), (Test-File 'tox.ini'),
  (Test-File 'jest.config.js'), (Test-File 'vitest.config.ts'), (Test-File '.golangci.yml'),
  (Test-File 'rustfmt.toml'), (Test-File 'Clippy.toml'), (Test-File '.bandit'),
  (Test-File '.semgrep.yml'), (Test-File '.semgrep.yaml'), (Test-File '.snyk'), (Test-File 'snyk.yml'),
  (Test-File '.dockerignore'), (Test-File 'Dockerfile'), (Test-File '.deepsource.toml'),
  (Test-File '.prettierrc'), (Test-File '.prettier.config.js'), (Test-File '.ruff.toml'),
  (Test-File '.hadolint.yaml'), (Test-File '.tflint.hcl'),
  (Test-File 'docs/ARCHITECTURE.md'), (Test-File 'ARCHITECTURE.md'), (Test-File 'SECURITY.md'), (Test-File 'CODE_OF_CONDUCT.md'), (Test-File 'CODEOWNERS')
) | Where-Object { $_ }

$pkgMans = @()
if (Test-Path package.json) { $pkgMans += 'node' }
if (Test-Path yarn.lock) { $pkgMans += 'yarn' }
if (Test-Path pnpm-lock.yaml) { $pkgMans += 'pnpm' }
if (Test-Path bun.lockb) { $pkgMans += 'bun' }
if (Test-Path pyproject.toml) { $pkgMans += 'python-pyproject' }
if (Test-Path requirements.txt) { $pkgMans += 'python-pip' }
if (Test-Path poetry.lock) { $pkgMans += 'poetry' }
if (Test-Path uv.lock) { $pkgMans += 'uv' }
if (Test-Path go.mod) { $pkgMans += 'go-mod' }
if (Test-Path Cargo.toml) { $pkgMans += 'cargo' }
if (Test-Path Gemfile) { $pkgMans += 'bundler' }
if (Test-Path composer.json) { $pkgMans += 'composer' }
if (Test-Path pom.xml) { $pkgMans += 'maven' }
if (Test-Path build.gradle -or Test-Path build.gradle.kts) { $pkgMans += 'gradle' }

$ci = Get-ChildItem .github/workflows -Filter *.yml -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
if (-not $ci) { $ci = Get-ChildItem .github/workflows -Filter *.yaml -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName }

$boundaries = @(
  (Test-Dir 'src'), (Test-Dir 'backend'), (Test-Dir 'frontend'), (Test-Dir 'api'), (Test-Dir 'cmd'), (Test-Dir 'internal'), (Test-Dir 'pkg'), (Test-Dir 'services'), (Test-Dir 'models')
) | Where-Object { $_ }

# Extensions
$extCounts = Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\.git\\' -and $_.FullName -notmatch 'node_modules' -and $_.FullName -notmatch '\\.gobuildme\\' } |
  ForEach-Object { [IO.Path]::GetExtension($_.Name).TrimStart('.') } |
  Where-Object { $_ } |
  Group-Object |
  Sort-Object Count -Descending |
  Select-Object -First 20 |
  ForEach-Object { ,@($_.Name.ToLower(),$_.Count) }

$obj = [ordered]@{
  repo_root = $repoRoot
  languages_by_ext = $extCounts
  package_managers = $pkgMans
  important_files = $files
  ci_workflows = $ci
  boundaries = $boundaries
}

if ($Json) { $obj | ConvertTo-Json -Depth 5 } else { $obj }
