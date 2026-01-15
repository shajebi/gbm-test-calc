# validate-template-style.ps1 - Validate templates follow concise output style guidelines
# Part of Issue #11: Improve readability and reduce verbosity

param(
    [switch]$Verbose,
    [switch]$CheckOnly,
    [string]$File
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$TemplatesDir = Join-Path $RepoRoot "templates\commands"

# Banned terms (verbose language to avoid)
$BannedTerms = @(
    "comprehensive"
    "exhaustive"
    "in order to"
    "It is recommended that"
    "The following is a list"
    "As previously mentioned"
)

# Allowlist - terms OK in specific contexts
$Allowlist = @(
    "comprehensive test coverage"
    "comprehensive architecture"
)

# Counters
$script:TotalFiles = 0
$script:PassedFiles = 0
$script:FailedFiles = 0
$script:Warnings = 0

function Write-VerboseLog {
    param([string]$Message)
    if ($Verbose) {
        Write-Host $Message
    }
}

function Test-StyleBlock {
    param([string]$FilePath)

    $filename = Split-Path -Leaf $FilePath

    # Skip non-command templates
    if ($filename.StartsWith("_")) {
        return
    }

    $content = Get-Content $FilePath -Raw
    if ($content -match "## Output Style Requirements") {
        Write-VerboseLog "  [PASS] Has Output Style Requirements section"
    } else {
        Write-Host "  [WARN] Missing Output Style Requirements section"
        $script:Warnings++
    }
}

function Test-BannedTerms {
    param([string]$FilePath)

    $content = Get-Content $FilePath -Raw
    $foundBanned = $false

    foreach ($term in $BannedTerms) {
        if ($content -match [regex]::Escape($term)) {
            $isAllowed = $false

            foreach ($allowed in $Allowlist) {
                if ($content -match [regex]::Escape($allowed)) {
                    $countBanned = ([regex]::Matches($content, [regex]::Escape($term), 'IgnoreCase')).Count
                    $countAllowed = ([regex]::Matches($content, [regex]::Escape($allowed), 'IgnoreCase')).Count

                    if ($countBanned -le $countAllowed) {
                        $isAllowed = $true
                        break
                    }
                }
            }

            if (-not $isAllowed) {
                Write-Host "  [WARN] Contains banned term: '$term'"
                $script:Warnings++
                $foundBanned = $true
            }
        }
    }

    if (-not $foundBanned) {
        Write-VerboseLog "  [PASS] No banned terms found"
    }
}

function Get-FileMetrics {
    param([string]$FilePath)

    $lines = Get-Content $FilePath
    $totalLines = $lines.Count
    $sectionCount = ($lines | Where-Object { $_ -match "^## " }).Count

    Write-VerboseLog "  Lines: $totalLines, Sections: $sectionCount"

    if ($totalLines -gt 600) {
        Write-Host "  [WARN] File is $totalLines lines (target: <600)"
        $script:Warnings++
    }
}

function Test-TemplateFile {
    param([string]$FilePath)

    $filename = Split-Path -Leaf $FilePath
    Write-Host "Validating: $filename"
    $script:TotalFiles++

    $fileWarnings = $script:Warnings

    Test-StyleBlock -FilePath $FilePath
    Test-BannedTerms -FilePath $FilePath
    Get-FileMetrics -FilePath $FilePath

    if ($script:Warnings -eq $fileWarnings) {
        $script:PassedFiles++
        Write-VerboseLog "  Result: PASS"
    } else {
        $script:FailedFiles++
        Write-VerboseLog "  Result: NEEDS ATTENTION"
    }

    Write-Host ""
}

# Main execution
Write-Host "Template Style Validation"
Write-Host "========================="
Write-Host ""

if ($File) {
    if (Test-Path $File) {
        Test-TemplateFile -FilePath $File
    } else {
        Write-Error "File not found: $File"
        exit 1
    }
} else {
    # Validate all command templates
    $files = Get-ChildItem -Path $TemplatesDir -Filter "*.md"
    foreach ($f in $files) {
        Test-TemplateFile -FilePath $f.FullName
    }
}

# Summary
Write-Host "========================="
Write-Host "Summary"
Write-Host "========================="
Write-Host "Total files: $script:TotalFiles"
Write-Host "Passed: $script:PassedFiles"
Write-Host "Need attention: $script:FailedFiles"
Write-Host "Total warnings: $script:Warnings"

if ($script:Warnings -gt 0) {
    exit 1
} else {
    Write-Host ""
    Write-Host "All validations passed!"
    exit 0
}
