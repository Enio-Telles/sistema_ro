from __future__ import annotations

import polars as pl


def build_item_unidades(itens_df: pl.DataFrame, produtos_df: pl.DataFrame) -> pl.DataFrame:
    if itens_df.is_empty() or produtos_df.is_empty():
        return pl.DataFrame()

    join_keys = [key for key in ["codigo_fonte", "id_agrupado"] if key in itens_df.columns and key in produtos_df.columns]
    if not join_keys:
        return pl.DataFrame()

    result = (
        itens_df.join(
            produtos_df.select([col for col in ["codigo_fonte", "id_agrupado", "mercadoria_id", "apresentacao_id", "descr_padrao", "unid_ref"] if col in produtos_df.columns]),
            on=join_keys,
            how="left",
        )
        .group_by([col for col in ["id_agrupado", "mercadoria_id", "apresentacao_id", "unid", "unid_ref"] if col in itens_df.columns or col in produtos_df.columns])
        .agg(
            pl.col("vl_item").sum().alias("valor_total"),
            pl.col("qtd").sum().alias("qtd_total"),
            pl.len().alias("linhas"),
        )
        .with_columns(
            pl.when(pl.col("qtd_total") > 0)
            .then(pl.col("valor_total") / pl.col("qtd_total"))
            .otherwise(None)
            .alias("preco_medio")
        )
    )
    return result
