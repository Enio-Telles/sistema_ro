from fastapi.testclient import TestClient

from backend.app.runtime_main_v3 import app


client = TestClient(app)


def test_runtime_main_v3_root() -> None:
    response = client.get('/')
    assert response.status_code == 200
    assert response.json()['name'] == 'sistema_ro_main_v3'


def test_runtime_main_v3_health() -> None:
    response = client.get('/api/main3/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'
