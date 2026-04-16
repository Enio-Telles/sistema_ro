from __future__ import annotations

import polars as pl

from backend.app.services.conversao_quality_summary import summarize_conversion_quality
from pipeline.persist_gold_v2 import persist_gold_outputs_v2
from pipeline.run_gold_v20 import run_gold_v20


def run_and_persist_gold_v20(
    cnpj: str,
    *,
    itens_df: pl.DataFrame,
    c170_df: pl.DataFrame,
    nfe_df: pl.DataFrame,
    nfce_df: pl.DataFrame,
    bloco_h_df: pl.DataFrame,
    overrides_df: pl.DataFrame | None = None,
    base_info_df: pl.DataFrame | None = None,
    mapa_manual_df: pl.DataFrame | None = None,
    map_produto_agrupado_df: pl.DataFrame | None = None,
    produtos_agrupados_df: pl.DataFrame | None = None,
    id_agrupados_df: pl.DataFrame | None = None,
    produtos_final_df: pl.DataFrame | None = None,
    diagnostico_conversao_df: pl.DataFrame | None = None,
) -> dict:
    outputs = run_gold_v20(
        itens_df,
        c170_df=c170_df,
        nfe_df=nfe_df,
        nfce_df=nfce_df,
        bloco_h_df=bloco_h_df,
        overrides_df=overrides_df,
        base_info_df=base_info_df,
        mapa_manual_df=mapa_manual_df,
        map_produto_agrupado_df=map_produto_agrupado_df,
        produtos_agrupados_df=produtos_agrupados_df,
        id_agrupados_df=id_agrupados_df,
        produtos_final_df=produtos_final_df,
        diagnostico_conversao_df=diagnostico_conversao_df,
    )
    saved = persist_gold_outputs_v2(cnpj, outputs)
    conversion_quality = summarize_conversion_quality(
        item_unidades_df=outputs.get("item_unidades"),
        fatores_df=outputs.get("fatores_conversao"),
        anomalias_df=outputs.get("log_conversao_anomalias"),
    )
    return {
        "cnpj": cnpj,
        "saved": saved,
        "datasets": list(saved.keys()),
        "rows": {name: df.height for name, df in outputs.items() if name in saved},
        "conversion_quality": conversion_quality,
    }
