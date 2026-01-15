---
description: "Task breakdown for calculator frontend UI implementation with HTML, CSS, JavaScript and API integration"
metadata:
  feature_name: "calculator--frontend-ui"
  artifact_type: tasks
  created_timestamp: "2026-01-15T17:50:00Z"
  created_by_git_user: "Saeed Hajebi"
  input_summary: []
---

# Tasks: Calculator Frontend UI

**Input**: Design documents from `.gobuildme/specs/epics/calculator/frontend-ui/`
**Prerequisites**: plan.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

## Task Scope (PR Slice Only)

- Epic Name: calculator
- PR Slice: 2 of 3
- Depends On: PR-1 (backend-api) ✅ Complete

### This PR Delivers (In-Scope)
- `static/index.html` — Calculator page with display and button grid
- `static/css/styles.css` — Calculator styling, responsive layout
- `static/js/app.js` — Main entry point, DOM initialization
- `static/js/calculator.js` — State management, display logic
- `static/js/api.js` — Backend API client with session handling
- FastAPI static file serving in `src/main.py`
- JS unit tests in `tests/js/unit/`
- JS integration tests in `tests/js/integration/`
- E2E tests in `tests/e2e/`

### Deferred to Future PRs (Do Not Implement Here)
- PR-3 (theming): Dark/light mode toggle, CSS variables, theme persistence

---

## Phase 1: Analysis
**Gate**: All tasks `[x]` before Setup ✅

- [x] A1 Validate design documents completeness
  - [x] A1-1 Verify plan.md has tech stack and structure
  - [x] A1-2 Verify spec.md has all 17 acceptance criteria
  - [x] A1-3 Verify data-model.md has state schema
- [x] A2 Validate architecture compliance
  - [x] A2-1 Check constitution for frontend constraints
  - [x] A2-2 Verify separation of concerns (no business logic in frontend)
  - [x] A2-3 Confirm API contracts match PR-1 endpoints

---

## Phase 2: Setup
**Gate**: All tasks `[x]` before Tests ✅

- [x] 1 Create static file directory structure
  - [x] 1-1 Create `static/` directory at repo root
  - [x] 1-2 Create `static/css/` subdirectory
  - [x] 1-3 Create `static/js/` subdirectory
- [x] 2 Configure FastAPI static file serving in `src/main.py`
  - [x] 2-1 Import StaticFiles from fastapi.staticfiles
  - [x] 2-2 Mount `/static` to serve `static/` directory
  - [x] 2-3 Add route for `/` to serve `static/index.html`
- [x] 3 [P] Create test directory structure
  - [x] 3-1 Create `tests/js/unit/` directory
  - [x] 3-2 Create `tests/js/integration/` directory
  - [x] 3-3 Create Jest config `tests/js/package.json`

---

## Phase 3: Tests First (TDD)
**Gate**: All tests written and FAILING before Phase 4 ✅ (JS tests RED, E2E GREEN)

- [x] 4 [P] Write unit tests `tests/js/unit/test_calculator_state.js`
  - [x] 4-1 test_initial_state_shows_zero — AC-001
  - [x] 4-2 test_digit_appends_to_display — AC-002
  - [x] 4-3 test_operator_stores_first_operand — AC-003
  - [x] 4-4 test_clear_resets_state — AC-005
  - [x] 4-5 test_decimal_only_once — AC-B03
  - [x] 4-6 test_equals_without_operator_no_op — AC-B02
- [x] 5 [P] Write integration tests `tests/js/integration/test_api_client.js`
  - [x] 5-1 test_calculate_success — AC-004
  - [x] 5-2 test_calculate_division_by_zero — AC-E01
  - [x] 5-3 test_calculate_network_error — AC-E02
  - [x] 5-4 test_memory_add_success — AC-006
  - [x] 5-5 test_memory_recall_success — AC-007
  - [x] 5-6 test_memory_clear_success — AC-008
  - [x] 5-7 test_session_id_persistence
- [x] 6 [P] Write E2E tests `tests/e2e/test_calculator.py`
  - [x] 6-1 test_addition_workflow — 5 + 3 = 8
  - [x] 6-2 test_subtraction_workflow — 10 - 4 = 6
  - [x] 6-3 test_multiplication_workflow — 6 * 7 = 42
  - [x] 6-4 test_division_workflow — 15 / 3 = 5
  - [x] 6-5 test_memory_workflow — M+, MR, MC sequence
  - [x] 6-6 test_error_display — Division by zero message
  - [x] 6-7 test_chained_operations — 5 + 3 = 8 + 2 = 10

---

## Phase 4: Core Implementation
**Gate**: All tasks `[x]` before Integration ✅

- [x] 7 Create HTML structure `static/index.html`
  - [x] 7-1 Add HTML5 doctype and semantic structure
  - [x] 7-2 Create calculator display element with "0"
  - [x] 7-3 Create button grid (digits 0-9, operators, memory)
  - [x] 7-4 Add memory indicator element
  - [x] 7-5 Link CSS and JS files
- [x] 8 Create CSS styling `static/css/styles.css`
  - [x] 8-1 Add calculator container layout with Flexbox
  - [x] 8-2 Style display element (font, size, alignment)
  - [x] 8-3 Style button grid with CSS Grid
  - [x] 8-4 Add button hover/active states
  - [x] 8-5 Add focus styles for accessibility
  - [x] 8-6 Add responsive media queries
- [x] 9 [P] Create API client `static/js/api.js`
  - [x] 9-1 Define API_BASE_URL constant
  - [x] 9-2 Implement getOrCreateSessionId() with localStorage
  - [x] 9-3 Implement calculate(operand1, operand2, operator)
  - [x] 9-4 Implement memoryAdd(value)
  - [x] 9-5 Implement memorySubtract(value)
  - [x] 9-6 Implement memoryRecall()
  - [x] 9-7 Implement memoryClear()
- [x] 10 [P] Create calculator state `static/js/calculator.js`
  - [x] 10-1 Define initial state object
  - [x] 10-2 Implement inputDigit(digit) function
  - [x] 10-3 Implement inputOperator(op) function
  - [x] 10-4 Implement inputDecimal() function
  - [x] 10-5 Implement clear() function
  - [x] 10-6 Implement updateDisplay() function
  - [x] 10-7 Export state and functions
- [x] 11 Create app entry point `static/js/app.js`
  - [x] 11-1 Add DOMContentLoaded event listener
  - [x] 11-2 Query DOM elements (display, buttons)
  - [x] 11-3 Bind digit buttons to inputDigit
  - [x] 11-4 Bind operator buttons to inputOperator
  - [x] 11-5 Bind equals button to calculate flow
  - [x] 11-6 Bind memory buttons to API calls
  - [x] 11-7 Bind clear button to reset state

---

## Phase 5: Integration
**Gate**: All tasks `[x]` before Polish ✅

- [x] 12 Integrate equals button with API
  - [x] 12-1 Call api.calculate() on equals click
  - [x] 12-2 Update display with result
  - [x] 12-3 Handle division by zero error display
  - [x] 12-4 Handle network error display
- [x] 13 Integrate memory operations with API
  - [x] 13-1 Call api.memoryAdd() on M+ click
  - [x] 13-2 Call api.memorySubtract() on M- click
  - [x] 13-3 Call api.memoryRecall() on MR click
  - [x] 13-4 Call api.memoryClear() on MC click
  - [x] 13-5 Toggle memory indicator based on API response

---

## Phase 6: Polish
**Gate**: All tasks `[x]` before Testing Validation

- [ ] 14 Add accessibility improvements
  - [ ] 14-1 Add aria-label to all buttons
  - [ ] 14-2 Add aria-live to display for screen readers
  - [ ] 14-3 Verify 44x44px touch targets
  - [ ] 14-4 Verify 4.5:1 contrast ratio
- [ ] 15 Add error handling polish
  - [ ] 15-1 Display "Cannot divide by zero" for division error
  - [ ] 15-2 Display "Connection error" for network failure
  - [ ] 15-3 Keep buttons functional after error
- [ ] 16 Run manual testing per quickstart.md
  - [ ] 16-1 Test basic calculation workflow
  - [ ] 16-2 Test memory operations workflow
  - [ ] 16-3 Test error handling scenarios

---

## Phase 7: Reliability & Observability
**Gate**: All tasks `[x]` before Testing Validation

- [ ] R1 Add console logging for debugging
  - [ ] R1-1 Log API requests and responses
  - [ ] R1-2 Log state transitions
- [ ] R2 Performance validation
  - [ ] R2-1 Verify button response <50ms
  - [ ] R2-2 Verify API round-trip <200ms

---

## Phase 8: Testing Validation
**Gate**: All tests PASS before Review

- [ ] T1 Run JS unit tests
  - [ ] T1-1 Execute `npm test` in tests/js/
  - [ ] T1-2 Verify all 6 unit tests pass
  - [ ] T1-3 Check coverage ≥85%
- [ ] T2 Run JS integration tests
  - [ ] T2-1 Execute integration test suite
  - [ ] T2-2 Verify all 7 integration tests pass
- [ ] T3 Run E2E tests
  - [ ] T3-1 Start backend server
  - [ ] T3-2 Execute `pytest tests/e2e/`
  - [ ] T3-3 Verify all 7 E2E tests pass

---

## Phase 9: Review
**Gate**: All tasks `[x]` before Release

- [ ] RV1 Architecture compliance
  - [ ] RV1-1 No hardcoded values (base URL is configurable)
  - [ ] RV1-2 No business logic in frontend JS
  - [ ] RV1-3 Separation of concerns maintained
- [ ] RV2 Code quality
  - [ ] RV2-1 No console.log in production code
  - [ ] RV2-2 Proper error handling
  - [ ] RV2-3 Semantic HTML structure

---

## Phase 10: Release
**Gate**: All tasks `[x]` before push

- [ ] P1 Pre-push validation
  - [ ] P1-1 All previous phase tasks `[x]`
  - [ ] P1-2 Git status clean
  - [ ] P1-3 Backend tests still pass
  - [ ] P1-4 Frontend tests pass
- [ ] P2 Commit preparation
  - [ ] P2-1 Create comprehensive commit message
  - [ ] P2-2 Reference PR-1 dependency

---

## Dependencies

| Blocker | Blocked |
|---------|---------|
| Phase 1 (Analysis) | Phase 2 (Setup) |
| Phase 2 (Setup) | Phase 3 (Tests) |
| Phase 3 (Tests) | Phase 4 (Implementation) |
| Tasks 7-11 | Tasks 12-13 |
| Phase 4 | Phase 5 (Integration) |
| Phase 5 | Phase 6 (Polish) |
| Phase 6 | Phase 8 (Testing) |

## Parallel Execution Groups

```bash
# Group 1: Test files (Phase 3)
Task 4: tests/js/unit/test_calculator_state.js
Task 5: tests/js/integration/test_api_client.js
Task 6: tests/e2e/test_calculator.py

# Group 2: JS modules (Phase 4)
Task 9: static/js/api.js
Task 10: static/js/calculator.js
```

## Validation Checklist

- [x] All 17 ACs have corresponding tests
- [x] All tests come before implementation (TDD)
- [x] Parallel tasks are truly independent
- [x] Each task specifies exact file path
- [x] No [P] tasks modify same file

