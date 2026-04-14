from __future__ import annotations

import polars as pl

from backend.app.services.datasets import dataset_ref
from pipeline.io.parquet_store import save_parquet


GOLD_DATASET_NAMES = {
    "produtos_agrupados": "gold",
    "id_agrupados": "gold",
    "produtos_final": "gold",
    "item_unidades": "gold",
    "fatores_conversao": "gold",
    "mov_estoque": "gold",
    "aba_mensal": "gold",
    "aba_anual": "gold",
    "aba_periodos": "gold",
    "estoque_resumo": "gold",
    "estoque_alertas": "gold",
}


def persist_gold_outputs(cnpj: str, outputs: dict[str, pl.DataFrame]) -> dict[str, str]:
    saved: dict[str, str] = {}
    for name, df in outputs.items():
        if name not in GOLD_DATASET_NAMES:
            continue
        ref = dataset_ref(cnpj=cnpj, layer=GOLD_DATASET_NAMES[name], name=name)
        save_parquet(df, ref)
        saved[name] = str(ref.path)
    return saved
