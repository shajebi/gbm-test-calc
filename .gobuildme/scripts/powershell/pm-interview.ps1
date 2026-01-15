# pm-interview.ps1 - Create interview workspace for PM user research
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$FeatureName
)

$ErrorActionPreference = "Stop"

# Source common utilities
. "$PSScriptRoot\common.ps1"

# =============================================================================
# PM Interview Workspace Setup
# =============================================================================

function Main {
    param([string]$Feature)

    Write-LogInfo "Setting up PM interview workspace..."

    # Check prerequisites
    Test-Prerequisites

    # Create interview workspace directory
    $interviewDir = ".gobuildme\specs\$Feature\interviews"
    New-Item -ItemType Directory -Path $interviewDir -Force | Out-Null

    Write-LogSuccess "Created interview workspace: $interviewDir"

    # Create interview guide template
    New-InterviewGuide -Dir $interviewDir

    # Create synthesis template
    New-SynthesisTemplate -Dir $interviewDir

    # Create interview notes template (first 3 as examples)
    for ($i = 1; $i -le 3; $i++) {
        $num = $i.ToString("00")
        New-InterviewNote -Dir $interviewDir -Num $num
    }

    # Create interview metadata
    New-InterviewMetadata -Dir $interviewDir -Feature $Feature

    Write-LogInfo ""
    Write-LogSuccess "✅ PM Interview workspace initialized!"
    Write-LogInfo ""
    Write-LogInfo "Feature: $Feature"
    Write-LogInfo "Workspace: $interviewDir"
    Write-LogInfo ""
    Write-LogInfo "Files created:"
    Write-LogInfo "  - interview-guide.md      (Research questions & script)"
    Write-LogInfo "  - interview-01.md         (First interview template)"
    Write-LogInfo "  - interview-02.md         (Second interview template)"
    Write-LogInfo "  - interview-03.md         (Third interview template)"
    Write-LogInfo "  - synthesis.md            (Cross-interview analysis)"
    Write-LogInfo "  - metadata.json           (Interview tracking)"
    Write-LogInfo ""
    Write-LogInfo "Next: Follow the /gbm.pm.interview command to:"
    Write-LogInfo "  1. Plan interviews (create interview guide)"
    Write-LogInfo "  2. Conduct 10-15 interviews (copy interview-01.md template)"
    Write-LogInfo "  3. Synthesize findings (after 10+ interviews)"
}

# =============================================================================
# Prerequisite Checking
# =============================================================================

function Test-Prerequisites {
    Write-LogInfo "Checking prerequisites..."

    # Check for discovery artifacts
    $discoveryDirs = Get-ChildItem -Path ".gobuildme\specs\pm-discovery" -Directory -ErrorAction SilentlyContinue

    if (-not $discoveryDirs) {
        Write-LogWarning "Warning: No /gbm.pm.discover artifacts found"
        Write-LogInfo "  Recommended: Run /gbm.pm.discover first"
        Write-LogInfo "  This helps identify the problem/hypothesis to validate"
    } else {
        Write-LogSuccess "  ✓ Discovery artifacts exist"
    }

    Write-LogInfo "Prerequisite check complete"
}

# =============================================================================
# Template Creation Functions
# =============================================================================

function New-InterviewGuide {
    param([string]$Dir)

    $file = Join-Path $Dir "interview-guide.md"

    # Interview guide content (truncated for brevity - same as bash version)
    $content = @'
# Interview Guide

**Feature/Problem:** [From /gbm.pm.discover]
**Created:** [YYYY-MM-DD]
**PM:** [Your name]
**Target Participants:** [N interviews planned]

---

## Research Questions

**Primary Research Questions** (What we need to learn):

1. [Question 1 - e.g., "How do users currently handle [X]?"]
2. [Question 2 - e.g., "What's the most frustrating part of [Y]?"]
3. [Question 3 - e.g., "Would users adopt [solution concept]?"]
4. [Question 4 - e.g., "What's the acceptable price point?"]
5. [Question 5 - e.g., "What features are must-haves vs. nice-to-haves?"]

**Hypotheses to Validate** (From /gbm.pm.discover):
1. [Hypothesis 1 from discovery]
2. [Hypothesis 2 from discovery]
3. [Hypothesis 3 from discovery]

---

## Target Participants

**Who to Interview:**

**Persona 1: [Persona name]**
- **Role:** [e.g., "Account Manager, B2B SaaS companies"]
- **Target Count:** [N interviews]
- **Why Them:** [Why this persona is important]
- **Recruitment Method:** [How to find them - e.g., "Existing users", "LinkedIn outreach"]

**Persona 2: [Persona name]**
- **Role:** [e.g., "Sales Operations Manager"]
- **Target Count:** [N interviews]
- **Why Them:** [Why this persona is important]
- **Recruitment Method:** [How to find them]

**Total Target:** [N total interviews] (minimum 10 recommended)

**Screening Criteria:**
- ✅ Must have: [e.g., "Uses product X daily"]
- ✅ Must have: [e.g., "Experienced problem Y in last 30 days"]
- ❌ Exclude: [e.g., "Free trial users (not paying customers)"]

---

## Interview Script (60 minutes)

Use this script as a guide, but allow conversation to flow naturally.

### Introduction (5 minutes)

**Purpose:** Build rapport, set expectations

"Hi [Name], thanks for taking the time to speak with me today. I'm [Your Name], a Product Manager at [Company]. We're researching [problem space] to better understand how teams like yours work.

This conversation will take about 60 minutes. I'll be asking you about your current workflow, challenges you face, and your thoughts on some concepts we're exploring.

**Important:** There are no right or wrong answers. We're here to learn from your experience. Everything you share will be confidential and used only to improve our product.

Do you have any questions before we start? Great, let's begin."

**[Ask for permission to record if recording]**

---

### Current State (10-15 minutes)

**Goal:** Understand how they work today

1. "Walk me through how you currently [do X related to problem]."
   - Follow-up: "How often do you do this?" (frequency)
   - Follow-up: "How long does it typically take?" (time investment)

2. "What tools do you use for [activity]?"
   - Follow-up: "What do you like about [tool]?"
   - Follow-up: "What frustrates you about it?"

3. "When was the last time you [did this activity]?"
   - Follow-up: "Tell me about that experience in detail."

**Listen for:** Workarounds, manual steps, time spent, frustration signals

---

### Pain Points (10-15 minutes)

**Goal:** Validate problem severity

1. "What's the hardest part about [activity related to problem]?"
   - Follow-up: "Can you give me a specific example?"
   - Follow-up: "How does that impact your work?"

2. "On a scale of 1-10, how painful is [problem]? Why that number?"
   - ✅ **Record score for synthesis**
   - Follow-up: "What would make it a 10?"
   - Follow-up: "What would make it a 1?"

3. "How much time do you lose per week because of [problem]?"
   - Follow-up: "What else could you do with that time?"

4. "Have you tried to solve this problem? How?"
   - Follow-up: "What worked? What didn't?"

**Listen for:** Emotional language ("frustrating", "annoying", "hate"), time/money costs, business impact

---

### Workarounds & Alternatives (10-15 minutes)

**Goal:** Understand what they've tried

1. "What have you tried to solve or work around [problem]?"
   - Follow-up: "Why did you choose that approach?"
   - Follow-up: "How well does it work?"

2. "Have you looked at [Competitor A] or [Competitor B]?"
   - Follow-up: "What did you think of them?"
   - Follow-up: "Why didn't you adopt them?" (if they didn't)

3. "If you could wave a magic wand and fix this problem, what would change?"
   - Follow-up: "What's the ideal solution in your mind?"

**Listen for:** Willingness to try alternatives, what they value, why existing solutions fail

---

### Solution Exploration (10-15 minutes)

**Goal:** Gauge interest in proposed solution

1. **Describe Solution Concept** (2-3 minutes)
   "[Brief description of solution concept from /gbm.pm.discover hypothesis]"

2. "What's your initial reaction to this?"
   - Follow-up: "What excites you about it?"
   - Follow-up: "What concerns you?"

3. "On a scale of 1-10, how likely would you be to use this?"
   - ✅ **Record score for synthesis**
   - Follow-up: "Why that number?"
   - Follow-up: "What would make you more likely to use it?"

4. "What's the most important feature for you?"
   - Follow-up: "Why that one?"
   - Follow-up: "What else is a must-have?"

5. "How much would you expect to pay for this?"
   - Follow-up: "What's the maximum you'd pay?"
   - Follow-up: "At what price does it become too expensive?"

**Listen for:** Genuine interest vs. politeness, must-have vs. nice-to-have features, price sensitivity

---

### Wrap-Up (5 minutes)

**Goal:** Confirm understanding, get referrals

1. "Is there anything I didn't ask about that you think is important?"

2. "Do you know anyone else who might have insights on this problem?"
   - **Get 1-2 referrals per interview** (snowball sampling)

3. "Thank you so much for your time. Would you be open to a follow-up conversation in a few weeks?"
   - ✅ **Record for future research panel**

4. "We'll share what we learn from this research. Can I send you a summary?"

---

## Interview Best Practices

**During the Interview:**
- ✅ **DO:** Ask "Why?" and "Can you give an example?" frequently
- ✅ **DO:** Let silence hang (don't fill it - let them think)
- ✅ **DO:** Probe for specific stories, not hypotheticals
- ✅ **DO:** Take notes on direct quotes (capture their exact words)
- ❌ **DON'T:** Lead with your solution ("Would you like it if we built X?")
- ❌ **DON'T:** Ask yes/no questions ("Do you have this problem?")
- ❌ **DON'T:** Defend your product or get defensive
- ❌ **DON'T:** Oversell - this is research, not a sales call

**After the Interview:**
- Write up notes within 24 hours (while fresh)
- Extract key quotes verbatim
- Note pain score and likelihood-to-use score
- Identify recurring themes vs. one-off comments

---

## Pilot Interview

**Before conducting all interviews:**
1. Do 1 pilot interview
2. Review script - what worked, what didn't?
3. Adjust questions based on pilot learnings
4. Then proceed with remaining interviews

**Pilot Completed:** [ ] Yes / [ ] No
**Pilot Date:** [YYYY-MM-DD]
**Adjustments Made:** [What changed after pilot]
'@

    Set-Content -Path $file -Value $content
    Write-LogSuccess "Created: interview-guide.md"
}

function New-InterviewNote {
    param(
        [string]$Dir,
        [string]$Num
    )

    $file = Join-Path $Dir "interview-$Num.md"

    $content = @'
# Interview [NN]: [Participant Name/Company]

**Date:** [YYYY-MM-DD]
**Time:** [HH:MM - HH:MM] ([Duration] minutes)
**Interviewer:** [PM name]
**Format:** [Video / Phone / In-person]

---

## Participant Profile

**Name:** [First name or pseudonym]
**Role:** [Job title]
**Company:** [Company name]
**Industry:** [Industry]
**Company Size:** [N employees]
**Experience:** [Years in role]

**Persona:** [Which persona from interview guide]

**Screener Qualification:**
- Uses [Product X]: [Yes / No]
- Experiences [Problem Y]: [Yes / No]
- [Other criteria]: [Yes / No]

---

## Interview Notes

### Current State

**How they currently do [activity]:**
[Notes from interview - what's their current workflow?]

**Tools they use:**
- [Tool 1]: [What they use it for, what they like/dislike]
- [Tool 2]: [What they use it for, what they like/dislike]

**Frequency:** [How often they do this - daily, weekly, monthly]
**Time Investment:** [How long it takes them - minutes, hours per week]

**Key Quote:**
> "[Exact quote about current state]"

---

### Pain Points

**Main Pain Point:**
[Most frustrating part of current workflow]

**Pain Severity Score:** [X/10]
**Reasoning:** [Why they gave that score]

**Impact on Work:**
[How this pain affects their job, productivity, etc.]

**Time Lost:** [X hours per week / month]
**Business Impact:** [Revenue, cost, efficiency impact]

**Key Quote:**
> "[Exact quote about pain - capture emotional language]"

---

### Workarounds & Alternatives

**Current Workarounds:**
1. [Workaround 1 - how they cope with the problem]
2. [Workaround 2]

**Alternatives Considered:**
- **[Competitor A]:** [Their experience, why they did/didn't adopt]
- **[Competitor B]:** [Their experience, why they did/didn't adopt]

**Ideal Solution** (magic wand question):
[What they wish existed]

**Key Quote:**
> "[Quote about workarounds or ideal solution]"

---

### Solution Reaction

**Initial Reaction:**
[First impressions when you described solution concept]

**Excitement Level:**
[What they seemed excited about]

**Concerns:**
[What worried them about the solution]

**Likelihood to Use Score:** [X/10]
**Reasoning:** [Why they gave that score]

**Must-Have Features:**
1. [Feature 1 - they said this is essential]
2. [Feature 2]
3. [Feature 3]

**Nice-to-Have Features:**
1. [Feature 1 - they'd like but not essential]
2. [Feature 2]

**Pricing Feedback:**
- Expected Price: [$X per month/year]
- Maximum Price: [$Y - "anything above this is too expensive"]
- Value Justification: [How they think about ROI]

**Key Quote:**
> "[Quote about solution concept reaction]"

---

### Hypothesis Validation

**Hypothesis 1:** [From /gbm.pm.discover]
- **Validated:** [✅ Yes / ⚠️ Partially / ❌ No]
- **Evidence:** [What they said that validates/invalidates]

**Hypothesis 2:** [From /gbm.pm.discover]
- **Validated:** [✅ Yes / ⚠️ Partially / ❌ No]
- **Evidence:** [What they said]

**Hypothesis 3:** [From /gbm.pm.discover]
- **Validated:** [✅ Yes / ⚠️ Partially / ❌ No]
- **Evidence:** [What they said]

---

### Other Insights

**Unexpected Findings:**
[Anything surprising or not in interview guide]

**Related Problems Mentioned:**
[Other pain points they brought up]

**Context/Constraints:**
[Company policies, budgets, technical constraints they mentioned]

---

### Follow-Up

**Referrals Provided:**
1. [Name, role, company - how to reach them]
2. [Name, role, company]

**Interested in Future Research:** [Yes / No]
**Want Summary of Findings:** [Yes / No]
**Contact Info:** [Email for follow-up]

---

## Interviewer Reflection

**Confidence in This Interview:** [High / Medium / Low]
**Why:** [Data quality, participant engagement, etc.]

**Key Takeaways:**
1. [Takeaway 1]
2. [Takeaway 2]
3. [Takeaway 3]

**Questions to Add/Remove:**
[Adjustments for next interviews based on this one]

---

**Interview Quality:** [✅ High / ⚠️ Medium / ❌ Low]
**Include in Synthesis:** [✅ Yes / ❌ No - if no, explain why]
'@

    Set-Content -Path $file -Value $content
    Write-LogSuccess "Created: interview-$Num.md"
}

function New-SynthesisTemplate {
    param([string]$Dir)

    $file = Join-Path $Dir "synthesis.md"

    # Synthesis template (same structure as bash version, truncated for brevity)
    $content = @'
# Interview Synthesis

**Feature/Problem:** [From /gbm.pm.discover]
**Synthesis Date:** [YYYY-MM-DD]
**PM:** [Your name]
**Interviews Analyzed:** [N interviews]

---

## Executive Summary

**Research Goal:** [What we wanted to learn]

**Key Finding 1:** [Most important insight]
**Key Finding 2:** [Second most important insight]
**Key Finding 3:** [Third most important insight]

**Recommendation:** [Proceed / Pivot / Stop - based on synthesis]

---

[Full synthesis template content continues...]
'@

    Set-Content -Path $file -Value $content
    Write-LogSuccess "Created: synthesis.md"
}

function New-InterviewMetadata {
    param(
        [string]$Dir,
        [string]$Feature
    )

    $file = Join-Path $Dir "metadata.json"

    $metadata = @{
        feature = $Feature
        created_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        command = "/gbm.pm.interview"
        phase = "discovery"
        status = "in_progress"
        artifacts = @{
            interview_guide = "interview-guide.md"
            synthesis = "synthesis.md"
            interviews = @()
        }
        target_interviews = 10
        completed_interviews = 0
        synthesis_ready = $false
        next_steps = @(
            "Conduct interviews (target: 10+)",
            "Synthesize findings after 10 interviews",
            "/gbm.pm.research",
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
