"""Contract tests for /calculate API response schemas."""

from fastapi.testclient import TestClient


class TestCalculateContract:
    """Tests for calculate endpoint response schemas."""

    def test_calculate_200_schema(self, client: TestClient) -> None:
        """Success response matches CalculationResponse schema."""
        response = client.post(
            "/calculate",
            json={"operand1": 10.0, "operand2": 5.0, "operator": "+"},
        )
        assert response.status_code == 200
        data = response.json()
        assert "result" in data
        assert isinstance(data["result"], (int, float))
        assert "expression" in data
        assert isinstance(data["expression"], str)

    def test_calculate_400_error_schema(self, client: TestClient) -> None:
        """Division by zero error matches ErrorResponse schema."""
        response = client.post(
            "/calculate",
            json={"operand1": 10.0, "operand2": 0.0, "operator": "/"},
        )
        assert response.status_code == 400
        data = response.json()
        assert "error" in data
        assert isinstance(data["error"], str)
        assert "code" in data
        assert isinstance(data["code"], str)

    def test_calculate_422_validation_schema(self, client: TestClient) -> None:
        """Validation error has structured detail."""
        response = client.post(
            "/calculate",
            json={"operand1": "invalid"},
        )
        assert response.status_code == 422
        data = response.json()
        assert "detail" in data
