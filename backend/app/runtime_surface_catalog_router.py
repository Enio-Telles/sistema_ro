from fastapi import APIRouter

from backend.app.services.runtime_surface_catalog_service import get_runtime_surface_catalog

router = APIRouter()


@router.get("/")
def get_catalog() -> dict:
    return get_runtime_surface_catalog()
