from datetime import date

import polars as pl

from pipeline.estoque.derivados_fiscais_v3 import build_aba_mensal_v3


def test_build_aba_mensal_v3_falls_back_to_aliq_interna_when_it_pc_interna_missing() -> None:
    mov_df = pl.DataFrame([
        {
            'id_agrupado': 'AGR1',
            'dt_e_s': date(2024, 1, 10),
            'dt_doc': date(2024, 1, 10),
            'tipo_operacao': '1 - ENTRADA',
            'vl_item': 100.0,
            'q_conv': 10.0,
            'qtd': 10.0,
            'preco_unit': 10.0,
            'saldo_estoque_anual': 8.0,
            'custo_medio_anual': 12.0,
            'entr_desac_anual': 2.0,
            'saldo_estoque_periodo': 8.0,
            'custo_medio_periodo': 12.0,
            'entr_desac_periodo': 2.0,
            'co_sefin_agr': '1234',
            'aliq_interna': 17.0,
            'it_in_st': 'S',
            'it_pc_mva': 40.0,
            'it_in_mva_ajustado': 'S',
            'aliq_inter': 12.0,
            'descr_padrao': 'Produto A',
            'unid': 'CX',
            'unid_ref': 'UN',
        }
    ])

    result = build_aba_mensal_v3(mov_df)
    row = result.to_dicts()[0]

    assert row['aliq_interna'] == 17.0
    assert row['ST'] == 'ST'
    assert row['MVA'] == 40.0
    assert row['MVA_ajustado'] is not None


def test_build_aba_mensal_v3_normalizes_boolean_like_mva_adjustment_flag() -> None:
    mov_df = pl.DataFrame([
        {
            'id_agrupado': 'AGR1',
            'dt_e_s': date(2024, 1, 10),
            'dt_doc': date(2024, 1, 10),
            'tipo_operacao': '1 - ENTRADA',
            'vl_item': 100.0,
            'q_conv': 10.0,
            'qtd': 10.0,
            'preco_unit': 10.0,
            'saldo_estoque_anual': 8.0,
            'custo_medio_anual': 12.0,
            'entr_desac_anual': 2.0,
            'saldo_estoque_periodo': 8.0,
            'custo_medio_periodo': 12.0,
            'entr_desac_periodo': 2.0,
            'co_sefin_agr': '1234',
            'it_pc_interna': 17.0,
            'it_in_st': True,
            'it_pc_mva': 40.0,
            'it_in_mva_ajustado': True,
            'aliq_inter': 12.0,
            'descr_padrao': 'Produto A',
            'unid': 'CX',
            'unid_ref': 'UN',
        }
    ])

    result = build_aba_mensal_v3(mov_df)
    row = result.to_dicts()[0]

    assert row['ST'] == 'ST'
    assert row['MVA_ajustado'] is not None
    assert row['ICMS_entr_desacob'] >= 0.0
