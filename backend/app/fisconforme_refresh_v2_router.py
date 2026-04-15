from __future__ import annotations

from fastapi import APIRouter
from pydantic import BaseModel

from backend.app.services.fisconforme_refresh_service_v3 import refresh_fisconforme_batch_v3, refresh_fisconforme_v3

router = APIRouter()


class FisconformeRefreshBatchRequestV2(BaseModel):
    cnpjs: list[str]
    data_inicio: str = "01/2021"
    data_fim: str = "12/2025"


@router.post("/{cnpj}/refresh")
def refresh_single(cnpj: str, data_inicio: str = "01/2021", data_fim: str = "12/2025") -> dict:
    return refresh_fisconforme_v3(cnpj, data_inicio=data_inicio, data_fim=data_fim)


@router.post("/refresh-lote")
def refresh_batch(req: FisconformeRefreshBatchRequestV2) -> dict:
    return refresh_fisconforme_batch_v3(req.cnpjs, data_inicio=req.data_inicio, data_fim=req.data_fim)
