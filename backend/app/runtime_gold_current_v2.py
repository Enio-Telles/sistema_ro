from fastapi import FastAPI

from backend.app.runtime_router_factory import build_pipeline_router
from backend.app.runtime_surface_builder import include_gold_runtime_routes
from backend.app.runtime_recommendation_v2_router import router as runtime_recommendation_v2_router
from backend.app.services.pipeline_exec_gold_v20 import execute_gold_v20, get_gold_v20_status

pipeline_router = build_pipeline_router(
    run_handler=lambda cnpj: execute_gold_v20(cnpj),
    status_handler=lambda cnpj: get_gold_v20_status(cnpj),
)


app = FastAPI(title="sistema_ro_gold_current_v2", version="2.9.0")
include_gold_runtime_routes(
    app,
    prefix="/api/current-v2",
    pipeline_router=pipeline_router,
    runtime_recommendation_router=runtime_recommendation_v2_router,
)


@app.get("/")
def root() -> dict[str, str]:
    return {
        "name": "sistema_ro_gold_current_v2",
        "status": "official_runtime_aliasing_gold_v20",
    }
