from __future__ import annotations

import polars as pl


def assign_periodo_inventario(mov_df: pl.DataFrame) -> pl.DataFrame:
    if mov_df.is_empty() or "id_agrupado" not in mov_df.columns:
        return mov_df

    df = mov_df
    if "tipo_operacao" not in df.columns:
        return df.with_columns(pl.lit(1).alias("periodo_inventario"))

    marcador = (
        pl.when(pl.col("tipo_operacao") == "0 - ESTOQUE INICIAL")
        .then(1)
        .otherwise(0)
        .cum_sum()
        .over("id_agrupado")
        .alias("periodo_inventario")
    )

    return df.with_columns(marcador).with_columns(
        pl.when(pl.col("periodo_inventario") <= 0).then(1).otherwise(pl.col("periodo_inventario")).alias("periodo_inventario")
    )


def build_estoque_inicial_rows(bloco_h_df: pl.DataFrame) -> pl.DataFrame:
    if bloco_h_df.is_empty():
        return pl.DataFrame()

    cols = bloco_h_df.columns
    df = bloco_h_df

    if "dt_doc" in cols:
        dt_col = pl.col("dt_doc")
        dt_dtype = bloco_h_df.schema.get("dt_doc")
        if dt_dtype == pl.Utf8:
            dt_col = dt_col.str.strptime(pl.Date, strict=False)
        elif dt_dtype == pl.Datetime:
            dt_col = dt_col.cast(pl.Date)
        dt_e_s_expr = dt_col.dt.offset_by("1d").alias("dt_e_s")
    else:
        dt_e_s_expr = pl.lit(None, dtype=pl.Date).alias("dt_e_s")

    return df.with_columns(
        pl.lit("gerado").alias("fonte"),
        pl.lit("0 - ESTOQUE INICIAL").alias("tipo_operacao"),
        dt_e_s_expr,
    )
