from __future__ import annotations

import polars as pl

from backend.app.services.datasets import dataset_ref
from pipeline.io.parquet_store import load_parquet


def _load(cnpj: str, layer: str, name: str) -> pl.DataFrame:
    ref = dataset_ref(cnpj=cnpj, layer=layer, name=name)
    df = load_parquet(ref)
    return df if df is not None else pl.DataFrame()


def load_gold_inputs(cnpj: str) -> dict[str, pl.DataFrame]:
    return {
        "itens_df": _load(cnpj, "silver", "itens_unificados"),
        "c170_df": _load(cnpj, "silver", "efd_c170"),
        "nfe_df": _load(cnpj, "silver", "nfe_itens"),
        "nfce_df": _load(cnpj, "silver", "nfce_itens"),
        "bloco_h_df": _load(cnpj, "silver", "bloco_h"),
        "overrides_df": _load(cnpj, "gold", "overrides_conversao"),
        "base_info_df": _load(cnpj, "silver", "base_info_mercadorias"),
    }
