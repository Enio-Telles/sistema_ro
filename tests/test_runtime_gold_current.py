from fastapi.testclient import TestClient

from backend.app.runtime_gold_current import app


client = TestClient(app)


def test_runtime_gold_current_root() -> None:
    response = client.get('/')
    assert response.status_code == 200
    assert response.json()['name'] == 'sistema_ro_gold_current'


def test_runtime_gold_current_health() -> None:
    response = client.get('/api/current/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'
