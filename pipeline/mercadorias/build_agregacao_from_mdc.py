from __future__ import annotations

import polars as pl

from pipeline.mercadorias.mercadoria_pipeline_v2 import run_mercadoria_v2


def _product_lookup(produtos_base_df: pl.DataFrame) -> pl.DataFrame:
    if produtos_base_df.is_empty():
        return pl.DataFrame()
    keep = [
        col
        for col in [
            "cnpj",
            "codigo_produto_original",
            "descr_item",
            "descr_compl",
            "tipo_item",
            "ncm",
            "cest",
            "gtin_padrao",
            "unid",
        ]
        if col in produtos_base_df.columns
    ]
    if not keep:
        return pl.DataFrame()
    subset = [col for col in ["cnpj", "codigo_produto_original"] if col in keep]
    lookup = produtos_base_df.select(keep)
    return lookup.unique(subset=subset) if subset else lookup.unique()


def _normalize_rows(
    df: pl.DataFrame,
    *,
    source_prefix: str,
    produtos_lookup_df: pl.DataFrame,
) -> pl.DataFrame:
    if df.is_empty():
        return pl.DataFrame(
            schema={
                "cnpj": pl.Utf8,
                "id_linha_origem": pl.Utf8,
                "codigo_fonte": pl.Utf8,
                "codigo_produto_original": pl.Utf8,
                "descr_item": pl.Utf8,
                "descr_compl": pl.Utf8,
                "tipo_item": pl.Utf8,
                "ncm": pl.Utf8,
                "cest": pl.Utf8,
                "gtin_padrao": pl.Utf8,
                "unid": pl.Utf8,
            }
        )

    result = df
    join_keys = [col for col in ["cnpj", "codigo_produto_original"] if col in result.columns and col in produtos_lookup_df.columns]
    if join_keys and not produtos_lookup_df.is_empty():
        lookup_cols = join_keys + [col for col in ["descr_item", "descr_compl", "tipo_item", "ncm", "cest", "gtin_padrao", "unid"] if col in produtos_lookup_df.columns]
        result = result.join(produtos_lookup_df.select(lookup_cols), on=join_keys, how="left", suffix="_prod")

    result = result.with_row_index("__row_nr__")

    def _coalesce(name: str, fallback: str | None = None) -> pl.Expr:
        cols = []
        if name in result.columns:
            cols.append(pl.col(name).cast(pl.Utf8, strict=False))
        if fallback and fallback in result.columns:
            cols.append(pl.col(fallback).cast(pl.Utf8, strict=False))
        if cols:
            return pl.coalesce(cols).fill_null("").alias(name)
        return pl.lit("").alias(name)

    result = result.with_columns(
        _coalesce("cnpj"),
        _coalesce("codigo_produto_original"),
        _coalesce("descr_item", "descr_item_prod"),
        _coalesce("descr_compl", "descr_compl_prod"),
        _coalesce("tipo_item", "tipo_item_prod"),
        _coalesce("ncm", "ncm_prod"),
        _coalesce("cest", "cest_prod"),
        _coalesce("gtin_padrao", "gtin_padrao_prod"),
        _coalesce("unid", "unid_prod"),
    )

    result = result.with_columns(
        pl.when(pl.col("id_linha_origem").cast(pl.Utf8, strict=False).fill_null("") == "")
        .then(
            pl.concat_str(
                [
                    pl.lit(source_prefix),
                    pl.lit("|"),
                    pl.col("codigo_produto_original"),
                    pl.lit("|"),
                    pl.col("__row_nr__").cast(pl.Utf8),
                ]
            )
        )
        .otherwise(pl.col("id_linha_origem").cast(pl.Utf8, strict=False))
        .alias("id_linha_origem"),
        pl.when(pl.col("codigo_fonte").cast(pl.Utf8, strict=False).fill_null("") == "")
        .then(pl.concat_str([pl.col("cnpj"), pl.lit("|"), pl.col("codigo_produto_original")]))
        .otherwise(pl.col("codigo_fonte").cast(pl.Utf8, strict=False))
        .alias("codigo_fonte"),
    )

    return result.select(
        [
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
    )


def build_agregacao_from_mdc_base(
    *,
    efd_itens_base_df: pl.DataFrame,
    efd_inventario_base_df: pl.DataFrame,
    efd_produtos_base_df: pl.DataFrame,
    mapa_manual_df: pl.DataFrame | None = None,
) -> dict[str, pl.DataFrame]:
    produtos_lookup_df = _product_lookup(efd_produtos_base_df)
    itens_norm = _normalize_rows(
        efd_itens_base_df,
        source_prefix="mdc_itens",
        produtos_lookup_df=produtos_lookup_df,
    )
    inventario_norm = _normalize_rows(
        efd_inventario_base_df,
        source_prefix="mdc_inventario",
        produtos_lookup_df=produtos_lookup_df,
    )

    fontes = [df for df in [itens_norm, inventario_norm] if not df.is_empty()]
    itens_agregacao = pl.concat(fontes, how="vertical_relaxed") if fontes else pl.DataFrame()

    outputs = run_mercadoria_v2(
        itens_agregacao,
        mapa_manual_df=mapa_manual_df,
    ) if not itens_agregacao.is_empty() else {
        "map_produto_agrupado": pl.DataFrame(),
        "produtos_agrupados": pl.DataFrame(),
        "id_agrupados": pl.DataFrame(),
        "produtos_final": pl.DataFrame(),
    }

    if not outputs["produtos_final"].is_empty() and not produtos_lookup_df.is_empty():
        enrich = (
            outputs["map_produto_agrupado"]
            .join(
                produtos_lookup_df.select([col for col in ["cnpj", "codigo_produto_original", "gtin_padrao", "unid"] if col in produtos_lookup_df.columns]),
                on=[col for col in ["cnpj", "codigo_produto_original"] if col in outputs["map_produto_agrupado"].columns and col in produtos_lookup_df.columns],
                how="left",
                suffix="_prod",
            )
            .group_by("id_agrupado")
            .agg(
                pl.col("gtin_padrao_prod").drop_nulls().first().alias("gtin_padrao_enriched") if "gtin_padrao_prod" in outputs["map_produto_agrupado"].join(
                    produtos_lookup_df.select([col for col in ["cnpj", "codigo_produto_original", "gtin_padrao", "unid"] if col in produtos_lookup_df.columns]),
                    on=[col for col in ["cnpj", "codigo_produto_original"] if col in outputs["map_produto_agrupado"].columns and col in produtos_lookup_df.columns],
                    how="left",
                    suffix="_prod",
                ).columns else pl.lit(None).alias("gtin_padrao_enriched"),
                pl.col("unid_prod").drop_nulls().first().alias("unid_ref_enriched") if "unid_prod" in outputs["map_produto_agrupado"].join(
                    produtos_lookup_df.select([col for col in ["cnpj", "codigo_produto_original", "gtin_padrao", "unid"] if col in produtos_lookup_df.columns]),
                    on=[col for col in ["cnpj", "codigo_produto_original"] if col in outputs["map_produto_agrupado"].columns and col in produtos_lookup_df.columns],
                    how="left",
                    suffix="_prod",
                ).columns else pl.lit(None).alias("unid_ref_enriched"),
            )
        )
        outputs["produtos_final"] = outputs["produtos_final"].join(enrich, on="id_agrupado", how="left").with_columns(
            pl.coalesce([pl.col("gtin_padrao_enriched"), pl.col("gtin_padrao")]).alias("gtin_padrao"),
            pl.coalesce([pl.col("unid_ref_enriched"), pl.col("unid_ref")]).alias("unid_ref"),
        ).drop([col for col in ["gtin_padrao_enriched", "unid_ref_enriched"] if col in outputs["produtos_final"].columns])

    outputs["itens_agregacao"] = itens_agregacao
    return outputs
