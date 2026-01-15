"""Integration tests for /calculate API endpoint."""

import time

from fastapi.testclient import TestClient


class TestCalculateAPI:
    """Tests for POST /calculate endpoint."""

    def test_calculate_addition_returns_200(self, client: TestClient) -> None:
        """POST /calculate with addition returns 200."""
        response = client.post(
            "/calculate",
            json={"operand1": 10.0, "operand2": 5.0, "operator": "+"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["result"] == 15.0
        assert "expression" in data

    def test_calculate_division_by_zero_returns_400(self, client: TestClient) -> None:
        """POST /calculate with division by zero returns 400."""
        response = client.post(
            "/calculate",
            json={"operand1": 10.0, "operand2": 0.0, "operator": "/"},
        )
        assert response.status_code == 400
        data = response.json()
        assert "error" in data

    def test_calculate_invalid_operator_returns_400(self, client: TestClient) -> None:
        """POST /calculate with invalid operator returns 400."""
        response = client.post(
            "/calculate",
            json={"operand1": 10.0, "operand2": 5.0, "operator": "^"},
        )
        assert response.status_code == 400
        data = response.json()
        assert "error" in data

    def test_calculate_missing_fields_returns_422(self, client: TestClient) -> None:
        """POST /calculate with missing fields returns 422."""
        response = client.post(
            "/calculate",
            json={"operand1": 10.0},
        )
        assert response.status_code == 422

    def test_calculate_response_time_under_100ms(self, client: TestClient) -> None:
        """POST /calculate responds in under 100ms (AC-P01)."""
        start = time.time()
        response = client.post(
            "/calculate",
            json={"operand1": 10.0, "operand2": 5.0, "operator": "+"},
        )
        elapsed = (time.time() - start) * 1000
        assert response.status_code == 200
        assert elapsed < 100, f"Response took {elapsed:.1f}ms, expected <100ms"
