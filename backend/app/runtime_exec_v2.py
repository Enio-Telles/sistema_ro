from fastapi import FastAPI

from backend.app.routers_v2 import agregacao, conversao, estoque, fisconforme, health
from backend.app.routers_v4 import pipeline

app = FastAPI(title="sistema_ro_exec_v2", version="0.4.0")

app.include_router(health.router, prefix="/api/v4/health", tags=["health"])
app.include_router(agregacao.router, prefix="/api/v4/agregacao", tags=["agregacao"])
app.include_router(conversao.router, prefix="/api/v4/conversao", tags=["conversao"])
app.include_router(estoque.router, prefix="/api/v4/estoque", tags=["estoque"])
app.include_router(fisconforme.router, prefix="/api/v4/fisconforme", tags=["fisconforme"])
app.include_router(pipeline.router, prefix="/api/v4/pipeline", tags=["pipeline"])


@app.get("/")
def root() -> dict[str, str]:
    return {
        "name": "sistema_ro_exec_v2",
        "status": "validated_gold_execution",
    }
