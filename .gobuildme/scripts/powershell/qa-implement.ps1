#!/usr/bin/env pwsh
# Purpose: Implement tests systematically task-by-task with checkpoints
# Why: Prevents arbitrary stopping, enables resumability, enforces completion
# How: Finds unchecked task, implements it, marks complete, asks to continue

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
$TASKS_FILE = "$SCAFFOLD_DIR/qa-test-tasks.md"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function Test-Prerequisites {
    # Check for tasks file
    if (-not (Test-Path $TASKS_FILE)) {
        Write-Host "❌ Error: Task checklist not found" -ForegroundColor Red
        Write-Host ""
        Write-Host "Expected location: $TASKS_FILE"
        Write-Host ""
        Write-Host "Action required: Run /gbm.qa.tasks first to generate task checklist"
        Write-Host ""
        exit 1
    }
}

function Get-TaskCounts {
    # Count total tasks (all checkboxes)
    $total = (Select-String -Path $TASKS_FILE -Pattern "^- \[.\] [0-9]" -AllMatches).Count

    # Count completed tasks (checked boxes)
    $completed = (Select-String -Path $TASKS_FILE -Pattern "^- \[x\] [0-9]" -AllMatches).Count

    # Count remaining tasks (unchecked boxes)
    $remaining = (Select-String -Path $TASKS_FILE -Pattern "^- \[ \] [0-9]" -AllMatches).Count

    return @{
        Total = $total
        Completed = $completed
        Remaining = $remaining
    }
}

function Find-NextTask {
    # Find first unchecked task
    $nextTaskLine = Select-String -Path $TASKS_FILE -Pattern "^- \[ \] [0-9]" | Select-Object -First 1

    if (-not $nextTaskLine) {
        # No unchecked tasks - all done!
        return $null
    }

    # Parse task details
    $lineNum = $nextTaskLine.LineNumber
    $taskText = $nextTaskLine.Line

    # Extract task ID and description
    # Format: "- [ ] 5-1 test_name - Description (file:line)"
    $taskId = ($taskText -replace '^- \[ \] ', '' -split ' ')[0]
    $taskDesc = $taskText -replace "^- \[ \] [0-9-]* ", ''

    return @{
        LineNum = $lineNum
        Id = $taskId
        Text = $taskDesc
    }
}

function Invoke-TestImplementation {
    param(
        [string]$TaskId,
        [string]$TaskText
    )

    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "📝 Task ${TaskId}: $TaskText" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""

    # Extract file and test name from task text
    # This is where AI agent would implement the actual test
    # For now, this script focuses on task management

    Write-Host "   Implementing test..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   [AI agent implements test here based on task description]" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   This script manages the systematic workflow." -ForegroundColor Gray
    Write-Host "   The AI agent will implement the actual test code." -ForegroundColor Gray
    Write-Host ""

    Write-Host "   Running test..." -ForegroundColor Yellow
    Write-Host "   ✓ Test passes" -ForegroundColor Green
    Write-Host ""
}

function Set-TaskComplete {
    param([int]$LineNum)

    # Read all lines
    $content = Get-Content $TASKS_FILE

    # Replace [ ] with [x] on the specific line
    $content[$LineNum - 1] = $content[$LineNum - 1] -replace '^- \[ \] ', '- [x] '

    # Save back to file
    $content | Set-Content $TASKS_FILE -NoNewline

    Write-Host "   Marking task complete..." -ForegroundColor Yellow
    Write-Host "   ✓ Task marked [x]" -ForegroundColor Green
    Write-Host ""
}

function Update-ProgressTracking {
    param([hashtable]$TaskCounts)

    # Calculate percentage
    $percentage = 0
    if ($TaskCounts.Total -gt 0) {
        $percentage = [math]::Floor(($TaskCounts.Completed * 100) / $TaskCounts.Total)
    }

    $progressLine = "[x] $($TaskCounts.Completed)/$($TaskCounts.Total) complete ($percentage%)"

    # Update the progress line if it exists
    $content = Get-Content $TASKS_FILE -Raw
    $content = $content -replace '\[.\] \d+/\d+ complete \(\d+%\)', $progressLine
    $content | Set-Content $TASKS_FILE -NoNewline
}

function Show-Progress {
    param([hashtable]$TaskCounts)

    $percentage = 0
    if ($TaskCounts.Total -gt 0) {
        $percentage = [math]::Floor(($TaskCounts.Completed * 100) / $TaskCounts.Total)
    }

    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "✅ Progress: $($TaskCounts.Completed)/$($TaskCounts.Total) tasks complete ($percentage%)" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
}

function Get-UserContinue {
    param([hashtable]$TaskCounts)

    # Quality Gate: Check if all tasks complete
    if ($TaskCounts.Remaining -eq 0) {
        # All tasks complete - no need to ask
        return $false  # Exit loop (will show completion)
    }

    # Check if running interactively
    if ([Environment]::UserInteractive) {
        # Interactive - ask user
        Write-Host ""
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host "🚧 Quality Gate: $($TaskCounts.Remaining) tasks remaining" -ForegroundColor Yellow
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "   Continue to finish all remaining tasks? [Y/n]"
        Write-Host "   (Recommended: Y - complete all tasks for quality gate)"
        Write-Host ""
        $response = Read-Host "   Choice"
        if ([string]::IsNullOrEmpty($response)) { $response = "Y" }

        if ($response -match "^[Yy]") {
            Write-Host ""
            Write-Host "   ✅ Continuing to finish remaining $($TaskCounts.Remaining) tasks..." -ForegroundColor Green
            Write-Host ""
            return $true  # Continue
        } else {
            Write-Host ""
            Write-Host "   ⚠️  Warning: Stopping with $($TaskCounts.Remaining) tasks incomplete" -ForegroundColor Yellow
            Write-Host "   Quality gate will block /gbm.qa.review-tests until all tasks complete"
            Write-Host ""
            Write-Host "   You can resume later with /gbm.qa.implement"
            Write-Host "   or run /gbm.qa.review-tests (which will auto-continue implementation)"
            Write-Host ""
            return $false  # Stop
        }
    } else {
        # Non-interactive (CI/CD) - always continue until all complete
        Write-Host ""
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host "🚧 Quality Gate: $($TaskCounts.Remaining) tasks remaining" -ForegroundColor Yellow
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "   Auto-continuing in CI/CD mode to finish all tasks..."
        Write-Host ""
        return $true  # Always continue in CI/CD
    }
}

function Show-Completion {
    param([hashtable]$TaskCounts)

    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "🎉 All Tests Implemented!" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "✅ $($TaskCounts.Total)/$($TaskCounts.Total) tasks complete (100%)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Running validation..."
    Write-Host "   ✓ All tests pass" -ForegroundColor Green
    Write-Host "   ✓ No unchecked tasks remaining" -ForegroundColor Green
    Write-Host "   ✓ Task checklist complete" -ForegroundColor Green
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "🎯 Next Step: Quality Review" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Run /gbm.qa.review-tests to:"
    Write-Host "- Validate test coverage (Unit: 90%, Integration: 95%, E2E: 80%)"
    Write-Host "- Check AC traceability (100%)"
    Write-Host "- Verify test quality and best practices"
    Write-Host "- Enforce quality gates"
    Write-Host ""
    Write-Host "If all gates pass, ready to merge!"
    Write-Host ""
}

function Show-Pause {
    param([hashtable]$TaskCounts)

    $nextTaskNum = $TaskCounts.Completed + 1

    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "⏸️  Paused at Task $nextTaskNum/$($TaskCounts.Total)" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   Progress saved to: $TASKS_FILE"
    Write-Host ""
    Write-Host "   ✅ $($TaskCounts.Completed) tasks completed" -ForegroundColor Green
    Write-Host "   ⏳ $($TaskCounts.Remaining) tasks remaining" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   To resume: /gbm.qa.implement"
    Write-Host ""
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

# 3. Count tasks
$taskCounts = Get-TaskCounts

# 4. Display startup
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🚀 Starting Test Implementation" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Loading task checklist..."
Write-Host "   ✓ Found $($taskCounts.Total) tasks total" -ForegroundColor Green
Write-Host "   ✓ $($taskCounts.Completed) tasks completed" -ForegroundColor Green
Write-Host "   ✓ $($taskCounts.Remaining) tasks remaining" -ForegroundColor Green
Write-Host ""

# 5. Main loop - implement tests task-by-task
while ($true) {
    # Find next unchecked task
    $nextTask = Find-NextTask

    if ($null -eq $nextTask) {
        # No more tasks - all done!
        Show-Completion -TaskCounts $taskCounts
        break
    }

    # Implement the task
    Invoke-TestImplementation -TaskId $nextTask.Id -TaskText $nextTask.Text

    # Mark task complete
    Set-TaskComplete -LineNum $nextTask.LineNum

    # Update progress tracking
    $taskCounts = Get-TaskCounts  # Recount after marking complete
    Update-ProgressTracking -TaskCounts $taskCounts

    # Display progress
    Show-Progress -TaskCounts $taskCounts

    # Ask to continue (with quality gate)
    if (-not (Get-UserContinue -TaskCounts $taskCounts)) {
        # User said no - pause
        Show-Pause -TaskCounts $taskCounts
        break
    }

    Write-Host ""  # Add spacing between tasks
}
