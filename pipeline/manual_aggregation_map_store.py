from __future__ import annotations

import polars as pl

from backend.app.services.datasets import dataset_ref
from pipeline.io.parquet_store import save_parquet


def save_manual_aggregation_map(cnpj: str, mapa_manual_df: pl.DataFrame) -> str:
    ref = dataset_ref(cnpj=cnpj, layer="gold", name="mapa_manual_agregacao")
    save_parquet(mapa_manual_df, ref)
    return str(ref.path)
