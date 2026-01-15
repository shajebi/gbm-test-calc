"""Pydantic models for calculator API requests and responses."""

from pydantic import BaseModel


class CalculationRequest(BaseModel):
    """Request model for calculation endpoint."""

    operand1: float
    operand2: float
    operator: str


class CalculationResponse(BaseModel):
    """Response model for calculation endpoint."""

    result: float
    expression: str


class MemoryValueRequest(BaseModel):
    """Request model for memory operations requiring a value."""

    value: float


class MemoryResponse(BaseModel):
    """Response model for memory operations."""

    value: float
    message: str


class ErrorResponse(BaseModel):
    """Response model for error responses."""

    error: str
    code: str

