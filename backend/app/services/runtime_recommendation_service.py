from __future__ import annotations


def get_runtime_recommendation() -> dict:
    return {
        "official_runtime": "runtime_gold_v19",
        "official_pipeline": "gold_v19",
        "official_api_prefix": "/api/gold19",
        "status": "official_recommended_runtime",
        "why": [
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
            "runtime_gold_v19": "runtime_oficial",
        },
        "next_focus": [
            "reduzir paralelismo entre trilhas antigas e nova",
            "ligar diagnostico_conversao_unidade_base ao fluxo operacional completo",
            "migrar fisconforme nao atendido em servicos desacoplados",
        ],
    }
