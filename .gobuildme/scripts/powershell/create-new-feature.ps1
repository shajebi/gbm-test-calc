#!/usr/bin/env pwsh
# Purpose : Create numbered feature scaffolds from PowerShell.
# Why     : Keeps branch naming and folder structure consistent for Windows workflows.
# How     : Parses descriptions into slugs, increments feature counters, and seeds request/spec files.

# Create a new feature with smarter slug inference and optional overrides
[CmdletBinding()]
param(
    [switch]$Json,
    [string]$Slug,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FeatureDescription
)
$ErrorActionPreference = 'Stop'

# Normalize descriptive strings into safe branch-friendly slugs.
# Preserves -- (double-dash) as epic/slice separator.
function Get-SanitizedSlug {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return '' }
    $lower = $Value.ToLowerInvariant()
    # Step 1: Replace non-alphanumeric (except hyphen) with hyphen
    $lower = [regex]::Replace($lower, '[^a-z0-9-]', '-')
    # Step 2: Preserve -- by replacing with placeholder, collapse other multiples, restore
    $lower = $lower.Replace('--', '__DOUBLE_DASH__')
    $lower = [regex]::Replace($lower, '-{2,}', '-')
    $lower = $lower.Replace('__DOUBLE_DASH__', '--')
    # Step 3: Trim leading/trailing hyphens
    $lower = $lower.Trim('-')
    return $lower
}

function Get-Stopwords {
    $set = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($word in @('a','an','and','are','as','at','be','but','by','for','from','has','have','if','in','is','it','of','on','or','our','shall','should','so','that','the','their','this','to','we','with','you','add','adds','added','adding','allow','allows','allowing','allowed','create','creates','created','creating','design','designs','designed','designing','ensure','ensures','ensured','ensuring','enhance','enhances','enhanced','enhancing','feature','features','fix','fixes','fixed','fixing','implement','implements','implemented','implementing','launch','launches','launched','launching','make','makes','made','making','need','needs','needed','needing','plan','plans','planned','planning','request','requests','requested','requesting','specify','specifies','specified','specifying','task','tasks','tasked','tasking','update','updates','updated','updating','want','wants','wanted','wanting','would')) {
        $set.Add($word) | Out-Null
    }
    return $set
}

function Add-UniqueToken {
    param(
        [System.Collections.Generic.List[string]]$List,
        [string]$Token,
        [System.Collections.Generic.HashSet[string]]$Stopwords
    )
    if ([string]::IsNullOrWhiteSpace($Token)) { return }
    $tokenLower = $Token.ToLowerInvariant()
    if ($Stopwords.Contains($tokenLower)) { return }
    if (-not $List.Contains($tokenLower)) { $List.Add($tokenLower) | Out-Null }
}

function Get-SlugTokens {
    param(
        [string]$Description,
        [string]$CleanDescription,
        [System.Collections.Generic.HashSet[string]]$Stopwords
    )

    $tokens = [System.Collections.Generic.List[string]]::new()

    foreach ($match in [regex]::Matches($Description, '\b[A-Z0-9]{2,}\b')) {
        Add-UniqueToken -List $tokens -Token $match.Value -Stopwords $Stopwords
    }

    foreach ($match in [regex]::Matches($CleanDescription.ToLowerInvariant(), '\b[a-z0-9]{3,}\b')) {
        Add-UniqueToken -List $tokens -Token $match.Value -Stopwords $Stopwords
    }

    if ($tokens.Count -eq 0) {
        $fallback = Get-SanitizedSlug $CleanDescription
        if (-not [string]::IsNullOrWhiteSpace($fallback)) {
            foreach ($part in $fallback.Split('-', [System.StringSplitOptions]::RemoveEmptyEntries)) {
                Add-UniqueToken -List $tokens -Token $part -Stopwords $Stopwords
                if ($tokens.Count -ge 3) { break }
            }
        }
    }

    if ($tokens.Count -eq 0) {
        $tokens.Add('feature') | Out-Null
    }

    return ($tokens | Select-Object -First 3) -join '-'
}

.
 "$PSScriptRoot/common.ps1"

if ((-not $FeatureDescription -or $FeatureDescription.Count -eq 0) -and [string]::IsNullOrWhiteSpace($Slug)) {
    Write-Error "Usage: ./create-new-feature.ps1 [-Json] [-Slug <name>] <feature description>"
    exit 1
}

$featureDesc = ($FeatureDescription -join ' ').Trim()
if ([string]::IsNullOrWhiteSpace($featureDesc)) { $featureDesc = $Slug }

$stopwords = Get-Stopwords

try { $repoRoot = git rev-parse --show-toplevel 2>$null; $hasGit = ($LASTEXITCODE -eq 0) } catch { $repoRoot = (Get-RepoRoot); $hasGit = $false }

Set-Location $repoRoot

$specsDir = Get-SpecsRoot -RepoRoot $repoRoot
New-Item -ItemType Directory -Path $specsDir -Force | Out-Null

$ticketMatch = [regex]::Match($featureDesc, '([A-Z][A-Z0-9]+-[0-9]+)')
# Preserve original casing for branch names and spec folders
$ticket = if ($ticketMatch.Success) { $ticketMatch.Value } else { $null }

$cleanDesc = $featureDesc -replace 'https?://\S+', ' ' -replace '([A-Z][A-Z0-9]+-[0-9]+)', ' '

if (-not [string]::IsNullOrWhiteSpace($Slug)) {
    $words = Get-SanitizedSlug $Slug
} else {
    $words = Get-SlugTokens -Description $featureDesc -CleanDescription $cleanDesc -Stopwords $stopwords
}

if ([string]::IsNullOrWhiteSpace($words)) { $words = 'feature' }
$words = Get-SanitizedSlug $words
if ([string]::IsNullOrWhiteSpace($words)) { $words = 'feature' }

# Build branch name with JIRA-first approach (no artificial numbering)
if ($ticket) {
    # Use lowercase comparison but preserve original ticket casing in branch name
    $ticketLower = $ticket.ToLowerInvariant()
    if ($words -like "$ticketLower*" -or $words -like "*$ticketLower*") {
        # Slug already contains ticket (in lowercase), replace with original casing
        $branchName = $words -replace [regex]::Escape($ticketLower), $ticket
    } else {
        $branchName = "$ticket-$words"
    }
} else {
    $branchName = $words
}

if ($hasGit) {
    # Check for duplicate branch names (local and remote)
    # Fetch remote branches to ensure we have latest info
    try {
        git fetch --all --prune 2>&1 | Out-Null
    } catch {
        # Ignore fetch errors (e.g., no remote configured)
    }

    # Check if branch already exists locally
    $localBranches = git branch --list $branchName 2>&1
    if ($localBranches -match $branchName) {
        Write-Error "Error: Branch '$branchName' already exists locally."
        Write-Error "Please use a different feature description or -Slug to create a unique branch name."
        exit 1
    }

    # Check if branch exists on remote
    $remoteBranches = git ls-remote --heads origin $branchName 2>&1
    if ($remoteBranches -match $branchName) {
        Write-Error "Error: Branch '$branchName' already exists on remote."
        Write-Error "Please use a different feature description or -Slug to create a unique branch name."
        exit 1
    }

    try {
        git checkout -b $branchName | Out-Null
    } catch {
        Write-Warning "Failed to create git branch: $branchName"
    }
} else {
    Write-Warning "[specify] Warning: Git repository not detected; skipped branch creation for $branchName"
}

# Use Get-FeatureDir to resolve correct path (handles epic--slice → specs/epics/<epic>/<slice>/)
$featureDir = Get-FeatureDir -RepoRoot $repoRoot -Branch $branchName
New-Item -ItemType Directory -Path $featureDir -Force | Out-Null

# Note: spec.md should only be created by /specify command, not during feature creation
$specFile = Join-Path $featureDir 'spec.md'

# Also create request.md for this user request if not present
$requestTemplate = Join-Path $repoRoot '.gobuildme/templates/request-template.md'
if (-not (Test-Path $requestTemplate)) { $requestTemplate = Join-Path $repoRoot 'templates/request-template.md' }
$requestFile = Join-Path $featureDir 'request.md'
if (-not (Test-Path $requestFile)) {
    if (Test-Path $requestTemplate) { Copy-Item $requestTemplate $requestFile -Force } else { Set-Content -Path $requestFile -Value "# Request`n`n> Describe the user request, context, and open questions." }
}

# Set the SPECIFY_FEATURE environment variable for the current session
$env:SPECIFY_FEATURE = $branchName

if ($Json) {
    $obj = [PSCustomObject]@{
        BRANCH_NAME = $branchName
        SPEC_FILE = $specFile
        REQUEST_FILE = $requestFile
        HAS_GIT = $hasGit
    }
    $obj | ConvertTo-Json -Compress
} else {
    Write-Output "BRANCH_NAME: $branchName"
    Write-Output "SPEC_FILE: $specFile"
    Write-Output "REQUEST_FILE: $requestFile"
    Write-Output "HAS_GIT: $hasGit"
    Write-Output "SPECIFY_FEATURE environment variable set to: $branchName"
}
