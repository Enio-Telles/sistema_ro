from fastapi import APIRouter

from backend.app.services.decommission_plan_service import get_decommission_plan

router = APIRouter()


@router.get("/")
def get_plan() -> dict:
    return get_decommission_plan()
