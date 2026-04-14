import polars as pl

from pipeline.mercadorias.builders import build_id_agrupados, build_produtos_agrupados, build_produtos_final


def test_build_produtos_agrupados_separates_descricoes_and_complementos() -> None:
    itens = pl.DataFrame([
        {
            'id_agrupado': 'P1',
            'codigo_fonte': '123|A',
            'descr_item': 'ARROZ T1',
            'descr_compl': 'PACOTE 5KG',
            'ncm': '10063021',
            'cest': '0100100',
            'codigo_produto_original': 'A',
            'id_linha_origem': 'nfe|1|1',
        },
        {
            'id_agrupado': 'P1',
            'codigo_fonte': '123|B',
            'descr_item': 'ARROZ T1',
            'descr_compl': 'FARDO',
            'ncm': '10063021',
            'cest': '0100100',
            'codigo_produto_original': 'B',
            'id_linha_origem': 'nfe|2|1',
        },
    ])
    agrupados = build_produtos_agrupados(itens)
    assert agrupados['lista_descricoes'][0] == ['ARROZ T1']
    assert set(agrupados['lista_desc_compl'][0]) == {'FARDO', 'PACOTE 5KG'}


def test_build_produtos_final_bootstraps_identity() -> None:
    agrupados = pl.DataFrame([
        {
            'id_agrupado': 'P1',
            'lista_descricoes': ['ARROZ T1'],
            'lista_desc_compl': ['PACOTE 5KG'],
            'lista_itens_agrupados': ['A'],
            'ids_origem_agrupamento': ['nfe|1|1'],
            'codigos_fonte': ['123|A'],
            'ncm_padrao': '10063021',
            'cest_padrao': '0100100',
        }
    ])
    final = build_produtos_final(agrupados)
    ids = build_id_agrupados(agrupados)
    assert 'mercadoria_id' in final.columns
    assert 'apresentacao_id' in final.columns
    assert ids.height == 1
