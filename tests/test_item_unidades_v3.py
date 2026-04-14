import polars as pl

from pipeline.conversao.item_unidades_v3 import build_item_unidades_v3


def test_build_item_unidades_v3_joins_conversion_diagnosis() -> None:
    itens = pl.DataFrame([
        {
            'codigo_fonte': '1|A',
            'id_agrupado': 'AGR1',
            'unid': 'CX',
            'qtd': 2.0,
            'vl_item': 20.0,
            'co_sefin_agr': '123',
        }
    ])
    produtos = pl.DataFrame([
        {
            'codigo_fonte': '1|A',
            'id_agrupado': 'AGR1',
            'mercadoria_id': 'M1',
            'apresentacao_id': 'A1',
            'descr_padrao': 'ARROZ',
            'unid_ref': 'UN',
        }
    ])
    diagnostico = pl.DataFrame([
        {
            'id_agrupado': 'AGR1',
            'unid': 'CX',
            'unid_ref': 'UN',
            'necessita_conversao': True,
            'evidencia': 'unidade_divergente',
        }
    ])
    result = build_item_unidades_v3(itens, produtos, diagnostico_df=diagnostico)
    row = result.row(0, named=True)
    assert row['possui_diagnostico_conversao'] is True
    assert row['necessita_conversao_diag'] is True
    assert row['unid_ref_diag'] == 'UN'
    assert row['evidencia_diag'] == 'unidade_divergente'
