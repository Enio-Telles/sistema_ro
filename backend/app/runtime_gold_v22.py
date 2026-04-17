from fastapi import FastAPI

from backend.app.runtime_router_factory import build_pipeline_router
from backend.app.runtime_surface_builder import include_gold_runtime_routes
from backend.app.services.transition_runtime_service import TransitionRuntimeMiddleware
from backend.app.runtime_recommendation_v2_router import router as runtime_recommendation_v2_router
from backend.app.services.pipeline_exec_gold_v20 import execute_gold_v20

pipeline_router = build_pipeline_router(
    run_handler=lambda cnpj: execute_gold_v20(cnpj),
)


app = FastAPI(title="sistema_ro_gold_v22", version="3.1.0")
app.add_middleware(
    TransitionRuntimeMiddleware,
    replacement_runtime="runtime_gold_v25",
    replacement_prefix="/api/gold25/fisconforme-v2",
)
include_gold_runtime_routes(
    app,
    prefix="/api/gold22",
    pipeline_router=pipeline_router,
    runtime_recommendation_router=runtime_recommendation_v2_router,
    include_fisconforme_v2_base=True,
    include_fisconforme_refresh_v2=True,
)


@app.get("/")
def root() -> dict[str, str]:
    return {
        "name": "sistema_ro_gold_v22",
        "status": "transition_runtime_replaced_by_gold_v25_for_fisconforme_use",
        "replacement_runtime": "runtime_gold_v25",
        "replacement_prefix": "/api/gold25/fisconforme-v2",
    }
