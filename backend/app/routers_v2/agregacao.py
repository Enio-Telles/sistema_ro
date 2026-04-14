from fastapi import APIRouter

from backend.app.services.mercadorias_service import get_mercadorias_overview

router = APIRouter()


@router.get("/{cnpj}/grupos")
def get_grupos(cnpj: str) -> dict:
    return get_mercadorias_overview(cnpj)
