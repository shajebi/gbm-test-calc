---
description: "Quickstart guide for calculator frontend development and testing"
metadata:
  feature_name: "calculator--frontend-ui"
  artifact_type: quickstart
  created_timestamp: "2026-01-15T17:40:00Z"
---

# Quickstart: Calculator Frontend UI

## Prerequisites

- Python 3.11+ with uv installed
- Node.js 18+ (for Jest tests)
- Backend running (PR-1 required)

## Development Setup

```bash
# 1. Start backend (from repo root)
uv run uvicorn src.main:app --reload --port 8000

# 2. Open browser
open http://localhost:8000/
```

## Running Tests

### Backend Tests (existing)
```bash
uv run pytest --cov=src --cov-report=term-missing
```

### JavaScript Unit Tests
```bash
cd tests/js
npm install
npm test
```

### E2E Tests (Playwright)
```bash
# Install Playwright browsers (first time)
uv run playwright install chromium

# Run E2E tests (backend must be running)
uv run pytest tests/e2e/ -v
```

## Manual Validation Scenarios

### Basic Calculation (AC-001 to AC-005)
1. Open calculator page
2. Click: 5, +, 3, =
3. Verify display shows "8"
4. Click: C
5. Verify display shows "0"

### Memory Operations (AC-006 to AC-009)
1. Calculate: 10 + 5 = (shows "15")
2. Click: M+
3. Verify "M" indicator appears
4. Click: C (display shows "0")
5. Click: MR
6. Verify display shows "15"
7. Click: MC
8. Verify "M" indicator disappears

### Error Handling (AC-E01 to AC-E03)
1. Calculate: 5, /, 0, =
2. Verify display shows "Cannot divide by zero"
3. Stop backend (Ctrl+C)
4. Click: 5, +, 3, =
5. Verify display shows "Connection error"

### Edge Cases (AC-B01 to AC-B03)
1. Click: 5, ., 3, . (second decimal ignored)
2. Click: = (without operator, no change)
3. Calculate: 99999999999999 * 99999999999999 (verify scientific notation)

## File Structure

```
static/
├── index.html       # Entry point
├── css/
│   └── styles.css   # All styles
└── js/
    ├── app.js       # DOM initialization
    ├── calculator.js # State management
    └── api.js       # Backend client
```

## Configuration

### Base URL (api.js)
```javascript
const API_BASE_URL = 'http://localhost:8000';
```

### Session ID
- Auto-generated UUID on first load
- Stored in `localStorage.session_id`
- Sent via `X-Session-ID` header

## Common Issues

| Issue | Solution |
|-------|----------|
| "Connection error" on all clicks | Start backend: `uv run uvicorn src.main:app --reload` |
| CORS errors | Backend running on different port? Check FastAPI CORS config |
| Session lost on refresh | Check localStorage not blocked by browser |
| Tests failing | Ensure Node.js 18+ and Playwright browsers installed |

