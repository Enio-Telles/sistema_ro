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


def test_validate_manual_map_df_reports_recommended_metadata_without_failing() -> None:
    df = pl.DataFrame([
        {'codigo_fonte': 'EMP|B', 'id_agrupado_manual': 'AGR_002'}
    ])

    result = validate_manual_map_df(df)

    assert result['ok'] is True
    assert 'regra_id' in result['recommended_columns']
    assert 'regra_id' in result['missing_recommended_columns']


def test_validate_manual_map_df_detects_duplicate_active_rule_id() -> None:
    df = pl.DataFrame([
        {
            'codigo_fonte': 'EMP|C',
            'id_agrupado_manual': 'AGR_003',
            'regra_id': 'R1',
            'ativo': True,
        },
        {
            'codigo_fonte': 'EMP|D',
            'id_agrupado_manual': 'AGR_004',
            'regra_id': 'R1',
            'ativo': True,
        },
    ])

    result = validate_manual_map_df(df)

    assert result['ok'] is False
    assert result['duplicate_active_regra_id'] == 1
