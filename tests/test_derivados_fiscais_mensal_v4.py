import polars as pl

from pipeline.estoque.derivados_fiscais_v4 import build_aba_mensal_v4


def test_build_aba_mensal_v4_calculates_icms_entradas_desacob_with_st() -> None:
    mov = pl.DataFrame([
        {
            'id_agrupado': 'P1',
            'descr_padrao': 'ARROZ',
            'unid': 'UN',
            'unid_ref': 'UN',
            'tipo_operacao': '1 - ENTRADA',
            'dt_doc': '2024-01-10',
            'dt_e_s': '2024-01-10',
            'vl_item': 100.0,
            'q_conv': 10.0,
            'saldo_estoque_anual': 10.0,
            'custo_medio_anual': 10.0,
            'entr_desac_anual': 2.0,
            'saldo_estoque_periodo': 10.0,
            'custo_medio_periodo': 10.0,
            'entr_desac_periodo': 1.0,
            'co_sefin_agr': '123',
            'it_pc_interna': 17.0,
            'it_in_st': 'S',
            'it_pc_mva': 40.0,
            'it_in_mva_ajustado': 'N',
        },
        {
            'id_agrupado': 'P1',
            'descr_padrao': 'ARROZ',
            'unid': 'UN',
            'unid_ref': 'UN',
            'tipo_operacao': '2 - SAIDAS',
            'dt_doc': '2024-01-11',
            'dt_e_s': '2024-01-11',
            'vl_item': 60.0,
            'q_conv': 4.0,
            'saldo_estoque_anual': 6.0,
            'custo_medio_anual': 10.0,
            'entr_desac_anual': 0.0,
            'saldo_estoque_periodo': 6.0,
            'custo_medio_periodo': 10.0,
            'entr_desac_periodo': 0.0,
            'co_sefin_agr': '123',
            'it_pc_interna': 17.0,
            'it_in_st': 'S',
            'it_pc_mva': 40.0,
            'it_in_mva_ajustado': 'N',
        },
    ])
    result = build_aba_mensal_v4(mov)
    assert result.height == 1
    row = result.row(0, named=True)
    assert row['ST'] == 'ST'
    assert row['it_in_st'] == 'S'
    assert row['pms_mes'] == 15.0
    assert row['ICMS_entr_desacob'] == 5.1


def test_build_aba_mensal_v4_computes_mva_ajustado_when_flagged() -> None:
    mov = pl.DataFrame([
        {
            'id_agrupado': 'P2',
            'descr_padrao': 'OLEO',
            'unid': 'UN',
            'unid_ref': 'UN',
            'tipo_operacao': '1 - ENTRADA',
            'dt_doc': '2024-02-10',
            'dt_e_s': '2024-02-10',
            'vl_item': 120.0,
            'q_conv': 10.0,
            'saldo_estoque_anual': 10.0,
            'custo_medio_anual': 12.0,
            'entr_desac_anual': 1.0,
            'saldo_estoque_periodo': 10.0,
            'custo_medio_periodo': 12.0,
            'entr_desac_periodo': 1.0,
            'co_sefin_agr': '456',
            'it_pc_interna': 18.0,
            'it_in_st': 'S',
            'it_pc_mva': 40.0,
            'it_in_mva_ajustado': 'S',
            'aliq_inter': 12.0,
        }
    ])
    result = build_aba_mensal_v4(mov)
    row = result.row(0, named=True)
    assert row['MVA_ajustado'] is not None
    assert round(row['MVA_ajustado'], 6) == round((((1 + 0.40) * (1 - 0.12)) / (1 - 0.18)) - 1, 6)


def test_build_aba_mensal_v4_resolves_st_by_month_vigencia() -> None:
    mov = pl.DataFrame([
        {
            'id_agrupado': 'P3',
            'descr_padrao': 'ACUCAR',
            'unid': 'UN',
            'unid_ref': 'UN',
            'tipo_operacao': '1 - ENTRADA',
            'dt_doc': '2024-03-10',
            'dt_e_s': '2024-03-10',
            'vl_item': 100.0,
            'q_conv': 10.0,
            'saldo_estoque_anual': 10.0,
            'custo_medio_anual': 10.0,
            'entr_desac_anual': 2.0,
            'saldo_estoque_periodo': 10.0,
            'custo_medio_periodo': 10.0,
            'entr_desac_periodo': 2.0,
            'co_sefin_agr': '789',
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
            'it_pc_mva': 10.0,
            'it_in_mva_ajustado': 'N',
        },
        {
            'id_agrupado': 'P3',
            'descr_padrao': 'ACUCAR',
            'unid': 'UN',
            'unid_ref': 'UN',
            'tipo_operacao': '2 - SAIDAS',
            'dt_doc': '2024-03-20',
            'dt_e_s': '2024-03-20',
            'vl_item': 60.0,
            'q_conv': 4.0,
            'saldo_estoque_anual': 6.0,
            'custo_medio_anual': 10.0,
            'entr_desac_anual': 0.0,
            'saldo_estoque_periodo': 6.0,
            'custo_medio_periodo': 10.0,
            'entr_desac_periodo': 0.0,
            'co_sefin_agr': '789',
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
            'it_pc_mva': 10.0,
            'it_in_mva_ajustado': 'N',
        },
    ])
    vigencia = pl.DataFrame([
        {
            'co_sefin': '789',
            'it_da_inicio': '2024-03-01',
            'it_da_final': '2024-03-31',
            'it_pc_interna': 19.0,
            'it_in_st': 'S',
            'it_pc_mva': 40.0,
            'it_in_mva_ajustado': 'N',
        }
    ])

    result = build_aba_mensal_v4(mov, vigencia_df=vigencia)
    row = result.row(0, named=True)

    assert row['ST'] == 'ST'
    assert row['it_in_st'] == 'S'
    assert row['aliq_interna'] == 19.0
    assert row['MVA'] == 40.0
    assert row['ICMS_entr_desacob'] == 5.7
    assert row['ICMS_entr_desacob_periodo'] == 5.7
