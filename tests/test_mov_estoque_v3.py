import polars as pl

from pipeline.estoque.mov_estoque_v3 import build_mov_estoque_v3


def _minimal_frames():
    c170 = pl.DataFrame([
        {"id_agrupado": "P1", "id_linha_origem": "c170|1|1|1", "qtd": 10.0, "vl_item": 100.0, "dt_doc": "2024-01-10"},
    ])
    nfe = pl.DataFrame()
    nfce = pl.DataFrame()
    bloco_h = pl.DataFrame()
    fatores = pl.DataFrame([
        {"id_agrupado": "P1", "unid_ref": "UN", "fator": 1.0, "tipo_fator": "preco", "confianca_fator": 0.9, "fonte_fator": "preco_medio_relativo"},
    ])
    return c170, nfe, nfce, bloco_h, fatores


def test_build_mov_estoque_v3_returns_base_mov_when_item_unidades_empty():
    c170, nfe, nfce, bloco_h, fatores = _minimal_frames()
    result = build_mov_estoque_v3(c170, nfe, nfce, bloco_h, fatores, item_unidades_df=pl.DataFrame())
    assert result.height > 0
    assert "id_agrupado" in result.columns


def test_build_mov_estoque_v3_enriches_with_sefin_cols():
    c170, nfe, nfce, bloco_h, fatores = _minimal_frames()
    item_unidades = pl.DataFrame([
        {
            "id_agrupado": "P1",
            "co_sefin_agr": "SEFIN01",
            "co_sefin_final": "SF01",
            "it_pc_interna": 0.12,
            "it_in_st": 1,
            "it_pc_mva": 0.0,
            "it_in_mva_ajustado": 0,
            "it_pc_reducao": 0.0,
            "it_in_reducao_credito": 0,
        }
    ])
    result = build_mov_estoque_v3(c170, nfe, nfce, bloco_h, fatores, item_unidades_df=item_unidades)
    assert "co_sefin_agr" in result.columns
    assert "it_pc_interna" in result.columns
    p1_rows = result.filter(pl.col("id_agrupado") == "P1").to_dicts()
    assert any(r.get("co_sefin_agr") == "SEFIN01" for r in p1_rows)


def test_build_mov_estoque_v3_preserves_factor_resolution_mode():
    c170, nfe, nfce, bloco_h, fatores = _minimal_frames()
    result = build_mov_estoque_v3(c170, nfe, nfce, bloco_h, fatores, item_unidades_df=pl.DataFrame())
    assert "factor_resolution_mode" in result.columns


def test_build_mov_estoque_v3_no_sefin_overlap_columns_when_item_unidades_lacks_join_cols():
    c170, nfe, nfce, bloco_h, fatores = _minimal_frames()
    item_unidades = pl.DataFrame([{"id_agrupado": "P1"}])
    result = build_mov_estoque_v3(c170, nfe, nfce, bloco_h, fatores, item_unidades_df=item_unidades)
    assert "co_sefin_agr" not in result.columns
