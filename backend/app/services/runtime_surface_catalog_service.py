from __future__ import annotations


def get_runtime_surface_catalog() -> dict:
    return {
        "official": {
            "silver_runtime": "runtime_silver_v2",
            "silver_prepare_prefix": "/api/v5b/silver",
            "silver_prepare_sefin_endpoint": "/api/v5b/silver/{cnpj}/prepare-sefin",
            "gold_runtime": "runtime_gold_v20",
            "gold_current_alias": "runtime_gold_current_v2",
            "gold_api_prefix": "/api/gold20",
            "gold_current_prefix": "/api/current-v2",
            "fisconforme_runtime": "runtime_gold_v25",
            "fisconforme_current_alias": "runtime_gold_current_v5",
            "fisconforme_api_prefix": "/api/gold25/fisconforme-v2",
            "fisconforme_current_prefix": "/api/current-v5/fisconforme-v2",
        },
        "transition": {
            "gold": [],
            "fisconforme": [
                "runtime_gold_v21",
                "runtime_gold_v22",
                "runtime_gold_v23",
                "runtime_gold_v24",
            ],
        },
        "legacy": {
            "gold": [
                "runtime_gold_v14",
                "runtime_gold_v15",
                "runtime_gold_v16",
                "runtime_gold_v17",
                "runtime_gold_v18",
                "runtime_gold_v19",
            ],
            "current_aliases": [
                "runtime_gold_current",
                "runtime_gold_current_v3",
            ],
            "fisconforme_routes": [
                "/api/current-v3/fisconforme",
                "/api/gold25/fisconforme",
            ],
            "repo_status": {
                "removed_from_repo": [
                    "runtime_gold_v14",
                    "runtime_gold_v15",
                    "runtime_gold_v16",
                    "runtime_gold_v17",
                    "runtime_gold_v18",
                    "runtime_gold_v19",
                    "runtime_gold_current",
                ],
                "still_present_as_transition": [
                    "runtime_gold_current_v3",
                    "runtime_gold_v21",
                    "runtime_gold_v22",
                    "runtime_gold_v23",
                    "runtime_gold_v24",
                ],
            },
        },
        "operational_guidance": {
            "silver_preferred_prefixes": ["/api/v5b/silver"],
            "gold_preferred_prefixes": ["/api/gold20", "/api/current-v2"],
            "fisconforme_preferred_prefixes": ["/api/gold25/fisconforme-v2", "/api/current-v5/fisconforme-v2"],
        },
        "decommissioning_guidelines": [
            "nao abrir novas features nas runtimes marcadas como legacy",
            "usar as runtimes transition apenas para comparacao controlada e migracao",
            "considerar v14 a v19 e runtime_gold_current como historico ja removido do repositorio",
            "usar runtime_silver_v2 para preparacao silver com enriquecimento SEFIN",
            "concentrar novas evolucoes de gold em gold_v20/current-v2",
            "concentrar novas evolucoes de fisconforme em gold_v25/current-v5 fisconforme-v2",
        ],
    }
