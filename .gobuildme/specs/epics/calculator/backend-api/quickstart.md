---
description: "Quickstart guide for calculator backend API"
metadata:
  feature_name: "calculator--backend-api"
  artifact_type: quickstart
  created_timestamp: "2026-01-15T16:05:47Z"
---

# Quickstart: Calculator Backend API

## Setup

```bash
# Install dependencies
uv sync

# Run development server
uv run uvicorn src.main:app --reload --port 8000
```

## API Documentation

Open `http://localhost:8000/docs` for Swagger UI.

## Example Requests

### Calculate Addition

```bash
curl -X POST http://localhost:8000/calculate \
  -H "Content-Type: application/json" \
  -d '{"operand1": 10.5, "operand2": 5.0, "operator": "+"}'
```

Response: `{"result": 15.5, "operation": "10.5 + 5.0"}`

### Calculate Division

```bash
curl -X POST http://localhost:8000/calculate \
  -H "Content-Type: application/json" \
  -d '{"operand1": 20, "operand2": 4, "operator": "/"}'
```

Response: `{"result": 5.0, "operation": "20.0 / 4.0"}`

### Memory Add (M+)

```bash
curl -X POST http://localhost:8000/memory/add \
  -H "Content-Type: application/json" \
  -H "X-Session-ID: my-session-123" \
  -d '{"value": 10.0}'
```

Response: `{"memory": 10.0, "operation": "M+ 10.0"}`

### Memory Recall (MR)

```bash
curl http://localhost:8000/memory \
  -H "X-Session-ID: my-session-123"
```

Response: `{"memory": 10.0}`

### Memory Clear (MC)

```bash
curl -X DELETE http://localhost:8000/memory \
  -H "X-Session-ID: my-session-123"
```

Response: `{"memory": 0.0, "operation": "MC"}`

## Error Examples

### Division by Zero

```bash
curl -X POST http://localhost:8000/calculate \
  -H "Content-Type: application/json" \
  -d '{"operand1": 10, "operand2": 0, "operator": "/"}'
```

Response (400): `{"error": "Division by zero", "code": "DIVISION_BY_ZERO"}`

### Invalid Operator

```bash
curl -X POST http://localhost:8000/calculate \
  -H "Content-Type: application/json" \
  -d '{"operand1": 10, "operand2": 5, "operator": "^"}'
```

Response (400): `{"error": "Invalid operator", "code": "INVALID_OPERATOR"}`

## Running Tests

```bash
# Run all tests with coverage
uv run pytest --cov=src --cov-report=term-missing

# Run unit tests only
uv run pytest tests/unit/

# Run integration tests
uv run pytest tests/integration/
```

## Linting & Type Checking

```bash
# Lint with ruff
uv run ruff check src/ tests/

# Format with ruff
uv run ruff format src/ tests/

# Type check with mypy
uv run mypy src/
```

