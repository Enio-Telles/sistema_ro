from fastapi import APIRouter

from backend.app.services.pipeline_exec_v3_service import execute_pipeline_from_storage_v3

router = APIRouter()


@router.post("/{cnpj}/run")
def run_pipeline(cnpj: str) -> dict:
    return execute_pipeline_from_storage_v3(cnpj)
