from __future__ import annotations

from backend.app.services.gold_pipeline_service_v8 import run_and_persist_gold_v8
from backend.app.services.input_validation import validate_gold_inputs
from backend.app.services.manual_map_source_loader import load_gold_inputs_with_manual_map
from backend.app.services.references_diagnostic_service import get_references_and_parquets_status
from pipeline.normalization.base_info import build_base_info_mercadorias
from pipeline.normalization.unified_items import build_itens_unificados


def execute_gold_v9(cnpj: str) -> dict:
    raw_inputs = load_gold_inputs_with_manual_map(cnpj)
    selected_items_source = str(raw_inputs.pop("selected_items_source"))
    using_sefin_items = bool(raw_inputs.pop("using_sefin_items"))
    inputs = raw_inputs

    if inputs["itens_df"].is_empty():
        inputs["itens_df"] = build_itens_unificados(
            inputs["c170_df"],
            inputs["nfe_df"],
            inputs["nfce_df"],
            inputs["bloco_h_df"],
        )
        selected_items_source = "itens_unificados_rebuilt"
        using_sefin_items = False

    if inputs["base_info_df"].is_empty() and not inputs["itens_df"].is_empty():
        inputs["base_info_df"] = build_base_info_mercadorias(inputs["itens_df"])

    validation = validate_gold_inputs({k: v for k, v in inputs.items() if k != "mapa_manual_df"})
    references_status = get_references_and_parquets_status(cnpj)
    missing_references = [name for name, exists in references_status["references"].items() if not exists]

    if not validation["ok"]:
        return {
            "cnpj": cnpj,
            "status": "validation_failed",
            "selected_items_source": selected_items_source,
            "using_sefin_items": using_sefin_items,
            "missing_references": missing_references,
            **validation,
        }

    result = run_and_persist_gold_v8(cnpj, **inputs)
    result["status"] = "ok"
    result["validation"] = validation
    result["pipeline_version"] = "gold_v8_manual_map"
    result["selected_items_source"] = selected_items_source
    result["using_sefin_items"] = using_sefin_items
    result["missing_references"] = missing_references
    result["manual_map_rows"] = 0 if inputs["mapa_manual_df"].is_empty() else inputs["mapa_manual_df"].height
    result["warnings"] = []
    if missing_references:
        result["warnings"].append("Execução sem conjunto completo de referências SEFIN em runtime.")
    if not using_sefin_items:
        result["warnings"].append("Execução usando itens_unificados sem enriquecimento SEFIN preferencial.")
    if inputs["mapa_manual_df"].is_empty():
        result["warnings"].append("Execução sem mapa manual de agregação carregado.")
    return result
