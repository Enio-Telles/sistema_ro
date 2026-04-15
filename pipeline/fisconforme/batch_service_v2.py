from __future__ import annotations

from typing import Callable

import polars as pl

from pipeline.fisconforme.query_service_v2 import FisconformeProvider, limpar_cnpj_fisconforme, query_fisconforme_v2


def query_fisconforme_batch_v2(
    cnpjs: list[str],
    provider: FisconformeProvider | None = None,
    force_refresh: bool = False,
) -> dict:
    resultados = []
    vistos: set[str] = set()
    for item in cnpjs:
        cnpj = limpar_cnpj_fisconforme(item)
        if not cnpj or cnpj in vistos:
            continue
        vistos.add(cnpj)
        resultados.append(query_fisconforme_v2(cnpj, provider=provider, force_refresh=force_refresh))
    return {
        "total": len(resultados),
        "resultados": resultados,
    }
