from fastapi import APIRouter

router = APIRouter()


@router.post("/{cnpj}/run")
def run_pipeline(cnpj: str) -> dict:
    return {
        "cnpj": cnpj,
        "status": "todo",
        "message": "Endpoint reservado para executar persistência do pipeline gold por CNPJ.",
    }
