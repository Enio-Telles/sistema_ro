from datetime import date

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


def test_build_aba_anual_v4_rolls_up_inventory_divergences_across_multiple_closings() -> None:
    mov = pl.DataFrame([
        {
            'id_agrupado': 'P4',
            'descr_padrao': 'ACUCAR',
            'unid_ref': 'UN',
            'tipo_operacao': '3 - ESTOQUE FINAL',
            'dt_doc': date(2024, 1, 31),
            'dt_e_s': date(2024, 1, 31),
            'q_conv': 0.0,
            'qtd': 10.0,
            '__qtd_decl_final_audit__': 10.0,
            'preco_unit': 10.0,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 8.0,
            'co_sefin_agr': '900',
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
            'periodo_inventario': 1,
            'divergencia_estoque_declarado': 2.0,
            'divergencia_estoque_calculado': 0.0,
        },
        {
            'id_agrupado': 'P4',
            'descr_padrao': 'ACUCAR',
            'unid_ref': 'UN',
            'tipo_operacao': '3 - ESTOQUE FINAL',
            'dt_doc': date(2024, 2, 10),
            'dt_e_s': date(2024, 2, 10),
            'q_conv': 0.0,
            'qtd': 7.0,
            '__qtd_decl_final_audit__': 7.0,
            'preco_unit': 10.0,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 9.0,
            'co_sefin_agr': '900',
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
            'periodo_inventario': 2,
            'divergencia_estoque_declarado': 0.0,
            'divergencia_estoque_calculado': 2.0,
        },
    ])

    result = build_aba_anual_v4(mov)
    row = result.row(0, named=True)

    assert row['divergencia_estoque_declarado'] == 2.0
    assert row['divergencia_estoque_calculado'] == 2.0
    assert row['saidas_desacob'] == 2.0
    assert row['estoque_final_desacob'] == 2.0


def test_build_aba_anual_v4_keeps_incremental_uncovered_entries_separate_from_final_inventory_divergence() -> None:
    mov = pl.DataFrame([
        {
            'id_agrupado': 'P5',
            'descr_padrao': 'FARINHA',
            'unid_ref': 'UN',
            'tipo_operacao': '0 - ESTOQUE INICIAL',
            'dt_doc': date(2024, 1, 1),
            'dt_e_s': date(2024, 1, 1),
            'q_conv': 5.0,
            'qtd': 5.0,
            'preco_unit': 8.0,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 5.0,
            'co_sefin_agr': '910',
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
        },
        {
            'id_agrupado': 'P5',
            'descr_padrao': 'FARINHA',
            'unid_ref': 'UN',
            'tipo_operacao': '1 - ENTRADA',
            'dt_doc': date(2024, 1, 10),
            'dt_e_s': date(2024, 1, 10),
            'q_conv': 4.0,
            'qtd': 4.0,
            'preco_unit': 10.0,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 9.0,
            'co_sefin_agr': '910',
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
        },
        {
            'id_agrupado': 'P5',
            'descr_padrao': 'FARINHA',
            'unid_ref': 'UN',
            'tipo_operacao': '2 - SAIDAS',
            'dt_doc': date(2024, 1, 20),
            'dt_e_s': date(2024, 1, 20),
            'q_conv': 12.0,
            'qtd': 12.0,
            'preco_unit': 15.0,
            'entr_desac_anual': 3.0,
            'saldo_estoque_anual': 0.0,
            'co_sefin_agr': '910',
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
        },
        {
            'id_agrupado': 'P5',
            'descr_padrao': 'FARINHA',
            'unid_ref': 'UN',
            'tipo_operacao': '3 - ESTOQUE FINAL',
            'dt_doc': date(2024, 12, 31),
            'dt_e_s': date(2024, 12, 31),
            'q_conv': 0.0,
            'qtd': 2.0,
            '__qtd_decl_final_audit__': 2.0,
            'preco_unit': None,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 0.0,
            'co_sefin_agr': '910',
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
            'divergencia_estoque_declarado': 2.0,
            'divergencia_estoque_calculado': 0.0,
        },
    ])

    result = build_aba_anual_v4(mov)
    row = result.row(0, named=True)

    assert row['entradas_desacob'] == 3.0
    assert row['saidas_calculadas'] == 10.0
    assert row['saidas'] == 12.0
    assert row['saidas_desacob'] == 2.0
    assert row['estoque_final_desacob'] == 0.0
    assert row['ICMS_saidas_desac'] == 5.1
    assert row['ICMS_estoque_desac'] == 0.0


def test_build_aba_anual_v4_keeps_icms_estoque_desac_with_st_when_multiple_closings_roll_up_both_divergences() -> None:
    mov = pl.DataFrame([
        {
            'id_agrupado': 'P6',
            'descr_padrao': 'MACARRAO',
            'unid_ref': 'UN',
            'tipo_operacao': '0 - ESTOQUE INICIAL',
            'dt_doc': date(2024, 1, 1),
            'dt_e_s': date(2024, 1, 1),
            'q_conv': 5.0,
            'qtd': 5.0,
            'preco_unit': 10.0,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 5.0,
            'co_sefin_agr': '920',
            'it_pc_interna': 12.0,
            'it_in_st': 'N',
        },
        {
            'id_agrupado': 'P6',
            'descr_padrao': 'MACARRAO',
            'unid_ref': 'UN',
            'tipo_operacao': '2 - SAIDAS',
            'dt_doc': date(2024, 1, 10),
            'dt_e_s': date(2024, 1, 10),
            'q_conv': 2.0,
            'qtd': 2.0,
            'preco_unit': 20.0,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 3.0,
            'co_sefin_agr': '920',
            'it_pc_interna': 12.0,
            'it_in_st': 'N',
        },
        {
            'id_agrupado': 'P6',
            'descr_padrao': 'MACARRAO',
            'unid_ref': 'UN',
            'tipo_operacao': '2 - SAIDAS',
            'dt_doc': date(2024, 2, 10),
            'dt_e_s': date(2024, 2, 10),
            'q_conv': 1.0,
            'qtd': 1.0,
            'preco_unit': 30.0,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 2.0,
            'co_sefin_agr': '920',
            'it_pc_interna': 12.0,
            'it_in_st': 'N',
        },
        {
            'id_agrupado': 'P6',
            'descr_padrao': 'MACARRAO',
            'unid_ref': 'UN',
            'tipo_operacao': '3 - ESTOQUE FINAL',
            'dt_doc': date(2024, 3, 31),
            'dt_e_s': date(2024, 3, 31),
            'q_conv': 0.0,
            'qtd': 1.0,
            '__qtd_decl_final_audit__': 1.0,
            'preco_unit': None,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 0.0,
            'co_sefin_agr': '920',
            'it_pc_interna': 12.0,
            'it_in_st': 'N',
            'periodo_inventario': 1,
            'divergencia_estoque_declarado': 1.0,
            'divergencia_estoque_calculado': 0.0,
        },
        {
            'id_agrupado': 'P6',
            'descr_padrao': 'MACARRAO',
            'unid_ref': 'UN',
            'tipo_operacao': '3 - ESTOQUE FINAL',
            'dt_doc': date(2024, 12, 31),
            'dt_e_s': date(2024, 12, 31),
            'q_conv': 0.0,
            'qtd': 2.0,
            '__qtd_decl_final_audit__': 2.0,
            'preco_unit': None,
            'entr_desac_anual': 0.0,
            'saldo_estoque_anual': 4.0,
            'co_sefin_agr': '920',
            'it_pc_interna': 12.0,
            'it_in_st': 'N',
            'periodo_inventario': 2,
            'divergencia_estoque_declarado': 0.0,
            'divergencia_estoque_calculado': 2.0,
        },
    ])
    vigencia = pl.DataFrame([
        {
            'co_sefin': '920',
            'it_da_inicio': date(2024, 1, 1),
            'it_da_final': date(2024, 12, 31),
            'it_pc_interna': 18.0,
            'it_in_st': 'S',
        }
    ])

    result = build_aba_anual_v4(mov, vigencia_df=vigencia)
    row = result.row(0, named=True)

    assert row['ST'] == 'ST'
    assert row['divergencia_estoque_declarado'] == 1.0
    assert row['divergencia_estoque_calculado'] == 2.0
    assert row['saidas_desacob'] == 1.0
    assert row['estoque_final_desacob'] == 2.0
    assert row['ICMS_saidas_desac'] == 0.0
    assert row['ICMS_estoque_desac'] == 9.0
