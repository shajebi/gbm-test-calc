#!/usr/bin/env pwsh
# Purpose : Enforce constitutional rules via PowerShell.
# Why     : Guarantees governance checks run even when bash is not the primary shell.
# How     : Loads the constitution, inspects code/test layout, and reports errors or warnings.

[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'

# validate-constitution.ps1 - Validate project compliance with constitution
# Checks that current codebase and artifacts comply with constitutional principles

try { $repoRoot = (git rev-parse --show-toplevel) } catch { $repoRoot = (Get-Location).Path }
Set-Location $repoRoot

$constitutionFile = ".gobuildme/memory/constitution.md"
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
    Write-Host "INFO: $Message" -ForegroundColor Green
}

# Check if constitution exists
if (-not (Test-Path $constitutionFile)) {
    Log-Error "Constitution file not found at $constitutionFile"
    exit 1
}

Log-Info "Validating constitutional compliance..."

# Extract principles from constitution (look for ### headers)
$principles = Get-Content $constitutionFile | Where-Object { $_ -match "^### " } | ForEach-Object { $_ -replace "^### ", "" }

if (-not $principles) {
    Log-Warning "No principles found in constitution (expected ### headers)"
}

# Check for common constitutional violations

# 1. Test-First principle validation
$constitutionContent = Get-Content $constitutionFile -Raw
if ($constitutionContent -match "Test-First|TDD") {
    Log-Info "Checking Test-First compliance..."
    
    # Check if tests exist
    $testDirs = @("test", "tests", "__tests__", "spec", "specs")
    $hasTests = $false
    foreach ($dir in $testDirs) {
        if (Test-Path $dir) {
            $hasTests = $true
            break
        }
    }
    
    if (-not $hasTests) {
        # Check for test files in src directories
        $testFiles = Get-ChildItem -Recurse -Include "*test*", "*spec*" | Where-Object { $_.Extension -match "\.(py|js|ts|go|rs|java)$" }
        if ($testFiles) {
            $hasTests = $true
        }
    }
    
    if (-not $hasTests) {
        Log-Error "Test-First principle violated: No test files found"
    } else {
        Log-Info "Test-First principle: Tests found"
    }
}

# 2. Library-First principle validation
if ($constitutionContent -match "Library-First") {
    Log-Info "Checking Library-First compliance..."
    
    # Check for proper library structure
    if ((Test-Path "src") -or (Test-Path "lib") -or (Test-Path "setup.py") -or (Test-Path "pyproject.toml") -or (Test-Path "package.json")) {
        Log-Info "Library-First principle: Library structure detected"
    } else {
        Log-Warning "Library-First principle: No clear library structure found"
    }
}

# 3. CLI Interface principle validation
if ($constitutionContent -match "CLI Interface") {
    Log-Info "Checking CLI Interface compliance..."
    
    # Check for CLI entry points
    $hasCli = $false
    if ((Test-Path "pyproject.toml") -and (Get-Content "pyproject.toml" -Raw) -match "\[project\.scripts\]") {
        $hasCli = $true
    } elseif ((Test-Path "package.json") -and (Get-Content "package.json" -Raw) -match '"bin":') {
        $hasCli = $true
    } elseif ((Test-Path "Cargo.toml") -and (Get-Content "Cargo.toml" -Raw) -match "\[\[bin\]\]") {
        $hasCli = $true
    } elseif ((Get-ChildItem -Recurse -Include "main.py", "cli.py", "main.go" -ErrorAction SilentlyContinue).Count -gt 0) {
        $hasCli = $true
    }
    
    if ($hasCli) {
        Log-Info "CLI Interface principle: CLI entry points found"
    } else {
        Log-Warning "CLI Interface principle: No CLI entry points detected"
    }
}

# 4. Security requirements validation
if ($constitutionContent -match "(?i)security|secrets|tls") {
    Log-Info "Checking security compliance..."
    
    # Check for secrets in code
    $secretsFound = $false
    if (Get-Command rg -ErrorAction SilentlyContinue) {
        try {
            $secrets = rg -i "password\s*=\s*['\`"][^'\`"]+['\`"]|api_key\s*=\s*['\`"][^'\`"]+['\`"]|secret\s*=\s*['\`"][^'\`"]+['\`"]" --type py --type js --type ts --type go 2>$null
            if ($secrets) { $secretsFound = $true }
        } catch {}
    }
    
    if ($secretsFound) {
        Log-Error "Security violation: Potential hardcoded secrets found in code"
    } else {
        Log-Info "Security check: No obvious hardcoded secrets found"
    }
    
    # Check for .env files in git
    if ((Test-Path ".env") -and (git ls-files --error-unmatch .env 2>$null)) {
        Log-Error "Security violation: .env file is tracked in git"
    }
}

# 5. Dependency management validation
if ($constitutionContent -match "(?i)dependency|pin") {
    Log-Info "Checking dependency management compliance..."
    
    # Check for lock files
    $lockFiles = @("package-lock.json", "yarn.lock", "pnpm-lock.yaml", "poetry.lock", "Pipfile.lock", "Cargo.lock", "go.sum")
    $hasLockfile = $false
    foreach ($lockfile in $lockFiles) {
        if (Test-Path $lockfile) {
            $hasLockfile = $true
            Log-Info "Dependency management: Found $lockfile"
            break
        }
    }
    
    if (-not $hasLockfile) {
        Log-Warning "Dependency management: No lock files found (dependencies not pinned)"
    }
}

# 6. Architecture baseline validation
if ($constitutionContent -match "Architecture Baseline") {
    Log-Info "Checking architecture baseline compliance..."
    
    # Run architecture validation
    if (Test-Path "scripts/powershell/validate-architecture.ps1") {
        try {
            & "scripts/powershell/validate-architecture.ps1" *>$null
            Log-Info "Architecture baseline: Validation passed"
        } catch {
            Log-Error "Architecture baseline: Validation failed"
        }
    } else {
        Log-Warning "Architecture baseline: No validation script found"
    }
}

# Summary
Write-Host ""
if ($errors -gt 0) {
    Write-Host "Constitutional compliance failed: $errors error(s), $warnings warning(s)" -ForegroundColor Red
    exit 1
} elseif ($warnings -gt 0) {
    Write-Host "Constitutional compliance passed with warnings: $warnings warning(s)" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "Constitutional compliance: All checks passed" -ForegroundColor Green
    exit 0
}
