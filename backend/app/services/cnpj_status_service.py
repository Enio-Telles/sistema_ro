from __future__ import annotations

from backend.app.services.references_diagnostic_service import get_references_and_parquets_status
from backend.app.services.runtime_surface_catalog_service import get_runtime_surface_catalog

REQUIRED_SILVER_FOR_PREPARE = ["efd_c170", "nfe_itens"]
REQUIRED_SILVER_FOR_GOLD = ["itens_unificados", "base_info_mercadorias"]
KEY_GOLD_OUTPUTS = ["produtos_final", "fatores_conversao", "mov_estoque", "aba_anual"]


def _count_existing(items: dict[str, dict]) -> int:
    return sum(1 for value in items.values() if value.get("exists"))


def _missing_names(items: dict[str, dict], required_names: list[str] | None = None) -> list[str]:
    names = required_names or list(items.keys())
    return [name for name in names if not items.get(name, {}).get("exists")]


def _recommended_surfaces() -> dict[str, dict]:
    official = get_runtime_surface_catalog()["official"]
    return {
        "gold": {
            "runtime": official["gold_runtime"],
            "alias": official["gold_current_alias"],
            "api_prefixes": [official["gold_api_prefix"], official["gold_current_prefix"]],
            "status_endpoint": f"{official['gold_current_prefix']}/status/{{cnpj}}",
        },
        "fisconforme": {
            "runtime": official["fisconforme_runtime"],
            "alias": official["fisconforme_current_alias"],
            "api_prefixes": [official["fisconforme_api_prefix"], official["fisconforme_current_prefix"]],
            "status_endpoint": "/api/current-v5/status/{cnpj}",
        },
    }


def get_cnpj_status(cnpj: str) -> dict:
    status = get_references_and_parquets_status(cnpj)
    silver = status["silver"]
    gold = status["gold"]
    references = status["references"]

    silver_prepare_ready = all(silver[name]["exists"] for name in REQUIRED_SILVER_FOR_PREPARE)
    silver_gold_ready = all(silver[name]["exists"] for name in REQUIRED_SILVER_FOR_GOLD)
    gold_ready = all(gold[name]["exists"] for name in KEY_GOLD_OUTPUTS)
    sefin_ready = all(references.values()) and silver.get("itens_unificados_sefin", {}).get("exists", False)

    next_action = "validar_referencias"
    if all(references.values()):
        next_action = "carregar_silver_base"
    if silver_prepare_ready:
        next_action = "preparar_silver"
    if silver_gold_ready:
        next_action = "executar_gold"
    if gold_ready:
        next_action = "revisar_quality"

    recommended_surfaces = _recommended_surfaces()

    return {
        "cnpj": cnpj,
        "references_complete": all(references.values()),
        "silver_prepare_ready": silver_prepare_ready,
        "silver_gold_ready": silver_gold_ready,
        "gold_ready": gold_ready,
        "sefin_ready": sefin_ready,
        "counts": {
            "references_present": sum(1 for exists in references.values() if exists),
            "silver_present": _count_existing(silver),
            "gold_present": _count_existing(gold),
        },
        "missing": {
            "references": [name for name, exists in references.items() if not exists],
            "silver_prepare": _missing_names(silver, REQUIRED_SILVER_FOR_PREPARE),
            "silver_gold": _missing_names(silver, REQUIRED_SILVER_FOR_GOLD),
            "gold_outputs": _missing_names(gold, KEY_GOLD_OUTPUTS),
        },
        "next_action": next_action,
        "recommended_runtime": f"backend.app.{recommended_surfaces['gold']['alias']}:app",
        "recommended_surfaces": recommended_surfaces,
    }
