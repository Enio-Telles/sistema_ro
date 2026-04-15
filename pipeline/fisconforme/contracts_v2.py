from __future__ import annotations

FISCONFORME_DATASETS_V2 = {
    "cadastral": "fisconforme_cadastral",
    "malhas": "fisconforme_malhas",
}


def get_dataset_name_v2(kind: str) -> str:
    if kind not in FISCONFORME_DATASETS_V2:
        raise KeyError(kind)
    return FISCONFORME_DATASETS_V2[kind]


def empty_overview_v2(cnpj: str) -> dict:
    return {
        "cnpj": cnpj,
        "dados_cadastrais": [],
        "malhas": [],
        "from_cache_cadastral": False,
        "from_cache_malhas": False,
    }
