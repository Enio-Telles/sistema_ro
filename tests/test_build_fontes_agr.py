import polars as pl

from pipeline.fontes_agr.build_fontes_agr import build_fontes_agr


def test_build_fontes_agr_enriches_rows_with_id_agrupado() -> None:
    c170 = pl.DataFrame([
        {
            'cnpj': '1',
            'id_linha_origem': 'l1',
            'codigo_fonte': '1|A',
            'codigo_produto_original': 'A',
            'descr_item': 'ARROZ',
            'unid': 'UN',
        }
    ])
    map_df = pl.DataFrame([
        {'codigo_fonte': '1|A', 'id_agrupado': 'AGR_1', 'descricao_normalizada': 'ARROZ'}
    ])
    produtos_final = pl.DataFrame([
        {'id_agrupado': 'AGR_1', 'descr_padrao': 'ARROZ TIPO 1', 'ncm_padrao': '10063021', 'cest_padrao': '0100100', 'gtin_padrao': '111', 'unid_ref': 'UN'}
    ])
    result = build_fontes_agr(
        c170_df=c170,
        nfe_df=pl.DataFrame(),
        nfce_df=pl.DataFrame(),
        bloco_h_df=pl.DataFrame(),
        map_produto_agrupado_df=map_df,
        produtos_final_df=produtos_final,
    )
    assert result['c170_agr'].height == 1
    assert result['c170_agr']['id_agrupado'][0] == 'AGR_1'
    assert result['c170_agr']['descr_padrao'][0] == 'ARROZ TIPO 1'


def test_build_fontes_agr_sends_unmapped_rows_to_audit() -> None:
    c170 = pl.DataFrame([
        {
            'cnpj': '1',
            'id_linha_origem': 'l1',
            'codigo_fonte': '1|X',
            'codigo_produto_original': 'X',
            'descr_item': 'PRODUTO X',
            'unid': 'UN',
        }
    ])
    result = build_fontes_agr(
        c170_df=c170,
        nfe_df=pl.DataFrame(),
        nfce_df=pl.DataFrame(),
        bloco_h_df=pl.DataFrame(),
        map_produto_agrupado_df=pl.DataFrame(),
        produtos_final_df=pl.DataFrame(),
    )
    assert result['c170_agr'].height == 0
    assert result['c170_agr_sem_id_agrupado'].height == 1
