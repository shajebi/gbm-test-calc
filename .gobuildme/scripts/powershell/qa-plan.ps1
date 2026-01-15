#!/usr/bin/env pwsh
# Purpose: Create test implementation plan from scaffolded tests
# Why: Provides systematic approach to test implementation
# How: Scans test files, categorizes, prioritizes, generates plan from template

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Setup
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (Test-Path "$ScriptDir/qa-common.ps1") {
    . "$ScriptDir/qa-common.ps1"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$SCAFFOLD_DIR = ".gobuildme/specs/qa-test-scaffolding"
$SCAFFOLD_REPORT = "$SCAFFOLD_DIR/scaffold-report.md"
$PLAN_TEMPLATE = ".gobuildme/templates/qa-test-plan-template.md"
$PLAN_FILE = "$SCAFFOLD_DIR/qa-test-plan.md"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Test-Prerequisites {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "🚀 QA Test Planning" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""

    # Check for scaffold report
    if (-not (Test-Path $SCAFFOLD_REPORT)) {
        Write-Host "❌ Error: Scaffold report not found" -ForegroundColor Red
        Write-Host ""
        Write-Host "Expected location: $SCAFFOLD_REPORT"
        Write-Host ""
        Write-Host "Action required: Run /gbm.qa.scaffold-tests first to generate test scaffolding"
        Write-Host ""
        exit 1
    }

    # Check for plan template
    if (-not (Test-Path $PLAN_TEMPLATE)) {
        Write-Host "❌ Error: Plan template not found" -ForegroundColor Red
        Write-Host ""
        Write-Host "Expected location: $PLAN_TEMPLATE"
        Write-Host ""
        Write-Host "Action required: Ensure GoBuildMe is properly installed"
        Write-Host ""
        exit 1
    }

    Write-Host "✓ Prerequisites check passed" -ForegroundColor Green
    Write-Host ""
}

function Get-TestCounts {
    Write-Host "📊 Scanning test files for TODO tests..." -ForegroundColor Yellow
    Write-Host ""

    # Initialize counters
    $totalTests = 0
    $todoTests = 0
    $implementedTests = 0

    # Find test files from scaffold report
    $testFiles = Select-String -Path $SCAFFOLD_REPORT -Pattern "tests/[^)]*\.(php|py|js|ts|java)" -AllMatches |
        ForEach-Object { $_.Matches.Value } | Sort-Object -Unique

    if ($testFiles.Count -eq 0) {
        Write-Host "⚠️  Warning: No test files found in scaffold report" -ForegroundColor Yellow
        Write-Host ""
        return @{
            Total = 0
            Todo = 0
            Implemented = 0
        }
    }

    # Scan each test file
    foreach ($testFile in $testFiles) {
        if (-not (Test-Path $testFile)) {
            continue
        }

        # Count TODO markers
        $fileTodos = (Select-String -Path $testFile -Pattern "TODO|@skip|pytest.skip|markTestSkipped" -AllMatches).Count

        # Count total test functions/methods
        $fileTotal = (Select-String -Path $testFile -Pattern "function test|def test_|it\(|@Test|public function test" -AllMatches).Count

        $todoTests += $fileTodos
        $totalTests += $fileTotal
    }

    $implementedTests = $totalTests - $todoTests

    Write-Host "   Total tests scaffolded: $totalTests" -ForegroundColor Cyan
    Write-Host "   TODO tests to implement: $todoTests" -ForegroundColor Cyan
    Write-Host "   Tests already implemented: $implementedTests" -ForegroundColor Cyan
    Write-Host ""

    return @{
        Total = $totalTests
        Todo = $todoTests
        Implemented = $implementedTests
    }
}

function Get-TestCategories {
    Write-Host "📈 Categorizing tests by type and priority..." -ForegroundColor Yellow
    Write-Host ""

    # Parse scaffold report for test categories
    $unitTests = 0
    $integrationApiTests = 0
    $integrationDbTests = 0
    $e2eTests = 0

    if (Select-String -Path $SCAFFOLD_REPORT -Pattern "Unit Tests" -Quiet) {
        $match = Select-String -Path $SCAFFOLD_REPORT -Pattern "Unit Tests" -Context 0,5 |
            Select-String -Pattern "\d+ tests" | Select-Object -First 1
        if ($match) {
            $unitTests = [regex]::Match($match, "\d+").Value
        }
    }

    if (Select-String -Path $SCAFFOLD_REPORT -Pattern "Integration Tests - API" -Quiet) {
        $match = Select-String -Path $SCAFFOLD_REPORT -Pattern "Integration Tests - API" -Context 0,5 |
            Select-String -Pattern "\d+ tests" | Select-Object -First 1
        if ($match) {
            $integrationApiTests = [regex]::Match($match, "\d+").Value
        }
    }

    if (Select-String -Path $SCAFFOLD_REPORT -Pattern "Integration Tests - Database" -Quiet) {
        $match = Select-String -Path $SCAFFOLD_REPORT -Pattern "Integration Tests - Database" -Context 0,5 |
            Select-String -Pattern "\d+ tests" | Select-Object -First 1
        if ($match) {
            $integrationDbTests = [regex]::Match($match, "\d+").Value
        }
    }

    if (Select-String -Path $SCAFFOLD_REPORT -Pattern "E2E Tests" -Quiet) {
        $match = Select-String -Path $SCAFFOLD_REPORT -Pattern "E2E Tests" -Context 0,5 |
            Select-String -Pattern "\d+ tests" | Select-Object -First 1
        if ($match) {
            $e2eTests = [regex]::Match($match, "\d+").Value
        }
    }

    # Assign priorities
    $highPriority = [int]$integrationApiTests
    $mediumPriority = [int]$integrationDbTests + [int]$unitTests
    $lowPriority = [int]$e2eTests

    Write-Host "   High priority: $highPriority tests" -ForegroundColor Cyan
    Write-Host "   Medium priority: $mediumPriority tests" -ForegroundColor Cyan
    Write-Host "   Low priority: $lowPriority tests" -ForegroundColor Cyan
    Write-Host ""

    return @{
        High = $highPriority
        Medium = $mediumPriority
        Low = $lowPriority
    }
}

function Get-TechStack {
    Write-Host "🔍 Detecting technology stack..." -ForegroundColor Yellow
    Write-Host ""

    $language = "Unknown"
    $testingFramework = "Unknown"
    $mockingLibrary = "Unknown"
    $fixturesStrategy = "Unknown"
    $database = "Unknown"

    # Detect language and framework
    if (Test-Path "composer.json") {
        $language = "PHP"
        $testingFramework = "PHPUnit"
        $mockingLibrary = "Mockery"
        $fixturesStrategy = "Database factories"
    } elseif ((Test-Path "requirements.txt") -or (Test-Path "pyproject.toml")) {
        $language = "Python"
        $testingFramework = "pytest"
        $mockingLibrary = "pytest-mock"
        $fixturesStrategy = "Factory Boy"
    } elseif (Test-Path "package.json") {
        $language = "JavaScript/TypeScript"
        $testingFramework = "Jest"
        $mockingLibrary = "jest.mock"
        $fixturesStrategy = "fixtures.js"
    }

    # Detect database
    if (Test-Path ".env") {
        $envContent = Get-Content ".env" -Raw
        if ($envContent -match "DATABASE_URL.*?(postgresql|mysql|sqlite)") {
            $database = $Matches[1]
        }
    }

    Write-Host "   Language: $language" -ForegroundColor Cyan
    Write-Host "   Testing framework: $testingFramework" -ForegroundColor Cyan
    Write-Host "   Database: $database" -ForegroundColor Cyan
    Write-Host ""

    return @{
        Language = $language
        TestingFramework = $testingFramework
        MockingLibrary = $mockingLibrary
        FixturesStrategy = $fixturesStrategy
        Database = $database
    }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Coverage Gap Analysis (CRITICAL for #32)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$TEST_DIRS = @("tests", "test", "spec", "__tests__")

function Get-CoverageBaseline {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "📊 Analyzing Coverage Baseline (Production Code Without Tests)" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""

    # Source directories to scan
    $sourceDirs = @("src", "app", "lib", "pkg", "internal", "cmd")
    $sourceFiles = @()

    foreach ($dir in $sourceDirs) {
        if (Test-Path $dir) {
            $sourceFiles += Get-ChildItem -Path $dir -Recurse -Include "*.php","*.py","*.js","*.ts","*.go","*.java","*.rb" -File |
                Where-Object { $_.Name -notmatch "_test\.|test_|\.test\.|Test\." }
        }
    }

    $totalSource = $sourceFiles.Count
    Write-Host "   Found $totalSource source files to analyze" -ForegroundColor Cyan
    Write-Host "   Checking test directories: $($TEST_DIRS -join ', ')" -ForegroundColor Cyan
    Write-Host ""

    if ($totalSource -eq 0) {
        Write-Host "   No source files found in common directories (src/, app/, lib/, etc.)" -ForegroundColor Yellow
        return @{
            CoverageBaseline = 100
            UntestedCount = 0
            TotalSourceFiles = 0
            HighPriorityGap = 0
            MediumPriorityGap = 0
            LowPriorityGap = 0
        }
    }

    $untestedCount = 0
    $highPriorityGap = 0
    $mediumPriorityGap = 0
    $lowPriorityGap = 0

    foreach ($sourceFile in $sourceFiles) {
        $baseName = $sourceFile.BaseName
        $ext = $sourceFile.Extension
        $hasTest = $false

        # Check common test naming patterns across all test directories
        switch ($ext) {
            ".php" {
                foreach ($testDir in $TEST_DIRS) {
                    if ((Test-Path $testDir -PathType Container) -and -not $hasTest) {
                        $hasTest = (Get-ChildItem -Path $testDir -Recurse -Filter "${baseName}Test.php" -ErrorAction SilentlyContinue).Count -gt 0
                    }
                }
            }
            ".py" {
                foreach ($testDir in $TEST_DIRS) {
                    if ((Test-Path $testDir -PathType Container) -and -not $hasTest) {
                        $hasTest = (Get-ChildItem -Path $testDir -Recurse -Filter "test_${baseName}.py" -ErrorAction SilentlyContinue).Count -gt 0
                    }
                }
            }
            { $_ -in ".js", ".ts" } {
                foreach ($testDir in $TEST_DIRS) {
                    if ((Test-Path $testDir -PathType Container) -and -not $hasTest) {
                        $hasTest = (Get-ChildItem -Path $testDir -Recurse -Filter "${baseName}.test.*" -ErrorAction SilentlyContinue).Count -gt 0
                        if (-not $hasTest) {
                            $hasTest = (Get-ChildItem -Path $testDir -Recurse -Filter "${baseName}.spec.*" -ErrorAction SilentlyContinue).Count -gt 0
                        }
                    }
                }
            }
            ".go" {
                $testFile = Join-Path $sourceFile.DirectoryName "${baseName}_test.go"
                $hasTest = Test-Path $testFile
            }
            ".java" {
                $hasTest = (Get-ChildItem -Path . -Recurse -Filter "${baseName}Test.java" -ErrorAction SilentlyContinue |
                    Where-Object { $_.FullName -match "test" }).Count -gt 0
            }
        }

        if (-not $hasTest) {
            $untestedCount++

            # Categorize by priority
            if ($sourceFile.FullName -match "auth|security|payment|Controller|Service") {
                $highPriorityGap++
            } elseif ($sourceFile.FullName -match "api|model|repository") {
                $mediumPriorityGap++
            } else {
                $lowPriorityGap++
            }
        }
    }

    # Calculate baseline coverage percentage
    $testedCount = $totalSource - $untestedCount
    $coveragePct = 0
    if ($totalSource -gt 0) {
        $coveragePct = [math]::Floor($testedCount * 100 / $totalSource)
    }

    Write-Host "   Coverage Baseline Results:" -ForegroundColor Cyan
    Write-Host "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "   Total source files: $totalSource"
    Write-Host "   Files with tests: $testedCount"
    Write-Host "   Files without tests: $untestedCount"
    Write-Host "   Current test coverage: ${coveragePct}%"
    Write-Host ""
    Write-Host "   Coverage Gaps by Priority:"
    Write-Host "   - High priority (auth, security, controllers, services): $highPriorityGap"
    Write-Host "   - Medium priority (api, models, repositories): $mediumPriorityGap"
    Write-Host "   - Low priority (other): $lowPriorityGap"
    Write-Host ""

    return @{
        CoverageBaseline = $coveragePct
        UntestedCount = $untestedCount
        TotalSourceFiles = $totalSource
        HighPriorityGap = $highPriorityGap
        MediumPriorityGap = $mediumPriorityGap
        LowPriorityGap = $lowPriorityGap
    }
}

function New-Plan {
    param(
        [hashtable]$TestCounts,
        [hashtable]$Categories,
        [hashtable]$TechStack,
        [hashtable]$CoverageBaseline
    )

    Write-Host "📝 Generating test implementation plan..." -ForegroundColor Yellow
    Write-Host ""

    # Create scaffold directory if it doesn't exist
    if (-not (Test-Path $SCAFFOLD_DIR)) {
        New-Item -ItemType Directory -Path $SCAFFOLD_DIR | Out-Null
    }

    # Copy template
    Copy-Item $PLAN_TEMPLATE $PLAN_FILE -Force

    # Get current date
    $currentDate = Get-Date -Format "yyyy-MM-dd"

    # Replace placeholders
    $content = Get-Content $PLAN_FILE -Raw
    $content = $content -replace '\[DATE\]', $currentDate
    $content = $content -replace '\[PROJECT/FEATURE\]', 'Project-wide Test Implementation'
    $content = $content -replace '\[Scope: Project-wide | Feature-specific\]', 'Scope: Project-wide'

    # Fill in test counts
    $content = $content -replace 'Total Tests Scaffolded\]: \[NUMBER\]', "Total Tests Scaffolded]: $($TestCounts.Total)"
    $content = $content -replace 'TODO Tests to Implement\]: \[NUMBER\]', "TODO Tests to Implement]: $($TestCounts.Todo)"
    $content = $content -replace 'Tests Already Implemented\]: \[NUMBER\]', "Tests Already Implemented]: $($TestCounts.Implemented)"

    # Fill in technology stack
    $content = $content -replace 'Language/Version\]: \[e\.g\., Python 3\.11, PHP 8\.2, JavaScript ES2022\]', "Language/Version]: $($TechStack.Language)"
    $content = $content -replace 'Testing Framework\]: \[e\.g\., pytest, PHPUnit, Jest\]', "Testing Framework]: $($TechStack.TestingFramework)"
    $content = $content -replace 'Mocking Strategy\]: \[e\.g\., unittest\.mock, Mockery, jest\.mock\]', "Mocking Strategy]: $($TechStack.MockingLibrary)"
    $content = $content -replace 'Fixtures Strategy\]: \[e\.g\., Factory Boy, Faker, fixtures\.js\]', "Fixtures Strategy]: $($TechStack.FixturesStrategy)"
    $content = $content -replace 'Database\]: \[e\.g\., PostgreSQL 15, MySQL 8\.0, MongoDB 6\.0\]', "Database]: $($TechStack.Database)"

    # Save updated content
    $content | Set-Content $PLAN_FILE -NoNewline

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # CRITICAL: Persist coverage baseline to the artifact (#32)
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    $testedFiles = $CoverageBaseline.TotalSourceFiles - $CoverageBaseline.UntestedCount

    $coverageSection = @"

## Coverage Baseline Analysis (Production Code)

**Analysis Date**: $currentDate
**Source Directories Scanned**: src/, app/, lib/, pkg/, internal/, cmd/
**Test Directories Checked**: $($TEST_DIRS -join ', ')

### Production Code Coverage Baseline

| Metric | Value |
|--------|-------|
| Total Source Files | $($CoverageBaseline.TotalSourceFiles) |
| Files With Tests | $testedFiles |
| Files Without Tests | $($CoverageBaseline.UntestedCount) |
| **Coverage Baseline** | **$($CoverageBaseline.CoverageBaseline)%** |

### Coverage Gaps by Priority

| Priority | Count | Description |
|----------|-------|-------------|
| **High** | $($CoverageBaseline.HighPriorityGap) | Auth, security, controllers, services |
| **Medium** | $($CoverageBaseline.MediumPriorityGap) | API, models, repositories |
| **Low** | $($CoverageBaseline.LowPriorityGap) | Other utility code |
| **Total Gaps** | $($CoverageBaseline.UntestedCount) | Production files without corresponding tests |

> **Note**: Coverage gaps are production code files that don't have corresponding test files.
> Run ``/gbm.qa.tasks`` to generate actionable tasks for each gap.

"@

    # Find the line number for insertion (before "### Test Files Analysis")
    $planContent = Get-Content $PLAN_FILE
    $insertIndex = -1
    for ($i = 0; $i -lt $planContent.Count; $i++) {
        if ($planContent[$i] -match "### Test Files Analysis") {
            $insertIndex = $i
            break
        }
    }

    if ($insertIndex -ge 0) {
        # Insert coverage baseline section before "### Test Files Analysis"
        $newContent = @()
        $newContent += $planContent[0..($insertIndex - 1)]
        $newContent += $coverageSection
        $newContent += $planContent[$insertIndex..($planContent.Count - 1)]
        $newContent | Set-Content $PLAN_FILE
    } else {
        # Fallback: append to end of file if marker not found
        Add-Content -Path $PLAN_FILE -Value $coverageSection
    }

    # Update Quality Metrics section with actual baseline values
    $content = Get-Content $PLAN_FILE -Raw
    $content = $content -replace 'Overall coverage: 0% \(target: 85%\)', "Overall coverage: $($CoverageBaseline.CoverageBaseline)% (target: 85%)"
    $content | Set-Content $PLAN_FILE -NoNewline

    Write-Host "   ✓ Plan generated: $PLAN_FILE" -ForegroundColor Green
    Write-Host "   ✓ Coverage baseline persisted to artifact" -ForegroundColor Green
    Write-Host ""
}

function Show-Summary {
    param(
        [hashtable]$TestCounts,
        [hashtable]$Categories,
        [hashtable]$CoverageBaseline
    )

    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "QA Test Implementation Plan Created" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Test Coverage Summary"
    Write-Host "   Total tests scaffolded: $($TestCounts.Total)"
    Write-Host "   TODO tests to implement: $($TestCounts.Todo)"
    Write-Host "   Tests already implemented: $($TestCounts.Implemented)"
    Write-Host ""
    Write-Host "Coverage Baseline (Production Code)"
    Write-Host "   Total source files: $($CoverageBaseline.TotalSourceFiles)"
    Write-Host "   Files with tests: $($CoverageBaseline.TotalSourceFiles - $CoverageBaseline.UntestedCount)"
    Write-Host "   Files without tests: $($CoverageBaseline.UntestedCount)"
    Write-Host "   Coverage baseline: $($CoverageBaseline.CoverageBaseline)%"
    Write-Host ""
    Write-Host "Breakdown by Priority"
    Write-Host "   High priority: $($Categories.High) tests (auth, security, critical paths)"
    Write-Host "   Medium priority: $($Categories.Medium) tests (CRUD, validation, business logic)"
    Write-Host "   Low priority: $($Categories.Low) tests (edge cases, non-critical)"
    Write-Host ""
    Write-Host "Coverage Gaps by Priority"
    Write-Host "   High (auth, security, controllers): $($CoverageBaseline.HighPriorityGap)"
    Write-Host "   Medium (api, models, repositories): $($CoverageBaseline.MediumPriorityGap)"
    Write-Host "   Low (other utility code): $($CoverageBaseline.LowPriorityGap)"
    Write-Host ""
    Write-Host "Plan Location"
    Write-Host "   $PLAN_FILE"
    Write-Host ""
    Write-Host "Next Steps"
    Write-Host "   1. Review the plan: $PLAN_FILE"
    Write-Host "   2. Generate task checklist: /gbm.qa.tasks"
    Write-Host "   3. Optionally generate fixtures: /gbm.qa.generate-fixtures (recommended)"
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Main
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# 1. Architecture integration
if (Get-Command Test-AndGenerateArchitecture -ErrorAction SilentlyContinue) {
    Test-AndGenerateArchitecture
}

# 2. Check prerequisites
Test-Prerequisites

# 3. Scan test files
$testCounts = Get-TestCounts

# 4. Categorize tests
$categories = Get-TestCategories

# 5. Detect tech stack
$techStack = Get-TechStack

# 6. Analyze coverage baseline (CRITICAL for #32)
$coverageBaseline = Get-CoverageBaseline

# 7. Generate plan (with coverage baseline persistence)
New-Plan -TestCounts $testCounts -Categories $categories -TechStack $techStack -CoverageBaseline $coverageBaseline

# 8. Display summary (including coverage baseline)
Show-Summary -TestCounts $testCounts -Categories $categories -CoverageBaseline $coverageBaseline
