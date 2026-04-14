from __future__ import annotations

import polars as pl

from pipeline.references.loaders import resolve_reference_dataset


def load_sefin_tables(reference_root):
    return {
        "cest_ncm": resolve_reference_dataset(reference_root, "sitafe_cest_ncm").read(),
        "cest": resolve_reference_dataset(reference_root, "sitafe_cest").read(),
        "ncm": resolve_reference_dataset(reference_root, "sitafe_ncm").read(),
        "produto": resolve_reference_dataset(reference_root, "sitafe_produto_sefin").read(),
        "produto_aux": resolve_reference_dataset(reference_root, "sitafe_produto_sefin_aux").read(),
    }


def infer_co_sefin(df: pl.DataFrame, reference_root) -> pl.DataFrame:
    if df.is_empty():
        return df

    refs = load_sefin_tables(reference_root)
    cest_ncm = refs["cest_ncm"]
    cest = refs["cest"]
    ncm = refs["ncm"]
    produto = refs["produto"]

    result = (
        df.join(cest_ncm, on=["cest", "ncm"], how="left", suffix="_cest_ncm")
        .join(cest, on=["cest"], how="left", suffix="_cest")
        .join(ncm, on=["ncm"], how="left", suffix="_ncm")
        .with_columns(
            pl.coalesce([
                pl.col("co_sefin"),
                pl.col("co_sefin_cest"),
                pl.col("co_sefin_ncm"),
            ]).alias("co_sefin_inferido")
        )
        .join(
            produto.rename({"co_sefin": "co_sefin_inferido"}),
            on="co_sefin_inferido",
            how="left",
        )
    )
    return result
