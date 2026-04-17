from fastapi import APIRouter

from backend.app.services.agents_service import list_agents

router = APIRouter()


@router.get("/")
def get_agents() -> dict:
    return list_agents()
