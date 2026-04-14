from fastapi.testclient import TestClient

from backend.app.runtime_exec_v2 import app


client = TestClient(app)


def test_runtime_exec_v2_root() -> None:
    response = client.get('/')
    assert response.status_code == 200
    assert response.json()['name'] == 'sistema_ro_exec_v2'


def test_runtime_exec_v2_health() -> None:
    response = client.get('/api/v4/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'
