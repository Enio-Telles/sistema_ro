from fastapi.testclient import TestClient

from backend.app.runtime_gold_current_v3 import app


client = TestClient(app)


def test_runtime_gold_current_v3_root_transition_status() -> None:
    response = client.get('/')
    assert response.status_code == 200
    payload = response.json()
    assert payload['name'] == 'sistema_ro_gold_current_v3'
    assert payload['status'] == 'transition_runtime_replaced_by_current_v5_for_official_use'
    assert payload['replacement_runtime'] == 'runtime_gold_current_v5'


def test_runtime_gold_current_v3_health_has_deprecation_headers() -> None:
    response = client.get('/api/current-v3/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'
    assert response.headers['Deprecation'] == 'true'
    assert response.headers['X-Replacement-Runtime'] == 'runtime_gold_current_v5'


def test_runtime_gold_current_v3_surface_catalog_points_to_current_v5() -> None:
    response = client.get('/api/current-v3/surfaces/catalog')
    assert response.status_code == 200
    payload = response.json()
    assert payload['official']['fisconforme_current_alias'] == 'runtime_gold_current_v5'
