from __future__ import annotations

from pathlib import Path
from typing import Any

import polars as pl

from backend.app.services.datasets import DatasetRef, dataset_ref
from pipeline.extraction.db_client import DatabaseClient
from pipeline.extraction.sql_runner import execute_query
from pipeline.io.parquet_store import save_parquet


def extract_to_bronze(
    client: DatabaseClient,
    sql_root: Path,
    cnpj: str,
    template_name: str,
    values: dict[str, Any],
    output_name: str | None = None,
) -> DatasetRef:
    rows = execute_query(client=client, sql_root=sql_root, template_name=template_name, values=values)
    df = pl.DataFrame(rows) if rows else pl.DataFrame()
    target_name = output_name or template_name
    target = dataset_ref(cnpj=cnpj, layer="bronze", name=target_name)
    save_parquet(df, target)
    return target


def rows_to_dataframe(rows: list[dict[str, Any]]) -> pl.DataFrame:
    return pl.DataFrame(rows) if rows else pl.DataFrame()
