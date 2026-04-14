import polars as pl

from pipeline.estoque.resumo import build_estoque_alertas, build_estoque_resumo


def test_build_estoque_resumo_and_alertas() -> None:
    aba_anual = pl.DataFrame([
        {
            'id_agregado': 'P1',
            'saidas_desacob': 2.0,
            'estoque_final_desacob': 1.0,
            'entradas_desacob': 3.0,
        }
    ])
    fatores = pl.DataFrame([
        {'id_agrupado': 'P1', 'tipo_fator': 'manual', 'confianca_fator': 0.5}
    ])
    resumo = build_estoque_resumo(aba_anual, fatores)
    alertas = build_estoque_alertas(aba_anual, fatores)
    assert resumo['total_produtos'][0] == 1
    assert resumo['produtos_com_fator_manual'][0] == 1
    assert alertas['alerta_fator_manual'][0] is True
