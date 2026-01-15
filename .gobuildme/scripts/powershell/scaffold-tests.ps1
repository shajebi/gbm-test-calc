#!/usr/bin/env pwsh
# Purpose: Scaffold integration test structure with samples and TODOs
# Why: Provides starting point for comprehensive integration testing
# How: Scans codebase, generates test files from templates

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Source common utilities (if available)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (Test-Path "$ScriptDir/qa-common.ps1") {
    . "$ScriptDir/qa-common.ps1"
}

Write-Host "🏗️ Scaffolding integration tests..." -ForegroundColor Green
Write-Host ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Check and generate architecture if needed
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📐 Checking Architecture Documentation..." -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

$archFile = ".gobuildme/docs/technical/architecture/technology-stack.md"

if (-not (Test-Path $archFile)) {
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host "❌ Architecture documentation not found" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host ""
    Write-Host "   /gbm.qa.scaffold-tests requires architecture documentation to:"
    Write-Host "   - Understand your tech stack (language, framework, database)"
    Write-Host "   - Generate appropriate test scaffolds (PHPUnit vs pytest vs Jest)"
    Write-Host "   - Create correct fixture patterns"
    Write-Host "   - Provide accurate test recommendations"
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "🎯 Action Required: Run /gbm.architecture first" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   1. Run: /gbm.architecture"
    Write-Host "   2. Review the generated architecture docs"
    Write-Host "   3. Commit if satisfied: git add . && git commit -m 'docs: add architecture documentation'"
    Write-Host "   4. Then run: /gbm.qa.scaffold-tests"
    Write-Host ""
    Write-Host "   NOTE: Architecture files are NOT auto-generated or auto-committed"
    Write-Host "         to ensure you review and approve them first."
    Write-Host ""
    exit 1
} else {
    Write-Host "✓ Architecture documentation found" -ForegroundColor Green
    Write-Host ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Detect language and framework
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function Get-Language {
    if ((Test-Path "requirements.txt") -or (Test-Path "pyproject.toml")) {
        return "python"
    } elseif (Test-Path "composer.json") {
        return "php"
    } elseif ((Test-Path "pom.xml") -or (Test-Path "build.gradle")) {
        return "java"
    } elseif (Test-Path "package.json") {
        return "javascript"
    } elseif (Test-Path "go.mod") {
        return "go"
    } elseif (Test-Path "Cargo.toml") {
        return "rust"
    } else {
        return "unknown"
    }
}

function Get-Framework {
    param([string]$Language)
    
    if ($Language -eq "python") {
        if ((Test-Path "requirements.txt") -and (Select-String -Path "requirements.txt" -Pattern "fastapi" -Quiet)) {
            return "fastapi"
        } elseif ((Test-Path "requirements.txt") -and (Select-String -Path "requirements.txt" -Pattern "django" -Quiet)) {
            return "django"
        } elseif ((Test-Path "requirements.txt") -and (Select-String -Path "requirements.txt" -Pattern "flask" -Quiet)) {
            return "flask"
        } else {
            return "unknown"
        }
    } elseif ($Language -eq "javascript") {
        if ((Test-Path "package.json") -and (Select-String -Path "package.json" -Pattern "express" -Quiet)) {
            return "express"
        } elseif ((Test-Path "package.json") -and (Select-String -Path "package.json" -Pattern "nestjs" -Quiet)) {
            return "nestjs"
        } else {
            return "unknown"
        }
    } else {
        return "unknown"
    }
}

$Language = Get-Language
$Framework = Get-Framework -Language $Language

Write-Host "🔍 Detected language: $Language" -ForegroundColor Cyan
Write-Host "🔍 Detected framework: $Framework" -ForegroundColor Cyan
Write-Host ""

# Create test directory structure
function New-TestStructure {
    Write-Host "📁 Creating test directory structure..." -ForegroundColor Yellow
    
    if ($Language -eq "python") {
        New-Item -ItemType Directory -Force -Path "tests/integration/api" | Out-Null
        New-Item -ItemType Directory -Force -Path "tests/integration/database" | Out-Null
        New-Item -ItemType Directory -Force -Path "tests/integration/queue" | Out-Null
        New-Item -ItemType Directory -Force -Path "tests/integration/external" | Out-Null
        New-Item -ItemType Directory -Force -Path "tests/integration/cache" | Out-Null
        New-Item -ItemType Directory -Force -Path "tests/fixtures" | Out-Null
        New-Item -ItemType Directory -Force -Path ".gobuildme/specs/qa-test-scaffolding" | Out-Null
        
        # Create __init__.py files
        New-Item -ItemType File -Force -Path "tests/__init__.py" | Out-Null
        New-Item -ItemType File -Force -Path "tests/integration/__init__.py" | Out-Null
        New-Item -ItemType File -Force -Path "tests/integration/api/__init__.py" | Out-Null
        New-Item -ItemType File -Force -Path "tests/integration/database/__init__.py" | Out-Null
        New-Item -ItemType File -Force -Path "tests/integration/queue/__init__.py" | Out-Null
        New-Item -ItemType File -Force -Path "tests/integration/external/__init__.py" | Out-Null
        New-Item -ItemType File -Force -Path "tests/integration/cache/__init__.py" | Out-Null
        New-Item -ItemType File -Force -Path "tests/fixtures/__init__.py" | Out-Null
    } elseif ($Language -eq "javascript") {
        New-Item -ItemType Directory -Force -Path "tests/integration/api" | Out-Null
        New-Item -ItemType Directory -Force -Path "tests/integration/database" | Out-Null
        New-Item -ItemType Directory -Force -Path "tests/integration/queue" | Out-Null
        New-Item -ItemType Directory -Force -Path "tests/integration/external" | Out-Null
        New-Item -ItemType Directory -Force -Path "tests/integration/cache" | Out-Null
        New-Item -ItemType Directory -Force -Path "tests/fixtures" | Out-Null
        New-Item -ItemType Directory -Force -Path ".gobuildme/specs/qa-test-scaffolding" | Out-Null
    }
    
    Write-Host "  ✓ Created test directory structure" -ForegroundColor Green
}

# Copy fixture templates
function Copy-Fixtures {
    Write-Host "📋 Copying fixture templates..." -ForegroundColor Yellow
    
    $templateDir = ".gobuildme/templates/test-templates/fixtures"
    
    if (Test-Path $templateDir) {
        if ($Language -eq "python") {
            Copy-Item "$templateDir/api_fixtures.py" "tests/fixtures/" -ErrorAction SilentlyContinue
            Copy-Item "$templateDir/database_fixtures.py" "tests/fixtures/" -ErrorAction SilentlyContinue
            Copy-Item "$templateDir/mock_services.py" "tests/fixtures/" -ErrorAction SilentlyContinue
            Write-Host "  ✓ Copied fixture templates" -ForegroundColor Green
        }
    } else {
        Write-Host "  ⚠️  Template directory not found, skipping fixtures" -ForegroundColor Yellow
    }
}

# Generate conftest.py
function New-Conftest {
    if ($Language -eq "python") {
        Write-Host "📝 Generating conftest.py..." -ForegroundColor Yellow
        
        $conftestContent = @'
"""
Pytest configuration and shared fixtures

This file is automatically loaded by pytest and provides:
- Shared fixtures available to all tests
- Pytest configuration
- Test hooks
"""

import pytest
import sys
from pathlib import Path

# Add project root to Python path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

# Import fixtures from fixtures directory
pytest_plugins = [
    "tests.fixtures.api_fixtures",
    "tests.fixtures.database_fixtures",
    "tests.fixtures.mock_services",
]


@pytest.fixture(scope="session", autouse=True)
def setup_test_environment():
    """
    Setup test environment before running tests
    
    This runs once per test session
    """
    # TODO: Add test environment setup
    # - Set environment variables
    # - Initialize test database
    # - Start test services
    
    yield
    
    # TODO: Add test environment teardown
    # - Clean up test data
    # - Stop test services


@pytest.fixture(autouse=True)
def reset_test_state():
    """
    Reset test state before each test
    
    This runs before each test function
    """
    # TODO: Add state reset logic
    # - Clear caches
    # - Reset mocks
    # - Clean up test data
    
    yield
    
    # TODO: Add cleanup after each test
'@
        
        Set-Content -Path "tests/conftest.py" -Value $conftestContent
        Write-Host "  ✓ Generated conftest.py" -ForegroundColor Green
    }
}

# Generate sample API test
function New-SampleApiTest {
    if ($Language -eq "python") {
        Write-Host "📝 Generating sample API test..." -ForegroundColor Yellow
        
        $sampleTestContent = @'
"""
SAMPLE: Integration tests for API endpoints

This is a sample test file demonstrating best practices.
Use this as a template for your own API tests.

Delete this file once you've created your actual tests.
"""

import pytest
from tests.fixtures.api_fixtures import test_client, auth_headers


def test_sample_get_endpoint(test_client):
    """
    SAMPLE: Test GET endpoint
    
    This demonstrates:
    - Making GET request
    - Checking status code
    - Validating response structure
    """
    response = test_client.get("/api/health")
    
    assert response.status_code == 200
    data = response.json()
    assert "status" in data


def test_sample_post_endpoint(test_client, auth_headers):
    """
    SAMPLE: Test POST endpoint with authentication
    
    This demonstrates:
    - Making POST request
    - Using authentication
    - Sending JSON data
    - Validating response
    """
    payload = {
        "name": "Test Item",
        "description": "Test description"
    }
    
    response = test_client.post(
        "/api/items",
        headers=auth_headers,
        json=payload
    )
    
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == payload["name"]


# TODO: Replace this sample file with your actual API tests
# 1. Identify your API endpoints
# 2. Create test files for each resource (e.g., test_users_api.py)
# 3. Use the templates in .gobuildme/templates/test-templates/
# 4. Delete this sample file
'@
        
        Set-Content -Path "tests/integration/api/test_sample_api.py" -Value $sampleTestContent
        Write-Host "  ✓ Generated sample API test" -ForegroundColor Green
    }
}

# Generate README
function New-TestReadme {
    Write-Host "📝 Generating test README..." -ForegroundColor Yellow
    
    $readmeContent = @'
# Integration Tests

This directory contains integration tests scaffolded by `/gbm.scaffold-tests`.

## Structure

```
tests/
├── integration/
│   ├── api/          # API endpoint tests
│   ├── database/     # Database model tests
│   ├── queue/        # Message queue tests
│   ├── external/     # External service tests
│   └── cache/        # Cache operation tests
├── fixtures/
│   ├── api_fixtures.py       # API test fixtures
│   ├── database_fixtures.py  # Database fixtures
│   └── mock_services.py      # External service mocks
└── conftest.py       # Pytest configuration
```

## Running Tests

```bash
# Run all integration tests
pytest tests/integration/

# Run specific test type
pytest tests/integration/api/
pytest tests/integration/database/

# Run with coverage
pytest --cov=app tests/integration/

# Run with verbose output
pytest -v tests/integration/
```

## Next Steps

1. **Review generated files**: Check the sample tests and fixtures
2. **Customize fixtures**: Adapt fixtures to your data models
3. **Implement TODO tests**: Fill in the TODO test cases
4. **Add more tests**: Create additional test files as needed
5. **Run tests**: Execute tests and measure coverage

## Best Practices

- **Use fixtures**: Reuse test data and setup code
- **Test isolation**: Each test should be independent
- **Clear assertions**: Make test failures easy to understand
- **Mock external services**: Don't call real external APIs in tests
- **Measure coverage**: Aim for 95%+ integration test coverage

## Resources

- Pytest documentation: https://docs.pytest.org/
- Testing best practices: See `.gobuildme/specs/qa-test-scaffolding/scaffold-report.md`
'@
    
    Set-Content -Path "tests/README.md" -Value $readmeContent
    Write-Host "  ✓ Generated test README" -ForegroundColor Green
}

# Generate scaffold report
function New-ScaffoldReport {
    Write-Host "📄 Generating scaffold report..." -ForegroundColor Yellow
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $reportContent = @"
# Test Scaffolding Report

Generated: $timestamp

## Summary

- **Language**: $Language
- **Framework**: $Framework
- **Test Directory**: tests/integration/
- **Fixtures Directory**: tests/fixtures/

## Generated Files

### Test Structure
- ``tests/integration/api/`` - API endpoint tests
- ``tests/integration/database/`` - Database model tests
- ``tests/integration/queue/`` - Message queue tests
- ``tests/integration/external/`` - External service tests
- ``tests/integration/cache/`` - Cache operation tests

### Fixtures
- ``tests/fixtures/api_fixtures.py`` - API test fixtures (sample)
- ``tests/fixtures/database_fixtures.py`` - Database fixtures (sample)
- ``tests/fixtures/mock_services.py`` - External service mocks (sample)

### Configuration
- ``tests/conftest.py`` - Pytest configuration
- ``tests/README.md`` - Testing documentation

## Next Steps

See tests/README.md for detailed next steps and best practices.
"@
    
    Set-Content -Path ".gobuildme/specs/qa-test-scaffolding/scaffold-report.md" -Value $reportContent
    Write-Host "  ✓ Generated scaffold report" -ForegroundColor Green
}

# Main execution
New-TestStructure
Copy-Fixtures
New-Conftest
New-SampleApiTest
New-TestReadme
New-ScaffoldReport

Write-Host ""
Write-Host "✅ Scaffolding complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "  - Test structure created in tests/integration/"
Write-Host "  - Sample fixtures copied to tests/fixtures/"
Write-Host "  - Configuration generated in tests/conftest.py"
Write-Host "  - Sample test created in tests/integration/api/"
Write-Host ""
Write-Host "📄 Report saved to: .gobuildme/specs/qa-test-scaffolding/scaffold-report.md" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Review generated files in tests/"
Write-Host "  2. Customize fixtures for your models"
Write-Host "  3. Implement TODO tests"
Write-Host "  4. Run tests: pytest tests/integration/"
Write-Host "  5. Measure coverage: pytest --cov=app tests/"

