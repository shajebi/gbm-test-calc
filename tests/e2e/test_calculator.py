"""
E2E tests for calculator workflow.
Tests AC-001 to AC-004, AC-006 to AC-008, AC-E01
"""

import pytest
from fastapi.testclient import TestClient

from src.main import app


@pytest.fixture
def client():
    """Create test client."""
    return TestClient(app)


class TestCalculatorE2E:
    """E2E tests for calculator workflows."""

    def test_addition_workflow(self, client):
        """AC-001 to AC-004: 5 + 3 = 8"""
        response = client.post(
            "/calculate",
            json={"operand1": 5, "operand2": 3, "operator": "+"},
        )
        assert response.status_code == 200
        assert response.json()["result"] == 8

    def test_subtraction_workflow(self, client):
        """10 - 4 = 6"""
        response = client.post(
            "/calculate",
            json={"operand1": 10, "operand2": 4, "operator": "-"},
        )
        assert response.status_code == 200
        assert response.json()["result"] == 6

    def test_multiplication_workflow(self, client):
        """6 * 7 = 42"""
        response = client.post(
            "/calculate",
            json={"operand1": 6, "operand2": 7, "operator": "*"},
        )
        assert response.status_code == 200
        assert response.json()["result"] == 42

    def test_division_workflow(self, client):
        """15 / 3 = 5"""
        response = client.post(
            "/calculate",
            json={"operand1": 15, "operand2": 3, "operator": "/"},
        )
        assert response.status_code == 200
        assert response.json()["result"] == 5

    def test_memory_workflow(self, client):
        """AC-006 to AC-008: M+, MR, MC sequence"""
        session_id = "e2e-test-session"
        headers = {"X-Session-ID": session_id}

        # M+: Add 10 to memory
        response = client.post(
            "/memory/add",
            json={"value": 10},
            headers=headers,
        )
        assert response.status_code == 200
        assert response.json()["value"] == 10

        # MR: Recall memory
        response = client.get("/memory", headers=headers)
        assert response.status_code == 200
        assert response.json()["value"] == 10

        # MC: Clear memory
        response = client.delete("/memory", headers=headers)
        assert response.status_code == 200
        assert response.json()["value"] == 0

    def test_error_display(self, client):
        """AC-E01: Division by zero shows error"""
        response = client.post(
            "/calculate",
            json={"operand1": 10, "operand2": 0, "operator": "/"},
        )
        assert response.status_code == 400
        assert "divide by zero" in response.json()["error"].lower()

    def test_chained_operations(self, client):
        """5 + 3 = 8, then 8 + 2 = 10"""
        # First calculation
        response = client.post(
            "/calculate",
            json={"operand1": 5, "operand2": 3, "operator": "+"},
        )
        result1 = response.json()["result"]
        assert result1 == 8

        # Chain: use result as first operand
        response = client.post(
            "/calculate",
            json={"operand1": result1, "operand2": 2, "operator": "+"},
        )
        assert response.json()["result"] == 10

    def test_index_page_served(self, client):
        """Verify index.html is served at root."""
        response = client.get("/")
        assert response.status_code == 200
        assert "text/html" in response.headers["content-type"]

