from __future__ import annotations

import polars as pl

from pipeline.conversao.item_unidades_v2 import build_item_unidades_v2


def _aggregate_diagnostico(diagnostico_df: pl.DataFrame) -> pl.DataFrame:
    if diagnostico_df.is_empty() or "id_agrupado" not in diagnostico_df.columns or "unid" not in diagnostico_df.columns:
        return pl.DataFrame()

    diag = diagnostico_df.with_columns(
        pl.col("id_agrupado").cast(pl.Utf8, strict=False).fill_null("").alias("id_agrupado"),
        pl.col("unid").cast(pl.Utf8, strict=False).fill_null("").alias("unid"),
        pl.col("unid_ref").cast(pl.Utf8, strict=False).fill_null("").alias("unid_ref_diag") if "unid_ref" in diagnostico_df.columns else pl.lit("").alias("unid_ref_diag"),
        pl.col("evidencia").cast(pl.Utf8, strict=False).fill_null("").alias("evidencia_diag") if "evidencia" in diagnostico_df.columns else pl.lit("").alias("evidencia_diag"),
        pl.col("necessita_conversao").cast(pl.Boolean, strict=False).fill_null(False).alias("necessita_conversao_diag") if "necessita_conversao" in diagnostico_df.columns else pl.lit(False).alias("necessita_conversao_diag"),
    )

    return diag.group_by(["id_agrupado", "unid"]).agg(
        pl.col("necessita_conversao_diag").any().alias("necessita_conversao_diag"),
        pl.col("unid_ref_diag").filter(pl.col("unid_ref_diag") != "").first().alias("unid_ref_diag"),
        pl.col("evidencia_diag").filter(pl.col("evidencia_diag") != "").first().alias("evidencia_diag"),
        pl.len().alias("linhas_diagnostico"),
    ).with_columns(
        pl.lit(True).alias("possui_diagnostico_conversao")
    )


def build_item_unidades_v3(
    itens_df: pl.DataFrame,
    produtos_df: pl.DataFrame,
    diagnostico_df: pl.DataFrame | None = None,
) -> pl.DataFrame:
    result = build_item_unidades_v2(itens_df, produtos_df)
    if result.is_empty() or diagnostico_df is None or diagnostico_df.is_empty():
        return result

    aggregated = _aggregate_diagnostico(diagnostico_df)
    if aggregated.is_empty():
        return result

    join_keys = [col for col in ["id_agrupado", "unid"] if col in result.columns and col in aggregated.columns]
    if len(join_keys) != 2:
        return result

    result = result.join(aggregated, on=join_keys, how="left")
    return result.with_columns(
        pl.col("possui_diagnostico_conversao").fill_null(False).alias("possui_diagnostico_conversao"),
        pl.col("necessita_conversao_diag").fill_null(False).alias("necessita_conversao_diag"),
        pl.col("linhas_diagnostico").fill_null(0).alias("linhas_diagnostico"),
        pl.col("unid_ref_diag").cast(pl.Utf8, strict=False).fill_null("").alias("unid_ref_diag"),
        pl.col("evidencia_diag").cast(pl.Utf8, strict=False).fill_null("").alias("evidencia_diag"),
    )
