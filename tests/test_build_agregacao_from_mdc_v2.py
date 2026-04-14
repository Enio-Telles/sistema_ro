import polars as pl

from pipeline.mercadorias.build_agregacao_from_mdc_v2 import build_agregacao_from_mdc_base_v2


def test_build_agregacao_from_mdc_base_v2_groups_same_normalized_description() -> None:
    efd_itens = pl.DataFrame([
        {
            'cnpj': '1',
            'id_linha_origem': 'i1',
            'codigo_fonte': '1|A',
            'codigo_produto_original': 'A',
            'descr_item': 'Arroz Tipo 1',
            'descr_compl': 'Pacote',
            'tipo_item': '00',
            'ncm': '10063021',
            'cest': '0100100',
            'gtin_padrao': '111',
            'unid': 'UN',
        },
        {
            'cnpj': '1',
            'id_linha_origem': 'i2',
            'codigo_fonte': '1|B',
            'codigo_produto_original': 'B',
            'descr_item': '  arroz tipo 1  ',
            'descr_compl': 'fardo',
            'tipo_item': '00',
            'ncm': '10063021',
            'cest': '0100100',
            'gtin_padrao': '222',
            'unid': 'UN',
        },
    ])
    result = build_agregacao_from_mdc_base_v2(
        efd_itens_base_df=efd_itens,
        efd_inventario_base_df=pl.DataFrame(),
        efd_produtos_base_df=pl.DataFrame(),
        mapa_manual_df=pl.DataFrame(),
    )
    assert result['produtos_final'].height == 1
    assert result['map_produto_agrupado'].height == 2


def test_build_agregacao_from_mdc_base_v2_applies_manual_map() -> None:
    efd_itens = pl.DataFrame([
        {
            'cnpj': '1',
            'id_linha_origem': 'i1',
            'codigo_fonte': '1|A',
            'codigo_produto_original': 'A',
            'descr_item': 'Arroz Tipo 1',
            'descr_compl': 'Pacote',
            'tipo_item': '00',
            'ncm': '10063021',
            'cest': '0100100',
            'gtin_padrao': '111',
            'unid': 'UN',
        }
    ])
    mapa_manual = pl.DataFrame([
        {'codigo_fonte': '1|A', 'id_agrupado_manual': 'AGR_MANUAL_A'}
    ])
    result = build_agregacao_from_mdc_base_v2(
        efd_itens_base_df=efd_itens,
        efd_inventario_base_df=pl.DataFrame(),
        efd_produtos_base_df=pl.DataFrame(),
        mapa_manual_df=mapa_manual,
    )
    assert result['map_produto_agrupado']['id_agrupado'][0] == 'AGR_MANUAL_A'
