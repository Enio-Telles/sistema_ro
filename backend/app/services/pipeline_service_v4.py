from __future__ import annotations

import polars as pl

from pipeline.persist_gold_v2 import persist_gold_outputs_v2
from pipeline.run_cnpj_v4 import run_gold_pipeline_v4


def run_and_persist_gold_pipeline_v4(
    cnpj: str,
    *,
    itens_df: pl.DataFrame,
    c170_df: pl.DataFrame,
    nfe_df: pl.DataFrame,
    nfce_df: pl.DataFrame,
    bloco_h_df: pl.DataFrame,
    overrides_df: pl.DataFrame | None = None,
    base_info_df: pl.DataFrame | None = None,
) -> dict:
    outputs = run_gold_pipeline_v4(
        itens_df,
        c170_df=c170_df,
        nfe_df=nfe_df,
        nfce_df=nfce_df,
        bloco_h_df=bloco_h_df,
        overrides_df=overrides_df,
        base_info_df=base_info_df,
    )
    saved = persist_gold_outputs_v2(cnpj, outputs)
    return {
        "cnpj": cnpj,
        "saved": saved,
        "datasets": list(saved.keys()),
        "rows": {name: df.height for name, df in outputs.items() if name in saved},
    }
