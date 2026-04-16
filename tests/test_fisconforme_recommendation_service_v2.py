from backend.app.services.fisconforme_recommendation_service_v2 import get_fisconforme_recommendation_v2


def test_fisconforme_recommendation_v2_points_to_v25_and_current_v5() -> None:
    result = get_fisconforme_recommendation_v2()
    assert result['official_runtime'] == 'runtime_gold_v25'
    assert result['official_current_alias'] == 'runtime_gold_current_v5'
    assert '/api/gold25/fisconforme-v2' == result['official_api_prefix']
