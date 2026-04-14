from __future__ import annotations

from backend.app.services.gold_consistency_service import get_gold_consistency
from backend.app.services.pipeline_exec_gold_v18 import execute_gold_v18


def execute_gold_v19(cnpj: str) -> dict:
    result = execute_gold_v18(cnpj)
    if result.get("status") != "ok":
        return result
    consistency = get_gold_consistency(cnpj)
    result["pipeline_version"] = "gold_v19"
    result["gold_consistency"] = consistency
    if not consistency.get("ok", False):
        result.setdefault("warnings", []).append("Inconsistência detectada entre mov_estoque e abas fiscais derivadas após a execução.")
    else:
        result.setdefault("warnings", []).append("Consistência pós-gold validada para estoque e derivados fiscais.")
    return result
