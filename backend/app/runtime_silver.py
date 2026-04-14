from fastapi import FastAPI

from backend.app.routers_v5 import health, silver

app = FastAPI(title="sistema_ro_silver", version="0.5.0")

app.include_router(health.router, prefix="/api/v5/health", tags=["health"])
app.include_router(silver.router, prefix="/api/v5/silver", tags=["silver"])


@app.get("/")
def root() -> dict[str, str]:
    return {
        "name": "sistema_ro_silver",
        "status": "ready_for_silver_preparation",
    }
