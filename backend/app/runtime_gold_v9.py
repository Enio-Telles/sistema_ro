from fastapi import FastAPI, APIRouter

from backend.app.conversao_quality_router import router as conversao_quality_router
from backend.app.estoque_quality_router import router as estoque_quality_router
from backend.app.references_diagnostic_router import router as references_router
from backend.app.status_router import router as status_router
from backend.app.routers_v2 import agregacao, conversao, estoque, fisconforme, health
from backend.app.services.pipeline_exec_gold_v9 import execute_gold_v9

pipeline_router = APIRouter()


@pipeline_router.post("/{cnpj}/run")
def run_pipeline(cnpj: str) -> dict:
    return execute_gold_v9(cnpj)


app = FastAPI(title="sistema_ro_gold_v9", version="1.6.0")

app.include_router(health.router, prefix="/api/gold9/health", tags=["health"])
app.include_router(status_router, prefix="/api/gold9/status", tags=["status"])
app.include_router(agregacao.router, prefix="/api/gold9/agregacao", tags=["agregacao"])
app.include_router(conversao.router, prefix="/api/gold9/conversao", tags=["conversao"])
app.include_router(estoque.router, prefix="/api/gold9/estoque", tags=["estoque"])
app.include_router(fisconforme.router, prefix="/api/gold9/fisconforme", tags=["fisconforme"])
app.include_router(pipeline_router, prefix="/api/gold9/pipeline", tags=["pipeline"])
app.include_router(conversao_quality_router, prefix="/api/gold9/conversao", tags=["conversao_quality"])
app.include_router(estoque_quality_router, prefix="/api/gold9/estoque", tags=["estoque_quality"])
app.include_router(references_router, prefix="/api/gold9/references", tags=["references"])


@app.get("/")
def root() -> dict[str, str]:
    return {
        "name": "sistema_ro_gold_v9",
        "status": "recommended_runtime_gold_v8_with_manual_map",
    }
