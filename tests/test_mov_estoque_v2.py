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
    assert final_row['__qtd_decl_final_audit__'] == 8.0
