from fastapi import APIRouter, Path

from backend.app.services.pipeline_exec_v5_service import execute_pipeline_from_storage_v5
from backend.app.services.references_diagnostic_service import get_references_and_parquets_status
from backend.app.services.input_validation import validate_gold_inputs
from backend.app.services.source_datasets_v2 import load_gold_inputs_prefer_sefin

router = APIRouter()


@router.post("/{cnpj}/run")
def run_pipeline(cnpj: str = Path(..., pattern="^[0-9]{14}$")) -> dict:
    return execute_pipeline_from_storage_v5(cnpj)


@router.get("/{cnpj}/status")
def pipeline_status(cnpj: str = Path(..., pattern="^[0-9]{14}$")) -> dict:
    inputs = load_gold_inputs_prefer_sefin(cnpj)
    selected_items_source = str(inputs.pop("selected_items_source"))
    using_sefin_items = bool(inputs.pop("using_sefin_items"))

    validation = validate_gold_inputs(inputs)
    references_status = get_references_and_parquets_status(cnpj)
    missing_references = [name for name, exists in references_status["references"].items() if not exists]

    return {
        "cnpj": cnpj,
        "validation": validation,
        "missing_references": missing_references,
        "selected_items_source": selected_items_source,
        "using_sefin_items": using_sefin_items,
    }
