from fastapi import APIRouter

from backend.app.services.estoque_service import get_estoque_overview

router = APIRouter()


@router.get("/{cnpj}/overview")
def get_estoque(cnpj: str) -> dict:
    return get_estoque_overview(cnpj)
