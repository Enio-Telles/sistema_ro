import polars as pl

from pipeline.conversao.overrides import apply_manual_overrides, build_override_log


def test_apply_manual_overrides_prioritizes_specific_before_general() -> None:
    fatores = pl.DataFrame([
        {
            'id_agrupado': 'AGR1',
            'unid': 'CX',
            'unid_ref': 'UN',
            'unid_ref_heuristica': 'UN',
            'unid_ref_final': 'UN',
            'fator': 10.0,
            'fator_heuristico': 10.0,
            'fator_final': 10.0,
            'tipo_fator': 'preco',
            'tipo_fator_heuristico': 'preco',
            'tipo_fator_final': 'preco',
            'confianca_fator': 0.6,
            'confianca_fator_heuristica': 0.6,
            'confianca_fator_final': 0.6,
            'fonte_fator': 'preco',
            'fonte_fator_heuristico': 'preco',
            'fonte_fator_final': 'preco',
            'override_aplicado': False,
            'override_resolution_key': 'nenhum',
            'caminho_decisao_final': 'heuristico',
        },
        {
            'id_agrupado': 'AGR1',
            'unid': 'FD',
            'unid_ref': 'UN',
            'unid_ref_heuristica': 'UN',
            'unid_ref_final': 'UN',
            'fator': 20.0,
            'fator_heuristico': 20.0,
            'fator_final': 20.0,
            'tipo_fator': 'preco',
            'tipo_fator_heuristico': 'preco',
            'tipo_fator_final': 'preco',
            'confianca_fator': 0.6,
            'confianca_fator_heuristica': 0.6,
            'confianca_fator_final': 0.6,
            'fonte_fator': 'preco',
            'fonte_fator_heuristico': 'preco',
            'fonte_fator_final': 'preco',
            'override_aplicado': False,
            'override_resolution_key': 'nenhum',
            'caminho_decisao_final': 'heuristico',
        },
    ])
    overrides = pl.DataFrame([
        {
            'id_agrupado': 'AGR1',
            'unid': 'CX',
            'unid_ref_manual': 'UN',
            'fator_manual': 12.0,
            'justificativa_fator': 'override especifico',
        },
        {
            'id_agrupado': 'AGR1',
            'unid': None,
            'unid_ref_manual': 'UN',
            'fator_manual': 2.0,
            'justificativa_fator': 'override geral',
        },
    ])

    result = apply_manual_overrides(fatores, overrides).sort('unid')
    cx = result.filter(pl.col('unid') == 'CX').row(0, named=True)
    fd = result.filter(pl.col('unid') == 'FD').row(0, named=True)

    assert cx['fator'] == 12.0
    assert cx['fator_heuristico'] == 10.0
    assert cx['fator_final'] == 12.0
    assert cx['override_aplicado'] is True
    assert cx['override_resolution_key'] == 'id_agrupado+unid'
    assert cx['caminho_decisao_final'] == 'override_manual:id_agrupado+unid'
    assert cx['justificativa_fator'] == 'override especifico'

    assert fd['fator'] == 2.0
    assert fd['fator_heuristico'] == 20.0
    assert fd['fator_final'] == 2.0
    assert fd['override_aplicado'] is True
    assert fd['override_resolution_key'] == 'id_agrupado'
    assert fd['caminho_decisao_final'] == 'override_manual:id_agrupado'
    assert fd['justificativa_fator'] == 'override geral'


def test_build_override_log_includes_heuristic_and_final_values() -> None:
    fatores = pl.DataFrame([
        {
            'id_agrupado': 'AGR9',
            'unid_ref': 'UN',
            'fator': 12.0,
            'tipo_fator': 'manual',
            'fonte_fator': 'override_manual',
            'fator_heuristico': 10.0,
            'fator_final': 12.0,
            'justificativa_fator': 'ajuste',
            'override_aplicado': True,
            'override_resolution_key': 'id_agrupado+unid',
            'caminho_decisao_final': 'override_manual:id_agrupado+unid',
        }
    ])

    log = build_override_log(fatores).row(0, named=True)

    assert log['fator_heuristico'] == 10.0
    assert log['fator_final'] == 12.0
    assert log['caminho_decisao_final'] == 'override_manual:id_agrupado+unid'
