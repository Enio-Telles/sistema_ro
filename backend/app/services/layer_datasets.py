from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from backend.app.services.layer_paths import operational_layer_dir


@dataclass(frozen=True)
class OperationalDatasetRef:
    cnpj: str
    layer: str
    name: str
    path: Path


def operational_dataset_ref(cnpj: str, layer: str, name: str) -> OperationalDatasetRef:
    base_dir = operational_layer_dir(cnpj, layer)
    return OperationalDatasetRef(cnpj=cnpj, layer=layer, name=name, path=base_dir / f"{name}_{cnpj}.parquet")
