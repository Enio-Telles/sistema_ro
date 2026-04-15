from fastapi.testclient import TestClient

from backend.app.runtime_gold_current_v3 import app

client = TestClient(app)


def test_runtime_gold_current_v3_runtime_overview() -> None:
    response = client.get('/api/current-v3/runtime-overview')
    assert response.status_code == 200
    payload = response.json()
    assert payload['recommendation']['official_runtime']['fisconforme']['current_alias'] == 'runtime_gold_current_v5'
    assert payload['operational_index']['historical_only']['runtimes'][0] == 'runtime_gold_v14'
    assert payload['surface_catalog']['official']['fisconforme_current_prefix'] == '/api/current-v5/fisconforme-v2'
