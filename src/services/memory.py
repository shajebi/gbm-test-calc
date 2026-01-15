"""Memory service for session-based calculator memory."""

_memory_store: dict[str, float] = {}


def get_memory(session_id: str) -> float:
    """Get current memory value for session.

    Args:
        session_id: Unique session identifier

    Returns:
        Current memory value (0.0 for new sessions)
    """
    return _memory_store.get(session_id, 0.0)


def set_memory(session_id: str, value: float) -> None:
    """Set memory value for session.

    Args:
        session_id: Unique session identifier
        value: New memory value
    """
    _memory_store[session_id] = value


def add_to_memory(session_id: str, value: float) -> float:
    """Add value to memory.

    Args:
        session_id: Unique session identifier
        value: Value to add

    Returns:
        New memory value
    """
    current = get_memory(session_id)
    new_value = current + value
    set_memory(session_id, new_value)
    return new_value


def subtract_from_memory(session_id: str, value: float) -> float:
    """Subtract value from memory.

    Args:
        session_id: Unique session identifier
        value: Value to subtract

    Returns:
        New memory value
    """
    current = get_memory(session_id)
    new_value = current - value
    set_memory(session_id, new_value)
    return new_value


def clear_memory(session_id: str) -> None:
    """Clear memory for session.

    Args:
        session_id: Unique session identifier
    """
    _memory_store[session_id] = 0.0
