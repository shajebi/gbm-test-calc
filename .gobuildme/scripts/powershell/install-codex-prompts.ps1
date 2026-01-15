# install-codex-prompts.ps1
# Install GoBuildMe prompts to Codex CLI's expected location (~/.codex/prompts/)
#
# Usage:
#   .\scripts\powershell\install-codex-prompts.ps1         # Interactive mode
#   .\scripts\powershell\install-codex-prompts.ps1 copy    # Copy files
#   .\scripts\powershell\install-codex-prompts.ps1 symlink # Create symlink

param(
    [ValidateSet('copy', 'symlink', '')]
    [string]$Method = ''
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$ProjectPrompts = Join-Path $ProjectRoot ".codex\prompts"
$HomePrompts = Join-Path $env:USERPROFILE ".codex\prompts"

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

# Check if project has .codex/prompts directory
if (-not (Test-Path $ProjectPrompts)) {
    Write-Error "No .codex\prompts directory found in project root"
    Write-Error "Run 'gobuildme init <project> --ai codex' first"
    exit 1
}

$promptFiles = Get-ChildItem -Path $ProjectPrompts -Filter "*.md" -File -ErrorAction SilentlyContinue
if ($promptFiles.Count -eq 0) {
    Write-Error "No prompt files found in $ProjectPrompts"
    exit 1
}

Write-Info "Found $($promptFiles.Count) Codex prompt files in project"

# Determine installation method
if ([string]::IsNullOrEmpty($Method)) {
    # Interactive mode
    Write-Host ""
    Write-Host "Codex CLI expects prompts in: $HomePrompts"
    Write-Host "Project prompts are in:       $ProjectPrompts"
    Write-Host ""
    Write-Host "Choose installation method:"
    Write-Host "  1) Symlink (recommended) - Links home directory to project"
    Write-Host "  2) Copy - Copies files to home directory"
    Write-Host ""

    $choice = Read-Host "Enter choice (1 or 2)"

    switch ($choice) {
        "1" { $Method = "symlink" }
        "2" { $Method = "copy" }
        default {
            Write-Error "Invalid choice"
            exit 1
        }
    }
}

# Check if ~/.codex/prompts already exists
if (Test-Path $HomePrompts) {
    Write-Warning "~/.codex/prompts already exists"

    $item = Get-Item $HomePrompts
    if ($item.LinkType -eq "SymbolicLink") {
        $target = $item.Target
        if ($target -eq $ProjectPrompts) {
            Write-Success "Already linked to this project"
            exit 0
        }
        else {
            Write-Warning "Currently linked to: $target"
        }
    }
    elseif ($item.PSIsContainer) {
        $fileCount = (Get-ChildItem -Path $HomePrompts -Filter "*.md" -File -ErrorAction SilentlyContinue).Count
        Write-Warning "Directory contains $fileCount files"
    }

    Write-Host ""
    $confirm = Read-Host "Overwrite ~/.codex/prompts? (y/N)"
    if ($confirm -notmatch '^[Yy]$') {
        Write-Info "Installation cancelled"
        exit 0
    }

    # Backup existing
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backup = "$($env:USERPROFILE)\.codex\prompts.backup.$timestamp"
    Write-Info "Backing up to: $backup"
    Move-Item -Path $HomePrompts -Destination $backup -Force
    Write-Success "Backup created"
}

# Create parent directory
$codexHome = Join-Path $env:USERPROFILE ".codex"
if (-not (Test-Path $codexHome)) {
    New-Item -ItemType Directory -Path $codexHome -Force | Out-Null
}

# Install prompts
switch ($Method) {
    "symlink" {
        Write-Info "Creating symlink..."

        # PowerShell requires admin for symlinks on older Windows
        # Try symlink first, fall back to junction
        try {
            New-Item -ItemType SymbolicLink -Path $HomePrompts -Target $ProjectPrompts -Force | Out-Null
            Write-Success "Symlink created: ~/.codex/prompts -> $ProjectPrompts"
        }
        catch {
            Write-Warning "Symlink requires admin. Creating junction instead..."
            New-Item -ItemType Junction -Path $HomePrompts -Target $ProjectPrompts -Force | Out-Null
            Write-Success "Junction created: ~/.codex/prompts -> $ProjectPrompts"
        }

        Write-Host ""
        Write-Info "Note: Link points to this project. Switching projects will require:"
        Write-Info "  1. Remove link: Remove-Item ~/.codex/prompts"
        Write-Info "  2. Re-run this script from the new project"
    }

    "copy" {
        Write-Info "Copying files..."
        Copy-Item -Path $ProjectPrompts -Destination $HomePrompts -Recurse -Force
        $copiedFiles = Get-ChildItem -Path $HomePrompts -Filter "*.md" -File
        Write-Success "Copied $($copiedFiles.Count) files to ~/.codex/prompts"

        Write-Host ""
        Write-Warning "Files copied. If project prompts change, re-run this script to update"
    }
}

Write-Host ""
Write-Success "Installation complete!"
Write-Host ""
Write-Info "Test with Codex CLI:"
Write-Host "  codex /gbm"
Write-Host "  codex /gbm.specify"
Write-Host ""
