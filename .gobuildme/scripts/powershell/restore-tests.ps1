# Purpose: Restore tests from backup (rollback mechanism)
# Why: Provides undo functionality if test generation fails or corrupts tests
# How: Restores from .gobuildme/test-generation-backup/

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Restore from specific backup directory")]
    [string]$Backup = "",

    [Parameter(HelpMessage = "List available backups")]
    [switch]$List,

    [Parameter(HelpMessage = "Show help message")]
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# Source common utilities
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\qa-common.ps1"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Show help if requested
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if ($Help) {
    Write-Host "Usage: restore-tests.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Restore tests from backup (rollback mechanism)"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Backup DIR    Restore from specific backup directory"
    Write-Host "  -List          List available backups"
    Write-Host "  -Help          Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  restore-tests.ps1                      # Restore from latest backup"
    Write-Host "  restore-tests.ps1 -List                # List available backups"
    Write-Host "  restore-tests.ps1 -Backup <dir>        # Restore from specific backup"
    exit 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# List backups if requested
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if ($List) {
    Print-Section "📋 Available Backups"

    $BackupBase = ".gobuildme/test-generation-backup"

    if (-not (Test-Path $BackupBase)) {
        Print-Info "No backups found"
        exit 0
    }

    $Backups = Get-ChildItem -Path $BackupBase -Directory | Sort-Object -Property LastWriteTime -Descending

    if ($Backups.Count -eq 0) {
        Print-Info "No backups found"
        exit 0
    }

    Write-Host "Found backups:"
    Write-Host ""

    foreach ($BackupDir in $Backups) {
        $ManifestPath = Join-Path $BackupDir.FullName "manifest.json"
        if (Test-Path $ManifestPath) {
            $Manifest = Get-Content $ManifestPath | ConvertFrom-Json
            Write-Host "  • $($BackupDir.FullName)"
            Write-Host "    Operation: $($Manifest.operation)"
            Write-Host "    Timestamp: $($Manifest.timestamp)"
            Write-Host ""
        } else {
            Write-Host "  • $($BackupDir.FullName)"
            Write-Host "    (No manifest found)"
            Write-Host ""
        }
    }

    exit 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Restore from backup
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Print-Section "🔄 Restore Tests from Backup"

# Determine backup directory
if ([string]::IsNullOrEmpty($Backup)) {
    Print-Info "No backup specified, using latest..."
    $Backup = Get-LatestBackup

    if ([string]::IsNullOrEmpty($Backup)) {
        Print-Error "No backups found"
        Write-Host ""
        Write-Host "Tip: Run -List to see available backups"
        exit 1
    }

    Print-Info "Latest backup: $Backup"
}

# Confirm restore
Write-Host ""
Write-Host "⚠️  This will replace current tests/ directory with backup"
Write-Host ""

# Check if running interactively
$IsInteractive = [Environment]::UserInteractive -and (-not [Console]::IsInputRedirected)

if ($IsInteractive) {
    $Confirm = Read-Host "Proceed with restore? [y/N]"
} else {
    # Non-interactive - require explicit confirmation via environment variable
    if ($env:AUTO_CONFIRM -eq "true") {
        $Confirm = "y"
        Write-Host "Proceed with restore? [y/N] y (auto-confirmed)"
    } else {
        $Confirm = "n"
        Write-Host "Proceed with restore? [y/N] n (non-interactive, use AUTO_CONFIRM=true to override)"
    }
}

Write-Host ""

if ($Confirm -ne "y" -and $Confirm -ne "Y") {
    Print-Info "Restore cancelled"
    exit 0
}

# Perform restore
if (Restore-FromBackup -BackupDir $Backup) {
    Print-Section "✅ Restore Complete"
    Write-Host "Tests have been restored from backup."
    Write-Host ""
    Write-Host "Backup: $Backup"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  • Review restored tests"
    Write-Host "  • Run tests: /gbm.tests or npm test"
    exit 0
} else {
    Print-Section "❌ Restore Failed"
    Write-Host "Failed to restore from backup."
    Write-Host ""
    Write-Host "Backup: $Backup"
    exit 1
}
