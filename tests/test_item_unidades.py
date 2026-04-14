import polars as pl

from pipeline.conversao.item_unidades import build_item_unidades


def test_build_item_unidades_groups_joined_items() -> None:
    itens = pl.DataFrame([
        {'codigo_fonte': '123|A', 'id_agrupado': 'PROD_1', 'unid': 'UN', 'qtd': 10.0, 'vl_item': 100.0},
        {'codigo_fonte': '123|A', 'id_agrupado': 'PROD_1', 'unid': 'UN', 'qtd': 5.0, 'vl_item': 60.0},
    ])
    produtos = pl.DataFrame([
        {'codigo_fonte': '123|A', 'id_agrupado': 'PROD_1', 'mercadoria_id': 'M1', 'apresentacao_id': 'A1', 'unid_ref': 'UN'}
    ])
    result = build_item_unidades(itens, produtos)
    assert result.height == 1
    assert result['qtd_total'][0] == 15.0
    assert result['valor_total'][0] == 160.0
