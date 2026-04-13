from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from backend.app.services import paths


@dataclass(frozen=True)
class DatasetRef:
    cnpj: str
    layer: str
    name: str
    path: Path


LAYER_RESOLVERS = {
    "bronze": paths.bronze_dir,
    "silver": paths.silver_dir,
    "gold": paths.gold_dir,
    "fisconforme": paths.fisconforme_dir,
}


def dataset_ref(cnpj: str, layer: str, name: str) -> DatasetRef:
    if layer not in LAYER_RESOLVERS:
        raise ValueError(f"Camada desconhecida: {layer}")
    base_dir = LAYER_RESOLVERS[layer](cnpj)
    return DatasetRef(cnpj=cnpj, layer=layer, name=name, path=base_dir / f"{name}_{cnpj}.parquet")
