from __future__ import annotations

from backend.app.services.gold_temporal_resolution_service import get_gold_temporal_resolution_summary
from backend.app.services.references_diagnostic_service import get_references_and_parquets_status
from backend.app.services.runtime_surface_catalog_service import get_runtime_surface_catalog

REQUIRED_SILVER_FOR_PREPARE = ["efd_c170", "nfe_itens"]
REQUIRED_SILVER_FOR_GOLD = ["itens_unificados", "base_info_mercadorias"]
REQUIRED_SILVER_FOR_SEFIN = ["itens_unificados_sefin"]
KEY_GOLD_OUTPUTS = ["produtos_final", "fatores_conversao", "mov_estoque", "aba_anual"]


def _count_existing(items: dict[str, dict]) -> int:
    return sum(1 for value in items.values() if value.get("exists"))


def _missing_names(items: dict[str, dict], required_names: list[str] | None = None) -> list[str]:
    names = required_names or list(items.keys())
    return [name for name in names if not items.get(name, {}).get("exists")]


def _recommended_surfaces() -> dict[str, dict]:
    official = get_runtime_surface_catalog()["official"]
    return {
        "silver": {
            "runtime": f"backend.app.{official['silver_runtime']}:app",
            "alias": official["silver_runtime"],
            "api_prefixes": [official["silver_prepare_prefix"]],
            "prepare_sefin_endpoint": official["silver_prepare_sefin_endpoint"],
        },
        "gold": {
            "runtime": official["gold_runtime"],
            "alias": official["gold_current_alias"],
            "api_prefixes": [official["gold_api_prefix"], official["gold_current_prefix"]],
            "status_endpoint": f"{official['gold_current_prefix']}/status/{{cnpj}}",
            "pipeline_status_endpoint": f"{official['gold_current_prefix']}/pipeline/{{cnpj}}/status",
            "run_endpoint": f"{official['gold_current_prefix']}/pipeline/{{cnpj}}/run",
        },
        "fisconforme": {
            "runtime": official["fisconforme_runtime"],
            "alias": official["fisconforme_current_alias"],
            "api_prefixes": [official["fisconforme_api_prefix"], official["fisconforme_current_prefix"]],
            "status_endpoint": "/api/current-v5/status/{cnpj}",
            "pipeline_status_endpoint": "/api/current-v5/pipeline/{cnpj}/status",
        },
    }


def _build_sefin_context(
    *,
    references: dict[str, bool],
    silver: dict[str, dict],
    silver_prepare_ready: bool,
    temporal_resolution_summary: dict | None = None,
) -> dict:
    missing_references = [name for name, exists in references.items() if not exists]
    silver_enriched_ready = silver.get("itens_unificados_sefin", {}).get("exists", False)

    if missing_references:
        status = "missing_references"
    elif silver_enriched_ready:
        status = "ready"
    elif silver_prepare_ready:
        status = "prepare_silver_sefin_required"
    else:
        status = "silver_base_pending"

    return {
        "status": status,
        "references_complete": not missing_references,
        "references_status": references,
        "silver_enriched_ready": silver_enriched_ready,
        "missing_references": missing_references,
        "missing_datasets": _missing_names(silver, REQUIRED_SILVER_FOR_SEFIN),
        "temporal_resolution_summary": temporal_resolution_summary or {"status": "not_available", "partial_coverage": False, "targets_with_partial_coverage": [], "targets": {}},
        "temporal_resolution_partial": bool(temporal_resolution_summary and temporal_resolution_summary.get("partial_coverage")),
    }


def _recommended_action_endpoint(next_action: str, recommended_surfaces: dict[str, dict]) -> str | None:
    if next_action in {"preparar_silver", "preparar_silver_sefin"}:
        return recommended_surfaces["silver"]["prepare_sefin_endpoint"]
    if next_action == "executar_gold":
        return recommended_surfaces["gold"]["run_endpoint"]
    if next_action == "revisar_quality":
        return recommended_surfaces["gold"]["pipeline_status_endpoint"]
    return None


def get_cnpj_status(cnpj: str) -> dict:
    status = get_references_and_parquets_status(cnpj)
    silver = status["silver"]
    gold = status["gold"]
    references = status["references"]

    references_complete = all(references.values())
    silver_prepare_ready = all(silver[name]["exists"] for name in REQUIRED_SILVER_FOR_PREPARE)
    silver_gold_ready = all(silver[name]["exists"] for name in REQUIRED_SILVER_FOR_GOLD)
    gold_ready = all(gold[name]["exists"] for name in KEY_GOLD_OUTPUTS)
    sefin_ready = references_complete and silver.get("itens_unificados_sefin", {}).get("exists", False)
    temporal_resolution_summary = get_gold_temporal_resolution_summary(cnpj) if gold_ready else None
    sefin_context = _build_sefin_context(
        references=references,
        silver=silver,
        silver_prepare_ready=silver_prepare_ready,
        temporal_resolution_summary=temporal_resolution_summary,
    )

    next_action = "validar_referencias"
    if references_complete:
        next_action = "carregar_silver_base"
    if silver_prepare_ready:
        next_action = "preparar_silver"
    if silver_gold_ready and references_complete and not sefin_ready:
        next_action = "preparar_silver_sefin"
    if silver_gold_ready and sefin_ready:
        next_action = "executar_gold"
    if gold_ready:
        next_action = "revisar_quality"

    recommended_surfaces = _recommended_surfaces()
    attention_flags: list[str] = []
    if sefin_context["temporal_resolution_partial"]:
        attention_flags.append("temporal_resolution_partial")

    return {
        "cnpj": cnpj,
        "references_complete": references_complete,
        "references_status": references,
        "silver_prepare_ready": silver_prepare_ready,
        "silver_gold_ready": silver_gold_ready,
        "gold_ready": gold_ready,
        "sefin_ready": sefin_ready,
        "sefin_context": sefin_context,
        "counts": {
            "references_present": sum(1 for exists in references.values() if exists),
            "silver_present": _count_existing(silver),
            "gold_present": _count_existing(gold),
        },
        "missing": {
            "references": [name for name, exists in references.items() if not exists],
            "silver_prepare": _missing_names(silver, REQUIRED_SILVER_FOR_PREPARE),
            "silver_gold": _missing_names(silver, REQUIRED_SILVER_FOR_GOLD),
            "silver_sefin": _missing_names(silver, REQUIRED_SILVER_FOR_SEFIN),
            "gold_outputs": _missing_names(gold, KEY_GOLD_OUTPUTS),
        },
        "next_action": next_action,
        "recommended_action_endpoint": _recommended_action_endpoint(next_action, recommended_surfaces),
        "quality_attention_required": bool(attention_flags),
        "attention_flags": attention_flags,
        "recommended_runtime": f"backend.app.{recommended_surfaces['gold']['alias']}:app",
        "recommended_surfaces": recommended_surfaces,
    }
