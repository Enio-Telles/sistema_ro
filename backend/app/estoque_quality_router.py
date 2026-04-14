from fastapi import APIRouter

from backend.app.services.estoque_quality_service import get_estoque_quality

router = APIRouter()


@router.get("/{cnpj}/quality")
def get_quality(cnpj: str) -> dict:
    return get_estoque_quality(cnpj)
