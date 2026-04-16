from __future__ import annotations


def get_fisconforme_recommendation_v2() -> dict:
    return {
        "official_runtime": "runtime_gold_v25",
        "official_current_alias": "runtime_gold_current_v5",
        "official_api_prefix": "/api/gold25/fisconforme-v2",
        "official_current_api_prefix": "/api/current-v5/fisconforme-v2",
        "status": "fisconforme_v2_official_modular_flow",
        "official_modules": [
            "cache e overview",
            "consulta individual e lote",
            "refresh Oracle/SQL runner",
            "acervo DSF",
            "notificacao TXT com template externo",
            "ZIP em lote",
            "DOCX modular",
        ],
        "legacy_routes": [
            "/api/gold25/fisconforme",
        ],
        "recommended_routes": [
            "/api/current-v5/fisconforme-v2/{cnpj}",
            "/api/current-v5/fisconforme-v2/lote",
            "/api/current-v5/fisconforme-v2/cache/stats",
            "/api/current-v5/fisconforme-v2/{cnpj}/refresh",
            "/api/current-v5/fisconforme-v2/refresh-lote",
            "/api/current-v5/fisconforme-v2/dsfs",
            "/api/current-v5/fisconforme-v2/notificacao-v3",
            "/api/current-v5/fisconforme-v2/notificacoes-lote-v3/download",
            "/api/current-v5/fisconforme-v2/notificacao-docx-v2",
            "/api/current-v5/fisconforme-v2/notificacao-docx-v2/download",
        ],
        "why": [
            "separa cache, extracao, acervo, notificacao e saida documental em modulos menores",
            "evita repetir o router monolitico do audit_react",
            "permite evolucao incremental com menor risco de regressao",
        ],
    }
