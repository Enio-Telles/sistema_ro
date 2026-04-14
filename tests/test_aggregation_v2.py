import polars as pl

from pipeline.mercadorias.aggregation_v2 import build_agrupamento_v2


def test_aggregation_v2_groups_only_by_normalized_description() -> None:
    itens = pl.DataFrame([
        {
            'id_linha_origem': 'nfe|1|1',
            'codigo_fonte': '123|A',
            'codigo_produto_original': 'A',
            'descr_item': ' Arroz Tipo 1 ',
            'descr_compl': 'Pacote 5kg',
            'tipo_item': '00',
            'ncm': '10063021',
            'cest': '0100100',
            'gtin_padrao': '789',
            'unid': 'UN',
        },
        {
            'id_linha_origem': 'nfe|2|1',
            'codigo_fonte': '123|B',
            'codigo_produto_original': 'B',
            'descr_item': 'ARROZ TIPO 1',
            'descr_compl': 'Fardo',
            'tipo_item': '00',
            'ncm': '10063021',
            'cest': '0100100',
            'gtin_padrao': '000',
            'unid': 'CX',
        },
    ])
    result = build_agrupamento_v2(itens)
    mapa = result['map_produto_agrupado']
    grupos = result['produtos_agrupados']
    assert mapa['id_agrupado'][0] == mapa['id_agrupado'][1]
    assert grupos.height == 1
    assert set(grupos['lista_unidades'][0]) == {'UN', 'CX'}
    assert set(grupos['lista_desc_compl'][0]) == {'Pacote 5kg', 'Fardo'}
