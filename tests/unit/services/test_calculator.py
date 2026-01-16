"""Unit tests for calculator service."""

import pytest


class TestCalculatorService:
    """Tests for calculate function."""

    def test_add_positive_numbers(self) -> None:
        """Returns sum for addition (AC-001)."""
        from src.services.calculator import calculate

        result = calculate(10.0, 5.0, "+")
        assert result == 15.0

    def test_subtract_numbers(self) -> None:
        """Returns difference for subtraction (AC-002)."""
        from src.services.calculator import calculate

        result = calculate(10.0, 3.0, "-")
        assert result == 7.0

    def test_multiply_numbers(self) -> None:
        """Returns product for multiplication (AC-003)."""
        from src.services.calculator import calculate

        result = calculate(4.0, 5.0, "*")
        assert result == 20.0

    def test_divide_numbers(self) -> None:
        """Returns quotient for division (AC-004)."""
        from src.services.calculator import calculate

        result = calculate(20.0, 4.0, "/")
        assert result == 5.0

    def test_divide_by_zero_raises_error(self) -> None:
        """Raises DivisionByZeroError for division by zero (AC-E01)."""
        from src.exceptions import DivisionByZeroError
        from src.services.calculator import calculate

        with pytest.raises(DivisionByZeroError):
            calculate(10.0, 0.0, "/")

    def test_invalid_operator_raises_error(self) -> None:
        """Raises InvalidOperatorError for unknown operator (AC-E02)."""
        from src.exceptions import InvalidOperatorError
        from src.services.calculator import calculate

        with pytest.raises(InvalidOperatorError):
            calculate(10.0, 5.0, "^")

    def test_negative_result(self) -> None:
        """Handles negative results correctly (AC-B03)."""
        from src.services.calculator import calculate

        result = calculate(5.0, 10.0, "-")
        assert result == -5.0

    def test_floating_point_precision(self) -> None:
        """Handles floating-point precision (AC-B04)."""
        from src.services.calculator import calculate

        result = calculate(0.1, 0.2, "+")
        assert abs(result - 0.3) < 1e-10

    def test_large_number_overflow(self) -> None:
        """Handles large numbers without overflow (AC-B01)."""
        from src.services.calculator import calculate

        result = calculate(1e15, 1e15, "+")
        assert result == 2e15
