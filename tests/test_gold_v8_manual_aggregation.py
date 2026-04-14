import polars as pl

from pipeline.run_gold_v8 import run_gold_v8


def test_run_gold_v8_respects_manual_aggregation_map() -> None:
    itens = pl.DataFrame([
        {
            'id_linha_origem': 'nfe|1|1',
            'codigo_fonte': 'EMP|A',
            'codigo_produto_original': 'A',
            'descr_item': 'ARROZ TIPO 1',
            'descr_compl': 'PACOTE',
            'tipo_item': '00',
            'ncm': '10063021',
            'cest': '0100100',
            'gtin_padrao': '111',
            'unid': 'UN',
            'qtd': 10.0,
            'vl_item': 100.0,
        },
        {
            'id_linha_origem': 'nfe|2|1',
            'codigo_fonte': 'EMP|B',
            'codigo_produto_original': 'B',
            'descr_item': 'ARROZ T1 ESPECIAL',
            'descr_compl': 'PACOTE',
            'tipo_item': '00',
            'ncm': '10063021',
            'cest': '0100100',
            'gtin_padrao': '222',
            'unid': 'UN',
            'qtd': 5.0,
            'vl_item': 60.0,
        },
    ])
    mapa_manual = pl.DataFrame([
        {'codigo_fonte': 'EMP|B', 'id_agrupado_manual': 'AGR_MANUAL_ARROZ'}
    ])
    result = run_gold_v8(
        itens,
        c170_df=pl.DataFrame(),
        nfe_df=pl.DataFrame(),
        nfce_df=pl.DataFrame(),
        bloco_h_df=pl.DataFrame(),
        mapa_manual_df=mapa_manual,
    )
    mapa = result['map_produto_agrupado']
    manual_row = mapa.filter(pl.col('codigo_fonte') == 'EMP|B')
    assert manual_row.height == 1
    assert manual_row['id_agrupado'][0] == 'AGR_MANUAL_ARROZ'
