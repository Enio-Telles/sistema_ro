from __future__ import annotations

from pathlib import Path

from backend.app.config import settings
from backend.app.services.fisconforme_dsf_service_v2 import get_dsf_v2
from pipeline.fisconforme.query_service_v2 import read_fisconforme_cache_v2

DEFAULT_TEMPLATE_V2 = """
NOTIFICAÇÃO FISCONFORME NÃO ATENDIDO

Razão Social: {{RAZAO_SOCIAL}}
CNPJ: {{CNPJ}}
IE: {{IE}}
DSF: {{DSF}}
Auditor: {{AUDITOR}}
Cargo/Título: {{CARGO_TITULO}}
Matrícula: {{MATRICULA}}
Contato: {{CONTATO}}
Órgão de origem: {{ORGAO_ORIGEM}}

Pendências:
{{TABELA}}
""".strip()


def _safe_output_dir(output_dir: str) -> Path | None:
    if not output_dir.strip() or ".." in output_dir:
        return None
    target = (settings.workspace_root / output_dir.lstrip("/\\")).resolve()
    if not target.is_relative_to(settings.workspace_root.resolve()):
        return None
    target.mkdir(parents=True, exist_ok=True)
    return target


def _table_text_v2(malhas: list[dict]) -> str:
    if not malhas:
        return "(Sem pendências registradas)"
    lines = []
    for item in malhas:
        lines.append(
            " | ".join(
                [
                    str(item.get("id_pendencia", "") or ""),
                    str(item.get("id_notificacao", "") or ""),
                    str(item.get("titulo_malha", "") or ""),
                    str(item.get("periodo", "") or ""),
                    str(item.get("status_pendencia", "") or ""),
                ]
            )
        )
    return "\n".join(lines)


def _resolve_output_dir(output_dir: str, dsf_id: str | None) -> str:
    if output_dir.strip():
        return output_dir.strip()
    if not dsf_id:
        return ""
    dsf = get_dsf_v2(dsf_id)
    if dsf.get("error"):
        return ""
    return str(dsf.get("output_dir", "") or "")


def build_notification_v2(cnpj: str, payload: dict) -> dict:
    overview = read_fisconforme_cache_v2(cnpj)
    cadastral = overview.get("dados_cadastrais", [])
    first = cadastral[0] if cadastral else {}
    razao_social = str(first.get("razao_social", "") or first.get("nome", "") or "")
    ie = str(first.get("ie", "") or "")
    malhas = list(overview.get("malhas", []) or [])
    dsf_id = str(payload.get("dsf_id", "") or "")
    output_dir = _resolve_output_dir(str(payload.get("output_dir", "") or ""), dsf_id or None)

    content = DEFAULT_TEMPLATE_V2
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
        "{{TABELA}}": _table_text_v2(malhas),
    }
    for key, value in replacements.items():
        content = content.replace(key, value)

    file_name = f"notificacao_det_{cnpj}.txt"
    saved_to = ""
    target_dir = _safe_output_dir(output_dir) if output_dir else None
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
    }
