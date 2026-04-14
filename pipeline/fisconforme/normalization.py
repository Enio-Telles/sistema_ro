from __future__ import annotations

import polars as pl

from pipeline.normalization.keys import normalize_cnpj, normalize_ie


def normalize_fisconforme_cadastral(df: pl.DataFrame) -> pl.DataFrame:
    if df.is_empty():
        return df
    return df.with_columns(
        pl.col("cnpj").map_elements(normalize_cnpj, return_dtype=pl.Utf8).alias("cnpj"),
        pl.col("ie").map_elements(normalize_ie, return_dtype=pl.Utf8).alias("ie"),
        pl.col("razao_social").cast(pl.Utf8, strict=False),
        pl.col("nome_fantasia").cast(pl.Utf8, strict=False),
    )


def normalize_fisconforme_malhas(df: pl.DataFrame) -> pl.DataFrame:
    if df.is_empty():
        return df
    return df.with_columns(
        pl.col("cnpj").map_elements(normalize_cnpj, return_dtype=pl.Utf8).alias("cnpj"),
        pl.col("id_pendencia").cast(pl.Utf8, strict=False),
        pl.col("id_notificacao").cast(pl.Utf8, strict=False),
        pl.col("malhas_id").cast(pl.Utf8, strict=False),
        pl.col("titulo_malha").cast(pl.Utf8, strict=False),
        pl.col("status_pendencia").cast(pl.Utf8, strict=False),
        pl.col("status_notificacao").cast(pl.Utf8, strict=False),
    )
