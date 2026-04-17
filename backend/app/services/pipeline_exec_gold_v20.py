from __future__ import annotations

from backend.app.services.gold_aggregated_source_loader_v3 import load_gold_inputs_with_conversion_diagnosis
from backend.app.services.gold_consistency_service import get_gold_consistency
from backend.app.services.gold_pipeline_service_v20 import run_and_persist_gold_v20
from backend.app.services.gold_temporal_resolution_service import get_gold_temporal_resolution_summary
from backend.app.services.input_validation import validate_gold_inputs
from backend.app.services.references_diagnostic_service import get_references_and_parquets_status
from pipeline.normalization.base_info import build_base_info_mercadorias
from pipeline.normalization.unified_items import build_itens_unificados

TEMPORAL_RESOLUTION_TARGETS = ("aba_mensal", "aba_anual", "aba_periodos")


def _default_temporal_resolution_summary(status: str = "not_available") -> dict:
    return {
        "status": status,
        "vigencia_runtime": {
            "status": "not_available",
            "rows": 0,
            "missing_columns": [],
            "usable_for_temporal_resolution": False,
        },
        "partial_coverage": False,
        "targets_with_partial_coverage": [],
        "targets": {},
    }


def _has_temporal_resolution_outputs(gold_status: dict[str, dict]) -> bool:
    return all(gold_status.get(name, {}).get("exists", False) for name in TEMPORAL_RESOLUTION_TARGETS)


def _resolve_temporal_resolution_summary(cnpj: str, gold_status: dict[str, dict]) -> dict:
    if not _has_temporal_resolution_outputs(gold_status):
        return _default_temporal_resolution_summary()
    return get_gold_temporal_resolution_summary(cnpj)


def _build_attention_flags(temporal_resolution_summary: dict | None) -> list[str]:
    if temporal_resolution_summary and temporal_resolution_summary.get("partial_coverage"):
        return ["temporal_resolution_partial"]
    return []


def _attach_temporal_resolution_fields(payload: dict, temporal_resolution_summary: dict | None) -> dict:
    summary = temporal_resolution_summary or _default_temporal_resolution_summary()
    attention_flags = _build_attention_flags(summary)
    payload["temporal_resolution_summary"] = summary
    payload["quality_attention_required"] = bool(attention_flags)
    payload["attention_flags"] = attention_flags
    return payload


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
    references_status: dict[str, bool],
    missing_references: list[str],
    temporal_resolution_summary: dict | None = None,
) -> dict:
    if using_aggregated_sources:
        status = "aggregated_sources"
    elif selected_items_source == "itens_unificados_sefin":
        status = "sefin_enriched_items"
    elif missing_references:
        status = "fallback_missing_references"
    else:
        status = "fallback_without_sefin"

    return {
        "status": status,
        "references_complete": not missing_references,
        "references_status": references_status,
        "missing_references": missing_references,
        "selected_items_source": selected_items_source,
        "using_sefin_enriched_items": selected_items_source == "itens_unificados_sefin",
        "using_aggregated_sources": using_aggregated_sources,
        "temporal_resolution_summary": temporal_resolution_summary or _default_temporal_resolution_summary(),
        "temporal_resolution_partial": bool(
            temporal_resolution_summary and temporal_resolution_summary.get("partial_coverage")
        ),
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
    layer_status = get_references_and_parquets_status(cnpj)
    reference_flags = layer_status["references"]
    gold_status = layer_status.get("gold", {})
    missing_references = [name for name, exists in reference_flags.items() if not exists]
    manual_map_rows = 0 if inputs["mapa_manual_df"].is_empty() else inputs["mapa_manual_df"].height
    overrides_rows = 0 if inputs["overrides_df"].is_empty() else inputs["overrides_df"].height
    diagnostico_conversao_rows = 0 if inputs["diagnostico_conversao_df"].is_empty() else inputs["diagnostico_conversao_df"].height
    temporal_resolution_summary = _resolve_temporal_resolution_summary(cnpj, gold_status)

    return {
        "inputs": inputs,
        "selected_items_source": selected_items_source,
        "using_aggregated_sources": using_aggregated_sources,
        "fontes_agr_validation": fontes_agr_validation,
        "validation": validation,
        "references_status": reference_flags,
        "gold_status": gold_status,
        "missing_references": missing_references,
        "manual_map_rows": manual_map_rows,
        "overrides_rows": overrides_rows,
        "diagnostico_conversao_rows": diagnostico_conversao_rows,
        "temporal_resolution_summary": temporal_resolution_summary,
    }


def get_gold_v20_status(cnpj: str) -> dict:
    context = _prepare_gold_v20_context(cnpj)
    return _attach_temporal_resolution_fields({
        "cnpj": cnpj,
        "validation": context["validation"],
        "selected_items_source": context["selected_items_source"],
        "using_aggregated_sources": context["using_aggregated_sources"],
        "fontes_agr_validation": context["fontes_agr_validation"],
        "references_status": context["references_status"],
        "missing_references": context["missing_references"],
        "sefin_context": _build_sefin_context(
            selected_items_source=context["selected_items_source"],
            using_aggregated_sources=context["using_aggregated_sources"],
            references_status=context["references_status"],
            missing_references=context["missing_references"],
            temporal_resolution_summary=context["temporal_resolution_summary"],
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
    }, context["temporal_resolution_summary"])


def execute_gold_v20(cnpj: str) -> dict:
    context = _prepare_gold_v20_context(cnpj)
    inputs = context["inputs"]

    if not context["validation"]["ok"]:
        return _attach_temporal_resolution_fields({
            "cnpj": cnpj,
            "status": "validation_failed",
            "selected_items_source": context["selected_items_source"],
            "using_aggregated_sources": context["using_aggregated_sources"],
            "fontes_agr_validation": context["fontes_agr_validation"],
            "references_status": context["references_status"],
            "missing_references": context["missing_references"],
            "sefin_context": _build_sefin_context(
                selected_items_source=context["selected_items_source"],
                using_aggregated_sources=context["using_aggregated_sources"],
                references_status=context["references_status"],
                missing_references=context["missing_references"],
                temporal_resolution_summary=context["temporal_resolution_summary"],
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
        }, context["temporal_resolution_summary"])

    result = run_and_persist_gold_v20(cnpj, **inputs)
    consistency = get_gold_consistency(cnpj)
    temporal_resolution_summary = get_gold_temporal_resolution_summary(cnpj)
    result["status"] = "ok"
    result["validation"] = context["validation"]
    result["pipeline_version"] = "gold_v20"
    result["selected_items_source"] = context["selected_items_source"]
    result["using_aggregated_sources"] = context["using_aggregated_sources"]
    result["fontes_agr_validation"] = context["fontes_agr_validation"]
    result["gold_consistency"] = consistency
    result["references_status"] = context["references_status"]
    result["missing_references"] = context["missing_references"]
    result["manual_map_rows"] = context["manual_map_rows"]
    result["diagnostico_conversao_rows"] = context["diagnostico_conversao_rows"]
    result["sefin_context"] = _build_sefin_context(
        selected_items_source=context["selected_items_source"],
        using_aggregated_sources=context["using_aggregated_sources"],
        references_status=context["references_status"],
        missing_references=context["missing_references"],
        temporal_resolution_summary=temporal_resolution_summary,
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
    return _attach_temporal_resolution_fields(result, temporal_resolution_summary)
