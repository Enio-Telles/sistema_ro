from fastapi import APIRouter

from backend.app.services.fontes_agr_materialization_service import materialize_fontes_agr

router = APIRouter()


@router.post("/{cnpj}/materialize")
def materialize(cnpj: str) -> dict:
    return materialize_fontes_agr(cnpj)
