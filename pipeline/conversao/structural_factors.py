from __future__ import annotations

import re

import polars as pl


MULTIPLIER_PATTERNS = [
    re.compile(r"(\d+)\s*[xX]\s*(\d+[\.,]?\d*)"),
    re.compile(r"C\/?\s*(\d+)"),
    re.compile(r"CX\s*(\d+)"),
    re.compile(r"FD\s*(\d+)"),
]


def _extract_multiplier(text: str) -> float | None:
    if not text:
        return None
    raw = text.upper().replace(",", ".")
    for pattern in MULTIPLIER_PATTERNS:
        match = pattern.search(raw)
        if not match:
            continue
        groups = match.groups()
        if len(groups) == 2:
            try:
                return float(groups[0])
            except Exception:
                return None
        if len(groups) == 1:
            try:
                return float(groups[0])
            except Exception:
                return None
    return None


def infer_structural_factors(itens_df: pl.DataFrame) -> pl.DataFrame:
    if itens_df.is_empty():
        return pl.DataFrame()

    df = itens_df.with_columns(
        pl.concat_str([
            pl.col("descr_item").cast(pl.Utf8, strict=False).fill_null(""),
            pl.lit(" "),
            pl.col("descr_compl").cast(pl.Utf8, strict=False).fill_null(""),
        ]).alias("texto_mercadoria")
    ).with_columns(
        pl.col("texto_mercadoria").map_elements(_extract_multiplier, return_dtype=pl.Float64).alias("fator_estrutural_inferido")
    )

    grouped = df.group_by([c for c in ["id_agrupado", "unid"] if c in df.columns]).agg(
        pl.col("fator_estrutural_inferido").drop_nulls().median().alias("fator_estrutural"),
        pl.col("texto_mercadoria").drop_nulls().first().alias("exemplo_texto"),
        pl.len().alias("linhas_base"),
    )

    return grouped.with_columns(
        pl.when(pl.col("fator_estrutural").is_not_null()).then(pl.lit("estrutural")).otherwise(pl.lit(None)).alias("tipo_fator_estrutural"),
        pl.when(pl.col("fator_estrutural").is_not_null()).then(pl.lit(0.9)).otherwise(pl.lit(None)).alias("confianca_estrutural"),
        pl.when(pl.col("fator_estrutural").is_not_null()).then(pl.lit("regex_embalagem_conteudo")).otherwise(pl.lit(None)).alias("fonte_estrutural"),
    )
