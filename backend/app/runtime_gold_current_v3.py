from __future__ import annotations

from fastapi import FastAPI, Request
from starlette.middleware.base import BaseHTTPMiddleware

from backend.app.runtime_router_factory import build_pipeline_router
from backend.app.runtime_surface_builder import include_gold_runtime_routes
from backend.app.runtime_recommendation_v2_router import router as runtime_recommendation_v2_router
from backend.app.services.pipeline_exec_gold_v20 import execute_gold_v20


class CurrentV3DeprecationMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        response.headers["Deprecation"] = "true"
        response.headers["X-Replacement-Runtime"] = "runtime_gold_current_v5"
        response.headers["X-Replacement-Prefix"] = "/api/current-v5/fisconforme-v2"
        response.headers["Warning"] = '299 - "Current-v3 em transicao. Prefira current-v5 para operacao oficial."'
        return response


pipeline_router = build_pipeline_router(
    run_handler=lambda cnpj: execute_gold_v20(cnpj),
)


app = FastAPI(title="sistema_ro_gold_current_v3", version="3.5.0")
app.add_middleware(CurrentV3DeprecationMiddleware)
include_gold_runtime_routes(
    app,
    prefix="/api/current-v3",
    pipeline_router=pipeline_router,
    runtime_recommendation_router=runtime_recommendation_v2_router,
    include_runtime_overview=True,
    include_deprecation_routes=True,
    include_decommission_routes=True,
    include_surface_catalog=True,
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
        "name": "sistema_ro_gold_current_v3",
        "status": "transition_runtime_replaced_by_current_v5_for_official_use",
        "replacement_runtime": "runtime_gold_current_v5",
        "replacement_prefix": "/api/current-v5/fisconforme-v2",
    }
