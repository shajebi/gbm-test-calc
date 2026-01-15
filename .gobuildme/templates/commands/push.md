---
description: "Push the reviewed feature branch and open a PR to the base branch. Updates tasks.md to mark Release phase tasks (P1-P3) as complete."
artifacts:
  - path: "(GitHub PR)"
    description: "Pull request created with implementation summary and tracking information"
  - path: "$FEATURE_DIR/tasks.md"
    description: "Updated task breakdown with Release phase tasks (P1-P3) marked complete"
reads:
  - request.md
  - slice-registry.yaml  # For multi-slice epics
updates:
  - slice-registry.yaml  # Marks current slice complete
scripts:
  sh: scripts/bash/push.sh {ARGS}
  ps: scripts/powershell/push.ps1 {ARGS}
---

## Output Style Requirements (MANDATORY)

**PR Description Output**:
- Summary: 3-5 bullets of key changes
- Files changed as collapsible section or table
- Test coverage: single line with percentage
- Deployment notes: numbered steps only
- No restating spec or plan content - link to them

**Pre-push Validation Output**:
- Gate results as table: check | status | details
- Only show failed/warning items in detail
- Pass items as single summary line
For complete style guidance, see .gobuildme/templates/_concise-style.md

---

## Step 0: Orientation (MANDATORY — DO THIS FIRST)

Before ANY work, establish context by running these commands:

```bash
# 1. Resolve repo root (works from any subdirectory)
# Try git first, fallback to searching for .gobuildme/manifest.json
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
  # Non-git project: search upward for .gobuildme/manifest.json
  dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/.gobuildme/manifest.json" ]; then
      REPO_ROOT="$dir"
      break
    fi
    dir=$(dirname "$dir")
  done
fi
[ -z "$REPO_ROOT" ] && REPO_ROOT="$PWD"
cd "$REPO_ROOT"

# 2. Verify GoBuildMe project structure
if [ -d "$REPO_ROOT/.gobuildme/specs/" ]; then
    ls -la "$REPO_ROOT/.gobuildme/specs/"
else
    echo "No specs directory yet (run /gbm.request first)"
fi

# 3. Read progress notes (CRITICAL) — tolerant of missing file
cat "$REPO_ROOT/$FEATURE_DIR/verification/gbm-progress.txt" 2>/dev/null || echo "No progress file yet"

# 4. Review git history
if git rev-parse --git-dir >/dev/null 2>&1; then
    git log --oneline -15
else
    echo "Not a git repository - skipping git history"
fi

# 5. Load task status
cat "$REPO_ROOT/$FEATURE_DIR/tasks.md" 2>/dev/null | head -100

# 6. Count remaining work
grep -c "^\- \[ \]" "$REPO_ROOT/$FEATURE_DIR/tasks.md" 2>/dev/null || echo "0"
```

**DO NOT proceed until you understand**:
- What was completed in previous sessions
- Current task completion status (should be 100% before push)
- Any blockers or issues to be aware of

**If progress notes exist**: Review session history to confirm all work is complete.
**If no progress notes**: Verify all tasks are marked complete in tasks.md before proceeding.

---

## Step 0.5: Immutability Validation (MANDATORY — After Orientation)

**Purpose**: Catch verification matrix tampering between `/gbm.review` and `/gbm.push` (defense in depth).

If `$FEATURE_DIR/verification/verification-matrix.json` exists:

1. Validate matrix integrity:
   ```bash
   gobuildme harness verify-validate <feature>
   ```

2. If validation FAILS (tampering/scope drift detected):
   - STOP — do not push or open a PR
   - Restore the original matrix/lock, or re-run `/gbm.tasks` to regenerate
   - If changes were intentional: `gobuildme harness regenerate-lock <feature>`

If the matrix does NOT exist: skip (opt-in feature).

---

**Script Output Variables**: The `{SCRIPT}` output above provides key paths. Parse and use these values:
- `FEATURE_DIR` - Feature directory path (e.g., `.gobuildme/specs/<feature>/` or `.gobuildme/specs/epics/<epic>/<slice>/`)
- `AVAILABLE_DOCS` - List of available documentation files in the feature directory

1. Track command start:
   - Run `.gobuildme/scripts/bash/get-telemetry-context.sh --track-start --command-name "gbm.push" --feature-dir "$FEATURE_DIR" --parameters '{"arguments": $ARGUMENTS}' --quiet` from repo root.
   - **CRITICAL**: Capture the JSON output and extract the `command_id` field. Store this value - you MUST use it in the final step for track-complete.
   - Example: If output is `{"command_id": "abc-123", ...}`, store `command_id = "abc-123"`
   - Initialize error tracking: `script_errors = []`

2. **Load Persona Configuration** (with Participants Support):

   **Load feature persona file**:
   - Read `$FEATURE_DIR/persona.yaml`
   - Extract `feature_persona` (driver persona ID)
   - Extract `participants` (list of participant persona IDs, may be empty list or missing field)
   - If file missing, fall back to `default_persona` from `.gobuildme/config/personas.yaml`

   **Build active personas list**:
   - Active personas = [driver] + participants
   - Example: If driver=`backend_engineer` and participants=`[security_compliance, sre]`
   - Then active_personas = `[backend_engineer, security_compliance, sre]`
   - If participants empty or missing: active_personas = [driver] only

   **Merge quality gates for /push** (CRITICAL - Final validation before push):
   - For each persona in active_personas:
     * Read `.gobuildme/personas/<persona_id>.yaml`
     * Extract `defaults.quality_gates` list (may not exist for all personas)
     * Collect all gates into a merged list
   - Ensure ALL merged gates pass before allowing push
   - Example merged quality gates:
     * Backend Engineer: ["contracts_present", "migrations_planned"]
     * Security: ["threat_model_present", "data_classification"]
     * SRE: ["slos_defined", "rollback_plan"]
     * Result: All 6 persona gates MUST pass + standard preflight gates

   **Include persona partials**:
   - For each persona in active_personas:
     * If `templates/personas/partials/<persona_id>/push.md` exists:
       - Include its content in PR description generation step
   - If no persona files exist, proceed as generalist

   **Error Handling**:
   - If participant persona file missing: Skip with warning, continue with remaining personas
   - If driver persona file missing: Fall back to default_persona
   - If no valid personas found: Proceed with standard preflight gates only

   **Validation**:
   - Report which personas are active (driver + participants)
   - Show merged quality gates grouped by persona
   - All merged gates must pass for push to succeed

3. **Load All Available Context** (for PR creation and validation):

   **3a. Feature-Specific Artifacts** (for PR description generation):
   - `$FEATURE_DIR/request.md` - Original user request and goals
   - `$FEATURE_DIR/spec.md` - Feature specification with acceptance criteria
   - `$FEATURE_DIR/plan.md` - Implementation plan and technology decisions
   - `$FEATURE_DIR/tasks.md` - Task breakdown and completion status (for validation)
   - `.docs/implementations/<feature>/implementation-summary.md` - Implementation documentation (if exists)
   - `.gobuildme/test-results/quality-review.md` - Test quality review results (if exists)

   **3b. Architecture Documentation** (MANDATORY for existing codebases):
   - `.gobuildme/docs/technical/architecture/system-analysis.md` - Architectural patterns for PR description
   - `.gobuildme/docs/technical/architecture/technology-stack.md` - Technologies used in implementation
   - `.gobuildme/docs/technical/architecture/security-architecture.md` - Security compliance validation
   - `.gobuildme/docs/technical/architecture/integration-landscape.md` - Integration point validation (if exists)
   - `$FEATURE_DIR/docs/technical/architecture/feature-context.md` - Feature architectural impact (if exists)

   **BLOCKING**: If codebase exists but architecture files missing → Stop and display: "❌ Architecture required. Run `/gbm.architecture` first."

   **Skip for**: New/empty projects with no existing source code.

   **3c. Governance & Principles** (NON-NEGOTIABLE):
   - `.gobuildme/memory/constitution.md` - Organizational rules for final PR validation
   - **CRITICAL**: Constitution defines non-negotiable principles for PR approval
   - Constitutional violations must be resolved before pushing
   - PR description must note any architectural decisions and their constitutional compliance

   **Usage**:
   - Generate comprehensive PR description from feature artifacts
   - Validate architectural compliance before pushing
   - Document architectural changes and impacts
   - Ensure constitutional principles are maintained
   - Include test quality and AC coverage in PR description

4. Run `{SCRIPT}` to perform a final preflight with **architecture validation**, push the current feature branch, and open a pull request.

**Architecture-Aware Behavior**:
- **Pre-push Architecture Validation**: Validate architectural compliance before pushing
- **Architecture Change Documentation**: Document any architectural changes in PR description
- **Integration Point Validation**: Ensure integration points work correctly
- **Security Compliance Check**: Validate security implementation follows security architecture
- **Technology Stack Validation**: Confirm use of approved technologies and frameworks

**Standard Behavior**:
- Verifies preconditions: clean git tree; on a feature branch (not main/master/etc.); remote `origin` set; GitHub auth available.
- Runs the local preflight `.gobuildme/scripts/bash/ready-to-push.sh` unless the user passed `--no-verify`.
- Builds a high‑quality PR description from `$FEATURE_DIR/request.md`, `spec.md`, `plan.md`, and `.docs/implementations/<feature>/implementation-summary.md` when present.
- **PR Slice Context (MANDATORY)**: PR description MUST include:
  - Epic Link/Name (if provided)
  - PR Slice (`standalone` or `N/M`)
  - “This PR Delivers (In-Scope)” (from request/spec/plan)
  - “Deferred to Future PRs (Out of Scope)” (from request/spec/plan)
  - **Rule**: If the work is part of an epic, ensure the PR description clearly states what is NOT included in this PR.
- **Includes architecture context**: Adds architectural impact and compliance information to PR description
- **Includes implementation summary**: Adds key implementation details, design decisions, and deployment notes to PR description
- Pushes to `origin` and opens a PR via GitHub CLI (`gh`).

Arguments (optional, pass after `/gbm.push`):
- `--base main` — Target base branch (default: `main`).
- `--draft` — Open PR as draft.
- `--labels "label1,label2"` — Comma‑separated labels.
- `--reviewers "user1,user2"` — Comma‑separated GitHub users.
- `--team-reviewers "org/team1,org/team2"` — Comma‑separated teams.
- `--title "Custom PR title"` — Override default title.
- `--body-file path/to/body.md` — Use a custom body file.
- `--no-verify` — Skip local preflight (format/lint/type/test/security). Not recommended.

**Persona Context**: Loaded in step 2 with participants support. Multiple personas may be active (driver + participants), and their quality gates are merged and validated before push.

---

## CRITICAL: Architecture Documentation Sync Validation (Prevents Stale Docs)

**Purpose**: Validate that architecture documentation was updated during `/gbm.implement` (as required by the "Architecture Documentation Update" step).

> **Note**: Architecture docs should be updated during implementation, not at push time. This check validates that step was completed.

**Validation Steps:**

Run the following validation script to check architecture doc sync:

```bash
#!/usr/bin/env bash
# Architecture Documentation Sync Validation
BASE_BRANCH=${BASE_BRANCH:-main}

# Step 1: Check if architecture docs were updated in this branch (with fallback if no remote)
ARCH_DOCS_CHANGED=$(git diff --name-only "origin/${BASE_BRANCH}...HEAD" 2>/dev/null | grep -E "\.gobuildme/docs/technical/architecture/" || \
                    git diff --name-only "${BASE_BRANCH}...HEAD" 2>/dev/null | grep -E "\.gobuildme/docs/technical/architecture/" || \
                    true)

if [ -n "$ARCH_DOCS_CHANGED" ]; then
  echo "✅ Architecture docs updated:"
  echo "$ARCH_DOCS_CHANGED"
else
  echo "⚠️  No architecture doc changes detected"
fi

# Step 2: Detect if architectural changes were made without doc updates
IMPL_FILES=$(git diff --name-only "origin/${BASE_BRANCH}...HEAD" 2>/dev/null || git diff --name-only "${BASE_BRANCH}...HEAD")

HAS_ARCH_CHANGES=$(echo "$IMPL_FILES" | grep -E "(migration|model|schema|entities|route|api|endpoint|handler|auth|security|guard|service|integration|adapter|external|package\.json|requirements\.txt|go\.mod|Cargo\.toml|pom\.xml|build\.gradle|Gemfile|\.prisma|\.sql|\.graphql|\.pem|\.key)" || true)

if [ -n "$HAS_ARCH_CHANGES" ] && [ -z "$ARCH_DOCS_CHANGED" ]; then
  echo ""
  echo "⚠️  WARNING: Architectural code changes detected but no architecture docs updated!"
  echo "Changed files with architectural impact:"
  echo "$HAS_ARCH_CHANGES"
  echo ""
  echo "Action required: Update architecture docs or confirm changes are internal-only"
fi
```

**If architecture docs are missing updates**:
   - ⚠️ **WARNING**: "Architecture documentation may be outdated"
   - **Option A**: Go back to `/gbm.implement` and complete the "Architecture Documentation Update" step
   - **Option B**: Update docs now before pushing (follow the mapping table below)

### Architecture Change → Doc Mapping

| If implementation changed... | Should have updated... |
|------------------------------|------------------------|
| `migrations/`, `models/`, `schema/`, `**/entities/`, `*.prisma`, `*.sql` | `data-architecture.md` |
| `package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle`, `Gemfile` | `technology-stack.md` |
| `routes/`, `controllers/`, `api/`, `endpoints/`, `**/handlers/`, `*.graphql` | `component-architecture.md` |
| `auth/`, `security/`, `**/middleware/auth*`, `**/guards/`, `*.pem`, `*.key` | `security-architecture.md` |
| `services/`, `clients/`, `integrations/`, `**/external/`, `**/adapters/` | `integration-landscape.md` |

### Architecture Validation Checklist

Before proceeding with push:

- [ ] Ran architecture doc change detection (step 1)
- [ ] If architectural code changes exist, verified corresponding doc updates exist
- [ ] If docs missing, either updated them or confirmed changes are internal-only

### ❌ BLOCK push if:
- Added new database entities WITHOUT updating `data-architecture.md`
- Upgraded dependency versions WITHOUT updating `technology-stack.md`
- Added new API endpoints WITHOUT updating `component-architecture.md`
- Integrated new external services WITHOUT updating `integration-landscape.md`

### ✅ OK to push without doc updates if:
- Changes are purely internal refactoring (no new entities, deps, or APIs)
- Bug fixes that don't change documented behavior
- Test-only changes

**Why this matters**: Issue #51 identified stale architecture docs as a key problem. This validation ensures the mandatory update step in `/gbm.implement` was completed.

---

**CRITICAL Pre-Push LoC Validation** (if enabled in constitution):

5. **Run LoC Analysis** (MANDATORY if `loc_constraints.enabled: true`):
   - Run `.gobuildme/scripts/bash/loc-analysis.sh` (or PowerShell twin) from repo root
   - **If `loc_constraints.enabled: false` or section missing**: Skip with note
   - **If `loc_constraints.mode: warn`**:
     * Display LoC report summary
     * Show advisory warnings for exceeded limits
     * Proceed with push (non-blocking)
   - **If `loc_constraints.mode: strict`**:
     * Display LoC report summary
     * **BLOCK PUSH** if any limits exceeded (branch, files, or artifacts)
     * Error: "❌ Push blocked: LoC limits exceeded. Reduce scope or split into smaller PRs."
     * List exceeded limits with specific over-by amounts
     * Suggest running `/gbm.review` to see full LoC breakdown
   - **Error Tracking**: If script fails, capture error but continue (LoC analysis optional)

**LoC Quality Gate** (based on mode):
- `mode: warn` → 🟡 Advisory (show warnings, allow push)
- `mode: strict` → 🔴 Blocking (deny push if limits exceeded)

**CRITICAL Pre-Push Task Validation** (MANDATORY - MUST RUN BEFORE PUSHING):

1. **Load and Validate ALL Tasks**:
   - Run `{SCRIPT}` to get FEATURE_DIR
   - Load tasks.md from FEATURE_DIR
   - Parse ALL tasks across ALL 10 phases
   - Count total tasks and completed tasks

2. **Phase-by-Phase Validation**:
   - **Phase 1 (Analysis)**: Count tasks starting with A1, A2, A3 - ALL must be `[x]`
   - **Phase 2 (Setup)**: Count numbered tasks 1, 2, 3 - ALL must be `[x]`
   - **Phase 3 (Tests First)**: Count numbered tasks 4, 5 - ALL must be `[x]`
   - **Phase 4 (Core Implementation)**: Count numbered tasks 6-9 - ALL must be `[x]`
   - **Phase 5 (Integration)**: Count numbered tasks 10-12 - ALL must be `[x]`
   - **Phase 6 (Polish)**: Count numbered tasks 13-14, T022-T024 - ALL must be `[x]`
   - **Phase 7 (Reliability & Observability)**: Count tasks R1-R5 - ALL must be `[x]`
   - **Phase 8 (Testing Validation)**: Count tasks T1-T3 - ALL must be `[x]`
   - **Phase 9 (Review)**: Count tasks RV1-RV4 - ALL must be `[x]`
   - **Phase 10 (Release)**: Count tasks P1-P3 - will mark as `[x]` if all previous phases complete

3. **Task Completion Report** (MANDATORY - Display before proceeding):
   ```
   ═══════════════════════════════════════════════════════════
   COMPLETE WORKFLOW TASK VALIDATION
   ═══════════════════════════════════════════════════════════

   Phase 1 (Analysis):           X/Y tasks complete [✓/✗]
   Phase 2 (Setup):              X/Y tasks complete [✓/✗]
   Phase 3 (Tests First):        X/Y tasks complete [✓/✗]
   Phase 4 (Implementation):     X/Y tasks complete [✓/✗]
   Phase 5 (Integration):        X/Y tasks complete [✓/✗]
   Phase 6 (Polish):             X/Y tasks complete [✓/✗]
   Phase 7 (Reliability):        X/Y tasks complete [✓/✗]
   Phase 8 (Testing):            X/Y tasks complete [✓/✗]
   Phase 9 (Review):             X/Y tasks complete [✓/✗]
   Phase 10 (Release):           X/Y tasks complete [✓/✗]

   ───────────────────────────────────────────────────────────
   TOTAL: X/Y tasks complete (Z%)

   Status: [✓ READY TO PUSH / ✗ BLOCKED - INCOMPLETE TASKS]
   ═══════════════════════════════════════════════════════════
   ```

4. **Push Decision Gate**:
   - 🟢 **ALL COMPLETE**: All tasks (Phases 1-9) are `[x]` → Mark Phase 10 tasks complete → Proceed with push
   - 🔴 **INCOMPLETE**: Any tasks `[ ]` in Phases 1-9 → **BLOCK PUSH** → List incomplete tasks → Instruct to complete missing tasks

5. **If Blocked** (any incomplete tasks):
   - List ALL incomplete tasks by phase
   - Output: "❌ Push blocked: X tasks incomplete across Y phases"
   - Suggest which command to run for incomplete phase:
     * Phase 1 incomplete → Run `/gbm.analyze`
     * Phases 2-7 incomplete → Run `/gbm.implement`
     * Phase 8 incomplete → Run `/gbm.tests`
     * Phase 9 incomplete → Run `/gbm.review`
   - **DO NOT PROCEED** with push until all tasks complete

6. **Mark Release Phase Tasks Complete** (ONLY if all Phases 1-9 complete):
   - Find all Phase 10 (Release) tasks (tasks starting with P1, P2, P3)
   - Mark each Release task as complete by changing `[ ]` to `[x]`:
     * P1: Pre-push validation
     * P2: Commit preparation
     * P3: Final quality check
   - Save updated tasks.md
   - Report: "✅ Marked Phase 10 Release tasks complete in tasks.md"

7. **Final Task Summary in Commit/PR**:
   - Include task completion summary in PR description
   - Format: "Completed X tasks across 10 phases (100%)"
   - List phases completed

## Persona-Aware PR Monitoring Guidance

**Detecting Persona** (always do this):
1. Read: `.gobuildme/config/personas.yaml` → check `default_persona` field
2. Store the value in variable: `$CURRENT_PERSONA`
3. If file doesn't exist or field not set → `$CURRENT_PERSONA = null`

**Standard Next Step** (for all personas):
- **Monitor PR and CI**: Review the created PR, ensure CI checks are running, respond to review feedback, and prepare to address any CI failures or blockers before merge.

**Persona-Specific Monitoring Focus Areas** (display based on $CURRENT_PERSONA):

**architect**: Review architectural compliance checks in CI (boundary validation, pattern consistency) · Monitor for architectural feedback from reviewers · Prepare to defend architectural decisions and trade-offs documented in ADRs · Ensure non-functional requirements validation passes in CI/CD · Track architectural impact metrics (complexity, coupling, dependencies)

**backend_engineer**: Monitor API contract validation tests and integration test results in CI · Review performance benchmarks and ensure latency budgets are met · Track database migration execution and rollback safety in staging · Monitor observability instrumentation (metrics, logs, traces) in pre-production · Prepare to address code review feedback on error handling and resilience

**frontend_engineer**: Monitor accessibility audit results and WCAG 2.1 AA compliance checks in CI · Review performance metrics (LCP, FID, CLS) from automated testing · Track visual regression test results and cross-browser compatibility reports · Monitor bundle size impact and ensure performance budgets are maintained · Prepare to address UX feedback from reviewers or stakeholders

**fullstack_engineer**: Monitor both frontend and backend CI checks (API + UI integration tests) · Review end-to-end test results and contract validation across full stack · Track performance metrics spanning API latency and UI rendering · Monitor observability dashboards showing full-stack request flow · Prepare to address integration issues or contract mismatches in staging

**qa_engineer**: Monitor test suite execution results and coverage reports in CI · Review acceptance criteria traceability and ensure all ACs have passing tests · Track non-functional test results (performance, security, load tests) · Monitor for flaky tests or test reliability issues in CI pipeline · Prepare test evidence and quality metrics for release decision-making

**data_engineer**: Monitor data quality checks and contract validation tests in CI · Review backfill/reprocessing dry-run results in staging environment · Track freshness and latency SLA metrics in pre-production monitoring · Monitor pipeline execution for idempotency and error handling robustness · Prepare runbooks and on-call documentation for production rollout

**data_scientist**: Review statistical validation results and reproducibility checks in CI · Monitor metric consistency across analysis artifacts and documentation · Track experimental results and ensure hypothesis testing is properly documented · Prepare to address methodology questions or statistical concerns from reviewers · Verify analysis artifacts (notebooks, reports) are version-controlled and accessible

**ml_engineer**: Monitor offline evaluation metrics and model performance regression tests in CI · Review training/serving parity checks and feature consistency validation · Track model artifact versioning and registry updates · Monitor drift/skew detection and alerting configuration in pre-production · Prepare canary deployment plan and rollback procedures for production

**sre**: Monitor CI/CD pipeline execution and ensure all build/deploy stages pass · Review SLO compliance checks and alert sensitivity validation in staging · Track capacity planning metrics and resource utilization in pre-production · Monitor runbook completeness and on-call documentation accuracy · Prepare rollout plan, rollback procedures, and incident response strategy

**security_compliance**: Monitor security scanning results (SAST, DAST, dependency audits) in CI · Review secrets detection and sensitive data handling validation · Track authentication/authorization test results and access control verification · Monitor compliance checks and ensure regulatory requirements are met · Prepare security sign-off documentation and residual risk assessment

**product_manager**: Review PR description and ensure user stories and acceptance criteria are clearly documented · Track CI status and prepare stakeholder updates on release timeline · Monitor success metrics instrumentation and measurement readiness · Prepare release communication and user-facing documentation updates · Coordinate with stakeholders for final sign-off and deployment approval

**maintainer**: Monitor all CI checks and ensure pipeline is green before merge · Review PR for completeness (release notes, version bumps, ownership updates) · Track code review status and ensure required approvers have signed off · Monitor for merge conflicts or dependencies that might block merge · Prepare merge strategy (squash, rebase, merge commit) and post-merge validation plan

**No persona set** ($CURRENT_PERSONA = null):
- Suggested: Run `/gbm.persona` first to set your role and get personalized guidance
- Default: Follow the standard next step above

- **CRITICAL**: Use the EXACT `command_id` value you captured in step 1. DO NOT use a placeholder or fake UUID.
5. Track command complete:
   - Prepare results JSON per schema `docs/technical/telemetry-schemas.md#gbm-push` (include error details if command failed)
   - Run `.gobuildme/scripts/bash/get-telemetry-context.sh --track-complete --command-id "$command_id" --status "success|failure" --results "$results_json" --quiet` from repo root (add `--error "$error_msg"` if failures occurred)
   - If track-complete fails with "Command ID not found", you used the wrong command_id. Go back and check step 1 output.

Next Steps (always print at the end):

⚠️ **Before proceeding, review the generated content:**
- Does it align with your requirements?
- Is all necessary information captured?
- Do the decisions sound correct?

**Running the next command = approval + responsibility acceptance.** No confirmation prompt.

**Not ready?**
- Run `/gbm.review` to identify remaining issues
- Fix failing tests or quality gate violations
- Run `/gbm.ready-to-push` to check readiness status
- Do NOT push until all quality gates pass

---

## Next PR Slice Guidance (If Part of Epic)

**IMPORTANT**: If this PR is part of a multi-PR epic (PR Slice: N/M where M > 1), inform the user about the next slice:

**After this PR is merged**, check if there are deferred items:

1. **Read the "Deferred to Future PRs" section** from request.md/spec.md/plan.md
2. **If deferred items exist**, display:

```
## Next PR Slice

This PR (PR-[N]/[M]) has been pushed. After merge, continue with the next slice:

**Deferred Items for Next PR**:
[List from "Deferred to Future PRs" section]

**To start PR-[N+1]**:
1. After this PR is merged to main, pull latest: `git checkout main && git pull`
2. Run: `/gbm.request slug:<feature>-pr[N+1]`
3. Reference: "Continue epic [Epic Name], implementing: [first deferred item]"
4. The new request.md will automatically link back to the epic

**Tip**: Keep the same epic link across all slices for traceability.
```

3. **If PR Slice is "standalone" or no deferred items**: Skip this section (single-PR feature complete)

4. **Update Slice Registry** (if multi-slice epic):

   **Locate registry via request.md metadata** (primary):
   - Read current feature's request.md frontmatter
   - Check for `epic_slug` field in metadata
   - If present: Registry at `.gobuildme/specs/epics/<epic_slug>/slice-registry.yaml`

   **Fallback: Infer from path** (if epic_slug missing):
   - If `epic_slug` field is absent but FEATURE_DIR is under `specs/epics/`:
     - Parse path: `specs/epics/<epic>/<slice>/` → extract `<epic>`
     - Registry at `.gobuildme/specs/epics/<epic>/slice-registry.yaml`
   - If FEATURE_DIR is NOT under `specs/epics/`: Standalone feature (no registry)

   **If registry exists**:
   a. Find current slice entry by matching `slice_name` to current slice folder
   b. **If slice found**:
      - Update: `status: in_progress` → `status: complete`
      - Add: `completed_at: "<ISO-8601>"`
      - Save registry
      - Display: `✅ Slice registry updated: <slice_name> marked complete (N/M)`
      - **DO NOT** change status of other slices (next slice stays `planned`)
   c. **If slice NOT found** (guardrail):
      - Display: `⚠️ Current feature not found in slice registry. Skipping registry update.`
      - Continue with push (don't block)

   **If no registry/no epic_slug**: Skip (standalone feature)

5. **Show next planned slice** (from registry, if exists):
   - Find first slice with `status: planned`
   - If found, display:
     ```
     📋 Next slice: <slice_name>
        Scope: <scope_summary>
        Depends on: <depends_on>
        To start: Create branch <epic>--<slice_name> and run /gbm.request
     ```
   - If all slices complete: `🎉 Epic complete! All N slices delivered.`
