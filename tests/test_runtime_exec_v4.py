from fastapi.testclient import TestClient

from backend.app.runtime_exec_v4 import app


client = TestClient(app)


def test_runtime_exec_v4_root() -> None:
    response = client.get('/')
    assert response.status_code == 200
    assert response.json()['name'] == 'sistema_ro_exec_v4'


def test_runtime_exec_v4_health() -> None:
    response = client.get('/api/v6b/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'
