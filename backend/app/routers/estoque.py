from fastapi import APIRouter

router = APIRouter()


@router.get("/{cnpj}/movimentos")
def get_movimentos(cnpj: str) -> dict:
    return {"cnpj": cnpj, "domain": "estoque", "view": "mov_estoque"}


@router.get("/{cnpj}/apuracao/mensal")
def get_mensal(cnpj: str) -> dict:
    return {"cnpj": cnpj, "domain": "estoque", "view": "aba_mensal"}


@router.get("/{cnpj}/apuracao/anual")
def get_anual(cnpj: str) -> dict:
    return {"cnpj": cnpj, "domain": "estoque", "view": "aba_anual"}


@router.get("/{cnpj}/apuracao/periodos")
def get_periodos(cnpj: str) -> dict:
    return {"cnpj": cnpj, "domain": "estoque", "view": "aba_periodos"}
