import polars as pl

from pipeline.mercadorias.mercadoria_pipeline_v2 import run_mercadoria_v2


def test_run_mercadoria_v2_propagates_grouping_metadata_to_outputs() -> None:
    itens = pl.DataFrame([
        {
            'id_linha_origem': 'nfe|10|1',
            'codigo_fonte': '321|A',
            'codigo_produto_original': 'A',
            'descr_item': 'CAFE TORRADO',
            'descr_compl': '500G',
            'tipo_item': '00',
            'ncm': '09012100',
            'cest': '0300100',
            'gtin_padrao': '789',
            'unid': 'CX',
        }
    ])
    mapa_manual = pl.DataFrame([
        {
            'codigo_fonte': '321|A',
            'id_agrupado_manual': 'AGR_CAFE_001',
        }
    ])

    result = run_mercadoria_v2(
        itens,
        mapa_manual_df=mapa_manual,
        versao_agrupamento='2026.04.18',
    )

    produto = result['produtos_final'].row(0, named=True)
    agrupado = result['id_agrupados'].row(0, named=True)

    assert produto['id_agrupado'] == 'AGR_CAFE_001'
    assert produto['id_agrupado_final'] == 'AGR_CAFE_001'
    assert agrupado['id_agrupado_final'] == 'AGR_CAFE_001'
    assert agrupado['tem_override_manual'] is True
    assert agrupado['origem_agrupamento'] == 'manual'
    assert agrupado['regra_agrupamento'] == 'codigo_fonte→id_agrupado_manual'
    assert agrupado['versao_agrupamento'] == '2026.04.18'
