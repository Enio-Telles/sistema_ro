from __future__ import annotations

import polars as pl


def build_estoque_resumo(aba_anual_df: pl.DataFrame, fatores_df: pl.DataFrame | None = None) -> pl.DataFrame:
    if aba_anual_df.is_empty():
        return pl.DataFrame()

    resumo = aba_anual_df.select(
        pl.len().alias("total_produtos"),
        pl.col("saidas_desacob").sum().alias("total_saidas_desacob"),
        pl.col("estoque_final_desacob").sum().alias("total_estoque_final_desacob"),
        pl.col("entradas_desacob").sum().alias("total_entradas_desacob"),
    )

    if fatores_df is not None and not fatores_df.is_empty() and "tipo_fator" in fatores_df.columns:
        fatores_resumo = fatores_df.select(
            pl.when(pl.col("tipo_fator") == "manual").then(1).otherwise(0).sum().alias("produtos_com_fator_manual"),
            pl.when(pl.col("confianca_fator") < 0.7).then(1).otherwise(0).sum().alias("produtos_com_baixa_confianca"),
        )
        return pl.concat([resumo, fatores_resumo], how="horizontal")
    return resumo


def build_estoque_alertas(aba_anual_df: pl.DataFrame, fatores_df: pl.DataFrame | None = None) -> pl.DataFrame:
    if aba_anual_df.is_empty():
        return pl.DataFrame()

    alertas = aba_anual_df.with_columns(
        (pl.col("saidas_desacob") > 0).alias("alerta_saidas_desacob"),
        (pl.col("estoque_final_desacob") > 0).alias("alerta_estoque_final_desacob"),
        (pl.col("entradas_desacob") > 0).alias("alerta_entradas_desacob"),
    )

    if fatores_df is not None and not fatores_df.is_empty() and "id_agrupado" in fatores_df.columns:
        factor_select = [c for c in ["id_agrupado", "tipo_fator", "confianca_fator"] if c in fatores_df.columns]
        alertas = alertas.join(
            fatores_df.select(factor_select).rename({"id_agrupado": "id_agregado"}).unique(subset=["id_agregado"]),
            on="id_agregado",
            how="left",
        ).with_columns(
            (pl.col("tipo_fator") == "manual").alias("alerta_fator_manual"),
            (pl.col("confianca_fator") < 0.7).alias("alerta_baixa_confianca_fator"),
        )
    return alertas
