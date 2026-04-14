from fastapi import APIRouter

from backend.app.services.pipeline_exec_service import execute_pipeline_from_storage

router = APIRouter()


@router.post("/{cnpj}/run")
def run_pipeline(cnpj: str) -> dict:
    return execute_pipeline_from_storage(cnpj)
