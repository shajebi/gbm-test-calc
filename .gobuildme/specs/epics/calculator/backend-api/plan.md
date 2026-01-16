---
description: "FastAPI backend implementation plan for calculator with calculation and memory management endpoints using TDD"
metadata:
  feature_name: "calculator--backend-api"
  artifact_type: plan
  epic_slug: "calculator"
  slice_name: "backend-api"
  created_timestamp: "2026-01-15T16:05:47Z"
  created_by_git_user: "Saeed Hajebi"
  input_summary:
    - "Build Python FastAPI backend for calculator"
    - "Implement REST endpoint for performing calculations (+, -, *, /)"
    - "Implement REST endpoints for memory management (M+, M-, MR, MC)"
    - "Use uv for dependency management"
    - "Store memory per session (in-memory acceptable)"
    - "Simple, readable project structure"
    - "Focus on clarity, correctness, and maintainability"
    - "TDD mandatory with 85% coverage"
---

# Implementation Plan: Calculator Backend API

**Branch**: `calculator--backend-api` | **Date**: 2026-01-15 | **Spec**: `.gobuildme/specs/epics/calculator/backend-api/spec.md`

## Epic & PR Slice Context (Incremental Delivery)

| Field | Value |
|-------|-------|
| Epic Name | calculator |
| PR Slice | 1 of 3 |
| Depends On | (none - first slice) |

### This PR Delivers (In-Scope)
- FastAPI application with uv dependency management
- `POST /calculate` endpoint for basic arithmetic (+, -, *, /)
- Memory endpoints: `POST /memory/add`, `POST /memory/subtract`, `GET /memory`, `DELETE /memory`
- Session-based in-memory storage via `X-Session-ID` header
- Pydantic request/response validation
- Error handling (division by zero, invalid operators, validation errors)
- OpenAPI documentation at `/docs`

### Deferred to Future PRs (Out of Scope)
| Future PR | Scope |
|-----------|-------|
| PR-2 (frontend-ui) | HTML layout, CSS, JavaScript, API integration |
| PR-3 (theming) | Dark/light mode toggle, CSS variables |

---

## Summary

Build a FastAPI REST API backend for a calculator application supporting basic arithmetic operations and session-based memory management. Implementation follows TDD (Red-Green-Refactor) with pytest, Pydantic validation, and 85% coverage minimum.

## Technical Context

| Attribute | Value |
|-----------|-------|
| Language/Version | Python 3.11+ |
| Primary Dependencies | FastAPI, Pydantic, uvicorn |
| Storage | In-memory dict (session-keyed) |
| Testing | pytest, pytest-cov, httpx |
| Target Platform | Linux/macOS server |
| Project Type | Single (backend only for this PR) |
| Performance Goals | <100ms p95 response time |
| Constraints | Stateless API, no database |
| Coverage Threshold | 85% |

## Test Plan (Mandatory for TDD)

**From Spec**: 29 test cases defined across unit, integration, and contract tests.

| Test Type | Files | Count |
|-----------|-------|-------|
| Unit Tests | `tests/unit/services/test_calculator.py`, `test_memory.py`, `test_models.py` | 13 |
| Integration Tests | `tests/integration/test_calculate_api.py`, `test_memory_api.py` | 10 |
| Contract Tests | `tests/api/contracts/test_calculate_contract.py`, `test_memory_contract.py` | 6 |

**Test Technology Stack**:
- Framework: pytest
- Fixtures/Factories: pytest fixtures, httpx.AsyncClient
- Coverage Target: 85%
- Coverage Tool: pytest-cov

**Test Execution Order (TDD Phases)**:
1. Phase A: Test Setup - Create test file structure
2. Phase B: RED - Write failing tests from spec
3. Phase C: GREEN - Implement code to pass tests
4. Phase D: REFACTOR - Improve code quality

**Test Verification Checkpoints**:
- [ ] All test files created (Phase A)
- [ ] All tests written and running (Phase B - RED)
- [ ] Implementation code passes tests (Phase C - GREEN)
- [ ] Refactoring complete, tests passing (Phase D)
- [ ] Coverage threshold met (85%)
- [ ] No untested code paths

## Constitution Check
*GATE: All items verified against `.gobuildme/memory/constitution.md`*

Core Engineering Rules:
- [x] No hardcoded values; configuration via environment/constants
- [x] Tests in `tests/` directory, not repo root
- [x] Comprehensive tests planned with pytest
- [x] Security review: N/A (no auth, no sensitive data)

Security Requirements:
- [x] Secrets management: N/A (no secrets required)
- [x] Dependency hygiene: uv lockfile, minimal dependencies
- [x] Code scanning: ruff linting, mypy type checking
- [x] Input validation: Pydantic models validate all inputs
- [x] Logging: Basic request logging (no PII)

## Architecture Alignment Check

Codebase Profile:
- [x] New project - no existing architecture conflicts

Compatibility & Boundaries:
- [x] Stack: Python 3.11+ / FastAPI / Pydantic (per constitution)
- [x] Layering: routes → services → models (clean separation)
- [x] Data model: In-memory session storage (no migrations)

Operational Constraints:
- [x] Performance: <100ms target achievable
- [x] Deployment: Standard uvicorn server
- [x] Observability: Request logging included

## Project Structure

### Source Code
```
src/
├── main.py              # FastAPI app, CORS, session middleware
├── models.py            # Pydantic request/response models
├── routes/
│   ├── __init__.py
│   ├── calculate.py     # POST /calculate
│   └── memory.py        # Memory CRUD endpoints
└── services/
    ├── __init__.py
    ├── calculator.py    # Calculation logic
    └── memory.py        # Session memory management

tests/
├── conftest.py          # Shared fixtures
├── unit/
│   ├── services/
│   │   ├── test_calculator.py
│   │   └── test_memory.py
│   └── test_models.py
├── integration/
│   ├── test_calculate_api.py
│   └── test_memory_api.py
└── api/
    └── contracts/
        ├── test_calculate_contract.py
        └── test_memory_contract.py
```

### Documentation (this feature)
```
.gobuildme/specs/epics/calculator/backend-api/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # OpenAPI schemas
└── tasks.md             # Phase 2 output (via /gbm.tasks)
```

---

## API Contracts (Fullstack Engineer Required Section)

### POST /calculate
| Method | Path | Request Body | Response |
|--------|------|--------------|----------|
| POST | `/calculate` | `{operand1: float, operand2: float, operator: str}` | `{result: float, operation: str}` |

**Error Responses**:
| Status | Code | Description |
|--------|------|-------------|
| 400 | `DIVISION_BY_ZERO` | Division by zero attempted |
| 400 | `INVALID_OPERATOR` | Operator not in [+, -, *, /] |
| 422 | Validation Error | Missing/invalid fields |

### Memory Endpoints
| Method | Path | Request Body | Response |
|--------|------|--------------|----------|
| POST | `/memory/add` | `{value: float}` | `{memory: float, operation: str}` |
| POST | `/memory/subtract` | `{value: float}` | `{memory: float, operation: str}` |
| GET | `/memory` | - | `{memory: float}` |
| DELETE | `/memory` | - | `{memory: 0.0, operation: "MC"}` |

**Session Header**: `X-Session-ID` (UUID, auto-generated if missing)

---

## Data Model & Migrations (Fullstack Engineer Required Section)

### Pydantic Models

| Model | Fields | Purpose |
|-------|--------|---------|
| `CalculationRequest` | operand1: float, operand2: float, operator: str | POST /calculate input |
| `CalculationResponse` | result: float, operation: str | Calculation result |
| `MemoryValueRequest` | value: float | Memory add/subtract input |
| `MemoryResponse` | memory: float, operation: str (optional) | Memory state |
| `ErrorResponse` | error: str, code: str | Error details |

### Session Storage
- In-memory `dict[str, float]` keyed by session ID
- Default memory value: `0.0`
- No persistence (clears on restart)
- No migrations required

---

## Error Model (Fullstack Engineer Required Section)

| Error Code | HTTP Status | Trigger | Response |
|------------|-------------|---------|----------|
| `DIVISION_BY_ZERO` | 400 | operand2=0 with operator="/" | `{"error": "Division by zero", "code": "DIVISION_BY_ZERO"}` |
| `INVALID_OPERATOR` | 400 | operator not in [+,-,*,/] | `{"error": "Invalid operator", "code": "INVALID_OPERATOR"}` |
| `OVERFLOW_ERROR` | 400 | Result exceeds float range | `{"error": "Overflow", "code": "OVERFLOW_ERROR"}` |
| Validation Error | 422 | Pydantic validation fails | FastAPI default validation response |

---

## Observability (Fullstack Engineer Required Section)

### Logging
- Request logging: method, path, session_id, response_time_ms
- Error logging: error code, message, request details
- Log format: JSON structured logs

### Metrics (Future)
- Request count by endpoint
- Response time histogram
- Error rate by code

---

## Routing (Fullstack Engineer Required Section)

| Route | Method | Handler | Description |
|-------|--------|---------|-------------|
| `/calculate` | POST | `routes.calculate.calculate` | Perform arithmetic |
| `/memory/add` | POST | `routes.memory.add_to_memory` | M+ operation |
| `/memory/subtract` | POST | `routes.memory.subtract_from_memory` | M- operation |
| `/memory` | GET | `routes.memory.get_memory` | MR operation |
| `/memory` | DELETE | `routes.memory.clear_memory` | MC operation |
| `/docs` | GET | OpenAPI UI | Swagger documentation |
| `/health` | GET | Health check | Liveness probe |

---

## i18n (Fullstack Engineer Required Section)

Not required for MVP. Error messages in English only. Future consideration for multi-language support.

---

## Components & State Management (Fullstack Engineer Required Section)

N/A for backend-only PR. Deferred to PR-2 (frontend-ui).

---

## API Integration (Fullstack Engineer Required Section)

N/A for backend-only PR. Frontend integration deferred to PR-2.

---

## Phase 2: Task Planning Approach
*Describes what /gbm.tasks will generate*

**Task Generation Strategy**:
- TDD order: Write tests before implementation
- Dependency order: Models → Services → Routes → Integration
- Mark [P] for parallel tasks

**Estimated Tasks**: ~25 tasks covering:
1. Project setup (uv, pyproject.toml)
2. Test structure setup
3. Pydantic model tests + implementation
4. Calculator service tests + implementation
5. Memory service tests + implementation
6. Route tests + implementation
7. Integration tests
8. Contract tests
9. Coverage validation

---

## Progress Tracking

**Phase Status**:
- [x] Phase 0: Research complete
- [x] Phase 1: Design complete
- [x] Phase 2: Task planning approach defined
- [ ] Phase 3: Tasks generated (/gbm.tasks)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Architecture Alignment Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [x] Complexity deviations documented (none needed)

