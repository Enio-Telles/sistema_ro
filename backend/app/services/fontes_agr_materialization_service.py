from __future__ import annotations

import polars as pl

from backend.app.services.datasets import dataset_ref
from backend.app.services.layer_datasets import operational_dataset_ref
from pipeline.fontes_agr.build_fontes_agr import build_fontes_agr
from pipeline.fontes_agr.persist_fontes_agr_layer import persist_fontes_agr_outputs
from pipeline.io.parquet_store import load_parquet


def _load_silver(cnpj: str, name: str) -> pl.DataFrame:
    ref = dataset_ref(cnpj=cnpj, layer="silver", name=name)
    df = load_parquet(ref)
    return df if df is not None else pl.DataFrame()


def _load_agregacao(cnpj: str, name: str) -> pl.DataFrame:
    ref = operational_dataset_ref(cnpj, "agregacao", name)
    df = load_parquet(ref)
    return df if df is not None else pl.DataFrame()


def materialize_fontes_agr(cnpj: str) -> dict:
    outputs = build_fontes_agr(
        c170_df=_load_silver(cnpj, "efd_c170"),
        nfe_df=_load_silver(cnpj, "nfe_itens"),
        nfce_df=_load_silver(cnpj, "nfce_itens"),
        bloco_h_df=_load_silver(cnpj, "bloco_h"),
        map_produto_agrupado_df=_load_agregacao(cnpj, "map_produto_agrupado"),
        produtos_final_df=_load_agregacao(cnpj, "produtos_final"),
    )
    saved = persist_fontes_agr_outputs(cnpj, outputs)
    return {
        "cnpj": cnpj,
        "saved": saved,
        "datasets": list(saved.keys()),
        "rows": {name: df.height for name, df in outputs.items()},
        "agr_rows": {
            "c170_agr": outputs["c170_agr"].height,
            "nfe_agr": outputs["nfe_agr"].height,
            "nfce_agr": outputs["nfce_agr"].height,
            "bloco_h_agr": outputs["bloco_h_agr"].height,
        },
        "audit_rows_sem_id_agrupado": {
            "c170": outputs["c170_agr_sem_id_agrupado"].height,
            "nfe": outputs["nfe_agr_sem_id_agrupado"].height,
            "nfce": outputs["nfce_agr_sem_id_agrupado"].height,
            "bloco_h": outputs["bloco_h_agr_sem_id_agrupado"].height,
        },
    }
