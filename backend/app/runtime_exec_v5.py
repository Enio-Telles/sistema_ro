from fastapi import FastAPI, APIRouter

from backend.app.conversao_quality_router import router as conversao_quality_router
from backend.app.estoque_quality_router import router as estoque_quality_router
from backend.app.references_diagnostic_router import router as references_router
from backend.app.routers_v2 import agregacao, conversao, estoque, fisconforme, health
from backend.app.services.pipeline_exec_v5_service import execute_pipeline_from_storage_v5

pipeline_router = APIRouter()


@pipeline_router.post("/{cnpj}/run")
def run_pipeline(cnpj: str) -> dict:
    return execute_pipeline_from_storage_v5(cnpj)


app = FastAPI(title="sistema_ro_exec_v5", version="0.6.2")

app.include_router(health.router, prefix="/api/v6c/health", tags=["health"])
app.include_router(agregacao.router, prefix="/api/v6c/agregacao", tags=["agregacao"])
app.include_router(conversao.router, prefix="/api/v6c/conversao", tags=["conversao"])
app.include_router(estoque.router, prefix="/api/v6c/estoque", tags=["estoque"])
app.include_router(fisconforme.router, prefix="/api/v6c/fisconforme", tags=["fisconforme"])
app.include_router(pipeline_router, prefix="/api/v6c/pipeline", tags=["pipeline"])
app.include_router(conversao_quality_router, prefix="/api/v6c/conversao", tags=["conversao_quality"])
app.include_router(estoque_quality_router, prefix="/api/v6c/estoque", tags=["estoque_quality"])
app.include_router(references_router, prefix="/api/v6c/references", tags=["references"])


@app.get("/")
def root() -> dict[str, str]:
    return {
        "name": "sistema_ro_exec_v5",
        "status": "validated_gold_execution_v3_with_sefin_awareness",
    }
