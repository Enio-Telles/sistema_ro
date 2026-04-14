from __future__ import annotations

import polars as pl


def _ensure_columns(df: pl.DataFrame, defaults: dict[str, object]) -> pl.DataFrame:
    result = df
    for col, value in defaults.items():
        if col not in result.columns:
            if isinstance(value, float):
                result = result.with_columns(pl.lit(value, dtype=pl.Float64).alias(col))
            else:
                result = result.with_columns(pl.lit(value).alias(col))
    return result


def _normalize_source(df: pl.DataFrame, source: str) -> pl.DataFrame:
    if df.is_empty():
        return df
    defaults = {
        "id_agrupado": "",
        "codigo_fonte": "",
        "id_linha_origem": "",
        "codigo_produto_original": "",
        "descr_item": "",
        "descr_compl": "",
        "ncm": "",
        "cest": "",
        "gtin_padrao": "",
        "unid": "UN",
        "qtd": 0.0,
        "vl_item": 0.0,
        "dt_doc": None,
        "dt_e_s": None,
    }
    result = _ensure_columns(df, defaults)
    return result.select([
        "id_agrupado",
        "codigo_fonte",
        "id_linha_origem",
        "codigo_produto_original",
        "descr_item",
        "descr_compl",
        "ncm",
        "cest",
        "gtin_padrao",
        "unid",
        "qtd",
        "vl_item",
        "dt_doc",
        "dt_e_s",
    ]).with_columns(pl.lit(source).alias("fonte_item"))


def build_itens_unificados(
    c170_df: pl.DataFrame,
    nfe_df: pl.DataFrame,
    nfce_df: pl.DataFrame,
    bloco_h_df: pl.DataFrame | None = None,
) -> pl.DataFrame:
    frames: list[pl.DataFrame] = []
    for df, source in [
        (c170_df, "c170"),
        (nfe_df, "nfe"),
        (nfce_df, "nfce"),
        (bloco_h_df if bloco_h_df is not None else pl.DataFrame(), "bloco_h"),
    ]:
        normalized = _normalize_source(df, source)
        if not normalized.is_empty():
            frames.append(normalized)
    if not frames:
        return pl.DataFrame()
    return pl.concat(frames, how="diagonal_relaxed")
