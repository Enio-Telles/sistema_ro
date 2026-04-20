"""Teste end-to-end da consolidação da movimentação."""

from __future__ import annotations

from datetime import date, datetime

import polars as pl

from sistema_ro.enums import TipoOperacao
from sistema_ro.movimentacao import montar_movimentacao_estoque


def _movimentos() -> pl.DataFrame:
    return pl.DataFrame(
        {
            "id_linha_origem": ["L1", "L2", "L3"],
            "id_produto_origem": ["P1", "P1", "P1"],
            "data_evento": [
                datetime(2025, 2, 1),
                datetime(2025, 3, 1),
                datetime(2025, 4, 1),
            ],
            "tipo_operacao": [
                int(TipoOperacao.ENTRADA),
                int(TipoOperacao.ENTRADA),
                int(TipoOperacao.SAIDA),
            ],
            "quantidade_original": [10.0, 5.0, 6.0],
            "unidade_original": ["UN", "UN", "UN"],
            "preco_item": [100.0, 60.0, 90.0],
            "cfop": ["1102", "1102", "5102"],
            "finnfe": [1, 1, 1],
        }
    )


def _inventarios() -> pl.DataFrame:
    return pl.DataFrame(
        {
            "id_linha_origem": ["H1"],
            "id_produto_origem": ["P1"],
            "data_inventario": [date(2025, 12, 31)],
            "quantidade_original": [9.0],
            "unidade_original": ["UN"],
            "valor_unitario": [12.0],
        }
    )


def _mapeamento() -> pl.DataFrame:
    return pl.DataFrame(
        {
            "id_produto_origem": ["P1"],
            "id_produto_agrupado": ["G1"],
            "id_produto_agrupado_base": ["G1"],
            "descricao_normalizada": ["test"],
            "ncm": ["10000000"],
            "cest": [""],
            "unidade_referencia": ["UN"],
            "versao_agrupamento": [1],
        }
    )


def _conversao() -> pl.DataFrame:
    return pl.DataFrame(
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


def test_montar_movimentacao_produz_saldo_correto():
    out = montar_movimentacao_estoque(
        movimentos=_movimentos(),
        inventarios=_inventarios(),
        mapeamento=_mapeamento(),
        conversao=_conversao(),
    )
    # sequência esperada: +10 → +5 → −6 → inventário (não altera saldo)
    # → saldo cronológico final = 9
    assert out["saldo_estoque_corrente"].to_list() == [10.0, 15.0, 9.0, 9.0]


def test_inventario_preenche_estoque_final_declarado():
    out = montar_movimentacao_estoque(
        movimentos=_movimentos(),
        inventarios=_inventarios(),
        mapeamento=_mapeamento(),
        conversao=_conversao(),
    )
    inv = out.filter(pl.col("tipo_operacao") == int(TipoOperacao.ESTOQUE_FINAL))
    assert inv.height == 1
    assert inv["estoque_final_declarado"][0] == 9.0
    assert inv["quantidade_fisica"][0] == 0.0
