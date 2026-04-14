from __future__ import annotations

import polars as pl

from backend.app.services.datasets import dataset_ref
from backend.app.services.fontes_agr_validation_service import get_fontes_agr_validation_status
from backend.app.services.layer_datasets import operational_dataset_ref
from pipeline.io.parquet_store import load_parquet


def _load_operational(cnpj: str, layer: str, name: str) -> pl.DataFrame:
    ref = operational_dataset_ref(cnpj, layer, name)
    df = load_parquet(ref)
    return df if df is not None else pl.DataFrame()


def _load_standard(cnpj: str, layer: str, name: str) -> pl.DataFrame:
    ref = dataset_ref(cnpj=cnpj, layer=layer, name=name)
    df = load_parquet(ref)
    return df if df is not None else pl.DataFrame()


def _concat_itens_from_fontes_agr(*frames: pl.DataFrame) -> pl.DataFrame:
    valid = [df for df in frames if df is not None and not df.is_empty()]
    if not valid:
        return pl.DataFrame()
    return pl.concat(valid, how="diagonal_relaxed")


def load_gold_inputs_with_conversion_diagnosis(cnpj: str) -> dict[str, pl.DataFrame | str | bool | dict]:
    validation = get_fontes_agr_validation_status(cnpj)
    diagnostico_df = _load_operational(cnpj, "mdc_base", "diagnostico_conversao_unidade_base")

    if validation["ok"]:
        c170_agr = _load_operational(cnpj, "fontes_agr", "c170_agr")
        nfe_agr = _load_operational(cnpj, "fontes_agr", "nfe_agr")
        nfce_agr = _load_operational(cnpj, "fontes_agr", "nfce_agr")
        bloco_h_agr = _load_operational(cnpj, "fontes_agr", "bloco_h_agr")
        itens_df = _concat_itens_from_fontes_agr(c170_agr, nfe_agr, nfce_agr, bloco_h_agr)
        return {
            "itens_df": itens_df,
            "c170_df": c170_agr,
            "nfe_df": nfe_agr,
            "nfce_df": nfce_agr,
            "bloco_h_df": bloco_h_agr,
            "overrides_df": _load_standard(cnpj, "gold", "overrides_conversao"),
            "base_info_df": _load_standard(cnpj, "silver", "base_info_mercadorias"),
            "mapa_manual_df": _load_standard(cnpj, "gold", "mapa_manual_agregacao"),
            "map_produto_agrupado_df": _load_operational(cnpj, "agregacao", "map_produto_agrupado"),
            "produtos_agrupados_df": _load_operational(cnpj, "agregacao", "produtos_agrupados"),
            "id_agrupados_df": _load_operational(cnpj, "agregacao", "id_agrupados"),
            "produtos_final_df": _load_operational(cnpj, "agregacao", "produtos_final"),
            "diagnostico_conversao_df": diagnostico_df,
            "selected_items_source": "fontes_agr_validated",
            "using_aggregated_sources": True,
            "fontes_agr_validation": validation,
        }

    itens_unificados_sefin = _load_standard(cnpj, "silver", "itens_unificados_sefin")
    itens_unificados = _load_standard(cnpj, "silver", "itens_unificados")
    using_sefin = not itens_unificados_sefin.is_empty()
    itens_df = itens_unificados_sefin if using_sefin else itens_unificados
    return {
        "itens_df": itens_df,
        "c170_df": _load_standard(cnpj, "silver", "efd_c170"),
        "nfe_df": _load_standard(cnpj, "silver", "nfe_itens"),
        "nfce_df": _load_standard(cnpj, "silver", "nfce_itens"),
        "bloco_h_df": _load_standard(cnpj, "silver", "bloco_h"),
        "overrides_df": _load_standard(cnpj, "gold", "overrides_conversao"),
        "base_info_df": _load_standard(cnpj, "silver", "base_info_mercadorias"),
        "mapa_manual_df": _load_standard(cnpj, "gold", "mapa_manual_agregacao"),
        "map_produto_agrupado_df": _load_operational(cnpj, "agregacao", "map_produto_agrupado"),
        "produtos_agrupados_df": _load_operational(cnpj, "agregacao", "produtos_agrupados"),
        "id_agrupados_df": _load_operational(cnpj, "agregacao", "id_agrupados"),
        "produtos_final_df": _load_operational(cnpj, "agregacao", "produtos_final"),
        "diagnostico_conversao_df": diagnostico_df,
        "selected_items_source": "itens_unificados_sefin" if using_sefin else "itens_unificados",
        "using_aggregated_sources": False,
        "fontes_agr_validation": validation,
    }
