from backend.app.services.fisconforme_recommendation_service_v2 import get_fisconforme_recommendation_v2
from backend.app.services.operational_surface_index_service import get_operational_surface_index
from backend.app.services.runtime_surface_catalog_service import get_runtime_surface_catalog


def test_no_transition_runtime_or_alias_wrappers_left_for_fisconforme() -> None:
    operational = get_operational_surface_index()
    catalog = get_runtime_surface_catalog()
    recommendation = get_fisconforme_recommendation_v2()

    assert operational['transition_only']['runtimes'] == []
    assert catalog['transition']['fisconforme'] == []
    assert catalog['legacy']['repo_status']['still_present_as_transition'] == []
    assert recommendation['official_current_alias'] == 'runtime_gold_current_v5'
    assert recommendation['official_current_api_prefix'] == '/api/current-v5/fisconforme-v2'
