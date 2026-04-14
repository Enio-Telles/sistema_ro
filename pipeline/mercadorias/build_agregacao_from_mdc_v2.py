from __future__ import annotations

import polars as pl

from pipeline.mercadorias.mercadoria_pipeline_v2 import run_mercadoria_v2


REQUIRED_COLS = [
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


def _product_lookup(produtos_base_df: pl.DataFrame) -> pl.DataFrame:
    if produtos_base_df.is_empty():
        return pl.DataFrame()
    keep = [col for col in REQUIRED_COLS if col in produtos_base_df.columns and col not in {"id_linha_origem", "codigo_fonte"}]
    lookup = produtos_base_df.select(keep)
    subset = [col for col in ["cnpj", "codigo_produto_original"] if col in lookup.columns]
    return lookup.unique(subset=subset) if subset else lookup.unique()


def _ensure_utf8(result: pl.DataFrame, col: str) -> pl.Expr:
    if col in result.columns:
        return pl.col(col).cast(pl.Utf8, strict=False).fill_null("").alias(col)
    return pl.lit("").alias(col)


def _normalize_rows(df: pl.DataFrame, *, source_prefix: str, produtos_lookup_df: pl.DataFrame) -> pl.DataFrame:
    if df.is_empty():
        return pl.DataFrame(schema={col: pl.Utf8 for col in REQUIRED_COLS})

    result = df.with_row_index("__row_nr__")
    join_keys = [col for col in ["cnpj", "codigo_produto_original"] if col in result.columns and col in produtos_lookup_df.columns]
    if join_keys and not produtos_lookup_df.is_empty():
        enrich_cols = join_keys + [col for col in ["descr_item", "descr_compl", "tipo_item", "ncm", "cest", "gtin_padrao", "unid"] if col in produtos_lookup_df.columns]
        result = result.join(produtos_lookup_df.select(enrich_cols), on=join_keys, how="left", suffix="_prod")

    for col in ["descr_item", "descr_compl", "tipo_item", "ncm", "cest", "gtin_padrao", "unid"]:
        prod_col = f"{col}_prod"
        if prod_col in result.columns:
            result = result.with_columns(pl.coalesce([pl.col(col).cast(pl.Utf8, strict=False) if col in result.columns else pl.lit(None), pl.col(prod_col).cast(pl.Utf8, strict=False)]).fill_null("").alias(col))

    result = result.with_columns(
        _ensure_utf8(result, "cnpj"),
        _ensure_utf8(result, "codigo_produto_original"),
        _ensure_utf8(result, "descr_item"),
        _ensure_utf8(result, "descr_compl"),
        _ensure_utf8(result, "tipo_item"),
        _ensure_utf8(result, "ncm"),
        _ensure_utf8(result, "cest"),
        _ensure_utf8(result, "gtin_padrao"),
        _ensure_utf8(result, "unid"),
    )

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

    for col in REQUIRED_COLS:
        if col not in result.columns:
            result = result.with_columns(pl.lit("").alias(col))

    return result.select(REQUIRED_COLS)


def _enrich_produtos_final(outputs: dict[str, pl.DataFrame], produtos_lookup_df: pl.DataFrame) -> dict[str, pl.DataFrame]:
    if outputs["produtos_final"].is_empty() or produtos_lookup_df.is_empty() or outputs["map_produto_agrupado"].is_empty():
        return outputs
    join_keys = [col for col in ["cnpj", "codigo_produto_original"] if col in outputs["map_produto_agrupado"].columns and col in produtos_lookup_df.columns]
    if not join_keys:
        return outputs
    map_enriched = outputs["map_produto_agrupado"].join(
        produtos_lookup_df.select(join_keys + [col for col in ["gtin_padrao", "unid"] if col in produtos_lookup_df.columns]),
        on=join_keys,
        how="left",
        suffix="_prod",
    )
    agg_exprs = []
    if "gtin_padrao_prod" in map_enriched.columns:
        agg_exprs.append(pl.col("gtin_padrao_prod").drop_nulls().first().alias("gtin_padrao_enriched"))
    if "unid_prod" in map_enriched.columns:
        agg_exprs.append(pl.col("unid_prod").drop_nulls().first().alias("unid_ref_enriched"))
    if not agg_exprs:
        return outputs
    enrich = map_enriched.group_by("id_agrupado").agg(agg_exprs)
    outputs["produtos_final"] = outputs["produtos_final"].join(enrich, on="id_agrupado", how="left")
    if "gtin_padrao_enriched" in outputs["produtos_final"].columns:
        outputs["produtos_final"] = outputs["produtos_final"].with_columns(pl.coalesce([pl.col("gtin_padrao_enriched"), pl.col("gtin_padrao")]).alias("gtin_padrao")).drop("gtin_padrao_enriched")
    if "unid_ref_enriched" in outputs["produtos_final"].columns:
        outputs["produtos_final"] = outputs["produtos_final"].with_columns(pl.coalesce([pl.col("unid_ref_enriched"), pl.col("unid_ref")]).alias("unid_ref")).drop("unid_ref_enriched")
    return outputs


def build_agregacao_from_mdc_base_v2(
    *,
    efd_itens_base_df: pl.DataFrame,
    efd_inventario_base_df: pl.DataFrame,
    efd_produtos_base_df: pl.DataFrame,
    mapa_manual_df: pl.DataFrame | None = None,
) -> dict[str, pl.DataFrame]:
    produtos_lookup_df = _product_lookup(efd_produtos_base_df)
    itens_norm = _normalize_rows(efd_itens_base_df, source_prefix="mdc_itens", produtos_lookup_df=produtos_lookup_df)
    inventario_norm = _normalize_rows(efd_inventario_base_df, source_prefix="mdc_inventario", produtos_lookup_df=produtos_lookup_df)
    fontes = [df for df in [itens_norm, inventario_norm] if not df.is_empty()]
    itens_agregacao = pl.concat(fontes, how="vertical_relaxed") if fontes else pl.DataFrame(schema={col: pl.Utf8 for col in REQUIRED_COLS})

    outputs = run_mercadoria_v2(itens_agregacao, mapa_manual_df=mapa_manual_df) if not itens_agregacao.is_empty() else {
        "map_produto_agrupado": pl.DataFrame(),
        "produtos_agrupados": pl.DataFrame(),
        "id_agrupados": pl.DataFrame(),
        "produtos_final": pl.DataFrame(),
    }
    outputs = _enrich_produtos_final(outputs, produtos_lookup_df)
    outputs["itens_agregacao"] = itens_agregacao
    return outputs
