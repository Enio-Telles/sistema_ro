from backend.app.services.runtime_recommendation_service_v2 import get_runtime_recommendation_v2


def test_runtime_recommendation_v2_points_to_gold_v20() -> None:
    result = get_runtime_recommendation_v2()
    assert result['official_runtime'] == 'runtime_gold_v20'
    assert result['official_pipeline'] == 'gold_v20'
    assert result['official_api_prefix'] == '/api/gold20'
    assert result['official_current_alias'] == 'runtime_gold_current_v2'
