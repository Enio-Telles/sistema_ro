from __future__ import annotations

from fastapi import APIRouter
from pydantic import BaseModel

from backend.app.services.fisconforme_dsf_service_v2 import get_dsf_v2, list_dsfs_v2, save_dsf_v2
from backend.app.services.fisconforme_notification_service_v2 import build_notification_v2
from pipeline.fisconforme.query_service_v2 import limpar_cnpj_fisconforme

router = APIRouter()


class DsfAcervoRequestV2(BaseModel):
    id: str | None = None
    dsf: str
    referencia: str = ""
    cnpjs: list[str] = []
    data_inicio: str = "01/2021"
    data_fim: str = "12/2025"
    forcar_atualizacao: bool = False
    auditor: str = ""
    cargo_titulo: str = ""
    matricula: str = ""
    contato: str = ""
    orgao_origem: str = ""
    output_dir: str = ""
    pdf_file_name: str = ""
    pdf_base64: str | None = None


class NotificationRequestV2(BaseModel):
    cnpj: str
    dsf: str = ""
    dsf_id: str | None = None
    auditor: str = ""
    cargo_titulo: str = ""
    matricula: str = ""
    contato: str = ""
    orgao_origem: str = ""
    output_dir: str = ""


@router.get("/dsfs")
def list_dsfs() -> dict:
    return list_dsfs_v2()


@router.get("/dsfs/{dsf_id}")
def get_dsf(dsf_id: str) -> dict:
    return get_dsf_v2(dsf_id)


@router.post("/dsfs")
def save_dsf(req: DsfAcervoRequestV2) -> dict:
    return save_dsf_v2(req.model_dump())


@router.post("/notificacao")
def render_notification(req: NotificationRequestV2) -> dict:
    cnpj = limpar_cnpj_fisconforme(req.cnpj)
    return build_notification_v2(cnpj, req.model_dump())
