from pipeline.normalization.keys import (
    build_codigo_fonte,
    build_id_linha_origem,
    normalize_cnpj,
    normalize_cpf,
    normalize_ie,
)


def test_normalize_identifiers() -> None:
    assert normalize_cnpj('12.345.678/0001-90') == '12345678000190'
    assert normalize_cpf('123.456.789-00') == '12345678900'
    assert normalize_ie('000.123.45-6') == '000123456'


def test_build_codigo_fonte() -> None:
    assert build_codigo_fonte('12.345.678/0001-90', 'ABC-01') == '12345678000190|ABC-01'


def test_build_id_linha_origem() -> None:
    nfe_id = build_id_linha_origem('nfe', {'chave_acesso': '351...', 'num_item': 3})
    c170_id = build_id_linha_origem('c170', {'reg_0000_id': 11, 'num_doc': '123', 'num_item': 7})
    assert nfe_id == 'nfe|351...|3'
    assert c170_id == 'c170|11|123|7'
