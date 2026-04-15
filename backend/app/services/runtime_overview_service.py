from __future__ import annotations

from backend.app.services.decommission_plan_service import get_decommission_plan
from backend.app.services.operational_surface_index_service import get_operational_surface_index
from backend.app.services.runtime_recommendation_service_v2 import get_runtime_recommendation_v2
from backend.app.services.runtime_surface_catalog_service import get_runtime_surface_catalog


def get_runtime_overview() -> dict:
    return {
        "recommendation": get_runtime_recommendation_v2(),
        "operational_index": get_operational_surface_index(),
        "surface_catalog": get_runtime_surface_catalog(),
        "decommission_plan": get_decommission_plan(),
    }
