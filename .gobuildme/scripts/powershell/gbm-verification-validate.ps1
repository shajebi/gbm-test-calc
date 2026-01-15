<#
.SYNOPSIS
    GoBuildMe Verification Validate Script

.DESCRIPTION
    Validates that the verification matrix hasn't been tampered with.
    Detects scope drift by comparing current matrix against the lock file.

.NOTES
    PURPOSE:
        - Enforces immutability of acceptance criteria (tooling, not trust)
        - Prevents scope creep by detecting unauthorized changes
        - Acts as a quality gate in /gbm.review and /gbm.push commands
        - Provides audit trail for compliance and code review

    HOW IT WORKS:
        1. Reads verification-matrix.json (current state)
        2. Reads verification-matrix.lock.json (locked state with SHA256 hashes)
        3. Computes hashes of immutable fields for each item
        4. Compares against locked hashes
        5. Reports any discrepancies (modified, added, or deleted items)

    MUTABLE VS IMMUTABLE FIELDS:
        - MUTABLE (can change): passes, verified_at, verified_in_session, verification_evidence
        - IMMUTABLE (locked): id, type, description, verification_method

    VALIDATION RESULTS:
        - SKIP: No verification-matrix.json found (opt-in feature, backwards compatible)
        - WARN: Matrix exists but no lock file (suggest creating lock)
        - PASS: All hashes match (no tampering detected)
        - BLOCK: Tampering detected (hash mismatch, added/deleted items)

    FILES READ:
        .gobuildme/specs/<feature>/verification/verification-matrix.json
        .gobuildme/specs/<feature>/verification/verification-matrix.lock.json

    EXIT CODES:
        0 - PASS, SKIP, or WARN (proceed with workflow)
        1 - BLOCK (tampering detected) or error (stop workflow)

    WHEN TO USE:
        - Automatically called by /gbm.review and /gbm.push commands
        - Manually when you suspect scope drift
        - In CI/CD pipelines as a quality gate

    IF VALIDATION FAILS:
        - Review the tampered items listed in the output
        - If changes were intentional: run 'gobuildme harness regenerate-lock <feature>'
        - If changes were accidental: restore from git history

    DEPENDENCIES:
        - gobuildme CLI must be installed and in PATH
        - Install with: uv tool install gobuildme-cli

    SEE ALSO:
        - gbm-verification-status.ps1 - Reports pass/fail status of items
        - gbm-harness.ps1 - Session handoff commands
        - docs/handbook/harness-guide.md - Full harness system documentation

.PARAMETER Feature
    Feature name/slug (e.g., "user-auth", "api-refactor")

.PARAMETER Help
    Display this help message

.EXAMPLE
    gbm-verification-validate.ps1 user-auth

    Validates the verification matrix integrity for the "user-auth" feature.

.EXAMPLE
    # If validation fails with intentional changes:
    gobuildme harness regenerate-lock user-auth
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
    Write-Host "GoBuildMe Verification Validate"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  gbm-verification-validate.ps1 <feature>"
    Write-Host ""
    Write-Host "Validates that the verification matrix hasn't been tampered with."
    Write-Host "Compares current matrix against the lock file using SHA256 hashes."
    Write-Host ""
    Write-Host "Detects:"
    Write-Host "  - MODIFIED: Item exists in both but hash differs"
    Write-Host "  - DELETED: Item in lock file but not in matrix"
    Write-Host "  - ADDED: Item in matrix but not in lock file"
    Write-Host ""
    Write-Host "Validation results:"
    Write-Host "  SKIP  - No verification-matrix.json (opt-in, proceed)"
    Write-Host "  WARN  - Matrix exists, no lock file (suggest creating lock)"
    Write-Host "  PASS  - All hashes match (no tampering)"
    Write-Host "  BLOCK - Tampering detected (stop workflow)"
    Write-Host ""
    Write-Host "Exit codes:"
    Write-Host "  0 - PASS, SKIP, or WARN"
    Write-Host "  1 - BLOCK (tampering detected) or error"
    Write-Host ""
    Write-Host "Example:"
    Write-Host "  gbm-verification-validate.ps1 user-auth"
    Write-Host ""
    Write-Host "If validation fails:"
    Write-Host "  - Intentional change: gobuildme harness regenerate-lock <feature>"
    Write-Host "  - Accidental change: restore from git history"
    Write-Host ""
    Write-Host "Note: This script delegates to 'gobuildme harness verify-validate'."
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
& gobuildme harness verify-validate $Feature
