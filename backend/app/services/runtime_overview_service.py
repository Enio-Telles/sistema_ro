from __future__ import annotations

from backend.app.services.decommission_plan_service import get_decommission_plan
from backend.app.services.operational_surface_index_service import get_operational_surface_index
from backend.app.services.runtime_recommendation_service_v2 import get_runtime_recommendation_v2
from backend.app.services.runtime_surface_catalog_service import get_runtime_surface_catalog
from backend.app.services.fisconforme_recommendation_service_v2 import get_fisconforme_recommendation_v2


def get_runtime_overview() -> dict:
    gold_rec = get_runtime_recommendation_v2()
    fis_rec = get_fisconforme_recommendation_v2()
    catalog = get_runtime_surface_catalog()

    return {
        "recommendation": {
            "official_runtime": {
                "gold": gold_rec,
                "fisconforme": {
                    "runtime": fis_rec.get("official_runtime"),
                    "current_alias": catalog["official"]["fisconforme_current_alias"],
                    "api_prefix": fis_rec.get("official_api_prefix"),
                }
            }
        },
        "operational_index": get_operational_surface_index(),
        "surface_catalog": catalog,
        "decommission_plan": get_decommission_plan(),
    }
