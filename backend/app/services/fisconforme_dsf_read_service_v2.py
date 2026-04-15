from __future__ import annotations

import base64
import json
from pathlib import Path

from backend.app.config import settings


def _state_root() -> Path:
    path = settings.app_state_root / "fisconforme_v2"
    path.mkdir(parents=True, exist_ok=True)
    return path


def _registry_path() -> Path:
    return _state_root() / "dsfs.json"


def _files_root() -> Path:
    path = _state_root() / "dsfs"
    path.mkdir(parents=True, exist_ok=True)
    return path


def _read_registry() -> list[dict]:
    path = _registry_path()
    if not path.exists():
        return []
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
        return raw if isinstance(raw, list) else []
    except Exception:
        return []


def _pdf_path(dsf_id: str, pdf_file_name: str = "") -> Path:
    ext = Path(pdf_file_name).suffix.lower() or ".pdf"
    path = _files_root() / dsf_id
    path.mkdir(parents=True, exist_ok=True)
    return path / f"documento{ext}"


def read_dsf_pdf_base64_v2(dsf_id: str) -> str:
    for item in _read_registry():
        if str(item.get("id", "")) == dsf_id:
            pdf_path = _pdf_path(dsf_id, str(item.get("pdf_file_name", "") or ""))
            if not pdf_path.exists():
                return ""
            return base64.b64encode(pdf_path.read_bytes()).decode("ascii")
    return ""
