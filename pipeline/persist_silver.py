from __future__ import annotations

import polars as pl

from backend.app.services.datasets import dataset_ref
from pipeline.io.parquet_store import save_parquet


SILVER_DATASET_NAMES = {
    "itens_unificados": "silver",
    "base_info_mercadorias": "silver",
}


def persist_silver_outputs(cnpj: str, outputs: dict[str, pl.DataFrame]) -> dict[str, str]:
    saved: dict[str, str] = {}
    for name, df in outputs.items():
        if name not in SILVER_DATASET_NAMES:
            continue
        ref = dataset_ref(cnpj=cnpj, layer=SILVER_DATASET_NAMES[name], name=name)
        save_parquet(df, ref)
        saved[name] = str(ref.path)
    return saved
