from pipeline.fisconforme.provider_oracle_v2 import _periodo_para_oracle


def test_periodo_para_oracle_converts_mm_aaaa() -> None:
    assert _periodo_para_oracle('01/2024', '190001') == '202401'


def test_periodo_para_oracle_falls_back_on_invalid_value() -> None:
    assert _periodo_para_oracle('invalido', '190001') == '190001'
