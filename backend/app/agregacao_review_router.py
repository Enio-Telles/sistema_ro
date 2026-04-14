from fastapi import APIRouter

from backend.app.services.agregacao_review_service import get_agregacao_review

router = APIRouter()


@router.get("/{cnpj}/review")
def get_review(cnpj: str) -> dict:
    return get_agregacao_review(cnpj)
