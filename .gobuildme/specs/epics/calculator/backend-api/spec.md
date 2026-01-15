---
description: "FastAPI backend specification for calculator application with calculation and memory management endpoints"
metadata:
  feature_name: "calculator--backend-api"
  artifact_type: specify
  epic_slug: "calculator"
  slice_name: "backend-api"
  created_timestamp: "2026-01-15T15:59:48Z"
  created_by_git_user: "Saeed Hajebi"
  input_summary:
    - "Build Python FastAPI backend for calculator"
    - "Implement REST endpoint for performing calculations (+, -, *, /)"
    - "Implement REST endpoints for memory management (M+, M-, MR, MC)"
    - "Use uv for dependency management"
    - "Store memory per session (in-memory acceptable)"
    - "Simple, readable project structure"
    - "Focus on clarity, correctness, and maintainability"
---

# Feature Specification: Calculator Backend API

**Feature Branch**: `calculator--backend-api`
**Created**: 2026-01-15
**Status**: Draft
**Persona**: fullstack_engineer

## Epic & PR Slice Context (Incremental Delivery)

| Field | Value |
|-------|-------|
| Epic Name | calculator |
| PR Slice | 1 of 3 |
| Depends On | (none - first slice) |
| Registry | `.gobuildme/specs/epics/calculator/slice-registry.yaml` |

### This PR Delivers (In-Scope)
- FastAPI application with uv dependency management
- `POST /calculate` endpoint for basic arithmetic
- Memory endpoints: `POST /memory/add`, `POST /memory/subtract`, `GET /memory`, `DELETE /memory`
- Session-based in-memory storage
- Pydantic request/response validation
- Error handling (division by zero, invalid operators)
- OpenAPI documentation

## Deferred to Future PRs (Out of Scope)

| Future PR | Scope | Dependencies |
|-----------|-------|--------------|
| PR-2 (frontend-ui) | HTML layout, CSS, JavaScript, API integration | Depends on PR-1 |
| PR-3 (theming) | Dark/light mode toggle, CSS variables | Depends on PR-2 |

---

## Clarifications

### Clarification Session (2026-01-15)

*All ambiguities resolved through context inference - no questions required.*

| Decision | Inferred Value | Source |
|----------|----------------|--------|
| Session ID generation | Auto-generated server-side (UUID cookie) | Constitution: "Stateless design" + REST best practices |
| Session ID header | `X-Session-ID` header or cookie | Standard REST pattern for session tracking |
| Division by zero behavior | Return 400 error with `DIVISION_BY_ZERO` code | Spec AC-E01 (already defined) |
| Memory operation response | Return new memory value + operation string | Spec API contracts (already defined) |
| Floating-point precision | Python native float, display rounded to 10 decimals | Constitution: "Simplicity First" |
| Large number handling | Return result if within float range, else 400 overflow | Spec AC-B01 (already defined) |
| New session memory value | Initialize to 0.0 | Spec AC-B02 (already defined) |

### Inferred Design Decisions

**Session Management** (inferred from constitution "Stateless design"):
- Server auto-generates UUID session ID on first request if not provided
- Client receives session ID via `X-Session-ID` response header
- Client includes session ID in subsequent requests via header
- Missing/invalid session ID creates new session with memory=0

**Floating-Point Handling** (inferred from constitution "Simplicity First"):
- Use Python's native `float` type for all calculations
- No special decimal library (avoids over-engineering)
- Display precision: round to 10 decimal places for clean output
- Accept scientific notation in input (Pydantic handles automatically)

---

## UX Flows

### API Consumer Flow
1. Client sends calculation request → receives result
2. Client manages memory: add, subtract, recall, clear
3. Session persists across requests via session ID

### Performance Targets
- API response time: <100ms (p95)
- Calculation latency: <10ms
- Memory operations: <5ms

### Accessibility
- API returns structured JSON with clear error messages
- HTTP status codes follow REST conventions
- OpenAPI/Swagger UI for interactive testing

---

## User Scenarios & Testing

### Primary User Story
As an API consumer, I want to perform calculator operations via REST endpoints so that I can integrate calculation functionality into my frontend application.

### Acceptance Scenarios

1. **Given** a valid calculation request, **When** I POST to `/calculate`, **Then** I receive the computed result
2. **Given** a session with stored memory, **When** I GET `/memory`, **Then** I receive the current memory value
3. **Given** division by zero, **When** I POST to `/calculate`, **Then** I receive a 400 error with clear message

### Edge Cases
- What happens with very large numbers? → Return result or overflow error
- What happens with floating-point precision issues? → Use Python's decimal handling
- What happens with empty/invalid session? → Create new session with memory=0

---

## API Contracts

### POST /calculate
Calculate result of arithmetic operation.

**Request**:
```json
{
  "operand1": 10.5,
  "operand2": 5.0,
  "operator": "+"
}
```

**Response (200)**:
```json
{
  "result": 15.5,
  "operation": "10.5 + 5.0"
}
```

**Error Response (400)**:
```json
{
  "error": "Division by zero",
  "code": "DIVISION_BY_ZERO"
}
```

### POST /memory/add
Add value to session memory.

**Request**: `{"value": 10.0}`
**Response**: `{"memory": 10.0, "operation": "M+ 10.0"}`

### POST /memory/subtract
Subtract value from session memory.

**Request**: `{"value": 5.0}`
**Response**: `{"memory": 5.0, "operation": "M- 5.0"}`

### GET /memory
Recall current memory value.

**Response**: `{"memory": 5.0}`

### DELETE /memory
Clear memory to zero.

**Response**: `{"memory": 0.0, "operation": "MC"}`

---

## Acceptance Criteria

### Happy Path Criteria

- **AC-001**: **Given** valid operands and operator (+), **When** POST `/calculate`, **Then** return sum with 200 status
- **AC-002**: **Given** valid operands and operator (-), **When** POST `/calculate`, **Then** return difference with 200 status
- **AC-003**: **Given** valid operands and operator (*), **When** POST `/calculate`, **Then** return product with 200 status
- **AC-004**: **Given** valid operands and non-zero divisor (/), **When** POST `/calculate`, **Then** return quotient with 200
- **AC-005**: **Given** session exists, **When** POST `/memory/add` with value, **Then** add to memory and return new value
- **AC-006**: **Given** session exists, **When** POST `/memory/subtract` with value, **Then** subtract and return new value
- **AC-007**: **Given** session with memory, **When** GET `/memory`, **Then** return current memory value
- **AC-008**: **Given** session with memory, **When** DELETE `/memory`, **Then** reset memory to 0

### Error Handling Criteria

- **AC-E01**: **Given** division by zero, **When** POST `/calculate`, **Then** return 400 with `DIVISION_BY_ZERO` error code
- **AC-E02**: **Given** invalid operator, **When** POST `/calculate`, **Then** return 400 with `INVALID_OPERATOR` error
- **AC-E03**: **Given** missing required fields, **When** POST any endpoint, **Then** return 422 with validation errors
- **AC-E04**: **Given** non-numeric operands, **When** POST `/calculate`, **Then** return 422 with type validation error

### Edge Case Criteria

- **AC-B01**: **Given** very large numbers, **When** calculate, **Then** return result or 400 with overflow error
- **AC-B02**: **Given** new session (no memory), **When** GET `/memory`, **Then** return `{"memory": 0.0}`
- **AC-B03**: **Given** negative result, **When** any calculation, **Then** return negative number correctly
- **AC-B04**: **Given** floating-point operands, **When** calculate, **Then** handle precision correctly

### Performance Criteria

- **AC-P01**: **Given** any calculation request, **When** processed, **Then** respond within 100ms (p95)
- **AC-P02**: **Given** memory operation, **When** processed, **Then** respond within 50ms (p95)

---

## Requirements

### Functional Requirements

- **FR-001**: System provides POST `/calculate` endpoint accepting operand1, operand2, and operator
- **FR-002**: System supports operators: `+`, `-`, `*`, `/`
- **FR-003**: System validates request bodies using Pydantic models
- **FR-004**: System provides memory endpoints: add, subtract, recall, clear
- **FR-005**: System maintains session-based memory (in-memory dict)
- **FR-006**: System returns structured JSON responses with operation details
- **FR-007**: System generates OpenAPI documentation at `/docs`
- **FR-008**: System handles division by zero with appropriate error response
- **FR-009**: System handles invalid operators with appropriate error response

### Key Entities

| Entity | Description | Attributes |
|--------|-------------|------------|
| CalculationRequest | Input for calculate endpoint | operand1: float, operand2: float, operator: str |
| CalculationResponse | Result from calculation | result: float, operation: str |
| MemoryValueRequest | Input for memory add/subtract | value: float |
| MemoryResponse | Memory operation result | memory: float, operation: str (optional) |
| ErrorResponse | Error details | error: str, code: str |

---

## Test Specifications

### Unit Tests: Calculator Service
- **Test File**: `tests/unit/services/test_calculator.py`
- **Test Cases**:
  - `test_add_positive_numbers()` - Returns sum of two positive floats (AC-001)
  - `test_subtract_numbers()` - Returns difference correctly (AC-002)
  - `test_multiply_numbers()` - Returns product correctly (AC-003)
  - `test_divide_numbers()` - Returns quotient correctly (AC-004)
  - `test_divide_by_zero_raises_error()` - Raises DivisionByZeroError (AC-E01)
  - `test_invalid_operator_raises_error()` - Raises InvalidOperatorError (AC-E02)
  - `test_negative_result()` - Handles negative results (AC-B03)
  - `test_floating_point_precision()` - Handles float precision (AC-B04)

### Unit Tests: Memory Service
- **Test File**: `tests/unit/services/test_memory.py`
- **Test Cases**:
  - `test_add_to_memory()` - Adds value to session memory (AC-005)
  - `test_subtract_from_memory()` - Subtracts value from memory (AC-006)
  - `test_recall_memory()` - Returns current memory value (AC-007)
  - `test_clear_memory()` - Resets memory to zero (AC-008)
  - `test_new_session_memory_zero()` - New session has memory=0 (AC-B02)

### Unit Tests: Pydantic Models
- **Test File**: `tests/unit/test_models.py`
- **Test Cases**:
  - `test_calculation_request_valid()` - Valid request parses correctly
  - `test_calculation_request_missing_field()` - Missing field raises ValidationError (AC-E03)
  - `test_calculation_request_invalid_type()` - Non-numeric raises ValidationError (AC-E04)
  - `test_memory_value_request_valid()` - Valid memory request parses
  - `test_memory_response_structure()` - Response has required fields

### Integration Tests: Calculate API
- **Test File**: `tests/integration/test_calculate_api.py`
- **Test Cases**:
  - `test_calculate_addition_returns_200()` - POST /calculate with + returns 200 (AC-001)
  - `test_calculate_division_by_zero_returns_400()` - Returns 400 with error (AC-E01)
  - `test_calculate_invalid_operator_returns_400()` - Returns 400 for invalid op (AC-E02)
  - `test_calculate_missing_fields_returns_422()` - Validation error (AC-E03)
  - `test_calculate_response_time_under_100ms()` - Performance check (AC-P01)

### Integration Tests: Memory API
- **Test File**: `tests/integration/test_memory_api.py`
- **Test Cases**:
  - `test_memory_add_returns_new_value()` - POST /memory/add works (AC-005)
  - `test_memory_subtract_returns_new_value()` - POST /memory/subtract works (AC-006)
  - `test_memory_recall_returns_value()` - GET /memory works (AC-007)
  - `test_memory_clear_resets_to_zero()` - DELETE /memory works (AC-008)
  - `test_memory_new_session_returns_zero()` - New session = 0 (AC-B02)

### Contract Tests: POST /calculate
- **Test File**: `tests/api/contracts/test_calculate_contract.py`
- **Endpoint**: POST /calculate
- **Test Cases**:
  - `test_calculate_201_schema()` - Response matches CalculationResponse schema
  - `test_calculate_400_error_schema()` - Error matches ErrorResponse schema
  - `test_calculate_422_validation_schema()` - Validation errors structured

### Contract Tests: Memory Endpoints
- **Test File**: `tests/api/contracts/test_memory_contract.py`
- **Test Cases**:
  - `test_memory_add_response_schema()` - POST /memory/add matches schema
  - `test_memory_get_response_schema()` - GET /memory matches schema
  - `test_memory_delete_response_schema()` - DELETE /memory matches schema

---

## Review & Acceptance Checklist

### Content Quality
- [x] No implementation details (languages, frameworks, APIs) - Spec focuses on WHAT not HOW
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

### Acceptance Criteria Quality
- [x] Each functional requirement has corresponding acceptance criteria
- [x] All acceptance criteria follow Given-When-Then format
- [x] Happy path scenarios are covered (AC-001 to AC-008)
- [x] Error handling criteria are defined (AC-E01 to AC-E04)
- [x] Edge cases are addressed (AC-B01 to AC-B04)
- [x] Criteria are specific and verifiable
- [x] Performance criteria included (AC-P01, AC-P02)
- [ ] Security criteria included where relevant (N/A - no auth for MVP)

### Test Specifications Quality
- [x] Each AC has corresponding test case(s)
- [x] Unit tests defined for services and models
- [x] Integration tests defined for API endpoints
- [x] Contract tests defined for response schemas
- [x] Test file paths specified

---

## Execution Status

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked (none remain)
- [x] User scenarios defined
- [x] Requirements generated
- [x] Acceptance criteria defined
- [x] Entities identified
- [x] Test specifications defined
- [x] Review checklist passed

