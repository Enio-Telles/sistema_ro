import polars as pl

from backend.app.services.fontes_agr_validation_service import validate_fontes_agr_df


def test_validate_fontes_agr_df_ok() -> None:
    df = pl.DataFrame([
        {
            'cnpj': '1',
            'id_linha_origem': 'l1',
            'codigo_fonte': '1|A',
            'codigo_produto_original': 'A',
            'id_agrupado': 'AGR1',
            'unid': 'UN',
            'qtd': 1.0,
            'vl_item': 10.0,
        }
    ])
    result = validate_fontes_agr_df('c170_agr', df)
    assert result['ok'] is True
    assert result['missing_columns'] == []


def test_validate_fontes_agr_df_detects_missing_and_empty_id() -> None:
    df = pl.DataFrame([
        {
            'cnpj': '1',
            'id_linha_origem': 'l1',
            'codigo_fonte': '1|A',
            'codigo_produto_original': 'A',
            'id_agrupado': '',
            'unid': 'UN',
            'qtd': 1.0,
        }
    ])
    result = validate_fontes_agr_df('bloco_h_agr', df)
    assert result['ok'] is False
    assert result['empty_id_agrupado_rows'] == 1
