from __future__ import annotations

import polars as pl

REQUIRED_MANUAL_MAP_COLUMNS = [
    "codigo_fonte",
    "id_agrupado_manual",
]

OPTIONAL_MANUAL_MAP_COLUMNS = [
    "motivo",
    "usuario",
    "observacao",
    "data_regra",
]


def validate_manual_map_df(df: pl.DataFrame) -> dict:
    missing_columns = [col for col in REQUIRED_MANUAL_MAP_COLUMNS if col not in df.columns]
    duplicate_codigo_fonte = 0
    null_codigo_fonte = 0
    null_id_agrupado_manual = 0

    if not df.is_empty() and "codigo_fonte" in df.columns:
        duplicate_codigo_fonte = (
            df.group_by("codigo_fonte")
            .agg(pl.len().alias("rows"))
            .filter(pl.col("rows") > 1)
            .height
        )
        null_codigo_fonte = df.filter(pl.col("codigo_fonte").cast(pl.Utf8, strict=False).fill_null("") == "").height
    if not df.is_empty() and "id_agrupado_manual" in df.columns:
        null_id_agrupado_manual = df.filter(pl.col("id_agrupado_manual").cast(pl.Utf8, strict=False).fill_null("") == "").height

    return {
        "ok": not missing_columns and duplicate_codigo_fonte == 0 and null_codigo_fonte == 0 and null_id_agrupado_manual == 0,
        "required_columns": REQUIRED_MANUAL_MAP_COLUMNS,
        "optional_columns": OPTIONAL_MANUAL_MAP_COLUMNS,
        "missing_columns": missing_columns,
        "duplicate_codigo_fonte": duplicate_codigo_fonte,
        "null_codigo_fonte": null_codigo_fonte,
        "null_id_agrupado_manual": null_id_agrupado_manual,
    }
