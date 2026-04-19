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


def test_aggregation_v2_normalizes_accents_and_keeps_provenance() -> None:
    itens = pl.DataFrame([
        {
            'id_linha_origem': 'nfe|3|1',
            'codigo_fonte': '123|C',
            'codigo_produto_original': 'C',
            'descr_item': 'Óleo de Soja',
            'descr_compl': '',
            'tipo_item': '00',
            'ncm': '15079011',
            'cest': '0200100',
            'gtin_padrao': '111',
            'unid': 'UN',
        },
        {
            'id_linha_origem': 'nfe|4|1',
            'codigo_fonte': '123|D',
            'codigo_produto_original': 'D',
            'descr_item': 'OLEO DE SOJA',
            'descr_compl': '',
            'tipo_item': '00',
            'ncm': '15079011',
            'cest': '0200100',
            'gtin_padrao': '222',
            'unid': 'CX',
        },
    ])

    result = build_agrupamento_v2(itens, versao_agrupamento='2026.04')
    mapa = result['map_produto_agrupado']
    grupos = result['produtos_agrupados']

    assert mapa['descricao_normalizada'][0] == 'OLEO DE SOJA'
    assert mapa['id_agrupado'][0] == mapa['id_agrupado'][1]
    assert mapa['id_agrupado_final'][0] == mapa['id_agrupado'][0]
    assert mapa['manual_override_aplicado'][0] is False
    assert mapa['origem_agrupamento'][0] == 'auto'
    assert grupos['versao_agrupamento'][0] == '2026.04'
    assert grupos['origem_agrupamento'][0] == 'auto'


def test_aggregation_v2_preserves_manual_grouping_provenance() -> None:
    itens = pl.DataFrame([
        {
            'id_linha_origem': 'nfe|5|1',
            'codigo_fonte': '123|E',
            'codigo_produto_original': 'E',
            'descr_item': 'ARROZ ESPECIAL',
            'descr_compl': '',
            'tipo_item': '00',
            'ncm': '10063021',
            'cest': '0100100',
            'gtin_padrao': '333',
            'unid': 'UN',
        }
    ])
    mapa_manual = pl.DataFrame([
        {'codigo_fonte': '123|E', 'id_agrupado_manual': 'AGR_MANUAL_001'}
    ])

    result = build_agrupamento_v2(itens, mapa_manual_df=mapa_manual, versao_agrupamento='manual.v1')
    mapa = result['map_produto_agrupado'].row(0, named=True)
    grupo = result['produtos_agrupados'].row(0, named=True)

    assert mapa['id_agrupado'] == 'AGR_MANUAL_001'
    assert mapa['id_agrupado_final'] == 'AGR_MANUAL_001'
    assert mapa['id_agrupado_auto'] != 'AGR_MANUAL_001'
    assert mapa['manual_override_aplicado'] is True
    assert mapa['origem_agrupamento'] == 'manual'
    assert mapa['regra_agrupamento'] == 'codigo_fonte→id_agrupado_manual'
    assert grupo['tem_override_manual'] is True
    assert grupo['origem_agrupamento'] == 'manual'
    assert grupo['versao_agrupamento'] == 'manual.v1'
