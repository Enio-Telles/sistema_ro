from fastapi import APIRouter

from backend.app.services.silver_base_service import execute_silver_base_from_storage

router = APIRouter()


@router.post("/{cnpj}/prepare")
def prepare_silver(cnpj: str) -> dict:
    return execute_silver_base_from_storage(cnpj)
