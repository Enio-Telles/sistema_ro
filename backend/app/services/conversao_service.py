from __future__ import annotations

from backend.app.services.parquet_api import load_dataset_preview


def get_conversao_overview(cnpj: str) -> dict:
    return {
        "cnpj": cnpj,
        "fatores_conversao": load_dataset_preview(cnpj, "gold", "fatores_conversao"),
        "item_unidades": load_dataset_preview(cnpj, "gold", "item_unidades"),
    }
