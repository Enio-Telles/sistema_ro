from fastapi import APIRouter

from backend.app.services.agregacao_materialization_service import materialize_agregacao_from_mdc_base

router = APIRouter()


@router.post("/{cnpj}/materialize")
def materialize(cnpj: str) -> dict:
    return materialize_agregacao_from_mdc_base(cnpj)
