from fastapi import FastAPI

from backend.app.pipeline_router_v6 import router as pipeline_router
from backend.app.routers_v2 import agregacao, conversao, estoque, fisconforme, health

app = FastAPI(title="sistema_ro_exec_v3", version="0.6.0")

app.include_router(health.router, prefix="/api/v6/health", tags=["health"])
app.include_router(agregacao.router, prefix="/api/v6/agregacao", tags=["agregacao"])
app.include_router(conversao.router, prefix="/api/v6/conversao", tags=["conversao"])
app.include_router(estoque.router, prefix="/api/v6/estoque", tags=["estoque"])
app.include_router(fisconforme.router, prefix="/api/v6/fisconforme", tags=["fisconforme"])
app.include_router(pipeline_router, prefix="/api/v6/pipeline", tags=["pipeline"])


@app.get("/")
def root() -> dict[str, str]:
    return {
        "name": "sistema_ro_exec_v3",
        "status": "validated_gold_execution_v2",
    }
