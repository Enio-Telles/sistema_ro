from __future__ import annotations


def get_operational_surface_index() -> dict:
    return {
        "in_use_now": {
            "silver": {
                "official_runtime": "runtime_silver_v2",
                "preferred_prefixes": ["/api/v5b/silver"],
                "prepare_sefin_endpoint": "/api/v5b/silver/{cnpj}/prepare-sefin",
            },
            "gold": {
                "official_runtime": "runtime_gold_v20",
                "official_alias": "runtime_gold_current_v2",
                "preferred_prefixes": ["/api/gold20", "/api/current-v2"],
            },
            "fisconforme": {
                "official_runtime": "runtime_gold_v25",
                "official_alias": "runtime_gold_current_v5",
                "preferred_prefixes": ["/api/current-v5/fisconforme-v2", "/api/gold25/fisconforme-v2"],
            },
        },
        "transition_only": {
            "runtimes": [],
            "usage_rule": "sem runtimes de transicao remanescentes; usar apenas aliases/documentacao de migracao quando estritamente necessario",
        },
        "historical_only": {
            "runtimes": [
                "runtime_gold_v14",
                "runtime_gold_v15",
                "runtime_gold_v16",
                "runtime_gold_v17",
                "runtime_gold_v18",
                "runtime_gold_v19",
                "runtime_gold_v21",
                "runtime_gold_v22",
                "runtime_gold_v23",
                "runtime_gold_v24",
                "runtime_gold_current",
                "runtime_gold_current_v3",
                "runtime_gold_current_v4",
            ],
            "repo_status": "ja_removidas_do_repositorio",
            "usage_rule": "manter apenas como referencia historica em documentacao tecnica e nao usar como referencia principal",
        },
    }
