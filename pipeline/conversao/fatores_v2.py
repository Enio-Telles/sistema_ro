from __future__ import annotations

import polars as pl

from pipeline.conversao.fatores import calcular_fatores
from pipeline.conversao.structural_factors import infer_structural_factors


def calcular_fatores_priorizados(item_unidades_df: pl.DataFrame, itens_df: pl.DataFrame) -> pl.DataFrame:
    if item_unidades_df.is_empty():
        return item_unidades_df

    preco_df = calcular_fatores(item_unidades_df)
    estrutural_df = infer_structural_factors(itens_df)
    if estrutural_df.is_empty():
        return preco_df

    joined = preco_df.join(
        estrutural_df.select([c for c in [
            "id_agrupado",
            "unid",
            "fator_estrutural",
            "tipo_fator_estrutural",
            "confianca_estrutural",
            "fonte_estrutural",
        ] if c in estrutural_df.columns]),
        on=[c for c in ["id_agrupado", "unid"] if c in preco_df.columns and c in estrutural_df.columns],
        how="left",
    )

    return joined.with_columns(
        pl.when(pl.col("fator_estrutural").is_not_null()).then(pl.col("fator_estrutural")).otherwise(pl.col("fator")).alias("fator"),
        pl.when(pl.col("fator_estrutural").is_not_null()).then(pl.lit("estrutural")).otherwise(pl.col("tipo_fator")).alias("tipo_fator"),
        pl.when(pl.col("fator_estrutural").is_not_null()).then(pl.col("confianca_estrutural")).otherwise(pl.col("confianca_fator")).alias("confianca_fator"),
        pl.when(pl.col("fator_estrutural").is_not_null()).then(pl.col("fonte_estrutural")).otherwise(pl.col("fonte_fator")).alias("fonte_fator"),
    ).drop([c for c in ["fator_estrutural", "tipo_fator_estrutural", "confianca_estrutural", "fonte_estrutural"] if c in joined.columns])
