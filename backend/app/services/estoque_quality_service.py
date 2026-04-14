from __future__ import annotations

from backend.app.services.datasets import dataset_ref
from backend.app.services.parquet_api import load_dataset_preview
from pipeline.io.parquet_store import load_parquet


def get_estoque_quality(cnpj: str) -> dict:
    mov_preview = load_dataset_preview(cnpj, "gold", "mov_estoque")
    anual_preview = load_dataset_preview(cnpj, "gold", "aba_anual")
    alertas_preview = load_dataset_preview(cnpj, "gold", "estoque_alertas")

    mov_ref = dataset_ref(cnpj=cnpj, layer="gold", name="mov_estoque")
    mov_df = load_parquet(mov_ref)

    resumo = {
        "total_movimentos": 0 if mov_df is None else mov_df.height,
        "linhas_estoque_inicial": 0,
        "linhas_estoque_final": 0,
        "linhas_com_periodo": 0,
        "divergencia_estoque_declarado_total": 0.0,
        "divergencia_estoque_calculado_total": 0.0,
    }

    if mov_df is not None and not mov_df.is_empty():
        if "tipo_operacao" in mov_df.columns:
            resumo["linhas_estoque_inicial"] = mov_df.filter(mov_df["tipo_operacao"] == "0 - ESTOQUE INICIAL").height
            resumo["linhas_estoque_final"] = mov_df.filter(mov_df["tipo_operacao"] == "3 - ESTOQUE FINAL").height
        if "periodo_inventario" in mov_df.columns:
            resumo["linhas_com_periodo"] = mov_df.filter(mov_df["periodo_inventario"].is_not_null()).height
        if "divergencia_estoque_declarado" in mov_df.columns:
            resumo["divergencia_estoque_declarado_total"] = float(mov_df["divergencia_estoque_declarado"].sum())
        if "divergencia_estoque_calculado" in mov_df.columns:
            resumo["divergencia_estoque_calculado_total"] = float(mov_df["divergencia_estoque_calculado"].sum())

    return {
        "cnpj": cnpj,
        "resumo": resumo,
        "mov_estoque": mov_preview,
        "aba_anual": anual_preview,
        "estoque_alertas": alertas_preview,
    }
