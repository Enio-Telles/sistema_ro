from __future__ import annotations

import polars as pl


def _count_tipo_fator(df: pl.DataFrame | None, tipo: str) -> int:
    if df is None or df.is_empty() or "tipo_fator" not in df.columns:
        return 0
    return df.filter(df["tipo_fator"] == tipo).height


def _count_true(df: pl.DataFrame | None, column: str) -> int:
    if df is None or df.is_empty() or column not in df.columns:
        return 0
    return df.filter(df[column] == True).height


def summarize_conversion_quality(
    *,
    item_unidades_df: pl.DataFrame | None = None,
    fatores_df: pl.DataFrame | None = None,
    anomalias_df: pl.DataFrame | None = None,
) -> dict:
    return {
        "total_item_unidades": 0 if item_unidades_df is None else item_unidades_df.height,
        "total_fatores": 0 if fatores_df is None else fatores_df.height,
        "fatores_estruturais": _count_tipo_fator(fatores_df, "estrutural"),
        "fatores_preco": _count_tipo_fator(fatores_df, "preco"),
        "fatores_manuais": _count_tipo_fator(fatores_df, "manual"),
        "anomalias_total": 0 if anomalias_df is None else anomalias_df.height,
        "anomalias_mesma_unidade": _count_true(
            anomalias_df, "anomalia_mesma_unidade_fator_diferente"
        ),
        "anomalias_baixa_confianca": _count_true(
            anomalias_df, "anomalia_preco_baixa_confianca"
        ),
    }
