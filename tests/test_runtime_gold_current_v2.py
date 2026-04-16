from fastapi.testclient import TestClient

import backend.app.runtime_gold_current_v2 as runtime_gold_current_v2_module
import backend.app.status_router as status_router_module
from backend.app.runtime_gold_current_v2 import app


client = TestClient(app)


def test_runtime_gold_current_v2_root() -> None:
    response = client.get('/')
    assert response.status_code == 200
    assert response.json()['name'] == 'sistema_ro_gold_current_v2'


def test_runtime_gold_current_v2_health() -> None:
    response = client.get('/api/current-v2/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'


def test_runtime_gold_current_v2_status_summary(monkeypatch) -> None:
    monkeypatch.setattr(
        status_router_module,
        'get_cnpj_status',
        lambda cnpj: {
            'cnpj': cnpj,
            'next_action': 'executar_gold',
            'recommended_surfaces': {
                'gold': {'alias': 'runtime_gold_current_v2'},
                'fisconforme': {'alias': 'runtime_gold_current_v5'},
            },
        },
    )

    response = client.get('/api/current-v2/status/12345678000199')
    assert response.status_code == 200
    payload = response.json()
    assert payload['cnpj'] == '12345678000199'
    assert payload['next_action'] == 'executar_gold'
    assert payload['recommended_surfaces']['gold']['alias'] == 'runtime_gold_current_v2'


def test_runtime_gold_current_v2_pipeline_status(monkeypatch) -> None:
    monkeypatch.setattr(
        runtime_gold_current_v2_module,
        'get_gold_v20_status',
        lambda cnpj: {
            'cnpj': cnpj,
            'validation': {'ok': True},
            'conversion_quality_summary': {'manual_overrides_rows': 2},
            'sefin_context': {'using_sefin_enriched_items': False},
        },
    )

    response = client.get('/api/current-v2/pipeline/12345678000199/status')
    assert response.status_code == 200
    payload = response.json()
    assert payload['cnpj'] == '12345678000199'
    assert payload['conversion_quality_summary']['manual_overrides_rows'] == 2
    assert payload['sefin_context']['using_sefin_enriched_items'] is False
