from __future__ import annotations

from backend.app.services.pipeline_service import run_and_persist_gold_pipeline
from backend.app.services.source_datasets import load_gold_inputs


def execute_pipeline_from_storage(cnpj: str) -> dict:
    inputs = load_gold_inputs(cnpj)
    return run_and_persist_gold_pipeline(cnpj, **inputs)
