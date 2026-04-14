from __future__ import annotations

import polars as pl

from pipeline.mercadorias.builders import build_id_agrupados, build_produtos_agrupados, build_produtos_final


def run_mercadoria_pipeline(itens_df: pl.DataFrame, base_info_df: pl.DataFrame | None = None) -> dict[str, pl.DataFrame]:
    produtos_agrupados = build_produtos_agrupados(itens_df)
    id_agrupados = build_id_agrupados(produtos_agrupados)
    produtos_final = build_produtos_final(produtos_agrupados, base_info_df=base_info_df)
    return {
        "produtos_agrupados": produtos_agrupados,
        "id_agrupados": id_agrupados,
        "produtos_final": produtos_final,
    }
