#!/usr/bin/env pwsh
# Purpose: Generate task checklist from test implementation plan
# Why: Breaks down plan into actionable tasks with checkboxes
# How: Scans test files for TODO tests, creates task for each with checkbox

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
$PLAN_FILE = "$SCAFFOLD_DIR/qa-test-plan.md"
$TASKS_TEMPLATE = ".gobuildme/templates/qa-test-tasks-template.md"
$TASKS_FILE = "$SCAFFOLD_DIR/qa-test-tasks.md"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Helpers
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Get current repo root for path normalization
$REPO_ROOT = (Get-Location).Path

function Get-RepoRelativePath {
    param([string]$AbsolutePath)

    # Convert absolute path to repo-relative path
    if ($AbsolutePath.StartsWith($REPO_ROOT)) {
        $relativePath = $AbsolutePath.Substring($REPO_ROOT.Length)
        # Remove leading slash or backslash
        if ($relativePath.StartsWith([System.IO.Path]::DirectorySeparatorChar) -or $relativePath.StartsWith('/') -or $relativePath.StartsWith('\')) {
            $relativePath = $relativePath.Substring(1)
        }
        # Normalize to forward slashes for cross-platform consistency
        return $relativePath -replace '\\', '/'
    }
    # If not under repo root, return as-is (shouldn't happen)
    return $AbsolutePath -replace '\\', '/'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Test-Prerequisites {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "🚀 QA Test Task Generation" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""

    # Check for plan file
    if (-not (Test-Path $PLAN_FILE)) {
        Write-Host "❌ Error: Test implementation plan not found" -ForegroundColor Red
        Write-Host ""
        Write-Host "Expected location: $PLAN_FILE"
        Write-Host ""
        Write-Host "Action required: Run /gbm.qa.plan first to create test implementation plan"
        Write-Host ""
        exit 1
    }

    # Check for tasks template
    if (-not (Test-Path $TASKS_TEMPLATE)) {
        Write-Host "❌ Error: Tasks template not found" -ForegroundColor Red
        Write-Host ""
        Write-Host "Expected location: $TASKS_TEMPLATE"
        Write-Host ""
        Write-Host "Action required: Ensure GoBuildMe is properly installed"
        Write-Host ""
        exit 1
    }

    Write-Host "✓ Prerequisites check passed" -ForegroundColor Green
    Write-Host ""
}

function Get-TestFiles {
    Write-Host "📂 Extracting test files from plan..." -ForegroundColor Yellow
    Write-Host ""

    # Find test directories
    $testDirs = @("tests", "test", "spec", "__tests__")
    $testFiles = @()

    foreach ($dir in $testDirs) {
        if (Test-Path $dir) {
            # Find test files
            $testFiles += Get-ChildItem -Path $dir -Recurse -Include "*Test.php","test_*.py","*.test.js","*.test.ts","*Test.java" -File
        }
    }

    Write-Host "   Found $($testFiles.Count) test files" -ForegroundColor Cyan
    Write-Host ""

    return $testFiles
}

function Get-TodoTests {
    param([array]$TestFiles)

    Write-Host "🔍 Parsing TODO tests from test files..." -ForegroundColor Yellow
    Write-Host ""

    $totalTasks = 0
    $highPriorityTasks = 0
    $mediumPriorityTasks = 0
    $lowPriorityTasks = 0
    $todoTestDetails = @()  # Array of objects with file, line, name, priority

    # Handle empty array safely
    if ($TestFiles.Count -eq 0) {
        Write-Host "   No test files found to parse" -ForegroundColor Yellow
        Write-Host ""
        return @{
            Total = 0
            High = 0
            Medium = 0
            Low = 0
            Details = @()
        }
    }

    foreach ($testFile in $TestFiles) {
        # Convert to repo-relative path for consistent output
        $relativeFilePath = Get-RepoRelativePath -AbsolutePath $testFile.FullName

        # Determine priority based on file path
        $priority = "low"
        if ($relativeFilePath -match "api|auth|security") {
            $priority = "high"
        } elseif ($relativeFilePath -match "integration|database") {
            $priority = "medium"
        }

        # Find TODO/skip test patterns with line numbers
        $matches = Select-String -Path $testFile.FullName -Pattern "(public function test|def test_|it\(|test\()" -AllMatches

        foreach ($match in $matches) {
            $lineNum = $match.LineNumber

            # Check if this test has TODO/skip marker (within next 10 lines or previous 5 lines)
            $content = Get-Content $testFile.FullName
            $startLine = [Math]::Max(0, $lineNum - 6)
            $endLine = [Math]::Min($content.Count - 1, $lineNum + 9)
            $contextLines = $content[$startLine..$endLine] -join "`n"

            if ($contextLines -match "TODO|@skip|pytest\.skip|markTestSkipped|\.skip\(") {
                # Extract test name
                $testName = "unnamed_test"
                if ($match.Line -match "function (test\w+)") {
                    $testName = $Matches[1]
                } elseif ($match.Line -match "def (test_\w+)") {
                    $testName = $Matches[1]
                } elseif ($match.Line -match "(it|test)\([`"']([^`"']+)") {
                    $testName = $Matches[2]
                }

                $todoTestDetails += @{
                    File = $relativeFilePath  # Use repo-relative path
                    Line = $lineNum
                    Name = $testName
                    Priority = $priority
                }

                $totalTasks++
                switch ($priority) {
                    "high" { $highPriorityTasks++ }
                    "medium" { $mediumPriorityTasks++ }
                    default { $lowPriorityTasks++ }
                }
            }
        }
    }

    Write-Host "   Total TODO tests found: $totalTasks" -ForegroundColor Cyan
    Write-Host "   High priority: $highPriorityTasks" -ForegroundColor Cyan
    Write-Host "   Medium priority: $mediumPriorityTasks" -ForegroundColor Cyan
    Write-Host "   Low priority: $lowPriorityTasks" -ForegroundColor Cyan
    Write-Host ""

    return @{
        Total = $totalTasks
        High = $highPriorityTasks
        Medium = $mediumPriorityTasks
        Low = $lowPriorityTasks
        Details = $todoTestDetails
    }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Coverage Gap Analysis (CRITICAL for #31/#32)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Get-CoverageGaps {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "🔍 Analyzing Coverage Gaps (Production Code Without Tests)" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""

    # Source directories to scan
    $sourceDirs = @("src", "app", "lib", "pkg", "internal", "cmd")
    $sourceFiles = @()

    foreach ($dir in $sourceDirs) {
        if (Test-Path $dir) {
            # Find source files (PHP, Python, JavaScript, TypeScript, Go, Java)
            $sourceFiles += Get-ChildItem -Path $dir -Recurse -Include "*.php","*.py","*.js","*.ts","*.go","*.java","*.rb" -File |
                Where-Object { $_.Name -notmatch "_test\.|test_|\.test\.|Test\." }
        }
    }

    Write-Host "   Found $($sourceFiles.Count) source files to analyze" -ForegroundColor Cyan
    Write-Host ""

    if ($sourceFiles.Count -eq 0) {
        Write-Host "   No source files found in common directories (src/, app/, lib/, etc.)" -ForegroundColor Yellow
        Write-Host ""
        return @{
            Total = 0
            High = 0
            Medium = 0
            Low = 0
            UntestedFiles = @()
        }
    }

    $untestedCount = 0
    $highPriorityGap = 0
    $mediumPriorityGap = 0
    $lowPriorityGap = 0
    $untestedFiles = @()

    foreach ($sourceFile in $sourceFiles) {
        $baseName = $sourceFile.BaseName
        $ext = $sourceFile.Extension

        $hasTest = $false

        # Check common test naming patterns across all test directories
        $testDirsToCheck = @("tests", "test", "spec", "__tests__")

        switch ($ext) {
            ".php" {
                # PHP: UserController.php -> UserControllerTest.php
                foreach ($testDir in $testDirsToCheck) {
                    if ((Test-Path $testDir -PathType Container) -and -not $hasTest) {
                        $hasTest = (Get-ChildItem -Path $testDir -Recurse -Filter "${baseName}Test.php" -ErrorAction SilentlyContinue).Count -gt 0
                    }
                }
            }
            ".py" {
                # Python: user_service.py -> test_user_service.py
                foreach ($testDir in $testDirsToCheck) {
                    if ((Test-Path $testDir -PathType Container) -and -not $hasTest) {
                        $hasTest = (Get-ChildItem -Path $testDir -Recurse -Filter "test_${baseName}.py" -ErrorAction SilentlyContinue).Count -gt 0
                    }
                }
            }
            { $_ -in ".js", ".ts" } {
                # JavaScript/TypeScript: UserService.js -> UserService.test.js or UserService.spec.js
                foreach ($testDir in $testDirsToCheck) {
                    if ((Test-Path $testDir -PathType Container) -and -not $hasTest) {
                        $hasTest = (Get-ChildItem -Path $testDir -Recurse -Filter "${baseName}.test.*" -ErrorAction SilentlyContinue).Count -gt 0
                        if (-not $hasTest) {
                            $hasTest = (Get-ChildItem -Path $testDir -Recurse -Filter "${baseName}.spec.*" -ErrorAction SilentlyContinue).Count -gt 0
                        }
                    }
                }
            }
            ".go" {
                # Go: user.go -> user_test.go (same directory)
                $testFile = Join-Path $sourceFile.DirectoryName "${baseName}_test.go"
                $hasTest = Test-Path $testFile
            }
            ".java" {
                # Java: UserService.java -> UserServiceTest.java
                $hasTest = (Get-ChildItem -Path . -Recurse -Filter "${baseName}Test.java" -ErrorAction SilentlyContinue |
                    Where-Object { $_.FullName -match "test" }).Count -gt 0
            }
        }

        # If no test found, add to coverage gaps
        if (-not $hasTest) {
            # Convert to repo-relative path for consistent output
            $relativeFilePath = Get-RepoRelativePath -AbsolutePath $sourceFile.FullName
            $untestedFiles += $relativeFilePath
            $untestedCount++

            # Assign priority based on file path/name
            if ($relativeFilePath -match "auth|security|payment|Controller|Service") {
                $highPriorityGap++
            } elseif ($relativeFilePath -match "api|model|repository") {
                $mediumPriorityGap++
            } else {
                $lowPriorityGap++
            }
        }
    }

    Write-Host "   Coverage Gap Analysis Results:" -ForegroundColor Cyan
    Write-Host "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "   Source files without tests: $untestedCount"
    Write-Host "   - High priority gaps: $highPriorityGap (auth, security, controllers, services)"
    Write-Host "   - Medium priority gaps: $mediumPriorityGap (api, models, repositories)"
    Write-Host "   - Low priority gaps: $lowPriorityGap (other files)"
    Write-Host ""

    if ($untestedCount -gt 0) {
        Write-Host "   Top 10 untested files (by priority):" -ForegroundColor Yellow
        $untestedFiles | Select-Object -First 10 | ForEach-Object { Write-Host "   - $_" }
        if ($untestedFiles.Count -gt 10) {
            Write-Host "   ... and $($untestedFiles.Count - 10) more"
        }
        Write-Host ""
    }

    return @{
        Total = $untestedCount
        High = $highPriorityGap
        Medium = $mediumPriorityGap
        Low = $lowPriorityGap
        UntestedFiles = $untestedFiles
    }
}

# Test directories to search (supports tests/, test/, spec/, __tests__/)
$TEST_DIRS = @("tests", "test", "spec", "__tests__")

function Get-SuggestedTestPath {
    param(
        [string]$SourceFile,
        [string]$Extension
    )

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($SourceFile)

    # Determine test directory (prefer first existing one)
    $testDir = "tests"
    foreach ($dir in $TEST_DIRS) {
        if (Test-Path $dir) {
            $testDir = $dir
            break
        }
    }

    switch ($Extension) {
        ".php" { return "$testDir/Unit/${baseName}Test.php" }
        ".py" { return "$testDir/test_${baseName}.py" }
        ".js" { return "$testDir/${baseName}.test.js" }
        ".ts" { return "$testDir/${baseName}.test.ts" }
        ".go" {
            $dirName = [System.IO.Path]::GetDirectoryName($SourceFile)
            return "$dirName/${baseName}_test.go"
        }
        ".java" { return "$testDir/java/${baseName}Test.java" }
        ".rb" { return "$testDir/${baseName}_spec.rb" }
        default { return "$testDir/${baseName}_test$Extension" }
    }
}

function New-TasksFile {
    param(
        [hashtable]$TaskCounts,
        [hashtable]$CoverageGaps,
        [array]$TodoTestDetails
    )

    Write-Host "📝 Generating task checklist..." -ForegroundColor Yellow
    Write-Host ""

    # Create scaffold directory if it doesn't exist
    if (-not (Test-Path $SCAFFOLD_DIR)) {
        New-Item -ItemType Directory -Path $SCAFFOLD_DIR | Out-Null
    }

    # Copy template
    Copy-Item $TASKS_TEMPLATE $TASKS_FILE -Force

    # Replace placeholders
    $content = Get-Content $TASKS_FILE -Raw
    $content = $content -replace '\[PROJECT/FEATURE\]', 'Project-wide Test Implementation'
    $content = $content -replace '\{TOTAL_TASKS\}', $TaskCounts.Total
    $content = $content -replace 'High-priority tests: \{N\} tasks', "High-priority tests: $($TaskCounts.High) tasks"
    $content = $content -replace 'Medium-priority tests: \{N\} tasks', "Medium-priority tests: $($TaskCounts.Medium) tasks"
    $content = $content -replace 'Low-priority tests: \{N\} tasks', "Low-priority tests: $($TaskCounts.Low) tasks"

    # Save updated content
    $content | Set-Content $TASKS_FILE -NoNewline

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # CRITICAL: Write TODO/placeholder test tasks (#31/#32)
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    if ($TodoTestDetails -and $TodoTestDetails.Count -gt 0) {
        $todoContent = @"

---

## TODO/Placeholder Test Tasks (Auto-Generated)

**Purpose**: Complete implementation of tests marked with TODO, pytest.skip, or similar placeholders.

**Total TODO Test Tasks**: $($TodoTestDetails.Count)

"@
        Add-Content -Path $TASKS_FILE -Value $todoContent

        $taskId = 1  # TODO test IDs start at 1

        # High priority section
        Add-Content -Path $TASKS_FILE -Value "### High Priority TODO Tests (Security, Auth, API)`n"
        $highTodos = $TodoTestDetails | Where-Object { $_.Priority -eq "high" }
        if ($highTodos.Count -eq 0) {
            Add-Content -Path $TASKS_FILE -Value "_No high priority TODO tests detected._`n"
        } else {
            foreach ($todo in $highTodos) {
                $taskEntry = @"
- [ ] $taskId [P] Implement test: ``$($todo.Name)``
  - **Location**: ``$($todo.File):$($todo.Line)``
  - **Must verify before marking [x]**:
    - ✓ TODO/skip marker removed
    - ✓ Test logic fully implemented
    - ✓ Uses AAA pattern (Arrange, Act, Assert)
    - ✓ Test passes

"@
                Add-Content -Path $TASKS_FILE -Value $taskEntry
                $taskId++
            }
        }

        # Medium priority section
        Add-Content -Path $TASKS_FILE -Value "### Medium Priority TODO Tests (Integration, Database)`n"
        $mediumTodos = $TodoTestDetails | Where-Object { $_.Priority -eq "medium" }
        if ($mediumTodos.Count -eq 0) {
            Add-Content -Path $TASKS_FILE -Value "_No medium priority TODO tests detected._`n"
        } else {
            foreach ($todo in $mediumTodos) {
                $taskEntry = @"
- [ ] $taskId [P] Implement test: ``$($todo.Name)``
  - **Location**: ``$($todo.File):$($todo.Line)``
  - **Must verify before marking [x]**:
    - ✓ TODO/skip marker removed
    - ✓ Test logic fully implemented
    - ✓ Uses AAA pattern (Arrange, Act, Assert)
    - ✓ Test passes

"@
                Add-Content -Path $TASKS_FILE -Value $taskEntry
                $taskId++
            }
        }

        # Low priority section
        Add-Content -Path $TASKS_FILE -Value "### Low Priority TODO Tests (Unit, Other)`n"
        $lowTodos = $TodoTestDetails | Where-Object { $_.Priority -eq "low" }
        if ($lowTodos.Count -eq 0) {
            Add-Content -Path $TASKS_FILE -Value "_No low priority TODO tests detected._`n"
        } else {
            foreach ($todo in $lowTodos) {
                $taskEntry = @"
- [ ] $taskId [P] Implement test: ``$($todo.Name)``
  - **Location**: ``$($todo.File):$($todo.Line)``
  - **Must verify before marking [x]**:
    - ✓ TODO/skip marker removed
    - ✓ Test logic fully implemented
    - ✓ Uses AAA pattern (Arrange, Act, Assert)
    - ✓ Test passes

"@
                Add-Content -Path $TASKS_FILE -Value $taskEntry
                $taskId++
            }
        }
    }

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # CRITICAL: Write coverage gap tasks to the file (#31/#32)
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    if ($CoverageGaps -and $CoverageGaps.UntestedFiles -and $CoverageGaps.UntestedFiles.Count -gt 0) {
        $taskContent = @"

---

## Coverage Gap Tasks (Auto-Generated)

**Purpose**: Create tests for production code files that have no corresponding test files.

**Total Coverage Gap Tasks**: $($CoverageGaps.UntestedFiles.Count)

"@
        Add-Content -Path $TASKS_FILE -Value $taskContent

        $taskId = 100  # Start coverage gap IDs at 100 to avoid conflicts

        # Categorize untested files by priority
        $highFiles = @()
        $mediumFiles = @()
        $lowFiles = @()

        foreach ($file in $CoverageGaps.UntestedFiles) {
            if ($file -match "auth|security|payment|Controller|Service") {
                $highFiles += $file
            } elseif ($file -match "api|model|repository") {
                $mediumFiles += $file
            } else {
                $lowFiles += $file
            }
        }

        # High priority section
        Add-Content -Path $TASKS_FILE -Value "### High Priority Coverage Gaps (Security, Auth, Controllers, Services)`n"
        if ($highFiles.Count -eq 0) {
            Add-Content -Path $TASKS_FILE -Value "_No high priority coverage gaps detected._`n"
        } else {
            foreach ($file in $highFiles) {
                $ext = [System.IO.Path]::GetExtension($file)
                $testPath = Get-SuggestedTestPath -SourceFile $file -Extension $ext
                $taskEntry = @"
- [ ] $taskId [P] Create test file for ``$file``
  - **Source**: ``$file``
  - **Create test at**: ``$testPath``
  - **Must verify before marking [x]**:
    - ✓ Test file created at suggested location
    - ✓ Tests cover primary public methods/functions
    - ✓ Uses AAA pattern (Arrange, Act, Assert)
    - ✓ All tests pass

"@
                Add-Content -Path $TASKS_FILE -Value $taskEntry
                $taskId++
            }
        }

        # Medium priority section
        Add-Content -Path $TASKS_FILE -Value "### Medium Priority Coverage Gaps (API, Models, Repositories)`n"
        if ($mediumFiles.Count -eq 0) {
            Add-Content -Path $TASKS_FILE -Value "_No medium priority coverage gaps detected._`n"
        } else {
            foreach ($file in $mediumFiles) {
                $ext = [System.IO.Path]::GetExtension($file)
                $testPath = Get-SuggestedTestPath -SourceFile $file -Extension $ext
                $taskEntry = @"
- [ ] $taskId [P] Create test file for ``$file``
  - **Source**: ``$file``
  - **Create test at**: ``$testPath``
  - **Must verify before marking [x]**:
    - ✓ Test file created at suggested location
    - ✓ Tests cover primary public methods/functions
    - ✓ Uses AAA pattern (Arrange, Act, Assert)
    - ✓ All tests pass

"@
                Add-Content -Path $TASKS_FILE -Value $taskEntry
                $taskId++
            }
        }

        # Low priority section
        Add-Content -Path $TASKS_FILE -Value "### Low Priority Coverage Gaps (Other Files)`n"
        if ($lowFiles.Count -eq 0) {
            Add-Content -Path $TASKS_FILE -Value "_No low priority coverage gaps detected._`n"
        } else {
            foreach ($file in $lowFiles) {
                $ext = [System.IO.Path]::GetExtension($file)
                $testPath = Get-SuggestedTestPath -SourceFile $file -Extension $ext
                $taskEntry = @"
- [ ] $taskId [P] Create test file for ``$file``
  - **Source**: ``$file``
  - **Create test at**: ``$testPath``
  - **Must verify before marking [x]**:
    - ✓ Test file created at suggested location
    - ✓ Tests cover primary public methods/functions
    - ✓ Uses AAA pattern (Arrange, Act, Assert)
    - ✓ All tests pass

"@
                Add-Content -Path $TASKS_FILE -Value $taskEntry
                $taskId++
            }
        }
    }

    Write-Host "   ✓ Task checklist generated: $TASKS_FILE" -ForegroundColor Green
    if ($TodoTestDetails -and $TodoTestDetails.Count -gt 0) {
        Write-Host "   ✓ Added $($TodoTestDetails.Count) TODO/placeholder test tasks with locations" -ForegroundColor Green
    }
    if ($CoverageGaps -and $CoverageGaps.UntestedFiles -and $CoverageGaps.UntestedFiles.Count -gt 0) {
        Write-Host "   ✓ Added $($CoverageGaps.UntestedFiles.Count) coverage gap tasks with file paths and IDs" -ForegroundColor Green
    }
    Write-Host ""
}

function Show-Summary {
    param([hashtable]$TaskCounts)

    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "✅ QA Test Task Checklist Created" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📋 Task Breakdown"
    Write-Host "   Total tasks: $($TaskCounts.Total)"
    Write-Host ""
    Write-Host "   By Source:"
    $todoTasks = if ($TaskCounts.ContainsKey('TodoTasks')) { $TaskCounts.TodoTasks } else { $TaskCounts.Total }
    $coverageGapTasks = if ($TaskCounts.ContainsKey('CoverageGapTasks')) { $TaskCounts.CoverageGapTasks } else { 0 }
    Write-Host "   - TODO/placeholder tests: $todoTasks tasks"
    Write-Host "   - Coverage gap tests (NEW): $coverageGapTasks tasks"
    Write-Host ""
    Write-Host "   By Phase:"
    Write-Host "   - Phase 1 (Fixtures): Optional (run /gbm.qa.generate-fixtures)"
    Write-Host "   - Phase 2 (High Priority): $($TaskCounts.High) tasks"
    Write-Host "   - Phase 3 (Medium Priority): $($TaskCounts.Medium) tasks"
    Write-Host "   - Phase 4 (Low Priority): $($TaskCounts.Low) tasks"
    Write-Host "   - Phase 5 (Validation): 3 tasks"
    Write-Host ""
    Write-Host "   By Priority:"
    Write-Host "   - High-priority tests: $($TaskCounts.High) tasks"
    Write-Host "   - Medium-priority tests: $($TaskCounts.Medium) tasks"
    Write-Host "   - Low-priority tests: $($TaskCounts.Low) tasks"
    Write-Host ""
    if ($coverageGapTasks -gt 0) {
        Write-Host "⚠️  Coverage Gap Alert" -ForegroundColor Yellow
        Write-Host "   Found $coverageGapTasks source files without corresponding tests."
        Write-Host "   These tasks ensure comprehensive coverage beyond existing placeholders."
        Write-Host ""
    }
    Write-Host "📁 Tasks Location"
    Write-Host "   $TASKS_FILE"
    Write-Host ""
    Write-Host "🎯 Next Steps"
    Write-Host "   1. Review task checklist: $TASKS_FILE"
    Write-Host "   2. Optionally generate fixtures: /gbm.qa.generate-fixtures (recommended)"
    Write-Host "   3. Start implementation: /gbm.qa.implement (systematic task-by-task)"
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

# 3. Extract test files
$testFiles = Get-TestFiles

# 4. Parse TODO tests (existing placeholders)
$taskCounts = Get-TodoTests -TestFiles $testFiles

# 5. CRITICAL: Analyze coverage gaps (source files without tests)
# This addresses #31/#32 - comprehensive testing, not just TODO markers
$coverageGaps = Get-CoverageGaps

# Combine task counts
$combinedCounts = @{
    Total = $taskCounts.Total + $coverageGaps.Total
    High = $taskCounts.High + $coverageGaps.High
    Medium = $taskCounts.Medium + $coverageGaps.Medium
    Low = $taskCounts.Low + $coverageGaps.Low
    TodoTasks = $taskCounts.Total
    CoverageGapTasks = $coverageGaps.Total
}

# 6. Generate tasks file with TODO tests and coverage gaps
New-TasksFile -TaskCounts $combinedCounts -CoverageGaps $coverageGaps -TodoTestDetails $taskCounts.Details

# 7. Display summary
Show-Summary -TaskCounts $combinedCounts
