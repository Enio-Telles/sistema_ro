from fastapi import FastAPI

from backend.app.runtime_router_factory import build_pipeline_router
from backend.app.runtime_surface_builder import include_gold_runtime_routes
from backend.app.runtime_recommendation_v2_router import router as runtime_recommendation_v2_router
from backend.app.services.pipeline_exec_gold_v20 import execute_gold_v20, get_gold_v20_status

pipeline_router = build_pipeline_router(
    run_handler=lambda cnpj: execute_gold_v20(cnpj),
    status_handler=lambda cnpj: get_gold_v20_status(cnpj),
)


app = FastAPI(title="sistema_ro_main", version="1.0.0")

include_gold_runtime_routes(
    app,
    prefix="/api/main",
    pipeline_router=pipeline_router,
    runtime_recommendation_router=runtime_recommendation_v2_router,
    include_runtime_overview=True,
    include_deprecation_routes=True,
    include_decommission_routes=True,
    include_surface_catalog=True,
    include_fisconforme_recommendation=True,
)


@app.get("/")
def root() -> dict[str, object]:
    return {
        "name": "sistema_ro_main",
        "status": "recommended_operational_entrypoint",
        "official_entrypoints": {
            "silver": {
                "runtime": "runtime_silver_v2",
                "api_prefix": "/api/v5b/silver",
                "prepare_sefin_endpoint": "/api/v5b/silver/{cnpj}/prepare-sefin",
            },
            "gold": {
                "runtime": "runtime_gold_current_v2",
                "api_prefix": "/api/current-v2",
            },
            "fisconforme": {
                "runtime": "runtime_gold_current_v5",
                "api_prefix": "/api/current-v5/fisconforme-v2",
            },
        },
    }
