from backend.app.services.operational_surface_index_service import get_operational_surface_index
from backend.app.services.runtime_recommendation_service_v2 import get_runtime_recommendation_v2
from backend.app.services.runtime_surface_catalog_service import get_runtime_surface_catalog


def test_legacy_runtime_governance_marks_v14_to_v17_as_removed_from_repo() -> None:
    operational = get_operational_surface_index()
    catalog = get_runtime_surface_catalog()
    recommendation = get_runtime_recommendation_v2()

    assert operational['historical_only']['repo_status'] == 'ja_removidas_do_repositorio'
    assert catalog['legacy']['repo_status']['removed_from_repo'] == [
        'runtime_gold_v14',
        'runtime_gold_v15',
        'runtime_gold_v16',
        'runtime_gold_v17',
        'runtime_gold_current',
    ]
    assert recommendation['migration_map']['runtime_gold_v14'].startswith('historico_removido_do_repositorio')
