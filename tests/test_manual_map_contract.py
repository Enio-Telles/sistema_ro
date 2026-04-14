import polars as pl

from pipeline.manual_map_contract import validate_manual_map_df


def test_validate_manual_map_df_ok() -> None:
    df = pl.DataFrame([
        {'codigo_fonte': 'EMP|A', 'id_agrupado_manual': 'AGR_001'}
    ])
    result = validate_manual_map_df(df)
    assert result['ok'] is True
    assert result['missing_columns'] == []


def test_validate_manual_map_df_detects_missing_and_duplicates() -> None:
    df = pl.DataFrame([
        {'codigo_fonte': 'EMP|A', 'id_agrupado_manual': 'AGR_001'},
        {'codigo_fonte': 'EMP|A', 'id_agrupado_manual': ''},
    ])
    result = validate_manual_map_df(df)
    assert result['ok'] is False
    assert result['duplicate_codigo_fonte'] == 1
    assert result['null_id_agrupado_manual'] == 1
