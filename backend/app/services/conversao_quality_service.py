from __future__ import annotations

from backend.app.services.datasets import dataset_ref
from backend.app.services.parquet_api import load_dataset_preview
from pipeline.io.parquet_store import load_parquet


def _count_tipo_fator(df, tipo: str) -> int:
    if df is None or df.is_empty() or "tipo_fator" not in df.columns:
        return 0
    return df.filter(df["tipo_fator"] == tipo).height


def get_conversao_quality(cnpj: str) -> dict:
    fatores_preview = load_dataset_preview(cnpj, "gold", "fatores_conversao")
    item_unidades_preview = load_dataset_preview(cnpj, "gold", "item_unidades")
    anomalias_preview = load_dataset_preview(cnpj, "gold", "log_conversao_anomalias")

    fatores_ref = dataset_ref(cnpj=cnpj, layer="gold", name="fatores_conversao")
    anomalias_ref = dataset_ref(cnpj=cnpj, layer="gold", name="log_conversao_anomalias")
    fatores_df = load_parquet(fatores_ref)
    anomalias_df = load_parquet(anomalias_ref)

    resumo = {
        "total_fatores": 0 if fatores_df is None else fatores_df.height,
        "fatores_estruturais": _count_tipo_fator(fatores_df, "estrutural"),
        "fatores_preco": _count_tipo_fator(fatores_df, "preco"),
        "fatores_manuais": _count_tipo_fator(fatores_df, "manual"),
        "anomalias_total": 0 if anomalias_df is None else anomalias_df.height,
        "anomalias_mesma_unidade": 0,
        "anomalias_baixa_confianca": 0,
    }

    if anomalias_df is not None and not anomalias_df.is_empty():
        if "anomalia_mesma_unidade_fator_diferente" in anomalias_df.columns:
            resumo["anomalias_mesma_unidade"] = anomalias_df.filter(
                anomalias_df["anomalia_mesma_unidade_fator_diferente"] == True
            ).height
        if "anomalia_preco_baixa_confianca" in anomalias_df.columns:
            resumo["anomalias_baixa_confianca"] = anomalias_df.filter(
                anomalias_df["anomalia_preco_baixa_confianca"] == True
            ).height

    return {
        "cnpj": cnpj,
        "resumo": resumo,
        "item_unidades": item_unidades_preview,
        "fatores_conversao": fatores_preview,
        "log_conversao_anomalias": anomalias_preview,
    }
