#!/usr/bin/env pwsh
# Purpose: Review test quality, coverage, and best practices
# Why: Ensures tests meet quality standards before final review
# How: Analyzes test structure, coverage, and AC traceability

# Source common utilities
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path "$ScriptDir/qa-common.ps1")) {
    Write-Host "Error: qa-common.ps1 not found in $ScriptDir" -ForegroundColor Red
    exit 1
}

. "$ScriptDir/qa-common.ps1"

Write-Host "🔍 Reviewing test quality..."
Write-Host ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 1: Check and generate architecture
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Test-AndGenerateArchitecture

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 1.5: Quality Gate - Check Task Completion (Critical)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# This quality gate enforces that all test implementation tasks are complete
# before allowing the review to proceed. This prevents incomplete test
# implementations from passing through to merge.

$TASKS_FILE = ".gobuildme/specs/qa-test-scaffolding/qa-test-tasks.md"

if (Test-Path $TASKS_FILE) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "🚧 Quality Gate: Task Completion Check" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""

    # Count unchecked tasks
    $incompleteCount = (Select-String -Path $TASKS_FILE -Pattern "^- \[ \] [0-9]" -AllMatches).Count
    $totalCount = (Select-String -Path $TASKS_FILE -Pattern "^- \[.\] [0-9]" -AllMatches).Count
    $completedCount = (Select-String -Path $TASKS_FILE -Pattern "^- \[x\] [0-9]" -AllMatches).Count

    if ($incompleteCount -gt 0) {
        Write-Host "❌ Quality Gate: Test Implementation Incomplete" -ForegroundColor Red
        Write-Host ""
        Write-Host "   Status: $completedCount/$totalCount tasks complete"
        Write-Host "   Remaining: $incompleteCount tasks"
        Write-Host ""
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host "🔄 Automatically continuing test implementation..." -ForegroundColor Yellow
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host ""

        # Automatically run qa-implement.ps1 to finish remaining tasks
        $implementScript = Join-Path $ScriptDir "qa-implement.ps1"

        if (Test-Path $implementScript) {
            Write-Host "Running /gbm.qa.implement to complete remaining tasks..."
            Write-Host ""

            # Execute qa-implement.ps1 to finish all remaining tasks
            & $implementScript

            # After implementation, check again
            $incompleteAfter = (Select-String -Path $TASKS_FILE -Pattern "^- \[ \] [0-9]" -AllMatches).Count

            if ($incompleteAfter -gt 0) {
                Write-Host ""
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                Write-Host "⚠️  Warning: $incompleteAfter tasks still incomplete" -ForegroundColor Yellow
                Write-Host "   User stopped implementation. Run /gbm.qa.review-tests again to continue."
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                Write-Host ""
                exit 1
            } else {
                Write-Host ""
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                Write-Host "✅ All tasks completed! Continuing with review..." -ForegroundColor Green
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                Write-Host ""
            }
        } else {
            Write-Host "❌ Error: qa-implement.ps1 not found at $implementScript" -ForegroundColor Red
            Write-Host "   Please run /gbm.qa.implement manually to complete remaining tasks"
            Write-Host ""
            exit 1
        }
    } else {
        Write-Host "✅ Task completion check passed" -ForegroundColor Green
        Write-Host "   All $totalCount tasks completed"
        Write-Host ""
    }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 2: Load context (architecture, persona, config)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

$archContext = Get-ArchitectureContext
$featureContext = Get-FeatureContext
$personaConfig = Get-PersonaConfig
$qaConfig = Get-QaConfig

$language = if ($archContext -and $archContext.Language) { $archContext.Language } else { Get-ProjectLanguage }
$testFramework = Get-TestFramework

Write-Section "📊 Context Loaded"
Write-Host "Language:        $language"
Write-Host "Test Framework:  $testFramework"

# Display persona if configured
if ($personaConfig.PersonaName) {
    Write-Host "Persona:         $($personaConfig.PersonaName)"
    if ($personaConfig.CoverageFloor) {
        $coveragePercent = [math]::Round([double]$personaConfig.CoverageFloor * 100)
        Write-Host "Coverage Floor:  ${coveragePercent}% (persona)"
    }
}

# Display gate mode
Write-Host "Gate Mode:       $($qaConfig.GateMode)"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 3: Check test structure
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Write-Section "📁 Test Structure Check"

$issues = 0

# Check if tests directory exists
if (-not (Test-Path "tests")) {
    Write-Error "tests/ directory not found"
    $issues++
} else {
    Write-Success "tests/ directory exists"

    # Check for test subdirectories
    if (Test-Path "tests/unit") {
        Write-Success "tests/unit/ exists"
    } else {
        Write-Warning "tests/unit/ not found"
    }

    if (Test-Path "tests/integration") {
        Write-Success "tests/integration/ exists"
    } else {
        Write-Warning "tests/integration/ not found"
    }

    if (Test-Path "tests/e2e") {
        Write-Success "tests/e2e/ exists"
    } else {
        Write-Warning "tests/e2e/ not found (optional)"
    }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 4: Check for remaining TODOs
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Write-Section "📝 TODO Check"

$todoFiles = Find-TestTodos -TestDir "tests"

if ($todoFiles.Count -eq 0) {
    Write-Success "No TODO tests found"
} else {
    $todoCount = $todoFiles.Count
    Write-Warning "Found $todoCount file(s) with TODOs"
    foreach ($file in $todoFiles) {
        Write-Host "  • $($file.FullName)"
    }
    $issues++
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 5: Run coverage analysis (Per-Type Coverage)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Write-Section "📊 Coverage Analysis (Per-Type)"

$coveragePassed = $true
$coverageIssues = 0

# Get thresholds from config (aligned with documentation)
$unitThreshold = Get-CoverageThreshold -TestType "unit"
$integrationThreshold = Get-CoverageThreshold -TestType "integration"
$e2eThreshold = Get-CoverageThreshold -TestType "e2e"
$overallThreshold = Get-CoverageThreshold -TestType "overall"

Write-Host "Coverage Thresholds:"
Write-Host "  Unit:        ${unitThreshold}%"
Write-Host "  Integration: ${integrationThreshold}%"
Write-Host "  E2E:         ${e2eThreshold}%"
Write-Host "  Overall:     ${overallThreshold}%"
Write-Host ""

switch ($testFramework) {
    "pytest" {
        if (Get-Command pytest -ErrorAction SilentlyContinue) {
            Write-Host "Running pytest with coverage..."
            Write-Host ""

            # Per-type coverage checks
            $testTypes = @(
                @{ Name = "Unit"; Dir = "tests/unit"; Threshold = $unitThreshold },
                @{ Name = "Integration"; Dir = "tests/integration"; Threshold = $integrationThreshold },
                @{ Name = "E2E"; Dir = "tests/e2e"; Threshold = $e2eThreshold }
            )

            foreach ($testType in $testTypes) {
                if (Test-Path $testType.Dir) {
                    Write-Host "Running $($testType.Name) tests with coverage..."
                    $covJsonFile = "coverage_$($testType.Name.ToLower()).json"

                    # Run pytest for this test type
                    $null = pytest $testType.Dir --cov --cov-report=json:$covJsonFile -q 2>$null

                    if (Test-Path $covJsonFile) {
                        try {
                            $coverageData = Get-Content $covJsonFile | ConvertFrom-Json
                            $coverage = [math]::Round($coverageData.totals.percent_covered)

                            if ($coverage -ge $testType.Threshold) {
                                Write-Success "$($testType.Name): ${coverage}% (threshold: $($testType.Threshold)%)"
                            } else {
                                Write-Error "$($testType.Name): ${coverage}% (threshold: $($testType.Threshold)%)"
                                $coveragePassed = $false
                                $coverageIssues++
                            }

                            # Cleanup
                            Remove-Item $covJsonFile -ErrorAction SilentlyContinue
                        } catch {
                            Write-Warning "Failed to parse $covJsonFile"
                        }
                    } else {
                        Write-Warning "$($testType.Name): No coverage data available"
                    }
                } else {
                    Write-Info "$($testType.Name): Directory $($testType.Dir) not found (skipped)"
                }
            }

            # Overall coverage check
            Write-Host ""
            Write-Host "Running overall coverage check..."
            $null = pytest --cov --cov-report=json -q 2>$null

            if (Test-Path "coverage.json") {
                try {
                    $coverageData = Get-Content "coverage.json" | ConvertFrom-Json
                    $coverage = [math]::Round($coverageData.totals.percent_covered)

                    if ($coverage -ge $overallThreshold) {
                        Write-Success "Overall: ${coverage}% (threshold: ${overallThreshold}%)"
                    } else {
                        Write-Error "Overall: ${coverage}% (threshold: ${overallThreshold}%)"
                        $coveragePassed = $false
                        $coverageIssues++
                    }
                } catch {
                    Write-Warning "Failed to parse coverage.json"
                    $coveragePassed = $false
                }
            }
        } else {
            Write-Warning "pytest not installed, skipping coverage"
        }
    }
    { $_ -in "jest", "vitest" } {
        if (Get-Command npm -ErrorAction SilentlyContinue) {
            Write-Host "Running Jest/Vitest with coverage..."

            # Per-type coverage for Jest/Vitest
            $testTypes = @(
                @{ Name = "Unit"; Pattern = "tests/unit"; Threshold = $unitThreshold },
                @{ Name = "Integration"; Pattern = "tests/integration"; Threshold = $integrationThreshold },
                @{ Name = "E2E"; Pattern = "tests/e2e"; Threshold = $e2eThreshold }
            )

            foreach ($testType in $testTypes) {
                if (Test-Path $testType.Pattern) {
                    Write-Host "Running $($testType.Name) tests..."
                    $null = npm test -- --coverage --testPathPattern="$($testType.Pattern)" --silent 2>$null

                    if ($LASTEXITCODE -eq 0) {
                        Write-Success "$($testType.Name): Coverage check passed"
                    } else {
                        Write-Warning "$($testType.Name): Coverage check failed"
                        $coveragePassed = $false
                        $coverageIssues++
                    }
                }
            }

            # Overall check
            $null = npm test -- --coverage --silent 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Overall: Coverage check passed"
            } else {
                Write-Warning "Overall: Coverage check failed"
                $coveragePassed = $false
            }
        } else {
            Write-Warning "npm not found, skipping coverage"
        }
    }
    default {
        Write-Warning "Coverage analysis not implemented for $testFramework"
    }
}

# Track coverage issues separately
if ($coverageIssues -gt 0) {
    $issues += $coverageIssues
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 6: Check AC traceability
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Write-Section "✅ AC Traceability Check"

if ($featureContext.AcceptanceCriteria -and $featureContext.AcceptanceCriteria.Count -gt 0) {
    $acCount = $featureContext.AcceptanceCriteria.Count
    $testedAcs = 0
    $manualReviewAcs = 0

    Write-Host "Checking $acCount acceptance criteria..."
    Write-Host ""

    # Check for manual overrides
    $acOverridesFile = ".gobuildme/specs/qa-test-scaffolding/ac-overrides.yaml"

    foreach ($ac in $featureContext.AcceptanceCriteria) {
        if ($ac -match "^(\d+)\.") {
            $acNum = $matches[1]

            # Check if AC is marked for manual review
            if ((Test-Path $acOverridesFile) -and (Select-String -Path $acOverridesFile -Pattern "AC${acNum}" -Quiet)) {
                Write-Host "  ℹ️  AC${acNum}: Manual review required"
                $manualReviewAcs++
            }
            # Search for AC reference in tests
            elseif (Get-ChildItem -Path "tests" -Recurse -Include "*.py","*.js","*.ts","*.php","*.java" -ErrorAction SilentlyContinue |
                    Select-String -Pattern "AC${acNum}|AC-${acNum}|AC ${acNum}" -Quiet) {
                Write-Host "  ✓ AC${acNum}: Tested"
                $testedAcs++
            } else {
                Write-Host "  ✗ AC${acNum}: Not tested"
            }
        }
    }

    # Calculate traceability percentage
    $testableAcCount = $acCount - $manualReviewAcs
    if ($testableAcCount -gt 0) {
        $acTraceability = [math]::Round(($testedAcs * 100) / $testableAcCount)
    } else {
        $acTraceability = 100
    }

    $acMinThreshold = $qaConfig.AcTraceabilityMin

    if ($testedAcs -eq $testableAcCount) {
        Write-Success "All testable ACs have tests (100% traceability)"
    } elseif ($acTraceability -ge $acMinThreshold) {
        Write-Success "$testedAcs/$testableAcCount ACs have tests (${acTraceability}% ≥ ${acMinThreshold}%)"
        if ($manualReviewAcs -gt 0) {
            Write-Info "$manualReviewAcs AC(s) marked for manual review"
        }
    } else {
        Write-Error "$testedAcs/$testableAcCount ACs have tests (${acTraceability}% < ${acMinThreshold}%)"
        $issues++
        if ($manualReviewAcs -gt 0) {
            Write-Info "$manualReviewAcs AC(s) marked for manual review"
        }
        if ($qaConfig.AcManualReview) {
            Write-Info "Tip: Mark non-testable ACs in $acOverridesFile"
        }
    }
} else {
    Write-Info "No acceptance criteria found (skipping traceability check)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 7: Generate review report
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

New-Item -ItemType Directory -Force -Path ".gobuildme/specs/qa-test-scaffolding" | Out-Null

$testStructureStatus = if (Test-Path "tests") { "✓ Pass" } else { "✗ Fail" }
$todoStatus = if ($todoFiles.Count -eq 0) { "✓ None" } else { "⚠️ Found" }
$coverageStatus = if ($coveragePassed) { "✓ Pass" } else { "⚠️ Below threshold" }
$acTraceabilityStatus = if ($featureContext.AcceptanceCriteria) { "Checked" } else { "N/A" }

$report = @"
# Test Quality Review Report

**Generated**: $(Get-Date)
**Language**: $language
**Test Framework**: $testFramework

## Summary

- **Test Structure**: $testStructureStatus
- **TODO Tests**: $todoStatus
- **Coverage**: $coverageStatus
- **AC Traceability**: $acTraceabilityStatus

## Issues Found

Total issues: $issues

"@

if ($issues -eq 0) {
    $report += @'
✅ **No issues found!** Tests meet quality standards.

'@
} else {
    $report += @'
⚠️ **Issues found.** Please address before proceeding.

'@
}

$report += @'
## Recommendations

1. **Implement all TODO tests** - Use /gbm.qa.implement-tests for guidance
2. **Improve coverage** - Add tests for uncovered code paths
3. **Ensure AC traceability** - Reference ACs in test docstrings
4. **Follow AAA pattern** - Arrange, Act, Assert structure
5. **Use descriptive names** - Test names should describe behavior

## Next Steps

- Fix any issues found above
- Re-run: /gbm.qa.review-tests
- When all checks pass: /gbm.review
- Then: /gbm.push

'@

Set-Content -Path ".gobuildme/specs/qa-test-scaffolding/quality-review.md" -Value $report

# Save pass/fail status for /gbm.review integration
$qualityReviewStatus = if ($issues -eq 0) { "true" } else { "false" }
Set-Content -Path ".gobuildme/specs/qa-test-scaffolding/quality-review.txt" -Value "quality_review_passed=$qualityReviewStatus"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Step 8: Display results
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Write-Section "📊 Review Summary"

# Determine exit code based on gate mode
$exitCode = 0

if ($issues -eq 0) {
    Write-Host "✅ All quality checks passed!"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  • Run final review: /gbm.review"
    Write-Host "  • Create PR: /gbm.push"
    $exitCode = 0
} else {
    switch ($qaConfig.GateMode) {
        "strict" {
            Write-Host "❌ Found $issues issue(s) - BLOCKING (strict mode)"
            Write-Host ""
            Write-Host "Quality gates failed. Must fix before proceeding."
            Write-Host ""
            Write-Host "Next steps:"
            Write-Host "  • Address issues listed above"
            Write-Host "  • Re-run: /gbm.qa.review-tests"
            Write-Host ""
            Write-Host "To change gate mode, edit .gobuildme/config/qa-config.yaml"
            $exitCode = $issues
        }
        "advisory" {
            Write-Host "⚠️  Found $issues issue(s) - WARNING (advisory mode)"
            Write-Host ""
            Write-Host "Quality gates flagged issues but not blocking."
            Write-Host ""
            Write-Host "Next steps:"
            Write-Host "  • Review issues listed above"
            Write-Host "  • Address critical issues before merging"
            Write-Host "  • Optional: Re-run /gbm.qa.review-tests after fixes"
            $exitCode = 0  # Don't block in advisory mode
        }
        "disabled" {
            Write-Host "ℹ️  Found $issues issue(s) - INFO ONLY (gates disabled)"
            Write-Host ""
            Write-Host "Quality gates are disabled. Review issues manually."
            $exitCode = 0
        }
        default {
            Write-Host "⚠️  Found $issues issue(s)"
            $exitCode = $issues
        }
    }
}

Write-Host ""
Write-Host "📄 Full report: .gobuildme/specs/qa-test-scaffolding/quality-review.md"
Write-Host "Gate Mode: $($qaConfig.GateMode)"
Write-Host ""

# Exit with appropriate code
exit $exitCode
