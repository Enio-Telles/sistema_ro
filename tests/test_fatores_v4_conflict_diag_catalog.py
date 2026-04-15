import polars as pl

from pipeline.conversao.fatores_v4 import calcular_fatores_priorizados_v4


def test_calcular_fatores_priorizados_v4_prefers_diag_reference_over_catalog() -> None:
    item_unidades = pl.DataFrame([
        {
            'id_agrupado': 'AGR1',
            'mercadoria_id': 'M1',
            'apresentacao_id': 'A1',
            'unid': 'CX',
            'unid_ref': 'UN',
            'qtd_total': 10.0,
            'linhas': 2,
            'preco_medio': 50.0,
            'possui_diagnostico_conversao': True,
            'necessita_conversao_diag': True,
            'unid_ref_diag': 'KG',
            'evidencia_diag': 'unidade_divergente',
        },
        {
            'id_agrupado': 'AGR1',
            'mercadoria_id': 'M1',
            'apresentacao_id': 'A2',
            'unid': 'KG',
            'unid_ref': 'UN',
            'qtd_total': 20.0,
            'linhas': 3,
            'preco_medio': 10.0,
            'possui_diagnostico_conversao': True,
            'necessita_conversao_diag': True,
            'unid_ref_diag': 'KG',
            'evidencia_diag': 'unidade_divergente',
        },
    ])
    itens = pl.DataFrame([
        {'id_agrupado': 'AGR1', 'unid': 'CX', 'descr_item': 'ARROZ', 'descr_compl': ''},
        {'id_agrupado': 'AGR1', 'unid': 'KG', 'descr_item': 'ARROZ', 'descr_compl': ''},
    ])
    result = calcular_fatores_priorizados_v4(item_unidades, itens)
    cx_row = result.filter(pl.col('unid') == 'CX').row(0, named=True)
    kg_row = result.filter(pl.col('unid') == 'KG').row(0, named=True)
    assert cx_row['unid_ref'] == 'KG'
    assert kg_row['unid_ref'] == 'KG'
    assert cx_row['fonte_unid_ref'] == 'diagnostico_conversao'
    assert cx_row['fator'] == 5.0
    assert cx_row['fonte_fator'] == 'preco_relativo_com_ref_diagnostico'
