"""Contract tests for memory API response schemas."""

from fastapi.testclient import TestClient


class TestMemoryContract:
    """Tests for memory endpoint response schemas."""

    def test_memory_add_response_schema(
        self, client: TestClient, session_headers: dict[str, str]
    ) -> None:
        """POST /memory/add response matches MemoryResponse schema."""
        client.delete("/memory", headers=session_headers)
        response = client.post(
            "/memory/add",
            json={"value": 10.0},
            headers=session_headers,
        )
        assert response.status_code == 200
        data = response.json()
        assert "value" in data
        assert isinstance(data["value"], (int, float))
        assert "message" in data
        assert isinstance(data["message"], str)

    def test_memory_get_response_schema(
        self, client: TestClient, session_headers: dict[str, str]
    ) -> None:
        """GET /memory response matches MemoryResponse schema."""
        response = client.get("/memory", headers=session_headers)
        assert response.status_code == 200
        data = response.json()
        assert "value" in data
        assert isinstance(data["value"], (int, float))
        assert "message" in data
        assert isinstance(data["message"], str)

    def test_memory_delete_response_schema(
        self, client: TestClient, session_headers: dict[str, str]
    ) -> None:
        """DELETE /memory response matches MemoryResponse schema."""
        response = client.delete("/memory", headers=session_headers)
        assert response.status_code == 200
        data = response.json()
        assert "value" in data
        assert data["value"] == 0.0
        assert "message" in data
