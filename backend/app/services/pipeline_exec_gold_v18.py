from __future__ import annotations

from backend.app.services.gold_aggregated_source_loader_v2 import load_gold_inputs_preferring_validated_aggregated_sources
from backend.app.services.gold_pipeline_service_v17 import run_and_persist_gold_v17
from backend.app.services.input_validation import validate_gold_inputs
from backend.app.services.references_diagnostic_service import get_references_and_parquets_status
from pipeline.normalization.base_info import build_base_info_mercadorias
from pipeline.normalization.unified_items import build_itens_unificados


def execute_gold_v18(cnpj: str) -> dict:
    raw_inputs = load_gold_inputs_preferring_validated_aggregated_sources(cnpj)
    selected_items_source = str(raw_inputs.pop("selected_items_source"))
    using_aggregated_sources = bool(raw_inputs.pop("using_aggregated_sources"))
    fontes_agr_validation = raw_inputs.pop("fontes_agr_validation")
    inputs = raw_inputs

    if inputs["itens_df"].is_empty() and not using_aggregated_sources:
        inputs["itens_df"] = build_itens_unificados(
            inputs["c170_df"],
            inputs["nfe_df"],
            inputs["nfce_df"],
            inputs["bloco_h_df"],
        )
        selected_items_source = "itens_unificados_rebuilt"

    if inputs["base_info_df"].is_empty() and not inputs["itens_df"].is_empty():
        inputs["base_info_df"] = build_base_info_mercadorias(inputs["itens_df"])

    validation = validate_gold_inputs({
        k: v for k, v in inputs.items() if k in {"itens_df", "c170_df", "nfe_df", "nfce_df", "bloco_h_df", "overrides_df", "base_info_df"}
    })
    references_status = get_references_and_parquets_status(cnpj)
    missing_references = [name for name, exists in references_status["references"].items() if not exists]

    if not validation["ok"]:
        return {
            "cnpj": cnpj,
            "status": "validation_failed",
            "selected_items_source": selected_items_source,
            "using_aggregated_sources": using_aggregated_sources,
            "fontes_agr_validation": fontes_agr_validation,
            "missing_references": missing_references,
            **validation,
        }

    result = run_and_persist_gold_v17(cnpj, **inputs)
    result["status"] = "ok"
    result["validation"] = validation
    result["pipeline_version"] = "gold_v18"
    result["selected_items_source"] = selected_items_source
    result["using_aggregated_sources"] = using_aggregated_sources
    result["fontes_agr_validation"] = fontes_agr_validation
    result["missing_references"] = missing_references
    result["manual_map_rows"] = 0 if inputs["mapa_manual_df"].is_empty() else inputs["mapa_manual_df"].height
    result["warnings"] = []
    if using_aggregated_sources:
        result["warnings"].append("Execução preferencial usando fontes_agr validadas por schema e camada de agregação materializada.")
    else:
        result["warnings"].append("Execução em fallback para fontes silver/itens_unificados por indisponibilidade ou schema inválido de fontes_agr.")
    if missing_references:
        result["warnings"].append("Execução sem conjunto completo de referências SEFIN em runtime.")
    if inputs["mapa_manual_df"].is_empty():
        result["warnings"].append("Execução sem mapa manual de agregação carregado.")
    return result
