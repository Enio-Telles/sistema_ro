from fastapi import APIRouter

from backend.app.services.runtime_recommendation_service import get_runtime_recommendation

router = APIRouter()


@router.get("/")
def get_recommendation() -> dict:
    return get_runtime_recommendation()
