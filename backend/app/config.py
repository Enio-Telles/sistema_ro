from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Settings:
    app_env: str = os.getenv("APP_ENV", "dev")
    app_state_root: Path = Path(os.getenv("APP_STATE_ROOT", "./state"))
    workspace_root: Path = Path(os.getenv("WORKSPACE_ROOT", "./workspace"))
    cnpj_root: Path = Path(os.getenv("CNPJ_ROOT", "./dados/CNPJ"))
    oracle_host: str = os.getenv("ORACLE_HOST", "")
    oracle_port: int = int(os.getenv("ORACLE_PORT", "1521"))
    oracle_service: str = os.getenv("ORACLE_SERVICE", "")
    db_user: str = os.getenv("DB_USER", "")
    db_password: str = os.getenv("DB_PASSWORD", "")

    def ensure_directories(self) -> None:
        self.app_state_root.mkdir(parents=True, exist_ok=True)
        self.workspace_root.mkdir(parents=True, exist_ok=True)
        self.cnpj_root.mkdir(parents=True, exist_ok=True)


settings = Settings()
