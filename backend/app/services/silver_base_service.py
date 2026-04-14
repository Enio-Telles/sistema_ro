from __future__ import annotations

from backend.app.services.source_datasets import load_gold_inputs
from pipeline.persist_silver import persist_silver_outputs
from pipeline.run_silver import run_silver_base_pipeline


def execute_silver_base_from_storage(cnpj: str) -> dict:
    inputs = load_gold_inputs(cnpj)
    outputs = run_silver_base_pipeline(
        c170_df=inputs["c170_df"],
        nfe_df=inputs["nfe_df"],
        nfce_df=inputs["nfce_df"],
        bloco_h_df=inputs["bloco_h_df"],
    )
    saved = persist_silver_outputs(cnpj, outputs)
    return {
        "cnpj": cnpj,
        "status": "ok",
        "saved": saved,
        "datasets": list(saved.keys()),
        "rows": {name: df.height for name, df in outputs.items() if name in saved},
    }
