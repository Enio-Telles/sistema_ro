from __future__ import annotations

from backend.app.services.datasets import dataset_ref
from backend.app.services.parquet_api import load_dataset_preview
from pipeline.io.parquet_store import load_parquet


def get_agregacao_review(cnpj: str) -> dict:
    manual_map_preview = load_dataset_preview(cnpj, "gold", "mapa_manual_agregacao")
    map_preview = load_dataset_preview(cnpj, "gold", "map_produto_agrupado")
    grupos_preview = load_dataset_preview(cnpj, "gold", "produtos_agrupados")

    map_ref = dataset_ref(cnpj=cnpj, layer="gold", name="map_produto_agrupado")
    grupos_ref = dataset_ref(cnpj=cnpj, layer="gold", name="produtos_agrupados")
    manual_ref = dataset_ref(cnpj=cnpj, layer="gold", name="mapa_manual_agregacao")

    map_df = load_parquet(map_ref)
    grupos_df = load_parquet(grupos_ref)
    manual_df = load_parquet(manual_ref)

    resumo = {
        "total_mapeamentos": 0 if map_df is None else map_df.height,
        "total_grupos": 0 if grupos_df is None else grupos_df.height,
        "total_regras_manuais": 0 if manual_df is None else manual_df.height,
        "rows_com_override_manual": 0,
        "grupos_com_multiplas_descricoes": 0,
        "candidatos_revisao": 0,
    }

    candidatos_preview = []
    if map_df is not None and not map_df.is_empty():
        if "id_agrupado_auto" in map_df.columns and "id_agrupado" in map_df.columns:
            resumo["rows_com_override_manual"] = map_df.filter(map_df["id_agrupado_auto"] != map_df["id_agrupado"]).height

        if all(col in map_df.columns for col in ["ncm", "cest", "tipo_item", "unid", "descricao_normalizada", "id_agrupado", "id_agrupado_auto"]):
            candidates = map_df.group_by(["ncm", "cest", "tipo_item", "unid"]).agg(
                map_df["descricao_normalizada"].drop_nulls().unique().sort().alias("descricoes"),
                map_df["id_agrupado"].drop_nulls().unique().sort().alias("ids_agrupados"),
                map_df["id_agrupado_auto"].drop_nulls().unique().sort().alias("ids_auto"),
                map_df["codigo_fonte"].drop_nulls().unique().sort().alias("codigos_fonte"),
            )
            candidates = candidates.filter(candidates["descricoes"].list.len() > 1)
            resumo["candidatos_revisao"] = candidates.height
            candidatos_preview = candidates.head(30).to_dicts()

    if grupos_df is not None and not grupos_df.is_empty() and "lista_descricoes_normalizadas" in grupos_df.columns:
        resumo["grupos_com_multiplas_descricoes"] = grupos_df.filter(grupos_df["lista_descricoes_normalizadas"].list.len() > 1).height

    return {
        "cnpj": cnpj,
        "resumo": resumo,
        "mapa_manual_agregacao": manual_map_preview,
        "map_produto_agrupado": map_preview,
        "produtos_agrupados": grupos_preview,
        "candidatos_revisao": candidatos_preview,
    }
