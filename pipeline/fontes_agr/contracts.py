from __future__ import annotations

FONTES_AGR_REQUIRED_COLUMNS: dict[str, list[str]] = {
    "c170_agr": [
        "cnpj",
        "id_linha_origem",
        "codigo_fonte",
        "codigo_produto_original",
        "id_agrupado",
        "unid",
        "qtd",
        "vl_item",
    ],
    "nfe_agr": [
        "cnpj",
        "id_linha_origem",
        "codigo_fonte",
        "codigo_produto_original",
        "id_agrupado",
        "unid",
        "qtd",
        "vl_item",
    ],
    "nfce_agr": [
        "cnpj",
        "id_linha_origem",
        "codigo_fonte",
        "codigo_produto_original",
        "id_agrupado",
        "unid",
        "qtd",
        "vl_item",
    ],
    "bloco_h_agr": [
        "cnpj",
        "id_linha_origem",
        "codigo_fonte",
        "codigo_produto_original",
        "id_agrupado",
        "unid",
        "qtd",
    ],
}

FONTES_AGR_AUDIT_DATASETS = [
    "c170_agr_sem_id_agrupado",
    "nfe_agr_sem_id_agrupado",
    "nfce_agr_sem_id_agrupado",
    "bloco_h_agr_sem_id_agrupado",
]


def get_required_columns(dataset_name: str) -> list[str]:
    if dataset_name not in FONTES_AGR_REQUIRED_COLUMNS:
        raise KeyError(dataset_name)
    return FONTES_AGR_REQUIRED_COLUMNS[dataset_name]
