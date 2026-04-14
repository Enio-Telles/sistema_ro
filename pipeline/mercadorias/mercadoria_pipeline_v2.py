from __future__ import annotations

import polars as pl

from pipeline.mercadorias.aggregation_v2 import build_agrupamento_v2
from pipeline.mercadorias.grouping import bootstrap_produtos_final


def run_mercadoria_v2(
    itens_df: pl.DataFrame,
    base_info_df: pl.DataFrame | None = None,
    mapa_manual_df: pl.DataFrame | None = None,
) -> dict[str, pl.DataFrame]:
    outputs = build_agrupamento_v2(itens_df, mapa_manual_df=mapa_manual_df)
    produtos_agrupados = outputs["produtos_agrupados"]
    map_produto_agrupado = outputs["map_produto_agrupado"]
    produtos_final = outputs["produtos_final"]

    if base_info_df is not None and not base_info_df.is_empty() and "id_agrupado" in base_info_df.columns:
        keep_cols = [c for c in ["id_agrupado", "gtin_padrao", "unid_ref", "embalagem", "conteudo"] if c in base_info_df.columns]
        if keep_cols:
            produtos_final = produtos_final.drop([c for c in ["gtin_padrao", "unid_ref", "embalagem", "conteudo"] if c in produtos_final.columns]).join(
                base_info_df.select(keep_cols).unique(subset=["id_agrupado"]),
                on="id_agrupado",
                how="left",
            )
    if "unid_ref" not in produtos_final.columns:
        produtos_final = produtos_final.with_columns(pl.lit("UN").alias("unid_ref"))
    if "gtin_padrao" not in produtos_final.columns:
        produtos_final = produtos_final.with_columns(pl.lit(None, dtype=pl.Utf8).alias("gtin_padrao"))
    if "embalagem" not in produtos_final.columns:
        produtos_final = produtos_final.with_columns(pl.lit(None, dtype=pl.Utf8).alias("embalagem"))
    if "conteudo" not in produtos_final.columns:
        produtos_final = produtos_final.with_columns(pl.lit(None, dtype=pl.Utf8).alias("conteudo"))

    produtos_final = bootstrap_produtos_final(produtos_final)

    id_agrupados = map_produto_agrupado.group_by("id_agrupado").agg(
        pl.col("codigo_produto_original").drop_nulls().unique().sort().alias("lista_itens_agrupados"),
        pl.col("id_linha_origem").drop_nulls().unique().sort().alias("ids_origem_agrupamento"),
        pl.col("codigo_fonte").drop_nulls().unique().sort().alias("codigos_fonte"),
    ) if not map_produto_agrupado.is_empty() else pl.DataFrame()

    return {
        "map_produto_agrupado": map_produto_agrupado,
        "produtos_agrupados": produtos_agrupados,
        "id_agrupados": id_agrupados,
        "produtos_final": produtos_final,
    }
