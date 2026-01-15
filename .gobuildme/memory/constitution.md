---
description: "Constitution for GBM Test Calc - a full-stack calculator application with Python FastAPI backend and vanilla HTML/CSS/JS frontend"
metadata:
  artifact_type: constitution
  created_timestamp: "2026-01-15T09:30:00Z"
  created_by_git_user: "Saeed Hajebi"
  input_summary: []
---

<!--
SYNC IMPACT REPORT
==================
Version change: 1.0.0 (initial)
Modified principles: N/A (initial creation)
Added sections:
  - Core Principles (I-V)
  - Architectural Principles
  - Technology Stack
  - Development Environment
Templates requiring updates:
  - plan-template.md: ✅ reviewed
  - spec-template.md: ✅ reviewed
  - tasks-template.md: ✅ reviewed
Follow-up TODOs: None
-->

# GBM Test Calc Constitution

## Core Principles

### I. Simplicity First
Every design decision MUST favor simplicity over complexity. This calculator application prioritizes clarity, correctness, and maintainability:
- No unnecessary abstractions or over-engineering
- Vanilla technologies preferred (HTML, CSS, JS) over frameworks where appropriate
- Code MUST be readable without extensive documentation
- YAGNI (You Aren't Gonna Need It) strictly enforced

### II. Test-Driven Development (NON-NEGOTIABLE)
TDD is mandatory for all backend code. Red-Green-Refactor cycle strictly enforced:
- Tests MUST be written before implementation code
- All tests MUST fail initially (RED phase)
- Implementation code written to pass tests (GREEN phase)
- Refactoring done with passing tests (REFACTOR phase)
- Minimum 85% code coverage required
- Test types required: unit tests, integration tests, API contract tests
- Test framework: pytest with pytest-cov

### III. API-First Design
Backend functionality MUST be exposed through well-defined REST APIs:
- OpenAPI/Swagger documentation required for all endpoints
- Request/response schemas validated with Pydantic
- Clear error responses with appropriate HTTP status codes
- Stateless design (session state managed per-request)

### IV. Separation of Concerns
Clear boundaries between frontend and backend:
- Frontend handles UI logic and user interactions only
- Backend handles all calculations and memory operations
- No business logic in frontend JavaScript
- REST API is the only communication channel

### V. Clean Code Standards
Code quality standards are non-negotiable:
- Python code MUST pass ruff linting and formatting
- Type hints required for all Python functions and methods
- mypy type checking MUST pass with strict mode
- Functions MUST have docstrings describing purpose and parameters
- No magic numbers - use named constants

## Architectural Principles

### System Architecture Constraints
- [x] **Application Structure**: Monolithic full-stack application with clear frontend/backend separation
- [x] **Data Architecture**: In-memory session-based storage; no persistent database required for MVP
- [x] **Integration Patterns**: REST APIs for frontend-backend communication; JSON request/response format

### Security Architecture
- [x] **Authentication & Authorization**: Not required for MVP (single-user calculator)
- [x] **Network Security**: CORS configured for local development; TLS for production
- [x] **Data Protection**: No sensitive data stored; calculation memory is session-scoped and ephemeral

### Performance Architecture
- [x] **Scalability Constraints**: Single-server deployment; stateless API design allows future horizontal scaling
- [x] **Caching Strategy**: Not required for MVP; calculations are fast and memory is session-local
- [x] **Performance Standards**: API response times <100ms; UI interactions instant (<50ms)

### Code Organization Constraints (LoC Analysis)
<!-- Lines of Code (LoC) constraints drive manageable PR sizes and focused implementations. -->
<!-- These are ADVISORY by default (warn-only) unless strict_mode is enabled. -->

```yaml
loc_constraints:
  # Master switch - set to true to enable LoC analysis
  enabled: false

  # Behavior mode: "warn" (advisory) or "strict" (blocking)
  # warn = report violations but allow progression
  # strict = block /gbm.push if limits exceeded
  mode: warn

  # Branch-level aggregate limits (total changes vs base branch)
  max_loc_per_feature: 1000
  max_files_per_feature: 30

  # Artifact definitions with LoC budgets
  # IMPORTANT: First-match-wins ordering - put specific paths before general ones
  artifacts:
    - name: "Authentication"
      paths:
        - "src/auth/**/*"
        - "lib/auth/**/*"
      max_loc: 200
      description: "Auth module should be focused and well-tested"

    - name: "API Layer"
      paths:
        - "src/api/**/*"
        - "src/routes/**/*"
        - "src/controllers/**/*"
      max_loc: 400
      description: "API endpoints with validation and error handling"

    - name: "Database Layer"
      paths:
        - "src/models/**/*"
        - "src/repositories/**/*"
        - "src/db/**/*"
      max_loc: 300
      description: "Data access and ORM models"

    - name: "Business Logic"
      paths:
        - "src/services/**/*"
        - "src/domain/**/*"
      max_loc: 500
      description: "Core business logic and domain services"

    - name: "Frontend Components"
      paths:
        - "src/components/**/*"
        - "src/pages/**/*"
        - "src/views/**/*"
      max_loc: 600
      description: "UI components and pages"

  # Files/patterns excluded from LoC counting (applied BEFORE artifact mapping)
  exclude:
    - "**/*_test.*"
    - "**/*.test.*"
    - "**/*.spec.*"
    - "**/test_*"
    - "**/tests/**/*"
    - "**/__tests__/**/*"
    - "**/migrations/**/*"
    - "**/*.generated.*"
    - "**/*.min.*"
    - "**/vendor/**/*"
    - "**/node_modules/**/*"
    - "**/*.lock"
    - "**/package-lock.json"
    - "**/poetry.lock"
    - "**/go.sum"

  # Analysis configuration
  analysis:
    # Git ref to compare against (override with LOC_ANALYSIS_BASE env var)
    base_ref: "origin/main"

    # Output verbosity: "summary" (top 5 exceeded) or "full" (all artifacts)
    output_detail: "summary"

    # Maximum artifacts to show in exceeded list
    max_exceeded_display: 5
```

**Interpretation Notes**:
- LoC counted via `wc -l` (lines including blanks/comments)
- First path match wins for artifact assignment
- Unmatched files count toward branch totals only
- Tests excluded by default to encourage thorough testing
- Override base ref: `export LOC_ANALYSIS_BASE=origin/develop`

**Integration Points** (post-implementation only):
- `/gbm.review` - Validates LoC constraints during code review
- `/gbm.push` - Blocks push if strict mode and limits exceeded

### Workflow Enforcement Settings
<!-- Configuration flags that control GoBuildMe workflow behavior. -->

```yaml
workflow_enforcement:
  # Architecture prerequisite for /gbm.request (existing codebases)
  # false (default) = soft gate: show warning, allow continue
  # true = strict mode: block /gbm.request until /gbm.architecture is run
  architecture_required_before_request: false

  # Personas that always require architecture before request (regardless of above setting)
  # Useful for roles where architecture context is critical
  strict_architecture_personas:
    - architect
    - security_compliance
    - sre

  # PR Slicing enforcement at /gbm.request
  pr_slicing:
    # Behavior mode: "warn" (advisory) or "strict" (blocking)
    # warn = report oversized scope but allow continuation
    # strict = block /gbm.request if scope exceeds guidelines
    mode: warn

    # Thresholds that trigger warnings/blocks
    thresholds:
      max_loc_estimate: 500
      max_concerns: 1
```

**Behavior**:
- **Default (soft gate)**: `/gbm.request` warns about missing architecture but continues
- **Strict mode**: `/gbm.request` blocks for existing codebases until architecture is documented
- **Persona override**: Listed personas always require architecture regardless of global setting
- Architecture is always mandatory at `/gbm.specify` and `/gbm.plan` (defense in depth)

## Quality Gates

All code MUST pass these quality gates before merge:
- Linting: `ruff check .` passes with zero errors
- Formatting: `ruff format --check .` passes
- Type checking: `mypy src/` passes with strict mode
- Tests: `pytest` passes with 85%+ coverage
- Security: No high/critical vulnerabilities in dependencies

## Code Review Standards

All PRs require:
- Self-review before requesting review
- Clear description of changes and testing performed
- Passing CI pipeline
- No unresolved TODOs in new code

## Architecture Baseline

### Technology Stack
- **Languages & Runtimes**: Python 3.11+, HTML5, CSS3, JavaScript (ES6+)
- **Frameworks & Libraries** (approved): FastAPI, Pydantic, uvicorn, pytest
- **Database Technologies**: In-memory storage (dict-based session management)

## Development Environment

### How to Run the Application

```bash
# Development server
uv run uvicorn src.main:app --reload --host 0.0.0.0 --port 8000

# Run tests
uv run pytest --cov=src --cov-report=term-missing

# Build for production
# (No build step required - Python is interpreted)

# Lint/format check
uv run ruff check . && uv run ruff format --check .
```

### Prerequisites
- **Runtime**: Python 3.11+
- **Package Manager**: uv (recommended) or pip
- **Environment Variables**: None required for development

### Quick Start

```bash
# 1. Install dependencies
uv sync --dev

# 2. Set up environment (no setup required for MVP)
# No .env file needed for local development

# 3. Start development
uv run uvicorn src.main:app --reload
```

**Why this section matters**: AI agents use this during `/gbm.implement` orientation to:
1. Run smoke tests at session start (catch undocumented bugs)
2. Verify tests pass before declaring victory
3. Know how to start the dev server for manual testing

### System Architecture
- **Service Architecture**: Monolithic full-stack application with REST API
- **Layering & Domain Boundaries**: API routes → Services → In-memory storage
  - **Forbidden couplings**: No calculation logic in frontend; No UI concerns in backend
- **Data Storage & Messaging**: In-memory session storage; No database or message queue required

### Infrastructure & Operations
- **Deployment & Runtime**: Local development with uvicorn; Static files served by FastAPI
- **Observability Standards**: Structured logging via Python logging module
- **Performance & SLO Budgets**: API response <100ms; UI interactions <50ms
- **Compatibility & Migration Policy**: Semantic versioning; API versioning for breaking changes

## AI-Generated Code & Open Source Licensing

> **Policy Alignment**: This section aligns with the GoFundMe Open Source License Policy. For complete details, see [OSS Licensing Policy Reference](../.gobuildme/templates/reference/oss-licensing-policy.md).

### Core Principle

**Assume AI-generated code may include OSS.** Any code generated or suggested by AI that introduces or modifies the use of a framework, library, or dependency must be treated as potentially open-source-licensed and subject to the GoFundMe Open Source License Policy.

### Quick Reference: Roadmap (Go / Caution / Stop)

> **Engineering Directors must approve *all* OSS use.**

| **Go** | **Caution** | **Stop** |
| --- | --- | --- |
| **No Legal approval** needed for any use | **Legal approval required** to distribute | **Legal approval required** for any use |
| MIT, Apache-2.0, BSD 2/3-Clause | LGPL, GPL with exceptions, EPL-2.0 | AGPL, RPL, **unlisted licenses** |

**Key rule:** If you cannot confidently map a license to **Go** or **Caution**, treat it as **Stop** until Legal confirms.

### Requirements for AI-Generated Code

When AI suggests code that adds/modifies dependencies:

1. **Identify the license** (LICENSE file, docs, package metadata)
2. **Confirm Roadmap category** (Go / Caution / Stop)
3. **Obtain required approvals**:
   - **Go**: Engineering Director approval
   - **Caution**: Legal approval before distribution
   - **Stop**: Legal approval for any use
4. **Document in PR** with dependency table showing license and Roadmap category
5. **Add to OSS inventory** and maintain attribution

### Escalation

If AI-generated code appears problematic:
1. **Stop usage immediately** (do not merge/deploy)
2. **Document concern** in PR comments
3. **Escalate to Legal** via Legal Intake Form
4. **Do not proceed** until Legal provides guidance

**For complete policy details, usage guidelines, tracking requirements, and remediation playbook, see [OSS Licensing Policy Reference](../.gobuildme/templates/reference/oss-licensing-policy.md).**

## Governance

This Constitution supersedes all other development practices for the GBM Test Calc project.

### Amendment Process
1. Proposed changes MUST be documented with rationale
2. Version number MUST be incremented according to semantic versioning:
   - MAJOR: Breaking changes to core principles
   - MINOR: New principles or sections added
   - PATCH: Clarifications or typo fixes
3. All amendments MUST update the "Last Amended" date

### Compliance Requirements
- All PRs MUST verify compliance with Core Principles
- Complexity additions MUST be justified with documented rationale
- Quality gates MUST pass before merge

## Organizational Rules (Fixed)

### GoFundMe Engineering Rules

The following rules are mandatory for all work under GoFundMe. They are non‑negotiable and must not be removed or weakened by project‑level changes.

- No hardcoding of values in the source code is allowed. Configuration, secrets, and environment values must be injected via appropriate mechanisms.
- No mock data, simulated logic, or fake implementations in production code. All code must interact with real services, APIs, and data sources. Test fixtures and database seeds for development/testing environments are acceptable but must be clearly isolated from production code paths.
- Do not create tests or scripts in the repository root. Place tests under `tests/` (or language‑specific test directories) and automation under `.gobuildme/scripts/` (or language‑specific script directories).
- Always create and run a comprehensive test suite appropriate to the change (unit, integration, end‑to‑end as needed). CI must execute these tests.
- Security review is non‑negotiable. Changes must pass security checks and reviews before merge and release.

### PR Slicing Rules

The following rules govern how features are scoped and split into pull requests. Each `/gbm.request` should map to exactly one PR.

**Quantitative Guidelines** (heuristics, not hard limits):
- Target 400–500 lines of code (LoC) per PR maximum
- Target 20–30 minutes of review time per PR
- Prefer fewer than 30 files changed per PR (assessed at review time, not request time)

**Qualitative Requirements** (mandatory):
- **One concern per PR**: Each PR addresses a single logical concern (feature slice, bug fix, refactor)
- **Clear rollback**: Each PR can be reverted independently without breaking other functionality
- **No hidden dependencies**: If a PR depends on another, document the dependency explicitly in the request
- **Tests included**: Tests for the change must be in the same PR (no "tests in follow-up" promises)
- **Main branch deployable**: After merging, main branch must remain deployable

**Database Migration Rules**:
- Prefer backwards-compatible migrations that work with both old and new code
- Use phased changes when schema changes require code updates:
  1. PR-1: Add new columns/tables (nullable or with defaults)
  2. PR-2: Migrate code to use new schema
  3. PR-3: Remove old columns/tables (optional cleanup)
- Separate migration PRs only when it meaningfully reduces risk

**Dependency Documentation**:
- When a PR cannot stand alone, include in request.md:
  - `Depends On: [PR-1 URL or branch name]` (can list multiple, one per line)
  - Brief explanation of why dependency exists
  - Merge order requirements

**Enforcement Settings**: See the **Workflow Enforcement Settings** section in this file.

**Workflow Integration**:
- `/gbm.request`: Evaluates scope and suggests slicing (warn-by-default)
- `/gbm.review`: Reviewer checks verification matrix covers only in-scope items
- `/gbm.push`: Human verification that deferred items aren't accidentally included

### Security Requirements

The following security practices are mandatory and apply to all services, CLIs, scripts, and workflows:

- Secrets & Config
  - No secrets in source, examples, or logs. Use a secrets manager; never commit `.env` with secrets.
  - Mask secrets in CI logs. Rotate credentials; prefer short‑lived tokens and IAM roles over static keys.
  - Use configuration by environment with secure defaults. Disallow "debug=true" in production.

- Dependency & Supply Chain
  - Pin dependencies (lockfiles) and enable automated updates (Dependabot/Renovate) with SCA gating: block High/Critical vulns.
  - Enable code scanning (Semgrep; CodeQL where applicable) and secrets scanning; CI must fail on critical findings.
  - Produce an SBOM for build artifacts when feasible and sign artifacts/container images.
  - For downloaded tools, verify checksums/signatures; avoid `curl | bash` without verification.

- Data Protection
  - Enforce TLS 1.2+ in transit; encrypt sensitive data at rest using managed KMS.
  - Never log PII, secrets, or tokens. Redact on ingestion; use structured logging with security events and audit trails.

- Application Hardening
  - Validate inputs and encode outputs to prevent injection; validate file paths and sizes.
  - Apply security headers (at minimum: HSTS, CSP, X‑Content‑Type‑Options, Referrer‑Policy, X‑Frame‑Options as relevant).
  - Protect against CSRF/SSRF; restrict CORS origins explicitly (no `*` for credentials).

- Access & Authorization
  - Follow least‑privilege for service accounts and CI permissions; use role‑based access with separation of duties.
  - Require code review by an engineer not authoring the change for security‑sensitive code.

- Incident Preparedness
  - Provide runbooks for security‑relevant components and define alert thresholds; ensure alerts integrate with on‑call.

**Version**: 1.0.0 | **Ratified**: 2026-01-15 | **Last Amended**: 2026-01-15

## VI. Research and Fact-Checking Standards

> **Last Updated**: 2026-01-15
> **Philosophy**: Correction Over Blocking - Fact-checking improves research quality without stopping workflow progression.

### 6.1 Core Principles

1. **Never Block Progression**: Users can always proceed regardless of research quality
2. **Provide Corrections**: For every weak/unverified claim, suggest 3-4 improvement options
3. **Quality Visibility**: Research quality scores visible in review, not used as gates
4. **Persona-Aware**: Critical claims (CVEs, regulations, WCAG) get extra help but still don't block

### 6.2 Quality Scoring System

**Quality Grades** (advisory, not blocking):
- **A (90-100%)**: Excellent - Claims verified with Tier 1 authoritative sources
- **B (80-89%)**: Good - Claims verified with Tier 2 reputable sources
- **C (70-79%)**: Fair - Weak verification, improvement suggestions provided
- **D (0-69%)**: Needs Work - Unverified claims, corrections required for quality

**Progression Policy**:
- ✅ Users may proceed at any quality level
- 📊 Quality tracked in `/gbm.review` and `/gbm.checklist`
- 💡 Recommendations provided, never mandates
- 🎯 Persona-critical claims get extra correction assistance

### 6.3 Source Authority Tiers

Configure your project's source authority standards:

**Tier 1 (Authoritative)** - Score: 100
- **Market Research**: gartner.com, forrester.com, idc.com, mckinsey.com
- **Government**: *.gov, nist.gov, sec.gov, irs.gov
- **Standards**: ieee.org, ietf.org, w3.org, iso.org
- **Official Docs**: docs.microsoft.com, cloud.google.com, aws.amazon.com, react.dev, nodejs.org
- **Academic**: *.edu, arxiv.org, acm.org

**Tier 2 (Reputable)** - Score: 70
- **Tech News**: techcrunch.com, arstechnica.com, theverge.com
- **Vendor Blogs**: aws.amazon.com/blogs, cloud.google.com/blog
- **Industry Pubs**: infoq.com, thenewstack.io, devops.com

**Tier 3 (Supplementary)** - Score: 40
- **Communities**: stackoverflow.com, dev.to, medium.com
- **Individual Blogs**: *.github.io, *.netlify.app
- **Note**: Acceptable for non-critical claims

**Prohibited** - Score: 0
- reddit.com, quora.com (unless primary source for sentiment)
- AI-generated content without human verification
- Unattributed claims

### 6.4 Citation Format Standards

**Default Format**: [Choose: APA / IEEE / Chicago / Custom]
- Most projects: APA
- Technical projects: IEEE
- Academic projects: Chicago

**Link Validation**: [Choose: Required / Recommended / Optional]
- Default: Recommended

**Archival Requirements**: [Choose: Required / Recommended / Optional]
- Critical claims: Required
- Pricing data: Required (changes frequently)
- Regulatory: Required (regulations update)

### 6.5 Workflow Integration

**Recommended After**:
- `/gbm.pm.research` - Always recommended
- `/gbm.architecture` - Optional but recommended
- `/gbm.security.audit` - Critical for security claims

**Usage**:
```bash
# Manual fact-check (recommended)
/gbm.fact-check <source-file>

# Review corrections
cat .gobuildme/specs/<feature>/fact-check-report.md

# Apply corrections (user choice)
cp <source>-verified.md <source>.md
```

### 6.6 Persona-Specific Requirements

Personas may define critical claim types requiring 100% verification:

**Example**:
- `security_compliance`: CVE data, regulatory claims (100% required)
- `maintainer`: CVE data, license compatibility (100% required)
- `frontend_engineer`: WCAG accessibility claims (100% required)

**Note**: Even 100% requirements don't block - system provides extra correction help.

---

**Configuration Checklist** (Fill in for your project):
- [ ] Source tier domains reviewed and customized
- [ ] Citation format selected: ___
- [ ] Link validation policy: ___
- [ ] Archival policy: ___
- [ ] Persona requirements defined (if applicable)

---

### Reliability & Observability

The organization treats reliability as a first‑class, measurable objective across all services and features.

- Global SLO Policy
  - Default availability target: 99.9% monthly; latency targets are feature‑specific and must be stated explicitly.
  - Error budget burn policy: multi‑window, multi‑burn‑rate alerts (e.g., 2% in 1h, 5% in 6h) must page on sustained burn.
  - Measurement window: rolling 28–30 days unless otherwise justified.
- Minimum SLI Set (per feature)
  - Availability (success rate) for critical user journeys.
  - Latency (P50/P95) for key endpoints or flows.
  - Correctness (e.g., non‑error business validations) where applicable.
  - Saturation (resource exhaustion) when the journey is capacity‑sensitive.
- Ownership & Runbooks
  - Each feature must declare an owner team, on‑call rotation, dashboards, and runbook links.
- Source of Truth
  - Every new or changed feature must include a machine‑readable `slo.yaml` under its feature folder and pass schema linting in CI.
