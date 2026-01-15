# Purpose : Provide an end-to-end review gate via PowerShell.
# Why     : Aggregates architecture, quality, tests, security, CI, and docs checks on Windows.
# How     : Runs supporting scripts, scores categories, and prints pass/warn/fail output.

# comprehensive-review.ps1 - End-to-end project review
# Performs systematic checks across all project aspects

param(
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: comprehensive-review.ps1 [-Help]"
    Write-Host "Performs comprehensive end-to-end project review"
    exit 0
}

# Initialize review tracking
$reviewScores = @{}
$reviewDetails = @{}
$overallScore = 0
$totalCategories = 6

# Status indicators
$PASS = "🟢"
$WARN = "🟡"
$FAIL = "🔴"

function Write-Header {
    param([string]$Message)
    Write-Host "`n========================================" -ForegroundColor Blue
    Write-Host " $Message" -ForegroundColor Blue
    Write-Host "========================================`n" -ForegroundColor Blue
}

function Write-Category {
    param([string]$Message)
    Write-Host "`n## $Message`n" -ForegroundColor White
}

function Write-Status {
    param(
        [string]$Status,
        [string]$Message
    )

    switch ($Status) {
        "PASS" { Write-Host "$PASS $Message" -ForegroundColor Green }
        "WARN" { Write-Host "$WARN $Message" -ForegroundColor Yellow }
        "FAIL" { Write-Host "$FAIL $Message" -ForegroundColor Red }
        default { Write-Host $Message }
    }
}

function Set-CategoryScore {
    param(
        [string]$Category,
        [int]$Score,
        [string]$Details
    )

    $script:reviewScores[$Category] = $Score
    $script:reviewDetails[$Category] = $Details
    $script:overallScore += $Score
}

# 1. Architecture & Structure Review
function Test-Architecture {
    Write-Category "1. Architecture & Structure"
    $score = 2
    $details = ""

    $scriptDir = Split-Path -Parent $PSScriptRoot
    $bashDir = Join-Path $scriptDir "bash"

    # Run architecture analysis
    $archScript = Join-Path $bashDir "analyze-architecture.sh"
    if (Test-Path $archScript) {
        Write-Status "INFO" "Analyzing architecture..."
        try {
            & bash $archScript *>$null
            $details += "✓ Architecture analysis completed`n"
        }
        catch {
            $details += "⚠ Architecture analysis had issues`n"
            $score = 1
        }
    }

    # Run codebase scan
    $scanScript = Join-Path $bashDir "scan-codebase.sh"
    if (Test-Path $scanScript) {
        Write-Status "INFO" "Scanning codebase structure..."
        try {
            & bash $scanScript *>$null
            $details += "✓ Codebase scan successful`n"
        }
        catch {
            $details += "⚠ Codebase scan encountered issues`n"
            $score = 1
        }
    }

    # Validate architecture boundaries
    $validateScript = Join-Path $bashDir "validate-architecture.sh"
    if (Test-Path $validateScript) {
        Write-Status "INFO" "Validating architecture boundaries..."
        try {
            & bash $validateScript *>$null
            $details += "✓ Architecture boundaries valid`n"
            Write-Status "PASS" "Architecture validation passed"
        }
        catch {
            $details += "✗ Architecture boundary violations detected`n"
            Write-Status "FAIL" "Architecture validation failed"
            $score = 0
        }
    }
    else {
        $details += "- Architecture validation script not found"
        $score = 1
    }

    Set-CategoryScore "architecture" $score $details
}

# 2. Code Quality & Conventions Review
function Test-CodeQuality {
    Write-Category "2. Code Quality & Conventions"
    $score = 2
    $details = ""

    $scriptDir = Split-Path -Parent $PSScriptRoot
    $bashDir = Join-Path $scriptDir "bash"

    # Validate conventions
    $conventionsScript = Join-Path $bashDir "validate-conventions.sh"
    if (Test-Path $conventionsScript) {
        Write-Status "INFO" "Validating code conventions..."
        try {
            & bash $conventionsScript *>$null
            $details += "✓ Code conventions validated`n"
            Write-Status "PASS" "Code conventions check passed"
        }
        catch {
            $details += "✗ Code convention violations found`n"
            Write-Status "FAIL" "Code conventions check failed"
            $score = 0
        }
    }
    else {
        $details += "- Convention validation script not found`n"
        $score = 1
    }

    # Run linting
    $lintScript = Join-Path $bashDir "run-lint.sh"
    if (Test-Path $lintScript) {
        Write-Status "INFO" "Running linting checks..."
        try {
            $lintOutput = & bash $lintScript 2>&1
            if ($LASTEXITCODE -eq 0) {
                $details += "✓ Linting passed`n"
                Write-Status "PASS" "Linting check passed"
            }
            else {
                $errorCount = ($lintOutput | Select-String -Pattern "error|Error|ERROR").Count
                if ($errorCount -gt 0) {
                    $details += "✗ $errorCount linting errors found`n"
                    Write-Status "FAIL" "Linting failed with $errorCount errors"
                    $score = 0
                }
                else {
                    $details += "⚠ Linting warnings present`n"
                    Write-Status "WARN" "Linting passed with warnings"
                    $score = 1
                }
            }
        }
        catch {
            $details += "✗ Linting script execution failed`n"
            $score = 0
        }
    }
    else {
        $details += "- Linting script not found`n"
        $score = 1
    }

    # Type checking
    $typeScript = Join-Path $bashDir "run-type-check.sh"
    if (Test-Path $typeScript) {
        Write-Status "INFO" "Running type checks..."
        try {
            & bash $typeScript *>$null
            $details += "✓ Type checking passed`n"
            Write-Status "PASS" "Type checking passed"
        }
        catch {
            $details += "✗ Type checking errors found`n"
            Write-Status "FAIL" "Type checking failed"
            $score = 0
        }
    }
    else {
        $details += "- Type checking script not found`n"
        $score = 1
    }

    Set-CategoryScore "code_quality" $score $details
}

# 3. Testing & Coverage Review
function Test-Testing {
    Write-Category "3. Testing & Coverage"
    $score = 2
    $details = ""

    $scriptDir = Split-Path -Parent $PSScriptRoot
    $bashDir = Join-Path $scriptDir "bash"
    $testScript = Join-Path $bashDir "run-tests.sh"

    if (Test-Path $testScript) {
        Write-Status "INFO" "Running test suite..."
        try {
            $testOutput = & bash $testScript --json 2>&1
            if ($LASTEXITCODE -eq 0) {
                $details += "✓ All tests passed`n"
                Write-Status "PASS" "Test suite passed"

                # Check for coverage information
                if ($testOutput -match "coverage|Coverage") {
                    $coverageLine = ($testOutput | Select-String -Pattern "coverage|Coverage" | Select-Object -First 1).Line
                    $details += "✓ Coverage: $coverageLine`n"

                    # Extract coverage percentage
                    if ($coverageLine -match '(\d+)%') {
                        $coveragePct = [int]$matches[1]
                        if ($coveragePct -lt 70) {
                            $details += "⚠ Coverage below 70% threshold`n"
                            Write-Status "WARN" "Test coverage below recommended threshold"
                            $score = 1
                        }
                    }
                }
                else {
                    $details += "- No coverage information available`n"
                    $score = 1
                }
            }
            else {
                $failedTests = ($testOutput | Select-String -Pattern "FAILED|failed|FAIL").Count
                $details += "✗ $failedTests test(s) failed`n"
                Write-Status "FAIL" "Test suite failed ($failedTests failures)"
                $score = 0
            }
        }
        catch {
            $details += "✗ Test execution failed`n"
            $score = 0
        }
    }
    else {
        $details += "- Test script not found`n"
        Write-Status "WARN" "No test script available"
        $score = 1
    }

    Set-CategoryScore "testing" $score $details
}

# 4. Security & Compliance Review
function Test-Security {
    Write-Category "4. Security & Compliance"
    $score = 2
    $details = ""

    $scriptDir = Split-Path -Parent $PSScriptRoot
    $bashDir = Join-Path $scriptDir "bash"
    $securityScript = Join-Path $bashDir "security-scan.sh"

    if (Test-Path $securityScript) {
        Write-Status "INFO" "Running security scan..."
        try {
            $securityOutput = & bash $securityScript 2>&1
            if ($LASTEXITCODE -eq 0) {
                $details += "✓ Security scan passed`n"
                Write-Status "PASS" "Security scan passed"
            }
            else {
                $vulnCount = ($securityOutput | Select-String -Pattern "vulnerability|Vulnerability|VULNERABILITY|HIGH|CRITICAL").Count
                if ($vulnCount -gt 0) {
                    $details += "✗ $vulnCount security vulnerabilities found`n"
                    Write-Status "FAIL" "Security vulnerabilities detected"
                    $score = 0
                }
                else {
                    $details += "⚠ Security scan completed with warnings`n"
                    Write-Status "WARN" "Security scan passed with warnings"
                    $score = 1
                }
            }
        }
        catch {
            $details += "✗ Security scan failed`n"
            $score = 0
        }
    }
    else {
        $details += "- Security scan script not found`n"
        $score = 1
    }

    # Check for sensitive files
    Write-Status "INFO" "Checking for sensitive data..."
    $sensitivePatterns = @("password", "secret", "key", "token", "api_key", "private")
    $sensitiveFound = $false

    foreach ($pattern in $sensitivePatterns) {
        $files = Get-ChildItem -Recurse -Include "*.py", "*.js", "*.ts", "*.go", "*.java" -Exclude ".git", "node_modules", ".venv" -ErrorAction SilentlyContinue |
                 Where-Object { (Get-Content $_.FullName -ErrorAction SilentlyContinue) -match $pattern }

        if ($files) {
            $sensitiveFound = $true
            break
        }
    }

    if (-not $sensitiveFound) {
        $details += "✓ No obvious sensitive data in code`n"
    }
    else {
        $details += "⚠ Potential sensitive data found in code files`n"
        $score = 1
    }

    Set-CategoryScore "security" $score $details
}

# 5. CI/CD & Deployment Review
function Test-CICD {
    Write-Category "5. CI/CD & Deployment"
    $score = 2
    $details = ""

    $scriptDir = Split-Path -Parent $PSScriptRoot
    $bashDir = Join-Path $scriptDir "bash"

    # Check branch status
    $branchScript = Join-Path $bashDir "branch-status.sh"
    if (Test-Path $branchScript) {
        Write-Status "INFO" "Checking branch status..."
        try {
            & bash $branchScript *>$null
            $details += "✓ Branch status clean`n"
            Write-Status "PASS" "Branch status check passed"
        }
        catch {
            $details += "⚠ Branch status issues detected`n"
            Write-Status "WARN" "Branch status check has warnings"
            $score = 1
        }
    }

    # Check CI workflows
    if (Test-Path ".github/workflows") {
        $workflowCount = (Get-ChildItem ".github/workflows" -Filter "*.yml" -ErrorAction SilentlyContinue).Count +
                        (Get-ChildItem ".github/workflows" -Filter "*.yaml" -ErrorAction SilentlyContinue).Count

        if ($workflowCount -gt 0) {
            $details += "✓ $workflowCount CI workflow(s) found`n"
            Write-Status "PASS" "CI workflows present"
        }
        else {
            $details += "- No CI workflows found`n"
            $score = 1
        }
    }
    else {
        $details += "- No .github/workflows directory`n"
        $score = 1
    }

    # Ready to push check
    $readyScript = Join-Path $bashDir "ready-to-push.sh"
    if (Test-Path $readyScript) {
        Write-Status "INFO" "Checking deployment readiness..."
        try {
            & bash $readyScript *>$null
            $details += "✓ Ready for deployment`n"
            Write-Status "PASS" "Deployment readiness check passed"
        }
        catch {
            $details += "✗ Not ready for deployment`n"
            Write-Status "FAIL" "Deployment readiness check failed"
            $score = 0
        }
    }
    else {
        $details += "- Ready-to-push script not found`n"
        $score = 1
    }

    Set-CategoryScore "cicd" $score $details
}

# 6. Documentation & Maintenance Review
function Test-Documentation {
    Write-Category "6. Documentation & Maintenance"
    $score = 2
    $details = ""

    # Check for essential documentation
    $essentialDocs = @("README.md", "CONTRIBUTING.md", "CHANGELOG.md")
    $missingDocs = @()

    foreach ($doc in $essentialDocs) {
        if (Test-Path $doc) {
            $details += "✓ $doc present`n"
        }
        else {
            $missingDocs += $doc
        }
    }

    if ($missingDocs.Count -eq 0) {
        Write-Status "PASS" "Essential documentation present"
    }
    elseif ($missingDocs.Count -le 1) {
        $details += "⚠ Missing: $($missingDocs -join ', ')`n"
        Write-Status "WARN" "Some documentation missing"
        $score = 1
    }
    else {
        $details += "✗ Missing: $($missingDocs -join ', ')`n"
        Write-Status "FAIL" "Critical documentation missing"
        $score = 0
    }

    # Check for code organization documentation
    if ((Test-Path "docs/ARCHITECTURE.md") -or (Test-Path "ARCHITECTURE.md")) {
        $details += "✓ Architecture documentation found`n"
    }
    else {
        $details += "- No architecture documentation`n"
        $score = 1
    }

    # Check git history health
    try {
        $commitCount = (git rev-list --count HEAD 2>$null) -as [int]
        if ($commitCount -gt 1) {
            $details += "✓ $commitCount commits in history`n"
        }
        else {
            $details += "⚠ Limited git history`n"
            $score = 1
        }
    }
    catch {
        $details += "⚠ Unable to check git history`n"
        $score = 1
    }

    Set-CategoryScore "documentation" $score $details
}

# Generate comprehensive report
function Write-Report {
    Write-Header "COMPREHENSIVE PROJECT REVIEW REPORT"

    # Calculate overall health score
    $maxScore = $totalCategories * 2
    $healthPercentage = [math]::Round(($overallScore * 100) / $maxScore)

    Write-Host "Overall Project Health: $healthPercentage% ($overallScore/$maxScore)`n" -ForegroundColor White

    # Health status
    if ($healthPercentage -ge 90) {
        Write-Host "$PASS EXCELLENT - Project is in excellent condition" -ForegroundColor Green
    }
    elseif ($healthPercentage -ge 75) {
        Write-Host "$WARN GOOD - Project is in good condition with minor issues" -ForegroundColor Yellow
    }
    elseif ($healthPercentage -ge 60) {
        Write-Host "$WARN FAIR - Project needs attention in several areas" -ForegroundColor Yellow
    }
    else {
        Write-Host "$FAIL POOR - Project has significant issues requiring immediate attention" -ForegroundColor Red
    }

    Write-Host "`nCategory Breakdown:`n" -ForegroundColor White

    # Display category results
    $categories = @("architecture", "code_quality", "testing", "security", "cicd", "documentation")
    $categoryNames = @("Architecture & Structure", "Code Quality & Conventions", "Testing & Coverage",
                      "Security & Compliance", "CI/CD & Deployment", "Documentation & Maintenance")

    for ($i = 0; $i -lt $categories.Count; $i++) {
        $cat = $categories[$i]
        $name = $categoryNames[$i]
        $score = $reviewScores[$cat]
        $details = $reviewDetails[$cat]

        Write-Host "$name:" -ForegroundColor White
        switch ($score) {
            2 { Write-Host "  $PASS PASS" -ForegroundColor Green }
            1 { Write-Host "  $WARN WARNING" -ForegroundColor Yellow }
            0 { Write-Host "  $FAIL FAIL" -ForegroundColor Red }
        }

        $details -split "`n" | ForEach-Object {
            if ($_.Trim()) { Write-Host "  $_" }
        }
        Write-Host ""
    }

    # Blocking issues
    $blockingIssues = ($reviewScores.Values | Where-Object { $_ -eq 0 }).Count

    if ($blockingIssues -gt 0) {
        Write-Host "⚠ BLOCKING ISSUES DETECTED ($blockingIssues)" -ForegroundColor Red
        Write-Host "The following categories have critical issues that must be resolved:" -ForegroundColor Red

        for ($i = 0; $i -lt $categories.Count; $i++) {
            $cat = $categories[$i]
            $name = $categoryNames[$i]
            if ($reviewScores[$cat] -eq 0) {
                Write-Host "  $FAIL $name" -ForegroundColor Red
            }
        }
        Write-Host ""
    }

    # Recommendations
    Write-Host "Next Steps:" -ForegroundColor White
    if ($blockingIssues -gt 0) {
        Write-Host "1. $FAIL Address all blocking issues immediately"
        Write-Host "2. Re-run review after fixes"
        Write-Host "3. Once all issues resolved, run /ready-to-push"
    }
    elseif ($healthPercentage -ge 90) {
        Write-Host "1. $PASS Project ready for deployment"
        Write-Host "2. Consider running /ready-to-push for final validation"
        Write-Host "3. Optional: Run /gbm.preflight for additional verification"
    }
    else {
        Write-Host "1. $WARN Address warning-level issues in next sprint"
        Write-Host "2. Run /ready-to-push to check deployment readiness"
        Write-Host "3. Consider implementing automated quality gates"
    }

    Write-Host ""
    return $blockingIssues
}

# Main execution
function Main {
    Write-Header "Starting Comprehensive Project Review"

    # Run all review categories
    Test-Architecture
    Test-CodeQuality
    Test-Testing
    Test-Security
    Test-CICD
    Test-Documentation

    # Generate final report
    $blockingIssues = Write-Report

    # Exit with appropriate code
    if ($blockingIssues -gt 0) {
        exit 1
    }
    else {
        exit 0
    }
}

# Execute main function
Main