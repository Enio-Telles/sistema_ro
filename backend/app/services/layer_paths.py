from __future__ import annotations

from pathlib import Path

from backend.app.config import settings


OPERATIONAL_LAYERS = {
    "mdc_base",
    "agregacao",
    "fontes_agr",
    "gold_produtos",
}


def operational_layer_dir(cnpj: str, layer: str) -> Path:
    if layer not in OPERATIONAL_LAYERS:
        raise ValueError(f"Camada operacional desconhecida: {layer}")
    path = settings.cnpj_root / cnpj / layer
    path.mkdir(parents=True, exist_ok=True)
    return path
