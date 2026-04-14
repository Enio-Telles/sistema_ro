from __future__ import annotations

import polars as pl


def apply_manual_overrides(fatores_df: pl.DataFrame, overrides_df: pl.DataFrame | None) -> pl.DataFrame:
    if fatores_df.is_empty() or overrides_df is None or overrides_df.is_empty():
        return fatores_df

    override_cols = [c for c in ["id_agrupado", "unid_ref_manual", "fator_manual", "justificativa_fator"] if c in overrides_df.columns]
    if "id_agrupado" not in override_cols:
        return fatores_df

    joined = fatores_df.join(
        overrides_df.select(override_cols).unique(subset=["id_agrupado"]),
        on="id_agrupado",
        how="left",
    )

    return joined.with_columns(
        pl.when(pl.col("unid_ref_manual").is_not_null()).then(pl.col("unid_ref_manual")).otherwise(pl.col("unid_ref")).alias("unid_ref"),
        pl.when(pl.col("fator_manual").is_not_null()).then(pl.col("fator_manual")).otherwise(pl.col("fator")).alias("fator"),
        pl.when(pl.col("fator_manual").is_not_null()).then(pl.lit("manual")).otherwise(pl.col("tipo_fator")).alias("tipo_fator"),
        pl.when(pl.col("fator_manual").is_not_null()).then(pl.lit(1.0)).otherwise(pl.col("confianca_fator")).alias("confianca_fator"),
        pl.when(pl.col("fator_manual").is_not_null()).then(pl.lit("override_manual")).otherwise(pl.col("fonte_fator")).alias("fonte_fator"),
    )


def build_override_log(fatores_df: pl.DataFrame) -> pl.DataFrame:
    if fatores_df.is_empty() or "tipo_fator" not in fatores_df.columns:
        return pl.DataFrame()
    return fatores_df.filter(pl.col("tipo_fator") == "manual").select(
        [c for c in ["id_agrupado", "unid_ref", "fator", "tipo_fator", "fonte_fator", "justificativa_fator"] if c in fatores_df.columns]
    )
