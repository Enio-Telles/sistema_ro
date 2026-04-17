from fastapi.testclient import TestClient

import backend.app.runtime_gold_v25 as runtime_gold_v25_module
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
    assert payload['in_use_now']['fisconforme']['official_runtime'] == 'runtime_gold_v25'
    assert '/api/gold25/fisconforme-v2' in payload['in_use_now']['fisconforme']['preferred_prefixes']


def test_runtime_gold_v25_runtime_surface_catalog() -> None:
    response = client.get('/api/gold25/surfaces/catalog')
    assert response.status_code == 200
    payload = response.json()
    assert payload['official']['fisconforme_current_alias'] == 'runtime_gold_current_v5'
    assert payload['official']['fisconforme_current_prefix'] == '/api/current-v5/fisconforme-v2'


def test_runtime_gold_v25_pipeline_status(monkeypatch) -> None:
    monkeypatch.setattr(
        runtime_gold_v25_module,
        'get_gold_v20_status',
        lambda cnpj: {
            'cnpj': cnpj,
            'validation': {'ok': True},
            'conversion_quality_summary': {'log_conversao_anomalias_rows': 4},
            'sefin_context': {'references_complete': False},
        },
    )

    response = client.get('/api/gold25/pipeline/12345678000199/status')
    assert response.status_code == 200
    payload = response.json()
    assert payload['cnpj'] == '12345678000199'
    assert payload['conversion_quality_summary']['log_conversao_anomalias_rows'] == 4
    assert payload['sefin_context']['references_complete'] is False
