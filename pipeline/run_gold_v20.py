from __future__ import annotations

import polars as pl

from pipeline.conversao.anomalias import build_conversion_anomalies
from pipeline.conversao.fatores_v4 import calcular_fatores_priorizados_v4
from pipeline.conversao.item_unidades_v3 import build_item_unidades_v3
from pipeline.conversao.overrides import apply_manual_overrides
from pipeline.estoque.derivados_fiscais_v4 import build_aba_anual_v4, build_aba_mensal_v4, build_aba_periodos_v4
from pipeline.estoque.mov_estoque_v3 import build_mov_estoque_v3
from pipeline.estoque.resumo import build_estoque_alertas, build_estoque_resumo
from pipeline.mercadorias.mercadoria_pipeline_v2 import run_mercadoria_v2


def _mercadorias_from_precomputed(
    *,
    map_produto_agrupado_df: pl.DataFrame | None,
    produtos_agrupados_df: pl.DataFrame | None,
    id_agrupados_df: pl.DataFrame | None,
    produtos_final_df: pl.DataFrame | None,
) -> dict[str, pl.DataFrame] | None:
    if produtos_final_df is None or produtos_final_df.is_empty():
        return None
    return {
        "map_produto_agrupado": map_produto_agrupado_df if map_produto_agrupado_df is not None else pl.DataFrame(),
        "produtos_agrupados": produtos_agrupados_df if produtos_agrupados_df is not None else pl.DataFrame(),
        "id_agrupados": id_agrupados_df if id_agrupados_df is not None else pl.DataFrame(),
        "produtos_final": produtos_final_df,
    }


def run_gold_v20(
    itens_df: pl.DataFrame,
    *,
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
    sefin_vigencia_df: pl.DataFrame | None = None,
) -> dict[str, pl.DataFrame]:
    mercadorias = _mercadorias_from_precomputed(
        map_produto_agrupado_df=map_produto_agrupado_df,
        produtos_agrupados_df=produtos_agrupados_df,
        id_agrupados_df=id_agrupados_df,
        produtos_final_df=produtos_final_df,
    )
    if mercadorias is None:
        mercadorias = run_mercadoria_v2(itens_df, base_info_df=base_info_df, mapa_manual_df=mapa_manual_df)

    produtos_final = mercadorias["produtos_final"]
    item_unidades = build_item_unidades_v3(itens_df, produtos_final, diagnostico_df=diagnostico_conversao_df)
    fatores = calcular_fatores_priorizados_v4(item_unidades, itens_df)
    fatores = apply_manual_overrides(fatores, overrides_df)
    log_conversao_anomalias = build_conversion_anomalies(fatores)
    mov_estoque = build_mov_estoque_v3(c170_df, nfe_df, nfce_df, bloco_h_df, fatores, item_unidades)
    aba_mensal = build_aba_mensal_v4(mov_estoque, vigencia_df=sefin_vigencia_df)
    aba_anual = build_aba_anual_v4(mov_estoque, vigencia_df=sefin_vigencia_df)
    aba_periodos = build_aba_periodos_v4(mov_estoque, vigencia_df=sefin_vigencia_df)
    estoque_resumo = build_estoque_resumo(aba_anual, fatores)
    estoque_alertas = build_estoque_alertas(aba_anual, fatores)
    return {
        **mercadorias,
        "item_unidades": item_unidades,
        "fatores_conversao": fatores,
        "log_conversao_anomalias": log_conversao_anomalias,
        "mov_estoque": mov_estoque,
        "aba_mensal": aba_mensal,
        "aba_anual": aba_anual,
        "aba_periodos": aba_periodos,
        "estoque_resumo": estoque_resumo,
        "estoque_alertas": estoque_alertas,
    }
