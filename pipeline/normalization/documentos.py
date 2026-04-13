from __future__ import annotations

import polars as pl

from pipeline.normalization.keys import build_codigo_fonte, build_id_linha_origem, normalize_cnpj


def normalize_nfe_itens(df: pl.DataFrame, cnpj_base: str) -> pl.DataFrame:
    if df.is_empty():
        return df

    cnpj_norm = normalize_cnpj(cnpj_base)
    return (
        df.with_columns(
            pl.lit(cnpj_norm).alias("cnpj_base"),
            pl.col("codigo_produto").cast(pl.Utf8, strict=False).alias("codigo_produto_original"),
            pl.col("descricao_produto").cast(pl.Utf8, strict=False).alias("descr_item"),
            pl.col("num_item").cast(pl.Utf8, strict=False),
            pl.col("chave_acesso").cast(pl.Utf8, strict=False),
            pl.col("unid").cast(pl.Utf8, strict=False),
        )
        .with_columns(
            pl.struct(["cnpj_base", "codigo_produto_original"]).map_elements(
                lambda row: build_codigo_fonte(row["cnpj_base"], row["codigo_produto_original"]),
                return_dtype=pl.Utf8,
            ).alias("codigo_fonte"),
            pl.struct(["chave_acesso", "num_item"]).map_elements(
                lambda row: build_id_linha_origem(
                    "nfe",
                    {"chave_acesso": row["chave_acesso"], "num_item": row["num_item"]},
                ),
                return_dtype=pl.Utf8,
            ).alias("id_linha_origem"),
        )
    )


def normalize_nfce_itens(df: pl.DataFrame, cnpj_base: str) -> pl.DataFrame:
    if df.is_empty():
        return df

    cnpj_norm = normalize_cnpj(cnpj_base)
    return (
        df.with_columns(
            pl.lit(cnpj_norm).alias("cnpj_base"),
            pl.col("codigo_produto").cast(pl.Utf8, strict=False).alias("codigo_produto_original"),
            pl.col("descricao_produto").cast(pl.Utf8, strict=False).alias("descr_item"),
            pl.col("num_item").cast(pl.Utf8, strict=False),
            pl.col("chave_acesso").cast(pl.Utf8, strict=False),
            pl.col("unid").cast(pl.Utf8, strict=False),
        )
        .with_columns(
            pl.struct(["cnpj_base", "codigo_produto_original"]).map_elements(
                lambda row: build_codigo_fonte(row["cnpj_base"], row["codigo_produto_original"]),
                return_dtype=pl.Utf8,
            ).alias("codigo_fonte"),
            pl.struct(["chave_acesso", "num_item"]).map_elements(
                lambda row: build_id_linha_origem(
                    "nfce",
                    {"chave_acesso": row["chave_acesso"], "num_item": row["num_item"]},
                ),
                return_dtype=pl.Utf8,
            ).alias("id_linha_origem"),
        )
    )
