from __future__ import annotations

from io import BytesIO

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from starlette.responses import StreamingResponse

from backend.app.services.fisconforme_notification_service import (
    generate_notification_docx,
    generate_notification_txt,
    generate_notifications_zip,
    load_auditor_config,
    save_auditor_config,
    save_binary_output,
    save_text_output,
)
from backend.app.services.fisconforme_service import get_fisconforme_overview

router = APIRouter()


class AuditorConfigRequest(BaseModel):
    auditor: str = ""
    cargo_titulo: str = ""
    matricula: str = ""
    contato: str = ""
    orgao_origem: str = ""


class GerarNotificacaoRequest(BaseModel):
    cnpj: str
    dsf: str = ""
    auditor: str
    cargo_titulo: str = ""
    matricula: str = ""
    contato: str = ""
    orgao_origem: str = ""
    output_dir: str = ""
    pdf_base64: str | None = None


class GerarNotificacoesLoteRequest(BaseModel):
    cnpjs: list[str]
    dsf: str = ""
    auditor: str
    cargo_titulo: str = ""
    matricula: str = ""
    contato: str = ""
    orgao_origem: str = ""
    output_dir: str = ""
    pdf_base64: str | None = None


@router.get("/auditor-config")
def get_auditor_config() -> dict[str, str]:
    return load_auditor_config()


@router.post("/auditor-config")
def post_auditor_config(req: AuditorConfigRequest) -> dict[str, bool]:
    try:
        save_auditor_config(
            auditor=req.auditor,
            cargo_titulo=req.cargo_titulo,
            matricula=req.matricula,
            contato=req.contato,
            orgao_origem=req.orgao_origem,
        )
        return {"ok": True}
    except Exception as exc:
        raise HTTPException(500, f"Erro ao salvar dados do auditor: {exc}") from exc


@router.post("/gerar-notificacao-v2")
def post_gerar_notificacao(req: GerarNotificacaoRequest) -> dict[str, str]:
    try:
        content, filename = generate_notification_txt(
            req.cnpj,
            dsf=req.dsf,
            auditor=req.auditor,
            cargo_titulo=req.cargo_titulo,
            matricula=req.matricula,
            contato=req.contato,
            orgao_origem=req.orgao_origem,
            pdf_base64=req.pdf_base64,
        )
        saved_to = ""
        if req.output_dir.strip():
            saved_to = save_text_output(content, filename, req.output_dir)
        return {"conteudo": content, "nome_arquivo": filename, "salvo_em": saved_to}
    except ValueError as exc:
        raise HTTPException(400, str(exc)) from exc
    except FileNotFoundError as exc:
        raise HTTPException(500, str(exc)) from exc
    except Exception as exc:
        raise HTTPException(500, f"Erro ao gerar notificação: {exc}") from exc


@router.post("/gerar-notificacoes-lote")
def post_gerar_notificacoes_lote(req: GerarNotificacoesLoteRequest):
    try:
        zip_bytes, filename = generate_notifications_zip(
            req.cnpjs,
            dsf=req.dsf,
            auditor=req.auditor,
            cargo_titulo=req.cargo_titulo,
            matricula=req.matricula,
            contato=req.contato,
            orgao_origem=req.orgao_origem,
            pdf_base64=req.pdf_base64,
        )
        headers = {"Content-Disposition": f'attachment; filename="{filename}"'}
        if req.output_dir.strip():
            saved_to = save_binary_output(zip_bytes, filename, req.output_dir)
            if saved_to:
                headers["X-Saved-To"] = saved_to
                headers["X-Saved-Count"] = str(len(req.cnpjs))
        return StreamingResponse(BytesIO(zip_bytes), media_type="application/zip", headers=headers)
    except ValueError as exc:
        raise HTTPException(400, str(exc)) from exc
    except FileNotFoundError as exc:
        raise HTTPException(500, str(exc)) from exc
    except Exception as exc:
        raise HTTPException(500, f"Erro ao gerar lote de notificações: {exc}") from exc


@router.post("/gerar-docx")
def post_gerar_docx(req: GerarNotificacaoRequest):
    try:
        docx_bytes, filename = generate_notification_docx(
            req.cnpj,
            dsf=req.dsf,
            auditor=req.auditor,
            cargo_titulo=req.cargo_titulo,
            matricula=req.matricula,
            contato=req.contato,
            orgao_origem=req.orgao_origem,
            pdf_base64=req.pdf_base64,
        )
        headers = {
            "Content-Disposition": f'attachment; filename="{filename}"',
        }
        if req.output_dir.strip():
            saved_to = save_binary_output(docx_bytes, filename, req.output_dir)
            if saved_to:
                headers["X-Saved-To"] = saved_to
        return StreamingResponse(
            BytesIO(docx_bytes),
            media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            headers=headers,
        )
    except RuntimeError as exc:
        raise HTTPException(500, str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(400, str(exc)) from exc
    except Exception as exc:
        raise HTTPException(500, f"Erro ao gerar DOCX: {exc}") from exc


@router.get("/{cnpj}")
def get_fisconforme(cnpj: str) -> dict:
    return get_fisconforme_overview(cnpj)
