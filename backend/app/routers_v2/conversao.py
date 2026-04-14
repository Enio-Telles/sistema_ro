from fastapi import APIRouter

from backend.app.services.conversao_service import get_conversao_overview

router = APIRouter()


@router.get("/{cnpj}/fatores")
def get_fatores(cnpj: str) -> dict:
    return get_conversao_overview(cnpj)
