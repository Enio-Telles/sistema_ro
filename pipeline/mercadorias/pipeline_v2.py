from __future__ import annotations

import polars as pl

from pipeline.mercadorias.aggregation_v2 import build_agrupamento_v2
from pipeline.mercadorias.grouping import bootstrap_produtos_final


def run_mercadoria_pipeline_v2(
    itens_df: pl.DataFrame,
    base_info_df: pl.DataFrame | None = None,
    mapa_manual_df: pl.DataFrame | None = None,
) -> dict[str, pl.DataFrame]:
    built = build_agrupamento_v2(itens_df, mapa_manual_df=mapa_manual_df)
    produtos_agrupados = built["produtos_agrupados"]
    map_produto_agrupado = built["map_produto_agrupado"]
    produtos_final = built["produtos_final"]

    if base_info_df is not None and not base_info_df.is_empty() and "id_agrupado" in base_info_df.columns:
        keep_cols = [
            c for c in [
                "id_agrupado",
                "gtin_padrao",
                "unid_ref",
                "embalagem",
                "conteudo",
            ] if c in base_info_df.columns
        ]
        if keep_cols:
            produtos_final = produtos_final.join(
                base_info_df.select(keep_cols).unique(subset=["id_agrupado"]),
                on="id_agrupado",
                how="left",
                suffix="_base",
            )
            if "unid_ref_base" in produtos_final.columns:
                produtos_final = produtos_final.with_columns(
                    pl.coalesce([pl.col("unid_ref_base"), pl.col("unid_ref")]).alias("unid_ref")
                ).drop([c for c in ["unid_ref_base"] if c in produtos_final.columns])
            if "gtin_padrao_base" in produtos_final.columns:
                produtos_final = produtos_final.with_columns(
                    pl.coalesce([pl.col("gtin_padrao_base"), pl.col("gtin_padrao")]).alias("gtin_padrao")
                ).drop([c for c in ["gtin_padrao_base"] if c in produtos_final.columns])

    produtos_final = bootstrap_produtos_final(produtos_final)
    id_agrupados = map_produto_agrupado.select(
        [c for c in ["id_agrupado", "codigo_fonte", "id_linha_origem", "descricao_normalizada", "codigo_produto_original"] if c in map_produto_agrupado.columns]
    )
    return {
        "map_produto_agrupado": map_produto_agrupado,
        "produtos_agrupados": produtos_agrupados,
        "id_agrupados": id_agrupados,
        "produtos_final": produtos_final,
    }
