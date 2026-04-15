from __future__ import annotations

import base64
import json
import re
from datetime import datetime
from pathlib import Path
from typing import Any
from uuid import uuid4

from backend.app.config import settings


def _fisconforme_state_root_v2() -> Path:
    path = settings.app_state_root / "fisconforme_v2"
    path.mkdir(parents=True, exist_ok=True)
    return path


def _dsf_registry_path_v2() -> Path:
    return _fisconforme_state_root_v2() / "dsfs.json"


def _dsf_files_root_v2() -> Path:
    path = _fisconforme_state_root_v2() / "dsfs"
    path.mkdir(parents=True, exist_ok=True)
    return path


def _normalize_cnpjs_v2(cnpjs: list[str]) -> list[str]:
    seen: set[str] = set()
    result: list[str] = []
    for item in cnpjs:
        cnpj = re.sub(r"\D", "", item or "")
        if not cnpj or cnpj in seen:
            continue
        seen.add(cnpj)
        result.append(cnpj)
    return result


def _read_registry_v2() -> list[dict[str, Any]]:
    path = _dsf_registry_path_v2()
    if not path.exists():
        return []
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
        return raw if isinstance(raw, list) else []
    except Exception:
        return []


def _write_registry_v2(items: list[dict[str, Any]]) -> None:
    path = _dsf_registry_path_v2()
    path.write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding="utf-8")


def _pdf_path_v2(dsf_id: str, pdf_file_name: str = "") -> Path:
    ext = Path(pdf_file_name).suffix.lower() or ".pdf"
    path = _dsf_files_root_v2() / dsf_id
    path.mkdir(parents=True, exist_ok=True)
    return path / f"documento{ext}"


def _summary_v2(item: dict[str, Any]) -> dict[str, Any]:
    pdf_path = _pdf_path_v2(str(item.get("id", "")), str(item.get("pdf_file_name", "") or ""))
    return {
        "id": str(item.get("id", "") or ""),
        "dsf": str(item.get("dsf", "") or ""),
        "referencia": str(item.get("referencia", "") or ""),
        "auditor": str(item.get("auditor", "") or ""),
        "cargo_titulo": str(item.get("cargo_titulo", "") or ""),
        "orgao_origem": str(item.get("orgao_origem", "") or ""),
        "output_dir": str(item.get("output_dir", "") or ""),
        "cnpjs": list(item.get("cnpjs", []) or []),
        "cnpjs_count": len(list(item.get("cnpjs", []) or [])),
        "data_inicio": str(item.get("data_inicio", "01/2021") or "01/2021"),
        "data_fim": str(item.get("data_fim", "12/2025") or "12/2025"),
        "updated_at": str(item.get("updated_at", "") or ""),
        "created_at": str(item.get("created_at", "") or ""),
        "pdf_file_name": str(item.get("pdf_file_name", "") or ""),
        "pdf_disponivel": pdf_path.exists(),
    }


def list_dsfs_v2() -> dict:
    return {"items": [_summary_v2(item) for item in _read_registry_v2()]}


def get_dsf_v2(dsf_id: str) -> dict:
    for item in _read_registry_v2():
        if str(item.get("id", "")) == dsf_id:
            result = _summary_v2(item)
            result.update(
                {
                    "matricula": str(item.get("matricula", "") or ""),
                    "contato": str(item.get("contato", "") or ""),
                    "forcar_atualizacao": bool(item.get("forcar_atualizacao", False)),
                }
            )
            return result
    return {"error": "dsf_nao_encontrada", "id": dsf_id}


def save_dsf_v2(payload: dict[str, Any]) -> dict:
    items = _read_registry_v2()
    existing = None
    if payload.get("id"):
        for item in items:
            if str(item.get("id", "")) == str(payload["id"]):
                existing = item
                break

    dsf_id = str((existing or {}).get("id") or payload.get("id") or uuid4())
    now = datetime.now().isoformat()
    record = {
        "id": dsf_id,
        "dsf": str(payload.get("dsf", "") or "").strip(),
        "referencia": str(payload.get("referencia", "") or "").strip(),
        "cnpjs": _normalize_cnpjs_v2(list(payload.get("cnpjs", []) or [])),
        "data_inicio": str(payload.get("data_inicio", "01/2021") or "01/2021"),
        "data_fim": str(payload.get("data_fim", "12/2025") or "12/2025"),
        "forcar_atualizacao": bool(payload.get("forcar_atualizacao", False)),
        "auditor": str(payload.get("auditor", "") or "").strip(),
        "cargo_titulo": str(payload.get("cargo_titulo", "") or "").strip(),
        "matricula": str(payload.get("matricula", "") or "").strip(),
        "contato": str(payload.get("contato", "") or "").strip(),
        "orgao_origem": str(payload.get("orgao_origem", "") or "").strip(),
        "output_dir": str(payload.get("output_dir", "") or "").strip(),
        "pdf_file_name": str(payload.get("pdf_file_name", "") or (existing or {}).get("pdf_file_name", "") or "").strip(),
        "created_at": str((existing or {}).get("created_at", "") or now),
        "updated_at": now,
    }

    pdf_base64 = payload.get("pdf_base64")
    if pdf_base64 is not None:
        pdf_path = _pdf_path_v2(dsf_id, record["pdf_file_name"])
        if str(pdf_base64).strip():
            pdf_path.write_bytes(base64.b64decode(str(pdf_base64)))
        elif pdf_path.exists():
            pdf_path.unlink()

    items = [item for item in items if str(item.get("id", "")) != dsf_id]
    items.append(record)
    items = sorted(items, key=lambda item: str(item.get("updated_at", "")), reverse=True)
    _write_registry_v2(items)

    result = _summary_v2(record)
    result.update(
        {
            "matricula": record["matricula"],
            "contato": record["contato"],
            "forcar_atualizacao": record["forcar_atualizacao"],
        }
    )
    return result
