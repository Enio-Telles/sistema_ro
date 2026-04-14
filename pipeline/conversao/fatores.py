from __future__ import annotations

import polars as pl


def choose_unid_ref(item_unidades_df: pl.DataFrame) -> pl.DataFrame:
    if item_unidades_df.is_empty():
        return item_unidades_df

    ranked = (
        item_unidades_df
        .sort(["id_agrupado", "qtd_total", "linhas"], descending=[False, True, True])
        .group_by("id_agrupado")
        .first()
        .select(["id_agrupado", pl.col("unid").alias("unid_ref_auto")])
    )
    return item_unidades_df.join(ranked, on="id_agrupado", how="left")


def calcular_fatores(item_unidades_df: pl.DataFrame) -> pl.DataFrame:
    if item_unidades_df.is_empty():
        return item_unidades_df

    base = choose_unid_ref(item_unidades_df)
    refs = (
        base.filter(pl.col("unid") == pl.col("unid_ref_auto"))
        .select(["id_agrupado", pl.col("preco_medio").alias("preco_unid_ref")])
    )
    result = base.join(refs, on="id_agrupado", how="left").with_columns(
        pl.col("unid_ref_auto").alias("unid_ref"),
        pl.when((pl.col("preco_unid_ref") > 0) & (pl.col("preco_medio") > 0))
        .then(pl.col("preco_medio") / pl.col("preco_unid_ref"))
        .otherwise(1.0)
        .alias("fator"),
        pl.lit("preco").alias("tipo_fator"),
        pl.lit(0.6).alias("confianca_fator"),
        pl.lit("preco_medio_relativo").alias("fonte_fator"),
    )
    return result
