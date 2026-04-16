from fastapi.testclient import TestClient

from backend.app.runtime_gold_current_v2 import app as current_v2_app
from backend.app.runtime_gold_current_v5 import app as current_v5_app
from backend.app.runtime_gold_v20 import app as gold_v20_app
from backend.app.runtime_gold_v25 import app as gold_v25_app


def test_official_gold_runtime_and_alias_surfaces() -> None:
    gold_client = TestClient(gold_v20_app)
    current_client = TestClient(current_v2_app)

    gold_root = gold_client.get('/')
    assert gold_root.status_code == 200
    assert gold_root.json()['name'] == 'sistema_ro_gold_v20'
    assert gold_root.json()['status'] == 'runtime_with_conversion_diagnosis_integrated'

    current_root = current_client.get('/')
    assert current_root.status_code == 200
    assert current_root.json()['name'] == 'sistema_ro_gold_current_v2'
    assert current_root.json()['status'] == 'official_runtime_aliasing_gold_v20'

    runtime_payload = current_client.get('/api/current-v2/runtime').json()
    assert runtime_payload['official_runtime'] == 'runtime_gold_v20'
    assert runtime_payload['official_current_alias'] == 'runtime_gold_current_v2'
    assert runtime_payload['official_current_api_prefix'] == '/api/current-v2'


def test_official_fisconforme_runtime_and_alias_surfaces() -> None:
    gold_client = TestClient(gold_v25_app)
    current_client = TestClient(current_v5_app)

    gold_root = gold_client.get('/')
    assert gold_root.status_code == 200
    assert gold_root.json()['name'] == 'sistema_ro_gold_v25'

    current_root = current_client.get('/')
    assert current_root.status_code == 200
    assert current_root.json()['name'] == 'sistema_ro_gold_current_v5'

    surface_catalog = current_client.get('/api/current-v5/surfaces/catalog').son()
    assert surface_catalog['official']['gold_current_alias'] == 'runtime_gold_current_v2'
    assert surface_catalog['official']['fisconforme_current_alias'] == 'runtime_gold_current_v5'

    runtime_overview = current_client.get('/api/current-v5/runtime-overview').json()
    assert runtime_overview['recommendation']['official_runtime']['gold']['current_alias'] == 'runtime_gold_current_v2'
    assert runtime_overview['recommendation']['official_runtime']['fisconforme']['current_alias'] == 'runtime_gold_current_v5'
