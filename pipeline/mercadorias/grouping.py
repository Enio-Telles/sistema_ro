from __future__ import annotations

import polars as pl

from pipeline.mercadorias.identity import build_apresentacao_id, build_mercadoria_id, choose_match_rule


def bootstrap_produtos_final(df: pl.DataFrame) -> pl.DataFrame:
    if df.is_empty():
        return df

    result = df.with_columns(
        pl.struct(["gtin_padrao", "ncm_padrao", "cest_padrao", "descr_padrao"]).map_elements(
            lambda row: build_mercadoria_id(
                row.get("gtin_padrao"),
                row.get("ncm_padrao"),
                row.get("cest_padrao"),
                row.get("descr_padrao"),
            ),
            return_dtype=pl.Utf8,
        ).alias("mercadoria_id"),
        pl.struct(["unid_ref", "embalagem", "conteudo"]).map_elements(
            lambda row: build_apresentacao_id(
                row.get("unid_ref"),
                row.get("embalagem"),
                row.get("conteudo"),
            ),
            return_dtype=pl.Utf8,
        ).alias("apresentacao_id"),
        pl.struct(["gtin_padrao", "ncm_padrao", "cest_padrao", "descr_padrao"]).map_elements(
            lambda row: choose_match_rule(
                row.get("gtin_padrao"),
                row.get("ncm_padrao"),
                row.get("cest_padrao"),
                row.get("descr_padrao"),
            ),
            return_dtype=pl.Utf8,
        ).alias("match_rule"),
    )

    if "match_confidence" not in result.columns:
        result = result.with_columns(pl.lit(0.8).alias("match_confidence"))
    if "match_version" not in result.columns:
        result = result.with_columns(pl.lit("v0").alias("match_version"))
    return result
