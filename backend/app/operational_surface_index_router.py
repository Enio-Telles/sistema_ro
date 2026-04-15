from fastapi import APIRouter

from backend.app.services.operational_surface_index_service import get_operational_surface_index

router = APIRouter()


@router.get("/")
def get_index() -> dict:
    return get_operational_surface_index()
