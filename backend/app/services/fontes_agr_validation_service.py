from __future__ import annotations

import polars as pl

from backend.app.services.layer_datasets import operational_dataset_ref
from pipeline.fontes_agr.contracts import FONTES_AGR_REQUIRED_COLUMNS
from pipeline.io.parquet_store import load_parquet, parquet_exists


def validate_fontes_agr_df(dataset_name: str, df: pl.DataFrame) -> dict:
    required = FONTES_AGR_REQUIRED_COLUMNS[dataset_name]
    missing_columns = [col for col in required if col not in df.columns]
    empty_key_rows = 0
    empty_id_rows = 0

    if not df.is_empty() and "codigo_fonte" in df.columns:
        empty_key_rows = df.filter(pl.col("codigo_fonte").cast(pl.Utf8, strict=False).fill_null("") == "").height
    if not df.is_empty() and "id_agrupado" in df.columns:
        empty_id_rows = df.filter(pl.col("id_agrupado").cast(pl.Utf8, strict=False).fill_null("") == "").height

    return {
        "dataset": dataset_name,
        "ok": not missing_columns and empty_key_rows == 0 and empty_id_rows == 0,
        "rows": df.height,
        "required_columns": required,
        "missing_columns": missing_columns,
        "empty_codigo_fonte_rows": empty_key_rows,
        "empty_id_agrupado_rows": empty_id_rows,
    }


def get_fontes_agr_validation_status(cnpj: str) -> dict:
    datasets: dict[str, dict] = {}
    all_ok = True
    for name in FONTES_AGR_REQUIRED_COLUMNS:
        ref = operational_dataset_ref(cnpj, "fontes_agr", name)
        exists = parquet_exists(ref)
        if not exists:
            datasets[name] = {
                "dataset": name,
                "ok": False,
                "exists": False,
                "path": str(ref.path),
                "rows": 0,
                "required_columns": FONTES_AGR_REQUIRED_COLUMNS[name],
                "missing_columns": FONTES_AGR_REQUIRED_COLUMNS[name],
                "empty_codigo_fonte_rows": 0,
                "empty_id_agrupado_rows": 0,
            }
            all_ok = False
            continue
        df = load_parquet(ref)
        if df is None:
            datasets[name] = {
                "dataset": name,
                "ok": False,
                "exists": True,
                "path": str(ref.path),
                "rows": 0,
                "required_columns": FONTES_AGR_REQUIRED_COLUMNS[name],
                "missing_columns": FONTES_AGR_REQUIRED_COLUMNS[name],
                "empty_codigo_fonte_rows": 0,
                "empty_id_agrupado_rows": 0,
            }
            all_ok = False
            continue
        validation = validate_fontes_agr_df(name, df)
        validation["exists"] = True
        validation["path"] = str(ref.path)
        datasets[name] = validation
        all_ok = all_ok and validation["ok"]
    return {
        "cnpj": cnpj,
        "ok": all_ok,
        "datasets": datasets,
    }
