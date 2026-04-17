from __future__ import annotations

import polars as pl

from pipeline.normalization.keys import build_codigo_fonte, build_id_linha_origem, normalize_cnpj, normalize_text


def normalize_efd_c170(df: pl.DataFrame, cnpj_base: str) -> pl.DataFrame:
    if df.is_empty():
        return df

    cnpj_norm = normalize_cnpj(cnpj_base)
    return (
        df.with_columns(
            pl.lit(cnpj_norm).alias("cnpj_base"),
            pl.col("codigo_produto").cast(pl.Utf8, strict=False).alias("codigo_produto_original"),
            pl.col("descricao_produto").cast(pl.Utf8, strict=False).alias("descr_item"),
            pl.col("unid").cast(pl.Utf8, strict=False),
            pl.col("cfop").cast(pl.Utf8, strict=False),
            pl.col("chave_acesso").cast(pl.Utf8, strict=False),
        )
        .with_columns(
            pl.struct(["cnpj_base", "codigo_produto_original"]).map_elements(
                lambda row: build_codigo_fonte(row["cnpj_base"], row["codigo_produto_original"]),
                return_dtype=pl.Utf8,
            ).alias("codigo_fonte"),
            pl.struct(["arquivo_id", "num_doc", "num_item"]).map_elements(
                lambda row: build_id_linha_origem(
                    "c170",
                    {
                        "reg_0000_id": row["arquivo_id"],
                        "num_doc": row["num_doc"],
                        "num_item": row["num_item"],
                    },
                ),
                return_dtype=pl.Utf8,
            ).alias("id_linha_origem"),
        )
    )


def normalize_efd_0200(df: pl.DataFrame) -> pl.DataFrame:
    if df.is_empty():
        return df
    return df.with_columns(
        pl.col("cod_item").cast(pl.Utf8, strict=False).alias("codigo_produto_original"),
        pl.col("descr_item").cast(pl.Utf8, strict=False).map_elements(normalize_text, return_dtype=pl.Utf8).alias("descr_item"),
        pl.col("cod_barra").cast(pl.Utf8, strict=False),
        pl.col("cod_ncm").cast(pl.Utf8, strict=False).alias("ncm"),
        pl.col("cest").cast(pl.Utf8, strict=False),
        pl.col("unid_inv").cast(pl.Utf8, strict=False).alias("unid_inv"),
    )
