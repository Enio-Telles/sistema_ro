"""Testes do saldo cronológico + custo médio."""

from __future__ import annotations

from datetime import datetime

import polars as pl

from sistema_ro.calculo_saldo import aplicar_saldo_e_custo
from sistema_ro.enums import TipoOperacao
from sistema_ro.quantidades import derivar_colunas_quantidade


def _mov(eventos: list[tuple[int, float, float]]) -> pl.DataFrame:
    """Gera DataFrame minimal a partir de tuplas (tipo, qconv, preco)."""

    n = len(eventos)
    df = pl.DataFrame(
        {
            "id_produto_agrupado": ["G1"] * n,
            "data_evento": [datetime(2025, 1, i + 1) for i in range(n)],
            "tipo_operacao": [t for t, _, _ in eventos],
            "quantidade_convertida": [q for _, q, _ in eventos],
            "preco_item": [p for _, _, p in eventos],
        }
    )
    return derivar_colunas_quantidade(df)


def test_saldo_acumula_corretamente():
    df = _mov(
        [
            (int(TipoOperacao.ENTRADA), 10.0, 100.0),
            (int(TipoOperacao.SAIDA), 3.0, 45.0),
            (int(TipoOperacao.ENTRADA), 5.0, 60.0),
        ]
    )
    out = aplicar_saldo_e_custo(df)
    assert out["saldo_estoque_corrente"].to_list() == [10.0, 7.0, 12.0]


def test_inventario_nao_altera_saldo():
    df = _mov(
        [
            (int(TipoOperacao.ENTRADA), 10.0, 100.0),
            (int(TipoOperacao.ESTOQUE_FINAL), 10.0, 0.0),
            (int(TipoOperacao.SAIDA), 4.0, 80.0),
        ]
    )
    out = aplicar_saldo_e_custo(df)
    assert out["saldo_estoque_corrente"].to_list() == [10.0, 10.0, 6.0]


def test_custo_medio_ponderado():
    # 10 × R$10 → média 10; +10 × R$20 → média 15
    df = _mov(
        [
            (int(TipoOperacao.ENTRADA), 10.0, 100.0),
            (int(TipoOperacao.ENTRADA), 10.0, 200.0),
        ]
    )
    out = aplicar_saldo_e_custo(df)
    assert out["custo_medio_corrente"].to_list() == [10.0, 15.0]


def test_saida_nao_altera_custo_medio():
    df = _mov(
        [
            (int(TipoOperacao.ENTRADA), 10.0, 100.0),
            (int(TipoOperacao.SAIDA), 4.0, 200.0),  # preço de saída alto
        ]
    )
    out = aplicar_saldo_e_custo(df)
    # custo médio continua 10, não é impactado pelo preço de venda
    assert out["custo_medio_corrente"].to_list() == [10.0, 10.0]


def test_entrada_desacoberta_quando_saldo_negativo():
    # saída maior que o saldo → saldo fica negativo → próxima entrada cobre
    df = _mov(
        [
            (int(TipoOperacao.ENTRADA), 5.0, 50.0),
            (int(TipoOperacao.SAIDA), 8.0, 120.0),  # saldo = -3
            (int(TipoOperacao.ENTRADA), 5.0, 100.0),  # cobre 3 como desac.
        ]
    )
    out = aplicar_saldo_e_custo(df)
    assert out["entr_desac_corrente"].to_list() == [0.0, 0.0, 3.0]
    # saldo segue a sequência -3 → +2
    assert out["saldo_estoque_corrente"].to_list() == [5.0, -3.0, 2.0]
