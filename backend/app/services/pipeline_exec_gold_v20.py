from __future__ import annotations

from backend.app.services.gold_aggregated_source_loader_v3 import load_gold_inputs_with_conversion_diagnosis
from backend.app.services.gold_consistency_service import get_gold_consistency
from backend.app.services.gold_pipeline_service_v20 import run_and_persist_gold_v20
from backend.app.services.input_validation import validate_gold_inputs
from backend.app.services.references_diagnostic_service import get_references_and_parquets_status
from pipeline.normalization.base_info import build_base_info_mercadorias
from pipeline.normalization.unified_items import build_itens_unificados


def _build_warnings(
    *,
    using_aggregated_sources: bool,
    diagnostico_conversao_rows: int,
    missing_references: list[str],
    manual_map_rows: int,
    consistency_ok: bool | None = None,
) -> list[str]:
    warnings: list[str] = []
    if using_aggregated_sources:
        warnings.append("Execução preferencial usando fontes_agr validadas por schema e camada de agregação materializada.")
    else:
        warnings.append("Execução em fallback para fontes silver/itens_unificados por indisponibilidade ou schema inválido de fontes_agr.")
    if diagnostico_conversao_rows > 0:
        warnings.append("Diagnóstico de conversão de unidades integrado ao cálculo de item_unidades e fatores.")
    if missing_references:
        warnings.append("Execução sem conjunto completo de referências SEFIN em runtime.")
    if manual_map_rows == 0:
        warnings.append("Execução sem mapa manual de agregação carregado.")
    if consistency_ok is False:
        warnings.append("Inconsistência detectada entre mov_estoque e abas fiscais derivadas após a execução.")
    return warnings


def _build_conversion_quality_summary(
    *,
    selected_items_source: str,
    using_aggregated_sources: bool,
    diagnostico_conversao_rows: int,
    overrides_rows: int,
    manual_map_rows: int,
    result_rows: dict[str, int] | None = None,
) -> dict:
    rows = result_rows or {}
    return {
        "selected_items_source": selected_items_source,
        "using_aggregated_sources": using_aggregated_sources,
        "diagnostico_conversao_rows": diagnostico_conversao_rows,
        "manual_overrides_rows": overrides_rows,
        "manual_map_rows": manual_map_rows,
        "fatores_conversao_rows": rows.get("fatores_conversao", 0),
        "log_conversao_anomalias_rows": rows.get("log_conversao_anomalias", 0),
    }


def _build_sefin_context(
    *,
    selected_items_source: str,
    using_aggregated_sources: bool,
    missing_references: list[str],
) -> dict:
    return {
        "references_complete": not missing_references,
        "missing_references": missing_references,
        "selected_items_source": selected_items_source,
        "using_sefin_enriched_items": selected_items_source == "itens_unificados_sefin",
        "using_aggregated_sources": using_aggregated_sources,
    }


def _prepare_gold_v20_context(cnpj: str) -> dict:
    raw_inputs = load_gold_inputs_with_conversion_diagnosis(cnpj)
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
    manual_map_rows = 0 if inputs["mapa_manual_df"].is_empty() else inputs["mapa_manual_df"].height
    overrides_rows = 0 if inputs["overrides_df"].is_empty() else inputs["overrides_df"].height
    diagnostico_conversao_rows = 0 if inputs["diagnostico_conversao_df"].is_empty() else inputs["diagnostico_conversao_df"].height

    return {
        "inputs": inputs,
        "selected_items_source": selected_items_source,
        "using_aggregated_sources": using_aggregated_sources,
        "fontes_agr_validation": fontes_agr_validation,
        "validation": validation,
        "missing_references": missing_references,
        "manual_map_rows": manual_map_rows,
        "overrides_rows": overrides_rows,
        "diagnostico_conversao_rows": diagnostico_conversao_rows,
    }


def get_gold_v20_status(cnpj: str) -> dict:
    context = _prepare_gold_v20_context(cnpj)
    return {
        "cnpj": cnpj,
        "validation": context["validation"],
        "selected_items_source": context["selected_items_source"],
        "using_aggregated_sources": context["using_aggregated_sources"],
        "fontes_agr_validation": context["fontes_agr_validation"],
        "missing_references": context["missing_references"],
        "sefin_context": _build_sefin_context(
            selected_items_source=context["selected_items_source"],
            using_aggregated_sources=context["using_aggregated_sources"],
            missing_references=context["missing_references"],
        ),
        "conversion_quality_summary": _build_conversion_quality_summary(
            selected_items_source=context["selected_items_source"],
            using_aggregated_sources=context["using_aggregated_sources"],
            diagnostico_conversao_rows=context["diagnostico_conversao_rows"],
            overrides_rows=context["overrides_rows"],
            manual_map_rows=context["manual_map_rows"],
        ),
        "warnings": _build_warnings(
            using_aggregated_sources=context["using_aggregated_sources"],
            diagnostico_conversao_rows=context["diagnostico_conversao_rows"],
            missing_references=context["missing_references"],
            manual_map_rows=context["manual_map_rows"],
        ),
    }


def execute_gold_v20(cnpj: str) -> dict:
    context = _prepare_gold_v20_context(cnpj)
    inputs = context["inputs"]

    if not context["validation"]["ok"]:
        return {
            "cnpj": cnpj,
            "status": "validation_failed",
            "selected_items_source": context["selected_items_source"],
            "using_aggregated_sources": context["using_aggregated_sources"],
            "fontes_agr_validation": context["fontes_agr_validation"],
            "missing_references": context["missing_references"],
            "sefin_context": _build_sefin_context(
                selected_items_source=context["selected_items_source"],
                using_aggregated_sources=context["using_aggregated_sources"],
                missing_references=context["missing_references"],
            ),
            "conversion_quality_summary": _build_conversion_quality_summary(
                selected_items_source=context["selected_items_source"],
                using_aggregated_sources=context["using_aggregated_sources"],
                diagnostico_conversao_rows=context["diagnostico_conversao_rows"],
                overrides_rows=context["overrides_rows"],
                manual_map_rows=context["manual_map_rows"],
            ),
            "warnings": _build_warnings(
                using_aggregated_sources=context["using_aggregated_sources"],
                diagnostico_conversao_rows=context["diagnostico_conversao_rows"],
                missing_references=context["missing_references"],
                manual_map_rows=context["manual_map_rows"],
            ),
            **context["validation"],
        }

    result = run_and_persist_gold_v20(cnpj, **inputs)
    consistency = get_gold_consistency(cnpj)
    result["status"] = "ok"
    result["validation"] = context["validation"]
    result["pipeline_version"] = "gold_v20"
    result["selected_items_source"] = context["selected_items_source"]
    result["using_aggregated_sources"] = context["using_aggregated_sources"]
    result["fontes_agr_validation"] = context["fontes_agr_validation"]
    result["gold_consistency"] = consistency
    result["missing_references"] = context["missing_references"]
    result["manual_map_rows"] = context["manual_map_rows"]
    result["diagnostico_conversao_rows"] = context["diagnostico_conversao_rows"]
    result["sefin_context"] = _build_sefin_context(
        selected_items_source=context["selected_items_source"],
        using_aggregated_sources=context["using_aggregated_sources"],
        missing_references=context["missing_references"],
    )
    result["conversion_quality_summary"] = _build_conversion_quality_summary(
        selected_items_source=context["selected_items_source"],
        using_aggregated_sources=context["using_aggregated_sources"],
        diagnostico_conversao_rows=context["diagnostico_conversao_rows"],
        overrides_rows=context["overrides_rows"],
        manual_map_rows=context["manual_map_rows"],
        result_rows=result.get("rows"),
    )
    result["warnings"] = _build_warnings(
        using_aggregated_sources=context["using_aggregated_sources"],
        diagnostico_conversao_rows=context["diagnostico_conversao_rows"],
        missing_references=context["missing_references"],
        manual_map_rows=context["manual_map_rows"],
        consistency_ok=consistency.get("ok", False),
    )
    return result
