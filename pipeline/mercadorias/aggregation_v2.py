from __future__ import annotations

import hashlib
import re
from typing import Any

import polars as pl


def normalize_descr_agregacao(value: Any) -> str:
    if value is None:
        return ""
    text = str(value).upper().strip()
    return re.sub(r"\s+", " ", text)


def build_auto_id_agrupado(descricao_normalizada: str) -> str:
    digest = hashlib.sha1(descricao_normalizada.encode("utf-8")).hexdigest()[:12]
    return f"AGR_{digest}"


def build_agrupamento_v2(itens_df: pl.DataFrame, mapa_manual_df: pl.DataFrame | None = None) -> dict[str, pl.DataFrame]:
    if itens_df.is_empty():
        empty = pl.DataFrame()
        return {
            "map_produto_agrupado": empty,
            "produtos_agrupados": empty,
            "produtos_final": empty,
        }

    df = itens_df.with_columns(
        pl.col("descr_item").cast(pl.Utf8, strict=False).fill_null("").map_elements(normalize_descr_agregacao, return_dtype=pl.Utf8).alias("descricao_normalizada"),
        pl.col("descr_item").cast(pl.Utf8, strict=False).fill_null("").alias("descr_item"),
        pl.col("descr_compl").cast(pl.Utf8, strict=False).fill_null("").alias("descr_compl"),
        pl.col("codigo_produto_original").cast(pl.Utf8, strict=False).fill_null("").alias("codigo_produto_original"),
        pl.col("ncm").cast(pl.Utf8, strict=False).fill_null("").alias("ncm"),
        pl.col("cest").cast(pl.Utf8, strict=False).fill_null("").alias("cest"),
        pl.col("gtin_padrao").cast(pl.Utf8, strict=False).fill_null("").alias("gtin_padrao") if "gtin_padrao" in itens_df.columns else pl.lit("").alias("gtin_padrao"),
        pl.col("unid").cast(pl.Utf8, strict=False).fill_null("").alias("unid"),
        pl.col("tipo_item").cast(pl.Utf8, strict=False).fill_null("").alias("tipo_item") if "tipo_item" in itens_df.columns else pl.lit("").alias("tipo_item"),
    )

    df = df.with_columns(
        pl.col("descricao_normalizada").map_elements(build_auto_id_agrupado, return_dtype=pl.Utf8).alias("id_agrupado_auto")
    )

    if mapa_manual_df is not None and not mapa_manual_df.is_empty() and "codigo_fonte" in mapa_manual_df.columns and "id_agrupado_manual" in mapa_manual_df.columns:
        df = df.join(
            mapa_manual_df.select(["codigo_fonte", "id_agrupado_manual"]).unique(subset=["codigo_fonte"]),
            on="codigo_fonte",
            how="left",
        ).with_columns(
            pl.when(pl.col("id_agrupado_manual").is_not_null())
            .then(pl.col("id_agrupado_manual"))
            .otherwise(pl.col("id_agrupado_auto"))
            .alias("id_agrupado")
        )
    else:
        df = df.with_columns(pl.col("id_agrupado_auto").alias("id_agrupado"))

    map_produto_agrupado = df.select([
        c for c in [
            "id_linha_origem",
            "codigo_fonte",
            "descricao_normalizada",
            "id_agrupado",
            "id_agrupado_auto",
            "codigo_produto_original",
            "descr_item",
            "descr_compl",
            "tipo_item",
            "ncm",
            "cest",
            "gtin_padrao",
            "unid",
        ] if c in df.columns
    ])

    produtos_agrupados = df.group_by("id_agrupado").agg(
        pl.col("descricao_normalizada").drop_nulls().unique().sort().alias("lista_descricoes_normalizadas"),
        pl.col("descr_item").drop_nulls().unique().sort().alias("lista_descricoes"),
        pl.col("descr_compl").drop_nulls().unique().sort().alias("lista_desc_compl"),
        pl.col("codigo_produto_original").drop_nulls().unique().sort().alias("lista_itens_agrupados"),
        pl.col("id_linha_origem").drop_nulls().unique().sort().alias("ids_origem_agrupamento"),
        pl.col("codigo_fonte").drop_nulls().unique().sort().alias("codigos_fonte"),
        pl.col("tipo_item").drop_nulls().unique().sort().alias("lista_tipo_item"),
        pl.col("ncm").drop_nulls().unique().sort().alias("lista_ncm"),
        pl.col("cest").drop_nulls().unique().sort().alias("lista_cest"),
        pl.col("gtin_padrao").drop_nulls().unique().sort().alias("lista_gtin"),
        pl.col("unid").drop_nulls().unique().sort().alias("lista_unidades"),
    )

    produtos_final = produtos_agrupados.with_columns(
        pl.col("lista_descricoes").list.first().alias("descr_padrao"),
        pl.col("lista_ncm").list.first().alias("ncm_padrao"),
        pl.col("lista_cest").list.first().alias("cest_padrao"),
        pl.col("lista_gtin").list.first().alias("gtin_padrao"),
        pl.col("lista_unidades").list.first().alias("unid_ref"),
    )

    return {
        "map_produto_agrupado": map_produto_agrupado,
        "produtos_agrupados": produtos_agrupados,
        "produtos_final": produtos_final,
    }
