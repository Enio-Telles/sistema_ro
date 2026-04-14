import polars as pl

from backend.app.services.gold_consistency_service import _validate_required


def test_validate_required_ok() -> None:
    df = pl.DataFrame([
        {'id_agregado': 'AGR1', 'ano': 2024, 'ST': 'ST', 'ICMS_saidas_desac': 0.0, 'ICMS_estoque_desac': 1.0}
    ])
    result = _validate_required(df, 'aba_anual')
    assert result['ok'] is True
    assert result['missing_columns'] == []


def test_validate_required_detects_missing_columns() -> None:
    df = pl.DataFrame([
        {'id_agregado': 'AGR1', 'ano': 2024}
    ])
    result = _validate_required(df, 'aba_anual')
    assert result['ok'] is False
    assert 'ST' in result['missing_columns']
