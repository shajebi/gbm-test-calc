# Purpose : Initialize GoBuildMe projects entirely offline using cached releases.
# Why     : Enables environments without network access to bootstrap the SDD
#           workflow while staying aligned with the official templates.
# How     : Selects the proper agent/template zip, unpacks it into the target
#           directory, and normalizes legacy folder names.

<#
.SYNOPSIS
    Offline initializer for GoBuildMe templates (no network).

.DESCRIPTION
    Uses local release zips from this repo's .genreleases/
    Unzips into target directory and renames .specify -> .gobuildme
    No Python, pip, or network required

.PARAMETER Agent
    One of: claude, gemini, copilot, cursor, qwen, opencode, codex, windsurf, kilocode, auggie, roo, q
    Default: copilot

.PARAMETER Script
    Script flavor: sh or ps
    Default: sh

.PARAMETER Here
    Use current working directory as destination

.PARAMETER Dir
    Destination directory (created if missing)

.PARAMETER Zip
    Use an explicit template zip path (bypasses agent/script)

.PARAMETER Force
    Proceed if .gobuildme already exists (merge/overwrite files)

.EXAMPLE
    .\offline-init.ps1 -Here -Agent copilot -Script sh

.EXAMPLE
    .\offline-init.ps1 -Dir C:\Code\newproj -Agent windsurf -Script sh

.EXAMPLE
    .\offline-init.ps1 -Zip C:\path\to\gobuildme-template-claude-sh-v9.9.8.zip -Here
#>

[CmdletBinding()]
param(
    [string]$Agent = "copilot",
    [ValidateSet("sh", "ps")]
    [string]$Script = "sh",
    [switch]$Here,
    [string]$Dir = "",
    [string]$Zip = "",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message)
    Write-Host "[offline-init] $Message" -ForegroundColor Cyan
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "[offline-init] ERROR: $Message" -ForegroundColor Red
    exit 1
}

# Determine repo root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path "$ScriptDir\..\.." -ErrorAction Stop).Path
$GenDir = Join-Path $RepoRoot ".genreleases"

# Validate parameters
if ($Here -and $Dir) {
    Write-ErrorMsg "Use either -Here or -Dir, not both."
}

if (-not $Here -and -not $Dir) {
    Write-ErrorMsg "Specify -Here or -Dir <path>."
}

# Determine destination directory
if ($Here) {
    $DestDir = Get-Location | Select-Object -ExpandProperty Path
} else {
    if (-not (Test-Path $Dir)) {
        New-Item -ItemType Directory -Path $Dir -Force | Out-Null
    }
    $DestDir = (Resolve-Path $Dir).Path
}

# Find or validate zip path
if (-not $Zip) {
    if (-not (Test-Path $GenDir)) {
        Write-ErrorMsg "Missing $GenDir. Run from a gobuildme repo clone."
    }

    # Find matching template zips
    $Pattern = "gobuildme-template-$Agent-$Script-v*.zip"
    $Candidates = Get-ChildItem -Path $GenDir -Filter $Pattern -ErrorAction SilentlyContinue | Sort-Object Name

    if ($Candidates.Count -eq 0) {
        Write-ErrorMsg "No template zips found for agent=$Agent script=$Script under $GenDir"
    }

    # Pick the lexicographically last as the newest
    $ZipPath = $Candidates[-1].FullName
} else {
    $ZipPath = $Zip
}

if (-not (Test-Path $ZipPath)) {
    Write-ErrorMsg "Template zip not found: $ZipPath"
}

Write-Info "Using zip: $ZipPath"
Write-Info "Destination: $DestDir"

# Safety checks
$GobuildmeDir = Join-Path $DestDir ".gobuildme"
if ((Test-Path $GobuildmeDir) -and -not $Force) {
    Write-ErrorMsg ".gobuildme already exists in $DestDir. Use -Force to merge/overwrite."
}

# Unzip into destination
Write-Info "Unzipping template..."
try {
    Expand-Archive -Path $ZipPath -DestinationPath $DestDir -Force
} catch {
    Write-ErrorMsg "Failed to unzip: $_"
}

# Rename legacy .specify -> .gobuildme if present
$SpecifyDir = Join-Path $DestDir ".specify"
if (Test-Path $SpecifyDir) {
    Write-Info "Renaming .specify -> .gobuildme"
    
    if (Test-Path $GobuildmeDir) {
        # Merge copy when both exist
        Get-ChildItem -Path $SpecifyDir -Recurse | ForEach-Object {
            $TargetPath = $_.FullName.Replace($SpecifyDir, $GobuildmeDir)
            if ($_.PSIsContainer) {
                if (-not (Test-Path $TargetPath)) {
                    New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
                }
            } else {
                $TargetDir = Split-Path -Parent $TargetPath
                if (-not (Test-Path $TargetDir)) {
                    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
                }
                Copy-Item -Path $_.FullName -Destination $TargetPath -Force
            }
        }
        Remove-Item -Path $SpecifyDir -Recurse -Force
    } else {
        Rename-Item -Path $SpecifyDir -NewName ".gobuildme"
    }
}

Write-Info "Done. Project bootstrap files are in: $DestDir"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "- /constitution → try: open .gobuildme/templates/commands/constitution.md (or use your agent's prompts) [FIRST]"
Write-Host "- /request → try: open .gobuildme/templates/commands/request.md (or use your agent's prompts)"
Write-Host "- /specify → write spec.md"
Write-Host "- /plan → generate plan artifacts"
Write-Host "- Tip: commit the generated files and set up CI"

