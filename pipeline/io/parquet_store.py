from __future__ import annotations

from pathlib import Path

import polars as pl

from backend.app.services.datasets import DatasetRef


import json

def save_parquet(df: pl.DataFrame, dataset: DatasetRef, metadata: dict | None = None) -> Path:
    dataset.path.parent.mkdir(parents=True, exist_ok=True)
    df.write_parquet(dataset.path)
    
    if metadata:
        meta_path = dataset.path.with_suffix(".meta.json")
        meta_path.write_text(json.dumps(metadata, indent=2, ensure_ascii=False), encoding="utf-8")
        
    return dataset.path


def load_parquet(dataset: DatasetRef) -> pl.DataFrame | None:
    if not dataset.path.exists():
        return None
    return pl.read_parquet(dataset.path)


def parquet_exists(dataset: DatasetRef) -> bool:
    return dataset.path.exists()
