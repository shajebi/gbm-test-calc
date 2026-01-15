# pm-stories.ps1 - Break down PRD into user stories and create Jira import file
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$FeatureName
)

$ErrorActionPreference = "Stop"

# Source common utilities
. "$PSScriptRoot\common.ps1"

# =============================================================================
# PM Stories Creation
# =============================================================================

function Main {
    param([string]$Feature)

    Write-LogInfo "Setting up PM stories workspace..."

    # Create stories directory
    $storiesDir = ".gobuildme\specs\$Feature\stories"
    New-Item -ItemType Directory -Path $storiesDir -Force | Out-Null

    Write-LogSuccess "Created stories workspace: $storiesDir"

    # Check prerequisites
    Test-Prerequisites -Feature $Feature

    # Create story templates
    New-StoryTemplates -Dir $storiesDir

    # Create Jira import CSV
    New-JiraImport -Dir $storiesDir -Feature $Feature

    # Create README
    New-ReadmeFile -Dir $storiesDir

    # Create metadata
    New-StoriesMetadata -Dir $storiesDir -Feature $Feature

    Write-LogInfo ""
    Write-LogSuccess "✅ PM Stories workspace initialized!"
    Write-LogInfo ""
    Write-LogInfo "Feature: $Feature"
    Write-LogInfo "Workspace: $storiesDir"
    Write-LogInfo ""
    Write-LogInfo "Files created:"
    Write-LogInfo "  - epic-template.md"
    Write-LogInfo "  - jira-import.csv"
    Write-LogInfo "  - README.md"
    Write-LogInfo "  - metadata.json"
    Write-LogInfo ""
    Write-LogInfo "Next: Follow /gbm.pm.stories to break down PRD epics"
}

function Test-Prerequisites {
    param([string]$Feature)

    Write-LogInfo "Checking prerequisites..."

    $baseDir = ".gobuildme\specs\$Feature"

    if (-not (Test-Path "$baseDir\prd.md")) {
        Write-LogWarning "Warning: No /gbm.pm.prd found"
    } else {
        Write-LogSuccess "  ✓ PRD exists"
    }
}

function New-StoryTemplates {
    param([string]$Dir)

    $file = Join-Path $Dir "epic-template.md"
    $content = @'
# Epic Breakdown Template

## Epic: [Epic Name from PRD]

**Priority:** [P0 / P1 / P2]
**Business Value:** [Why this matters]

---

## Story 1: [Title]

**As a** [persona],
**I want to** [action],
**So that** [benefit].

**Acceptance Criteria:**
**Given** [condition], **When** [action], **Then** [outcome].

**Story Points:** [1, 2, 3, 5, 8]
**Component:** [Backend / Frontend]

---

## INVEST Checklist

- [ ] Independent
- [ ] Negotiable
- [ ] Valuable
- [ ] Estimable
- [ ] Small
- [ ] Testable
'@

    Set-Content -Path $file -Value $content
    Write-LogSuccess "Created: epic-template.md"
}

function New-JiraImport {
    param(
        [string]$Dir,
        [string]$Feature
    )

    $file = Join-Path $Dir "jira-import.csv"
    $content = @'
Issue Type,Summary,Description,Priority,Story Points,Epic Link,Component,Labels,Acceptance Criteria
Epic,"[Epic Name]","[Epic description]",High,,,"","feature-name",""
Story,"[Story 1]","As a [persona], I want [action], so that [benefit].",High,5,[Epic Key],Backend,"feature-name","AC1: Given [condition], When [action], Then [outcome]."
'@

    Set-Content -Path $file -Value $content
    Write-LogSuccess "Created: jira-import.csv"
}

function New-ReadmeFile {
    param([string]$Dir)

    $file = Join-Path $Dir "README.md"
    $content = @'
# User Stories & Jira Import

## Jira Import Instructions

1. Open `jira-import.csv`
2. Fill in actual epic/story details from PRD
3. Go to Jira → Issues → Import from CSV
4. Upload file and map columns
5. Verify import

## Story Quality Checklist

- [ ] INVEST criteria met
- [ ] Acceptance criteria testable
- [ ] Story points assigned
- [ ] Stories <8 points

## Next Steps

1. Complete story breakdown
2. Import to Jira
3. Story refinement with engineering
4. Run `/gbm.pm.align`
'@

    Set-Content -Path $file -Value $content
    Write-LogSuccess "Created: README.md"
}

function New-StoriesMetadata {
    param(
        [string]$Dir,
        [string]$Feature
    )

    $file = Join-Path $Dir "metadata.json"
    $metadata = @{
        feature = $Feature
        created_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        command = "/gbm.pm.stories"
        phase = "definition"
        status = "in_progress"
        artifacts = @{
            epic_template = "epic-template.md"
            jira_import = "jira-import.csv"
            readme = "README.md"
        }
        total_epics = 0
        total_stories = 0
        next_steps = @(
            "Break down PRD epics",
            "Import to Jira",
            "/gbm.pm.align"
        )
    }

    $metadata | ConvertTo-Json -Depth 10 | Set-Content -Path $file
    Write-LogSuccess "Created: metadata.json"
}

# =============================================================================
# Execute
# =============================================================================

Main -Feature $FeatureName
