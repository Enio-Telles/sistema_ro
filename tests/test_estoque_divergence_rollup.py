from datetime import date

import polars as pl

from pipeline.estoque.derivados_fiscais_v3 import build_aba_anual_v3, build_aba_periodos_v3


def test_derivados_fiscais_v3_roll_up_inventory_divergences() -> None:
    mov_df = pl.DataFrame([
        {
            'id_agrupado': 'AGR1',
            'dt_e_s': date(2024, 1, 31),
            'dt_doc': date(2024, 1, 31),
            'tipo_operacao': '3 - ESTOQUE FINAL',
            'qtd': 10.0,
            'q_conv': 0.0,
            'vl_item': 0.0,
            'preco_unit': 10.0,
            'saldo_estoque_anual': 8.0,
            'saldo_estoque_periodo': 8.0,
            'entr_desac_anual': 0.0,
            'entr_desac_periodo': 0.0,
            'co_sefin_agr': '1234',
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
            'descr_padrao': 'Produto A',
            'unid_ref': 'UN',
            'periodo_inventario': 1,
            'divergencia_estoque_declarado': 2.0,
            'divergencia_estoque_calculado': 0.0,
        },
        {
            'id_agrupado': 'AGR1',
            'dt_e_s': date(2024, 2, 10),
            'dt_doc': date(2024, 2, 10),
            'tipo_operacao': '3 - ESTOQUE FINAL',
            'qtd': 7.0,
            'q_conv': 0.0,
            'vl_item': 0.0,
            'preco_unit': 10.0,
            'saldo_estoque_anual': 9.0,
            'saldo_estoque_periodo': 9.0,
            'entr_desac_anual': 0.0,
            'entr_desac_periodo': 0.0,
            'co_sefin_agr': '1234',
            'it_pc_interna': 17.0,
            'it_in_st': 'N',
            'descr_padrao': 'Produto A',
            'unid_ref': 'UN',
            'periodo_inventario': 2,
            'divergencia_estoque_declarado': 0.0,
            'divergencia_estoque_calculado': 2.0,
        },
    ])

    anual = build_aba_anual_v3(mov_df)
    periodos = build_aba_periodos_v3(mov_df)

    anual_row = anual.to_dicts()[0]
    period_rows = periodos.sort('cod_per').to_dicts()

    assert anual_row['divergencia_estoque_declarado'] == 2.0
    assert anual_row['divergencia_estoque_calculado'] == 2.0
    assert period_rows[0]['divergencia_estoque_declarado'] == 2.0
    assert period_rows[0]['divergencia_estoque_calculado'] == 0.0
    assert period_rows[1]['divergencia_estoque_declarado'] == 0.0
    assert period_rows[1]['divergencia_estoque_calculado'] == 2.0
