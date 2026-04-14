import polars as pl

from pipeline.fontes_agr.build_fontes_agr_v2 import build_fontes_agr_v2


def test_build_fontes_agr_v2_preserves_operational_fields() -> None:
    c170 = pl.DataFrame([
        {
            'cnpj': '1',
            'id_linha_origem': 'l1',
            'codigo_fonte': '1|A',
            'codigo_produto_original': 'A',
            'descr_item': 'ARROZ',
            'unid': 'UN',
            'qtd': 10.0,
            'vl_item': 100.0,
            'dt_doc': '2024-01-01',
        }
    ])
    map_df = pl.DataFrame([
        {'codigo_fonte': '1|A', 'id_agrupado': 'AGR_1', 'descricao_normalizada': 'ARROZ'}
    ])
    produtos_final = pl.DataFrame([
        {'id_agrupado': 'AGR_1', 'descr_padrao': 'ARROZ TIPO 1', 'ncm_padrao': '10063021', 'cest_padrao': '0100100', 'gtin_padrao': '111', 'unid_ref': 'UN'}
    ])
    result = build_fontes_agr_v2(
        c170_df=c170,
        nfe_df=pl.DataFrame(),
        nfce_df=pl.DataFrame(),
        bloco_h_df=pl.DataFrame(),
        map_produto_agrupado_df=map_df,
        produtos_final_df=produtos_final,
    )
    row = result['c170_agr'].row(0, named=True)
    assert row['id_agrupado'] == 'AGR_1'
    assert row['qtd'] == 10.0
    assert row['vl_item'] == 100.0
    assert row['dt_doc'] == '2024-01-01'
