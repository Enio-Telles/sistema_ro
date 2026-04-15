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
                "runtime_gold_current_v3",
                "runtime_gold_current_v4",
            ],
        },
        "keep_temporarily": {
            "transition_runtimes": [
                {
                    "name": "runtime_gold_v18",
                    "reason": "comparacao controlada da adocao de fontes_agr validadas",
                    "target_action": "retirar apos encerramento da validacao comparativa",
                },
                {
                    "name": "runtime_gold_v19",
                    "reason": "comparacao controlada da checagem pos-gold antes da integracao de diagnostico",
                    "target_action": "retirar apos aceite funcional do gold_v20",
                },
                {
                    "name": "runtime_gold_v21",
                    "reason": "marco inicial da modularizacao de fisconforme cache e lote",
                    "target_action": "retirar apos consolidacao do fluxo v2 completo",
                },
                {
                    "name": "runtime_gold_v22",
                    "reason": "marco inicial do refresh Oracle/SQL runner",
                    "target_action": "retirar apos estabilizacao do provider modular",
                },
                {
                    "name": "runtime_gold_v23",
                    "reason": "marco inicial de DSF e notificacao modular",
                    "target_action": "retirar apos aceite do ZIP e DOCX modulares",
                },
                {
                    "name": "runtime_gold_v24",
                    "reason": "marco inicial de template externo e ZIP em lote",
                    "target_action": "retirar apos uso corrente migrar para gold_v25/current-v3",
                },
            ],
        },
        "deprecate_now": {
            "legacy_runtimes": [
            ],
            "legacy_routes": [
                {
                    "route": "/api/current-v4/fisconforme",
                    "replacement": "/api/current-v4/fisconforme-v2",
                },
                {
                    "route": "/api/gold25/fisconforme",
                    "replacement": "/api/gold25/fisconforme-v2",
                },
            ],
        },
        "next_removals_priority": [
        ],
        "rules": [
            "nao remover uma runtime de transicao sem confirmar rota substituta operacional",
            "nao abrir novas features em superfícies marcadas como deprecate_now",
            "preferir esconder aliases antigos em documentacao antes da remocao fisica",
        ],
        "phases": [
            "1. Higienização de runtimes v6-v17",
            "2. Estabilização do Fisconforme v2",
            "3. Desativação das rotas de transição v21-v24",
        ],
    }
