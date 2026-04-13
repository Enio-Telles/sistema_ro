from fastapi import FastAPI

from backend.app.routers import agregacao, conversao, estoque, fisconforme, health

app = FastAPI(title="sistema_ro", version="0.1.0")

app.include_router(health.router, prefix="/api/v1/health", tags=["health"])
app.include_router(agregacao.router, prefix="/api/v1/agregacao", tags=["agregacao"])
app.include_router(conversao.router, prefix="/api/v1/conversao", tags=["conversao"])
app.include_router(estoque.router, prefix="/api/v1/estoque", tags=["estoque"])
app.include_router(fisconforme.router, prefix="/api/v1/fisconforme", tags=["fisconforme"])


@app.get("/")
def root() -> dict[str, str]:
    return {
        "name": "sistema_ro",
        "status": "initialized",
        "message": "Scaffold inicial pronto para as fases do plano.",
    }
