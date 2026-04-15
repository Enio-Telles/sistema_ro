from __future__ import annotations

from pipeline.fisconforme.batch_service_v2 import query_fisconforme_batch_v2
from pipeline.fisconforme.query_service_v2 import query_fisconforme_v2


def get_fisconforme_cache_overview_v2(cnpj: str) -> dict:
    return query_fisconforme_v2(cnpj, provider=None, force_refresh=False)


def get_fisconforme_batch_cache_overview_v2(cnpjs: list[str]) -> dict:
    return query_fisconforme_batch_v2(cnpjs, provider=None, force_refresh=False)
