from __future__ import annotations

from backend.app.services.datasets import dataset_ref
from pipeline.io.parquet_store import load_parquet, parquet_exists
from pipeline.manual_map_contract import validate_manual_map_df


def get_manual_map_status(cnpj: str) -> dict:
    ref = dataset_ref(cnpj=cnpj, layer="gold", name="mapa_manual_agregacao")
    exists = parquet_exists(ref)
    df = load_parquet(ref) if exists else None
    if df is None:
        return {
            "cnpj": cnpj,
            "exists": False,
            "path": str(ref.path),
            "rows": 0,
            "schema_validation": {
                "ok": False,
                "required_columns": ["codigo_fonte", "id_agrupado_manual"],
                "optional_columns": ["motivo", "usuario", "observacao", "data_regra"],
                "missing_columns": ["codigo_fonte", "id_agrupado_manual"],
                "duplicate_codigo_fonte": 0,
                "null_codigo_fonte": 0,
                "null_id_agrupado_manual": 0,
            },
        }
    return {
        "cnpj": cnpj,
        "exists": True,
        "path": str(ref.path),
        "rows": df.height,
        "schema_validation": validate_manual_map_df(df),
    }


def get_agregacao_pending_summary(cnpj: str) -> dict:
    map_ref = dataset_ref(cnpj=cnpj, layer="gold", name="map_produto_agrupado")
    grupos_ref = dataset_ref(cnpj=cnpj, layer="gold", name="produtos_agrupados")
    map_df = load_parquet(map_ref)
    grupos_df = load_parquet(grupos_ref)
    manual_status = get_manual_map_status(cnpj)

    pending_conflicts = 0
    multi_desc_groups = 0
    manual_overrides = 0

    if map_df is not None and not map_df.is_empty() and all(col in map_df.columns for col in ["ncm", "cest", "tipo_item", "unid", "descricao_normalizada"]):
        pending_conflicts = (
            map_df.group_by(["ncm", "cest", "tipo_item", "unid"])
            .agg(pl.col("descricao_normalizada").drop_nulls().unique().alias("descricoes"))
            .filter(pl.col("descricoes").list.len() > 1)
            .height
        )
        if "id_agrupado_auto" in map_df.columns and "id_agrupado" in map_df.columns:
            manual_overrides = map_df.filter(pl.col("id_agrupado_auto") != pl.col("id_agrupado")).height

    if grupos_df is not None and not grupos_df.is_empty() and "lista_descricoes_normalizadas" in grupos_df.columns:
        multi_desc_groups = grupos_df.filter(pl.col("lista_descricoes_normalizadas").list.len() > 1).height

    return {
        "cnpj": cnpj,
        "manual_map": manual_status,
        "pending_conflicts": pending_conflicts,
        "multi_description_groups": multi_desc_groups,
        "manual_overrides": manual_overrides,
    }
