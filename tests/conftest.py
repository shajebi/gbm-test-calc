"""Pytest fixtures for calculator API tests."""

import uuid
from collections.abc import Generator
from typing import Any

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def session_id() -> str:
    """Generate a unique session ID for each test."""
    return str(uuid.uuid4())


@pytest.fixture
def session_headers(session_id: str) -> dict[str, str]:
    """Headers with session ID for API requests."""
    return {"X-Session-ID": session_id}


@pytest.fixture
def app() -> Any:
    """FastAPI application instance."""
    from src.main import app
    return app


@pytest.fixture
def client(app: Any) -> Generator[TestClient, None, None]:
    """Test client for the FastAPI application."""
    with TestClient(app) as c:
        yield c

