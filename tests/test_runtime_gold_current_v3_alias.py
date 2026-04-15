from fastapi.testclient import TestClient

from backend.app.runtime_gold_current_v3 import app


client = TestClient(app)


def test_runtime_gold_current_v3_alias_root() -> None:
    response = client.get('/')
    assert response.status_code == 200
    assert response.json()['name'] == 'sistema_ro_gold_current_v3'


def test_runtime_gold_current_v3_alias_health() -> None:
    response = client.get('/api/current-v3/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'
