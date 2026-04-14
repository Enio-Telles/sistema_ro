import polars as pl

from backend.app.services.input_validation import validate_gold_inputs


def test_validate_gold_inputs_reports_empty_required_inputs() -> None:
    inputs = {
        'itens_df': pl.DataFrame(),
        'c170_df': pl.DataFrame(),
        'nfe_df': pl.DataFrame(),
        'nfce_df': pl.DataFrame(),
        'bloco_h_df': pl.DataFrame(),
        'overrides_df': pl.DataFrame(),
        'base_info_df': pl.DataFrame(),
    }
    result = validate_gold_inputs(inputs)
    assert result['ok'] is False
    assert set(result['empty']) == {'itens_df', 'c170_df', 'nfe_df'}
