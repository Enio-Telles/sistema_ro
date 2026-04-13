from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import polars as pl

REQUIRED_REFERENCE_FILES = {
    "sitafe_cest": "sitafe_cest.parquet",
    "sitafe_cest_ncm": "sitafe_cest_ncm.parquet",
    "sitafe_ncm": "sitafe_ncm.parquet",
    "sitafe_produto_sefin": "sitafe_produto_sefin.parquet",
    "sitafe_produto_sefin_aux": "sitafe_produto_sefin_aux.parquet",
}


@dataclass(frozen=True)
class ReferenceDataset:
    name: str
    path: Path

    def read(self) -> pl.DataFrame:
        return pl.read_parquet(self.path)


def resolve_reference_dataset(reference_root: Path, name: str) -> ReferenceDataset:
    filename = REQUIRED_REFERENCE_FILES.get(name)
    if filename is None:
        raise ValueError(f"Referência desconhecida: {name}")
    path = reference_root / filename
    if not path.exists():
        raise FileNotFoundError(f"Arquivo de referência ausente: {path}")
    return ReferenceDataset(name=name, path=path)


def validate_reference_root(reference_root: Path) -> dict[str, bool]:
    return {name: (reference_root / filename).exists() for name, filename in REQUIRED_REFERENCE_FILES.items()}
