from fastapi import APIRouter

from backend.app.services.references_diagnostic_service import get_references_and_parquets_status

router = APIRouter()


@router.get("/{cnpj}/status")
def get_status(cnpj: str) -> dict:
    return get_references_and_parquets_status(cnpj)
