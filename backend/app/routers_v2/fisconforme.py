from fastapi import APIRouter
from pydantic import BaseModel

from backend.app.services.fisconforme_cache_service_v2 import get_fisconforme_cache_stats_v2
from backend.app.services.fisconforme_query_service_v2 import (
    get_fisconforme_batch_cache_overview_v2,
    get_fisconforme_cache_overview_v2,
)

router = APIRouter()


class FisconformeBatchRequestV2(BaseModel):
    cnpjs: list[str]


@router.get("/cache/stats")
def get_cache_stats() -> dict:
    return get_fisconforme_cache_stats_v2()


@router.post("/lote")
def get_fisconforme_batch(req: FisconformeBatchRequestV2) -> dict:
    return get_fisconforme_batch_cache_overview_v2(req.cnpjs)


@router.get("/{cnpj}")
def get_fisconforme(cnpj: str) -> dict:
    return get_fisconforme_cache_overview_v2(cnpj)
