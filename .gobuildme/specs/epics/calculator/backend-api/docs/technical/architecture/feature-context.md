# Feature Context: Calculator Backend API

## Architectural Foundation

This feature establishes the backend foundation for a full-stack calculator application. As this is a new project (no existing codebase), architecture follows constitutional principles.

## Technology Decisions

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Framework | FastAPI | Constitution mandates Python + FastAPI |
| Validation | Pydantic | Constitution requires schema validation |
| Package Mgmt | uv | Per PRD requirements |
| Testing | pytest + pytest-cov | Constitution mandates TDD with 85% coverage |

## API Design Patterns

- RESTful endpoints with JSON request/response
- Pydantic models for request/response validation
- Session-based memory storage (in-memory dict keyed by session ID)
- Stateless API design per constitution

## Project Structure (Planned)

```
src/
├── main.py           # FastAPI app entry point
├── models.py         # Pydantic request/response models
├── routes/
│   ├── calculate.py  # POST /calculate endpoint
│   └── memory.py     # Memory CRUD endpoints
└── services/
    ├── calculator.py # Calculation logic
    └── memory.py     # Session memory management

tests/
├── unit/
│   ├── test_calculator.py
│   └── test_memory.py
├── integration/
│   └── test_api.py
└── conftest.py       # Fixtures
```

## Constitutional Alignment

- TDD mandatory (tests first)
- Type hints on all functions
- ruff linting + mypy strict
- 85% coverage minimum
- API documentation via OpenAPI/Swagger

