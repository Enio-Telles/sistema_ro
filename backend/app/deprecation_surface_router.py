from fastapi import APIRouter

from backend.app.services.deprecation_surface_service import get_legacy_route_replacements

router = APIRouter()


@router.get("/")
def get_deprecation_catalog() -> dict:
    return {
        "deprecated_routes": get_legacy_route_replacements(),
    }
