from __future__ import annotations

import polars as pl

REQUIRED_PIPELINE_INPUTS = [
    "itens_df",
    "c170_df",
    "nfe_df",
]


def validate_gold_inputs(inputs: dict[str, pl.DataFrame]) -> dict:
    missing: list[str] = []
    empty: list[str] = []
    stats: dict[str, int] = {}

    for name, df in inputs.items():
        rows = 0 if df is None else df.height
        stats[name] = rows
        if name in REQUIRED_PIPELINE_INPUTS:
            if df is None:
                missing.append(name)
            elif df.is_empty():
                empty.append(name)

    return {
        "ok": not missing and not empty,
        "missing": missing,
        "empty": empty,
        "stats": stats,
    }
