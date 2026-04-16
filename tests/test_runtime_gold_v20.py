from fastapi.testclient import TestClient

import backend.app.runtime_gold_v20 as runtime_gold_v20_module
from backend.app.runtime_gold_v20 import app


client = TestClient(app)


def test_runtime_gold_v20_root() -> None:
    response = client.get('/')
    assert response.status_code == 200
    assert response.json()['name'] == 'sistema_ro_gold_v20'


def test_runtime_gold_v20_health() -> None:
    response = client.get('/api/gold20/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'


def test_runtime_gold_v20_pipeline_status(monkeypatch) -> None:
    monkeypatch.setattr(
        runtime_gold_v20_module,
        'get_gold_v20_status',
        lambda cnpj: {
            'cnpj': cnpj,
            'validation': {'ok': True},
            'conversion_quality_summary': {'diagnostico_conversao_rows': 3},
            'sefin_context': {'references_complete': True},
        },
    )

    response = client.get('/api/gold20/pipeline/12345678000199/status')
    assert response.status_code == 200
    payload = response.json()
    assert payload['cnpj'] == '12345678000199'
    assert payload['validation']['ok'] is True
    assert payload['conversion_quality_summary']['diagnostico_conversao_rows'] == 3
