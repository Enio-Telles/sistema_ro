import polars as pl

from pipeline.estoque.derivados_fiscais_v4 import build_aba_anual_v4


def test_build_aba_anual_v4_zeros_saida_icms_when_st_and_keeps_estoque_icms() -> None:
    """
    ESTOQUE FINAL: q_conv deve ser usado (não qtd bruto).
    PME/PMS ponderado. ICMS_saidas_desac=0 quando ST. ICMS_estoque_desac calculado sempre.
    """
    mov = pl.DataFrame([
        {
            'id_agrupado': 'P1',
            'descr_padrao': 'ARROZ',
            'unid_ref': 'UN',
            'tipo_operacao': '0 - ESTOQUE INICIAL',
            'dt_doc': '2024-01-01',
            'dt_e_s': '2024-01-01',
            'q_conv': 5.0,
            'qtd': 5.0,
            'vl_item': 0.0,
            'preco_unit': None,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 5.0,
            'co_sefin_agr': '123',
            'it_pc_interna': 17.0,
            'it_in_st': 'S',
        },
        {
            'id_agrupado': 'P1',
            'descr_padrao': 'ARROZ',
            'unid_ref': 'UN',
            'tipo_operacao': '1 - ENTRADA',
            'dt_doc': '2024-01-10',
            'dt_e_s': '2024-01-10',
            'q_conv': 10.0,
            'qtd': 10.0,
            'vl_item': 100.0,   # preco_unit=10 * q_conv=10
            'preco_unit': 10.0,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 15.0,
            'co_sefin_agr': '123',
            'it_pc_interna': 17.0,
            'it_in_st': 'S',
        },
        {
            'id_agrupado': 'P1',
            'descr_padrao': 'ARROZ',
            'unid_ref': 'UN',
            'tipo_operacao': '2 - SAIDAS',
            'dt_doc': '2024-01-11',
            'dt_e_s': '2024-01-11',
            'q_conv': 4.0,
            'qtd': 4.0,
            'vl_item': 60.0,    # preco_unit=15 * q_conv=4
            'preco_unit': 15.0,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 11.0,
            'co_sefin_agr': '123',
            'it_pc_interna': 17.0,
            'it_in_st': 'S',
        },
        {
            'id_agrupado': 'P1',
            'descr_padrao': 'ARROZ',
            'unid_ref': 'UN',
            'tipo_operacao': '3 - ESTOQUE FINAL',
            'dt_doc': '2024-12-31',
            'dt_e_s': '2024-12-31',
            # q_conv deve ser qtd * fator (fator=1 aqui), não zero
            'q_conv': 8.0,
            'qtd': 8.0,
            'vl_item': 0.0,
            'preco_unit': None,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 11.0,
            'co_sefin_agr': '123',
            'it_pc_interna': 17.0,
            'it_in_st': 'S',
        },
    ])
    result = build_aba_anual_v4(mov)
    row = result.row(0, named=True)

    # ST ativo
    assert row['ST'] == 'ST'
    # estoque_final = 8.0 (q_conv), saldo_final = 11.0 → saidas_desacob = 0, estoque_final_desacob = 3
    assert row['saidas_desacob'] == 0.0
    assert row['estoque_final_desacob'] == 3.0
    # ST: ICMS_saidas_desac zerado; ICMS_estoque_desac = 3 * pms(15.0) * 0.17 = 7.65
    assert row['ICMS_saidas_desac'] == 0.0
    assert row['ICMS_estoque_desac'] == 7.65


def test_build_aba_anual_v4_applies_markup_130_when_no_pms() -> None:
    """
    Quando não há saídas (pms=0), base = qtd * pme * 1.30 (doc tabela_anual, seção ICMS anual).
    """
    mov = pl.DataFrame([
        {
            'id_agrupado': 'P2',
            'descr_padrao': 'FEIJAO',
            'unid_ref': 'UN',
            'tipo_operacao': '1 - ENTRADA',
            'dt_doc': '2024-01-05',
            'dt_e_s': '2024-01-05',
            'q_conv': 10.0,
            'qtd': 10.0,
            'vl_item': 100.0,
            'preco_unit': 10.0,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 10.0,
            'co_sefin_agr': '456',
            'it_pc_interna': 18.0,
            'it_in_st': 'N',
        },
        {
            'id_agrupado': 'P2',
            'descr_padrao': 'FEIJAO',
            'unid_ref': 'UN',
            'tipo_operacao': '3 - ESTOQUE FINAL',
            'dt_doc': '2024-12-31',
            'dt_e_s': '2024-12-31',
            'q_conv': 6.0,
            'qtd': 6.0,
            'vl_item': 0.0,
            'preco_unit': None,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 10.0,
            'co_sefin_agr': '456',
            'it_pc_interna': 18.0,
            'it_in_st': 'N',
        },
    ])
    result = build_aba_anual_v4(mov)
    row = result.row(0, named=True)

    # pms = 0, pme = 10.0
    # estoque_final = 6.0, saldo_final = 10.0 → estoque_final_desacob = 4.0
    # base_estoque = 4.0 * 10.0 * 1.30 = 52.0
    # ICMS_estoque_desac = 52.0 * 0.18 = 9.36
    assert row['estoque_final_desacob'] == 4.0
    assert round(row['ICMS_estoque_desac'], 2) == 9.36
