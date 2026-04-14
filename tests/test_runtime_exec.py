from fastapi.testclient import TestClient

from backend.app.runtime_exec import app


client = TestClient(app)


def test_runtime_exec_root() -> None:
    response = client.get('/')
    assert response.status_code == 200
    assert response.json()['name'] == 'sistema_ro_exec'


def test_runtime_exec_health() -> None:
    response = client.get('/api/v3/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'
