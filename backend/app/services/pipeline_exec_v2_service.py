from __future__ import annotations

from backend.app.services.input_validation import validate_gold_inputs
from backend.app.services.pipeline_service import run_and_persist_gold_pipeline
from backend.app.services.source_datasets import load_gold_inputs
from pipeline.normalization.base_info import build_base_info_mercadorias
from pipeline.normalization.unified_items import build_itens_unificados


def execute_pipeline_from_storage_v2(cnpj: str) -> dict:
    inputs = load_gold_inputs(cnpj)

    if inputs["itens_df"].is_empty():
        rebuilt = build_itens_unificados(
            inputs["c170_df"],
            inputs["nfe_df"],
            inputs["nfce_df"],
            inputs["bloco_h_df"],
        )
        inputs["itens_df"] = rebuilt

    if inputs["base_info_df"].is_empty() and not inputs["itens_df"].is_empty():
        inputs["base_info_df"] = build_base_info_mercadorias(inputs["itens_df"])

    validation = validate_gold_inputs(inputs)
    if not validation["ok"]:
        return {
            "cnpj": cnpj,
            "status": "validation_failed",
            **validation,
        }

    result = run_and_persist_gold_pipeline(cnpj, **inputs)
    result["status"] = "ok"
    result["validation"] = validation
    return result
