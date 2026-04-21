"""Testes das tabelas períodos/mensal/anual."""

from __future__ import annotations

from datetime import date, datetime

import polars as pl

from sistema_ro.enums import TipoOperacao
from sistema_ro.movimentacao import montar_movimentacao_estoque
from sistema_ro.tabelas import (
    gerar_tabela_anual,
    gerar_tabela_mensal,
    gerar_tabela_periodos,
)


def _pipeline_exemplo() -> pl.DataFrame:
    movimentos = pl.DataFrame(
        {
            "id_linha_origem": ["L1", "L2", "L3", "L4", "L5"],
            "id_produto_origem": ["P1"] * 5,
            "data_evento": [
                datetime(2025, 1, 2),
                datetime(2025, 2, 10),
                datetime(2025, 3, 15),
                datetime(2025, 6, 1),
                datetime(2025, 8, 1),
            ],
            "tipo_operacao": [
                int(TipoOperacao.ESTOQUE_INICIAL),
                int(TipoOperacao.ENTRADA),
                int(TipoOperacao.SAIDA),
                int(TipoOperacao.ENTRADA),
                int(TipoOperacao.SAIDA),
            ],
            "quantidade_original": [10.0, 20.0, 8.0, 15.0, 5.0],
            "unidade_original": ["UN"] * 5,
            "preco_item": [0.0, 200.0, 120.0, 180.0, 100.0],
            "cfop": [None, "1102", "5102", "1102", "5102"],
            "finnfe": [None, 1, 1, 1, 1],
        }
    )
    inventarios = pl.DataFrame(
        {
            "id_linha_origem": ["H1"],
            "id_produto_origem": ["P1"],
            "data_inventario": [date(2025, 12, 31)],
            "quantidade_original": [30.0],
            "unidade_original": ["UN"],
            "valor_unitario": [12.0],
        }
    )
    mapeamento = pl.DataFrame(
        {
            "id_produto_origem": ["P1"],
            "id_produto_agrupado": ["G1"],
            "id_produto_agrupado_base": ["G1"],
            "descricao_normalizada": ["teste"],
            "ncm": ["10000000"],
            "cest": [""],
            "unidade_referencia": ["UN"],
            "versao_agrupamento": [1],
        }
    )
    conversao = pl.DataFrame(
        {
            "id_produto_agrupado": ["G1"],
            "unidade_original": ["UN"],
            "unidade_referencia": ["UN"],
            "fator_conversao": [1.0],
            "fator_conversao_origem": ["manual"],
            "fator_conversao_override": [1.0],
            "unidade_referencia_override": [None],
        }
    )
    return montar_movimentacao_estoque(
        movimentos=movimentos,
        inventarios=inventarios,
        mapeamento=mapeamento,
        conversao=conversao,
    )


def test_tabela_periodos_basica():
    mov = _pipeline_exemplo()
    tab = gerar_tabela_periodos(mov)
    # um período (codigo_periodo = 1) para G1
    assert tab.height == 1
    row = tab.row(0, named=True)
    assert row["estoque_inicial_periodo"] == 10.0
    assert row["entradas_periodo"] == 20.0 + 15.0
    assert row["saidas_periodo"] == 8.0 + 5.0
    # saldo calculado = 10 + 35 − 13 = 32; declarado = 30
    # → saidas_desacobertas = 32 − 30 = 2; estoque_final_desacoberto = 0
    assert row["saidas_desacobertas_periodo"] == 2.0
    assert row["estoque_final_desacoberto_periodo"] == 0.0


def test_tabela_mensal_consome_saldo_corrente():
    mov = _pipeline_exemplo()
    tab = gerar_tabela_mensal(mov)
    # mês 1: saldo 10; mês 2: saldo 30; mês 3: saldo 22;
    # mês 6: saldo 37; mês 8: saldo 32.
    saldos_por_mes = {
        (row["ano"], row["mes"]): row["saldo_mes"]
        for row in tab.sort("mes").iter_rows(named=True)
    }
    assert saldos_por_mes[(2025, 1)] == 10.0
    assert saldos_por_mes[(2025, 2)] == 30.0
    assert saldos_por_mes[(2025, 3)] == 22.0
    assert saldos_por_mes[(2025, 6)] == 37.0
    assert saldos_por_mes[(2025, 8)] == 32.0


def test_tabela_anual_reporta_divergencia():
    mov = _pipeline_exemplo()
    tab = gerar_tabela_anual(mov)
    assert tab.height == 1
    row = tab.row(0, named=True)
    assert row["estoque_final_declarado_ano"] == 30.0
    assert row["saidas_desacobertas_ano"] == 2.0
    assert row["estoque_final_desacoberto_ano"] == 0.0
