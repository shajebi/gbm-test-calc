<#
.SYNOPSIS
    GoBuildMe Verification Status Script

.DESCRIPTION
    Reports the current status of verification matrix items.
    Shows what's passing vs failing, helping track acceptance criteria completion.

    IMPORTANT: This script does NOT run automated verification - it only REPORTS status.
    Actual verification is performed by the AI agent executing each item's
    verification_method (running tests, manual checks, etc.).

.NOTES
    PURPOSE:
        - Provides quick visibility into verification progress
        - Helps identify which acceptance criteria still need work
        - Useful for orientation at session start
        - Can be integrated into CI/CD for status reporting

    OUTPUT:
        Displays a formatted table showing:
        - Total verification items
        - Passing count (items with passes: true)
        - Failing count (items with passes: false)
        - List of passing/failing item IDs

    FILES READ:
        .gobuildme/specs/<feature>/verification/verification-matrix.json

    EXIT CODES:
        0 - Status retrieved successfully (or no matrix found - opt-in feature)
        1 - Error retrieving status (e.g., invalid feature name, malformed JSON)

    DEPENDENCIES:
        - gobuildme CLI must be installed and in PATH
        - Install with: uv tool install gobuildme-cli

    SEE ALSO:
        - gbm-verification-validate.ps1 - Validates matrix integrity (tamper detection)
        - gbm-harness.ps1 - Session handoff commands
        - docs/handbook/harness-guide.md - Full harness system documentation

.PARAMETER Feature
    Feature name/slug (e.g., "user-auth", "api-refactor")

.PARAMETER Help
    Display this help message

.EXAMPLE
    gbm-verification-status.ps1 user-auth

    Reports the verification status for the "user-auth" feature.
#>

param(
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$Feature,

    [switch]$Help
)

# Fail fast on any error
$ErrorActionPreference = "Stop"

# ============================================================================
# Help & Usage
# ============================================================================

function Write-Usage {
    # Provides comprehensive help for users unfamiliar with the harness system
    Write-Host "GoBuildMe Verification Status"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  gbm-verification-status.ps1 <feature>"
    Write-Host ""
    Write-Host "Reports the current status of verification matrix items."
    Write-Host ""
    Write-Host "IMPORTANT: Does NOT run automated verification - only reports status."
    Write-Host "Actual verification is performed by the AI agent running each item's"
    Write-Host "verification_method (tests, manual checks, etc.)."
    Write-Host ""
    Write-Host "Output includes:"
    Write-Host "  - Total items, passing count, failing count"
    Write-Host "  - List of passing item IDs"
    Write-Host "  - List of failing item IDs (need verification)"
    Write-Host ""
    Write-Host "Example:"
    Write-Host "  gbm-verification-status.ps1 user-auth"
    Write-Host ""
    Write-Host "Exit codes:"
    Write-Host "  0 - Status retrieved (or no matrix - opt-in feature)"
    Write-Host "  1 - Error (invalid feature, malformed JSON)"
    Write-Host ""
    Write-Host "Note: This script delegates to 'gobuildme harness verify-status'."
}

# ============================================================================
# Validation Functions
# ============================================================================

function Test-Gobuildme {
    # Verify gobuildme CLI is available before attempting to use it.
    # Provides clear installation instructions if missing.
    if (-not (Get-Command gobuildme -ErrorAction SilentlyContinue)) {
        Write-Host "Error: gobuildme CLI not found in PATH" -ForegroundColor Red
        Write-Host "Install with: uv tool install gobuildme-cli"
        exit 1
    }
}

# ============================================================================
# Main Entry Point
# ============================================================================

# Handle help request or missing feature argument
if ($Help -or [string]::IsNullOrEmpty($Feature)) {
    Write-Usage
    exit 0
}

# Validate CLI is available, then delegate to Python implementation
# Feature name validation (path traversal prevention) happens in Python CLI
Test-Gobuildme
& gobuildme harness verify-status $Feature
