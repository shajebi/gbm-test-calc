# Raw Architecture Data Collection (Existing Codebase)

**IMPORTANT**: This is RAW DATA ONLY - AI Agent must create actual architecture documentation
**Purpose**: Data collection for AI Agent to analyze and generate comprehensive architecture documentation
**Codebase Status**: Existing code detected - AI Agent should run /architecture command for global analysis
**AI Action Required**: Create system-analysis.md, component-architecture.md, and other architecture docs

## Project Structure Data
```json
{
  "directories": [
    ".",
    ".docs",
    ".docs/implementations",
    ".docs/implementations/calculator-backend-api",
    ".pytest_cache",
    ".pytest_cache/v",
    ".pytest_cache/v/cache",
    ".augment",
    ".augment/commands",
    ".ruff_cache",
    ".ruff_cache/0.14.11",
    "tests",
    "tests/unit",
    "tests/unit/__pycache__",
    "tests/unit/services",
    "tests/js",
    "tests/js/unit",
    "tests/js/integration",
    "tests/integration",
    "tests/integration/__pycache__",
    "tests/__pycache__",
    "tests/api",
    "tests/api/contracts",
    "tests/api/__pycache__",
    "tests/e2e",
    "tests/e2e/__pycache__",
    "docs",
    ".mypy_cache",
    ".mypy_cache/3.11",
    ".mypy_cache/3.11/zoneinfo",
    ".mypy_cache/3.11/ctypes",
    ".mypy_cache/3.11/annotated_types",
    ".mypy_cache/3.11/pathlib",
    ".mypy_cache/3.11/multiprocessing",
    ".mypy_cache/3.11/starlette",
    ".mypy_cache/3.11/_typeshed",
    ".mypy_cache/3.11/urllib",
    ".mypy_cache/3.11/zipfile",
    ".mypy_cache/3.11/idna",
    ".mypy_cache/3.11/html",
    ".mypy_cache/3.11/anyio",
    ".mypy_cache/3.11/sys",
    ".mypy_cache/3.11/json",
    ".mypy_cache/3.11/annotated_doc",
    ".mypy_cache/3.11/http",
    ".mypy_cache/3.11/fastapi",
    ".mypy_cache/3.11/concurrent",
    ".mypy_cache/3.11/os",
    ".mypy_cache/3.11/string",
    ".mypy_cache/3.11/importlib",
    ".mypy_cache/3.11/pydantic",
    ".mypy_cache/3.11/collections",
    ".mypy_cache/3.11/typing_inspection",
    ".mypy_cache/3.11/asyncio",
    ".mypy_cache/3.11/logging",
    ".mypy_cache/3.11/email",
    ".mypy_cache/3.11/pydantic_core",
    ".mypy_cache/3.11/src",
    "static",
    "static/css",
    "static/js",
    "src",
    "src/__pycache__",
    "src/routes",
    "src/routes/__pycache__",
    "src/services",
    "src/services/__pycache__"
  ],
  "config_files": [
    "pyproject.toml"
    ""
  ],
  "framework_indicators": [
    
  ]
}
```

## Technology Stack Indicators
```json
{
  "languages": {
    "javascript":        6,
    "python":       26,
    "total": 0
  },
  "database_indicators": [
    
  ],
  "infrastructure_indicators": [
    
  ]
}
```

## Architectural Pattern Indicators
```json
{
  "mvc_indicators": {
    "models_dir": false,
    "views_dir": false,
    "controllers_dir": false
  },
  "microservices_indicators": {
    "docker_compose": false,
    "dockerfile": false,
    "kubernetes": false,
    "services_dir": false
  },
  "api_patterns": [
    "versioned_api","graphql","rest_api"
  ],
  "event_driven_indicators": [
    "events","listeners","queues","observers"
  ]
}
```

## Security & Integration Indicators
```json
{
  "authentication_indicators": [
    "oauth","session"
  ],
  "authorization_indicators": [
    "roles","permissions","policies"
  ],
  "external_service_indicators": [
    
  ]
}
```

## Data Collection Summary
```json
{
  "collection_metadata": {
    "project_root": "/Users/shajebi/Code/personal/gbm-test-calc",
    "analysis_version": "2.0",
    "data_collector": "GoBuildMe Architecture Data Collector"
  },
  "ai_agent_instructions": {
    "purpose": "Generate comprehensive architectural analysis from collected data",
    "focus": "High-level strategic architectural insights and system design understanding",
    "output_format": "Executive-level architectural documentation with business context",
    "analysis_areas": ["architectural_style", "technology_decisions", "component_relationships", "scalability_patterns", "security_architecture", "integration_landscape"]
  }
}
```

---
**Next Step**: This raw data should be analyzed by an AI Agent to generate comprehensive architectural insights and strategic recommendations.
