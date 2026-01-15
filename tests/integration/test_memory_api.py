"""Integration tests for memory API endpoints."""

import time

from fastapi.testclient import TestClient


class TestMemoryAPI:
    """Tests for memory management endpoints."""

    def test_memory_add_returns_new_value(
        self, client: TestClient, session_headers: dict[str, str]
    ) -> None:
        """POST /memory/add returns updated value."""
        client.delete("/memory", headers=session_headers)
        response = client.post(
            "/memory/add",
            json={"value": 25.0},
            headers=session_headers,
        )
        assert response.status_code == 200
        data = response.json()
        assert data["value"] == 25.0

    def test_memory_subtract_returns_new_value(
        self, client: TestClient, session_headers: dict[str, str]
    ) -> None:
        """POST /memory/subtract returns updated value."""
        client.delete("/memory", headers=session_headers)
        client.post("/memory/add", json={"value": 50.0}, headers=session_headers)
        response = client.post(
            "/memory/subtract",
            json={"value": 15.0},
            headers=session_headers,
        )
        assert response.status_code == 200
        data = response.json()
        assert data["value"] == 35.0

    def test_memory_recall_returns_value(
        self, client: TestClient, session_headers: dict[str, str]
    ) -> None:
        """GET /memory returns current memory value."""
        client.delete("/memory", headers=session_headers)
        client.post("/memory/add", json={"value": 42.0}, headers=session_headers)
        response = client.get("/memory", headers=session_headers)
        assert response.status_code == 200
        data = response.json()
        assert data["value"] == 42.0

    def test_memory_clear_resets_to_zero(
        self, client: TestClient, session_headers: dict[str, str]
    ) -> None:
        """DELETE /memory resets to zero."""
        client.post("/memory/add", json={"value": 100.0}, headers=session_headers)
        response = client.delete("/memory", headers=session_headers)
        assert response.status_code == 200
        recall = client.get("/memory", headers=session_headers)
        assert recall.json()["value"] == 0.0

    def test_memory_new_session_returns_zero(self, client: TestClient) -> None:
        """New session with no prior memory returns zero."""
        import uuid
        new_session = {"X-Session-ID": str(uuid.uuid4())}
        response = client.get("/memory", headers=new_session)
        assert response.status_code == 200
        assert response.json()["value"] == 0.0

    def test_memory_response_time_under_50ms(
        self, client: TestClient, session_headers: dict[str, str]
    ) -> None:
        """Memory operations complete in under 50ms (AC-P02)."""
        start = time.time()
        response = client.get("/memory", headers=session_headers)
        elapsed = (time.time() - start) * 1000
        assert response.status_code == 200
        assert elapsed < 50, f"Response took {elapsed:.1f}ms, expected <50ms"

