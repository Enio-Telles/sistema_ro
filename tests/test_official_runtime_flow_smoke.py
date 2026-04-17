from fastapi.testclient import TestClient

from backend.app.runtime_gold_current_v5 import app as current_v5_app
from backend.app.services.deprecation_surface_service import match_legacy_route


client = TestClient(current_v5_app)


def test_current_v5_runtime_overview_smoke_after_transition_cleanup() -> None:
    response = client.get('/api/current-v5/runtime-overview/')
    assert response.status_code == 200

    payload = response.json()

    assert payload['recommendation']['official_runtime']['gold'] == {
        'runtime': 'runtime_gold_v20',
        'current_alias': 'runtime_gold_current_v2',
        'api_prefix': '/api/gold20',
    }
    assert payload['recommendation']['official_runtime']['fisconforme'] == {
        'runtime': 'runtime_gold_v25',
        'current_alias': 'runtime_gold_current_v5',
        'api_prefix': '/api/gold25/fisconforme-v2',
    }
    assert payload['operational_index']['transition_only']['runtimes'] == []
    assert payload['surface_catalog']['transition']['fisconforme'] == []
    assert 'runtime_gold_current_v3' in payload['surface_catalog']['legacy']['repo_status']['removed_from_repo']


def test_current_v5_legacy_fisconforme_route_has_replacement_mapping() -> None:
    match = match_legacy_route('/api/current-v5/fisconforme/12345678000190')

    assert match is not None
    assert match['legacy_prefix'] == '/api/current-v5/fisconforme'
    assert match['replacement_prefix'] == '/api/current-v5/fisconforme-v2'
