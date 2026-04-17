from fastapi.testclient import TestClient

import backend.app.runtime_gold_current_v5 as runtime_gold_current_v5_module
import backend.app.status_router as status_router_module
from backend.app.runtime_gold_current_v5 import app


client = TestClient(app)


def test_runtime_gold_current_v5_root() -> None:
    response = client.get('/')
    assert response.status_code == 200
    assert response.json()['name'] == 'sistema_ro_gold_current_v5'


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


def test_runtime_gold_current_v5_runtime_overview() -> None:
    response = client.get('/api/current-v5/runtime-overview')
    assert response.status_code == 200
    payload = response.json()
    assert payload['recommendation']['official_runtime']['fisconforme']['current_alias'] == 'runtime_gold_current_v5'
    assert payload['operational_index']['in_use_now']['fisconforme']['official_runtime'] == 'runtime_gold_v25'
    assert payload['surface_catalog']['official']['fisconforme_current_prefix'] == '/api/current-v5/fisconforme-v2'
    assert 'phases' in payload['decommission_plan']


def test_runtime_gold_current_v5_status_summary(monkeypatch) -> None:
    monkeypatch.setattr(
        status_router_module,
        'get_cnpj_status',
        lambda cnpj: {
            'cnpj': cnpj,
            'next_action': 'revisar_quality',
            'recommended_surfaces': {
                'gold': {'alias': 'runtime_gold_current_v2'},
                'fisconforme': {'alias': 'runtime_gold_current_v5'},
            },
        },
    )

    response = client.get('/api/current-v5/status/12345678000199')
    assert response.status_code == 200
    payload = response.json()
    assert payload['cnpj'] == '12345678000199'
    assert payload['next_action'] == 'revisar_quality'
    assert payload['recommended_surfaces']['fisconforme']['alias'] == 'runtime_gold_current_v5'


def test_runtime_gold_current_v5_pipeline_status(monkeypatch) -> None:
    monkeypatch.setattr(
        runtime_gold_current_v5_module,
        'get_gold_v20_status',
        lambda cnpj: {
            'cnpj': cnpj,
            'validation': {'ok': True},
            'conversion_quality_summary': {'manual_overrides_rows': 3},
            'sefin_context': {'using_sefin_enriched_items': True},
        },
    )

    response = client.get('/api/current-v5/pipeline/12345678000199/status')
    assert response.status_code == 200
    payload = response.json()
    assert payload['cnpj'] == '12345678000199'
    assert payload['conversion_quality_summary']['manual_overrides_rows'] == 3
    assert payload['sefin_context']['using_sefin_enriched_items'] is True
