---
description: "Research findings for calculator backend API implementation"
metadata:
  feature_name: "calculator--backend-api"
  artifact_type: research
  created_timestamp: "2026-01-15T16:05:47Z"
---

# Research: Calculator Backend API

## Technology Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Web Framework | FastAPI | Constitution mandates; async, Pydantic integration, OpenAPI |
| Validation | Pydantic v2 | Built into FastAPI; type-safe request/response |
| Package Manager | uv | Per PRD requirement; fast, modern Python tooling |
| Test Framework | pytest | Constitution mandates; fixtures, coverage integration |
| ASGI Server | uvicorn | Standard FastAPI deployment |
| HTTP Client (tests) | httpx | Async support for FastAPI TestClient |

## Alternatives Considered

| Option | Rejected Because |
|--------|------------------|
| Flask | No async, requires marshmallow for validation |
| Django REST | Overkill for simple calculator API |
| poetry | PRD explicitly requires uv |
| requests (tests) | No async support |

## Session Management Research

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| Cookie-based | Browser-friendly | Requires cookie parsing | ❌ |
| Header-based (`X-Session-ID`) | Simple, stateless | Client must manage | ✅ Chosen |
| JWT tokens | Secure, self-contained | Over-engineered for this use case | ❌ |

**Implementation**: Auto-generate UUID if `X-Session-ID` header missing; return in response header.

## Error Handling Research

| Pattern | Decision |
|---------|----------|
| Custom exception classes | ✅ `DivisionByZeroError`, `InvalidOperatorError` |
| FastAPI exception handlers | ✅ Map custom exceptions to HTTP responses |
| Structured error response | ✅ `{error: str, code: str}` per spec |

## Performance Considerations

| Concern | Mitigation |
|---------|------------|
| Float precision | Use Python native float (sufficient for basic calc) |
| Large numbers | Catch `OverflowError`, return 400 |
| Memory growth | Session cleanup not needed for MVP (ephemeral) |

## Dependencies (Minimal)

```toml
[project]
dependencies = [
    "fastapi>=0.109.0",
    "uvicorn>=0.27.0",
    "pydantic>=2.6.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "pytest-cov>=4.1.0",
    "httpx>=0.26.0",
    "ruff>=0.2.0",
    "mypy>=1.8.0",
]
```

## Constraints

| Constraint | Impact | Mitigation |
|------------|--------|------------|
| No database | Session data ephemeral | Document restart clears memory |
| No auth | Anyone can access | Acceptable for MVP calculator |
| Single server | No shared state | Stateless design enables future scaling |

