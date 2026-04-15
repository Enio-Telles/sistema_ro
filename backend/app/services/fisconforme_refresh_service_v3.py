from __future__ import annotations

from backend.app.config import settings
from backend.app.services.sql_root_service import get_sql_root
from pipeline.fisconforme.batch_service_v2 import query_fisconforme_batch_v2
from pipeline.fisconforme.provider_oracle_v2 import build_oracle_provider_v2
from pipeline.fisconforme.query_service_v2 import query_fisconforme_v2


def _provider_or_none_v3(data_inicio: str = "01/2021", data_fim: str = "12/2025"):
    sql_root = get_sql_root()
    if not sql_root.exists():
        return None
    secret = getattr(settings, "db_password", "")
    if not all([settings.oracle_host, settings.oracle_service, settings.db_user, secret]):
        return None
    return build_oracle_provider_v2(
        host=settings.oracle_host,
        port=settings.oracle_port,
        service=settings.oracle_service,
        user=settings.db_user,
        secret=secret,
        sql_root=sql_root,
        data_inicio=data_inicio,
        data_fim=data_fim,
    )


def refresh_fisconforme_v3(cnpj: str, data_inicio: str = "01/2021", data_fim: str = "12/2025") -> dict:
    provider = _provider_or_none_v3(data_inicio=data_inicio, data_fim=data_fim)
    if provider is None:
        result = query_fisconforme_v2(cnpj, provider=None, force_refresh=False)
        result["provider_status"] = "unavailable"
        return result
    result = query_fisconforme_v2(cnpj, provider=provider, force_refresh=True)
    result["provider_status"] = "oracle_sql_runner"
    return result


def refresh_fisconforme_batch_v3(cnpjs: list[str], data_inicio: str = "01/2021", data_fim: str = "12/2025") -> dict:
    provider = _provider_or_none_v3(data_inicio=data_inicio, data_fim=data_fim)
    if provider is None:
        result = query_fisconforme_batch_v2(cnpjs, provider=None, force_refresh=False)
        result["provider_status"] = "unavailable"
        return result
    result = query_fisconforme_batch_v2(cnpjs, provider=provider, force_refresh=True)
    result["provider_status"] = "oracle_sql_runner"
    return result
