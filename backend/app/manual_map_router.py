from fastapi import APIRouter

from backend.app.services.manual_map_status_service import get_agregacao_pending_summary, get_manual_map_status

router = APIRouter()


@router.get("/{cnpj}/status")
def get_status(cnpj: str) -> dict:
    return get_manual_map_status(cnpj)


@router.get("/{cnpj}/pendencias")
def get_pendencias(cnpj: str) -> dict:
    return get_agregacao_pending_summary(cnpj)
