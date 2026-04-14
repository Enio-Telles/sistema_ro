from __future__ import annotations

from backend.app.services.references_diagnostic_service import get_references_and_parquets_status

REQUIRED_SILVER_FOR_PREPARE = ["efd_c170", "nfe_itens"]
REQUIRED_SILVER_FOR_GOLD = ["itens_unificados", "base_info_mercadorias"]
KEY_GOLD_OUTPUTS = ["produtos_final", "fatores_conversao", "mov_estoque", "aba_anual"]


def _count_existing(items: dict[str, dict]) -> int:
    return sum(1 for value in items.values() if value.get("exists"))


def get_cnpj_status(cnpj: str) -> dict:
    status = get_references_and_parquets_status(cnpj)
    silver = status["silver"]
    gold = status["gold"]
    references = status["references"]

    silver_prepare_ready = all(silver[name]["exists"] for name in REQUIRED_SILVER_FOR_PREPARE)
    silver_gold_ready = all(silver[name]["exists"] for name in REQUIRED_SILVER_FOR_GOLD)
    gold_ready = all(gold[name]["exists"] for name in KEY_GOLD_OUTPUTS)
    sefin_ready = all(references.values()) and silver.get("itens_unificados_sefin", {}).get("exists", False)

    next_action = "carregar_silver_base"
    if silver_prepare_ready:
        next_action = "preparar_silver"
    if silver_gold_ready:
        next_action = "executar_gold"
    if gold_ready:
        next_action = "revisar_quality"

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
        "next_action": next_action,
        "recommended_runtime": "backend.app.runtime_main:app",
    }
