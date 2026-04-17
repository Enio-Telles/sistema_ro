from datetime import date

import polars as pl

from pipeline.estoque.mov_estoque_v2 import build_mov_estoque_v2
from pipeline.estoque.periodos import build_estoque_inicial_rows


def test_build_estoque_inicial_rows_moves_opening_stock_to_next_day() -> None:
    bloco_h_df = pl.DataFrame([
        {
            'id_agrupado': 'AGR1',
            'dt_doc': date(2024, 1, 31),
            'qtd': 10.0,
            'vl_item': 100.0,
        }
    ])

    result = build_estoque_inicial_rows(bloco_h_df)

    row = result.to_dicts()[0]
    assert row['tipo_operacao'] == '0 - ESTOQUE INICIAL'
    assert row['dt_e_s'] == date(2024, 2, 1)


def test_build_mov_estoque_v2_starts_new_period_after_inventory_close() -> None:
    c170_df = pl.DataFrame([
        {
            'id_agrupado': 'AGR1',
            'id_linha_origem': 'c1',
            'dt_e_s': date(2024, 2, 5),
            'dt_doc': date(2024, 2, 5),
            'qtd': 2.0,
            'vl_item': 30.0,
        }
    ])
    nfe_df = pl.DataFrame()
    nfce_df = pl.DataFrame()
    bloco_h_df = pl.DataFrame([
        {
            'id_agrupado': 'AGR1',
            'id_linha_origem': 'h1',
            'dt_doc': date(2024, 1, 31),
            'qtd': 10.0,
            'vl_item': 100.0,
        }
    ])
    fatores_df = pl.DataFrame([
        {
            'id_agrupado': 'AGR1',
            'fator': 1.0,
        }
    ])

    mov = build_mov_estoque_v2(c170_df, nfe_df, nfce_df, bloco_h_df, fatores_df)
    rows = mov.select(['tipo_operacao', 'dt_e_s', 'periodo_inventario']).to_dicts()

    assert rows[0]['tipo_operacao'] == '3 - ESTOQUE FINAL'
    assert rows[0]['periodo_inventario'] == 1
    assert rows[1]['tipo_operacao'] == '0 - ESTOQUE INICIAL'
    assert rows[1]['dt_e_s'] == date(2024, 2, 1)
    assert rows[1]['periodo_inventario'] == 1
    assert rows[2]['tipo_operacao'] == '1 - ENTRADA'
    assert rows[2]['periodo_inventario'] == 1


def test_build_mov_estoque_v2_resets_period_and_balance_on_second_inventory_cycle() -> None:
    c170_df = pl.DataFrame([
        {
            'id_agrupado': 'AGR1',
            'id_linha_origem': 'c1',
            'dt_e_s': date(2024, 2, 5),
            'dt_doc': date(2024, 2, 5),
            'qtd': 2.0,
            'vl_item': 30.0,
        },
        {
            'id_agrupado': 'AGR1',
            'id_linha_origem': 'c2',
            'dt_e_s': date(2024, 3, 5),
            'dt_doc': date(2024, 3, 5),
            'qtd': 1.0,
            'vl_item': 20.0,
        },
    ])
    nfe_df = pl.DataFrame([
        {
            'id_agrupado': 'AGR1',
            'id_linha_origem': 'n1',
            'dt_e_s': date(2024, 2, 10),
            'dt_doc': date(2024, 2, 10),
            'qtd': 1.0,
            'vl_item': 15.0,
        }
    ])
    nfce_df = pl.DataFrame()
    bloco_h_df = pl.DataFrame([
        {
            'id_agrupado': 'AGR1',
            'id_linha_origem': 'h1',
            'dt_doc': date(2024, 1, 31),
            'qtd': 10.0,
            'vl_item': 100.0,
        },
        {
            'id_agrupado': 'AGR1',
            'id_linha_origem': 'h2',
            'dt_doc': date(2024, 2, 29),
            'qtd': 7.0,
            'vl_item': 70.0,
        },
    ])
    fatores_df = pl.DataFrame([
        {
            'id_agrupado': 'AGR1',
            'fator': 1.0,
        }
    ])

    mov = build_mov_estoque_v2(c170_df, nfe_df, nfce_df, bloco_h_df, fatores_df)
    rows = mov.select([
        'id_linha_origem',
        'tipo_operacao',
        'dt_e_s',
        'periodo_inventario',
        'q_conv',
        'saldo_estoque_periodo',
        '__qtd_decl_final_audit__',
    ]).to_dicts()

    assert rows[0]['id_linha_origem'] == 'h1'
    assert rows[0]['tipo_operacao'] == '3 - ESTOQUE FINAL'
    assert rows[0]['periodo_inventario'] == 1
    assert rows[0]['q_conv'] == 0.0
    assert rows[0]['__qtd_decl_final_audit__'] == 10.0

    assert rows[1]['tipo_operacao'] == '0 - ESTOQUE INICIAL'
    assert rows[1]['dt_e_s'] == date(2024, 2, 1)
    assert rows[1]['periodo_inventario'] == 1
    assert rows[1]['saldo_estoque_periodo'] == 10.0

    assert rows[4]['id_linha_origem'] == 'h2'
    assert rows[4]['tipo_operacao'] == '3 - ESTOQUE FINAL'
    assert rows[4]['periodo_inventario'] == 1
    assert rows[4]['q_conv'] == 0.0
    assert rows[4]['saldo_estoque_periodo'] == 11.0
    assert rows[4]['__qtd_decl_final_audit__'] == 7.0

    assert rows[5]['tipo_operacao'] == '0 - ESTOQUE INICIAL'
    assert rows[5]['dt_e_s'] == date(2024, 3, 1)
    assert rows[5]['periodo_inventario'] == 2
    assert rows[5]['saldo_estoque_periodo'] == 7.0

    assert rows[6]['id_linha_origem'] == 'c2'
    assert rows[6]['tipo_operacao'] == '1 - ENTRADA'
    assert rows[6]['periodo_inventario'] == 2
    assert rows[6]['saldo_estoque_periodo'] == 8.0
