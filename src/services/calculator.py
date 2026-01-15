"""Calculator service for arithmetic operations."""

from src.exceptions import DivisionByZeroError, InvalidOperatorError


def calculate(operand1: float, operand2: float, operator: str) -> float:
    """Perform arithmetic calculation.

    Args:
        operand1: First operand
        operand2: Second operand
        operator: Arithmetic operator (+, -, *, /)

    Returns:
        Result of the calculation

    Raises:
        DivisionByZeroError: If dividing by zero
        InvalidOperatorError: If operator is not supported
    """
    if operator == "+":
        return operand1 + operand2
    elif operator == "-":
        return operand1 - operand2
    elif operator == "*":
        return operand1 * operand2
    elif operator == "/":
        if operand2 == 0:
            raise DivisionByZeroError()
        return operand1 / operand2
    else:
        raise InvalidOperatorError(operator)
