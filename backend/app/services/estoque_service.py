from __future__ import annotations

from backend.app.services.parquet_api import load_dataset_preview


def get_estoque_overview(cnpj: str) -> dict:
    return {
        "cnpj": cnpj,
        "mov_estoque": load_dataset_preview(cnpj, "gold", "mov_estoque"),
        "aba_mensal": load_dataset_preview(cnpj, "gold", "aba_mensal"),
        "aba_anual": load_dataset_preview(cnpj, "gold", "aba_anual"),
        "aba_periodos": load_dataset_preview(cnpj, "gold", "aba_periodos"),
        "estoque_resumo": load_dataset_preview(cnpj, "gold", "estoque_resumo"),
        "estoque_alertas": load_dataset_preview(cnpj, "gold", "estoque_alertas"),
    }
