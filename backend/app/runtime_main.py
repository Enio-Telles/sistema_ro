from fastapi import FastAPI, APIRouter

from backend.app.conversao_quality_router import router as conversao_quality_router
from backend.app.decommission_plan_router import router as decommission_plan_router
from backend.app.deprecation_surface_router import router as deprecation_surface_router
from backend.app.estoque_quality_router import router as estoque_quality_router
from backend.app.fisconforme_recommendation_v2_router import router as fisconforme_recommendation_v2_router
from backend.app.operational_surface_index_router import router as operational_surface_index_router
from backend.app.references_diagnostic_router import router as references_router
from backend.app.runtime_overview_router import router as runtime_overview_router
from backend.app.runtime_recommendation_v2_router import router as runtime_recommendation_v2_router
from backend.app.runtime_surface_catalog_router import router as runtime_surface_catalog_router
from backend.app.status_router import router as status_router
from backend.app.routers_v2 import agregacao, conversao, estoque, fisconforme, health
from backend.app.services.pipeline_exec_gold_v20 import execute_gold_v20, get_gold_v20_status

pipeline_router = APIRouter()

@pipeline_router.post("/{cnpj}/run")
def run_pipeline(cnpj: str) -> dict:
    return execute_gold_v20(cnpj)


@pipeline_router.get("/{cnpj}/status")
def get_pipeline_status(cnpj: str) -> dict:
    return get_gold_v20_status(cnpj)


app = FastAPI(title="sistema_ro_main", version="1.0.0")

app.include_router(health.router, prefix="/api/main/health", tags=["health"])
app.include_router(status_router, prefix="/api/main/status", tags=["status"])
app.include_router(runtime_recommendation_v2_router, prefix="/api/main/runtime", tags=["runtime_recommendation"])
app.include_router(runtime_overview_router, prefix="/api/main/runtime-overview", tags=["runtime_overview"])
app.include_router(deprecation_surface_router, prefix="/api/main/deprecations", tags=["deprecations"])
app.include_router(decommission_plan_router, prefix="/api/main/decommission", tags=["decommission"])
app.include_router(operational_surface_index_router, prefix="/api/main/surfaces", tags=["operational_surface_index"])
app.include_router(runtime_surface_catalog_router, prefix="/api/main/surfaces/catalog", tags=["runtime_surface_catalog"])
app.include_router(fisconforme_recommendation_v2_router, prefix="/api/main/fisconforme-v2/recommendation", tags=["fisconforme_recommendation_v2"])
app.include_router(agregacao.router, prefix="/api/main/agregacao", tags=["agregacao"])
app.include_router(conversao.router, prefix="/api/main/conversao", tags=["conversao"])
app.include_router(estoque.router, prefix="/api/main/estoque", tags=["estoque"])
app.include_router(fisconforme.router, prefix="/api/main/fisconforme", tags=["fisconforme"])
app.include_router(pipeline_router, prefix="/api/main/pipeline", tags=["pipeline"])
app.include_router(conversao_quality_router, prefix="/api/main/conversao", tags=["conversao_quality"])
app.include_router(estoque_quality_router, prefix="/api/main/estoque", tags=["estoque_quality"])
app.include_router(references_router, prefix="/api/main/references", tags=["references"])
app.include_router(agents_router, prefix="/api/main/agents", tags=["agents"])


@app.get("/")
def root() -> dict[str, object]:
    return {
        "name": "sistema_ro_main",
        "status": "recommended_operational_entrypoint",
        "official_entrypoints": {
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
