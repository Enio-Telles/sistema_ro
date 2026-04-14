from __future__ import annotations

import polars as pl


def attach_sefin_vigencia(
    df: pl.DataFrame,
    vigencia_df: pl.DataFrame,
    *,
    sefin_col: str = "co_sefin_inferido",
    date_col: str = "data_ref",
) -> pl.DataFrame:
    if df.is_empty() or vigencia_df.is_empty():
        return df

    base = df.with_row_index("__row_id__")
    vig = vigencia_df.rename({
        "co_sefin": sefin_col,
        "it_da_inicio": "__vig_inicio__",
        "it_da_final": "__vig_fim__",
    })

    joined = base.join(vig, on=sefin_col, how="left")
    if date_col in joined.columns:
        joined = joined.filter(
            pl.col(date_col).is_null() |
            (
                (pl.col(date_col) >= pl.col("__vig_inicio__")) &
                (pl.col(date_col) <= pl.col("__vig_fim__"))
            )
        )

    # mantém uma linha por linha original após aplicar vigência
    return (
        joined.sort(["__row_id__", "__vig_inicio__"], descending=[False, True], nulls_last=True)
        .group_by("__row_id__")
        .first()
        .drop("__row_id__")
    )
