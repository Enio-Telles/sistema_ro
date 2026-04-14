from __future__ import annotations

import polars as pl

from pipeline.normalization.base_info import build_base_info_mercadorias
from pipeline.normalization.unified_items import build_itens_unificados


def run_silver_base_pipeline(
    *,
    c170_df: pl.DataFrame,
    nfe_df: pl.DataFrame,
    nfce_df: pl.DataFrame,
    bloco_h_df: pl.DataFrame | None = None,
) -> dict[str, pl.DataFrame]:
    itens_unificados = build_itens_unificados(c170_df, nfe_df, nfce_df, bloco_h_df)
    base_info_mercadorias = build_base_info_mercadorias(itens_unificados)
    return {
        "itens_unificados": itens_unificados,
        "base_info_mercadorias": base_info_mercadorias,
    }
