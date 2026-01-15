"""Memory endpoints for calculator memory operations."""

import uuid

from fastapi import APIRouter, Header

from src.models import MemoryResponse, MemoryValueRequest
from src.services.memory import (
    add_to_memory,
    clear_memory,
    get_memory,
    subtract_from_memory,
)

router = APIRouter(prefix="/memory", tags=["memory"])


def get_session_id(x_session_id: str | None = Header(default=None)) -> str:
    """Get or generate session ID from header."""
    if x_session_id:
        return x_session_id
    return str(uuid.uuid4())


@router.post("/add", response_model=MemoryResponse)
def memory_add(
    request: MemoryValueRequest,
    x_session_id: str | None = Header(default=None),
) -> MemoryResponse:
    """Add value to memory."""
    session_id = get_session_id(x_session_id)
    new_value = add_to_memory(session_id, request.value)
    return MemoryResponse(value=new_value, message="Value added to memory")


@router.post("/subtract", response_model=MemoryResponse)
def memory_subtract(
    request: MemoryValueRequest,
    x_session_id: str | None = Header(default=None),
) -> MemoryResponse:
    """Subtract value from memory."""
    session_id = get_session_id(x_session_id)
    new_value = subtract_from_memory(session_id, request.value)
    return MemoryResponse(value=new_value, message="Value subtracted from memory")


@router.get("", response_model=MemoryResponse)
def memory_recall(
    x_session_id: str | None = Header(default=None),
) -> MemoryResponse:
    """Recall current memory value."""
    session_id = get_session_id(x_session_id)
    value = get_memory(session_id)
    return MemoryResponse(value=value, message="Memory recalled")


@router.delete("", response_model=MemoryResponse)
def memory_clear(
    x_session_id: str | None = Header(default=None),
) -> MemoryResponse:
    """Clear memory for session."""
    session_id = get_session_id(x_session_id)
    clear_memory(session_id)
    return MemoryResponse(value=0.0, message="Memory cleared")
