"""Calculate endpoint for arithmetic operations."""

from fastapi import APIRouter

from src.models import CalculationRequest, CalculationResponse
from src.services.calculator import calculate

router = APIRouter()


@router.post("/calculate", response_model=CalculationResponse)
def calculate_endpoint(request: CalculationRequest) -> CalculationResponse:
    """Perform arithmetic calculation.

    Args:
        request: Calculation request with operands and operator

    Returns:
        Calculation response with result and expression
    """
    result = calculate(request.operand1, request.operand2, request.operator)
    expression = f"{request.operand1} {request.operator} {request.operand2} = {result}"
    return CalculationResponse(result=result, expression=expression)

