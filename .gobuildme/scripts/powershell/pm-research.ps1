# pm-research.ps1 - Create research workspace for PM market/competitive/analytics analysis
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$FeatureName
)

$ErrorActionPreference = "Stop"

# Source common utilities
. "$PSScriptRoot\common.ps1"

# =============================================================================
# PM Research Workspace Setup
# =============================================================================

function Main {
    param([string]$Feature)

    Write-LogInfo "Setting up PM research workspace..."

    # Check prerequisites
    Test-Prerequisites -Feature $Feature

    # Create research workspace directory
    $researchDir = ".gobuildme\specs\$Feature\research"
    New-Item -ItemType Directory -Path $researchDir -Force | Out-Null

    Write-LogSuccess "Created research workspace: $researchDir"

    # Create research templates
    New-MarketResearchTemplate -Dir $researchDir
    New-CompetitiveAnalysisTemplate -Dir $researchDir
    New-AnalyticsReportTemplate -Dir $researchDir
    New-TechnicalFeasibilityTemplate -Dir $researchDir
    New-SynthesisTemplate -Dir $researchDir

    # Create research metadata
    New-ResearchMetadata -Dir $researchDir -Feature $Feature

    Write-LogInfo ""
    Write-LogSuccess "✅ PM Research workspace initialized!"
    Write-LogInfo ""
    Write-LogInfo "Feature: $Feature"
    Write-LogInfo "Workspace: $researchDir"
    Write-LogInfo ""
    Write-LogInfo "Files created:"
    Write-LogInfo "  - market-research.md           (Market sizing, trends, segments)"
    Write-LogInfo "  - competitive-analysis.md      (Competitor deep-dives, gaps)"
    Write-LogInfo "  - analytics-report.md          (Data-driven insights)"
    Write-LogInfo "  - technical-feasibility.md     (Engineering assessment)"
    Write-LogInfo "  - synthesis.md                 (Evidence quality, recommendation)"
    Write-LogInfo "  - metadata.json                (Research tracking)"
    Write-LogInfo ""
    Write-LogInfo "Next: Follow the /gbm.pm.research command to:"
    Write-LogInfo "  1. Market research & sizing (TAM/SAM/SOM)"
    Write-LogInfo "  2. Competitive analysis (3+ competitors)"
    Write-LogInfo "  3. Analytics deep-dive (validate with data)"
    Write-LogInfo "  4. Technical feasibility (consult engineering)"
    Write-LogInfo "  5. Synthesize evidence & make recommendation"
}

# =============================================================================
# Prerequisite Checking
# =============================================================================

function Test-Prerequisites {
    param([string]$Feature)

    $baseDir = ".gobuildme\specs\$Feature"

    Write-LogInfo "Checking prerequisites..."

    # Check for interview data
    if (-not (Test-Path "$baseDir\interviews\synthesis.md")) {
        Write-LogWarning "Warning: No /gbm.pm.interview synthesis found"
        Write-LogInfo "  Recommended: Run /gbm.pm.interview first"
        Write-LogInfo "  Research should be informed by user interview findings"
    } else {
        Write-LogSuccess "  ✓ Interview data exists"
    }

    Write-LogInfo "Prerequisite check complete"
}

# =============================================================================
# Template Creation Functions
# =============================================================================

function New-MarketResearchTemplate {
    param([string]$Dir)
    $file = Join-Path $Dir "market-research.md"
    $templateFile = ".gobuildme\templates\pm-market-research-template.md"

    if (-not (Test-Path $templateFile)) {
        Write-LogError "Market research template not found: $templateFile"
        exit 1
    }

    Copy-Item -Path $templateFile -Destination $file
    Write-LogSuccess "Created: market-research.md"
}

function New-CompetitiveAnalysisTemplate {
    param([string]$Dir)
    $file = Join-Path $Dir "competitive-analysis.md"
    $templateFile = ".gobuildme\templates\pm-competitive-analysis-template.md"

    if (-not (Test-Path $templateFile)) {
        Write-LogError "Competitive analysis template not found: $templateFile"
        exit 1
    }

    Copy-Item -Path $templateFile -Destination $file
    Write-LogSuccess "Created: competitive-analysis.md"
}

function New-AnalyticsReportTemplate {
    param([string]$Dir)
    $file = Join-Path $Dir "analytics-report.md"
    $templateFile = ".gobuildme\templates\pm-analytics-report-template.md"

    if (-not (Test-Path $templateFile)) {
        Write-LogError "Analytics report template not found: $templateFile"
        exit 1
    }

    Copy-Item -Path $templateFile -Destination $file
    Write-LogSuccess "Created: analytics-report.md"
}

function New-TechnicalFeasibilityTemplate {
    param([string]$Dir)
    $file = Join-Path $Dir "technical-feasibility.md"
    $templateFile = ".gobuildme\templates\pm-technical-feasibility-template.md"

    if (-not (Test-Path $templateFile)) {
        Write-LogError "Technical feasibility template not found: $templateFile"
        exit 1
    }

    Copy-Item -Path $templateFile -Destination $file
    Write-LogSuccess "Created: technical-feasibility.md"
}

function New-SynthesisTemplate {
    param([string]$Dir)
    $file = Join-Path $Dir "synthesis.md"
    $templateFile = ".gobuildme\templates\pm-synthesis-template.md"

    if (-not (Test-Path $templateFile)) {
        Write-LogError "Synthesis template not found: $templateFile"
        exit 1
    }

    Copy-Item -Path $templateFile -Destination $file
    Write-LogSuccess "Created: synthesis.md"
}

function New-ResearchMetadata {
    param(
        [string]$Dir,
        [string]$Feature
    )
    $file = Join-Path $Dir "metadata.json"
    $metadata = @{
        feature = $Feature
        created_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        command = "/gbm.pm.research"
        phase = "discovery"
        status = "in_progress"
        artifacts = @{
            market_research = "market-research.md"
            competitive_analysis = "competitive-analysis.md"
            analytics_report = "analytics-report.md"
            technical_feasibility = "technical-feasibility.md"
            synthesis = "synthesis.md"
        }
        next_steps = @(
            "Complete market research (TAM/SAM/SOM)",
            "Analyze 3+ competitors",
            "Validate with analytics data",
            "Assess technical feasibility",
            "/gbm.pm.validate-problem"
        )
    }
    $metadata | ConvertTo-Json -Depth 10 | Set-Content -Path $file
    Write-LogSuccess "Created: metadata.json"
}

# =============================================================================
# Execute
# =============================================================================

Main -Feature $FeatureName
