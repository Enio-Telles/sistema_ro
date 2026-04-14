from __future__ import annotations

import polars as pl

from backend.app.services.layer_datasets import operational_dataset_ref
from pipeline.io.parquet_store import save_parquet


AGREGACAO_DATASETS = [
    "mapa_manual_agregacao",
    "map_produto_agrupado",
    "produtos_agrupados",
    "id_agrupados",
    "produtos_final",
]


def persist_agregacao_outputs(cnpj: str, outputs: dict[str, pl.DataFrame], mapa_manual_df: pl.DataFrame | None = None) -> dict[str, str]:
    saved: dict[str, str] = {}
    for name in ["map_produto_agrupado", "produtos_agrupados", "id_agrupados", "produtos_final"]:
        if name in outputs:
            ref = operational_dataset_ref(cnpj, "agregacao", name)
            save_parquet(outputs[name], ref)
            saved[name] = str(ref.path)
    if mapa_manual_df is not None and not mapa_manual_df.is_empty():
        ref = operational_dataset_ref(cnpj, "agregacao", "mapa_manual_agregacao")
        save_parquet(mapa_manual_df, ref)
        saved["mapa_manual_agregacao"] = str(ref.path)
    return saved
