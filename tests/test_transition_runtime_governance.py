from backend.app.services.operational_surface_index_service import get_operational_surface_index
from backend.app.services.runtime_surface_catalog_service import get_runtime_surface_catalog


def test_transition_runtime_governance_has_no_runtime_wrappers_left() -> None:
    operational = get_operational_surface_index()
    catalog = get_runtime_surface_catalog()

    assert operational['transition_only']['runtimes'] == []
    assert catalog['transition']['fisconforme'] == []
    assert catalog['legacy']['repo_status']['removed_from_repo'] == [
        'runtime_gold_v14',
        'runtime_gold_v15',
        'runtime_gold_v16',
        'runtime_gold_v17',
        'runtime_gold_v18',
        'runtime_gold_v19',
        'runtime_gold_v21',
        'runtime_gold_v22',
        'runtime_gold_v23',
        'runtime_gold_v24',
        'runtime_gold_current',
    ]
