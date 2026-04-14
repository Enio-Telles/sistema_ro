from __future__ import annotations

from typing import Any

from backend.app.services.datasets import dataset_ref
from pipeline.io.parquet_store import load_parquet


def load_dataset_preview(cnpj: str, layer: str, name: str, limit: int = 20) -> dict[str, Any]:
    ref = dataset_ref(cnpj=cnpj, layer=layer, name=name)
    df = load_parquet(ref)
    if df is None:
        return {
            "cnpj": cnpj,
            "layer": layer,
            "name": name,
            "exists": False,
            "rows": 0,
            "items": [],
        }
    preview = df.head(limit).to_dicts()
    return {
        "cnpj": cnpj,
        "layer": layer,
        "name": name,
        "exists": True,
        "rows": df.height,
        "items": preview,
    }
