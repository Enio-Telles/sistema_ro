from __future__ import annotations

import polars as pl


SOURCE_COLS = [
    "cnpj",
    "id_linha_origem",
    "codigo_fonte",
    "codigo_produto_original",
    "descr_item",
    "descr_compl",
    "tipo_item",
    "ncm",
    "cest",
    "gtin_padrao",
    "unid",
]


def _ensure_utf8_expr(df: pl.DataFrame, col: str) -> pl.Expr:
    if col in df.columns:
        return pl.col(col).cast(pl.Utf8, strict=False).fill_null("").alias(col)
    return pl.lit("").alias(col)


def _normalize_source_rows(df: pl.DataFrame, *, source_prefix: str) -> pl.DataFrame:
    if df.is_empty():
        return pl.DataFrame(schema={col: pl.Utf8 for col in SOURCE_COLS})

    result = df.with_row_index("__row_nr__")
    result = result.with_columns(*[_ensure_utf8_expr(result, col) for col in [c for c in SOURCE_COLS if c not in {"id_linha_origem", "codigo_fonte"}]])
    result = result.with_columns(
        pl.when(pl.col("id_linha_origem").cast(pl.Utf8, strict=False).fill_null("") == "")
        .then(pl.concat_str([pl.lit(source_prefix), pl.lit("|"), pl.col("codigo_produto_original"), pl.lit("|"), pl.col("__row_nr__").cast(pl.Utf8)]))
        .otherwise(pl.col("id_linha_origem").cast(pl.Utf8, strict=False))
        .alias("id_linha_origem"),
        pl.when(pl.col("codigo_fonte").cast(pl.Utf8, strict=False).fill_null("") == "")
        .then(pl.concat_str([pl.col("cnpj"), pl.lit("|"), pl.col("codigo_produto_original")]))
        .otherwise(pl.col("codigo_fonte").cast(pl.Utf8, strict=False))
        .alias("codigo_fonte"),
    )
    for col in SOURCE_COLS:
        if col not in result.columns:
            result = result.with_columns(pl.lit("").alias(col))
    return result.select(SOURCE_COLS)


def _build_map_lookup(map_produto_agrupado_df: pl.DataFrame) -> pl.DataFrame:
    if map_produto_agrupado_df.is_empty():
        return pl.DataFrame()
    keep = [col for col in ["codigo_fonte", "id_agrupado", "descricao_normalizada"] if col in map_produto_agrupado_df.columns]
    if not keep:
        return pl.DataFrame()
    return map_produto_agrupado_df.select(keep).unique(subset=["codigo_fonte"] if "codigo_fonte" in keep else None)


def _build_produtos_lookup(produtos_final_df: pl.DataFrame) -> pl.DataFrame:
    if produtos_final_df.is_empty() or "id_agrupado" not in produtos_final_df.columns:
        return pl.DataFrame()
    keep = [col for col in ["id_agrupado", "descr_padrao", "ncm_padrao", "cest_padrao", "gtin_padrao", "unid_ref"] if col in produtos_final_df.columns]
    return produtos_final_df.select(keep).unique(subset=["id_agrupado"])


def _enrich_with_agregacao(df: pl.DataFrame, *, map_lookup_df: pl.DataFrame, produtos_lookup_df: pl.DataFrame) -> tuple[pl.DataFrame, pl.DataFrame]:
    if df.is_empty():
        empty = df.with_columns(pl.lit("").alias("id_agrupado")) if "id_agrupado" not in df.columns else df
        return empty, empty

    result = df
    if not map_lookup_df.is_empty() and "codigo_fonte" in result.columns and "codigo_fonte" in map_lookup_df.columns:
        result = result.join(map_lookup_df, on="codigo_fonte", how="left")
    if not produtos_lookup_df.is_empty() and "id_agrupado" in result.columns:
        result = result.join(produtos_lookup_df, on="id_agrupado", how="left", suffix="_agr")

    if "id_agrupado" not in result.columns:
        result = result.with_columns(pl.lit("").alias("id_agrupado"))

    for col in ["descr_padrao", "ncm_padrao", "cest_padrao", "unid_ref"]:
        if col not in result.columns:
            result = result.with_columns(pl.lit("").alias(col))
    if "gtin_padrao_agr" not in result.columns:
        if "gtin_padrao" in produtos_lookup_df.columns and "gtin_padrao" in result.columns:
            result = result.rename({"gtin_padrao": "gtin_padrao_agr"})
        else:
            result = result.with_columns(pl.lit("").alias("gtin_padrao_agr"))

    result = result.with_columns(
        pl.col("id_agrupado").cast(pl.Utf8, strict=False).fill_null("").alias("id_agrupado"),
        pl.col("descr_padrao").cast(pl.Utf8, strict=False).fill_null("").alias("descr_padrao"),
        pl.col("ncm_padrao").cast(pl.Utf8, strict=False).fill_null("").alias("ncm_padrao"),
        pl.col("cest_padrao").cast(pl.Utf8, strict=False).fill_null("").alias("cest_padrao"),
        pl.col("gtin_padrao_agr").cast(pl.Utf8, strict=False).fill_null("").alias("gtin_padrao_agr"),
        pl.col("unid_ref").cast(pl.Utf8, strict=False).fill_null("").alias("unid_ref"),
    )

    ok_df = result.filter(pl.col("id_agrupado") != "")
    sem_df = result.filter(pl.col("id_agrupado") == "")
    return ok_df, sem_df


def build_fontes_agr(
    *,
    c170_df: pl.DataFrame,
    nfe_df: pl.DataFrame,
    nfce_df: pl.DataFrame,
    bloco_h_df: pl.DataFrame,
    map_produto_agrupado_df: pl.DataFrame,
    produtos_final_df: pl.DataFrame,
) -> dict[str, pl.DataFrame]:
    map_lookup_df = _build_map_lookup(map_produto_agrupado_df)
    produtos_lookup_df = _build_produtos_lookup(produtos_final_df)

    c170_ok, c170_sem = _enrich_with_agregacao(
        _normalize_source_rows(c170_df, source_prefix="c170"),
        map_lookup_df=map_lookup_df,
        produtos_lookup_df=produtos_lookup_df,
    )
    nfe_ok, nfe_sem = _enrich_with_agregacao(
        _normalize_source_rows(nfe_df, source_prefix="nfe"),
        map_lookup_df=map_lookup_df,
        produtos_lookup_df=produtos_lookup_df,
    )
    nfce_ok, nfce_sem = _enrich_with_agregacao(
        _normalize_source_rows(nfce_df, source_prefix="nfce"),
        map_lookup_df=map_lookup_df,
        produtos_lookup_df=produtos_lookup_df,
    )
    bloco_h_ok, bloco_h_sem = _enrich_with_agregacao(
        _normalize_source_rows(bloco_h_df, source_prefix="bloco_h"),
        map_lookup_df=map_lookup_df,
        produtos_lookup_df=produtos_lookup_df,
    )

    return {
        "c170_agr": c170_ok,
        "c170_agr_sem_id_agrupado": c170_sem,
        "nfe_agr": nfe_ok,
        "nfe_agr_sem_id_agrupado": nfe_sem,
        "nfce_agr": nfce_ok,
        "nfce_agr_sem_id_agrupado": nfce_sem,
        "bloco_h_agr": bloco_h_ok,
        "bloco_h_agr_sem_id_agrupado": bloco_h_sem,
    }
