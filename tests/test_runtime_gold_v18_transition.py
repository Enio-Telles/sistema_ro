from fastapi.testclient import TestClient

from backend.app.runtime_gold_v18 import app


client = TestClient(app)


def test_runtime_gold_v18_root_transition_status() -> None:
    response = client.get('/')
    assert response.status_code == 200
    payload = response.json()
    assert payload['name'] == 'sistema_ro_gold_v18'
    assert payload['status'] == 'transition_runtime_replaced_by_gold_v20_for_official_use'
    assert payload['replacement_runtime'] == 'runtime_gold_v20'
    assert payload['replacement_prefix'] == '/api/gold20'


def test_runtime_gold_v18_health_has_deprecation_headers() -> None:
    response = client.get('/api/gold18/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'
    assert response.headers['Deprecation'] == 'true'
    assert response.headers['X-Replacement-Runtime'] == 'runtime_gold_v20'
    assert response.headers['X-Replacement-Prefix'] == '/api/gold20'
