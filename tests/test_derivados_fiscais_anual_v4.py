import polars as pl

from pipeline.estoque.derivados_fiscais_v4 import build_aba_anual_v4


def test_build_aba_anual_v4_zeros_saida_icms_when_st_and_keeps_estoque_icms() -> None:
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
            'preco_unit': 10.0,
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
            'q_conv': 0.0,
            'qtd': 8.0,
            '__qtd_decl_final_audit__': 8.0,
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
    assert row['ST'] == 'ST'
    assert row['saidas_desacob'] == 0.0
    assert row['estoque_final_desacob'] == 3.0
    assert row['ICMS_saidas_desac'] == 0.0
    assert row['ICMS_estoque_desac'] == 7.65


def test_build_aba_anual_v4_prefers_declared_inventory_audit_quantity() -> None:
    mov = pl.DataFrame([
        {
            'id_agrupado': 'P2',
            'descr_padrao': 'CAFE',
            'unid_ref': 'UN',
            'tipo_operacao': '0 - ESTOQUE INICIAL',
            'dt_doc': '2024-01-01',
            'dt_e_s': '2024-01-01',
            'q_conv': 5.0,
            'qtd': 5.0,
            'preco_unit': 10.0,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 5.0,
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
        },
        {
            'id_agrupado': 'P2',
            'descr_padrao': 'CAFE',
            'unid_ref': 'UN',
            'tipo_operacao': '3 - ESTOQUE FINAL',
            'dt_doc': '2024-12-31',
            'dt_e_s': '2024-12-31',
            'q_conv': 0.0,
            'qtd': 99.0,
            '__qtd_decl_final_audit__': 7.0,
            'preco_unit': None,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 5.0,
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
        },
    ])

    result = build_aba_anual_v4(mov)
    row = result.row(0, named=True)

    assert row['estoque_final'] == 7.0
    assert row['saidas_desacob'] == 2.0


def test_build_aba_anual_v4_resolves_st_by_year_vigencia() -> None:
    mov = pl.DataFrame([
        {
            'id_agrupado': 'P3',
            'descr_padrao': 'FEIJAO',
            'unid_ref': 'UN',
            'tipo_operacao': '0 - ESTOQUE INICIAL',
            'dt_doc': '2024-01-01',
            'dt_e_s': '2024-01-01',
            'q_conv': 5.0,
            'qtd': 5.0,
            'preco_unit': 10.0,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 5.0,
            'co_sefin_agr': '789',
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
        },
        {
            'id_agrupado': 'P3',
            'descr_padrao': 'FEIJAO',
            'unid_ref': 'UN',
            'tipo_operacao': '1 - ENTRADA',
            'dt_doc': '2024-06-10',
            'dt_e_s': '2024-06-10',
            'q_conv': 10.0,
            'qtd': 10.0,
            'preco_unit': 10.0,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 15.0,
            'co_sefin_agr': '789',
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
        },
        {
            'id_agrupado': 'P3',
            'descr_padrao': 'FEIJAO',
            'unid_ref': 'UN',
            'tipo_operacao': '2 - SAIDAS',
            'dt_doc': '2024-06-15',
            'dt_e_s': '2024-06-15',
            'q_conv': 4.0,
            'qtd': 4.0,
            'preco_unit': 15.0,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 11.0,
            'co_sefin_agr': '789',
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
        },
        {
            'id_agrupado': 'P3',
            'descr_padrao': 'FEIJAO',
            'unid_ref': 'UN',
            'tipo_operacao': '3 - ESTOQUE FINAL',
            'dt_doc': '2024-12-31',
            'dt_e_s': '2024-12-31',
            'q_conv': 0.0,
            'qtd': 8.0,
            '__qtd_decl_final_audit__': 8.0,
            'preco_unit': None,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 11.0,
            'co_sefin_agr': '789',
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
        },
    ])
    vigencia = pl.DataFrame([
        {
            'co_sefin': '789',
            'it_da_inicio': '2024-01-01',
            'it_da_final': '2024-12-31',
            'it_pc_interna': 19.0,
            'it_in_st': 'S',
        }
    ])

    result = build_aba_anual_v4(mov, vigencia_df=vigencia)
    row = result.row(0, named=True)

    assert row['ST'] == 'ST'
    assert row['aliq_interna'] == 19.0
    assert row['saidas_desacob'] == 0.0
    assert row['estoque_final_desacob'] == 3.0
    assert row['ICMS_saidas_desac'] == 0.0
    assert row['ICMS_estoque_desac'] == 8.55
