from __future__ import annotations

from pathlib import Path

import polars as pl

from backend.app.services.paths import fisconforme_dir


def fisconforme_cache_path(cnpj: str, dataset_name: str) -> Path:
    return fisconforme_dir(cnpj) / f"{dataset_name}_{cnpj}.parquet"


def save_cache(df: pl.DataFrame, cnpj: str, dataset_name: str) -> Path:
    path = fisconforme_cache_path(cnpj, dataset_name)
    df.write_parquet(path)
    return path


def load_cache(cnpj: str, dataset_name: str) -> pl.DataFrame | None:
    path = fisconforme_cache_path(cnpj, dataset_name)
    if not path.exists():
        return None
    return pl.read_parquet(path)
