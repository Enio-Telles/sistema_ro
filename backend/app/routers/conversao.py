from fastapi import APIRouter

router = APIRouter()


@router.get("/{cnpj}/fatores")
def get_fatores(cnpj: str) -> dict:
    return {
        "cnpj": cnpj,
        "domain": "conversao",
        "status": "todo",
        "dataset": "fatores_conversao",
        "fields": [
            "id_agrupado",
            "mercadoria_id",
            "apresentacao_id",
            "unid",
            "unid_ref",
            "fator",
            "tipo_fator",
            "confianca_fator",
            "fator_manual",
            "unid_ref_manual",
        ],
    }


@router.post("/{cnpj}/reprocessar")
def reprocessar_conversao(cnpj: str) -> dict:
    return {"cnpj": cnpj, "domain": "conversao", "status": "queued-manual"}
