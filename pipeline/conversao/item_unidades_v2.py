from __future__ import annotations

import polars as pl

from pipeline.references.sefin_projection import project_sefin_fields


SEFIN_AGG_COLS = [
    "co_sefin_agr",
    "co_sefin_final",
    "it_pc_interna",
    "it_in_st",
    "it_pc_mva",
    "it_in_mva_ajustado",
    "it_pc_reducao",
    "it_in_reducao_credito",
]


def build_item_unidades_v2(itens_df: pl.DataFrame, produtos_df: pl.DataFrame) -> pl.DataFrame:
    if itens_df.is_empty() or produtos_df.is_empty():
        return pl.DataFrame()

    itens = project_sefin_fields(itens_df)
    join_keys = [key for key in ["codigo_fonte", "id_agrupado"] if key in itens.columns and key in produtos_df.columns]
    if not join_keys:
        return pl.DataFrame()

    produto_cols = [col for col in ["codigo_fonte", "id_agrupado", "mercadoria_id", "apresentacao_id", "descr_padrao", "unid_ref"] if col in produtos_df.columns]
    group_keys = [col for col in ["id_agrupado", "mercadoria_id", "apresentacao_id", "unid", "unid_ref"] if col in itens.columns or col in produtos_df.columns]

    aggs = [
        pl.col("vl_item").sum().alias("valor_total"),
        pl.col("qtd").sum().alias("qtd_total"),
        pl.len().alias("linhas"),
    ]
    for col in SEFIN_AGG_COLS:
        if col in itens.columns:
            aggs.append(pl.col(col).drop_nulls().first().alias(col))

    result = (
        itens.join(produtos_df.select(produto_cols), on=join_keys, how="left")
        .group_by(group_keys)
        .agg(aggs)
        .with_columns(
            pl.when(pl.col("qtd_total") > 0)
            .then(pl.col("valor_total") / pl.col("qtd_total"))
            .otherwise(None)
            .alias("preco_medio")
        )
    )
    return result
