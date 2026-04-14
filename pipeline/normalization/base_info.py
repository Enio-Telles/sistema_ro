from __future__ import annotations

import polars as pl


def build_base_info_mercadorias(itens_unificados_df: pl.DataFrame) -> pl.DataFrame:
    if itens_unificados_df.is_empty():
        return pl.DataFrame()

    return itens_unificados_df.group_by("id_agrupado").agg(
        pl.col("gtin_padrao").drop_nulls().first().alias("gtin_padrao"),
        pl.col("unid").drop_nulls().first().alias("unid_ref"),
        pl.col("descr_item").drop_nulls().first().alias("descr_padrao"),
        pl.col("ncm").drop_nulls().first().alias("ncm_padrao"),
        pl.col("cest").drop_nulls().first().alias("cest_padrao"),
        pl.col("codigo_fonte").drop_nulls().first().alias("codigo_fonte"),
        pl.col("descr_compl").drop_nulls().unique().sort().alias("lista_desc_compl"),
    ).with_columns(
        pl.lit(None, dtype=pl.Utf8).alias("embalagem"),
        pl.lit(None, dtype=pl.Utf8).alias("conteudo"),
    )
