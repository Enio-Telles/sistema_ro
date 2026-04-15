from fastapi.testclient import TestClient

from backend.app.runtime_gold_v20 import app


client = TestClient(app)


def test_runtime_gold_v20_root() -> None:
    response = client.get('/')
    assert response.status_code == 200
    assert response.json()['name'] == 'sistema_ro_gold_v20'


def test_runtime_gold_v20_health() -> None:
    response = client.get('/api/gold20/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'
