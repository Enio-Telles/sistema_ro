from datetime import date

import polars as pl

from pipeline.estoque.derivados_fiscais_v4 import build_aba_periodos_v4


def test_build_aba_periodos_v4_computes_period_icms_without_st() -> None:
    mov = pl.DataFrame([
        {
            'id_agrupado': 'P9',
            'periodo_inventario': 1,
            'descr_padrao': 'FEIJAO',
            'unid_ref': 'UN',
            'tipo_operacao': '0 - ESTOQUE INICIAL',
            'dt_e_s': date(2024, 2, 1),
            'dt_doc': date(2024, 1, 31),
            'q_conv': 5.0,
            'qtd': 5.0,
            'preco_unit': 10.0,
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
            'dt_e_s': date(2024, 2, 15),
            'dt_doc': date(2024, 2, 15),
            'q_conv': 5.0,
            'qtd': 5.0,
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
            'dt_e_s': date(2024, 2, 29),
            'dt_doc': date(2024, 2, 29),
            'q_conv': 0.0,
            'qtd': 8.0,
            '__qtd_decl_final_audit__': 8.0,
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
    assert row['saidas_desacob'] == 0.0
    assert row['estoque_final_desacob'] == 2.0
    assert row['ICMS_saidas_desac'] == 0.0
    assert row['ICMS_estoque_desac'] == 3.6
    assert row['data_inicio'] == date(2024, 2, 1)
    assert row['data_fim'] == date(2024, 2, 29)
    assert row['periodo_label'] == '01/02/2024 até 29/02/2024'


def test_build_aba_periodos_v4_prefers_declared_inventory_audit_quantity() -> None:
    mov = pl.DataFrame([
        {
            'id_agrupado': 'P10',
            'periodo_inventario': 2,
            'descr_padrao': 'MILHO',
            'unid_ref': 'UN',
            'tipo_operacao': '0 - ESTOQUE INICIAL',
            'dt_e_s': date(2024, 3, 1),
            'dt_doc': date(2024, 2, 29),
            'q_conv': 5.0,
            'qtd': 5.0,
            'preco_unit': 10.0,
            'entr_desac_periodo': 0.0,
            'saldo_estoque_periodo': 5.0,
            'it_pc_interna': 18.0,
            'it_in_st': 'N',
        },
        {
            'id_agrupado': 'P10',
            'periodo_inventario': 2,
            'descr_padrao': 'MILHO',
            'unid_ref': 'UN',
            'tipo_operacao': '3 - ESTOQUE FINAL',
            'dt_e_s': date(2024, 3, 31),
            'dt_doc': date(2024, 3, 31),
            'q_conv': 0.0,
            'qtd': 99.0,
            '__qtd_decl_final_audit__': 7.0,
            'preco_unit': None,
            'entr_desac_periodo': 0.0,
            'saldo_estoque_periodo': 5.0,
            'it_pc_interna': 18.0,
            'it_in_st': 'N',
        },
    ])

    result = build_aba_periodos_v4(mov)
    row = result.row(0, named=True)

    assert row['estoque_final'] == 7.0
    assert row['saidas_desacob'] == 2.0


def test_build_aba_periodos_v4_resolves_st_by_period_vigencia() -> None:
    mov = pl.DataFrame([
        {
            'id_agrupado': 'P11',
            'periodo_inventario': 3,
            'descr_padrao': 'OLEO',
            'unid_ref': 'UN',
            'tipo_operacao': '0 - ESTOQUE INICIAL',
            'dt_e_s': date(2024, 4, 1),
            'dt_doc': date(2024, 3, 31),
            'q_conv': 5.0,
            'qtd': 5.0,
            'preco_unit': 10.0,
            'entr_desac_periodo': 0.0,
            'saldo_estoque_periodo': 5.0,
            'co_sefin_agr': '1234',
            'it_pc_interna': 12.0,
            'it_in_st': 'N',
            'it_pc_mva': 10.0,
        },
        {
            'id_agrupado': 'P11',
            'periodo_inventario': 3,
            'descr_padrao': 'OLEO',
            'unid_ref': 'UN',
            'tipo_operacao': '3 - ESTOQUE FINAL',
            'dt_e_s': date(2024, 4, 30),
            'dt_doc': date(2024, 4, 30),
            'q_conv': 0.0,
            'qtd': 8.0,
            '__qtd_decl_final_audit__': 8.0,
            'preco_unit': None,
            'entr_desac_periodo': 0.0,
            'saldo_estoque_periodo': 5.0,
            'co_sefin_agr': '1234',
            'it_pc_interna': 12.0,
            'it_in_st': 'N',
            'it_pc_mva': 10.0,
        },
    ])
    vigencia = pl.DataFrame([
        {
            'co_sefin': '1234',
            'it_da_inicio': date(2024, 4, 1),
            'it_da_final': date(2024, 4, 30),
            'it_pc_interna': 18.0,
            'it_in_st': 'S',
            'it_pc_mva': 40.0,
            'it_in_mva_ajustado': 'N',
        }
    ])

    result = build_aba_periodos_v4(mov, vigencia_df=vigencia)
    row = result.row(0, named=True)

    assert row['ST'] == 'ST'
    assert row['aliq_interna'] == 18.0
    assert row['it_in_st'] == 'S'
    assert row['it_pc_mva'] == 40.0
    assert row['ICMS_saidas_desac'] == 0.0


def test_build_aba_periodos_v4_sums_incremental_uncovered_entries_once_per_exit() -> None:
    mov = pl.DataFrame([
        {
            'id_agrupado': 'P12',
            'periodo_inventario': 1,
            'descr_padrao': 'SEMOLA',
            'unid_ref': 'UN',
            'tipo_operacao': '0 - ESTOQUE INICIAL',
            'dt_e_s': date(2024, 2, 1),
            'dt_doc': date(2024, 1, 31),
            'q_conv': 5.0,
            'qtd': 5.0,
            'preco_unit': 10.0,
            'entr_desac_periodo': 0.0,
            'saldo_estoque_periodo': 5.0,
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
        },
        {
            'id_agrupado': 'P12',
            'periodo_inventario': 1,
            'descr_padrao': 'SEMOLA',
            'unid_ref': 'UN',
            'tipo_operacao': '2 - SAIDAS',
            'dt_e_s': date(2024, 2, 5),
            'dt_doc': date(2024, 2, 5),
            'q_conv': 8.0,
            'qtd': 8.0,
            'preco_unit': 10.0,
            'entr_desac_periodo': 3.0,
            'saldo_estoque_periodo': 0.0,
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
        },
        {
            'id_agrupado': 'P12',
            'periodo_inventario': 1,
            'descr_padrao': 'SEMOLA',
            'unid_ref': 'UN',
            'tipo_operacao': '2 - SAIDAS',
            'dt_e_s': date(2024, 2, 6),
            'dt_doc': date(2024, 2, 6),
            'q_conv': 2.0,
            'qtd': 2.0,
            'preco_unit': 10.0,
            'entr_desac_periodo': 2.0,
            'saldo_estoque_periodo': 0.0,
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
        },
        {
            'id_agrupado': 'P12',
            'periodo_inventario': 1,
            'descr_padrao': 'SEMOLA',
            'unid_ref': 'UN',
            'tipo_operacao': '3 - ESTOQUE FINAL',
            'dt_e_s': date(2024, 2, 29),
            'dt_doc': date(2024, 2, 29),
            'q_conv': 0.0,
            'qtd': 0.0,
            '__qtd_decl_final_audit__': 0.0,
            'preco_unit': None,
            'entr_desac_periodo': 0.0,
            'saldo_estoque_periodo': 0.0,
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
        },
    ])

    result = build_aba_periodos_v4(mov)
    row = result.row(0, named=True)

    assert row['estoque_inicial'] == 5.0
    assert row['saidas'] == 10.0
    assert row['entradas_desacob'] == 5.0
    assert row['saidas_calculadas'] == 10.0
    assert row['saldo_final'] == 0.0
    assert row['saidas_desacob'] == 0.0
    assert row['estoque_final_desacob'] == 0.0


def test_build_aba_periodos_v4_keeps_desacob_metrics_aligned_with_inventory_divergence() -> None:
    mov = pl.DataFrame([
        {
            'id_agrupado': 'P13',
            'periodo_inventario': 1,
            'descr_padrao': 'TRIGO',
            'unid_ref': 'UN',
            'tipo_operacao': '3 - ESTOQUE FINAL',
            'dt_e_s': date(2024, 1, 31),
            'dt_doc': date(2024, 1, 31),
            'q_conv': 0.0,
            'qtd': 10.0,
            '__qtd_decl_final_audit__': 10.0,
            'preco_unit': 10.0,
            'entr_desac_periodo': 0.0,
            'saldo_estoque_periodo': 8.0,
            'co_sefin_agr': '901',
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
            'divergencia_estoque_declarado': 2.0,
            'divergencia_estoque_calculado': 0.0,
        },
        {
            'id_agrupado': 'P13',
            'periodo_inventario': 2,
            'descr_padrao': 'TRIGO',
            'unid_ref': 'UN',
            'tipo_operacao': '3 - ESTOQUE FINAL',
            'dt_e_s': date(2024, 2, 29),
            'dt_doc': date(2024, 2, 29),
            'q_conv': 0.0,
            'qtd': 8.0,
            '__qtd_decl_final_audit__': 8.0,
            'preco_unit': 10.0,
            'entr_desac_periodo': 0.0,
            'saldo_estoque_periodo': 10.0,
            'co_sefin_agr': '901',
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
            'divergencia_estoque_declarado': 0.0,
            'divergencia_estoque_calculado': 2.0,
        },
    ])

    result = build_aba_periodos_v4(mov).sort('cod_per').to_dicts()

    assert result[0]['divergencia_estoque_declarado'] == 2.0
    assert result[0]['divergencia_estoque_calculado'] == 0.0
    assert result[0]['saidas_desacob'] == 2.0
    assert result[0]['estoque_final_desacob'] == 0.0
    assert result[1]['divergencia_estoque_declarado'] == 0.0
    assert result[1]['divergencia_estoque_calculado'] == 2.0
    assert result[1]['saidas_desacob'] == 0.0
    assert result[1]['estoque_final_desacob'] == 2.0


def test_build_aba_periodos_v4_keeps_st_and_inventory_divergence_independent_from_uncovered_entries() -> None:
    mov = pl.DataFrame([
        {
            'id_agrupado': 'P14',
            'periodo_inventario': 3,
            'descr_padrao': 'OLEO',
            'unid_ref': 'UN',
            'tipo_operacao': '0 - ESTOQUE INICIAL',
            'dt_e_s': date(2024, 4, 1),
            'dt_doc': date(2024, 3, 31),
            'q_conv': 5.0,
            'qtd': 5.0,
            'preco_unit': 10.0,
            'entr_desac_periodo': 0.0,
            'saldo_estoque_periodo': 5.0,
            'co_sefin_agr': '1235',
            'it_pc_interna': 12.0,
            'it_in_st': 'N',
            'it_pc_mva': 10.0,
        },
        {
            'id_agrupado': 'P14',
            'periodo_inventario': 3,
            'descr_padrao': 'OLEO',
            'unid_ref': 'UN',
            'tipo_operacao': '2 - SAIDAS',
            'dt_e_s': date(2024, 4, 10),
            'dt_doc': date(2024, 4, 10),
            'q_conv': 8.0,
            'qtd': 8.0,
            'preco_unit': 15.0,
            'entr_desac_periodo': 3.0,
            'saldo_estoque_periodo': 0.0,
            'co_sefin_agr': '1235',
            'it_pc_interna': 12.0,
            'it_in_st': 'N',
            'it_pc_mva': 10.0,
        },
        {
            'id_agrupado': 'P14',
            'periodo_inventario': 3,
            'descr_padrao': 'OLEO',
            'unid_ref': 'UN',
            'tipo_operacao': '3 - ESTOQUE FINAL',
            'dt_e_s': date(2024, 4, 30),
            'dt_doc': date(2024, 4, 30),
            'q_conv': 0.0,
            'qtd': 2.0,
            '__qtd_decl_final_audit__': 2.0,
            'preco_unit': None,
            'entr_desac_periodo': 0.0,
            'saldo_estoque_periodo': 0.0,
            'co_sefin_agr': '1235',
            'it_pc_interna': 12.0,
            'it_in_st': 'N',
            'it_pc_mva': 10.0,
            'divergencia_estoque_declarado': 2.0,
            'divergencia_estoque_calculado': 0.0,
        },
    ])
    vigencia = pl.DataFrame([
        {
            'co_sefin': '1235',
            'it_da_inicio': date(2024, 4, 1),
            'it_da_final': date(2024, 4, 30),
            'it_pc_interna': 18.0,
            'it_in_st': 'S',
            'it_pc_mva': 40.0,
            'it_in_mva_ajustado': 'N',
        }
    ])

    result = build_aba_periodos_v4(mov, vigencia_df=vigencia)
    row = result.row(0, named=True)

    assert row['ST'] == 'ST'
    assert row['entradas_desacob'] == 3.0
    assert row['saidas_calculadas'] == 6.0
    assert row['saidas'] == 8.0
    assert row['saidas_desacob'] == 2.0
    assert row['estoque_final_desacob'] == 0.0
    assert row['ICMS_saidas_desac'] == 0.0
    assert row['ICMS_estoque_desac'] == 0.0
