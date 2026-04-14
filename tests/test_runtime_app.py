from fastapi.testclient import TestClient

from backend.app.runtime import app


client = TestClient(app)


def test_runtime_root() -> None:
    response = client.get('/')
    assert response.status_code == 200
    assert response.json()['name'] == 'sistema_ro_runtime'


def test_runtime_health() -> None:
    response = client.get('/api/v2/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'
