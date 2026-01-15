#!/usr/bin/env pwsh
# Purpose : Execute language-aware tests from PowerShell.
# Why     : Provides `/tests` parity for Windows shells without invoking bash.
# How     : Detects active ecosystems, runs best-known test commands, and emits summary objects.

[CmdletBinding()]
param(
  [switch]$Json,
  [int]$Threshold
)
$ErrorActionPreference = 'Stop'

try { $repoRoot = (git rev-parse --show-toplevel) } catch { $repoRoot = (Get-Location).Path }
Set-Location $repoRoot

# Capture detected stacks and command outcomes for reporting.
$detected = @()
$results = @()

function Add-Result {
  param([string]$name,[string]$command,[int]$exit)
  $results += [ordered]@{ name=$name; command=$command; exit_code=$exit }
}

# Detect
$hasPy = (Test-Path pyproject.toml) -or (Test-Path pytest.ini) -or (Test-Path tests)
$hasNode = Test-Path package.json
$hasGo = Test-Path go.mod
$hasRust = Test-Path Cargo.toml
$hasMaven = Test-Path pom.xml
$hasGradle = (Test-Path build.gradle) -or (Test-Path build.gradle.kts) -or (Test-Path gradlew)

if ($hasPy) { $detected += 'python-pytest' }
if ($hasNode) { $detected += 'node' }
if ($hasGo) { $detected += 'go' }
if ($hasRust) { $detected += 'rust' }
if ($hasMaven) { $detected += 'maven' }
if ($hasGradle) { $detected += 'gradle' }

# Run a command if available and record the exit code.
function Try-Run {
  param([string]$name, [string[]]$cmd)
  $cmdStr = ($cmd -join ' ')
  try { & $cmd[0] $cmd[1..($cmd.Length-1)] 2>$null; Add-Result $name $cmdStr $LASTEXITCODE } catch { Add-Result $name $cmdStr 127 }
}

if ($hasPy) {
  Try-Run 'pytest' @('pytest','--maxfail=1','--disable-warnings','-q')
}
if ($hasNode) {
  if (Get-Command pnpm -ErrorAction SilentlyContinue) { Try-Run 'node-pnpm' @('pnpm','test','--silent') }
  if (Get-Command yarn -ErrorAction SilentlyContinue) { Try-Run 'node-yarn' @('yarn','test','--silent') }
  if (Get-Command npm -ErrorAction SilentlyContinue)  { Try-Run 'node-npm'  @('npm','test','--silent') }
}
if ($hasGo) { Try-Run 'go' @('go','test','./...') }
if ($hasRust) { Try-Run 'rust' @('cargo','test','--all','--quiet') }
if ($hasMaven) { Try-Run 'maven' @('mvn','-q','-DskipITs=false','test') }
if ($hasGradle) {
  if (Test-Path ./gradlew) { Try-Run 'gradle' @('./gradlew','test','--console=plain') } else { Try-Run 'gradle' @('gradle','test','--console=plain') }
}

$obj = [ordered]@{ detected = $detected; results = $results }
if ($Json) { $obj | ConvertTo-Json -Depth 5 } else { $obj }
