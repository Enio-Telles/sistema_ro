from fastapi import APIRouter

from backend.app.services.runtime_overview_service import get_runtime_overview

router = APIRouter()


@router.get("/")
def get_overview() -> dict:
    return get_runtime_overview()
