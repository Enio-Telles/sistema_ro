import polars as pl

from pipeline.mercadorias.grouping import bootstrap_produtos_final


def test_bootstrap_produtos_final_adds_identity_columns() -> None:
    df = pl.DataFrame([
        {
            'id_agrupado': 'PROD_1',
            'gtin_padrao': '789',
            'ncm_padrao': '22030000',
            'cest_padrao': '0300100',
            'descr_padrao': 'PRODUTO TESTE',
            'unid_ref': 'UN',
            'embalagem': 'CX',
            'conteudo': '12',
        }
    ])
    result = bootstrap_produtos_final(df)
    assert 'mercadoria_id' in result.columns
    assert 'apresentacao_id' in result.columns
    assert 'match_rule' in result.columns
    assert result['match_rule'][0] == 'gtin'
