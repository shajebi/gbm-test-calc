# pm-prd.ps1 - Create PRD workspace from validated discovery
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$FeatureName
)

$ErrorActionPreference = "Stop"

# Source common utilities
. "$PSScriptRoot\common.ps1"

# =============================================================================
# PM PRD Creation
# =============================================================================

function Main {
    param([string]$Feature)

    Write-LogInfo "Setting up PM PRD workspace..."

    # Create PRD file
    $prdFile = ".gobuildme\specs\$Feature\prd.md"
    $specDir = Split-Path -Parent $prdFile
    New-Item -ItemType Directory -Path $specDir -Force | Out-Null

    Write-LogSuccess "Created PRD workspace: $specDir"

    # Check prerequisites
    Test-Prerequisites -Feature $Feature

    # Create PRD template
    New-PRDTemplate -File $prdFile -Feature $Feature

    # Create PRD metadata
    New-PRDMetadata -Dir $specDir -Feature $Feature

    Write-LogInfo ""
    Write-LogSuccess "✅ PM PRD workspace initialized!"
    Write-LogInfo ""
    Write-LogInfo "Feature: $Feature"
    Write-LogInfo "PRD File: $prdFile"
    Write-LogInfo ""
    Write-LogInfo "Next: Follow the /gbm.pm.prd command to:"
    Write-LogInfo "  1. Complete PRD based on validated discovery"
    Write-LogInfo "  2. Include evidence from interviews and research"
    Write-LogInfo "  3. Define success metrics with baselines"
    Write-LogInfo "  4. Review with stakeholders"
}

function Test-Prerequisites {
    param([string]$Feature)

    Write-LogInfo "Checking prerequisites..."

    $baseDir = ".gobuildme\specs\$Feature"

    if (-not (Test-Path "$baseDir\validation-report.md")) {
        Write-LogWarning "Warning: No /gbm.pm.validate-problem report found"
        Write-LogInfo "  Recommended: Run /gbm.pm.validate-problem first"
    } else {
        Write-LogSuccess "  ✓ Validation report exists"
    }

    if (-not (Test-Path "$baseDir\interviews")) {
        Write-LogWarning "Warning: No interview data found"
    } else {
        Write-LogSuccess "  ✓ Interview data exists"
    }

    if (-not (Test-Path "$baseDir\research")) {
        Write-LogWarning "Warning: No research data found"
    } else {
        Write-LogSuccess "  ✓ Research data exists"
    }

    Write-LogInfo "Prerequisite check complete"
}

function New-PRDTemplate {
    param(
        [string]$File,
        [string]$Feature
    )

    # Copy template from repository
    $templateFile = ".gobuildme\templates\pm-prd-template.md"

    if (-not (Test-Path $templateFile)) {
        Write-LogError "PRD template not found: $templateFile"
        exit 1
    }

    Copy-Item -Path $templateFile -Destination $File -Force
    Write-LogSuccess "Created: prd.md (from template)"
}

function New-PRDMetadata {
    param(
        [string]$Dir,
        [string]$Feature
    )

    $file = Join-Path $Dir "prd-metadata.json"

    $metadata = @{
        feature = $Feature
        created_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        command = "/gbm.pm.prd"
        phase = "definition"
        status = "draft"
        version = "1.0"
        artifacts = @{
            prd = "prd.md"
        }
        next_steps = @(
            "Complete PRD sections",
            "Stakeholder review",
            "/gbm.pm.stories"
        )
    }

    $metadata | ConvertTo-Json -Depth 10 | Set-Content -Path $file
    Write-LogSuccess "Created: prd-metadata.json"
}

# =============================================================================
# Execute
# =============================================================================

Main -Feature $FeatureName
