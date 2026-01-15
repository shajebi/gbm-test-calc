# GoBuildMe Harness Script
# Thin wrapper for session handoff and verification commands
#
# Usage:
#   gbm-harness.ps1 progress seed <feature> <persona> [participants...]
#   gbm-harness.ps1 progress update <feature>
#   gbm-harness.ps1 progress show <feature>
#
# This script delegates to the gobuildme harness CLI commands.

param(
    [Parameter(Position = 0)]
    [string]$Command,

    [Parameter(Position = 1)]
    [string]$SubCommand,

    [Parameter(Position = 2)]
    [string]$Feature,

    [Parameter(Position = 3)]
    [string]$Persona,

    [Parameter(Position = 4, ValueFromRemainingArguments = $true)]
    [string[]]$Participants
)

$ErrorActionPreference = "Stop"

function Write-Usage {
    Write-Host "GoBuildMe Harness - Session Handoff & Verification"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  gbm-harness.ps1 progress seed <feature> <persona> [participants...]"
    Write-Host "      Create a new progress file for session handoff"
    Write-Host ""
    Write-Host "  gbm-harness.ps1 progress update <feature>"
    Write-Host "      Update progress summary from tasks.md"
    Write-Host ""
    Write-Host "  gbm-harness.ps1 progress show <feature>"
    Write-Host "      Display current progress for a feature"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  gbm-harness.ps1 progress seed user-auth backend_engineer"
    Write-Host "  gbm-harness.ps1 progress seed api-refactor qa_engineer frontend_engineer backend_engineer"
    Write-Host "  gbm-harness.ps1 progress update user-auth"
    Write-Host "  gbm-harness.ps1 progress show user-auth"
    Write-Host ""
    Write-Host "Note: This script delegates to 'gobuildme harness' CLI commands."
    Write-Host "Ensure gobuildme is installed and in your PATH."
}

function Test-Gobuildme {
    if (-not (Get-Command gobuildme -ErrorAction SilentlyContinue)) {
        Write-Host "Error: gobuildme CLI not found in PATH" -ForegroundColor Red
        Write-Host "Install with: uv tool install gobuildme-cli"
        exit 1
    }
}

# Main entry point
switch ($Command) {
    { $_ -in @("-h", "--help", "help", "") } {
        Write-Usage
        exit 0
    }
    "progress" {
        Test-Gobuildme
        if (-not $SubCommand) {
            Write-Host "Error: progress requires a subcommand (seed, update, show)" -ForegroundColor Red
            Write-Usage
            exit 1
        }
        switch ($SubCommand) {
            "seed" {
                if ($Participants) {
                    & gobuildme harness progress-seed $Feature $Persona @Participants
                } else {
                    & gobuildme harness progress-seed $Feature $Persona
                }
            }
            "update" {
                & gobuildme harness progress-update $Feature
            }
            "show" {
                & gobuildme harness progress-show $Feature
            }
            default {
                Write-Host "Error: Unknown progress subcommand: $SubCommand" -ForegroundColor Red
                Write-Usage
                exit 1
            }
        }
    }
    default {
        Write-Host "Error: Unknown command: $Command" -ForegroundColor Red
        Write-Usage
        exit 1
    }
}
