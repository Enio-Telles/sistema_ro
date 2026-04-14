from __future__ import annotations

import polars as pl

from pipeline.estoque.mov_estoque_v2 import build_mov_estoque_v2


SEFIN_JOIN_COLS = [
    "id_agrupado",
    "co_sefin_agr",
    "co_sefin_final",
    "it_pc_interna",
    "it_in_st",
    "it_pc_mva",
    "it_in_mva_ajustado",
    "it_pc_reducao",
    "it_in_reducao_credito",
]


def build_mov_estoque_v3(
    c170_df: pl.DataFrame,
    nfe_df: pl.DataFrame,
    nfce_df: pl.DataFrame,
    bloco_h_df: pl.DataFrame,
    fatores_df: pl.DataFrame,
    item_unidades_df: pl.DataFrame,
) -> pl.DataFrame:
    mov = build_mov_estoque_v2(c170_df, nfe_df, nfce_df, bloco_h_df, fatores_df)
    if mov.is_empty() or item_unidades_df.is_empty() or "id_agrupado" not in mov.columns or "id_agrupado" not in item_unidades_df.columns:
        return mov

    join_cols = [c for c in SEFIN_JOIN_COLS if c in item_unidades_df.columns]
    if len(join_cols) <= 1:
        return mov

    fiscais = item_unidades_df.select(join_cols).unique(subset=["id_agrupado"])
    mov = mov.join(fiscais, on="id_agrupado", how="left", suffix="_itemun")
    if "it_pc_interna" in mov.columns:
        mov = mov.with_columns(pl.col("it_pc_interna").cast(pl.Float64, strict=False).alias("it_pc_interna"))
    return mov
