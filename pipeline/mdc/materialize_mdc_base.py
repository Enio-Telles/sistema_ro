from __future__ import annotations

import polars as pl

from backend.app.services.layer_datasets import operational_dataset_ref
from pipeline.io.parquet_store import save_parquet
from pipeline.mdc.mdc_contracts import MDC_BASE_CONTRACTS


def persist_mdc_base_dataset(cnpj: str, dataset_name: str, df: pl.DataFrame) -> str:
    if dataset_name not in MDC_BASE_CONTRACTS:
        raise ValueError(f"Dataset MDC não suportado: {dataset_name}")
    ref = operational_dataset_ref(cnpj, "mdc_base", dataset_name)
    save_parquet(df, ref)
    return str(ref.path)


def persist_priority_mdc_base(cnpj: str, datasets: dict[str, pl.DataFrame]) -> dict[str, str]:
    saved: dict[str, str] = {}
    for name, df in datasets.items():
        if name in MDC_BASE_CONTRACTS:
            saved[name] = persist_mdc_base_dataset(cnpj, name, df)
    return saved
