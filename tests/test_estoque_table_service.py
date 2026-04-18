import shutil

import polars as pl
from fastapi.testclient import TestClient

from backend.app.runtime_gold_current_v2 import app
from backend.app.services.datasets import dataset_ref
from pipeline.io.parquet_store import save_parquet


client = TestClient(app)


def _write_dataset(cnpj: str, dataset: str, rows: list[dict]) -> None:
    df = pl.DataFrame(rows)
    ref = dataset_ref(cnpj=cnpj, layer="gold", name=dataset)
    save_parquet(df, ref)


def _remove_cnpj_dir(cnpj: str) -> None:
    from backend.app.config import settings

    path = settings.cnpj_root / cnpj
    if path.exists():
        shutil.rmtree(path)


def test_estoque_table_endpoint_supports_filters_sort_and_projection() -> None:
    cnpj = "10000000000001"
    try:
        _write_dataset(
            cnpj,
            "mov_estoque",
            [
                {"id_agregado": "A1", "produto": "Arroz tipo 1", "tipo_operacao": "1 - ENTRADA", "valor": 10.0},
                {"id_agregado": "A2", "produto": "Feijao preto", "tipo_operacao": "2 - SAIDA", "valor": 20.0},
                {"id_agregado": "A3", "produto": "Arroz integral", "tipo_operacao": "1 - ENTRADA", "valor": 30.0},
            ],
        )

        response = client.get(
            f"/api/current-v2/estoque/{cnpj}/tabelas/mov_estoque",
            params={
                "offset": 0,
                "limit": 1,
                "sort_by": "valor",
                "sort_dir": "desc",
                "search": "arroz",
                "columns": "id_agregado,produto,valor",
                "filter__tipo_operacao": "entrada",
            },
        )

        assert response.status_code == 200
        payload = response.json()
        assert payload["dataset"] == "mov_estoque"
        assert payload["rows_total"] == 2
        assert len(payload["items"]) == 1
        assert payload["items"][0]["id_agregado"] == "A3"
        assert payload["columns"] == [
            {"name": "id_agregado", "dtype": "String"},
            {"name": "produto", "dtype": "String"},
            {"name": "valor", "dtype": "Float64"},
        ]
        assert payload["sort_applied"] == {"column": "valor", "direction": "desc"}
        assert payload["filters_applied"] == [{"column": "tipo_operacao", "value": "entrada", "mode": "contains"}]
        assert payload["search_applied"] == {
            "term": "arroz",
            "columns": ["id_agregado", "produto", "valor"],
        }
    finally:
        _remove_cnpj_dir(cnpj)


def test_estoque_table_export_uses_same_filtered_scope() -> None:
    cnpj = "10000000000002"
    try:
        _write_dataset(
            cnpj,
            "estoque_alertas",
            [
                {"id_agregado": "A1", "tipo_alerta": "saldo_negativo", "mensagem": "Produto em alerta"},
                {"id_agregado": "A2", "tipo_alerta": "fator_manual", "mensagem": "Revisar fator"},
            ],
        )

        response = client.get(
            f"/api/current-v2/estoque/{cnpj}/tabelas/estoque_alertas/export",
            params={"filter__tipo_alerta": "saldo", "columns": "id_agregado,tipo_alerta"},
        )

        assert response.status_code == 200
        assert response.headers["content-disposition"] == 'attachment; filename="estoque_alertas_10000000000002.csv"'
        assert "A1,saldo_negativo" in response.text
        assert "A2" not in response.text
    finally:
        _remove_cnpj_dir(cnpj)


def test_estoque_table_endpoint_returns_empty_state_when_dataset_is_missing() -> None:
    cnpj = "10000000000003"
    response = client.get(f"/api/current-v2/estoque/{cnpj}/tabelas/aba_periodos", params={"columns": "id_agregado"})
    assert response.status_code == 200
    payload = response.json()
    assert payload["exists"] is False
    assert payload["dataset"] == "aba_periodos"
    assert payload["rows_total"] == 0
    assert payload["items"] == []


def test_estoque_table_endpoint_rejects_invalid_sort_column() -> None:
    cnpj = "10000000000004"
    try:
        _write_dataset(
            cnpj,
            "aba_anual",
            [{"id_agregado": "A1", "ano": 2024, "valor": 10.0}],
        )
        response = client.get(
            f"/api/current-v2/estoque/{cnpj}/tabelas/aba_anual",
            params={"sort_by": "coluna_inexistente"},
        )
        assert response.status_code == 400
        payload = response.json()
        assert payload["detail"]["invalid_column"] == "coluna_inexistente"
    finally:
        _remove_cnpj_dir(cnpj)


def test_estoque_table_endpoint_rejects_invalid_filter_column() -> None:
    cnpj = "10000000000005"
    try:
        _write_dataset(
            cnpj,
            "aba_mensal",
            [{"id_agregado": "A1", "ano": 2024, "mes": 1}],
        )
        response = client.get(
            f"/api/current-v2/estoque/{cnpj}/tabelas/aba_mensal",
            params={"filter__nao_existe": "x"},
        )
        assert response.status_code == 400
        payload = response.json()
        assert payload["detail"]["invalid_column"] == "nao_existe"
    finally:
        _remove_cnpj_dir(cnpj)
