"""Unit tests for memory service."""


class TestMemoryService:
    """Tests for memory management functions."""

    def test_add_to_memory(self) -> None:
        """Adds value to memory (AC-005)."""
        from src.services.memory import add_to_memory, clear_memory, get_memory

        session_id = "test-session-add"
        clear_memory(session_id)
        add_to_memory(session_id, 10.0)
        assert get_memory(session_id) == 10.0

    def test_subtract_from_memory(self) -> None:
        """Subtracts value from memory (AC-006)."""
        from src.services.memory import (
            add_to_memory,
            clear_memory,
            get_memory,
            subtract_from_memory,
        )

        session_id = "test-session-sub"
        clear_memory(session_id)
        add_to_memory(session_id, 20.0)
        subtract_from_memory(session_id, 5.0)
        assert get_memory(session_id) == 15.0

    def test_recall_memory(self) -> None:
        """Returns current memory value (AC-007)."""
        from src.services.memory import add_to_memory, clear_memory, get_memory

        session_id = "test-session-recall"
        clear_memory(session_id)
        add_to_memory(session_id, 42.5)
        assert get_memory(session_id) == 42.5

    def test_clear_memory(self) -> None:
        """Resets memory to zero (AC-008)."""
        from src.services.memory import add_to_memory, clear_memory, get_memory

        session_id = "test-session-clear"
        add_to_memory(session_id, 100.0)
        clear_memory(session_id)
        assert get_memory(session_id) == 0.0

    def test_new_session_memory_zero(self) -> None:
        """New session starts with zero memory (AC-B02)."""
        from src.services.memory import get_memory

        session_id = "brand-new-session-12345"
        assert get_memory(session_id) == 0.0
