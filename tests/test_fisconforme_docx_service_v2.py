from pipeline.fisconforme.query_service_v2 import limpar_cnpj_fisconforme


def test_limpar_cnpj_for_docx_flow() -> None:
    assert limpar_cnpj_fisconforme('12.345.678/0001-90') == '12345678000190'
