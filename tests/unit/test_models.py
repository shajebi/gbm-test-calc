"""Unit tests for Pydantic models."""

import pytest
from pydantic import ValidationError


class TestCalculationRequest:
    """Tests for CalculationRequest model."""

    def test_calculation_request_valid(self) -> None:
        """Valid request with all fields parses correctly."""
        from src.models import CalculationRequest

        request = CalculationRequest(operand1=10.5, operand2=5.0, operator="+")
        assert request.operand1 == 10.5
        assert request.operand2 == 5.0
        assert request.operator == "+"

    def test_calculation_request_missing_field(self) -> None:
        """Missing required field raises ValidationError."""
        from src.models import CalculationRequest

        with pytest.raises(ValidationError):
            CalculationRequest(operand1=10.5, operator="+")  # type: ignore[call-arg]

    def test_calculation_request_invalid_type(self) -> None:
        """Non-numeric operand raises ValidationError."""
        from src.models import CalculationRequest

        with pytest.raises(ValidationError):
            CalculationRequest(operand1="abc", operand2=5.0, operator="+")  # type: ignore[arg-type]


class TestMemoryValueRequest:
    """Tests for MemoryValueRequest model."""

    def test_memory_value_request_valid(self) -> None:
        """Valid memory request parses correctly."""
        from src.models import MemoryValueRequest

        request = MemoryValueRequest(value=42.5)
        assert request.value == 42.5


class TestCalculationResponse:
    """Tests for CalculationResponse model."""

    def test_calculation_response_structure(self) -> None:
        """Response has required fields."""
        from src.models import CalculationResponse

        response = CalculationResponse(result=15.5, expression="10.5 + 5.0 = 15.5")
        assert response.result == 15.5
        assert response.expression == "10.5 + 5.0 = 15.5"


class TestMemoryResponse:
    """Tests for MemoryResponse model."""

    def test_memory_response_structure(self) -> None:
        """Memory response has required fields."""
        from src.models import MemoryResponse

        response = MemoryResponse(value=100.0, message="Memory updated")
        assert response.value == 100.0
        assert response.message == "Memory updated"
