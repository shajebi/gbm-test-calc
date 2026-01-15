# pm-handoff.ps1 - Create engineering handoff checklist and kickoff plan
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$FeatureName
)

$ErrorActionPreference = "Stop"

# Source common utilities
. "$PSScriptRoot\common.ps1"

# =============================================================================
# PM Handoff Setup
# =============================================================================

function Main {
    param([string]$Feature)

    Write-LogInfo "Setting up PM engineering handoff..."

    # Create handoff file
    $handoffFile = ".gobuildme\specs\$Feature\handoff-checklist.md"
    $specDir = Split-Path -Parent $handoffFile
    New-Item -ItemType Directory -Path $specDir -Force | Out-Null

    Write-LogSuccess "Created handoff workspace: $specDir"

    # Check prerequisites
    Test-Prerequisites -Feature $Feature

    # Create handoff template
    New-HandoffTemplate -File $handoffFile -Feature $Feature

    Write-LogInfo ""
    Write-LogSuccess "✅ PM Handoff checklist initialized!"
    Write-LogInfo ""
    Write-LogInfo "Feature: $Feature"
    Write-LogInfo "Checklist: $handoffFile"
    Write-LogInfo ""
    Write-LogInfo "Next: Follow /gbm.pm.handoff for formal engineering handoff"
}

function Test-Prerequisites {
    param([string]$Feature)

    Write-LogInfo "Checking prerequisites..."

    $baseDir = ".gobuildme\specs\$Feature"

    if (-not (Test-Path "$baseDir\alignment-checklist.md")) {
        Write-LogWarning "Warning: No alignment checklist found"
        Write-LogInfo "  Recommended: Run /gbm.pm.align first"
    } else {
        Write-LogSuccess "  ✓ Alignment checklist exists"
    }
}

function New-HandoffTemplate {
    param(
        [string]$File,
        [string]$Feature
    )

    $content = @'
# Engineering Handoff Checklist

**Feature:** [Feature name]
**PM Owner:** [Your name]
**Engineering Lead:** [Name]
**Handoff Date:** [YYYY-MM-DD]

---

## Pre-Handoff Verification

- [ ] PRD finalized
- [ ] Stories in Jira
- [ ] Alignment complete
- [ ] Design assets ready
- [ ] Resources allocated
- [ ] All sign-offs obtained

**Ready:** [✅/❌]

---

## Kickoff Meeting (90 min)

**Date:** [YYYY-MM-DD]
**Attendees:** PM, Eng Lead, Engineers, Designer, QA

### Agenda
1. Feature Context (15 min)
2. Solution Overview (20 min)
3. Requirements (20 min)
4. Sprint Plan (15 min)
5. Dependencies & Risks (10 min)
6. Roles & Responsibilities (5 min)
7. Q&A (15 min)

---

## PM Support Plan

**Availability:**
- Slack: <2hr response
- Office Hours: [Day/Time]
- Weekly 1:1: [Day/Time]

**Sprint Ceremonies:**
- Daily Standup: [Time]
- Sprint Planning: [Day/Time]
- Sprint Review: [Day/Time]

---

## Milestones

- [ ] Alpha: [Date]
- [ ] Beta: [Date]
- [ ] GA: [Date]

---

## Handoff Complete

**Sign-Off:**
- PM: __________ Date: __________
- Eng Lead: __________ Date: __________

**Status:** ✅ **DEVELOPMENT IN PROGRESS**

**Good luck, team! 🚀**
'@

    Set-Content -Path $File -Value $content
    Write-LogSuccess "Created: handoff-checklist.md"
}

# =============================================================================
# Execute
# =============================================================================

Main -Feature $FeatureName
