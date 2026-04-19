import polars as pl

from pipeline.conversao.fatores_v4 import calcular_fatores_priorizados_v4


def test_calcular_fatores_priorizados_v4_uses_diagnosis_to_keep_factor_one() -> None:
    item_unidades = pl.DataFrame([
        {
            'id_agrupado': 'AGR1',
            'mercadoria_id': 'M1',
            'apresentacao_id': 'A1',
            'unid': 'UN',
            'unid_ref': 'UN',
            'qtd_total': 10.0,
            'linhas': 2,
            'preco_medio': 5.0,
            'possui_diagnostico_conversao': True,
            'necessita_conversao_diag': False,
            'unid_ref_diag': 'UN',
            'evidencia_diag': 'unidade_compativel',
        }
    ])
    itens = pl.DataFrame([
        {'id_agrupado': 'AGR1', 'unid': 'UN', 'descr_item': 'ARROZ', 'descr_compl': ''}
    ])
    result = calcular_fatores_priorizados_v4(item_unidades, itens)
    row = result.row(0, named=True)
    assert row['fator'] == 1.0
    assert row['tipo_fator'] == 'diagnostico'
    assert row['fonte_fator'] == 'diagnostico_conversao_unidade_base'
    assert row['fator_heuristico'] == 1.0
    assert row['fator_final'] == 1.0
    assert row['unid_ref_heuristica'] == 'UN'
    assert row['unid_ref_final'] == 'UN'
    assert row['override_aplicado'] is False
    assert row['override_resolution_key'] == 'nenhum'
    assert row['caminho_decisao_final'] == 'heuristico'
