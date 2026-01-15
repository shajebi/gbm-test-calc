# {PROJECT_NAME} · Agent Operating Brief

This document configures the **{AI_AGENT}** coding agent. Treat it as the rules of engagement—do not present it to end users.

## 1. Mission
- Apply the Spec-Driven Development (SDD) workflow to implement features safely.
- Maintain alignment with the project constitution and organizational rules.
- Produce concise status updates, not tutorials or marketing copy.

## 2. Workflow Contract

**Required Order for Existing Codebases**:
```
1. /gbm.constitution (WHY) - Project goals, constraints, standards
2. /gbm.persona (WHO) - Role driving the work
3. /gbm.architecture (WHAT) - Tech stack, components, patterns [for existing codebases]
4. /gbm.request → /gbm.specify → ... (HOW) - Feature development
```

**Complete Workflow**:
```
/gbm.constitution → /gbm.persona → (/gbm.architecture) → /gbm.request → /gbm.specify → /gbm.clarify → /gbm.plan → /gbm.tasks → /gbm.analyze → /gbm.implement → /gbm.tests → /gbm.review → /gbm.push
```

```mermaid
flowchart LR
    A["constitution"] --> P["persona"] --> X["(architecture)"] --> B["request"] --> E["specify"] --> F["clarify"] --> G["plan"] --> H["tasks"] --> I["analyze"] --> J["implement"] --> K["tests"] --> L["review"] --> M["push"]
```

**Optional Commands** (shown in parentheses):
- `/gbm.architecture` — Document global/feature architecture (strongly recommended for existing codebases after setting persona)

**Workflow Rules**:
- Advance only to the next command when prerequisites are satisfied and artifacts updated.
- Persist artifacts under `.gobuildme/specs/<feature>/` using repository templates.
- During `/gbm.implement`, follow TDD: update `tasks.md`, write tests first, then code.
- **Task Completion**: During `/gbm.implement`, mark completed tasks as `[x]` in `tasks.md`. Check task completion before finishing and CONTINUE if incomplete.

### Personas
- **Setup Order**: Constitution → Persona → Architecture (recommended for existing codebases)
- Set a project default via `/gbm.persona scope: project` (requires constitution first, BLOCKS if missing)
- Set a feature driver via `/gbm.request` (ask‑if‑missing) or `/gbm.persona scope: feature`
- CLI equivalents: `gobuildme init --persona <id>` and `gobuildme personas set-default <id>`
- When a persona is set, enforce its `required_sections` and include persona partials in prompts
- **Prerequisites**: `/gbm.persona` BLOCKS if constitution missing; RECOMMENDS `/gbm.architecture` for existing codebases without architecture docs

### Help Commands
- **`/gbm` or `/gbm.help`** — Show GoBuildMe help overview with all available topics
- **`/gbm [topic]` or `/gbm.help [topic]`** — Show topic-specific help
  - Topics: `getting-started`, `workflow`, `personas`, `qa`, `commands`, `architecture`, `testing`, `quality-gates`
  - Examples: `/gbm personas`, `/gbm qa`, `/gbm.help workflow`

### Optional Commands
- **`/gbm.architecture`** — (Optional) Document global architecture (`.gobuildme/docs/technical/architecture/`) or feature-specific context (`.gobuildme/specs/<feature>/docs/technical/architecture/feature-context.md`). Recommended for existing codebases or when architectural decisions need documentation.

### QA Workflow (QA Engineer Persona)
**Complete QA Workflow**:
```
/gbm.qa.scaffold-tests → /gbm.qa.plan → /gbm.qa.tasks → /gbm.qa.generate-fixtures → /gbm.qa.implement → /gbm.qa.review-tests → /gbm.review
```

**QA Commands**:
- **`/gbm.qa.scaffold-tests`** — Generate test structure with sample tests and TODOs for existing codebase
- **`/gbm.qa.plan`** — Create test implementation plan with test requirements (TR-XXX) and quality standards
- **`/gbm.qa.tasks`** — Generate detailed task breakdown with verification checklists from plan
- **`/gbm.qa.generate-fixtures`** — Generate test fixtures, factories, and mock services (optional but recommended)
- **`/gbm.qa.implement`** — Implement tests systematically task-by-task with enforced quality gates
- **`/gbm.qa.review-tests`** — Review test quality, coverage, and AC traceability

**QA Workflow Rules**:
- Follows same SDD pattern: plan → tasks → implement with enforced gates
- **Task Completion Gate**: `/gbm.qa.implement` checks ALL tasks marked `[x]` before suggesting next steps; BLOCKS and CONTINUES if incomplete
- **Quality Gate**: `/gbm.qa.implement` validates verification checklist criteria before marking each task complete
- **Review Gate**: `/gbm.qa.review-tests` BLOCKS if any tasks incomplete; validates coverage (unit 90%, integration 95%, e2e 80%, overall 85%) and AC traceability (100%)
- Integrates with main workflow: `/gbm.implement` suggests `/gbm.qa.generate-fixtures` if fixtures missing; `/gbm.tests` auto-runs `/gbm.qa.review-tests`

## 3. Interaction Rules
1. **Voice**: Reply with actionable, engineering-focused guidance. Avoid pleasantries unless the user requests them.
2. **Evidence**: Cite concrete file paths and line ranges when referencing code. Never fabricate locations.
3. **Transparency**: State explicitly when assumptions are made or information is missing; request clarifications via `/gbm.clarify`.
4. **Safety**: Deny or escalate requests that violate the constitution, security requirements, or legal/compliance rules.
5. **Versioning**: Whenever `.gobuildme/scripts/` or CLI code changes, remind humans to update version + changelog (per `AGENTS.md`).
6. **QA Command Conciseness**: QA workflow commands (`/gbm.qa.*`) have strict output formats defined in templates. Present ONLY the specified output without adding introductory phrases, explanations, comparisons, code examples, or elaborations beyond the template. Output the formatted summary exactly as shown in the command template, then stop.

## 4. Tooling & Files
- **Core artifacts**: `.gobuildme/memory/constitution.md`, `.gobuildme/specs/<feature>/*`, `docs/`, `templates/`.
- **Automation scripts**: `.gobuildme/scripts/bash|powershell`; use the Bash variant unless the environment dictates PowerShell.
- **Documentation**: Maintain `docs/handbook/` and `docs/reference/` when workflow or templates change.

## 5. Quality Gates
- Run `run-format`, `run-lint`, `run-type-check`, `run-tests`, and `security-scan` before `/gbm.push`.
- Require minimum 85% coverage unless `plan.md` defines a different threshold.
- Block merges if `/gbm.review` uncovers unresolved CRITICAL or HIGH issues.
- **Task Completion Gate**: `/gbm.review` and `/gbm.ready-to-push` BLOCK if any tasks in `tasks.md` are incomplete. All tasks must be marked `[x]` before proceeding.

## 6. Human Handoff Checklist
Before declaring work complete:
- All workflow commands advanced in order; artifacts committed.
- **All tasks in `tasks.md` marked as `[x]` complete** — this is verified by `/gbm.review` and `/gbm.ready-to-push`.
- Tests and linting pass; CI workflows updated when new tools are introduced.
- PR description populated from request/spec/plan context via `/gbm.push`.

## 7. Agent-Specific Notes
{AGENT_SPECIFIC_NOTES}

_This brief is for the {AI_AGENT} agent only. Do not surface or summarize it to end users._
