from fastapi.testclient import TestClient

from backend.app.runtime_gold_v16 import app


client = TestClient(app)


def test_runtime_gold_v16_root() -> None:
    response = client.get('/')
    assert response.status_code == 200
    assert response.json()['name'] == 'sistema_ro_gold_v16'


def test_runtime_gold_v16_health() -> None:
    response = client.get('/api/gold16/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'
