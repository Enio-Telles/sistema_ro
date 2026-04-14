from __future__ import annotations

import polars as pl

from pipeline.normalization.keys import build_codigo_fonte, build_id_linha_origem, normalize_cnpj


def normalize_bloco_h(df: pl.DataFrame, cnpj_base: str) -> pl.DataFrame:
    if df.is_empty():
        return df

    cnpj_norm = normalize_cnpj(cnpj_base)
    return (
        df.with_columns(
            pl.lit(cnpj_norm).alias("cnpj_base"),
            pl.col("cod_item").cast(pl.Utf8, strict=False).alias("codigo_produto_original"),
            pl.col("txt_compl").cast(pl.Utf8, strict=False).alias("descr_compl"),
            pl.col("unid").cast(pl.Utf8, strict=False),
        )
        .with_columns(
            pl.struct(["cnpj_base", "codigo_produto_original"]).map_elements(
                lambda row: build_codigo_fonte(row["cnpj_base"], row["codigo_produto_original"]),
                return_dtype=pl.Utf8,
            ).alias("codigo_fonte"),
            pl.struct(["bloco_h_id", "cod_item"]).map_elements(
                lambda row: build_id_linha_origem(
                    "bloco_h",
                    {"bloco_h_id": row["bloco_h_id"], "cod_item": row["cod_item"]},
                ),
                return_dtype=pl.Utf8,
            ).alias("id_linha_origem"),
            pl.col("dt_inv").alias("dt_doc"),
            pl.col("dt_inv").alias("dt_e_s"),
        )
    )
