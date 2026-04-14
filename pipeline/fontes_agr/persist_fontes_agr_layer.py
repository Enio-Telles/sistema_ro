from __future__ import annotations

import polars as pl

from backend.app.services.layer_datasets import operational_dataset_ref
from pipeline.io.parquet_store import save_parquet


FONTES_AGR_DATASETS = [
    "c170_agr",
    "c170_agr_sem_id_agrupado",
    "nfe_agr",
    "nfe_agr_sem_id_agrupado",
    "nfce_agr",
    "nfce_agr_sem_id_agrupado",
    "bloco_h_agr",
    "bloco_h_agr_sem_id_agrupado",
]


def persist_fontes_agr_outputs(cnpj: str, outputs: dict[str, pl.DataFrame]) -> dict[str, str]:
    saved: dict[str, str] = {}
    for name in FONTES_AGR_DATASETS:
        if name in outputs:
            ref = operational_dataset_ref(cnpj, "fontes_agr", name)
            save_parquet(outputs[name], ref)
            saved[name] = str(ref.path)
    return saved
