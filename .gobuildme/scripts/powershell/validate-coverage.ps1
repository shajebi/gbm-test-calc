# Purpose: Validate test coverage meets thresholds
# Why: Enforce quality gates for unit, integration, and e2e tests
# How: Run coverage tools and compare against thresholds

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Unit test coverage threshold")]
    [int]$UnitThreshold = 90,

    [Parameter(HelpMessage = "Integration test coverage threshold")]
    [int]$IntegrationThreshold = 95,

    [Parameter(HelpMessage = "E2E test coverage threshold")]
    [int]$E2EThreshold = 80,

    [Parameter(HelpMessage = "Overall coverage threshold")]
    [int]$OverallThreshold = 85
)

$ErrorActionPreference = "Stop"

Write-Host "╔════════════════════════════════════════════════════════════════╗"
Write-Host "║              TEST COVERAGE VALIDATION                          ║"
Write-Host "╚════════════════════════════════════════════════════════════════╝"
Write-Host ""

# Detect language and test framework
function Detect-Language {
    if ((Test-Path "requirements.txt") -or (Test-Path "pyproject.toml")) {
        return "python"
    } elseif (Test-Path "package.json") {
        return "javascript"
    } elseif (Test-Path "composer.json") {
        return "php"
    } elseif ((Test-Path "pom.xml") -or (Test-Path "build.gradle")) {
        return "java"
    } elseif (Test-Path "go.mod") {
        return "go"
    } elseif (Test-Path "Cargo.toml") {
        return "rust"
    } else {
        return "unknown"
    }
}

$Language = Detect-Language
Write-Host "Detected language: $Language" -ForegroundColor Blue
Write-Host ""

# Run coverage for Python
function Run-PythonCoverage {
    Write-Host "Running Python coverage..."

    if (-not (Get-Command pytest -ErrorAction SilentlyContinue)) {
        Write-Host "✗ pytest not found" -ForegroundColor Red
        return $false
    }

    # Check if pytest-cov is installed
    $pytestCov = python -c "import pytest_cov" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠ pytest-cov not installed" -ForegroundColor Yellow
        return $false
    }

    # Run coverage
    pytest --cov=. --cov-report=term-missing --cov-report=json tests/ 2>&1 | Out-Null

    # Parse coverage.json
    if (Test-Path "coverage.json") {
        $CoverageData = Get-Content "coverage.json" | ConvertFrom-Json
        $Overall = [math]::Floor($CoverageData.totals.percent_covered)
        Write-Host "Overall coverage: $Overall%" -ForegroundColor Green

        if ($Overall -lt $OverallThreshold) {
            Write-Host "✗ Coverage $Overall% is below threshold $OverallThreshold%" -ForegroundColor Red
            return $false
        } else {
            Write-Host "✓ Coverage $Overall% meets threshold $OverallThreshold%" -ForegroundColor Green
            return $true
        }
    }

    return $false
}

# Run coverage for JavaScript/TypeScript
function Run-JavaScriptCoverage {
    Write-Host "Running JavaScript/TypeScript coverage..."

    if (Test-Path "package.json") {
        $PackageJson = Get-Content "package.json" | ConvertFrom-Json

        # Check for coverage script
        if ($PackageJson.scripts.coverage) {
            # Try npm, yarn, or pnpm
            if (Get-Command npm -ErrorAction SilentlyContinue) {
                npm run coverage 2>&1 | Out-Null
            } elseif (Get-Command yarn -ErrorAction SilentlyContinue) {
                yarn coverage 2>&1 | Out-Null
            } elseif (Get-Command pnpm -ErrorAction SilentlyContinue) {
                pnpm coverage 2>&1 | Out-Null
            }

            # Parse coverage from coverage-summary.json
            if (Test-Path "coverage/coverage-summary.json") {
                $CoverageSummary = Get-Content "coverage/coverage-summary.json" | ConvertFrom-Json
                $Overall = [math]::Floor($CoverageSummary.total.lines.pct)
                Write-Host "Overall coverage: $Overall%" -ForegroundColor Green

                if ($Overall -lt $OverallThreshold) {
                    Write-Host "✗ Coverage $Overall% is below threshold $OverallThreshold%" -ForegroundColor Red
                    return $false
                } else {
                    Write-Host "✓ Coverage $Overall% meets threshold $OverallThreshold%" -ForegroundColor Green
                    return $true
                }
            }
        } else {
            Write-Host "⚠ No coverage script found in package.json" -ForegroundColor Yellow
            return $false
        }
    }

    return $false
}

# Run coverage for PHP
function Run-PHPCoverage {
    Write-Host "Running PHP coverage..."

    if (Get-Command phpunit -ErrorAction SilentlyContinue) {
        $CoverageOutput = phpunit --coverage-text --coverage-html=coverage 2>&1

        # Parse coverage from output
        $CoverageLine = $CoverageOutput | Select-String "Lines:" | Select-Object -Last 1
        if ($CoverageLine) {
            if ($CoverageLine -match '(\d+\.\d+)%') {
                $Overall = [math]::Floor([double]$matches[1])
                Write-Host "Overall coverage: $Overall%" -ForegroundColor Green

                if ($Overall -lt $OverallThreshold) {
                    Write-Host "✗ Coverage $Overall% is below threshold $OverallThreshold%" -ForegroundColor Red
                    return $false
                } else {
                    Write-Host "✓ Coverage $Overall% meets threshold $OverallThreshold%" -ForegroundColor Green
                    return $true
                }
            }
        }
    } else {
        Write-Host "⚠ PHPUnit not found" -ForegroundColor Yellow
        return $false
    }

    return $false
}

# Run coverage for Java
function Run-JavaCoverage {
    Write-Host "Running Java coverage..."

    if (Test-Path "pom.xml") {
        # Maven with JaCoCo
        mvn clean test jacoco:report 2>&1 | Out-Null

        # Parse coverage from target/site/jacoco/index.html
        if (Test-Path "target/site/jacoco/index.html") {
            $IndexHTML = Get-Content "target/site/jacoco/index.html" -Raw
            if ($IndexHTML -match 'Total[^0-9]*(\d+)%') {
                $Overall = [int]$matches[1]
                Write-Host "Overall coverage: $Overall%" -ForegroundColor Green

                if ($Overall -lt $OverallThreshold) {
                    Write-Host "✗ Coverage $Overall% is below threshold $OverallThreshold%" -ForegroundColor Red
                    return $false
                } else {
                    Write-Host "✓ Coverage $Overall% meets threshold $OverallThreshold%" -ForegroundColor Green
                    return $true
                }
            }
        }
    } elseif (Test-Path "build.gradle") {
        # Gradle with JaCoCo
        if (Test-Path "./gradlew") {
            ./gradlew test jacocoTestReport 2>&1 | Out-Null
        } else {
            gradle test jacocoTestReport 2>&1 | Out-Null
        }

        # Parse coverage from build/reports/jacoco/test/html/index.html
        if (Test-Path "build/reports/jacoco/test/html/index.html") {
            $IndexHTML = Get-Content "build/reports/jacoco/test/html/index.html" -Raw
            if ($IndexHTML -match 'Total[^0-9]*(\d+)%') {
                $Overall = [int]$matches[1]
                Write-Host "Overall coverage: $Overall%" -ForegroundColor Green

                if ($Overall -lt $OverallThreshold) {
                    Write-Host "✗ Coverage $Overall% is below threshold $OverallThreshold%" -ForegroundColor Red
                    return $false
                } else {
                    Write-Host "✓ Coverage $Overall% meets threshold $OverallThreshold%" -ForegroundColor Green
                    return $true
                }
            }
        }
    }

    return $false
}

# Run coverage for Go
function Run-GoCoverage {
    Write-Host "Running Go coverage..."

    if (Get-Command go -ErrorAction SilentlyContinue) {
        go test -coverprofile=coverage.out ./... 2>&1 | Out-Null

        if (Test-Path "coverage.out") {
            $CoverageOutput = go tool cover -func=coverage.out
            $TotalLine = $CoverageOutput | Select-String "total" | Select-Object -Last 1
            if ($TotalLine -match '(\d+\.\d+)%') {
                $Overall = [math]::Floor([double]$matches[1])
                Write-Host "Overall coverage: $Overall%" -ForegroundColor Green

                if ($Overall -lt $OverallThreshold) {
                    Write-Host "✗ Coverage $Overall% is below threshold $OverallThreshold%" -ForegroundColor Red
                    return $false
                } else {
                    Write-Host "✓ Coverage $Overall% meets threshold $OverallThreshold%" -ForegroundColor Green
                    return $true
                }
            }
        }
    }

    return $false
}

# Main execution
$Success = switch ($Language) {
    "python" { Run-PythonCoverage }
    "javascript" { Run-JavaScriptCoverage }
    "php" { Run-PHPCoverage }
    "java" { Run-JavaCoverage }
    "go" { Run-GoCoverage }
    default {
        Write-Host "✗ Unsupported language: $Language" -ForegroundColor Red
        $false
    }
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗"
Write-Host "║              COVERAGE VALIDATION COMPLETE                      ║"
Write-Host "╚════════════════════════════════════════════════════════════════╝"

if ($Success) {
    exit 0
} else {
    exit 1
}
