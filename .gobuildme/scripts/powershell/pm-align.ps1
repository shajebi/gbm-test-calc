# pm-align.ps1 - Create stakeholder alignment checklist with RACI matrix
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$FeatureName
)

$ErrorActionPreference = "Stop"

# Source common utilities
. "$PSScriptRoot\common.ps1"

# =============================================================================
# PM Alignment Setup
# =============================================================================

function Main {
    param([string]$Feature)

    Write-LogInfo "Setting up PM alignment checklist..."

    # Create alignment file
    $alignmentFile = ".gobuildme\specs\$Feature\alignment-checklist.md"
    $specDir = Split-Path -Parent $alignmentFile
    New-Item -ItemType Directory -Path $specDir -Force | Out-Null

    Write-LogSuccess "Created alignment workspace: $specDir"

    # Check prerequisites
    Test-Prerequisites -Feature $Feature

    # Create alignment template
    New-AlignmentTemplate -File $alignmentFile -Feature $Feature

    Write-LogInfo ""
    Write-LogSuccess "✅ PM Alignment checklist initialized!"
    Write-LogInfo ""
    Write-LogInfo "Feature: $Feature"
    Write-LogInfo "Checklist: $alignmentFile"
    Write-LogInfo ""
    Write-LogInfo "Next: Follow /gbm.pm.align to obtain stakeholder sign-offs"
}

function Test-Prerequisites {
    param([string]$Feature)

    Write-LogInfo "Checking prerequisites..."

    $baseDir = ".gobuildme\specs\$Feature"

    if (-not (Test-Path "$baseDir\prd.md")) {
        Write-LogWarning "Warning: No PRD found"
    } else {
        Write-LogSuccess "  ✓ PRD exists"
    }

    if (-not (Test-Path "$baseDir\stories")) {
        Write-LogWarning "Warning: No stories found"
    } else {
        Write-LogSuccess "  ✓ Stories exist"
    }
}

function New-AlignmentTemplate {
    param(
        [string]$File,
        [string]$Feature
    )

    $content = @'
# Stakeholder Alignment Checklist

**Feature:** [Feature name]
**PM Owner:** [Your name]
**Date:** [YYYY-MM-DD]

---

## Stakeholders

| Role | Name | Sign-Off | Status |
|------|------|----------|--------|
| Engineering Lead | [Name] | ✅ Yes | ⏳ Pending |
| Design Lead | [Name] | ✅ Yes | ⏳ Pending |
| QA Lead | [Name] | ✅ Yes | ⏳ Pending |
| Security Lead | [Name] | ✅ Yes | ⏳ Pending |

---

## RACI Matrix

| Activity | PM | Eng | Design | QA | Security |
|----------|----|----|--------|----|----|
| PRD | A | C | C | C | C |
| Development | C | A,R | I | I | I |
| Testing | C | C | I | A,R | C |

---

## Alignment Meetings

### Engineering (60 min)
- [ ] Technical approach agreed
- [ ] Timeline realistic
- [ ] Resources confirmed

**Sign-Off:** __________ Date: __________

### Design (45 min)
- [ ] Design assets ready
- [ ] Accessibility met

**Sign-Off:** __________ Date: __________

### QA (30 min)
- [ ] Test strategy defined

**Sign-Off:** __________ Date: __________

### Security (30 min)
- [ ] Security review complete

**Sign-Off:** __________ Date: __________

---

## GO/NO-GO

| Criteria | Status |
|----------|--------|
| All sign-offs obtained | [✅/❌] |
| Concerns resolved | [✅/❌] |
| Resources allocated | [✅/❌] |

**Decision:** [GO / NO-GO]

**Next:** Run `/gbm.pm.handoff` if GO

---

**Version:** 1.0
**Status:** [Draft / Aligned]
'@

    Set-Content -Path $File -Value $content
    Write-LogSuccess "Created: alignment-checklist.md"
}

# =============================================================================
# Execute
# =============================================================================

Main -Feature $FeatureName
