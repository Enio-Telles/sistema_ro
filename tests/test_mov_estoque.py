import polars as pl

from pipeline.estoque.mov_estoque import build_mov_estoque


def test_build_mov_estoque_generates_qconv_and_saldo() -> None:
    c170 = pl.DataFrame([
        {'id_agrupado': 'P1', 'id_linha_origem': 'c170|1|1|1', 'qtd': 10.0, 'vl_item': 100.0, 'dt_doc': '2024-01-10'}
    ])
    nfe = pl.DataFrame([
        {'id_agrupado': 'P1', 'id_linha_origem': 'nfe|1|1', 'qtd': 4.0, 'vl_item': 60.0, 'dt_doc': '2024-01-11'}
    ])
    nfce = pl.DataFrame()
    bloco_h = pl.DataFrame()
    fatores = pl.DataFrame([
        {'id_agrupado': 'P1', 'unid_ref': 'UN', 'fator': 1.0, 'tipo_fator': 'preco', 'confianca_fator': 0.6, 'fonte_fator': 'preco_medio_relativo'}
    ])
    result = build_mov_estoque(c170, nfe, nfce, bloco_h, fatores)
    assert result.height == 2
    assert result.filter(pl.col('fonte') == 'c170')['q_conv'][0] == 10.0
    assert result.filter(pl.col('fonte') == 'nfe')['q_conv'][0] == 4.0
    assert result['saldo_estoque_anual'][-1] == 6.0
