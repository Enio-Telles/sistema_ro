from fastapi import FastAPI

from backend.app.routers_v2 import agregacao, conversao, estoque, fisconforme, health, pipeline

app = FastAPI(title="sistema_ro_runtime", version="0.2.0")

app.include_router(health.router, prefix="/api/v2/health", tags=["health"])
app.include_router(agregacao.router, prefix="/api/v2/agregacao", tags=["agregacao"])
app.include_router(conversao.router, prefix="/api/v2/conversao", tags=["conversao"])
app.include_router(estoque.router, prefix="/api/v2/estoque", tags=["estoque"])
app.include_router(fisconforme.router, prefix="/api/v2/fisconforme", tags=["fisconforme"])
app.include_router(pipeline.router, prefix="/api/v2/pipeline", tags=["pipeline"])


@app.get("/")
def root() -> dict[str, str]:
    return {
        "name": "sistema_ro_runtime",
        "status": "ready_for_dataset_preview",
    }
