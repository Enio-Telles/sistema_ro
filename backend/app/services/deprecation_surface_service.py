from __future__ import annotations

LEGACY_ROUTE_REPLACEMENTS = {
    "/api/current-v4/fisconforme": "/api/current-v4/fisconforme-v2",
    "/api/current-v5/fisconforme": "/api/current-v5/fisconforme-v2",
    "/api/gold25/fisconforme": "/api/gold25/fisconforme-v2",
    "/api/current-v4/runtime-gold-current": "/api/current-v4/runtime",
}


def get_legacy_route_replacements() -> dict:
    return LEGACY_ROUTE_REPLACEMENTS


def match_legacy_route(path: str) -> dict | None:
    for legacy_prefix, replacement_prefix in LEGACY_ROUTE_REPLACEMENTS.items():
        if path == legacy_prefix or path.startswith(f"{legacy_prefix}/"):
            return {
                "deprecated": True,
                "legacy_prefix": legacy_prefix,
                "replacement_prefix": replacement_prefix,
                "message": "Superfície legada. Use a rota modular recomendada.",
            }
    return None
