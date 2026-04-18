from backend.app.main import app
from fastapi.testclient import TestClient


client = TestClient(app)


def test_health_endpoint() -> None:
    response = client.get('/api/current-v2/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'
