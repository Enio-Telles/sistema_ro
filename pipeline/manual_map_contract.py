from __future__ import annotations

import polars as pl

REQUIRED_MANUAL_MAP_COLUMNS = [
    "codigo_fonte",
    "id_agrupado_manual",
]

RECOMMENDED_MANUAL_MAP_COLUMNS = [
    "regra_id",
    "usuario",
    "motivo",
    "created_at",
    "updated_at",
    "ativo",
    "observacao",
]

OPTIONAL_MANUAL_MAP_COLUMNS = [
    "data_regra",
] + RECOMMENDED_MANUAL_MAP_COLUMNS


def _active_expr() -> pl.Expr:
    return pl.col("ativo").cast(pl.Boolean, strict=False).fill_null(True)


def validate_manual_map_df(df: pl.DataFrame) -> dict:
    missing_columns = [col for col in REQUIRED_MANUAL_MAP_COLUMNS if col not in df.columns]
    missing_recommended_columns = [col for col in RECOMMENDED_MANUAL_MAP_COLUMNS if col not in df.columns]
    duplicate_codigo_fonte = 0
    duplicate_active_regra_id = 0
    null_codigo_fonte = 0
    null_id_agrupado_manual = 0

    if not df.is_empty() and "codigo_fonte" in df.columns:
        scoped = df.filter(_active_expr()) if "ativo" in df.columns else df
        duplicate_codigo_fonte = (
            scoped.group_by("codigo_fonte")
            .agg(pl.len().alias("rows"))
            .filter(pl.col("rows") > 1)
            .height
        )
        null_codigo_fonte = df.filter(pl.col("codigo_fonte").cast(pl.Utf8, strict=False).fill_null("") == "").height
    if not df.is_empty() and "id_agrupado_manual" in df.columns:
        null_id_agrupado_manual = df.filter(pl.col("id_agrupado_manual").cast(pl.Utf8, strict=False).fill_null("") == "").height
    if not df.is_empty() and "regra_id" in df.columns:
        scoped = df.filter(_active_expr()) if "ativo" in df.columns else df
        duplicate_active_regra_id = (
            scoped.filter(pl.col("regra_id").cast(pl.Utf8, strict=False).fill_null("") != "")
            .group_by("regra_id")
            .agg(pl.len().alias("rows"))
            .filter(pl.col("rows") > 1)
            .height
        )

    return {
        "ok": (
            not missing_columns
            and duplicate_codigo_fonte == 0
            and duplicate_active_regra_id == 0
            and null_codigo_fonte == 0
            and null_id_agrupado_manual == 0
        ),
        "required_columns": REQUIRED_MANUAL_MAP_COLUMNS,
        "recommended_columns": RECOMMENDED_MANUAL_MAP_COLUMNS,
        "optional_columns": OPTIONAL_MANUAL_MAP_COLUMNS,
        "missing_columns": missing_columns,
        "missing_recommended_columns": missing_recommended_columns,
        "duplicate_codigo_fonte": duplicate_codigo_fonte,
        "duplicate_active_regra_id": duplicate_active_regra_id,
        "null_codigo_fonte": null_codigo_fonte,
        "null_id_agrupado_manual": null_id_agrupado_manual,
    }
