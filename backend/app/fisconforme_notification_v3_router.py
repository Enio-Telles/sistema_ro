from __future__ import annotations

from fastapi import APIRouter
from pydantic import BaseModel

from backend.app.services.fisconforme_notification_service_v3 import build_notification_v3, build_notifications_zip_v2
from pipeline.fisconforme.query_service_v2 import limpar_cnpj_fisconforme

router = APIRouter()


class NotificationRequestV3(BaseModel):
    cnpj: str
    dsf: str = ""
    dsf_id: str | None = None
    auditor: str = ""
    cargo_titulo: str = ""
    matricula: str = ""
    contato: str = ""
    orgao_origem: str = ""
    output_dir: str = ""
    pdf_base64: str | None = None


class NotificationBatchRequestV3(BaseModel):
    cnpjs: list[str]
    dsf: str = ""
    dsf_id: str | None = None
    auditor: str = ""
    cargo_titulo: str = ""
    matricula: str = ""
    contato: str = ""
    orgao_origem: str = ""
    output_dir: str = ""
    pdf_base64: str | None = None


@router.post("/notificacao-v3")
def render_notification_v3(req: NotificationRequestV3) -> dict:
    cnpj = limpar_cnpj_fisconforme(req.cnpj)
    return build_notification_v3(cnpj, req.model_dump())


@router.post("/notificacoes-lote-v2")
def render_notification_batch_v2(req: NotificationBatchRequestV3) -> dict:
    cnpjs = [limpar_cnpj_fisconforme(item) for item in req.cnpjs]
    cnpjs = [item for item in cnpjs if item]
    return build_notifications_zip_v2(cnpjs, req.model_dump())
