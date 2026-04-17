import polars as pl

from pipeline.estoque.mov_estoque_v2 import build_mov_estoque_v2


def test_build_mov_estoque_v2_adds_periods_and_inventory_rows() -> None:
    c170 = pl.DataFrame([
        {'id_agrupado': 'P1', 'id_linha_origem': 'c170|1|1|1', 'qtd': 10.0, 'vl_item': 100.0, 'dt_doc': '2024-01-10'}
    ])
    nfe = pl.DataFrame([
        {'id_agrupado': 'P1', 'id_linha_origem': 'nfe|1|1', 'qtd': 4.0, 'vl_item': 60.0, 'dt_doc': '2024-01-11'}
    ])
    nfce = pl.DataFrame()
    bloco_h = pl.DataFrame([
        {'id_agrupado': 'P1', 'bloco_h_id': 'BH1', 'cod_item': 'A', 'qtd': 8.0, 'vl_item': 0.0, 'dt_doc': '2024-01-31'}
    ])
    fatores = pl.DataFrame([
        {'id_agrupado': 'P1', 'unid_ref': 'UN', 'fator': 1.0, 'tipo_fator': 'preco', 'confianca_fator': 0.6, 'fonte_fator': 'preco_medio_relativo'}
    ])
    result = build_mov_estoque_v2(c170, nfe, nfce, bloco_h, fatores)
    assert result.filter(pl.col('tipo_operacao') == '0 - ESTOQUE INICIAL').height == 1
    assert result.filter(pl.col('tipo_operacao') == '3 - ESTOQUE FINAL').height == 1
    assert 'periodo_inventario' in result.columns
    assert '__qtd_decl_final_audit__' in result.columns
    assert 'divergencia_estoque_declarado' in result.columns
    final_row = result.filter(pl.col('tipo_operacao') == '3 - ESTOQUE FINAL').to_dicts()[0]
    assert final_row['q_conv'] == 0.0
    assert final_row['__qtd_decl_final_audit__'] == 8.0


def test_build_mov_estoque_v2_keeps_declared_inventory_out_of_physical_balance() -> None:
    bloco_h = pl.DataFrame([
        {'id_agrupado': 'P2', 'id_linha_origem': 'h1', 'qtd': 8.0, 'vl_item': 80.0, 'dt_doc': '2024-01-31'}
    ])
    fatores = pl.DataFrame([
        {'id_agrupado': 'P2', 'unid_ref': 'UN', 'fator': 1.0}
    ])

    result = build_mov_estoque_v2(
        c170_df=pl.DataFrame(),
        nfe_df=pl.DataFrame(),
        nfce_df=pl.DataFrame(),
        bloco_h_df=bloco_h,
        fatores_df=fatores,
    ).select(['tipo_operacao', 'q_conv', 'saldo_estoque_periodo', '__qtd_decl_final_audit__']).to_dicts()

    assert result[0]['tipo_operacao'] == '3 - ESTOQUE FINAL'
    assert result[0]['q_conv'] == 0.0
    assert result[0]['saldo_estoque_periodo'] == 0.0
    assert result[0]['__qtd_decl_final_audit__'] == 8.0
    assert result[1]['tipo_operacao'] == '0 - ESTOQUE INICIAL'
    assert result[1]['q_conv'] == 8.0
    assert result[1]['saldo_estoque_periodo'] == 8.0


def test_build_mov_estoque_v2_records_only_incremental_uncovered_amount_per_exit() -> None:
    nfe = pl.DataFrame([
        {'id_agrupado': 'P3', 'id_linha_origem': 'n1', 'qtd': 8.0, 'vl_item': 80.0, 'dt_doc': '2024-02-05', 'dt_e_s': '2024-02-05'},
        {'id_agrupado': 'P3', 'id_linha_origem': 'n2', 'qtd': 2.0, 'vl_item': 20.0, 'dt_doc': '2024-02-06', 'dt_e_s': '2024-02-06'},
    ])
    bloco_h = pl.DataFrame([
        {'id_agrupado': 'P3', 'id_linha_origem': 'h0', 'qtd': 5.0, 'vl_item': 50.0, 'dt_doc': '2024-01-31'},
        {'id_agrupado': 'P3', 'id_linha_origem': 'h1', 'qtd': 0.0, 'vl_item': 0.0, 'dt_doc': '2024-02-29'},
    ])
    fatores = pl.DataFrame([
        {'id_agrupado': 'P3', 'unid_ref': 'UN', 'fator': 1.0}
    ])

    result = build_mov_estoque_v2(
        c170_df=pl.DataFrame(),
        nfe_df=nfe,
        nfce_df=pl.DataFrame(),
        bloco_h_df=bloco_h,
        fatores_df=fatores,
    )

    saidas = result.filter(pl.col('tipo_operacao') == '2 - SAIDAS').select([
        'id_linha_origem',
        'entr_desac_anual',
        'entr_desac_periodo',
        'saldo_estoque_anual',
        'saldo_estoque_periodo',
    ]).to_dicts()

    assert saidas[0]['id_linha_origem'] == 'n1'
    assert saidas[0]['entr_desac_anual'] == 3.0
    assert saidas[0]['entr_desac_periodo'] == 3.0
    assert saidas[0]['saldo_estoque_anual'] == 0.0
    assert saidas[0]['saldo_estoque_periodo'] == 0.0

    assert saidas[1]['id_linha_origem'] == 'n2'
    assert saidas[1]['entr_desac_anual'] == 2.0
    assert saidas[1]['entr_desac_periodo'] == 2.0
    assert saidas[1]['saldo_estoque_anual'] == 0.0
    assert saidas[1]['saldo_estoque_periodo'] == 0.0
