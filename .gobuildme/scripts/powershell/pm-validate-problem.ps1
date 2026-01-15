# pm-validate-problem.ps1 - Create validation checkpoint workspace for final go/no-go decision
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$FeatureName
)

$ErrorActionPreference = "Stop"

# Source common utilities
. "$PSScriptRoot\common.ps1"

# =============================================================================
# PM Problem Validation Checkpoint Setup
# =============================================================================

function Main {
    param([string]$Feature)

    Write-LogInfo "Setting up PM validation checkpoint..."

    # Create validation workspace
    $validationFile = ".gobuildme\specs\$Feature\validation-report.md"
    $validationDir = Split-Path -Parent $validationFile
    New-Item -ItemType Directory -Path $validationDir -Force | Out-Null

    Write-LogSuccess "Created validation workspace: $validationDir"

    # Check prerequisites
    Test-Prerequisites -Feature $Feature

    # Create validation report template
    New-ValidationReport -File $validationFile -Feature $Feature

    # Create validation metadata
    New-ValidationMetadata -Dir $validationDir -Feature $Feature

    Write-LogInfo ""
    Write-LogSuccess "✅ PM Validation checkpoint initialized!"
    Write-LogInfo ""
    Write-LogInfo "Feature: $Feature"
    Write-LogInfo "Workspace: $validationDir"
    Write-LogInfo ""
    Write-LogInfo "Files created:"
    Write-LogInfo "  - validation-report.md         (Comprehensive validation with scorecard)"
    Write-LogInfo "  - validation-metadata.json     (Validation tracking)"
    Write-LogInfo ""
    Write-LogInfo "Next: Follow the /gbm.pm.validate-problem command to:"
    Write-LogInfo "  1. Review all evidence"
    Write-LogInfo "  2. Score 6 dimensions"
    Write-LogInfo "  3. Calculate overall score"
    Write-LogInfo "  4. Make GO/NO-GO/NEED MORE DATA decision"
}

# =============================================================================
# Prerequisite Checking
# =============================================================================

function Test-Prerequisites {
    param([string]$Feature)

    Write-LogInfo "Checking prerequisites..."

    $baseDir = ".gobuildme\specs\$Feature"

    # Check for discovery
    if (-not (Test-Path ".gobuildme\specs\pm-discovery")) {
        Write-LogWarning "Warning: No /gbm.pm.discover session found"
        Write-LogInfo "  Recommended: Run /gbm.pm.discover first"
    } else {
        Write-LogSuccess "  ✓ Discovery session exists"
    }

    # Check for interviews
    if (-not (Test-Path "$baseDir\interviews")) {
        Write-LogWarning "Warning: No /gbm.pm.interview workspace found"
        Write-LogInfo "  Recommended: Run /gbm.pm.interview first"
    } else {
        Write-LogSuccess "  ✓ Interview workspace exists"
    }

    # Check for research
    if (-not (Test-Path "$baseDir\research")) {
        Write-LogWarning "Warning: No /gbm.pm.research workspace found"
        Write-LogInfo "  Recommended: Run /gbm.pm.research first"
    } else {
        Write-LogSuccess "  ✓ Research workspace exists"
    }

    Write-LogInfo "Prerequisite check complete"
}

# =============================================================================
# Template Creation Functions
# =============================================================================

function New-ValidationReport {
    param(
        [string]$File,
        [string]$Feature
    )

    $content = @'
# Problem Validation Report

**Problem/Opportunity:** [From /gbm.pm.discover]
**Validation Date:** [YYYY-MM-DD]
**Product Manager:** [Name]

---

## Executive Summary

**Problem Statement:**
[One-sentence problem]

**Validation Verdict:** [GO / NO-GO / NEED MORE DATA]

---

## Evidence Summary

### Discovery Session
**Opportunity Score:** [X.XX/15]

### User Interviews
**Pain Score:** [X.X/10]
**Likelihood-to-Use:** [X.X/10]

### Market Research
**TAM/SAM/SOM:** [$X/$Y/$Z]

### Competitive Analysis
**Competitors:** [N]
**Gaps:** [N gaps]

### Analytics
**Users Affected:** [N users, X%]
**Impact:** [$X/month]

### Technical Feasibility
**Feasibility:** [YES / YES, BUT / NO]
**Effort:** [X person-weeks]

---

## Validation Scorecard

### Dimension 1: Problem Validation (25%)
**Average:** [X.X/10]
**Result:** [✅/❌ Pass (≥7.0)]

### Dimension 2: Market Opportunity (15%)
**Average:** [X.X/10]
**Result:** [✅/❌ Pass (≥6.0)]

### Dimension 3: Competitive Advantage (15%)
**Average:** [X.X/10]
**Result:** [✅/❌ Pass (≥6.0)]

### Dimension 4: User Demand (25%)
**Average:** [X.X/10]
**Result:** [✅/❌ Pass (≥7.0)]

### Dimension 5: Feasibility & ROI (10%)
**Average:** [X.X/10]
**Result:** [✅/❌ Pass (≥6.0)]

### Dimension 6: Evidence Quality (10%)
**Average:** [X.X/10]
**Result:** [✅/❌ Pass (≥7.0)]

---

## Overall Validation Score

**Overall Score:** [X.X/10]

**Interpretation:**
- 8.0-10.0: **GO**
- 6.0-7.9: **GO** (with de-risking)
- 4.0-5.9: **NEED MORE DATA**
- 0.0-3.9: **NO-GO**

---

## Critical Success Factors

- [ ] Problem is real
- [ ] Problem is frequent
- [ ] Business impact quantified
- [ ] User demand strong
- [ ] Market size adequate
- [ ] Competitive gap identified
- [ ] Technical feasibility confirmed
- [ ] Evidence quality high
- [ ] Assumptions validated
- [ ] Stakeholder alignment

**Met:** [X/10]
**Threshold:** ≥8/10

---

## Final Decision

### ✅ GO
**Proceed to /gbm.pm.prd because:**
1. [Reason 1]
2. [Reason 2]

**Next:** Run `/gbm.pm.prd`

---

### ❌ NO-GO
**Will NOT proceed because:**
1. [Reason 1]
2. [Reason 2]

**Next:** Return to `/gbm.pm.discover`

---

### ⚠️ NEED MORE DATA
**Cannot decide because:**
1. [Gap 1]
2. [Gap 2]

**De-Risking Plan:** [Timeline, actions]

---

**Document Version:** 1.0
**Last Updated:** [YYYY-MM-DD]
'@

    Set-Content -Path $File -Value $content
    Write-LogSuccess "Created: validation-report.md"
}

function New-ValidationMetadata {
    param(
        [string]$Dir,
        [string]$Feature
    )

    $file = Join-Path $Dir "validation-metadata.json"

    $metadata = @{
        feature = $Feature
        created_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        command = "/gbm.pm.validate-problem"
        phase = "discovery"
        status = "validation_pending"
        artifacts = @{
            validation_report = "validation-report.md"
        }
        decision = $null
        overall_score = $null
        next_steps = @()
    }

    $metadata | ConvertTo-Json -Depth 10 | Set-Content -Path $file
    Write-LogSuccess "Created: validation-metadata.json"
}

# =============================================================================
# Execute
# =============================================================================

Main -Feature $FeatureName
