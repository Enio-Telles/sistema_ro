from pipeline.fisconforme.query_service_v2 import limpar_cnpj_fisconforme, validar_cnpj_tamanho


def test_limpar_cnpj_fisconforme_removes_non_digits() -> None:
    assert limpar_cnpj_fisconforme('12.345.678/0001-90') == '12345678000190'


def test_validar_cnpj_tamanho_accepts_14_digits_only() -> None:
    assert validar_cnpj_tamanho('12345678000190') is True
    assert validar_cnpj_tamanho('123') is False
