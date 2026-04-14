from fastapi import FastAPI, APIRouter

from backend.app.routers_v5 import health
from backend.app.services.silver_base_v2_service import execute_silver_base_with_sefin

silver_router = APIRouter()


@silver_router.post("/{cnpj}/prepare-sefin")
def prepare_silver_sefin(cnpj: str) -> dict:
    return execute_silver_base_with_sefin(cnpj)


app = FastAPI(title="sistema_ro_silver_v2", version="0.5.1")

app.include_router(health.router, prefix="/api/v5b/health", tags=["health"])
app.include_router(silver_router, prefix="/api/v5b/silver", tags=["silver"])


@app.get("/")
def root() -> dict[str, str]:
    return {
        "name": "sistema_ro_silver_v2",
        "status": "ready_for_silver_preparation_with_sefin",
    }
