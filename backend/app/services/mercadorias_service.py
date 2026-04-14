from __future__ import annotations

from backend.app.services.parquet_api import load_dataset_preview


def get_mercadorias_overview(cnpj: str) -> dict:
    return {
        "cnpj": cnpj,
        "produtos_agrupados": load_dataset_preview(cnpj, "gold", "produtos_agrupados"),
        "id_agrupados": load_dataset_preview(cnpj, "gold", "id_agrupados"),
        "produtos_final": load_dataset_preview(cnpj, "gold", "produtos_final"),
    }
