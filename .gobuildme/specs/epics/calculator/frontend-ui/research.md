---
description: "Research decisions for calculator frontend UI implementation"
metadata:
  feature_name: "calculator--frontend-ui"
  artifact_type: research
  created_timestamp: "2026-01-15T17:40:00Z"
---

# Research: Calculator Frontend UI

## Summary

All technology decisions resolved via constitution and spec analysis. No external research required.

## Technology Decisions

### Framework Choice

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| React | Component model, ecosystem | Build tools, complexity | ❌ Rejected |
| Vue | Simpler than React | Still requires build | ❌ Rejected |
| **Vanilla JS** | No build, simple, fast | Manual DOM management | ✅ Selected |

**Rationale**: Constitution mandates simplicity; vanilla JS aligns with "no build tools required" constraint.

### Styling Approach

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| Tailwind | Utility classes | Requires build | ❌ Rejected |
| SCSS | Variables, nesting | Requires compilation | ❌ Rejected |
| **CSS3** | Native, no build | Slightly more verbose | ✅ Selected |

**Rationale**: Native CSS3 with Flexbox/Grid provides all needed features without build step.

### API Client

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| Axios | Nice API, interceptors | External dependency | ❌ Rejected |
| **Fetch API** | Native, promise-based | Slightly more verbose | ✅ Selected |

**Rationale**: Fetch is built into all modern browsers; no external dependencies.

### Session Storage

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| Cookies | Automatic sending | More complex setup | ❌ Rejected |
| **localStorage** | Simple API, persists | Manual header management | ✅ Selected |

**Rationale**: localStorage is simpler and sufficient for session UUID persistence.

### Testing Strategy

| Type | Tool | Rationale |
|------|------|-----------|
| Unit | Jest | Industry standard for JS testing |
| Integration | Jest + MSW | Mock Service Worker for API mocking |
| E2E | Playwright | Modern, reliable, cross-browser |

## Constraints Addressed

| Constraint | Solution |
|------------|----------|
| No hardcoded values | Base URL as const in api.js |
| No build tools | Plain HTML/CSS/JS |
| 85% coverage | Jest + Playwright coverage |
| Performance <200ms | Fetch API, minimal DOM |

## Alternatives Considered

### Build Tool Stack
Rejected Vite + TypeScript for simplicity. TypeScript would add compile step and complexity beyond what this simple calculator needs.

### CSS-in-JS
Rejected styled-components/emotion for same reason — requires build tooling.

### State Management Library
Rejected Redux/MobX — vanilla JS object sufficient for 5-field calculator state.

