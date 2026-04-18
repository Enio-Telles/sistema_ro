import polars as pl

from pipeline.estoque.derivados_fiscais_v4 import build_aba_periodos_v4


def test_build_aba_periodos_v4_computes_period_icms_without_st() -> None:
    """
    ESTOQUE FINAL com q_conv correto. Sem ST: ICMS_saidas_desac calculado com markup 1.30 quando pms=0.
    """
    mov = pl.DataFrame([
        {
            'id_agrupado': 'P9',
            'periodo_inventario': 1,
            'descr_padrao': 'FEIJAO',
            'unid_ref': 'UN',
            'tipo_operacao': '0 - ESTOQUE INICIAL',
            'q_conv': 5.0,
            'qtd': 5.0,
            'vl_item': 0.0,
            'preco_unit': None,
            'entr_desac_periodo': 0.0,
            'saldo_estoque_periodo': 5.0,
            'co_sefin_agr': '999',
            'it_pc_interna': 18.0,
            'it_in_st': 'N',
        },
        {
            'id_agrupado': 'P9',
            'periodo_inventario': 1,
            'descr_padrao': 'FEIJAO',
            'unid_ref': 'UN',
            'tipo_operacao': '1 - ENTRADA',
            'q_conv': 5.0,
            'qtd': 5.0,
            'vl_item': 50.0,    # preco_unit=10 * q_conv=5
            'preco_unit': 10.0,
            'entr_desac_periodo': 0.0,
            'saldo_estoque_periodo': 10.0,
            'co_sefin_agr': '999',
            'it_pc_interna': 18.0,
            'it_in_st': 'N',
        },
        {
            'id_agrupado': 'P9',
            'periodo_inventario': 1,
            'descr_padrao': 'FEIJAO',
            'unid_ref': 'UN',
            'tipo_operacao': '3 - ESTOQUE FINAL',
            # q_conv deve ser qtd * fator (fator=1), não zero
            'q_conv': 8.0,
            'qtd': 8.0,
            'vl_item': 0.0,
            'preco_unit': None,
            'entr_desac_periodo': 0.0,
            'saldo_estoque_periodo': 10.0,
            'co_sefin_agr': '999',
            'it_pc_interna': 18.0,
            'it_in_st': 'N',
        },
    ])
    result = build_aba_periodos_v4(mov)
    row = result.row(0, named=True)

    assert row['ST'] == 'SEM ST'
    # estoque_final = 8.0 (q_conv), saldo_final = 10.0
    # saidas_desacob = max(8-10, 0) = 0
    # estoque_final_desacob = max(10-8, 0) = 2.0
    assert row['saidas_desacob'] == 0.0
    assert row['estoque_final_desacob'] == 2.0
    # pms=0, pme=10.0 → base = 2.0 * 10.0 * 1.30 = 26.0 → ICMS = 26.0 * 0.18 = 4.68
    assert row['ICMS_saidas_desac'] == 0.0
    assert round(row['ICMS_estoque_desac'], 2) == 4.68


def test_build_aba_periodos_v4_computes_icms_saidas_with_pms_and_no_st() -> None:
    """
    Com PMS disponível (pms>0), a base é qtd * pms (sem markup). Produto sem ST.
    """
    mov = pl.DataFrame([
        {
            'id_agrupado': 'P10',
            'periodo_inventario': 1,
            'descr_padrao': 'OLEO',
            'unid_ref': 'UN',
            'tipo_operacao': '1 - ENTRADA',
            'q_conv': 10.0,
            'qtd': 10.0,
            'vl_item': 100.0,
            'preco_unit': 10.0,
            'entr_desac_periodo': 0.0,
            'saldo_estoque_periodo': 10.0,
            'co_sefin_agr': '888',
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
        },
        {
            'id_agrupado': 'P10',
            'periodo_inventario': 1,
            'descr_padrao': 'OLEO',
            'unid_ref': 'UN',
            'tipo_operacao': '2 - SAIDAS',
            'q_conv': 3.0,
            'qtd': 3.0,
            'vl_item': 45.0,    # preco_unit=15 * q_conv=3
            'preco_unit': 15.0,
            'entr_desac_periodo': 0.0,
            'saldo_estoque_periodo': 7.0,
            'co_sefin_agr': '888',
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
        },
        {
            'id_agrupado': 'P10',
            'periodo_inventario': 1,
            'descr_padrao': 'OLEO',
            'unid_ref': 'UN',
            'tipo_operacao': '3 - ESTOQUE FINAL',
            'q_conv': 4.0,
            'qtd': 4.0,
            'vl_item': 0.0,
            'preco_unit': None,
            'entr_desac_periodo': 0.0,
            'saldo_estoque_periodo': 7.0,
            'co_sefin_agr': '888',
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
        },
    ])
    result = build_aba_periodos_v4(mov)
    row = result.row(0, named=True)

    # pms = 45/3 = 15.0
    # estoque_final=4.0, saldo_final=7.0 → saidas_desacob=0, estoque_final_desacob=3.0
    # base_estoque = 3.0 * pms(15.0) = 45.0 (pms>0, sem markup)
    # ICMS_estoque_desac = 45.0 * 0.17 = 7.65
    assert row['ST'] == 'SEM ST'
    assert row['estoque_final_desacob'] == 3.0
    assert round(row['ICMS_estoque_desac'], 2) == 7.65
