from fastapi.testclient import TestClient
import polars as pl
import shutil

from backend.app.runtime import app
from backend.app.services.datasets import dataset_ref
from pipeline.io.parquet_store import save_parquet
from backend.app.services.paths import fisconforme_dir


client = TestClient(app)


def write_sample_parquets(cnpj: str, names: list[str]) -> None:
    df = pl.DataFrame([
        {"codigo": "X01", "descricao": "A amostra", "valor": 1},
        {"codigo": "X02", "descricao": "Outra amostra", "valor": 2},
    ])
    for name in names:
        ref = dataset_ref(cnpj=cnpj, layer="gold", name=name)
        save_parquet(df, ref)


def write_sample_fisconforme(cnpj: str) -> None:
    df_cad = pl.DataFrame([
        {"cnpj": cnpj, "nome": "Empresa A"},
        {"cnpj": cnpj, "nome": "Empresa B"},
    ])
    df_malhas = pl.DataFrame([
        {"tipo": "malha1", "detalhe": "x"},
        {"tipo": "malha2", "detalhe": "y"},
    ])
    fis_dir = fisconforme_dir(cnpj)
    df_cad.write_parquet(fis_dir / f"fisconforme_cadastral_{cnpj}.parquet")
    df_malhas.write_parquet(fis_dir / f"fisconforme_malhas_{cnpj}.parquet")


def remove_cnpj_dir(cnpj: str) -> None:
    from backend.app.config import settings
    path = settings.cnpj_root / cnpj
    if path.exists():
        shutil.rmtree(path)


def test_get_conversao_fatores_preview() -> None:
    cnpj = "00000000000192"
    try:
        write_sample_parquets(cnpj, ["fatores_conversao", "item_unidades"])
        response = client.get(f"/api/v2/conversao/{cnpj}/fatores")
        assert response.status_code == 200
        data = response.json()
        assert data["cnpj"] == cnpj
        assert data["fatores_conversao"]["exists"] is True
        assert data["fatores_conversao"]["rows"] == 2
        assert data["item_unidades"]["exists"] is True
    finally:
        remove_cnpj_dir(cnpj)


def test_get_estoque_overview_preview() -> None:
    cnpj = "00000000000193"
    try:
        names = [
            "mov_estoque",
            "aba_mensal",
            "aba_anual",
            "aba_periodos",
            "estoque_resumo",
            "estoque_alertas",
        ]
        write_sample_parquets(cnpj, names)
        response = client.get(f"/api/v2/estoque/{cnpj}/overview")
        assert response.status_code == 200
        data = response.json()
        assert data["cnpj"] == cnpj
        for name in names:
            key = name
            assert key in data
            assert data[key]["exists"] is True
            assert data[key]["rows"] == 2
    finally:
        remove_cnpj_dir(cnpj)


def test_get_fisconforme_preview() -> None:
    cnpj = "00000000000194"
    try:
        write_sample_fisconforme(cnpj)
        response = client.get(f"/api/v2/fisconforme/{cnpj}")
        assert response.status_code == 200
        data = response.json()
        assert data["cnpj"] == cnpj
        assert data["from_cache_cadastral"] is True
        assert data["from_cache_malhas"] is True
        assert len(data["dados_cadastrais"]) == 2
        assert len(data["malhas"]) == 2
    finally:
        remove_cnpj_dir(cnpj)
