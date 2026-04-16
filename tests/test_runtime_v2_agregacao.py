from fastapi.testclient import TestClient
import polars as pl
import shutil

from backend.app.runtime import app
from backend.app.services.datasets import dataset_ref
from pipeline.io.parquet_store import save_parquet


client = TestClient(app)


def write_sample_gold_parquets(cnpj: str) -> None:
    df = pl.DataFrame([
        {"codigo": "A001", "descricao": "Produto A", "qtd": 10},
        {"codigo": "B002", "descricao": "Produto B", "qtd": 5},
    ])
    for name in ("produtos_agrupados", "id_agrupados", "produtos_final"):
        ref = dataset_ref(cnpj=cnpj, layer="gold", name=name)
        save_parquet(df, ref)


def remove_cnpj_dir(cnpj: str) -> None:
    # settings.cnpj_root is relative to repo; remove created test dir after test
    from backend.app.config import settings
    import os

    path = settings.cnpj_root / cnpj
    if path.exists():
        shutil.rmtree(path)


def test_get_agregacao_grupos_preview() -> None:
    cnpj = "00000000000191"
    try:
        write_sample_gold_parquets(cnpj)
        response = client.get(f"/api/v2/agregacao/{cnpj}/grupos")
        assert response.status_code == 200
        data = response.json()
        assert data["cnpj"] == cnpj
        assert "produtos_agrupados" in data
        assert data["produtos_agrupados"]["exists"] is True
        assert data["produtos_agrupados"]["rows"] == 2
        assert len(data["produtos_agrupados"]["items"]) == 2
        # other datasets should also exist
        assert data["id_agrupados"]["exists"] is True
        assert data["produtos_final"]["exists"] is True
    finally:
        remove_cnpj_dir(cnpj)
