from fastapi.testclient import TestClient

from backend.app.runtime_gold_current_v5 import app


client = TestClient(app)


def test_runtime_gold_current_v5_root() -> None:
    response = client.get('/')
    assert response.status_code == 200
    payload = response.json()
    assert payload['name'] == 'sistema_ro_gold_current_v5'
    assert payload['surface_role'] == 'official_alias'
    assert payload['runtime_family'] == 'fisconforme'
    assert payload['api_prefix'] == '/api/current-v5/fisconforme-v2'
    assert payload['canonical_runtime'] == 'runtime_gold_v25'


def test_runtime_gold_current_v5_health() -> None:
    response = client.get('/api/current-v5/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'


def test_runtime_gold_current_v5_operational_surface_index() -> None:
    response = client.get('/api/current-v5/surfaces')
    assert response.status_code == 200
    payload = response.json()
    assert payload['in_use_now']['fisconforme']['official_runtime'] == 'runtime_gold_v25'
    assert '/api/current-v5/fisconforme-v2' in payload['in_use_now']['fisconforme']['preferred_prefixes']


def test_runtime_gold_current_v5_runtime_surface_catalog() -> None:
    response = client.get('/api/current-v5/surfaces/catalog')
    assert response.status_code == 200
    payload = response.json()
    assert payload['official']['fisconforme_current_alias'] == 'runtime_gold_current_v5'
    assert payload['official']['fisconforme_current_prefix'] == '/api/current-v5/fisconforme-v2'


def test_runtime_gold_current_v5_runtime_recommendation() -> None:
    response = client.get('/api/current-v5/runtime')
    assert response.status_code == 200
    payload = response.json()
    assert payload['official_runtime']['gold']['runtime'] == 'runtime_gold_v20'
    assert payload['official_runtime']['fisconforme']['current_alias'] == 'runtime_gold_current_v5'
