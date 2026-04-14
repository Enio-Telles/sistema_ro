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
            'q_conv': 0.0,
            'qtd': 8.0,
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
