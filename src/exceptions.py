"""Custom exceptions for calculator API."""


class CalculatorError(Exception):
    """Base exception for calculator errors."""

    def __init__(self, message: str, code: str) -> None:
        self.message = message
        self.code = code
        super().__init__(message)


class DivisionByZeroError(CalculatorError):
    """Raised when division by zero is attempted."""

    def __init__(self) -> None:
        super().__init__("Cannot divide by zero", "DIVISION_BY_ZERO")


class InvalidOperatorError(CalculatorError):
    """Raised when an invalid operator is provided."""

    def __init__(self, operator: str) -> None:
        super().__init__(f"Invalid operator: {operator}", "INVALID_OPERATOR")


class OverflowError(CalculatorError):
    """Raised when calculation result overflows."""

    def __init__(self) -> None:
        super().__init__("Calculation result overflow", "OVERFLOW")
