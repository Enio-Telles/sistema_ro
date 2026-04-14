from fastapi import APIRouter

from backend.app.services.mdc_materialization_service import materialize_priority_mdc_base_from_existing

router = APIRouter()


@router.post("/{cnpj}/materialize")
def materialize(cnpj: str) -> dict:
    return materialize_priority_mdc_base_from_existing(cnpj)
