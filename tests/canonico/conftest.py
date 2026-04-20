"""Fixtures sintéticas para testes."""

from __future__ import annotations

from datetime import datetime

import polars as pl
import pytest

from sistema_ro.enums import TipoOperacao


@pytest.fixture
def mov_minima() -> pl.DataFrame:
    """DataFrame aderente ao schema de entrada para ``derivar_colunas_quantidade``.

    Caso simples com: 1 estoque inicial, 2 entradas, 2 saídas, 1 inventário.
    """

    return pl.DataFrame(
        {
            "id_linha_origem": ["L1", "L2", "L3", "L4", "L5", "L6"],
            "id_produto_origem": ["P1"] * 6,
            "id_produto_agrupado": ["G1"] * 6,
            "data_evento": [
                datetime(2025, 1, 1),
                datetime(2025, 2, 1),
                datetime(2025, 3, 1),
                datetime(2025, 4, 1),
                datetime(2025, 5, 1),
                datetime(2025, 12, 31, 23, 59, 59),
            ],
            "tipo_operacao": [
                int(TipoOperacao.ESTOQUE_INICIAL),
                int(TipoOperacao.ENTRADA),
                int(TipoOperacao.ENTRADA),
                int(TipoOperacao.SAIDA),
                int(TipoOperacao.SAIDA),
                int(TipoOperacao.ESTOQUE_FINAL),
            ],
            "quantidade_convertida": [10.0, 20.0, 15.0, 8.0, 12.0, 22.0],
            "preco_item": [0.0, 100.0, 60.0, 40.0, 60.0, 0.0],
            "cfop": [None, "1102", "1102", "5102", "5102", None],
            "finnfe": [None, 1, 1, 1, 1, None],
            "excluir_estoque": [False] * 6,
            "unidade_original": ["UN"] * 6,
            "unidade_referencia": ["UN"] * 6,
            "fator_conversao": [1.0] * 6,
            "quantidade_original": [10.0, 20.0, 15.0, 8.0, 12.0, 22.0],
        }
    )
