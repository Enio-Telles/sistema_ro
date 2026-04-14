from __future__ import annotations

import polars as pl

from pipeline.fisconforme.cache import load_cache, save_cache
from pipeline.fisconforme.normalization import normalize_fisconforme_cadastral, normalize_fisconforme_malhas


def read_fisconforme_result(cnpj: str) -> dict:
    cadastral = load_cache(cnpj, "fisconforme_cadastral")
    malhas = load_cache(cnpj, "fisconforme_malhas")
    return {
        "cnpj": cnpj,
        "dados_cadastrais": [] if cadastral is None else cadastral.to_dicts(),
        "malhas": [] if malhas is None else malhas.to_dicts(),
        "from_cache_cadastral": cadastral is not None,
        "from_cache_malhas": malhas is not None,
    }


def write_fisconforme_cadastral(cnpj: str, df: pl.DataFrame):
    normalized = normalize_fisconforme_cadastral(df)
    return save_cache(normalized, cnpj, "fisconforme_cadastral")


def write_fisconforme_malhas(cnpj: str, df: pl.DataFrame):
    normalized = normalize_fisconforme_malhas(df)
    return save_cache(normalized, cnpj, "fisconforme_malhas")
