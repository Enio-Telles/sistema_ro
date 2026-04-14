from fastapi import APIRouter, HTTPException

from backend.app.services.mdc_contract_service import list_mdc_contracts, read_mdc_contract

router = APIRouter()


@router.get("/")
def list_contracts() -> dict:
    return list_mdc_contracts()


@router.get("/{dataset_name}")
def get_contract(dataset_name: str) -> dict:
    try:
        return read_mdc_contract(dataset_name)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail=f"Contrato MDC não encontrado: {dataset_name}") from exc
