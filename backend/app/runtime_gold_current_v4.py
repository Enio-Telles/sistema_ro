from __future__ import annotations

from fastapi import FastAPI, Request
from starlette.middleware.base import BaseHTTPMiddleware

from backend.app.runtime_router_factory import build_pipeline_router
from backend.app.runtime_surface_builder import include_gold_runtime_routes
from backend.app.services.deprecation_surface_service import match_legacy_route
from backend.app.runtime_recommendation_v2_router import router as runtime_recommendation_v2_router
from backend.app.services.pipeline_exec_gold_v20 import execute_gold_v20


class LegacyDeprecationMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        match = match_legacy_route(request.url.path)
        if match is not None:
            response.headers["Deprecation"] = "true"
            response.headers["X-Legacy-Route"] = match["legacy_prefix"]
            response.headers["X-Replacement-Route"] = match["replacement_prefix"]
            response.headers["Warning"] = '299 - "Superficie legada. Use a rota modular recomendada."'
        return response


pipeline_router = build_pipeline_router(
    run_handler=lambda cnpj: execute_gold_v20(cnpj),
)


app = FastAPI(title="sistema_ro_gold_current_v4", version="3.6.0")
app.add_middleware(LegacyDeprecationMiddleware)
include_gold_runtime_routes(
    app,
    prefix="/api/current-v4",
    pipeline_router=pipeline_router,
    runtime_recommendation_router=runtime_recommendation_v2_router,
    include_deprecation_routes=True,
    include_fisconforme_recommendation=True,
    include_fisconforme_v2_base=True,
    include_fisconforme_refresh_v2=True,
    include_fisconforme_dsf_v2=True,
    include_fisconforme_notification_v3=True,
    include_fisconforme_output_v2=True,
    fisconforme_legacy_tag="fisconforme_legacy",
)


@app.get("/")
def root() -> dict[str, str]:
    return {
        "name": "sistema_ro_gold_current_v4",
        "status": "official_runtime_alias_with_legacy_deprecation_headers",
    }
