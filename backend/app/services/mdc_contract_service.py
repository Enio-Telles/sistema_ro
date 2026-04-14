from __future__ import annotations

from pipeline.mdc.mdc_contracts import get_mdc_contract, list_priority_mdc_contracts


def list_mdc_contracts() -> dict:
    return {
        "datasets": list_priority_mdc_contracts(),
        "count": len(list_priority_mdc_contracts()),
    }


def read_mdc_contract(dataset_name: str) -> dict:
    return {
        "dataset": dataset_name,
        "contract": get_mdc_contract(dataset_name),
    }
