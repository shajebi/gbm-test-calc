# Produce a provisional SLI/SLO report for CI from test or synthetic data.
# This is intentionally lightweight and advisory (non-blocking).

<#
.SYNOPSIS
    Generate provisional SLO report from test results.

.DESCRIPTION
    Produces a provisional SLI/SLO report for CI from test or synthetic data.
    Uses JUnit XML test results as a proxy for availability SLI.
    This is intentionally lightweight and advisory (non-blocking).

.EXAMPLE
    .\slo-synthetic.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"

function Write-SloInfo {
    param([string]$Message)
    Write-Host "[slo-synthetic] $Message" -ForegroundColor Cyan
}

# Determine repo root
try {
    $RepoRoot = git rev-parse --show-toplevel 2>$null
    if (-not $RepoRoot) {
        $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        $RepoRoot = (Resolve-Path "$ScriptDir\..\.." -ErrorAction Stop).Path
    }
} catch {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $RepoRoot = (Resolve-Path "$ScriptDir\..\.." -ErrorAction Stop).Path
}

$OutDir = Join-Path $RepoRoot ".gobuildme\self-driving\logs"
if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

$ReportPath = Join-Path $OutDir "slo-report.json"

# Heuristic: if a junit xml exists, consider pass rate as a proxy SLI
$JunitFile = Get-ChildItem -Path $RepoRoot -Filter "junit*.xml" -Recurse -Depth 4 -ErrorAction SilentlyContinue |
             Select-Object -First 1 -ExpandProperty FullName

$Pass = 0
$Total = 0
$Availability = 1.0

if ($JunitFile -and (Test-Path $JunitFile)) {
    try {
        [xml]$JunitXml = Get-Content $JunitFile
        $TestSuite = $JunitXml.testsuite
        
        if ($TestSuite) {
            $Total = [int]$TestSuite.tests
            $Failures = if ($TestSuite.failures) { [int]$TestSuite.failures } else { 0 }
            $Skipped = if ($TestSuite.skipped) { [int]$TestSuite.skipped } else { 0 }
            $Pass = $Total - $Failures - $Skipped
            
            if ($Total -gt 0) {
                $Availability = [math]::Round($Pass / $Total, 4)
            }
        }
    } catch {
        Write-SloInfo "Warning: Could not parse JUnit XML: $_"
    }
}

# Get current timestamp in UTC
$Timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Create JSON report
$Report = @{
    provisional = $true
    timestamp = $Timestamp
    test_pass = @{
        passed = $Pass
        total = $Total
    }
    heuristic_availability = $Availability
} | ConvertTo-Json -Depth 10

# Write report
Set-Content -Path $ReportPath -Value $Report -Encoding UTF8

Write-SloInfo "Wrote $ReportPath"
exit 0

