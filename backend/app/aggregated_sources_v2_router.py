from fastapi import APIRouter

from backend.app.services.fontes_agr_materialization_service_v3 import materialize_fontes_agr_v3
from backend.app.services.fontes_agr_validation_service import get_fontes_agr_validation_status

router = APIRouter()


@router.post("/{cnpj}/materialize")
def materialize(cnpj: str) -> dict:
    return materialize_fontes_agr_v3(cnpj)


@router.get("/{cnpj}/schema")
def schema_status(cnpj: str) -> dict:
    return get_fontes_agr_validation_status(cnpj)
