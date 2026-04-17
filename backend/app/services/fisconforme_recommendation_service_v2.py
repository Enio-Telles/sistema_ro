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
            "/api/current-v3/fisconforme-v2",
        ],
        "recommended_routes": [
            "/api/gold25/fisconforme-v2/{cnpj}",
            "/api/gold25/fisconforme-v2/lote",
            "/api/gold25/fisconforme-v2/cache/stats",
            "/api/gold25/fisconforme-v2/{cnpj}/refresh",
            "/api/gold25/fisconforme-v2/refresh-lote",
            "/api/gold25/fisconforme-v2/dsfs",
            "/api/gold25/fisconforme-v2/notificacao-v3",
            "/api/gold25/fisconforme-v2/notificacoes-lote-v3/download",
            "/api/gold25/fisconforme-v2/notificacao-docx-v2",
            "/api/gold25/fisconforme-v2/notificacao-docx-v2/download",
            "/api/current-v5/fisconforme-v2/{cnzpj}",
            "/api/current-v5/fisconforme-v2/lote",
        ],
        "why": [
            "separa cache, extracao, acervo, notificacao e saida documental em modulos menores",
            "evita repetir o router monolitico do audit_react",
            "permite evolucao incremental com menor risco de regressao",
            "consolida o alias operacional em current-v5 sem depender de superfícies intermediarias",
        ],
    }
