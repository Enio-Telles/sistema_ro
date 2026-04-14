from fastapi.testclient import TestClient

from backend.app.runtime_gold_v10 import app


client = TestClient(app)


def test_runtime_gold_v10_root() -> None:
    response = client.get('/')
    assert response.status_code == 200
    assert response.json()['name'] == 'sistema_ro_gold_v10'


def test_runtime_gold_v10_health() -> None:
    response = client.get('/api/gold10/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'
