from fastapi import FastAPI

from backend.app.routers_v2 import agregacao, conversao, estoque, fisconforme, health
from backend.app.routers_v3 import pipeline

app = FastAPI(title="sistema_ro_exec", version="0.3.0")

app.include_router(health.router, prefix="/api/v3/health", tags=["health"])
app.include_router(agregacao.router, prefix="/api/v3/agregacao", tags=["agregacao"])
app.include_router(conversao.router, prefix="/api/v3/conversao", tags=["conversao"])
app.include_router(estoque.router, prefix="/api/v3/estoque", tags=["estoque"])
app.include_router(fisconforme.router, prefix="/api/v3/fisconforme", tags=["fisconforme"])
app.include_router(pipeline.router, prefix="/api/v3/pipeline", tags=["pipeline"])


@app.get("/")
def root() -> dict[str, str]:
    return {
        "name": "sistema_ro_exec",
        "status": "ready_for_gold_execution",
    }
