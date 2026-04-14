from __future__ import annotations

import polars as pl


def project_sefin_fields(df: pl.DataFrame) -> pl.DataFrame:
    if df.is_empty():
        return df

    result = df

    def _coalesce_if_missing(target: str, candidates: list[str]) -> None:
        nonlocal result
        available = [pl.col(c) for c in candidates if c in result.columns]
        if not available:
            return
        if target in result.columns:
            result = result.with_columns(pl.coalesce([pl.col(target), *available]).alias(target))
        else:
            result = result.with_columns(pl.coalesce(available).alias(target))

    _coalesce_if_missing("co_sefin_agr", ["co_sefin_final", "co_sefin_inferido", "co_sefin"])
    _coalesce_if_missing("co_sefin_final", ["co_sefin_agr", "co_sefin_inferido", "co_sefin"])
    _coalesce_if_missing("it_pc_interna", ["aliq_interna"])
    _coalesce_if_missing("it_in_st", [])
    _coalesce_if_missing("it_pc_mva", [])
    _coalesce_if_missing("it_in_mva_ajustado", [])
    _coalesce_if_missing("it_pc_reducao", [])
    _coalesce_if_missing("it_in_reducao_credito", [])

    return result
