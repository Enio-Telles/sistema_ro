from fastapi import FastAPI

from backend.app.conversao_quality_router import router as conversao_quality_router
from backend.app.routers_v2 import health

app = FastAPI(title="sistema_ro_quality", version="0.7.0")

app.include_router(health.router, prefix="/api/v7/health", tags=["health"])
app.include_router(conversao_quality_router, prefix="/api/v7/conversao", tags=["conversao_quality"])


@app.get("/")
def root() -> dict[str, str]:
    return {
        "name": "sistema_ro_quality",
        "status": "ready_for_conversion_quality_preview",
    }
