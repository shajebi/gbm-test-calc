---
description: "TDD task breakdown for FastAPI calculator backend with calculation and memory endpoints"
metadata:
  feature_name: "calculator--backend-api"
  artifact_type: tasks
  epic_slug: "calculator"
  slice_name: "backend-api"
  created_timestamp: "2026-01-15T16:10:54Z"
  created_by_git_user: "Saeed Hajebi"
  input_summary:
    - "TDD mandatory - tests before implementation"
    - "85% coverage minimum required"
    - "FastAPI + Pydantic + uvicorn stack"
    - "uv for dependency management"
    - "Session-based memory via X-Session-ID header"
---

# Tasks: Calculator Backend API

**Branch**: `calculator--backend-api` | **Generated**: 2026-01-15

## Task Scope (PR Slice Only)

| Field | Value |
|-------|-------|
| Epic Name | calculator |
| PR Slice | 1 of 3 |

### This PR Delivers (In-Scope)
- FastAPI application with uv dependency management
- `POST /calculate` endpoint for basic arithmetic
- Memory endpoints: add, subtract, recall, clear
- Session-based in-memory storage
- Pydantic validation and error handling

### Deferred to Future PRs (Do Not Implement Here)
- PR-2: Frontend HTML/CSS/JavaScript
- PR-3: Dark/light mode theming

---

## Phase 1: Setup
*Initialize project structure and dependencies*

### T001: Initialize Python project with uv
- [x] 1: Run `uv init` and configure `pyproject.toml`
- [x] 1-1: Add project metadata (name, version, description) in `pyproject.toml`
- [x] 1-2: Add dependencies (fastapi, uvicorn, pydantic) in `pyproject.toml`
- [x] 1-3: Add dev dependencies (pytest, pytest-cov, httpx, ruff, mypy) in `pyproject.toml`
- [x] 1-4: Run `uv sync` to create lockfile

### T002: Create source directory structure
- [x] 2: Create `src/` directory with `__init__.py` files [P]
- [x] 2-1: Create `src/__init__.py`
- [x] 2-2: Create `src/routes/__init__.py`
- [x] 2-3: Create `src/services/__init__.py`

### T003: Create test directory structure
- [x] 3: Create `tests/` directory with structure [P]
- [x] 3-1: Create `tests/__init__.py`
- [x] 3-2: Create `tests/conftest.py` with pytest fixtures
- [x] 3-3: Create `tests/unit/__init__.py`
- [x] 3-4: Create `tests/unit/services/__init__.py`
- [x] 3-5: Create `tests/integration/__init__.py`
- [x] 3-6: Create `tests/api/__init__.py`
- [x] 3-7: Create `tests/api/contracts/__init__.py`

---

## Phase 2: RED - Write Failing Tests
*Write all tests from spec before implementation*

### T004: Write Pydantic model tests
- [x] 4: Create `tests/unit/test_models.py` with failing tests [P]
- [x] 4-1: `test_calculation_request_valid()` - Valid request parses
- [x] 4-2: `test_calculation_request_missing_field()` - Missing field raises ValidationError
- [x] 4-3: `test_calculation_request_invalid_type()` - Non-numeric raises ValidationError
- [x] 4-4: `test_memory_value_request_valid()` - Valid memory request parses
- [x] 4-5: `test_memory_response_structure()` - Response has required fields

### T005: Write calculator service tests
- [x] 5: Create `tests/unit/services/test_calculator.py` with failing tests [P]
- [x] 5-1: `test_add_positive_numbers()` - Returns sum (AC-001)
- [x] 5-2: `test_subtract_numbers()` - Returns difference (AC-002)
- [x] 5-3: `test_multiply_numbers()` - Returns product (AC-003)
- [x] 5-4: `test_divide_numbers()` - Returns quotient (AC-004)
- [x] 5-5: `test_divide_by_zero_raises_error()` - Raises DivisionByZeroError (AC-E01)
- [x] 5-6: `test_invalid_operator_raises_error()` - Raises InvalidOperatorError (AC-E02)
- [x] 5-7: `test_negative_result()` - Handles negatives (AC-B03)
- [x] 5-8: `test_floating_point_precision()` - Handles precision (AC-B04)

### T006: Write memory service tests
- [x] 6: Create `tests/unit/services/test_memory.py` with failing tests [P]
- [x] 6-1: `test_add_to_memory()` - Adds value (AC-005)
- [x] 6-2: `test_subtract_from_memory()` - Subtracts value (AC-006)
- [x] 6-3: `test_recall_memory()` - Returns current value (AC-007)
- [x] 6-4: `test_clear_memory()` - Resets to zero (AC-008)
- [x] 6-5: `test_new_session_memory_zero()` - New session = 0 (AC-B02)

### T007: Write calculate API integration tests
- [x] 7: Create `tests/integration/test_calculate_api.py` with failing tests [P]
- [x] 7-1: `test_calculate_addition_returns_200()` - POST /calculate + returns 200
- [x] 7-2: `test_calculate_division_by_zero_returns_400()` - Returns 400 error
- [x] 7-3: `test_calculate_invalid_operator_returns_400()` - Returns 400 error
- [x] 7-4: `test_calculate_missing_fields_returns_422()` - Validation error
- [x] 7-5: `test_calculate_response_time_under_100ms()` - Performance check

### T008: Write memory API integration tests
- [x] 8: Create `tests/integration/test_memory_api.py` with failing tests [P]
- [x] 8-1: `test_memory_add_returns_new_value()` - POST /memory/add works
- [x] 8-2: `test_memory_subtract_returns_new_value()` - POST /memory/subtract works
- [x] 8-3: `test_memory_recall_returns_value()` - GET /memory works
- [x] 8-4: `test_memory_clear_resets_to_zero()` - DELETE /memory works
- [x] 8-5: `test_memory_new_session_returns_zero()` - New session = 0

### T009: Write contract tests
- [x] 9: Create `tests/api/contracts/test_calculate_contract.py` with failing tests [P]
- [x] 9-1: `test_calculate_200_schema()` - Response matches CalculationResponse
- [x] 9-2: `test_calculate_400_error_schema()` - Error matches ErrorResponse
- [x] 9-3: `test_calculate_422_validation_schema()` - Validation errors structured
- [x] 10: Create `tests/api/contracts/test_memory_contract.py` with failing tests [P]
- [x] 10-1: `test_memory_add_response_schema()` - POST /memory/add schema
- [x] 10-2: `test_memory_get_response_schema()` - GET /memory schema
- [x] 10-3: `test_memory_delete_response_schema()` - DELETE /memory schema

### T010: Verify RED phase
- [x] 11: Run `uv run pytest` - All tests FAIL (RED confirmed ✓)

---

## Phase 3: GREEN - Implement to Pass Tests
*Write minimal code to make tests pass*

### T011: Implement Pydantic models
- [x] 12: Create `src/models.py` with request/response models
- [x] 12-1: Implement `CalculationRequest` model
- [x] 12-2: Implement `CalculationResponse` model
- [x] 12-3: Implement `MemoryValueRequest` model
- [x] 12-4: Implement `MemoryResponse` model
- [x] 12-5: Implement `ErrorResponse` model
- [x] 12-6: Run model tests - verify passing

### T012: Implement custom exceptions
- [x] 13: Create `src/exceptions.py` with custom errors
- [x] 13-1: Implement `DivisionByZeroError` exception
- [x] 13-2: Implement `InvalidOperatorError` exception
- [x] 13-3: Implement `OverflowError` exception

### T013: Implement calculator service
- [x] 14: Create `src/services/calculator.py` with calculate function
- [x] 14-1: Implement `calculate(operand1, operand2, operator)` function
- [x] 14-2: Handle addition (+)
- [x] 14-3: Handle subtraction (-)
- [x] 14-4: Handle multiplication (*)
- [x] 14-5: Handle division (/) with zero check
- [x] 14-6: Raise `InvalidOperatorError` for unknown operators
- [x] 14-7: Run calculator tests - verify passing

### T014: Implement memory service
- [x] 15: Create `src/services/memory.py` with memory functions
- [x] 15-1: Create `_memory_store: dict[str, float]` global
- [x] 15-2: Implement `get_memory(session_id)` function
- [x] 15-3: Implement `set_memory(session_id, value)` function
- [x] 15-4: Implement `add_to_memory(session_id, value)` function
- [x] 15-5: Implement `subtract_from_memory(session_id, value)` function
- [x] 15-6: Implement `clear_memory(session_id)` function
- [x] 15-7: Run memory tests - verify passing

### T015: Implement FastAPI application
- [x] 16: Create `src/main.py` with FastAPI app
- [x] 16-1: Create FastAPI app instance with metadata
- [x] 16-2: Register exception handlers for custom errors
- [x] 16-3: Include routers

### T016: Implement calculate route
- [x] 17: Create `src/routes/calculate.py` with endpoint
- [x] 17-1: Implement `POST /calculate` endpoint
- [x] 17-2: Parse `CalculationRequest` body
- [x] 17-3: Call calculator service
- [x] 17-4: Return `CalculationResponse`
- [x] 17-5: Run calculate API tests - verify passing

### T017: Implement memory routes
- [x] 18: Create `src/routes/memory.py` with endpoints
- [x] 18-1: Add session ID dependency (extract or generate UUID)
- [x] 18-2: Implement `POST /memory/add` endpoint
- [x] 18-3: Implement `POST /memory/subtract` endpoint
- [x] 18-4: Implement `GET /memory` endpoint
- [x] 18-5: Implement `DELETE /memory` endpoint
- [x] 18-6: Run memory API tests - verify passing

### T018: Implement health check
- [x] 19: Add `GET /health` endpoint in `src/main.py`

### T019: Verify GREEN phase
- [x] 20: Run `uv run pytest --cov=src` - All 37 tests PASS ✓

---

## Phase 4: REFACTOR - Improve Code Quality
*Refactor while keeping tests green*

### T020: Apply code formatting and linting
- [x] 21: Run `uv run ruff format src/ tests/`
- [x] 21-1: Run `uv run ruff check src/ tests/ --fix`
- [x] 21-2: Run `uv run mypy src/` - Fix any type errors

### T021: Add docstrings and type hints
- [x] 22: Add docstrings to all public functions
- [x] 22-1: Verify all function signatures have type hints
- [x] 22-2: Run mypy again - verify no errors

### T022: Verify REFACTOR phase
- [x] 23: Run `uv run pytest --cov=src` - All tests PASS, 97% coverage ✓

---

## Phase 5: Polish
*Final quality checks*

### T023: Validate coverage threshold
- [ ] 24: Run `uv run pytest --cov=src --cov-fail-under=85`
- [ ] 24-1: If coverage < 85%, add missing test cases

### T024: Security review
- [ ] 25: Review for input validation gaps
- [ ] 25-1: Verify no secrets in code

### T025: Add structured logging
- [ ] 26: Add request logging middleware in `src/main.py`

### T026: Create implementation documentation
- [ ] 27: Create `.docs/implementations/calculator-backend-api/implementation-summary.md`
- [ ] 27-1: Document implementation decisions
- [ ] 27-2: Link to planning documents in `.gobuildme/specs/epics/calculator/backend-api/`

---

## Parallel Execution Guide

**Independent tasks (can run in parallel)**:
```bash
# Phase 1 - Directory setup
Task agent: T002, T003 [P]

# Phase 2 - Write tests
Task agent: T004, T005, T006 [P]  # Unit tests in parallel
Task agent: T007, T008 [P]        # Integration tests in parallel
Task agent: T009, T010 [P]        # Contract tests in parallel
```

**Sequential tasks (dependencies)**:
- T001 → T002, T003 (setup before directories)
- Phase 2 → T010 (all tests before verify)
- T011 → T013 (models before services)
- Phase 3 → T019 (all implementation before verify)
- Phase 4 → Phase 5 (refactor before polish)

---

## Task Summary

| Phase | Tasks | Status |
|-------|-------|--------|
| Setup | T001-T003 | [ ] |
| RED (Tests) | T004-T010 | [ ] |
| GREEN (Implementation) | T011-T019 | [ ] |
| REFACTOR | T020-T022 | [ ] |
| Polish | T023-T026 | [ ] |
| **Total** | **26 tasks** | |

