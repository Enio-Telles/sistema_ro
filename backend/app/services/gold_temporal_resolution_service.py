from __future__ import annotations

import polars as pl

from backend.app.services.datasets import dataset_ref
from backend.app.services.paths import reference_dir
from pipeline.io.parquet_store import load_parquet
from pipeline.references.loaders import resolve_reference_dataset


TARGET_DATASETS = ("aba_mensal", "aba_anual", "aba_periodos")
REQUIRED_VIGENCIA_COLUMNS = ("co_sefin", "it_da_inicio")


def _load_gold_dataset(cnpj: str, name: str) -> pl.DataFrame:
    ref = dataset_ref(cnpj=cnpj, layer="gold", name=name)
    df = load_parquet(ref)
    return df if df is not None else pl.DataFrame()


def _load_vigencia_reference() -> pl.DataFrame:
    try:
        return resolve_reference_dataset(reference_dir(), "sitafe_produto_sefin_aux").read()
    except FileNotFoundError:
        return pl.DataFrame()


def _build_vigencia_runtime(df: pl.DataFrame) -> dict:
    missing_columns = [col for col in REQUIRED_VIGENCIA_COLUMNS if col not in df.columns]
    usable = not df.is_empty() and not missing_columns
    if df.is_empty():
        status = "missing_or_empty"
    elif missing_columns:
        status = "invalid_schema"
    else:
        status = "available"
    return {
        "status": status,
        "rows": df.height,
        "missing_columns": missing_columns,
        "usable_for_temporal_resolution": usable,
    }


def _normalize_vigencia(df: pl.DataFrame) -> pl.DataFrame:
    if df.is_empty() or any(col not in df.columns for col in REQUIRED_VIGENCIA_COLUMNS):
        return pl.DataFrame()

    vig = df
    if "it_in_status" in vig.columns:
        vig = vig.filter(pl.col("it_in_status").cast(pl.Utf8, strict=False).str.to_uppercase() != "C")
    if vig.is_empty():
        return pl.DataFrame()

    rename_map = {"co_sefin": "co_sefin_agr", "it_da_inicio": "__vig_inicio__"}
    if "it_da_final" in vig.columns:
        rename_map["it_da_final"] = "__vig_fim__"
    vig = vig.rename(rename_map)
    if "__vig_fim__" not in vig.columns:
        vig = vig.with_columns(pl.lit(None, dtype=pl.Date).alias("__vig_fim__"))

    if vig.schema.get("__vig_inicio__") == pl.Utf8:
        vig = vig.with_columns(pl.col("__vig_inicio__").str.strptime(pl.Date, strict=False))
    if vig.schema.get("__vig_fim__") == pl.Utf8:
        vig = vig.with_columns(pl.col("__vig_fim__").str.strptime(pl.Date, strict=False))

    return vig.select("co_sefin_agr", "__vig_inicio__", "__vig_fim__")


def _build_window(df: pl.DataFrame, dataset_name: str) -> tuple[pl.DataFrame, str | None]:
    if df.is_empty():
        return df, None
    if "co_sefin_agr" not in df.columns:
        return df, "missing_co_sefin_agr"

    if dataset_name == "aba_mensal":
        if not {"ano", "mes"}.issubset(df.columns):
            return df, "missing_time_columns"
        return (
            df.with_columns(
                pl.date(pl.col("ano"), pl.col("mes"), pl.lit(1)).alias("__window_start__"),
                pl.date(pl.col("ano"), pl.col("mes"), pl.lit(1)).dt.month_end().alias("__window_end__"),
            ),
            None,
        )
    if dataset_name == "aba_anual":
        if "ano" not in df.columns:
            return df, "missing_time_columns"
        return (
            df.with_columns(
                pl.date(pl.col("ano"), pl.lit(1), pl.lit(1)).alias("__window_start__"),
                pl.date(pl.col("ano"), pl.lit(12), pl.lit(31)).alias("__window_end__"),
            ),
            None,
        )
    if dataset_name == "aba_periodos":
        if not {"data_inicio", "data_fim"}.issubset(df.columns):
            return df, "missing_time_columns"
        return (
            df.with_columns(
                pl.col("data_inicio").alias("__window_start__"),
                pl.col("data_fim").alias("__window_end__"),
            ),
            None,
        )
    return df, "unsupported_dataset"


def _disabled_summary(dataset_name: str, total_rows: int, *, reason: str = "disabled") -> dict:
    return {
        "status": reason,
        "dataset": dataset_name,
        "total_rows": total_rows,
        "rows_with_co_sefin": 0,
        "rows_without_co_sefin": total_rows,
        "rows_with_vigencia_overlap": 0,
        "rows_without_vigencia_overlap": 0,
        "coverage_ratio": None,
        "non_coverage_breakdown": {
            "schema_insuficiente": 0,
            "sem_co_sefin": total_rows,
            "sem_intersecao_temporal": 0,
        },
    }


def _summarize_dataset(df: pl.DataFrame, normalized_vigencia: pl.DataFrame, dataset_name: str) -> dict:
    window_df, error = _build_window(df, dataset_name)
    if error:
        return {
            "status": "unsupported_schema",
            "dataset": dataset_name,
            "total_rows": df.height,
            "rows_with_co_sefin": 0,
            "rows_without_co_sefin": df.height,
            "rows_with_vigencia_overlap": 0,
            "rows_without_vigencia_overlap": 0,
            "coverage_ratio": None,
            "non_coverage_breakdown": {
                "schema_insuficiente": df.height,
                "sem_co_sefin": 0,
                "sem_intersecao_temporal": 0,
            },
        }
    if window_df.is_empty():
        return {
            "status": "empty_output",
            "dataset": dataset_name,
            "total_rows": 0,
            "rows_with_co_sefin": 0,
            "rows_without_co_sefin": 0,
            "rows_with_vigencia_overlap": 0,
            "rows_without_vigencia_overlap": 0,
            "coverage_ratio": None,
            "non_coverage_breakdown": {
                "schema_insuficiente": 0,
                "sem_co_sefin": 0,
                "sem_intersecao_temporal": 0,
            },
        }

    base = window_df.with_row_index("__row_id__")
    rows_with_key = int(base.filter(pl.col("co_sefin_agr").is_not_null()).height)
    rows_without_key = df.height - rows_with_key
    if rows_with_key == 0:
        return {
            "status": "no_co_sefin_rows",
            "dataset": dataset_name,
            "total_rows": df.height,
            "rows_with_co_sefin": 0,
            "rows_without_co_sefin": df.height,
            "rows_with_vigencia_overlap": 0,
            "rows_without_vigencia_overlap": 0,
            "coverage_ratio": None,
            "non_coverage_breakdown": {
                "schema_insuficiente": 0,
                "sem_co_sefin": df.height,
                "sem_intersecao_temporal": 0,
            },
        }

    overlap = (
        base.select("__row_id__", "co_sefin_agr", "__window_start__", "__window_end__")
        .filter(pl.col("co_sefin_agr").is_not_null())
        .join(normalized_vigencia, on="co_sefin_agr", how="left")
        .with_columns(
            pl.when(
                pl.col("__vig_inicio__").is_not_null()
                & (pl.col("__window_start__") <= pl.coalesce([pl.col("__vig_fim__"), pl.col("__window_end__")]))
                & (pl.col("__window_end__") >= pl.col("__vig_inicio__"))
            )
            .then(True)
            .otherwise(False)
            .alias("__vig_overlap__")
        )
        .group_by("__row_id__")
        .agg(pl.col("__vig_overlap__").any().alias("__vig_overlap__"))
    )
    rows_with_overlap = int(overlap.filter(pl.col("__vig_overlap__")).height)
    rows_without_overlap = rows_with_key - rows_with_overlap

    return {
        "status": "available",
        "dataset": dataset_name,
        "total_rows": df.height,
        "rows_with_co_sefin": rows_with_key,
        "rows_without_co_sefin": rows_without_key,
        "rows_with_vigencia_overlap": rows_with_overlap,
        "rows_without_vigencia_overlap": rows_without_overlap,
        "coverage_ratio": round(rows_with_overlap / rows_with_key, 4) if rows_with_key else None,
        "non_coverage_breakdown": {
            "schema_insuficiente": 0,
            "sem_co_sefin": rows_without_key,
            "sem_intersecao_temporal": rows_without_overlap,
        },
    }


def get_gold_temporal_resolution_summary(cnpj: str) -> dict:
    vigencia_df = _load_vigencia_reference()
    vigencia_runtime = _build_vigencia_runtime(vigencia_df)
    outputs = {name: _load_gold_dataset(cnpj, name) for name in TARGET_DATASETS}

    if not vigencia_runtime["usable_for_temporal_resolution"]:
        targets = {
            name: _disabled_summary(name, outputs[name].height)
            for name in TARGET_DATASETS
        }
        return {
            "status": "disabled",
            "vigencia_runtime": vigencia_runtime,
            "partial_coverage": False,
            "targets_with_partial_coverage": [],
            "targets": targets,
        }

    normalized_vigencia = _normalize_vigencia(vigencia_df)
    if normalized_vigencia.is_empty():
        targets = {
            name: _disabled_summary(name, outputs[name].height, reason="disabled")
            for name in TARGET_DATASETS
        }
        return {
            "status": "disabled",
            "vigencia_runtime": vigencia_runtime,
            "partial_coverage": False,
            "targets_with_partial_coverage": [],
            "targets": targets,
        }

    targets = {
        name: _summarize_dataset(outputs[name], normalized_vigencia, name)
        for name in TARGET_DATASETS
    }
    partial_targets = [
        name
        for name, summary in targets.items()
        if summary["rows_with_co_sefin"] > 0 and summary["rows_without_vigencia_overlap"] > 0
    ]
    return {
        "status": "available",
        "vigencia_runtime": vigencia_runtime,
        "partial_coverage": bool(partial_targets),
        "targets_with_partial_coverage": partial_targets,
        "targets": targets,
    }
