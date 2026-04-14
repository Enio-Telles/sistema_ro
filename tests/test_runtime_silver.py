from fastapi.testclient import TestClient

from backend.app.runtime_silver import app


client = TestClient(app)


def test_runtime_silver_root() -> None:
    response = client.get('/')
    assert response.status_code == 200
    assert response.json()['name'] == 'sistema_ro_silver'


def test_runtime_silver_health() -> None:
    response = client.get('/api/v5/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'
