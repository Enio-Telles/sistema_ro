from __future__ import annotations

import polars as pl

from pipeline.conversao.fatores import calcular_fatores
from pipeline.conversao.item_unidades import build_item_unidades
from pipeline.conversao.overrides import apply_manual_overrides
from pipeline.estoque.derivados import build_aba_anual, build_aba_mensal, build_aba_periodos
from pipeline.estoque.mov_estoque import build_mov_estoque
from pipeline.estoque.resumo import build_estoque_alertas, build_estoque_resumo
from pipeline.mercadorias.pipeline import run_mercadoria_pipeline


def run_gold_pipeline(
    itens_df: pl.DataFrame,
    *,
    c170_df: pl.DataFrame,
    nfe_df: pl.DataFrame,
    nfce_df: pl.DataFrame,
    bloco_h_df: pl.DataFrame,
    overrides_df: pl.DataFrame | None = None,
    base_info_df: pl.DataFrame | None = None,
) -> dict[str, pl.DataFrame]:
    mercadorias = run_mercadoria_pipeline(itens_df, base_info_df=base_info_df)
    produtos_final = mercadorias["produtos_final"]
    item_unidades = build_item_unidades(itens_df, produtos_final)
    fatores = calcular_fatores(item_unidades)
    fatores = apply_manual_overrides(fatores, overrides_df)
    mov_estoque = build_mov_estoque(c170_df, nfe_df, nfce_df, bloco_h_df, fatores)
    aba_mensal = build_aba_mensal(mov_estoque)
    aba_anual = build_aba_anual(mov_estoque)
    aba_periodos = build_aba_periodos(mov_estoque)
    estoque_resumo = build_estoque_resumo(aba_anual, fatores)
    estoque_alertas = build_estoque_alertas(aba_anual, fatores)
    return {
        **mercadorias,
        "item_unidades": item_unidades,
        "fatores_conversao": fatores,
        "mov_estoque": mov_estoque,
        "aba_mensal": aba_mensal,
        "aba_anual": aba_anual,
        "aba_periodos": aba_periodos,
        "estoque_resumo": estoque_resumo,
        "estoque_alertas": estoque_alertas,
    }
