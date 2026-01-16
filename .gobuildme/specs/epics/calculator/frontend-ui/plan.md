---
description: "Implementation plan for calculator frontend UI with HTML, CSS, JavaScript and API integration"
metadata:
  feature_name: "calculator--frontend-ui"
  artifact_type: plan
  created_timestamp: "2026-01-15T17:35:00Z"
  created_by_git_user: "Saeed Hajebi"
  input_summary:
    - "HTML5 semantic structure for calculator"
    - "CSS3 styling with Flexbox/Grid layout"
    - "Vanilla JavaScript ES6+ for logic"
    - "Fetch API for backend integration"
    - "Session management via localStorage"
---

# Implementation Plan: Calculator Frontend UI

**Branch**: `calculator--frontend-ui` | **Date**: 2026-01-15 | **Spec**: `.gobuildme/specs/epics/calculator/frontend-ui/spec.md`
**Input**: Feature specification from `.gobuildme/specs/epics/calculator/frontend-ui/spec.md`

## Epic & PR Slice Context (Incremental Delivery)

> **Rule**: This plan is for the current PR slice only.

- Epic Name: calculator
- PR Slice: 2 of 3
- Depends On: PR-1 (backend-api) ✅ Complete

### This PR Delivers (In-Scope)
- `static/index.html` — Calculator page with display and button grid
- `static/css/styles.css` — Calculator styling, responsive layout
- `static/js/app.js` — Main entry point, DOM initialization
- `static/js/calculator.js` — State management, display logic
- `static/js/api.js` — Backend API client with session handling
- FastAPI static file serving configuration
- E2E tests with Playwright

### Deferred to Future PRs (Out of Scope)
- PR-3 (theming): Dark/light mode toggle, CSS variables, theme persistence

## Summary

Build a responsive calculator frontend using plain HTML, CSS, and vanilla JavaScript that integrates with the existing FastAPI backend (PR-1). The UI provides digit/operator buttons, a display, and memory operations, all communicating with the backend via Fetch API.

## Technical Context

| Attribute | Value |
|-----------|-------|
| **Language/Version** | HTML5, CSS3, JavaScript ES6+ |
| **Primary Dependencies** | None (vanilla stack) |
| **Backend** | FastAPI at `http://localhost:8000` (configurable) |
| **Storage** | localStorage for session UUID |
| **Testing** | Playwright (E2E), Jest (unit/integration) |
| **Target Platform** | Modern browsers (Chrome, Firefox, Safari, Edge) |
| **Project Type** | Web application (frontend slice) |
| **Performance Goals** | Button response <50ms, API round-trip <200ms |
| **Constraints** | No build tools, no frameworks, 44x44px touch targets |
| **Coverage Threshold** | 85% (from constitution) |
| **Affected Modules** | `src/main.py` (add static file serving), new `static/` directory |
| **Architecture Profile** | `.gobuildme/specs/epics/calculator/frontend-ui/docs/technical/architecture/data-collection.md` |

## Test Plan (Mandatory for TDD)

**From Spec**: Test specifications defined in spec.md

| Type | File | Test Count |
|------|------|------------|
| Unit | `tests/js/unit/test_calculator_state.js` | 6 |
| Integration | `tests/js/integration/test_api_client.js` | 7 |
| E2E | `tests/e2e/test_calculator.py` | 7 |
| **Total** | | **20** |

**Test Technology Stack**:
- **Framework**: Jest (unit/integration), Playwright (E2E), pytest (E2E runner)
- **Mocking**: Jest mocks for Fetch API, MSW for integration
- **Coverage Target**: 85%
- **Coverage Tool**: Jest coverage, pytest-cov for E2E

**TDD Execution Order**:
1. **Phase A**: Create test file structure (empty tests)
2. **Phase B (RED)**: Write failing tests from spec
3. **Phase C (GREEN)**: Implement code to pass tests
4. **Phase D (REFACTOR)**: Clean up, maintain passing tests

**Test File Structure**:
```
tests/
├── js/
│   ├── unit/
│   │   └── test_calculator_state.js
│   └── integration/
│       └── test_api_client.js
├── e2e/
│   └── test_calculator.py
└── conftest.py
```

**Test Verification Checkpoints**:
- [ ] All test files created (Phase A)
- [ ] All 20 tests written and failing (Phase B - RED)
- [ ] Implementation passes all tests (Phase C - GREEN)
- [ ] Refactoring complete, tests still passing (Phase D)
- [ ] Coverage ≥85%

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Core GoFundMe Engineering Rules** ✅
- [x] No hardcoded values — Base URL defined as const in `api.js`
- [x] Tests in proper location — `tests/js/` and `tests/e2e/`
- [x] Comprehensive tests planned — 20 tests covering all ACs
- [x] Security review — N/A (no sensitive data, local calculator)

**Security Requirements** ✅
- [x] No secrets in code — Only session UUID (non-sensitive)
- [x] Dependency hygiene — No external JS dependencies
- [x] Input validation — Backend validates; frontend sanitizes display
- [x] CORS — Configured in FastAPI for localhost

## Architecture Alignment Check
*GATE: Validate design against current codebase architecture.*

**Codebase Profile** ✅
- [x] Profile loaded: `.gobuildme/specs/epics/calculator/frontend-ui/docs/technical/architecture/data-collection.md`

**Compatibility & Boundaries** ✅
- [x] Stack compatible: HTML5/CSS3/ES6+ per constitution
- [x] Separation of concerns: Frontend = UI only, Backend = calculations
- [x] API contracts: Uses existing `/calculate`, `/memory/*` endpoints
- [x] No data model changes — Uses existing session storage

**Operational Constraints** ✅
- [x] Performance: Button <50ms, API <200ms per spec
- [x] Deployment: Static files served by FastAPI
- [x] Observability: Console logging for development

## Project Structure

### Documentation (this feature)
```
.gobuildme/specs/epics/calculator/frontend-ui/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/tasks command)
```

### Source Code (repository root)
```
src/                     # Existing backend (PR-1)
├── main.py              # Add static file serving
├── routes/
└── services/

static/                  # NEW: Frontend files
├── index.html           # Calculator page
├── css/
│   └── styles.css       # Calculator styling
└── js/
    ├── app.js           # Entry point
    ├── calculator.js    # State management
    └── api.js           # Backend client

tests/                   # Existing + new tests
├── js/
│   ├── unit/
│   │   └── test_calculator_state.js
│   └── integration/
│       └── test_api_client.js
└── e2e/
    └── test_calculator.py
```

**Structure Decision**: Web application with shared `tests/` directory

## Phase 0: Research Complete ✅

No NEEDS CLARIFICATION items — all decisions resolved via constitution and spec.

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Framework** | Vanilla JS | Constitution: simplicity, no build tools |
| **Styling** | CSS3 Flexbox/Grid | Modern, well-supported, responsive |
| **API Client** | Fetch API | Native browser, promise-based |
| **Session Storage** | localStorage | Persist UUID across reloads |
| **Base URL** | Configurable const | Constitution: no hardcoding |
| **Testing** | Jest + Playwright | Industry standard, constitution-aligned |

**Output**: `research.md` (created below)

## Phase 1: Design & Contracts Complete ✅

### Components & State Management (Fullstack Engineer Required)

**Calculator State Model**:
```javascript
const state = {
  display: "0",           // Current display value
  firstOperand: null,     // Stored first operand
  operator: null,         // Pending operator (+, -, *, /)
  waitingForSecond: false,// Awaiting second operand entry
  hasDecimal: false,      // Decimal already in current number
  memoryHasValue: false   // Show memory indicator
};
```

**Component Architecture**:

| Component | File | Responsibility |
|-----------|------|----------------|
| **App** | `app.js` | DOM init, event binding, state wiring |
| **Calculator** | `calculator.js` | State transitions, display logic |
| **ApiClient** | `api.js` | HTTP requests, session management |

### API Integration (Fullstack Engineer Required)

**Consumed Endpoints** (from PR-1):

| Action | Endpoint | Method |
|--------|----------|--------|
| Calculate | `/calculate` | POST |
| Memory Add | `/memory/add` | POST |
| Memory Subtract | `/memory/subtract` | POST |
| Memory Recall | `/memory` | GET |
| Memory Clear | `/memory` | DELETE |

**Session Handling**:
- Generate UUID on first load: `crypto.randomUUID()`
- Store in `localStorage.getItem('session_id')`
- Send via `X-Session-ID` header on all requests

### Error Model (Fullstack Engineer Required)

| Error Type | Display Message | Recovery |
|------------|-----------------|----------|
| Division by zero | "Cannot divide by zero" | Clear or new calc |
| Network error | "Connection error" | Retry button available |
| API error | Show `error` from response | Display not cleared |

### Routing (Fullstack Engineer Required)

Single-page application — no routing needed.
- `GET /` → Serve `static/index.html`
- FastAPI `StaticFiles` mount at `/static`

### i18n (Fullstack Engineer Required)

Not in scope for PR-2. Buttons use symbols (+, -, *, /) that are universal.

### Observability (Fullstack Engineer Required)

- Console logging for development: `console.log/error`
- No production telemetry in PR-2

### Data Model & Migrations (Fullstack Engineer Required)

No new data models — uses existing session storage from PR-1.

**Output**: `data-model.md`, `quickstart.md` (created below)

## Phase 2: Task Planning Approach
*Describes what `/gbm.tasks` will generate — NOT executed by /plan*

**Task Generation Strategy**:
- TDD phases: Setup → RED → GREEN → REFACTOR
- Dependency order: Static serving → HTML → CSS → JS modules → Tests

**Estimated Task Groups**:

| Phase | Tasks | Description |
|-------|-------|-------------|
| Setup | 2-3 | Project structure, static serving |
| HTML | 2-3 | Index page, semantic structure |
| CSS | 2-3 | Layout, buttons, responsive |
| JS Modules | 4-5 | calculator.js, api.js, app.js |
| Tests | 4-5 | Unit, integration, E2E |
| Polish | 2-3 | Error handling, accessibility |

**Estimated Output**: 18-22 tasks in `tasks.md`

**IMPORTANT**: `/gbm.tasks` creates tasks.md, NOT /plan

## Complexity Tracking

No complexity violations — design follows constitution principles.

## Progress Tracking

**Phase Status**:
- [x] Phase 0: Research complete
- [x] Phase 1: Design complete
- [x] Phase 2: Task planning approach documented
- [ ] Phase 3: Tasks generated (`/gbm.tasks`)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Architecture Alignment Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [x] No complexity deviations

---
*Based on Constitution v1.0.0 - See `.gobuildme/memory/constitution.md`*
