from __future__ import annotations

from backend.app.config import settings
from pipeline.fisconforme.cache import fisconforme_cache_path
from pipeline.fisconforme.contracts_v2 import get_dataset_name_v2
from pipeline.fisconforme.query_service_v2 import limpar_cnpj_fisconforme


def get_fisconforme_cache_stats_v2() -> dict:
    cnpj_root = settings.cnpj_root
    items = []
    if cnpj_root.exists():
        for cnpj_dir in cnpj_root.iterdir():
            if not cnpj_dir.is_dir():
                continue
            cnpj = cnpj_dir.name
            items.append(
                {
                    "cnpj": cnpj,
                    "tem_cadastral": fisconforme_cache_path(cnpj, get_dataset_name_v2("cadastral")).exists(),
                    "tem_malhas": fisconforme_cache_path(cnpj, get_dataset_name_v2("malhas")).exists(),
                }
            )
    return {
        "total_cnpjs_cached": len(items),
        "cnpjs": items,
    }
