import polars as pl

from pipeline.estoque.mov_estoque_v2 import build_mov_estoque_v2


def test_build_mov_estoque_v2_applies_conversion_factor_to_q_conv() -> None:
    c170 = pl.DataFrame([
        {
            'id_agrupado': 'AGR1',
            'id_linha_origem': 'l1',
            'qtd': 2.0,
            'vl_item': 20.0,
            'dt_doc': '2024-01-01',
            'dt_e_s': '2024-01-01',
        }
    ])
    fatores = pl.DataFrame([
        {
            'id_agrupado': 'AGR1',
            'unid_ref': 'KG',
            'fator': 5.0,
            'tipo_fator': 'preco',
            'confianca_fator': 0.75,
            'fonte_fator': 'preco_relativo_com_ref_diagnostico',
        }
    ])
    result = build_mov_estoque_v2(
        c170_df=c170,
        nfe_df=pl.DataFrame(),
        nfce_df=pl.DataFrame(),
        bloco_h_df=pl.DataFrame(),
        fatores_df=fatores,
    )
    row = result.row(0, named=True)
    assert row['q_conv'] == 10.0
    assert row['preco_unit'] == 2.0
    assert row['fator'] == 5.0
    assert row['unid_ref'] == 'KG'


def test_build_mov_estoque_v2_prefers_unit_factor_and_avoids_unsafe_generic_fallback() -> None:
    c170 = pl.DataFrame([
        {
            'id_agrupado': 'AGR2',
            'id_linha_origem': 'l2',
            'unid': 'CX',
            'qtd': 2.0,
            'vl_item': 40.0,
            'dt_doc': '2024-01-02',
            'dt_e_s': '2024-01-02',
        },
        {
            'id_agrupado': 'AGR2',
            'id_linha_origem': 'l3',
            'unid': 'PC',
            'qtd': 2.0,
            'vl_item': 40.0,
            'dt_doc': '2024-01-03',
            'dt_e_s': '2024-01-03',
        },
    ])
    fatores = pl.DataFrame([
        {
            'id_agrupado': 'AGR2',
            'unid': 'CX',
            'unid_ref': 'UN',
            'fator': 10.0,
            'tipo_fator': 'preco',
            'confianca_fator': 0.75,
            'fonte_fator': 'preco_relativo',
        },
        {
            'id_agrupado': 'AGR2',
            'unid': 'FD',
            'unid_ref': 'UN',
            'fator': 24.0,
            'tipo_fator': 'preco',
            'confianca_fator': 0.75,
            'fonte_fator': 'preco_relativo',
        },
    ])

    result = build_mov_estoque_v2(
        c170_df=c170,
        nfe_df=pl.DataFrame(),
        nfce_df=pl.DataFrame(),
        bloco_h_df=pl.DataFrame(),
        fatores_df=fatores,
    ).sort('id_linha_origem')

    cx = result.filter(pl.col('id_linha_origem') == 'l2').row(0, named=True)
    pc = result.filter(pl.col('id_linha_origem') == 'l3').row(0, named=True)

    assert cx['fator'] == 10.0
    assert cx['q_conv'] == 20.0
    assert cx['factor_resolution_mode'] == 'id_agrupado+unid'

    assert pc['fator'] == 1.0
    assert pc['q_conv'] == 2.0
    assert pc['factor_resolution_mode'] == 'fallback_default'
