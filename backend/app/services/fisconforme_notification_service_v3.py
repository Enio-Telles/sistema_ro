from __future__ import annotations

import base64
import io
from datetime import datetime
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

from backend.app.config import settings
from backend.app.services.fisconforme_dsf_read_service_v2 import read_dsf_pdf_base64_v2
from pipeline.fisconforme.query_service_v2 import read_fisconforme_cache_v2

TEMPLATE_PATH_V3 = settings.workspace_root / "modelo" / "modelo_notificacao_fisconforme_n_atendido.txt"


def _safe_output_dir(output_dir: str) -> Path | None:
    if not output_dir.strip() or ".." in output_dir:
        return None
    target = (settings.workspace_root / output_dir.lstrip("/\\")).resolve()
    if not target.is_relative_to(settings.workspace_root.resolve()):
        return None
    target.mkdir(parents=True, exist_ok=True)
    return target


def _generated_root_v3() -> Path:
    path = settings.app_state_root / "fisconforme_v2" / "generated"
    path.mkdir(parents=True, exist_ok=True)
    return path


def _html_table_v3(malhas: list[dict]) -> str:
    if not malhas:
        return "<p><em>(Sem pendências registradas)</em></p>"
    cols = [
        ("ID Pend.", "id_pendencia"),
        ("ID Notif.", "id_notificacao"),
        ("Título", "titulo_malha"),
        ("Período", "periodo"),
        ("Status", "status_pendencia"),
    ]
    th = "border:1px solid #ccc;padding:4px 8px;background:#f0f0f0;font-family:Arial,sans-serif;font-size:10px;"
    td = "border:1px solid #ccc;padding:4px 8px;font-family:Arial,sans-serif;font-size:10px;"
    parts = ["<table style='border-collapse:collapse;width:100%;'>", "<thead><tr>"]
    for label, _ in cols:
        parts.append(f"<th style='{th}'>{label}</th>")
    parts.append("</tr></thead><tbody>")
    for row in malhas:
        parts.append("<tr>")
        for _, key in cols:
            parts.append(f"<td style='{td}'>{str(row.get(key, '') or '')}</td>")
        parts.append("</tr>")
    parts.append("</tbody></table>")
    return "\n".join(parts)


def _pdf_base64_to_html_images_v3(pdf_base64: str) -> str:
    if not pdf_base64:
        return ""
    try:
        import fitz
    except ImportError:
        return ""
    try:
        pdf_bytes = base64.b64decode(pdf_base64)
        doc = fitz.open(stream=io.BytesIO(pdf_bytes), filetype="pdf")
        images: list[str] = []
        target_width = 547
        target_height = 775
        for page in doc:
            rect = page.rect
            scale_x = target_width / max(rect.width, 1)
            scale_y = target_height / max(rect.height, 1)
            pix = page.get_pixmap(matrix=fitz.Matrix(scale_x, scale_y))
            png_bytes = pix.tobytes("png")
            b64 = base64.b64encode(png_bytes).decode("ascii")
            images.append(
                f'<img src="data:image/png;base64,{b64}" width="{target_width}" height="{target_height}" style="width:{target_width}px;height:{target_height}px;display:block;margin-bottom:10px;" />'
            )
        doc.close()
        return "\n".join(images)
    except Exception:
        return ""


def _resolve_pdf_base64_v3(payload: dict) -> str:
    explicit = str(payload.get("pdf_base64", "") or "")
    if explicit:
        return explicit
    dsf_id = str(payload.get("dsf_id", "") or "")
    if not dsf_id:
        return ""
    return read_dsf_pdf_base64_v2(dsf_id)


def _load_template_v3() -> str:
    if TEMPLATE_PATH_V3.exists():
        return TEMPLATE_PATH_V3.read_text(encoding="utf-8")
    return "{{RAZAO_SOCIAL}}\n{{CNPJ}}\n{{IE}}\n{{DSF}}\n{{AUDITOR}}\n{{CARGO_TITULO}}\n{{MATRICULA}}\n{{CONTATO}}\n{{ORGAO_ORIGEM}}\n{{TABELA}}\n{{DSF_IMAGENS}}"


def build_notification_v3(cnpj: str, payload: dict) -> dict:
    overview = read_fisconforme_cache_v2(cnpj)
    cadastral = list(overview.get("dados_cadastrais", []) or [])
    first = cadastral[0] if cadastral else {}
    razao_social = str(first.get("razao_social", "") or first.get("nome", "") or "")
    ie = str(first.get("ie", "") or "")
    malhas = list(overview.get("malhas", []) or [])
    table_html = _html_table_v3(malhas)
    images_html = _pdf_base64_to_html_images_v3(_resolve_pdf_base64_v3(payload))

    content = _load_template_v3()
    replacements = {
        "{{RAZAO_SOCIAL}}": razao_social,
        "{{CNPJ}}": cnpj,
        "{{IE}}": ie,
        "{{DSF}}": str(payload.get("dsf", "") or ""),
        "{{AUDITOR}}": str(payload.get("auditor", "") or ""),
        "{{CARGO_TITULO}}": str(payload.get("cargo_titulo", "") or ""),
        "{{MATRICULA}}": str(payload.get("matricula", "") or ""),
        "{{CONTATO}}": str(payload.get("contato", "") or ""),
        "{{ORGAO_ORIGEM}}": str(payload.get("orgao_origem", "") or ""),
        "{{TABELA}}": table_html,
        "{{DSF_IMAGENS}}": images_html,
    }
    for key, value in replacements.items():
        content = content.replace(key, value)

    file_name = f"notificacao_det_{cnpj}.txt"
    saved_to = ""
    output_dir = str(payload.get("output_dir", "") or "")
    target_dir = _safe_output_dir(output_dir) if output_dir else _generated_root_v3()
    if target_dir is not None:
        path = target_dir / file_name
        path.write_text(content, encoding="utf-8")
        saved_to = str(path)

    return {
        "cnpj": cnpj,
        "nome_arquivo": file_name,
        "conteudo": content,
        "salvo_em": saved_to,
        "malhas_count": len(malhas),
        "tem_imagens_dsf": bool(images_html),
        "template_externo": str(TEMPLATE_PATH_V3),
    }


def build_notifications_zip_v2(cnpjs: list[str], payload: dict) -> dict:
    generated_root = _generated_root_v3()
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    zip_name = f"notificacoes_fisconforme_{timestamp}.zip"
    zip_path = generated_root / zip_name
    files: list[str] = []

    with ZipFile(zip_path, "w", compression=ZIP_DEFLATED) as zf:
        for cnpj in cnpjs:
            item = build_notification_v3(cnpj, payload)
            zf.writestr(item["nome_arquivo"], item["conteudo"])
            files.append(item["nome_arquivo"])

    extra_saved = ""
    output_dir = str(payload.get("output_dir", "") or "")
    target_dir = _safe_output_dir(output_dir) if output_dir else None
    if target_dir is not None:
        final_path = target_dir / zip_name
        final_path.write_bytes(zip_path.read_bytes())
        extra_saved = str(final_path)

    return {
        "zip_name": zip_name,
        "zip_path": str(zip_path),
        "salvo_em": extra_saved,
        "arquivos": files,
        "total": len(files),
    }
