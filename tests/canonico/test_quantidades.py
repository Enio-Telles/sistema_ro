"""Testes da derivação de quantidades."""

from __future__ import annotations

import polars as pl

from sistema_ro.enums import TipoOperacao
from sistema_ro.quantidades import (
    derivar_colunas_quantidade,
    normalizar_parquet_legado,
)


def test_inventario_nao_altera_saldo(mov_minima):
    df = derivar_colunas_quantidade(mov_minima)

    com_inv = df["quantidade_fisica_sinalizada"].sum()
    sem_inv = (
        df.filter(pl.col("tipo_operacao") != int(TipoOperacao.ESTOQUE_FINAL))[
            "quantidade_fisica_sinalizada"
        ].sum()
    )
    assert com_inv == sem_inv


def test_quantidade_fisica_zero_em_inventario(mov_minima):
    df = derivar_colunas_quantidade(mov_minima)
    inv = df.filter(pl.col("tipo_operacao") == int(TipoOperacao.ESTOQUE_FINAL))
    assert (inv["quantidade_fisica"] == 0.0).all()
    assert (inv["quantidade_fisica_sinalizada"] == 0.0).all()


def test_estoque_final_declarado_somente_em_inventario(mov_minima):
    df = derivar_colunas_quantidade(mov_minima)
    nao_inv = df.filter(
        pl.col("tipo_operacao") != int(TipoOperacao.ESTOQUE_FINAL)
    )
    assert (nao_inv["estoque_final_declarado"] == 0.0).all()
    inv = df.filter(pl.col("tipo_operacao") == int(TipoOperacao.ESTOQUE_FINAL))
    assert (inv["estoque_final_declarado"] > 0).all()


def test_devolucao_compra_tem_sinal_negativo():
    df = pl.DataFrame(
        {
            "tipo_operacao": [int(TipoOperacao.DEVOLUCAO_DE_COMPRA)],
            "quantidade_convertida": [5.0],
        }
    )
    out = derivar_colunas_quantidade(df)
    assert out["quantidade_fisica_sinalizada"][0] == -5.0


def test_devolucao_venda_tem_sinal_positivo():
    df = pl.DataFrame(
        {
            "tipo_operacao": [int(TipoOperacao.DEVOLUCAO_DE_VENDA)],
            "quantidade_convertida": [3.0],
        }
    )
    out = derivar_colunas_quantidade(df)
    assert out["quantidade_fisica_sinalizada"][0] == 3.0


def test_normalizar_parquet_legado_recomputa():
    df_legado = pl.DataFrame(
        {
            "tipo_operacao": [int(TipoOperacao.ENTRADA)],
            "quantidade_convertida": [7.0],
            "quantidade_fisica": [999.0],  # valor errado vindo do legado
            "quantidade_fisica_sinalizada": [999.0],
            "estoque_final_declarado": [999.0],
        }
    )
    out = normalizar_parquet_legado(df_legado)
    assert out["quantidade_fisica"][0] == 7.0
    assert out["quantidade_fisica_sinalizada"][0] == 7.0
    assert out["estoque_final_declarado"][0] == 0.0
