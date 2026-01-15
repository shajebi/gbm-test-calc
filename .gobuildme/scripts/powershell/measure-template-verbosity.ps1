# measure-template-verbosity.ps1 - Measure and enforce template line count budgets
# Part of Issue #11: Improve readability and reduce verbosity

param(
    [switch]$Verbose,
    [switch]$CI,
    [switch]$Help
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$TemplatesDir = Join-Path $RepoRoot "templates/commands"

# Thresholds
$LineThreshold = 600      # Files above this trigger warning
$FailThreshold = 1000     # Files above this cause failure
$TotalBudget = 12000      # Target total lines across all templates
$AvgTarget = 300          # Target average lines per template

# Counters
$totalLines = 0
$templateCount = 0
$overThreshold = 0
$overFail = 0

if ($Help) {
    @"
Usage: measure-template-verbosity.ps1 [OPTIONS]

Measure template verbosity and enforce line count budgets.

Options:
    -Verbose        Show all templates (not just over threshold)
    -CI             CI mode: strict exit codes for automation
    -Help           Show this help

Thresholds:
    Per-file warning: >$LineThreshold lines
    Per-file failure: >$FailThreshold lines
    Total budget: $TotalBudget lines
    Average target: $AvgTarget lines

Exit codes:
    0 - All budgets met
    1 - Over budget (CI mode) or warnings present
"@
    exit 0
}

Write-Host "Template Verbosity Metrics"
Write-Host "=========================="
Write-Host ""

# Header
"{0,-40} {1,8} {2,10}" -f "Template", "Lines", "Status"
"{0,-40} {1,8} {2,10}" -f "--------", "-----", "------"

# Measure each template
Get-ChildItem -Path $TemplatesDir -Filter "*.md" | ForEach-Object {
    $filename = $_.Name
    $lines = (Get-Content $_.FullName | Measure-Object -Line).Lines
    $script:totalLines += $lines
    $script:templateCount++

    # Determine status
    $status = "OK"
    if ($lines -gt $FailThreshold) {
        $status = "FAIL"
        $script:overFail++
        $script:overThreshold++
    } elseif ($lines -gt $LineThreshold) {
        $status = "WARN"
        $script:overThreshold++
    }

    # Print based on mode
    if ($Verbose -or $status -ne "OK") {
        "{0,-40} {1,8} {2,10}" -f $filename, $lines, $status
    }
}

# Calculate averages
$avgLines = [math]::Floor($totalLines / $templateCount)

Write-Host ""
Write-Host "=========================="
Write-Host "Summary"
Write-Host "=========================="
"{0,-30} {1,10}" -f "Total lines:", $totalLines
"{0,-30} {1,10}" -f "Template count:", $templateCount
"{0,-30} {1,10}" -f "Average lines:", $avgLines
Write-Host ""

# Budget analysis
Write-Host "Budget Analysis"
Write-Host "---------------"

# Total budget check
if ($totalLines -gt $TotalBudget) {
    $overBy = $totalLines - $TotalBudget
    $pctOver = [math]::Floor(($overBy * 100) / $TotalBudget)
    Write-Host "Total budget:    OVER by $overBy lines ($pctOver%)"
    Write-Host "                 Current: $totalLines, Target: $TotalBudget"
} else {
    $underBy = $TotalBudget - $totalLines
    $pctUnder = [math]::Floor(($underBy * 100) / $TotalBudget)
    Write-Host "Total budget:    OK (under by $underBy lines, $pctUnder%)"
}

# Average check
if ($avgLines -gt $AvgTarget) {
    Write-Host "Average:         OVER target ($avgLines vs $AvgTarget)"
} else {
    Write-Host "Average:         OK ($avgLines vs $AvgTarget target)"
}

# Files over threshold
Write-Host ""
Write-Host "Files over threshold: $overThreshold"
Write-Host "Files causing failure: $overFail"

# Exit code determination
Write-Host ""
if ($overFail -gt 0) {
    Write-Host "Result: FAIL - $overFail templates exceed $FailThreshold lines"
    exit 1
} elseif ($CI -and $totalLines -gt $TotalBudget) {
    Write-Host "Result: FAIL - Total lines ($totalLines) exceeds budget ($TotalBudget)"
    exit 1
} elseif ($overThreshold -gt 0) {
    Write-Host "Result: WARN - $overThreshold templates exceed $LineThreshold lines"
    if ($CI) {
        exit 1
    }
    exit 0
} else {
    Write-Host "Result: PASS - All templates within budget"
    exit 0
}
