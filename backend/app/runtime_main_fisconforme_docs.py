from fastapi import APIRouter, FastAPI

from backend.app.conversao_quality_router import router as conversao_quality_router
from backend.app.estoque_quality_router import router as estoque_quality_router
from backend.app.references_diagnostic_router import router as references_router
from backend.app.routers_v2 import agregacao, conversao, estoque, health
from backend.app.routers_v2.fisconforme_notificacao import router as fisconforme_router
from backend.app.services.pipeline_exec_gold_v20 import execute_gold_v20
from backend.app.status_router import router as status_router

pipeline_router = APIRouter()


@pipeline_router.post("/{cnpj}/run")
def run_pipeline(cnpj: str) -> dict:
    return execute_gold_v20(cnpj)


app = FastAPI(title="sistema_ro_main_fisconforme_docs", version="1.0.0")

app.include_router(health.router, prefix="/api/main/health", tags=["health"])
app.include_router(status_router, prefix="/api/main/status", tags=["status"])
app.include_router(agregacao.router, prefix="/api/main/agregacao", tags=["agregacao"])
app.include_router(conversao.router, prefix="/api/main/conversao", tags=["conversao"])
app.include_router(estoque.router, prefix="/api/main/estoque", tags=["estoque"])
app.include_router(fisconforme_router, prefix="/api/main/fisconforme", tags=["fisconforme"])
app.include_router(pipeline_router, prefix="/api/main/pipeline", tags=["pipeline"])
app.include_router(conversao_quality_router, prefix="/api/main/conversao", tags=["conversao_quality"])
app.include_router(estoque_quality_router, prefix="/api/main/estoque", tags=["estoque_quality"])
app.include_router(references_router, prefix="/api/main/references", tags=["references"])


@app.get("/")
def root() -> dict[str, str]:
    return {
        "name": "sistema_ro_main_fisconforme_docs",
        "status": "experimental_runtime",
        "notes": "extends /api/main/fisconforme with TXT, DOCX and lote ZIP generation",
    }
