from __future__ import annotations

from backend.app.services.conversao_quality_summary import summarize_conversion_quality
from backend.app.services.datasets import dataset_ref
from backend.app.services.parquet_api import load_dataset_preview
from pipeline.io.parquet_store import load_parquet


def get_conversao_quality(cnpj: str) -> dict:
    fatores_preview = load_dataset_preview(cnpj, "gold", "fatores_conversao")
    item_unidades_preview = load_dataset_preview(cnpj, "gold", "item_unidades")
    anomalias_preview = load_dataset_preview(cnpj, "gold", "log_conversao_anomalias")

    fatores_ref = dataset_ref(cnpj=cnpj, layer="gold", name="fatores_conversao")
    anomalias_ref = dataset_ref(cnpj=cnpj, layer="gold", name="log_conversao_anomalias")
    item_unidades_ref = dataset_ref(cnpj=cnpj, layer="gold", name="item_unidades")

    fatores_df = load_parquet(fatores_ref)
    anomalias_df = load_parquet(anomalias_ref)
    item_unidades_df = load_parquet(item_unidades_ref)

    resumo = summarize_conversion_quality(
        item_unidades_df=item_unidades_df,
        fatores_df=fatores_df,
        anomalias_df=anomalias_df,
    )

    return {
        "cnpj": cnpj,
        "resumo": resumo,
        "item_unidades": item_unidades_preview,
        "fatores_conversao": fatores_preview,
        "log_conversao_anomalias": anomalias_preview,
    }
