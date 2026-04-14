from fastapi import APIRouter

from backend.app.services.conversao_quality_service import get_conversao_quality

router = APIRouter()


@router.get("/{cnpj}/quality")
def get_quality(cnpj: str) -> dict:
    return get_conversao_quality(cnpj)
