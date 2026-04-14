import polars as pl

from pipeline.conversao.fatores import calcular_fatores


def test_calcular_fatores_uses_preco_relativo() -> None:
    df = pl.DataFrame([
        {"id_agrupado": "P1", "unid": "UN", "qtd_total": 10.0, "linhas": 2, "preco_medio": 5.0},
        {"id_agrupado": "P1", "unid": "CX", "qtd_total": 20.0, "linhas": 3, "preco_medio": 50.0},
    ])
    result = calcular_fatores(df)
    assert "fator" in result.columns
    # unidade de referência automática tende a ser a de maior quantidade total
    assert result.filter(pl.col("unid") == "CX")["fator"][0] == 1.0
