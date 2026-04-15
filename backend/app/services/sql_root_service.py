from __future__ import annotations

from pathlib import Path

from backend.app.config import settings


def get_sql_root() -> Path:
    return settings.workspace_root / "sql"
