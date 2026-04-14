from fastapi import APIRouter

from backend.app.services.fisconforme_service import get_fisconforme_overview

router = APIRouter()


@router.get("/{cnpj}")
def get_fisconforme(cnpj: str) -> dict:
    return get_fisconforme_overview(cnpj)
