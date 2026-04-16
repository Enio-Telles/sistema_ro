import polars as pl

from backend.app.services.conversao_quality_summary import summarize_conversion_quality


def test_summarize_conversion_quality_counts_factors_and_anomalies() -> None:
    item_unidades_df = pl.DataFrame(
        {
            "mercadoria_id": ["m1", "m2", "m3"],
            "unidade": ["CX", "UN", "KG"],
        }
    )
    fatores_df = pl.DataFrame(
        {
            "tipo_fator": ["estrutural", "preco", "manual", "preco"],
            "fator": [12.0, 6.0, 1.0, 24.0],
        }
    )
    anomalias_df = pl.DataFrame(
        {
            "anomalia_mesma_unidade_fator_diferente": [True, False, True],
            "anomalia_preco_baixa_confianca": [False, True, False],
        }
    )

    resumo = summarize_conversion_quality(
        item_unidades_df=item_unidades_df,
        fatores_df=fatores_df,
        anomalias_df=anomalias_df,
    )

    assert resumo == {
        "total_item_unidades": 3,
        "total_fatores": 4,
        "fatores_estruturais": 1,
        "fatores_preco": 2,
        "fatores_manuais": 1,
        "anomalias_total": 3,
        "anomalias_mesma_unidade": 2,
        "anomalias_baixa_confianca": 1,
    }


def test_summarize_conversion_quality_is_resilient_to_missing_inputs() -> None:
    resumo = summarize_conversion_quality()

    assert resumo == {
        "total_item_unidades": 0,
        "total_fatores": 0,
        "fatores_estruturais": 0,
        "fatores_preco": 0,
        "fatores_manuais": 0,
        "anomalias_total": 0,
        "anomalias_mesma_unidade": 0,
        "anomalias_baixa_confianca": 0,
    }
