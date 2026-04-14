from fastapi.testclient import TestClient

from backend.app.runtime_exec_v5 import app


client = TestClient(app)


def test_runtime_exec_v5_root() -> None:
    response = client.get('/')
    assert response.status_code == 200
    assert response.json()['name'] == 'sistema_ro_exec_v5'


def test_runtime_exec_v5_health() -> None:
    response = client.get('/api/v6c/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'
