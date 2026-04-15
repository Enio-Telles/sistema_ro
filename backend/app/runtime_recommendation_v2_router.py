from fastapi import APIRouter

from backend.app.services.runtime_recommendation_service_v2 import get_runtime_recommendation_v2

router = APIRouter()


@router.get("/")
def get_recommendation() -> dict:
    return get_runtime_recommendation_v2()
