from fastapi.testclient import TestClient

import backend.app.runtime_gold_v20 as runtime_gold_v20


client = TestClient(runtime_gold_v20.app)


def test_gold_v20_pipeline_run_exposes_conversion_quality(monkeypatch) -> None:
    def _fake_execute_gold_v20(cnpj: str) -> dict:
        assert cnpj == '12345678000199'
        return {
            'cnpj': cnpj,
            'status': 'ok',
            'pipeline_version': 'gold_v20',
            'conversion_quality': {
                'total_item_unidades': 4,
                'total_fatores': 4,
                'fatores_estruturais': 2,
                'fatores_preco': 1,
                'fatores_manuais': 1,
                'anomalias_total': 1,
                'anomalias_mesma_unidade': 1,
                'anomalias_baixa_confianca': 0,
            },
        }

    monkeypatch.setattr(runtime_gold_v20, 'execute_gold_v20', _fake_execute_gold_v20)

    response = client.post('/api/gold20/pipeline/12345678000199/run')
    assert response.status_code == 200

    payload = response.json()
    assert payload['cnpj'] == '12345678000199'
    assert payload['status'] == 'ok'
    assert payload['pipeline_version'] == 'gold_v20'
    assert 'conversion_quality' in payload
    assert payload['conversion_quality']['total_item_unidades'] == 4
    assert payload['conversion_quality']['anomalias_total'] == 1
