from __future__ import annotations

import polars as pl

from pipeline.mercadorias.grouping import bootstrap_produtos_final
from pipeline.normalization.keys import normalize_text


def build_produtos_agrupados(itens_df: pl.DataFrame) -> pl.DataFrame:
    if itens_df.is_empty():
        return pl.DataFrame()

    required = [c for c in [
        "id_agrupado",
        "codigo_fonte",
        "descr_item",
        "descr_compl",
        "ncm",
        "cest",
        "codigo_produto_original",
        "id_linha_origem",
    ] if c in itens_df.columns]

    df = itens_df.select(required)
    if "descr_item" in df.columns:
        df = df.with_columns(pl.col("descr_item").map_elements(normalize_text, return_dtype=pl.Utf8))
    if "descr_compl" in df.columns:
        df = df.with_columns(pl.col("descr_compl").map_elements(normalize_text, return_dtype=pl.Utf8))

    grouped = df.group_by("id_agrupado").agg(
        pl.col("descr_item").drop_nulls().unique().sort().alias("lista_descricoes"),
        pl.col("descr_compl").drop_nulls().unique().sort().alias("lista_desc_compl"),
        pl.col("codigo_produto_original").drop_nulls().unique().sort().alias("lista_itens_agrupados"),
        pl.col("id_linha_origem").drop_nulls().unique().sort().alias("ids_origem_agrupamento"),
        pl.col("codigo_fonte").drop_nulls().unique().sort().alias("codigos_fonte"),
        pl.col("ncm").drop_nulls().first().alias("ncm_padrao"),
        pl.col("cest").drop_nulls().first().alias("cest_padrao"),
    )
    return grouped


def build_id_agrupados(produtos_agrupados_df: pl.DataFrame) -> pl.DataFrame:
    if produtos_agrupados_df.is_empty():
        return pl.DataFrame()
    return produtos_agrupados_df.select(
        "id_agrupado",
        pl.col("lista_itens_agrupados"),
        pl.col("ids_origem_agrupamento"),
        pl.col("codigos_fonte"),
    )


def build_produtos_final(produtos_agrupados_df: pl.DataFrame, base_info_df: pl.DataFrame | None = None) -> pl.DataFrame:
    if produtos_agrupados_df.is_empty():
        return pl.DataFrame()

    df = produtos_agrupados_df.with_columns(
        pl.col("lista_descricoes").list.first().alias("descr_padrao"),
        pl.lit("UN").alias("unid_ref"),
        pl.lit(None, dtype=pl.Utf8).alias("gtin_padrao"),
        pl.lit(None, dtype=pl.Utf8).alias("embalagem"),
        pl.lit(None, dtype=pl.Utf8).alias("conteudo"),
        pl.col("codigos_fonte").list.first().alias("codigo_fonte"),
    )

    if base_info_df is not None and not base_info_df.is_empty() and "id_agrupado" in base_info_df.columns:
        keep_cols = [c for c in ["id_agrupado", "gtin_padrao", "unid_ref", "embalagem", "conteudo"] if c in base_info_df.columns]
        if keep_cols:
            df = df.drop([c for c in ["gtin_padrao", "unid_ref", "embalagem", "conteudo"] if c in df.columns]).join(
                base_info_df.select(keep_cols).unique(subset=["id_agrupado"]),
                on="id_agrupado",
                how="left",
            )
            if "unid_ref" not in df.columns:
                df = df.with_columns(pl.lit("UN").alias("unid_ref"))

    return bootstrap_produtos_final(df)
