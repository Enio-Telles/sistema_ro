from __future__ import annotations


def get_runtime_recommendation_v2() -> dict:
    return {
        "official_runtime": {
            "gold": {
                "runtime": "runtime_gold_v20",
                "pipeline": "gold_v20",
                "api_prefix": "/api/gold20",
                "current_alias": "runtime_gold_current_v2",
                "current_api_prefix": "/api/current-v2",
                "status": "official_recommended_runtime_v2",
            },
            "fisconforme": {
                "runtime": "runtime_gold_v25",
                "pipeline": "gold_v25_fisconforme_v2",
                "api_prefix": "/api/gold25/fisconforme-v2",
                "current_alias": "runtime_gold_current_v5",
                "current_api_prefix": "/api/current-v5/fisconforme-v2",
                "status": "official_recommended_runtime_v5_for_fisconforme",
            },
        },
        "status": "official_operational_runtime_split_between_gold_v20_and_gold_v25",
        "why": [
            "mantem gold operacional estavel em gold_v20/current-v2",
            "concentra fisconforme modular em gold_v25/current-v5 fisconforme-v2",
            "prefere fontes_agr validadas por schema",
            "mantem fallback seguro para silver quando necessario",
            "executa checagem pos-gold de consistencia de estoque e fiscal",
            "preserva a arquitetura mdc_base -> agregacao -> fontes_agr -> gold",
        ],
        "migration_map": {
            "runtime_gold_v14": "transicao_mdc_base_inicial",
            "runtime_gold_v15": "transicao_agregacao_a_partir_do_mdc",
            "runtime_gold_v16": "transicao_fontes_agr_inicial",
            "runtime_gold_v17": "transicao_gold_preferindo_fontes_agr",
            "runtime_gold_v18": "transicao_fontes_agr_validadas_por_schema",
            "runtime_gold_v19": "transicao_pos_gold_consistency",
            "runtime_gold_v20": "runtime_oficial_gold",
            "runtime_gold_v21": "transicao_fisconforme_modular_inicial",
            "runtime_gold_v22": "transicao_fisconforme_recomendacao",
            "runtime_gold_v23": "transicao_fisconforme_refresh_e_dsf",
            "runtime_gold_v24": "transicao_fisconforme_notificacao_e_output",
            "runtime_gold_v25": "runtime_oficial_fisconforme",
            "runtime_gold_current_v3": "alias_em_transicao_substituido_por_current_v5",
            "runtime_gold_current_v5": "alias_oficial_fisconforme",
        },
        "next_focus": [
            "reduzir paralelismo entre trilhas antigas e nova",
            "ampliar testes de regressao da conversao integrada",
            "remover ambiguidade documental entre current-v3 e current-v5",
        ],
    }
