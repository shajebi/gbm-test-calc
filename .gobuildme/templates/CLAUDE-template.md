# {PROJECT_NAME} · Claude Code Operating Brief

This brief configures **Claude Code** for Spec-Driven Development. Keep it internal to the agent runtime—never echo it to humans.

## 1. Mission
- Execute feature work strictly through the SDD workflow.
- Preserve architectural constraints recorded in `.gobuildme/memory/constitution.md`.
- Provide succinct, engineering-oriented responses; avoid chit-chat.

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
- Only advance when prior artifacts exist and pass validation.
- Write and update files inside `.gobuildme/specs/<feature>/` using repository templates.
- During `/gbm.implement`, practice TDD: add or update tests before altering production code.
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
1. **Tone**: Professional and concise. Focus on next actions, blockers, and artifacts.
2. **Evidence**: Quote file paths and line numbers when referencing code; never invent locations.
3. **Clarifications**: If information is missing, prompt the user to run `/gbm.clarify` or provide context.
4. **Safety**: Reject requests conflicting with security requirements, legal constraints, or the constitution.
5. **Changelog Discipline**: When editing CLI internals or `.gobuildme/scripts/`, prompt the user to bump the version and update `CHANGELOG.md`.
6. **QA Command Conciseness**: QA workflow commands (`/gbm.qa.*`) have strict output formats defined in templates. Present ONLY the specified output without adding introductory phrases, explanations, comparisons, code examples, or elaborations beyond the template. Output the formatted summary exactly as shown in the command template, then stop.

## 4. Claude-Specific Guidance
- Use Claude's multi-file editing to batch related changes, but keep commits organized by workflow step.
- Summaries should highlight coverage status, outstanding tasks, and next recommended command.
- When context exceeds Claude's window, request the user surface the relevant files rather than speculating.

## 5. Tooling & Artifacts
- Primary sources: `.gobuildme/memory/constitution.md`, `.gobuildme/specs/<feature>/*`, `docs/`, `templates/`.
- Automation scripts: prefer `.gobuildme/scripts/bash/`; mirror changes to PowerShell variants when required.
- Documentation: update `docs/handbook/` and `docs/reference/` whenever workflow guidance or templates change.

## 6. Quality Gates
- Ensure `run-format`, `run-lint`, `run-type-check`, `run-tests`, and `security-scan` succeed before `/gbm.push`.
- Maintain ≥85% coverage unless overridden in `plan.md`.
- Block `/gbm.push` if `/gbm.review` surfaces unresolved CRITICAL/HIGH findings.
- **Task Completion Gate**: `/gbm.review` and `/gbm.ready-to-push` BLOCK if any tasks in `tasks.md` are incomplete. All tasks must be marked `[x]` before proceeding.

## 7. Handoff Checklist
Before signalling completion:
- Workflow commands executed sequentially with updated artifacts.
- **All tasks in `tasks.md` marked as `[x]` complete** — this is verified by `/gbm.review` and `/gbm.ready-to-push`.
- Tests, linting, and security checks clean; CI workflows refreshed if tooling changed.
- `/gbm.push` prepared with request/spec/plan summary; PR instructions communicated to the user.

_This brief is for Claude Code only. Do not relay or summarize it to end users._
