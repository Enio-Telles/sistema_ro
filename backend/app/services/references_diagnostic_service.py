from __future__ import annotations

from backend.app.services.datasets import dataset_ref
from backend.app.services.paths import reference_dir
from pipeline.io.parquet_store import parquet_exists
from pipeline.references.loaders import validate_reference_root

EXPECTED_SILVER = [
    "efd_c170",
    "nfe_itens",
    "nfce_itens",
    "bloco_h",
    "itens_unificados",
    "base_info_mercadorias",
    "itens_unificados_sefin",
]

EXPECTED_GOLD = [
    "produtos_agrupados",
    "id_agrupados",
    "produtos_final",
    "item_unidades",
    "fatores_conversao",
    "log_conversao_anomalias",
    "mov_estoque",
    "aba_mensal",
    "aba_anual",
    "aba_periodos",
    "estoque_resumo",
    "estoque_alertas",
]

EXPECTED_FISCONFORME = [
    "fisconforme_cadastral",
    "fisconforme_malhas",
]


def _layer_status(cnpj: str, layer: str, names: list[str]) -> dict[str, dict]:
    result: dict[str, dict] = {}
    for name in names:
        ref = dataset_ref(cnpj=cnpj, layer=layer, name=name)
        result[name] = {
            "exists": parquet_exists(ref),
            "path": str(ref.path),
        }
    return result


def get_references_and_parquets_status(cnpj: str) -> dict:
    refs_root = reference_dir()
    refs_status = validate_reference_root(refs_root)
    silver = _layer_status(cnpj, "silver", EXPECTED_SILVER)
    gold = _layer_status(cnpj, "gold", EXPECTED_GOLD)
    fisconforme = _layer_status(cnpj, "fisconforme", EXPECTED_FISCONFORME)
    return {
        "cnpj": cnpj,
        "references_root": str(refs_root),
        "references": refs_status,
        "silver": silver,
        "gold": gold,
        "fisconforme": fisconforme,
    }
