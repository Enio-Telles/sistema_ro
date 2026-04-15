from datetime import date

import polars as pl

from pipeline.conversao.item_unidades_v2 import build_item_unidades_v2
from pipeline.estoque.derivados_fiscais_v3 import (
    build_aba_anual_v3,
    build_aba_mensal_v3,
    build_aba_periodos_v3,
)


def test_item_unidades_v2_propagates_sefin_fields() -> None:
    itens_df = pl.DataFrame([
        {
            'codigo_fonte': '1|A',
            'id_agrupado': 'AGR1',
            'unid': 'CX',
            'qtd': 10.0,
            'vl_item': 100.0,
            'co_sefin': '1234',
            'aliq_interna': 17.0,
            'it_in_st': 'S',
            'it_pc_mva': 40.0,
            'it_in_mva_ajustado': 'S',
            'it_pc_reducao': 0.0,
            'it_in_reducao_credito': 'N',
        }
    ])
    produtos_df = pl.DataFrame([
        {
            'codigo_fonte': '1|A',
            'id_agrupado': 'AGR1',
            'mercadoria_id': 'M1',
            'apresentacao_id': 'A1',
            'descr_padrao': 'Produto A',
            'unid_ref': 'UN',
        }
    ])

    result = build_item_unidades_v2(itens_df, produtos_df)

    assert result.height == 1
    row = result.to_dicts()[0]
    assert row['co_sefin_agr'] == '1234'
    assert row['co_sefin_final'] == '1234'
    assert row['it_pc_interna'] == 17.0
    assert row['it_in_st'] == 'S'
    assert row['it_pc_mva'] == 40.0


def test_derivados_fiscais_v3_expose_sefin_based_icms_fields() -> None:
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
            'it_in_st': 'S',
            'it_pc_mva': 40.0,
            'it_in_mva_ajustado': 'S',
            'aliq_inter': 12.0,
            'descr_padrao': 'Produto A',
            'unid': 'CX',
            'unid_ref': 'UN',
            'periodo_inventario': '2024-01',
        },
        {
            'id_agrupado': 'AGR1',
            'dt_e_s': date(2024, 1, 20),
            'dt_doc': date(2024, 1, 20),
            'tipo_operacao': '2 - SAIDAS',
            'vl_item': -50.0,
            'q_conv': -5.0,
            'qtd': 5.0,
            'preco_unit': 10.0,
            'saldo_estoque_anual': 3.0,
            'custo_medio_anual': 12.0,
            'entr_desac_anual': 0.0,
            'saldo_estoque_periodo': 3.0,
            'custo_medio_periodo': 12.0,
            'entr_desac_periodo': 0.0,
            'co_sefin_agr': '1234',
            'it_pc_interna': 17.0,
            'it_in_st': 'S',
            'it_pc_mva': 40.0,
            'it_in_mva_ajustado': 'S',
            'aliq_inter': 12.0,
            'descr_padrao': 'Produto A',
            'unid': 'CX',
            'unid_ref': 'UN',
            'periodo_inventario': '2024-01',
        },
        {
            'id_agrupado': 'AGR1',
            'dt_e_s': date(2024, 1, 31),
            'dt_doc': date(2024, 1, 31),
            'tipo_operacao': '3 - ESTOQUE FINAL',
            'vl_item': 0.0,
            'q_conv': 0.0,
            'qtd': 3.0,
            'preco_unit': 12.0,
            'saldo_estoque_anual': 3.0,
            'custo_medio_anual': 12.0,
            'entr_desac_anual': 0.0,
            'saldo_estoque_periodo': 3.0,
            'custo_medio_periodo': 12.0,
            'entr_desac_periodo': 0.0,
            'co_sefin_agr': '1234',
            'it_pc_interna': 17.0,
            'it_in_st': 'S',
            'it_pc_mva': 40.0,
            'it_in_mva_ajustado': 'S',
            'aliq_inter': 12.0,
            'descr_padrao': 'Produto A',
            'unid': 'CX',
            'unid_ref': 'UN',
            'periodo_inventario': '2024-01',
        },
    ])

    mensal = build_aba_mensal_v3(mov_df)
    anual = build_aba_anual_v3(mov_df)
    periodos = build_aba_periodos_v3(mov_df)

    mensal_row = mensal.to_dicts()[0]
    anual_row = anual.to_dicts()[0]
    periodo_row = periodos.to_dicts()[0]

    assert mensal_row['co_sefin_agr'] == '1234'
    assert mensal_row['ST'] == 'ST'
    assert 'ICMS_entr_desacob' in mensal.columns
    assert mensal_row['ICMS_entr_desacob'] >= 0.0

    assert anual_row['co_sefin_agr'] == '1234'
    assert anual_row['ST'] == 'ST'
    assert 'ICMS_saidas_desac' in anual.columns
    assert 'ICMS_estoque_desac' in anual.columns

    assert periodo_row['co_sefin_agr'] == '1234'
    assert periodo_row['ST'] == 'ST'
    assert 'ICMS_saidas_desac' in periodos.columns
    assert 'ICMS_estoque_desac' in periodos.columns
