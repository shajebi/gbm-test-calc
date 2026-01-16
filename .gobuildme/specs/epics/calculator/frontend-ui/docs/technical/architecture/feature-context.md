# Feature Context: Calculator Frontend UI

## Overview
This document captures the architectural context for the frontend-ui slice of the calculator epic.

## Dependencies

### Backend API (PR-1)
- **Endpoints consumed**: `/calculate`, `/memory/add`, `/memory/subtract`, `/memory`, `/memory` (DELETE)
- **Session management**: `X-Session-ID` header
- **Base URL**: `http://localhost:8000` (development)

## Frontend Architecture

### Component Structure
```
static/
├── index.html       # Single-page layout
├── css/
│   └── styles.css   # Calculator styling
└── js/
    ├── app.js       # Main entry point
    ├── calculator.js # State management
    └── api.js       # Backend client
```

### State Management
- **Local state**: Current display value, pending operator, first operand
- **Session state**: UUID stored in localStorage
- **Backend state**: Memory value per session (via API)

### API Integration
- Fetch API for HTTP requests
- Session ID attached to all requests
- Error handling with user-friendly messages

## Technology Choices

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| Markup | HTML5 | Semantic structure, no framework needed |
| Styling | CSS3 | Flexbox/Grid, responsive, CSS variables ready |
| Logic | Vanilla JS (ES6+) | Simple app, no build tools required |
| HTTP | Fetch API | Native browser API, promise-based |

## Constraints

- No build tools or transpilation
- No external JavaScript libraries
- Must work with backend on localhost:8000
- Session ID required for all memory operations

## Testing Strategy

- **Unit tests**: JavaScript state logic (Jest or browser-native)
- **Integration tests**: API client with mocked responses
- **E2E tests**: Full workflow with real backend (pytest + Playwright/Selenium)

