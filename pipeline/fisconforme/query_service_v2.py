from __future__ import annotations

import re
from typing import Callable

import polars as pl

from pipeline.fisconforme.cache import load_cache, save_cache
from pipeline.fisconforme.contracts_v2 import empty_overview_v2, get_dataset_name_v2
from pipeline.fisconforme.normalization import normalize_fisconforme_cadastral, normalize_fisconforme_malhas

FisconformeProvider = Callable[[str], tuple[pl.DataFrame, pl.DataFrame]]


def limpar_cnpj_fisconforme(cnpj: str) -> str:
    return re.sub(r"\D", "", cnpj or "")


def validar_cnpj_tamanho(cnpj: str) -> bool:
    return len(limpar_cnpj_fisconforme(cnpj)) == 14


def read_fisconforme_cache_v2(cnpj: str) -> dict:
    cnpj = limpar_cnpj_fisconforme(cnpj)
    if not cnpj:
        return empty_overview_v2("")
    cadastral = load_cache(cnpj, get_dataset_name_v2("cadastral"))
    malhas = load_cache(cnpj, get_dataset_name_v2("malhas"))
    return {
        "cnpj": cnpj,
        "dados_cadastrais": [] if cadastral is None else cadastral.to_dicts(),
        "malhas": [] if malhas is None else malhas.to_dicts(),
        "from_cache_cadastral": cadastral is not None,
        "from_cache_malhas": malhas is not None,
    }


def write_fisconforme_cache_v2(cnpj: str, cadastral_df: pl.DataFrame, malhas_df: pl.DataFrame) -> dict:
    cnpj = limpar_cnpj_fisconforme(cnpj)
    cadastral = normalize_fisconforme_cadastral(cadastral_df) if not cadastral_df.is_empty() else pl.DataFrame()
    malhas = normalize_fisconforme_malhas(malhas_df) if not malhas_df.is_empty() else pl.DataFrame()
    cadastral_path = save_cache(cadastral, cnpj, get_dataset_name_v2("cadastral"))
    malhas_path = save_cache(malhas, cnpj, get_dataset_name_v2("malhas"))
    return {
        "cnpj": cnpj,
        "cadastral_path": str(cadastral_path),
        "malhas_path": str(malhas_path),
        "rows_cadastral": cadastral.height,
        "rows_malhas": malhas.height,
    }


def query_fisconforme_v2(cnpj: str, provider: FisconformeProvider | None = None, force_refresh: bool = False) -> dict:
    cnpj = limpar_cnpj_fisconforme(cnpj)
    if not validar_cnpj_tamanho(cnpj):
        return {
            "cnpj": cnpj,
            "error": "cnpj_invalido",
            **empty_overview_v2(cnpj),
        }

    if not force_refresh:
        cached = read_fisconforme_cache_v2(cnpj)
        if cached["from_cache_cadastral"] or cached["from_cache_malhas"]:
            cached["source"] = "cache"
            return cached

    if provider is None:
        result = read_fisconforme_cache_v2(cnpj)
        result["source"] = "cache_only"
        return result

    cadastral_df, malhas_df = provider(cnpj)
    write_info = write_fisconforme_cache_v2(cnpj, cadastral_df, malhas_df)
    result = read_fisconforme_cache_v2(cnpj)
    result["source"] = "provider"
    result["write_info"] = write_info
    return result
