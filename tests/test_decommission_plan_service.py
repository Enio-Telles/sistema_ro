from backend.app.services.decommission_plan_service import get_decommission_plan


def test_decommission_plan_has_official_and_deprecate_now_sections() -> None:
    result = get_decommission_plan()
    assert 'official_keep' in result
    assert 'keep_temporarily' in result
    assert 'deprecate_now' in result
    assert 'runtime_gold_v14' in result['deprecate_now']['legacy_runtimes']
