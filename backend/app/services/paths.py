from __future__ import annotations

from pathlib import Path

from backend.app.config import settings


def cnpj_dir(cnpj: str) -> Path:
    path = settings.cnpj_root / cnpj
    path.mkdir(parents=True, exist_ok=True)
    return path


def bronze_dir(cnpj: str) -> Path:
    path = cnpj_dir(cnpj) / "bronze"
    path.mkdir(parents=True, exist_ok=True)
    return path


def silver_dir(cnpj: str) -> Path:
    path = cnpj_dir(cnpj) / "silver"
    path.mkdir(parents=True, exist_ok=True)
    return path


def gold_dir(cnpj: str) -> Path:
    path = cnpj_dir(cnpj) / "gold"
    path.mkdir(parents=True, exist_ok=True)
    return path


def fisconforme_dir(cnpj: str) -> Path:
    path = cnpj_dir(cnpj) / "fisconforme"
    path.mkdir(parents=True, exist_ok=True)
    return path


def reference_dir() -> Path:
    path = settings.workspace_root / "references"
    path.mkdir(parents=True, exist_ok=True)
    return path
