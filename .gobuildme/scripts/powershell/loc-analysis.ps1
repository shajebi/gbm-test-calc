#!/usr/bin/env pwsh
# Purpose : Analyze Lines of Code (LoC) changes against constitution-defined limits
# Why     : Keep feature branches focused, PRs manageable, and implementations well-structured
# How     : Parses loc_constraints from constitution.md, counts changed lines per artifact,
#           and reports violations (advisory by default, blocking in strict mode)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir/common.ps1"

# Resolve repository and feature context
$paths = Get-FeaturePathsEnv
$RepoRoot = $paths.REPO_ROOT
$CurrentBranch = $paths.CURRENT_BRANCH
$HasGit = $paths.HAS_GIT

Set-Location $RepoRoot

# Configuration
$ConstitutionFile = Join-Path $RepoRoot ".gobuildme/memory/constitution.md"
$BaseRef = if ($env:LOC_ANALYSIS_BASE) { $env:LOC_ANALYSIS_BASE } else { "origin/main" }
$Verbose = ($env:LOC_ANALYSIS_VERBOSE -eq "true")
$Skip = ($env:LOC_ANALYSIS_SKIP -eq "true")

# Skip if requested
if ($Skip) {
    Write-Output "LoC analysis skipped (LOC_ANALYSIS_SKIP=true)"
    exit 0
}

# Check if constitution exists
if (-not (Test-Path $ConstitutionFile)) {
    Write-Output "No constitution file found at $ConstitutionFile"
    Write-Output "LoC analysis requires constitution.md with loc_constraints section"
    exit 0
}

# Read constitution content
$ConstitutionContent = Get-Content $ConstitutionFile -Raw

# Extract YAML value from constitution
function Get-YamlValue {
    param(
        [string]$Key,
        [string]$Default
    )

    $pattern = "(?m)^\s*${Key}:\s*(.+?)(?:\s*#.*)?$"
    $match = [regex]::Match($ConstitutionContent, $pattern)
    if ($match.Success) {
        return $match.Groups[1].Value.Trim().Trim('"').Trim("'")
    }
    return $Default
}

# Check if loc_constraints is enabled
$LocEnabled = Get-YamlValue -Key "enabled" -Default "false"
if ($LocEnabled -ne "true") {
    if ($Verbose) {
        Write-Output "LoC analysis disabled in constitution (enabled: $LocEnabled)"
    }
    exit 0
}

# Get configuration values
$LocMode = Get-YamlValue -Key "mode" -Default "warn"
$MaxLoc = [int](Get-YamlValue -Key "max_loc_per_feature" -Default "1000")
$MaxFiles = [int](Get-YamlValue -Key "max_files_per_feature" -Default "30")
$BaseRefConfig = Get-YamlValue -Key "base_ref" -Default "origin/main"
$OutputDetail = Get-YamlValue -Key "output_detail" -Default "summary"
$MaxExceeded = [int](Get-YamlValue -Key "max_exceeded_display" -Default "5")

# Override base ref from config if not set via env
if (-not $env:LOC_ANALYSIS_BASE) {
    $BaseRef = $BaseRefConfig
}

# Ensure base ref exists
try {
    git rev-parse $BaseRef 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Base ref not found"
    }
} catch {
    Write-Output "Warning: Base ref '$BaseRef' not found. Attempting fetch..."
    $branchName = $BaseRef -replace "origin/", ""
    git fetch origin $branchName 2>$null

    git rev-parse $BaseRef 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Output "Warning: Cannot resolve base ref '$BaseRef'"
        Write-Output "LoC analysis skipped (base ref unresolved)"
        Write-Output "Tip: Set LOC_ANALYSIS_BASE to a valid ref or ensure origin is fetched"
        exit 0
    }
}

# Extract exclusion patterns from constitution
function Get-Exclusions {
    $exclusions = @()
    $inExclude = $false

    foreach ($line in ($ConstitutionContent -split "`n")) {
        if ($line -match "^\s*exclude:") {
            $inExclude = $true
            continue
        }

        if ($inExclude) {
            # Exit if we hit another top-level key
            if ($line -match "^\s{0,3}[a-z_]+:") {
                break
            }

            # Extract pattern from list item
            if ($line -match "^\s*-\s*(.+)") {
                $pattern = $matches[1].Trim().Trim('"').Trim("'")
                if ($pattern) {
                    $exclusions += $pattern
                }
            }
        }
    }

    return $exclusions
}

# Extract artifact definitions
function Get-Artifacts {
    $artifacts = @()
    $inArtifacts = $false
    $inArtifact = $false
    $currentName = ""
    $currentPaths = @()
    $currentMax = 0

    foreach ($line in ($ConstitutionContent -split "`n")) {
        if ($line -match "^\s*artifacts:") {
            $inArtifacts = $true
            continue
        }

        if ($inArtifacts) {
            # Exit if we hit another top-level key
            if ($line -match "^\s{0,3}[a-z_]+:" -and $line -notmatch "^\s+-") {
                if ($currentName -and $currentPaths.Count -gt 0 -and $currentMax -gt 0) {
                    $artifacts += [PSCustomObject]@{
                        Name = $currentName
                        Paths = $currentPaths
                        MaxLoc = $currentMax
                    }
                }
                break
            }

            # New artifact entry
            if ($line -match "^\s*-\s*name:\s*(.+)") {
                if ($currentName -and $currentPaths.Count -gt 0 -and $currentMax -gt 0) {
                    $artifacts += [PSCustomObject]@{
                        Name = $currentName
                        Paths = $currentPaths
                        MaxLoc = $currentMax
                    }
                }
                $currentName = $matches[1].Trim().Trim('"').Trim("'")
                $currentPaths = @()
                $currentMax = 0
                $inArtifact = $true
                continue
            }

            if ($inArtifact) {
                # Collect paths
                if ($line -match '^\s*-\s*"([^"]+)"') {
                    $currentPaths += $matches[1]
                }

                # Get max_loc
                if ($line -match "^\s*max_loc:\s*(\d+)") {
                    $currentMax = [int]$matches[1]
                }
            }
        }
    }

    # Add last artifact
    if ($currentName -and $currentPaths.Count -gt 0 -and $currentMax -gt 0) {
        $artifacts += [PSCustomObject]@{
            Name = $currentName
            Paths = $currentPaths
            MaxLoc = $currentMax
        }
    }

    return $artifacts
}

# Convert glob pattern to regex
function Convert-GlobToRegex {
    param([string]$Pattern)

    # Escape special regex chars except * and ?
    $regex = [regex]::Escape($Pattern)
    # Convert ** to match any path
    $regex = $regex -replace "\\\*\\\*", ".*"
    # Convert single * to match within path segment
    $regex = $regex -replace "\\\*", "[^/]*"

    return "^$regex$"
}

# Check if file matches any exclusion pattern
function Test-Excluded {
    param(
        [string]$File,
        [string[]]$Exclusions
    )

    foreach ($pattern in $Exclusions) {
        $regex = Convert-GlobToRegex -Pattern $pattern
        if ($File -match $regex) {
            return $true
        }
    }
    return $false
}

# Find which artifact a file belongs to (first match wins)
function Find-Artifact {
    param(
        [string]$File,
        [array]$Artifacts
    )

    foreach ($artifact in $Artifacts) {
        foreach ($pattern in $artifact.Paths) {
            $regex = Convert-GlobToRegex -Pattern $pattern
            if ($File -match $regex) {
                return [PSCustomObject]@{
                    Name = $artifact.Name
                    MaxLoc = $artifact.MaxLoc
                }
            }
        }
    }

    return [PSCustomObject]@{
        Name = "UNMATCHED"
        MaxLoc = 0
    }
}

# Get changed files
function Get-ChangedFiles {
    try {
        $files = git diff --name-only "$BaseRef...HEAD" 2>$null
        if ($LASTEXITCODE -ne 0) {
            $files = git diff --name-only "$BaseRef" HEAD
        }
        return $files
    } catch {
        return @()
    }
}

# Count non-blank, non-comment lines (simple heuristic)
function Get-LineCount {
    param([string]$FilePath)

    if (-not (Test-Path $FilePath)) { return 0 }

    $count = 0
    $inBlock = $false
    $inPyDoc = $false

    foreach ($line in [System.IO.File]::ReadLines($FilePath)) {
        $trim = $line.Trim()

        # Block comment start/end (/* ... */)
        if ($trim -match '/\*') { $inBlock = $true }
        if ($trim -match '\*/') { if ($inBlock) { $inBlock = $false; continue } }

        # Python triple-quoted docstrings ''' or """
        if ($trim -match '"""') {
            if (-not $inPyDoc) { $inPyDoc = $true; continue }
            else { $inPyDoc = $false; continue }
        }
        if ($trim -match "'''") {
            if (-not $inPyDoc) { $inPyDoc = $true; continue }
            else { $inPyDoc = $false; continue }
        }

        if ($inBlock -or $inPyDoc) { continue }

        if ($trim -eq "") { continue }               # blank
        if ($trim.StartsWith("//")) { continue }     # // comment
        if ($trim.StartsWith("#")) { continue }      # # comment
        if ($trim.StartsWith("--")) { continue }     # SQL style
        if ($trim.StartsWith("<!--")) { continue }   # HTML/XML single-line

        $count++
    }
    return $count
}

# Main analysis
Write-Output ""
Write-Output "╔══════════════════════════════════════════════════════════════╗"
Write-Output "║                    LOC ANALYSIS REPORT                        ║"
Write-Output "╠══════════════════════════════════════════════════════════════╣"
Write-Output ("║ Branch: {0,-52} ║" -f $CurrentBranch.Substring(0, [Math]::Min(52, $CurrentBranch.Length)))
Write-Output ("║ Base: {0,-54} ║" -f $BaseRef.Substring(0, [Math]::Min(54, $BaseRef.Length)))
$modeText = "$LocMode ($( if ($LocMode -eq 'strict') { 'blocking' } else { 'advisory' }))"
Write-Output ("║ Mode: {0,-54} ║" -f $modeText)
Write-Output "╠══════════════════════════════════════════════════════════════╣"

# Get exclusions and artifacts
$Exclusions = Get-Exclusions
$Artifacts = Get-Artifacts

if ($Verbose) {
    Write-Output ("║ Exclusions: {0,-48} ║" -f "$($Exclusions.Count) patterns")
    Write-Output ("║ Artifacts: {0,-49} ║" -f "$($Artifacts.Count) defined")
    Write-Output "╠══════════════════════════════════════════════════════════════╣"
}

# Initialize tracking
$TotalLoc = 0
$TotalFiles = 0
$ArtifactTotals = @{}
$ExceededArtifacts = @()

# Initialize artifact totals
foreach ($artifact in $Artifacts) {
    $ArtifactTotals[$artifact.Name] = [PSCustomObject]@{
        Total = 0
        MaxLoc = $artifact.MaxLoc
    }
}

# Process each changed file
$changedFiles = Get-ChangedFiles
foreach ($file in $changedFiles) {
    if (-not $file) { continue }

    # Skip if excluded
    if (Test-Excluded -File $file -Exclusions $Exclusions) {
        if ($Verbose) {
            Write-Output "  [excluded] $file"
        }
        continue
    }

    # Skip if file doesn't exist (deleted files)
    if (-not (Test-Path $file)) {
        continue
    }

    # Count lines
    $loc = Get-LineCount -FilePath $file
    $TotalLoc += $loc
    $TotalFiles++

    # Find artifact and update totals
    $artifactInfo = Find-Artifact -File $file -Artifacts $Artifacts

    if ($artifactInfo.Name -ne "UNMATCHED") {
        if ($ArtifactTotals.ContainsKey($artifactInfo.Name)) {
            $ArtifactTotals[$artifactInfo.Name].Total += $loc
        }
    }
}

# Display branch totals
Write-Output "║ BRANCH TOTALS                                                 ║"
Write-Output "║ ────────────────────────────────────────────────────────────── ║"

$LocStatus = "✓ OK"
$LocOver = $false
if ($TotalLoc -gt $MaxLoc) {
    $LocStatus = "⚠ OVER"
    $LocOver = $true
}
Write-Output ("║ Total LoC Changed: {0,-6} / {1,-6} limit               {2} ║" -f $TotalLoc, $MaxLoc, $LocStatus)

$FilesStatus = "✓ OK"
$FilesOver = $false
if ($TotalFiles -gt $MaxFiles) {
    $FilesStatus = "⚠ OVER"
    $FilesOver = $true
}
Write-Output ("║ Files Changed: {0,-10} / {1,-6} limit               {2} ║" -f $TotalFiles, $MaxFiles, $FilesStatus)

# Display artifact breakdown
Write-Output "╠══════════════════════════════════════════════════════════════╣"
Write-Output "║ ARTIFACT BREAKDOWN                                            ║"
Write-Output "║ ────────────────────────────────────────────────────────────── ║"

foreach ($name in $ArtifactTotals.Keys | Sort-Object) {
    $info = $ArtifactTotals[$name]

    if ($info.Total -eq 0 -and $OutputDetail -ne "full") {
        continue
    }

    $status = "✓ OK"
    if ($info.Total -gt $info.MaxLoc) {
        $status = "⚠ OVER"
        $overBy = $info.Total - $info.MaxLoc
        $ExceededArtifacts += [PSCustomObject]@{
            Name = $name
            Total = $info.Total
            MaxLoc = $info.MaxLoc
            OverBy = $overBy
        }
    }

    Write-Output ("║ {0,-22} {1,6} / {2,-6} LoC               {3} ║" -f $name, $info.Total, $info.MaxLoc, $status)
}

# Show exceeded artifacts
if ($ExceededArtifacts.Count -gt 0) {
    Write-Output "╠══════════════════════════════════════════════════════════════╣"
    $exceededText = "$($ExceededArtifacts.Count) artifact$(if ($ExceededArtifacts.Count -gt 1) { 's' } else { ' ' })"
    Write-Output ("║ EXCEEDED LIMITS ({0})                                ║" -f $exceededText)
    Write-Output "║ ────────────────────────────────────────────────────────────── ║"

    $count = 0
    foreach ($exceeded in $ExceededArtifacts) {
        $count++
        if ($count -gt $MaxExceeded -and $OutputDetail -eq "summary") {
            $remaining = $ExceededArtifacts.Count - $MaxExceeded
            Write-Output ("║   ... and {0} more exceeded artifacts                         ║" -f $remaining)
            break
        }
        Write-Output "║   $($exceeded.Name): $($exceeded.Total) LoC (+$($exceeded.OverBy) over limit)"
    }
}

Write-Output "╚══════════════════════════════════════════════════════════════╝"

# Determine exit status based on mode
if ($LocMode -eq "strict") {
    if ($ExceededArtifacts.Count -gt 0 -or $LocOver -or $FilesOver) {
        Write-Output ""
        Write-Output "❌ STRICT MODE: LoC limits exceeded. Push blocked."
        Write-Output "   Reduce scope or split into smaller PRs."
        exit 1
    }
}

# Advisory mode - always succeed but show status
if ($ExceededArtifacts.Count -gt 0 -or $LocOver -or $FilesOver) {
    Write-Output ""
    Write-Output "⚠️  Advisory: Some LoC limits exceeded. Consider splitting for better review quality."
} else {
    Write-Output ""
    Write-Output "✅ All LoC limits respected."
}

exit 0
