from __future__ import annotations

import polars as pl

from backend.app.services.datasets import dataset_ref
from backend.app.services.layer_datasets import operational_dataset_ref
from pipeline.io.parquet_store import load_parquet
from pipeline.mercadorias.build_agregacao_from_mdc_v2 import build_agregacao_from_mdc_base_v2
from pipeline.mercadorias.persist_agregacao_layer import persist_agregacao_outputs


def _load_operational(cnpj: str, layer: str, name: str) -> pl.DataFrame:
    ref = operational_dataset_ref(cnpj, layer, name)
    df = load_parquet(ref)
    return df if df is not None else pl.DataFrame()


def _load_manual_map(cnpj: str) -> pl.DataFrame:
    aggr_ref = operational_dataset_ref(cnpj, "agregacao", "mapa_manual_agregacao")
    aggr_df = load_parquet(aggr_ref)
    if aggr_df is not None and not aggr_df.is_empty():
        return aggr_df
    gold_ref = dataset_ref(cnpj=cnpj, layer="gold", name="mapa_manual_agregacao")
    gold_df = load_parquet(gold_ref)
    return gold_df if gold_df is not None else pl.DataFrame()


def materialize_agregacao_from_mdc_base(cnpj: str) -> dict:
    efd_produtos_base_df = _load_operational(cnpj, "mdc_base", "efd_produtos_base")
    efd_itens_base_df = _load_operational(cnpj, "mdc_base", "efd_itens_base")
    efd_inventario_base_df = _load_operational(cnpj, "mdc_base", "efd_inventario_base")
    mapa_manual_df = _load_manual_map(cnpj)

    outputs = build_agregacao_from_mdc_base_v2(
        efd_itens_base_df=efd_itens_base_df,
        efd_inventario_base_df=efd_inventario_base_df,
        efd_produtos_base_df=efd_produtos_base_df,
        mapa_manual_df=mapa_manual_df,
    )
    saved = persist_agregacao_outputs(cnpj, outputs, mapa_manual_df=mapa_manual_df)

    return {
        "cnpj": cnpj,
        "saved": saved,
        "datasets": list(saved.keys()),
        "rows": {name: df.height for name, df in outputs.items() if name != "itens_agregacao"},
        "source_rows": 0 if outputs["itens_agregacao"].is_empty() else outputs["itens_agregacao"].height,
        "manual_map_rows": 0 if mapa_manual_df.is_empty() else mapa_manual_df.height,
    }
