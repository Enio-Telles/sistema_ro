from fastapi import FastAPI

from backend.app.references_diagnostic_router import router as references_router
from backend.app.routers_v2 import health

app = FastAPI(title="sistema_ro_diagnostics", version="0.8.0")

app.include_router(health.router, prefix="/api/v8/health", tags=["health"])
app.include_router(references_router, prefix="/api/v8/references", tags=["references"])


@app.get("/")
def root() -> dict[str, str]:
    return {
        "name": "sistema_ro_diagnostics",
        "status": "ready_for_references_and_parquet_diagnostics",
    }
