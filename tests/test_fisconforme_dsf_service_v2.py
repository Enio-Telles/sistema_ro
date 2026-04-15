from backend.app.services.fisconforme_dsf_service_v2 import _normalize_cnpjs_v2


def test_normalize_cnpjs_v2_deduplicates_and_cleans() -> None:
    result = _normalize_cnpjs_v2(['12.345.678/0001-90', '12345678000190', ''])
    assert result == ['12345678000190']
