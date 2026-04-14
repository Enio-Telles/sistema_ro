from __future__ import annotations

from backend.app.services.manual_map_source_loader import load_gold_inputs_with_manual_map
from backend.app.services.paths import reference_dir
from pipeline.mdc.build_from_existing_layers import build_priority_mdc_base_from_existing
from pipeline.mdc.materialize_mdc_base import persist_priority_mdc_base
from pipeline.mercadorias.mercadoria_pipeline_v2 import run_mercadoria_v2


def materialize_priority_mdc_base_from_existing(cnpj: str) -> dict:
    inputs = load_gold_inputs_with_manual_map(cnpj)
    mercadorias = run_mercadoria_v2(
        inputs["itens_df"],
        base_info_df=inputs["base_info_df"],
        mapa_manual_df=inputs["mapa_manual_df"],
    ) if not inputs["itens_df"].is_empty() else {"produtos_final": None}

    outputs = build_priority_mdc_base_from_existing(
        itens_df=inputs["itens_df"],
        c170_df=inputs["c170_df"],
        nfe_df=inputs["nfe_df"],
        nfce_df=inputs["nfce_df"],
        bloco_h_df=inputs["bloco_h_df"],
        base_info_df=inputs["base_info_df"],
        reference_root=reference_dir(),
        produtos_df=mercadorias.get("produtos_final"),
    )
    saved = persist_priority_mdc_base(cnpj, outputs)
    return {
        "cnpj": cnpj,
        "saved": saved,
        "datasets": list(saved.keys()),
        "rows": {name: df.height for name, df in outputs.items()},
        "selected_items_source": inputs["selected_items_source"],
        "using_sefin_items": inputs["using_sefin_items"],
        "manual_map_rows": 0 if inputs["mapa_manual_df"].is_empty() else inputs["mapa_manual_df"].height,
    }
