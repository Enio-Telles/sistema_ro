from __future__ import annotations

from pathlib import Path

from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel

from backend.app.services.fisconforme_docx_service_v2 import build_notification_docx_v2
from backend.app.services.fisconforme_notification_service_v3 import build_notifications_zip_v2
from pipeline.fisconforme.query_service_v2 import limpar_cnpj_fisconforme

router = APIRouter()


class NotificationDocxRequestV2(BaseModel):
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


class NotificationBatchRequestV4(BaseModel):
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


@router.post("/notificacoes-lote-v3/download")
def download_notifications_zip(req: NotificationBatchRequestV4):
    cnpjs = [limpar_cnpj_fisconforme(item) for item in req.cnpjs]
    cnpjs = [item for item in cnpjs if item]
    result = build_notifications_zip_v2(cnpjs, req.model_dump())
    path = Path(result["zip_path"])
    if not path.exists():
        raise HTTPException(status_code=404, detail="zip_nao_gerado")
    return FileResponse(path=path, filename=result["zip_name"], media_type="application/zip")


@router.post("/notificacao-docx-v2")
def render_notification_docx(req: NotificationDocxRequestV2) -> dict:
    cnpj = limpar_cnpj_fisconforme(req.cnpj)
    return build_notification_docx_v2(cnpj, req.model_dump())


@router.post("/notificacao-docx-v2/download")
def download_notification_docx(req: NotificationDocxRequestV2):
    cnpj = limpar_cnpj_fisconforme(req.cnpj)
    result = build_notification_docx_v2(cnpj, req.model_dump())
    path = Path(result["docx_path"])
    if not path.exists():
        raise HTTPException(status_code=404, detail="docx_nao_gerado")
    return FileResponse(
        path=path,
        filename=result["nome_arquivo"],
        media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    )
