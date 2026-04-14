from fastapi import APIRouter

from backend.app.services.cnpj_status_service import get_cnpj_status

router = APIRouter()


@router.get("/{cnpj}")
def get_status(cnpj: str) -> dict:
    return get_cnpj_status(cnpj)
