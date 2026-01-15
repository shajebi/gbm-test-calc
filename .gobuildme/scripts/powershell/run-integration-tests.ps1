#!/usr/bin/env pwsh
<#
.SYNOPSIS
Run integration tests for GoBuildMe CLI

.DESCRIPTION
Runs pytest integration tests with various options for filtering and verbosity.

.PARAMETER Fast
Run only fast tests (skip slow agent tests) [default]

.PARAMETER Slow
Run all tests including slow agent tests

.PARAMETER Agent
Run tests for specific agent only (e.g., claude, gemini)

.PARAMETER Suite
Run specific test suite (init_agents, persona_commands, prd_workflow)

.PARAMETER Verbose
Show detailed output (-v -s)

.EXAMPLE
./run-integration-tests.ps1
Run fast tests only (default)

.EXAMPLE
./run-integration-tests.ps1 -Slow
Run all tests including slow ones

.EXAMPLE
./run-integration-tests.ps1 -Agent claude
Run tests for specific agent

.EXAMPLE
./run-integration-tests.ps1 -Suite persona_commands
Run specific test suite

.EXAMPLE
./run-integration-tests.ps1 -Slow -Verbose
Run all tests with verbose output
#>

param(
    [switch]$Fast,
    [switch]$Slow,
    [string]$Agent,
    [string]$Suite,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Get repository root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "../..")).Path

# Default to fast tests if neither Fast nor Slow specified
if (-not $Fast -and -not $Slow) {
    $Fast = $true
}

# Change to repo root
Set-Location $RepoRoot

# Check if pytest is installed
try {
    $null = Get-Command pytest -ErrorAction Stop
} catch {
    Write-Host "Error: pytest not found" -ForegroundColor Red
    Write-Host "Install with: pip install pytest pytest-timeout"
    exit 1
}

# Check if gobuildme is installed
try {
    $null = Get-Command gobuildme -ErrorAction Stop
} catch {
    Write-Host "Error: gobuildme CLI not found" -ForegroundColor Red
    Write-Host "Install with: pip install -e ."
    exit 1
}

# Build pytest command
$PytestArgs = @()

# Add suite filter
if ($Suite) {
    $PytestArgs += "tests/integration/test_$Suite.py"
} else {
    $PytestArgs += "tests/integration/"
}

# Add agent filter
if ($Agent) {
    $PytestArgs += "-k"
    $PytestArgs += $Agent
}

# Add slow test handling
if ($Slow) {
    $PytestArgs += "--run-slow"
} else {
    $PytestArgs += "-m"
    $PytestArgs += "not slow"
}

# Add verbose if requested
if ($Verbose) {
    $PytestArgs += "-v"
    $PytestArgs += "-s"
} else {
    $PytestArgs += "-v"
}

# Add standard options
$PytestArgs += "--tb=short"
$PytestArgs += "--color=yes"

# Print configuration
Write-Host "Running GoBuildMe Integration Tests" -ForegroundColor Green
Write-Host "Repository: $RepoRoot"
Write-Host "Test mode: $(if ($Slow) { 'All tests (including slow)' } else { 'Fast tests only' })"
if ($Agent) { Write-Host "Agent filter: $Agent" }
if ($Suite) { Write-Host "Suite filter: $Suite" }
Write-Host ""

# Run tests
Write-Host "Executing: pytest $($PytestArgs -join ' ')" -ForegroundColor Yellow
Write-Host ""

$exitCode = 0
try {
    & pytest @PytestArgs
    if ($LASTEXITCODE -ne 0) {
        $exitCode = $LASTEXITCODE
    }
} catch {
    Write-Host "Error running tests: $_" -ForegroundColor Red
    $exitCode = 1
}

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "✅ All tests passed!" -ForegroundColor Green
} else {
    Write-Host "❌ Some tests failed" -ForegroundColor Red
}

exit $exitCode

