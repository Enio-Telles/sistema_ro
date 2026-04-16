from fastapi.testclient import TestClient

import backend.app.runtime_main as runtime_main_module
from backend.app.runtime_main import app


client = TestClient(app)


def test_runtime_main_root() -> None:
    response = client.get('/')
    assert response.status_code == 200
    payload = response.json()
    assert payload['name'] == 'sistema_ro_main'
    assert payload['official_entrypoints']['gold']['runtime'] == 'runtime_gold_current_v2'
    assert payload['official_entrypoints']['fisconforme']['runtime'] == 'runtime_gold_current_v5'


def test_runtime_main_health() -> None:
    response = client.get('/api/main/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'


def test_runtime_main_runtime_overview() -> None:
    response = client.get('/api/main/runtime-overview')
    assert response.status_code == 200
    payload = response.json()
    assert payload['recommendation']['official_runtime']['gold']['current_alias'] == 'runtime_gold_current_v2'
    assert payload['recommendation']['official_runtime']['fisconforme']['current_alias'] == 'runtime_gold_current_v5'


def test_runtime_main_pipeline_status(monkeypatch) -> None:
    monkeypatch.setattr(
        runtime_main_module,
        'get_gold_v20_status',
        lambda cnpj: {
            'cnpj': cnpj,
            'validation': {'ok': True},
            'sefin_context': {'references_complete': True},
        },
    )

    response = client.get('/api/main/pipeline/12345678000199/status')
    assert response.status_code == 200
    payload = response.json()
    assert payload['cnpj'] == '12345678000199'
    assert payload['validation']['ok'] is True
