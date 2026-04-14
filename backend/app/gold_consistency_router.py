from fastapi import APIRouter

from backend.app.services.gold_consistency_service import get_gold_consistency

router = APIRouter()


@router.get("/{cnpj}")
def get_consistency(cnpj: str) -> dict:
    return get_gold_consistency(cnpj)
