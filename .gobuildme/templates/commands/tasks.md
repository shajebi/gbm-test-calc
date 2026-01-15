---
description: Generate an actionable, dependency-ordered tasks.md for the feature based on available design artifacts.
scripts:
  sh: scripts/bash/check-prerequisites.sh --json
  ps: scripts/powershell/check-prerequisites.ps1 -Json
artifacts:
  - path: "$FEATURE_DIR/tasks.md"
    description: "Dependency-ordered task breakdown with specific file paths and parallel execution guidance. Metadata is automatically recorded for audit trail (created timestamp, author, artifact path)."
  - path: "$FEATURE_DIR/scope.json"
    description: "Scope manifest derived from tasks.md (allowed files/patterns + rationale for each change)."
  - path: "$FEATURE_DIR/verification/verification-matrix.json"
    description: "(Optional) Immutable verification matrix for acceptance criteria tracking and scope drift detection"
  - path: "$FEATURE_DIR/verification/verification-matrix.lock.json"
    description: "(Optional) Lock file with SHA256 hashes for tamper detection in /gbm.review"
---

## Output Style Requirements (MANDATORY)

**Task Descriptions**:
- One-line task descriptions (action + target + file path)
- No explanations of "why" - that's in plan.md
- File paths inline with task, not in separate notes
- Subtask descriptions: 10 words max

**Task Structure**:
- Hierarchical numbering only (1, 1-1, 1-1-1)
- No prose between task groups - use headers
- Parallel markers [P] at end of line, not explained
- Dependencies shown by ordering, not prose explanations

**Phase Headers**:
- Phase name + one-sentence purpose
- No multi-paragraph phase introductions
- No restating TDD principles in each phase
For complete style guidance, see .gobuildme/templates/_concise-style.md


The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

**Script Output Variables**: The `{SCRIPT}` output above provides key paths. Parse and use these values:
- `FEATURE_DIR` - Feature directory path (e.g., `.gobuildme/specs/<feature>/` or `.gobuildme/specs/epics/<epic>/<slice>/`)
- `AVAILABLE_DOCS` - List of available documentation files in the feature directory

1. Track command start:
   - Run `.gobuildme/scripts/bash/get-telemetry-context.sh --track-start --command-name "gbm.tasks" --feature-dir "$FEATURE_DIR" --parameters '{"arguments": $ARGUMENTS}' --quiet` from repo root.
   - **CRITICAL**: Capture the JSON output and extract the `command_id` field. Store this value - you MUST use it in the final step for track-complete.
   - Example: If output is `{"command_id": "abc-123", ...}`, store `command_id = "abc-123"`
   - Initialize error tracking: `script_errors = []`

2. Run `{SCRIPT}` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute.
   - For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

3. **Load All Available Context** (for task generation):

   **3a. Feature-Specific Artifacts** (from request/specify/clarify/plan phases):
   - `$FEATURE_DIR/request.md` - Original user request and assumptions
   - `$FEATURE_DIR/spec.md` - Feature specification with requirements and acceptance criteria
   - `$FEATURE_DIR/plan.md` - **REQUIRED** - Technology stack, libraries, and implementation approach
   - `$FEATURE_DIR/research.md` - Technical decisions and constraints (if exists)
   - `$FEATURE_DIR/data-model.md` - Entity definitions and relationships (if exists)
   - `$FEATURE_DIR/contracts/` - API endpoint specifications (if exists)
   - `$FEATURE_DIR/quickstart.md` - Integration scenarios for test tasks (if exists)
   - `$FEATURE_DIR/docs/references/` - External documentation summaries (if exists)

   **Note**: Not all projects have all documents (CLI tools might not have contracts/, simple libraries might not need data-model.md). Generate tasks based on what's available.

   **3b. Architecture Documentation** (MANDATORY for existing codebases):
   - `.gobuildme/docs/technical/architecture/system-analysis.md` - Architectural patterns, boundaries, layering rules
   - `.gobuildme/docs/technical/architecture/technology-stack.md` - Languages, frameworks, libraries, and approved technologies
   - `.gobuildme/docs/technical/architecture/security-architecture.md` - Auth patterns, security requirements
   - `.gobuildme/docs/technical/architecture/integration-landscape.md` - External service integrations (if exists)
   - `$FEATURE_DIR/docs/technical/architecture/feature-context.md` - Feature-specific architectural context (if exists)

   **BLOCKING**: If codebase exists but architecture files missing → Stop and display: "❌ Architecture required. Run `/gbm.architecture` first."

   **3c. Governance & Principles** (NON-NEGOTIABLE):
   - `.gobuildme/memory/constitution.md` - Organizational rules, security requirements, architectural constraints
   - **CRITICAL**: Constitution defines non-negotiable principles that MUST be enforced
   - Constitutional constraints override user preferences and task planning decisions
   - Any task that conflicts with constitution must be rejected or revised

   **Usage**:
   - **Constitution First**: Constitutional principles are absolute - enforce unconditionally
   - Note architectural boundaries, layering rules, and forbidden couplings for task planning
   - Use technology stack to determine specific implementation tasks
   - Generate tasks that respect architectural patterns and service boundaries
   - Incorporate external references for integration and testing task guidance

4. Generate tasks following the template:
   - Use `.gobuildme/templates/tasks-template.md` as the structural guide
   - Replace ALL placeholder descriptions `{TASK_DESCRIPTION}`, `{SUBTASK_DESCRIPTION}`, `{SUB_SUBTASK_DESCRIPTION}` with actual implementation-specific tasks
   - **CRITICAL**: Agent must determine ALL specific task details based on the feature request:
     * **What** needs to be implemented (specific components, files, functions)
     * **Where** implementation should go (exact file paths and locations)
     * **How** tasks should be broken down (appropriate detail level for complexity)
     * **Dependencies** between tasks and subtasks

5. **Multi-Level Task Breakdown** (CRITICAL):
   - **Use hierarchical numbering**: 1, 1-1, 1-1-1, 1-1-2, 1-2, 2, 2-1, etc.
   - **Break down complex tasks**: If a task involves multiple steps or components, create subtasks
   - **Add detail levels as needed**: Use 3-4 levels deep when complexity requires it
   - **Group related subtasks**: Keep related implementation steps under the same parent task
   - **Include file paths**: Specify exact file paths for each subtask when applicable
   - **Agent determines specificity**: Replace ALL generic placeholders with actual implementation details

6. **Architecture-Aware Task Generation** (MANDATORY):
   - **Follow architectural patterns**: Generate tasks that implement established architectural patterns
   - **Respect technology stack**: Use technologies and frameworks from documented technology stack
   - **Include integration tasks**: Add tasks for integration with existing system components
   - **Security implementation tasks**: Include security tasks based on security architecture patterns
   - **Architectural compliance tasks**: Add tasks to validate architectural boundary compliance

   **Standard Task Rules**:
   - Each contract file → contract test task marked [P]
   - Each entity in data-model → model creation task marked [P]
   - Each endpoint → implementation task (not parallel if shared files)
   - Each user story → integration test marked [P]
   - Different files = can be parallel [P]
   - Same file = sequential (no [P])

   **Architecture-Specific Task Rules**:
   - Integration points → integration implementation and testing tasks
   - Security requirements → authentication/authorization implementation tasks
   - New architectural patterns → pattern implementation and validation tasks
   - External service integrations → integration setup and testing tasks

   **Documentation Task Rules** (MANDATORY):
   - ALWAYS include implementation documentation task as final task in Polish phase
   - Task description: "Create complete implementation documentation in .docs/implementations/<feature>/implementation-summary.md"
   - Dependencies: All implementation tasks must complete before documentation task
   - NOT parallel [P] - must run after everything else is complete
   - File path: .docs/implementations/<feature>/implementation-summary.md
   - Cross-reference: Must link to planning documents in $FEATURE_DIR/ for context

7. **Order tasks by dependencies (MANDATORY TDD Ordering)**:

   **TDD-First Ordering** (enforces test-driven development):
   1. **Setup Phase** - Initialize project structure and dependencies first
   2. **Test Files Phase** (RED) - Create test files with all test cases from spec.md
      - Create test file structure (directory layout)
      - Write all unit test cases (red - they fail)
      - Write all integration test cases (red - they fail)
      - Write all contract test cases (red - they fail)
      - Do NOT implement code yet - tests should FAIL at this point
   3. **Implementation Phase** (GREEN) - Write code to pass tests
      - Create models/entities (to pass unit tests)
      - Create services (to pass integration tests)
      - Create endpoints/APIs (to pass contract tests)
      - Run tests after each component - watch RED → GREEN
   4. **Refactoring Phase** - Improve code while keeping tests passing
      - Extract common patterns
      - Optimize performance
      - Improve readability
      - Verify all tests still pass after refactoring
   5. **Integration Phase** - Cross-component integration
      - Connect components together
      - Add integration tests
      - Test full workflows
   6. **Polish Phase** - Final quality checks
      - Performance optimization
      - Security review
      - Logging and monitoring
   7. **Documentation Phase** - Implementation documentation
      - Document implementation decisions
      - Reference planning documents
      - Create architecture diagrams if needed

   **Key Principle**: Tests are CREATED BEFORE implementation code, not after
   - Models before services (both have tests first)
   - Services before endpoints (both have tests first)
   - Core before integration (both have tests first)

8. Include parallel execution examples:
   - Group [P] tasks that can run together
   - Show actual Task agent commands

9. **Architecture Boundary Validation**:
   - Ensure tasks respect architectural layering (e.g., no services→api dependencies)
   - Validate that implementation tasks don't violate forbidden couplings
   - Check that data model changes include proper migration tasks
   - Verify that integration tasks respect service boundaries
   - Flag any tasks that might require architectural changes or constitutional amendments

9a. Run validation (non-destructive):
    - Execute `scripts/bash/validate-architecture.sh` (or PowerShell twin) from repo root.
    - If validation fails, revise the task plan (or the design) to eliminate boundary violations before proceeding.

9b. **Load Persona-Specific Task Guidance** (if configured):
    - Check if persona is configured: `.gobuildme/config/personas.yaml` for `default_persona`
    - If persona is set: Read corresponding task partial from `.gobuildme/templates/personas/partials/<persona>/tasks.md`
    - Available personas: backend_engineer, frontend_engineer, fullstack_engineer, qa_engineer, data_engineer, data_scientist, ml_engineer, sre, security_compliance, architect, product_manager, maintainer
    - Apply persona-specific task breakdown guidance when generating tasks
    - If no persona configured: Use general task generation approach

10. **Add Metadata Frontmatter** (MANDATORY):
   - When creating tasks.md, ADD this YAML frontmatter structure at the top:

   ```markdown
   ---
   description: "[One-line summary of task breakdown for implementation]"
   metadata:
     feature_name: "[BRANCH_NAME from plan, without special chars]"
     artifact_type: tasks
     created_timestamp: "[GENERATE: Current date/time in ISO 8601 format YYYY-MM-DDTHH:MM:SSZ]"
     created_by_git_user: "[Run: git config user.name - extract the result here]"
     input_summary:
       - "[Task phase 1 or category 1]"
       - "[Task phase 2 or category 2]"
       - "[Task phase 3 or category 3]"
       - "[Continue with 5-10 total task phases/categories]"
   ---

   # [Feature Name] Tasks

   [Rest of tasks content...]
   ```

   **Metadata Field Details:**
   - `feature_name`: Extract from BRANCH_NAME (must match request.md, specify.md, and plan.md)
   - `created_timestamp`: Generate current timestamp in ISO 8601 format with Z suffix
   - `created_by_git_user`: Get from `git config user.name` - use the git username
   - `input_summary`: **CRITICAL - Extract 5-10 key points ONLY from the USER INPUT (not from tasks content):**
     * Review the user input provided when `/gbm.tasks` was invoked (or load from request.md/spec.md/plan.md)
     * Extract the main task breakdown preferences/constraints the user specified
     * Example: If user requested "prioritize unit tests first" → extract "Unit tests must be written before implementation"
     * Example: If user said "parallel tasks for independent components" → extract "Enable parallel execution for independent tasks"
     * **IF user provided NO input to tasks**: Set `input_summary: []` (empty array) or reference plan.md input_summary
     * DO NOT extract from the task phases/categories you created - those are generated content
     * Extract ONLY what the user explicitly asked for in their tasks request
     * Match user requirements, not task structure or breakdown you created

11. Create FEATURE_DIR/tasks.md with:
   - A `## Task Scope (PR Slice Only)` section at the top:
     * Epic Link/Name (optional)
     * PR Slice (`standalone` or `N/M`)
     * “This PR Delivers (In-Scope)” bullets
     * “Deferred to Future PRs (Do Not Implement Here)” bullets
   - **Rule**: tasks.md MUST be slice-scoped so `/gbm.review` can pass honestly for this PR.
   - Correct feature name from implementation plan
   - Numbered tasks (T001, T002, etc.)
   - Clear file paths for each task
   - Dependency notes
   - Parallel execution guidance

12. Create FEATURE_DIR/scope.json (MANDATORY) derived from tasks.md:
   - **Purpose**: Single source of truth for allowed files/patterns during implementation.
   - **Rule**: Only include paths/patterns explicitly referenced in tasks.md.
   - Use repo-relative paths (no leading ./).
   - Do NOT include backups, baselines, or "nice-to-have" cleanup.
   - **Pattern syntax**: Use Python `Path.match` glob syntax. `*` matches within a directory; `**` matches across directories.
   - **Schema**:
     ```json
     {
       "feature": "<feature-name>",
       "generated_from": "$FEATURE_DIR/tasks.md",
       "generated_at": "<ISO-8601 timestamp>",
       "allowed_files": [
         "path/to/existing-file.ext",
         "path/to/new-file.ext"
       ],
       "allowed_patterns": [
         "path/to/dir/**",
         "path/to/*.ext"
       ],
       "rationale": {
         "path/to/existing-file.ext": "Short reason tied to a task",
         "path/to/new-file.ext": "Short reason tied to a task",
         "path/to/dir/**": "Short reason tied to a task"
       }
     }
     ```
   - If a task mentions a directory, use `allowed_patterns` with a glob (e.g., `src/foo/**`).
   - If a task mentions a specific file, list it in `allowed_files`.
   - Keep rationales to one line each, linked to the task that requires the change.
   - **When tasks.md changes, scope.json must be regenerated.**
   - **Validation** (required after generation):
     * Every file path in tasks.md appears in `allowed_files` or matches `allowed_patterns`.
     * No entries exist in scope.json that are not referenced in tasks.md.
     * Every `allowed_files`/`allowed_patterns` entry has a rationale.

Context for task generation: {ARGS}

The tasks.md should be immediately executable - each task must be specific enough that an LLM can complete it without additional context.

13. **Generate Verification Matrix** (OPTIONAL but RECOMMENDED):

   **Purpose**: Create an immutable verification matrix for acceptance criteria tracking and scope drift detection.

   **When to Generate**:
   - For features requiring session handoff across multiple context windows
   - For features with formal acceptance criteria that should not change
   - For PR slices that need scope protection

   **If User Opts In** (or if spec.md has acceptance criteria):

   a. **Create verification matrix** at `$FEATURE_DIR/verification/verification-matrix.json`:
      ```json
      {
        "feature": "<feature-name>",
        "pr_slice": "PR-1: <description from request.md>",
        "epic": "<parent-epic-name if applicable, else null>",
        "persona": "<driver persona from persona.yaml>",
        "created_at": "<ISO timestamp>",
        "verification_items": [
          {
            "id": "V1",
            "type": "acceptance_criteria",
            "description": "<AC from spec.md>",
            "verification_method": {
              "type": "manual",
              "manual_steps": "<steps to verify this AC>"
            },
            "passes": false,
            "verified_at": null,
            "verified_in_session": null,
            "verification_evidence": null
          }
        ]
      }
      ```

   b. **Extract acceptance criteria**:
      - Read `$FEATURE_DIR/spec.md`
      - Find all ACs (AC-001, AC-002, etc.)
      - Create one verification_item per AC
      - Set `type: "acceptance_criteria"` for each

   c. **Set verification methods**:
      - `type: "manual"` — For ACs requiring human verification
      - `type: "builtin"` with `ref: "run_tests"` — For testable ACs
      - `type: "script"` with `ref: ".gobuildme/scripts/bash/..."` — For custom validation

   d. **Create lock file** for immutability enforcement (choose one method):

      **Option A - Manual creation** (always works):
      - Create `$FEATURE_DIR/verification/verification-matrix.lock.json`
      - For each verification_item, compute SHA256 hash of immutable fields only:
        * Include: id, type, description, verification_method
        * Exclude: passes, verified_at, verified_in_session, verification_evidence
      - Store as: `{"version": "1.0", "created_at": "<ISO timestamp>", "feature": "<name>", "item_hashes": {"V1": "sha256:...", ...}}`

      **Option B - CLI creation** (if gobuildme installed):
      ```bash
      gobuildme harness create-lock <feature>
      ```

   e. **Report creation**:
      ```
      ✅ Verification matrix created: $FEATURE_DIR/verification/verification-matrix.json
      ✅ Lock file created: $FEATURE_DIR/verification/verification-matrix.lock.json
      📊 Verification items: X acceptance criteria tracked
      🔒 Matrix is now immutable - changes will be detected in /gbm.review
      ```

   **If Skipped**:
   - Note: "ℹ️ Verification matrix not generated. Session handoff will rely on tasks.md only."
   - This is backwards compatible - existing workflows continue unchanged.

- **CRITICAL**: Use the EXACT `command_id` value you captured in step 1. Do NOT use a placeholder or fake UUID.
14. Track command complete and trigger auto-upload:
    - Prepare results JSON per schema `docs/technical/telemetry-schemas.md#gbm-tasks` (include error details if command failed)
    - Run `.gobuildme/scripts/bash/post-command-hook.sh --command "gbm.tasks" --status "success|failure" --command-id "$command_id" --feature-dir "$SPEC_DIR" --results "$results_json" --quiet` from repo root (add `--error "$error_msg"` if failures occurred)
    - This handles both telemetry tracking AND automatic spec upload (if enabled in manifest)
    - If track-complete fails with "Command ID not found", you used the wrong command_id. Go back and check step 1 output.

## Persona-Aware Next Steps

**Detecting Persona** (always do this):
1. Read: `.gobuildme/config/personas.yaml` → check `default_persona` field
2. Store the value in variable: `$CURRENT_PERSONA`
3. If file doesn't exist or field not set → `$CURRENT_PERSONA = null`

**Next Command**: `/gbm.analyze` (all personas)

**Focus varies by persona** - See `.gobuildme/templates/reference/persona-next-steps.md` for detailed guidance:
- Engineers: Cross-artifact consistency, API/component/pipeline coverage
- QA: Test coverage analysis, AC traceability
- Architect/PM/Maintainer: Architectural decisions, feature completeness, quality gates

### If $CURRENT_PERSONA = null (no persona set)
**Suggested Action**: Run `/gbm.persona` first to set your role and get personalized guidance

**Generic Next Step**: `/gbm.analyze` to validate task breakdown before implementation

## Optional: Spec Repository Upload

After generating `tasks.md`, you can optionally upload the spec directory:

→ `/gbm.upload-spec` - Upload specs to S3 for cross-project analysis and centralized storage

*Requires AWS credentials. Use `--dry-run` to validate access first.*

Next Steps (always print at the end):

⚠️ **Before proceeding, review the generated content:**
- Does it align with your requirements?
- Is all necessary information captured?
- Do the decisions sound correct?

**Running the next command = approval + responsibility acceptance.** No confirmation prompt.

**Not ready?**
- Manually edit `$FEATURE_DIR/tasks.md` to adjust task breakdown
- Re-run `/gbm.plan` if technical approach needs revision
- Run `/gbm.analyze` to identify specific issues first
