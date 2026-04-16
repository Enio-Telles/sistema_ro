from __future__ import annotations


def get_decommission_plan() -> dict:
    return {
        "official_keep": {
            "gold": [
                "runtime_gold_v20",
                "runtime_gold_current_v2",
            ],
            "fisconforme": [
                "runtime_gold_v25",
                "runtime_gold_current_v5",
            ],
        },
        "keep_temporarily": {
            "transition_runtimes": [],
        },
        "deprecate_now": {
            "legacy_runtimes": [
                "pipeline_exec_v5_service",
                "pipeline_exec_gold_v6_to_v17",
            ],
            "legacy_routes": [
                {
                    "route": "/api/current-v5/fisconforme",
                    "replacement": "/api/current-v5/fisconforme-v2",
                },
                {
                    "route": "/api/gold25/fisconforme",
                    "replacement": "/api/gold25/fisconforme-v2",
                },
            ],
        },
        "next_removals_priority": [],
        "rules": [
            "nao remover uma runtime sem confirmar rota substituta operacional",
            "nao abrir novas features em superfícies marcadas como legacy",
            "preferir consolidar aliases oficiais antes de manter aliases auxiliares legados",
        ],
        "phases": [
            "1. Higienização de runtimes v6-v24 e aliases legados",
            "2. Consolidação das superfícies oficiais em gold_v20/current-v2 e gold_v25/current-v5",
            "3. Validação ponta a ponta do fluxo oficial",
        ],
    }
