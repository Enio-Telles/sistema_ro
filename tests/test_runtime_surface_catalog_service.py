from backend.app.services.runtime_surface_catalog_service import get_runtime_surface_catalog


def test_runtime_surface_catalog_has_official_and_legacy_sections() -> None:
    result = get_runtime_surface_catalog()
    assert 'official' in result
    assert 'transition' in result
    assert 'legacy' in result
    assert result['official']['gold_runtime'] == 'runtime_gold_v20'
    assert result['official']['fisconforme_runtime'] == 'runtime_gold_v25'
