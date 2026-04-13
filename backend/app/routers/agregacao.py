from fastapi import APIRouter

router = APIRouter()


@router.get("/{cnpj}/grupos")
def get_grupos(cnpj: str) -> dict:
    return {
        "cnpj": cnpj,
        "domain": "agregacao",
        "status": "todo",
        "datasets": [
            "mercadorias_canonicas",
            "apresentacoes_mercadoria",
            "produtos_agrupados",
            "id_agrupados",
            "produtos_final",
        ],
    }


@router.post("/{cnpj}/reprocessar")
def reprocessar_agregacao(cnpj: str) -> dict:
    return {"cnpj": cnpj, "domain": "agregacao", "status": "queued-manual"}
