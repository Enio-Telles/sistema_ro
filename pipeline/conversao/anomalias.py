from __future__ import annotations

import polars as pl


def build_conversion_anomalies(fatores_df: pl.DataFrame) -> pl.DataFrame:
    if fatores_df.is_empty():
        return pl.DataFrame()

    df = fatores_df.with_columns(
        (pl.col("fator") <= 0).alias("anomalia_fator_nao_positivo"),
        (pl.col("fator") > 1000).alias("anomalia_fator_extremo"),
        ((pl.col("unid") == pl.col("unid_ref")) & (pl.col("fator") != 1)).alias("anomalia_mesma_unidade_fator_diferente"),
        ((pl.col("tipo_fator") == "preco") & (pl.col("confianca_fator") < 0.7)).alias("anomalia_preco_baixa_confianca"),
    )

    flags = [
        "anomalia_fator_nao_positivo",
        "anomalia_fator_extremo",
        "anomalia_mesma_unidade_fator_diferente",
        "anomalia_preco_baixa_confianca",
    ]

    return df.filter(pl.any_horizontal(*[pl.col(flag) for flag in flags])).select(
        [c for c in [
            "id_agrupado",
            "mercadoria_id",
            "apresentacao_id",
            "unid",
            "unid_ref",
            "fator",
            "tipo_fator",
            "confianca_fator",
            *flags,
        ] if c in df.columns]
    )
