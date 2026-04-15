from fastapi.testclient import TestClient

from backend.app.runtime_gold_v25 import app

client = TestClient(app)


def test_runtime_gold_v25_runtime_overview() -> None:
    response = client.get('/api/gold25/runtime-overview')
    assert response.status_code == 200
    payload = response.json()
    assert payload['recommendation']['official_runtime']['fisconforme']['runtime'] == 'runtime_gold_v25'
    assert payload['operational_index']['in_use_now']['gold']['official_runtime'] == 'runtime_gold_v20'
    assert payload['surface_catalog']['official']['fisconforme_current_alias'] == 'runtime_gold_current_v5'
