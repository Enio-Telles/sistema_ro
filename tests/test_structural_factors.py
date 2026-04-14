import polars as pl

from pipeline.conversao.fatores_v2 import calcular_fatores_priorizados


def test_structural_factor_has_priority_over_price() -> None:
    item_unidades = pl.DataFrame([
        {"id_agrupado": "P1", "unid": "UN", "qtd_total": 10.0, "linhas": 2, "preco_medio": 5.0},
        {"id_agrupado": "P1", "unid": "CX", "qtd_total": 2.0, "linhas": 1, "preco_medio": 50.0},
    ])
    itens = pl.DataFrame([
        {"id_agrupado": "P1", "unid": "CX", "descr_item": "ARROZ T1", "descr_compl": "CX 12 UN"},
        {"id_agrupado": "P1", "unid": "UN", "descr_item": "ARROZ T1", "descr_compl": "UN"},
    ])
    result = calcular_fatores_priorizados(item_unidades, itens)
    cx = result.filter(pl.col("unid") == "CX")
    assert cx["tipo_fator"][0] == "estrutural"
    assert cx["fator"][0] == 12.0
