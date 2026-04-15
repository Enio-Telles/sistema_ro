from fastapi.testclient import TestClient

from backend.app.runtime_gold_current_v5 import app


client = TestClient(app)


def test_runtime_gold_current_v5_root() -> None:
    response = client.get('/')
    assert response.status_code == 200
    assert response.json()['name'] == 'sistema_ro_gold_current_v5'


def test_runtime_gold_current_v5_health() -> None:
    response = client.get('/api/current-v5/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'
