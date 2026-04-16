from __future__ import annotations


def get_runtime_recommendation_v2() -> dict:
    return {
        "official_runtime": "runtime_gold_v20",
        "official_pipeline": "gold_v20",
        "official_api_prefix": "/api/gold20",
        "official_current_alias": "runtime_gold_current_v2",
        "official_current_api_prefix": "/api/current-v2",
        "status": "official_recommended_runtime_v2",
        "why": [
            "prefere fontes_agr validadas por schema",
            "mantem fallback seguro para silver quando necessario",
            "executa checagem pos-gold de consistencia de estoque e fiscal",
            "integra diagnostico_conversao_unidade_base ao fluxo operacional de conversao",
            "preserva a arquitetura mdc_base -> agregacao -> fontes_agr -> gold",
        ],
        "migration_map": {
            "runtime_gold_v14": "historico_removido_do_repositorio_mdc_base_inicial",
            "runtime_gold_v15": "historico_removido_do_repositorio_agregacao_a_partir_do_mdc",
            "runtime_gold_v16": "historico_removido_do_repositorio_fontes_agr_inicial",
            "runtime_gold_v17": "historico_removido_do_repositorio_gold_preferindo_fontes_agr",
            "runtime_gold_v18": "historico_removido_do_repositorio_fontes_agr_validadas_por_schema",
            "runtime_gold_v19": "historico_removido_do_repositorio_pos_gold_consistency",
            "runtime_gold_v20": "runtime_oficial_v2",
        },
        "next_focus": [
            "reduzir paralelismo entre trilhas antigas e nova",
            "ampliar testes de regressao da conversao integrada",
            "revisar descomissionamento das runtimes fisconforme de transicao restantes",
        ],
    }
