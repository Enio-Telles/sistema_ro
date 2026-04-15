from fastapi.testclient import TestClient

from backend.app.runtime_gold_v25 import app


client = TestClient(app)


def test_runtime_gold_v25_root() -> None:
    response = client.get('/')
    assert response.status_code == 200
    assert response.json()['name'] == 'sistema_ro_gold_v25'


def test_runtime_gold_v25_health() -> None:
    response = client.get('/api/gold25/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'


def test_runtime_gold_v25_operational_surface_index() -> None:
    response = client.get('/api/gold25/surfaces')
    assert response.status_code == 200
    payload = response.json()
    assert payload['in_use_now']['gold']['official_alias'] == 'runtime_gold_current_v2'
    assert '/api/gold25/fisconforme-v2' in payload['in_use_now']['fisconforme']['preferred_prefixes']
