from __future__ import annotations

from pathlib import Path

import polars as pl

from pipeline.references.sefin_classification import infer_co_sefin, load_sefin_tables
from pipeline.references.sefin_vigencia import attach_sefin_vigencia


def enrich_itens_with_sefin(itens_df: pl.DataFrame, reference_root: Path) -> pl.DataFrame:
    if itens_df.is_empty():
        return itens_df

    df = itens_df
    if "data_ref" not in df.columns:
        if "dt_e_s" in df.columns and "dt_doc" in df.columns:
            df = df.with_columns(pl.coalesce([pl.col("dt_e_s"), pl.col("dt_doc")]).alias("data_ref"))
        elif "dt_doc" in df.columns:
            df = df.with_columns(pl.col("dt_doc").alias("data_ref"))
        else:
            df = df.with_columns(pl.lit(None, dtype=pl.Utf8).alias("data_ref"))

    if df.schema.get("data_ref") == pl.Utf8:
        df = df.with_columns(pl.col("data_ref").str.strptime(pl.Date, strict=False))

    enriched = infer_co_sefin(df, reference_root)
    refs = load_sefin_tables(reference_root)
    produto_aux = refs["produto_aux"]
    enriched = attach_sefin_vigencia(enriched, produto_aux, date_col="data_ref")
    return enriched
