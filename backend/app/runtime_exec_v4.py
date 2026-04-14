from fastapi import FastAPI, APIRouter

from backend.app.conversao_quality_router import router as conversao_quality_router
from backend.app.estoque_quality_router import router as estoque_quality_router
from backend.app.routers_v2 import agregacao, conversao, estoque, fisconforme, health
from backend.app.services.pipeline_exec_v4_service import execute_pipeline_from_storage_v4

pipeline_router = APIRouter()


@pipeline_router.post("/{cnpj}/run")
def run_pipeline(cnpj: str) -> dict:
    return execute_pipeline_from_storage_v4(cnpj)


app = FastAPI(title="sistema_ro_exec_v4", version="0.6.1")

app.include_router(health.router, prefix="/api/v6b/health", tags=["health"])
app.include_router(agregacao.router, prefix="/api/v6b/agregacao", tags=["agregacao"])
app.include_router(conversao.router, prefix="/api/v6b/conversao", tags=["conversao"])
app.include_router(estoque.router, prefix="/api/v6b/estoque", tags=["estoque"])
app.include_router(fisconforme.router, prefix="/api/v6b/fisconforme", tags=["fisconforme"])
app.include_router(pipeline_router, prefix="/api/v6b/pipeline", tags=["pipeline"])
app.include_router(conversao_quality_router, prefix="/api/v6b/conversao", tags=["conversao_quality"])
app.include_router(estoque_quality_router, prefix="/api/v6b/estoque", tags=["estoque_quality"])


@app.get("/")
def root() -> dict[str, str]:
    return {
        "name": "sistema_ro_exec_v4",
        "status": "validated_gold_execution_v3",
    }
