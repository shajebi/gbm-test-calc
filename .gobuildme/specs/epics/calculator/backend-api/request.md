---
description: "FastAPI backend for calculator application with calculation and memory endpoints"
metadata:
  feature_name: "calculator--backend-api"
  artifact_type: request
  epic_slug: "calculator"
  slice_name: "backend-api"
  created_timestamp: "2026-01-15T15:57:15Z"
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

# Request

## Summary

Build the backend API for a full-stack calculator application using Python FastAPI. This PR focuses exclusively on the backend: REST endpoints for performing calculations and managing calculator memory, with session-based in-memory storage. Uses uv for dependency management.

## Epic & PR Slice (Incremental Delivery)

| Field | Value |
|-------|-------|
| Epic Link | (none) |
| Epic Name | calculator |
| PR Slice | 1 of 3 |
| Depends On | (none - first slice) |

### PR Scope Assessment
- **Concerns**: 2 (Backend API, Business Logic)
- **Est. LoC**: ~150-200
- **Status**: ✅ Within guidelines

### Slice Registry
- **Registry**: `.gobuildme/specs/epics/calculator/slice-registry.yaml`
- **This Slice**: backend-api (PR-1 of 3)
- **Next Slice**: frontend-ui (HTML layout, CSS styling, JavaScript UI logic, API integration)

### This PR Delivers (In-Scope)
- FastAPI application setup with uv dependency management
- REST endpoint for calculations: `POST /calculate` (accepts operands and operator)
- REST endpoints for memory: `POST /memory/add`, `POST /memory/subtract`, `GET /memory`, `DELETE /memory`
- Session-based in-memory storage for calculator memory
- Input validation using Pydantic models
- Basic error handling (division by zero, invalid operations)
- Project structure: `src/main.py`, `src/models.py`, `src/routes/`

### Deferred to Future PRs (Out of Scope)
- PR-2 (frontend-ui): HTML layout, CSS styling, JavaScript, API integration
- PR-3 (theming): Dark/light mode toggle, CSS variables

## Goals

- Build Python FastAPI backend for calculator application
- Implement REST endpoint for performing basic calculations (+, -, *, /)
- Implement REST endpoints for memory management (M+, M-, MR, MC)
- Use uv for Python dependency management
- Store calculator memory per session using in-memory storage
- Create simple, readable project structure
- Ensure clarity, correctness, and maintainability

## Non-Goals

- Frontend HTML/CSS/JavaScript (deferred to PR-2)
- Dark/light mode theming (deferred to PR-3)
- Persistent storage (database) - in-memory is acceptable per PRD
- User authentication or multi-user support
- Advanced calculator functions (scientific, graphing)

## Assumptions

- Single-user local development environment
- Session can be identified by a simple session ID or cookie
- In-memory storage is acceptable (data lost on server restart)
- Python 3.11+ is available
- uv package manager is installed

## Open Questions

~~1. Should session IDs be auto-generated or client-provided?~~
   → **Resolved (inferred)**: Auto-generated server-side UUID, returned via `X-Session-ID` header

~~2. What should happen when dividing by zero - return error or infinity?~~
   → **Resolved (spec)**: Return 400 error with `DIVISION_BY_ZERO` code (AC-E01)

~~3. Should memory operations return the new memory value or just acknowledge?~~
   → **Resolved (spec)**: Return new memory value + operation string

~~4. What precision should be used for floating-point calculations?~~
   → **Resolved (inferred)**: Python native float, display rounded to 10 decimals

## References

- PRD: `docs/PRD.md`

