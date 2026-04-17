from pathlib import Path

from backend.app.services.decommission_plan_service import get_decommission_plan


REMOVED_RUNTIME_FILES = [
    Path('backend/app/runtime_gold_v21.py'),
    Path('backend/app/runtime_gold_v22.py'),
    Path('backend/app/runtime_gold_v23.py'),
    Path('backend/app/runtime_gold_v24.py'),
    Path('backend/app/runtime_gold_current_v3.py'),
    Path('backend/app/runtime_gold_current_v4.py'),
]


def test_decommission_plan_matches_final_official_runtime_topology() -> None:
    plan = get_decommission_plan()

    assert plan['official_keep']['gold'] == [
        'runtime_gold_v20',
        'runtime_gold_current_v2',
    ]
    assert plan['official_keep']['fisconforme'] == [
        'runtime_gold_v25',
        'runtime_gold_current_v5',
    ]
    assert plan['keep_temporarily']['transition_runtimes'] == []
    assert 'runtime_gold_current_v4' not in plan['deprecate_now']['legacy_runtimes']


def test_removed_transition_runtime_files_are_absent_from_repository() -> None:
    for runtime_path in REMOVED_RUNTIME_FILES:
        assert not runtime_path.exists(), f'{runtime_path} ainda existe no repositório'
