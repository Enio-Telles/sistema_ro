from fastapi.testclient import TestClient

from backend.app.runtime_gold_current_v4 import app


client = TestClient(app)


def test_runtime_gold_current_v4_root() -> None:
    response = client.get('/')
    assert response.status_code == 200
    assert response.json()['name'] == 'sistema_ro_gold_current_v4'


def test_runtime_gold_current_v4_marks_legacy_route_as_deprecated() -> None:
    response = client.get('/api/current-v4/fisconforme/12345678000190')
    assert response.headers.get('Deprecation') == 'true'
    assert response.headers.get('X-Replacement-Route') == '/api/current-v4/fisconforme-v2'
