from backend.app.services.runtime_recommendation_service import get_runtime_recommendation


def test_runtime_recommendation_points_to_gold_v19() -> None:
    result = get_runtime_recommendation()
    assert result['official_runtime'] == 'runtime_gold_v19'
    assert result['official_pipeline'] == 'gold_v19'
    assert result['official_api_prefix'] == '/api/gold19'
