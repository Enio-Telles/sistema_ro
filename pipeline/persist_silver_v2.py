from __future__ import annotations

import polars as pl

from backend.app.services.datasets import dataset_ref
from pipeline.io.parquet_store import save_parquet


SILVER_DATASET_NAMES_V2 = {
    "itens_unificados": "silver",
    "base_info_mercadorias": "silver",
    "itens_unificados_sefin": "silver",
}


def persist_silver_outputs_v2(cnpj: str, outputs: dict[str, pl.DataFrame]) -> dict[str, str]:
    saved: dict[str, str] = {}
    for name, df in outputs.items():
        if name not in SILVER_DATASET_NAMES_V2:
            continue
        ref = dataset_ref(cnpj=cnpj, layer=SILVER_DATASET_NAMES_V2[name], name=name)

        meta = {
            "dataset_id": f"{name}_{SILVER_DATASET_NAMES_V2[name]}",
            "layer": SILVER_DATASET_NAMES_V2[name],
            "schema_version": "v1.0",
            "row_count": df.height,
            "cnpj": cnpj,
            "upstream_datasets": []
        }

        save_parquet(df, ref, metadata=meta)
        saved[name] = str(ref.path)
    return saved
