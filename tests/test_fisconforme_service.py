from pipeline.fisconforme.service import read_fisconforme_result


def test_read_fisconforme_result_when_cache_missing() -> None:
    result = read_fisconforme_result('00000000000000')
    assert result['cnpj'] == '00000000000000'
    assert result['dados_cadastrais'] == []
    assert result['malhas'] == []
    assert result['from_cache_cadastral'] is False
    assert result['from_cache_malhas'] is False
