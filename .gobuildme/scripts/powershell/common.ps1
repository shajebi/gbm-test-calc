#!/usr/bin/env pwsh
# Purpose : Share reusable PowerShell helpers across GoBuildMe scripts.
# Why     : Centralizes repo discovery, branch logic, and utility output for consistency.
# How     : Exposes functions to resolve feature paths, check tooling, and emit status.

# Common PowerShell functions analogous to common.sh

function Get-RepoRoot {
    try {
        $result = git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $result
        }
    } catch {
        # Git command failed
    }
    
    # Fall back to script location for non-git repos
    return (Resolve-Path (Join-Path $PSScriptRoot "../../..")).Path
}

function Get-CurrentBranch {
    # First check if SPECIFY_FEATURE environment variable is set
    if ($env:SPECIFY_FEATURE) {
        return $env:SPECIFY_FEATURE
    }
    
    # Then check git if available
    try {
        $result = git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $result
        }
    } catch {
        # Git command failed
    }
    
    # For non-git repos, try to find the latest feature directory
    $repoRoot = Get-RepoRoot
    # Use hidden .gobuildme/specs exclusively
    $specsDir = Join-Path $repoRoot '.gobuildme/specs'
    
    if (Test-Path $specsDir) {
        $latestFeature = ""
        $highest = 0
        
        Get-ChildItem -Path $specsDir -Directory | ForEach-Object {
            if ($_.Name -match '^(\d{3})-') {
                $num = [int]$matches[1]
                if ($num -gt $highest) {
                    $highest = $num
                    $latestFeature = $_.Name
                }
            }
        }
        
        if ($latestFeature) {
            return $latestFeature
        }
    }
    
    # Final fallback
    return "main"
}

function Test-HasGit {
    try {
        git rev-parse --show-toplevel 2>$null | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Test-FeatureBranch {
    param(
        [string]$Branch,
        [bool]$HasGit = $true
    )

    # For non-git repos, we can't enforce branch naming but still provide output
    if (-not $HasGit) {
        Write-Warning "[specify] Warning: Git repository not detected; skipped branch validation"
        return $true
    }

    # Check if it's a meaningful feature branch (not main, master, develop, etc.)
    if ($Branch -match '^(main|master|develop|dev|staging|production|prod)$') {
        Write-Output "ERROR: Not on a feature branch. Current branch: $Branch"
        Write-Output "Feature branches should be named descriptively, like: feature-name or jira-123-feature-name"
        return $false
    }
    return $true
}

function Get-SpecsRoot {
    param([string]$RepoRoot)
    return (Join-Path $RepoRoot '.gobuildme/specs')
}

# Normalize a slug to kebab-case lowercase.
# Converts underscores/spaces to hyphens, lowercases, preserves -- separator.
# Example: "MyEpic" → "myepic", "FrontEnd_UI" → "frontend-ui", "My Epic" → "my-epic"
function Normalize-Slug {
    param([string]$Input)
    # Step 1: Lowercase
    $result = $Input.ToLowerInvariant()
    # Step 2: Preserve -- by replacing with placeholder
    $result = $result.Replace('--', '__DOUBLE_DASH__')
    # Step 3: Replace underscores, spaces, and other non-alphanumeric with hyphens
    $result = [regex]::Replace($result, '[^a-z0-9-]', '-')
    # Step 4: Collapse multiple hyphens to single
    $result = [regex]::Replace($result, '-{2,}', '-')
    # Step 5: Restore -- separator
    $result = $result.Replace('__DOUBLE_DASH__', '--')
    # Step 6: Trim leading/trailing hyphens
    $result = $result.Trim('-')
    return $result
}

# Get feature directory, supporting both standalone and sliced epics.
# For sliced epics (branch contains "--"), resolves to specs/epics/<epic>/<slice>/
# For standalone features, resolves to specs/<branch>/
function Get-FeatureDir {
    param([string]$RepoRoot, [string]$Branch)
    $specsRoot = Get-SpecsRoot -RepoRoot $RepoRoot

    # Step 1: Parse branch for double-dash (epic/slice separator)
    if ($Branch -like '*--*') {
        $parts = $Branch -split '--', 2
        $epicPart = $parts[0]
        $slicePart = $parts[1]
        $epic = Normalize-Slug -Input $epicPart
        $slice = Normalize-Slug -Input $slicePart

        # Step 2: Check registry first (canonical source of truth)
        $registry = Join-Path $specsRoot "epics/$epic/slice-registry.yaml"
        if (Test-Path $registry) {
            $registryContent = Get-Content $registry -Raw
            # Verify slice exists in registry (anchored match to avoid substrings)
            if ($registryContent -match "(?m)^\s*slice_name:\s*$slice$") {
                return (Join-Path $specsRoot "epics/$epic/$slice")
            }
        }

        # Step 3: Fallback to directory check
        $sliceDir = Join-Path $specsRoot "epics/$epic/$slice"
        if (Test-Path $sliceDir -PathType Container) {
            return $sliceDir
        }

        # Step 4: No registry/directory found - return expected path for creation
        # NOTE: This is normal during slice creation (registry created by /gbm.request)
        return $sliceDir
    }

    # Step 5: Standalone feature (no -- in branch)
    return (Join-Path $specsRoot $Branch)
}

# Get all valid feature directories (standalone + sliced).
# Returns paths to all feature directories for spec enumeration.
#
# USAGE:
#   . common.ps1
#   $repoRoot = Get-RepoRoot
#   foreach ($featureDir in (Get-AllFeatureDirs -RepoRoot $repoRoot)) {
#       Write-Host "Processing: $featureDir"
#   }
#
# RETURNS:
#   - Standalone features: .gobuildme/specs/<feature>/
#   - Sliced features: .gobuildme/specs/epics/<epic>/<slice>/
#
# NOTE: This is infrastructure for progress tracking, telemetry, CI status, etc.
#       If no scripts currently call it, that's intentional - it's available for future use.
function Get-AllFeatureDirs {
    param([string]$RepoRoot)
    $specsRoot = Get-SpecsRoot -RepoRoot $RepoRoot
    $dirs = @()

    # Standalone features: specs/<feature>/
    if (Test-Path $specsRoot) {
        Get-ChildItem -Path $specsRoot -Directory | ForEach-Object {
            # Exclude epics directory (it contains sliced features, not standalone)
            if ($_.Name -ne 'epics') {
                $dirs += $_.FullName
            }
        }
    }

    # Sliced features: specs/epics/<epic>/<slice>/
    $epicsRoot = Join-Path $specsRoot 'epics'
    if (Test-Path $epicsRoot) {
        Get-ChildItem -Path $epicsRoot -Directory | ForEach-Object {
            $epicDir = $_.FullName
            Get-ChildItem -Path $epicDir -Directory | ForEach-Object {
                # Exclude registry file (just in case)
                if ($_.Name -ne 'slice-registry.yaml') {
                    $dirs += $_.FullName
                }
            }
        }
    }

    return $dirs
}

function Get-FeaturePathsEnv {
    $repoRoot = Get-RepoRoot
    $currentBranch = Get-CurrentBranch
    $hasGit = Test-HasGit
    $featureDir = Get-FeatureDir -RepoRoot $repoRoot -Branch $currentBranch
    
    [PSCustomObject]@{
        REPO_ROOT     = $repoRoot
        CURRENT_BRANCH = $currentBranch
        HAS_GIT       = $hasGit
        FEATURE_DIR   = $featureDir
        FEATURE_SPEC  = Join-Path $featureDir 'spec.md'
        REQUEST_FILE  = Join-Path $featureDir 'request.md'
        IMPL_PLAN     = Join-Path $featureDir 'plan.md'
        TASKS         = Join-Path $featureDir 'tasks.md'
        RESEARCH      = Join-Path $featureDir 'research.md'
        DATA_MODEL    = Join-Path $featureDir 'data-model.md'
        QUICKSTART    = Join-Path $featureDir 'quickstart.md'
        CONTRACTS_DIR = Join-Path $featureDir 'contracts'
        PRD           = Join-Path $featureDir 'prd.md'
    }
}

function Test-FileExists {
    param([string]$Path, [string]$Description)
    if (Test-Path -Path $Path -PathType Leaf) {
        Write-Output "  ✓ $Description"
        return $true
    } else {
        Write-Output "  ✗ $Description"
        return $false
    }
}

function Test-DirHasFiles {
    param([string]$Path, [string]$Description)
    if ((Test-Path -Path $Path -PathType Container) -and (Get-ChildItem -Path $Path -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | Select-Object -First 1)) {
        Write-Output "  ✓ $Description"
        return $true
    } else {
        Write-Output "  ✗ $Description"
        return $false
    }
}
