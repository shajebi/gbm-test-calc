#!/usr/bin/env pwsh
# Purpose : Validate that architecture documentation exists and contains actual analysis.
# Why     : Ensures architecture docs are comprehensive and not just raw data or stubs.
# How     : Checks for file existence, structure (## headings), content quality, and minimum length.

[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

try { $repoRoot = (git rev-parse --show-toplevel) } catch { $repoRoot = (Get-Location).Path }
Set-Location $repoRoot

$archDir = ".gobuildme/docs/technical/architecture"
$errors = 0
$warnings = 0

function Log-Error {
    param([string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor Red
    $script:errors++
}

function Log-Warning {
    param([string]$Message)
    Write-Host "WARNING: $Message" -ForegroundColor Yellow
    $script:warnings++
}

function Log-Info {
    param([string]$Message)
    Write-Host ("✓ " + $Message) -ForegroundColor Green
}

function Log-Check {
    param([string]$Message)
    Write-Host ("→ " + $Message) -ForegroundColor Cyan
}

# Check if codebase exists (has code files outside .gobuildme)
$hasCodebase = $false
$codeExtensions = @("php", "py", "js", "ts", "java", "go", "rb", "cs", "rs", "kt", "swift")
foreach ($ext in $codeExtensions) {
    $codeFiles = Get-ChildItem -Recurse -Filter "*.$ext" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch "\.gobuildme|node_modules|venv|vendor" }
    if ($codeFiles) {
        $hasCodebase = $true
        break
    }
}

if (-not $hasCodebase) {
    Log-Info "New/empty project detected - skipping global architecture validation"
    Log-Info "Architecture documentation not required for projects without existing code"
    exit 0
}

Log-Check "Existing codebase detected - validating architecture documentation..."

# Check if architecture directory exists
if (-not (Test-Path $archDir)) {
    Log-Error "Architecture documentation directory not found: $archDir"
    Log-Error "Run '/gbm.architecture' to create comprehensive architecture documentation"
    exit 1
}

# Required architecture files
$requiredFiles = @(
    "system-analysis.md",
    "technology-stack.md",
    "security-architecture.md",
    "integration-landscape.md"
)

# Optional architecture files (warnings only)
$optionalFiles = @(
    "component-architecture.md",
    "data-architecture.md"
)

Log-Check "Validating required architecture documentation files..."

function Validate-File {
    param(
        [string]$FileName,
        [string]$Required  # "required" or "optional"
    )

    $filePath = Join-Path $archDir $FileName
    Log-Check "Checking $FileName..."

    # Check file exists
    if (-not (Test-Path $filePath)) {
        if ($Required -eq "required") {
            Log-Error "$FileName not found at $filePath"
        } else {
            Log-Warning "$FileName not found (optional, but recommended)"
        }
        return $false
    }

    # Check file is not empty
    $fileContent = Get-Content $filePath -Raw -ErrorAction SilentlyContinue
    if (-not $fileContent -or $fileContent.Trim().Length -eq 0) {
        Log-Error "$FileName exists but is empty"
        return $false
    }

    # Check minimum line count (at least 50 lines for comprehensive analysis)
    $lineCount = (Get-Content $filePath).Count
    if ($lineCount -lt 50) {
        Log-Warning "$FileName has only $lineCount lines (expected at least 50 for comprehensive analysis)"
    }

    # Check for major sections (## headings)
    $sections = Get-Content $filePath | Where-Object { $_ -match "^## " }
    $sectionCount = ($sections | Measure-Object).Count
    if ($sectionCount -lt 3) {
        Log-Error "$FileName lacks proper structure (found $sectionCount major sections, expected at least 3)"
        return $false
    }

    # Check for placeholder content
    if ($fileContent -match "TODO|PLACEHOLDER|FILL THIS IN|XXX|FIXME") {
        Log-Warning "$FileName contains placeholder content (TODO/PLACEHOLDER/FIXME markers)"
    }

    # Check for raw data indicators (shouldn't be present in analysis files)
    if ($fileContent -match "^### Raw Data|^## Raw Data Collection") {
        Log-Error "$FileName appears to contain raw data instead of analysis"
        Log-Error "This file should contain YOUR architectural analysis, not raw script output"
        return $false
    }

    # File-specific validation
    switch ($FileName) {
        "system-analysis.md" {
            # Should contain architectural style/pattern analysis
            if (-not ($fileContent -match "(?i)architecture|pattern|style|design")) {
                Log-Warning "$FileName should contain architectural style and pattern analysis"
            }
        }
        "technology-stack.md" {
            # Should contain technology decisions and rationale
            if (-not ($fileContent -match "(?i)framework|library|database|technology")) {
                Log-Warning "$FileName should document technology stack and decisions"
            }
        }
        "security-architecture.md" {
            # Should contain security patterns and mechanisms
            if (-not ($fileContent -match "(?i)authentication|authorization|security|encryption")) {
                Log-Warning "$FileName should document security patterns and mechanisms"
            }
        }
        "integration-landscape.md" {
            # Should contain integration points and protocols
            if (-not ($fileContent -match "(?i)integration|api|service|endpoint")) {
                Log-Warning "$FileName should document integration points and protocols"
            }
        }
    }

    Log-Info "$FileName validated successfully ($lineCount lines, $sectionCount sections)"
    return $true
}

# Validate required files
foreach ($file in $requiredFiles) {
    Validate-File -FileName $file -Required "required" | Out-Null
}

# Validate optional files
foreach ($file in $optionalFiles) {
    Validate-File -FileName $file -Required "optional" | Out-Null
}

# Check for data-collection.md (should exist but shouldn't be the only file)
$dataCollectionPath = Join-Path $archDir "data-collection.md"
if (Test-Path $dataCollectionPath) {
    Log-Info "data-collection.md found (raw data from scripts)"

    # Count actual analysis files (not including data-collection.md)
    $analysisFileCount = 0
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $archDir $file
        if (Test-Path $filePath) {
            $analysisFileCount++
        }
    }

    if ($analysisFileCount -eq 0) {
        Log-Error "Only data-collection.md found - AI agent must create actual analysis files"
        Log-Error "The shell scripts create data-collection.md with RAW DATA only"
        Log-Error "YOU (AI Agent) must analyze raw data and CREATE comprehensive architecture files"
    }
}

# Summary
Write-Host ""
Write-Host "================================"
Write-Host "Architecture Documentation Validation Summary"
Write-Host "================================"
Write-Host "Errors: $errors"
Write-Host "Warnings: $warnings"
Write-Host ""

if ($errors -gt 0) {
    Log-Error "Architecture documentation validation failed ($errors error(s), $warnings warning(s))"
    Write-Host ""
    Write-Host "Required Actions:"
    Write-Host "1. Run '/gbm.architecture' to create or update architecture documentation"
    Write-Host "2. Ensure all required files contain comprehensive analysis (not just raw data)"
    Write-Host "3. Verify each file has proper structure with major sections (## headings)"
    Write-Host "4. Confirm files are comprehensive (at least 50 lines with meaningful content)"
    exit 1
} elseif ($warnings -gt 0) {
    Log-Warning "Architecture documentation validation passed with warnings ($warnings warning(s))"
    Write-Host ""
    Write-Host "Recommendations:"
    Write-Host "- Address warnings to improve documentation quality"
    Write-Host "- Remove placeholder content (TODO/FIXME markers)"
    Write-Host "- Add more detail to files with fewer than 50 lines"
    exit 0
} else {
    Log-Info "Architecture documentation validation passed successfully!"
    Write-Host ""
    Write-Host "All required architecture documentation files exist and contain comprehensive analysis."
    exit 0
}
