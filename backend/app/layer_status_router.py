from fastapi import APIRouter

from backend.app.services.layer_status_service import get_operational_layer_status

router = APIRouter()


@router.get("/{cnpj}")
def get_status(cnpj: str) -> dict:
    return get_operational_layer_status(cnpj)
