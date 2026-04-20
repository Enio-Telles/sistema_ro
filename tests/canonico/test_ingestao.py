"""Testes dos leitores concretos em ``sistema_ro.ingestao``."""

from __future__ import annotations

import sqlite3
from datetime import date, datetime
from pathlib import Path

import polars as pl
import pytest

from sistema_ro.ingestao import (
    ParquetFonteBlocoH,
    ParquetFonteMovimento,
    SQLFonteBlocoH,
    SQLFonteMovimento,
    sqlite_loader,
)
from sistema_ro.schemas import SCHEMA_FONTE_INVENTARIO, SCHEMA_FONTE_MOVIMENTO


CNPJ = "00000000000191"


def _mov_df() -> pl.DataFrame:
    return pl.DataFrame(
        {
            "id_linha_origem": ["L1"],
            "id_produto_origem": ["P1"],
            "data_evento": [datetime(2025, 1, 1)],
            "tipo_operacao": [1],
            "quantidade_original": [10.0],
            "unidade_original": ["UN"],
            "preco_item": [100.0],
            "cfop": ["1102"],
            "finnfe": [1],
        },
        schema=SCHEMA_FONTE_MOVIMENTO,
    )


def _inv_df() -> pl.DataFrame:
    return pl.DataFrame(
        {
            "id_linha_origem": ["H1"],
            "id_produto_origem": ["P1"],
            "data_inventario": [date(2025, 12, 31)],
            "quantidade_original": [7.0],
            "unidade_original": ["UN"],
            "valor_unitario": [10.0],
        },
        schema=SCHEMA_FONTE_INVENTARIO,
    )


# ---------------------------------------------------------------------------
# Parquet
# ---------------------------------------------------------------------------


def test_parquet_movimento_le_arquivo_existente(tmp_path: Path):
    raiz = tmp_path
    fontes_dir = raiz / CNPJ / "fontes"
    fontes_dir.mkdir(parents=True)
    _mov_df().write_parquet(fontes_dir / f"c170_{CNPJ}.parquet")

    fonte = ParquetFonteMovimento(raiz, nome="c170")
    df = fonte.carregar(CNPJ)
    assert df.height == 1
    assert df.row(0, named=True)["cfop"] == "1102"


def test_parquet_movimento_retorna_vazio_quando_ausente(tmp_path: Path):
    fonte = ParquetFonteMovimento(tmp_path, nome="nfe")
    df = fonte.carregar(CNPJ)
    assert df.is_empty()
    # schema preservado
    assert set(df.columns) == set(SCHEMA_FONTE_MOVIMENTO.keys())


def test_parquet_movimento_rejeita_nome_invalido(tmp_path: Path):
    with pytest.raises(ValueError, match="nome inválido"):
        ParquetFonteMovimento(tmp_path, nome="foo")


def test_parquet_bloco_h(tmp_path: Path):
    raiz = tmp_path
    (raiz / CNPJ / "fontes").mkdir(parents=True)
    _inv_df().write_parquet(raiz / CNPJ / "fontes" / f"bloco_h_{CNPJ}.parquet")

    fonte = ParquetFonteBlocoH(raiz)
    df = fonte.carregar(CNPJ)
    assert df.row(0, named=True)["quantidade_original"] == 7.0


# ---------------------------------------------------------------------------
# SQL
# ---------------------------------------------------------------------------


def test_sql_movimento_com_loader_in_memory():
    chamadas = []

    def loader(cnpj: str) -> pl.DataFrame:
        chamadas.append(cnpj)
        return _mov_df()

    fonte = SQLFonteMovimento(loader=loader)
    df = fonte.carregar(CNPJ)
    assert chamadas == [CNPJ]
    assert df.height == 1


def test_sql_movimento_valida_schema():
    def loader(cnpj: str) -> pl.DataFrame:
        return pl.DataFrame({"id_linha_origem": ["X"]})  # schema quebrado

    fonte = SQLFonteMovimento(loader=loader, rotulo="broken")
    with pytest.raises(ValueError, match="colunas obrigatórias ausentes"):
        fonte.carregar(CNPJ)


def test_sql_bloco_h_ok():
    fonte = SQLFonteBlocoH(loader=lambda cnpj: _inv_df())
    assert fonte.carregar(CNPJ).height == 1


def test_sqlite_loader_end_to_end(tmp_path: Path):
    db = tmp_path / "fiscal.sqlite"
    with sqlite3.connect(str(db)) as conn:
        conn.execute(
            """CREATE TABLE c170 (
                cnpj_titular TEXT,
                id_linha_origem TEXT,
                id_produto_origem TEXT,
                data_evento TEXT,
                tipo_operacao INTEGER,
                quantidade_original REAL,
                unidade_original TEXT,
                preco_item REAL,
                cfop TEXT,
                finnfe INTEGER
            )"""
        )
        conn.execute(
            "INSERT INTO c170 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            (CNPJ, "L1", "P1", "2025-01-01T00:00:00", 1, 10.0, "UN", 100.0, "1102", 1),
        )

    query = """
        SELECT id_linha_origem, id_produto_origem, data_evento, tipo_operacao,
               quantidade_original, unidade_original, preco_item, cfop, finnfe
        FROM c170 WHERE cnpj_titular = :cnpj
    """
    # Override de dtypes — SQLite devolve tipo_operacao/finnfe como Int64
    # por default e o schema exige Int32; data_evento fica String e deve
    # ser convertida depois com str.strptime.
    override = {
        "tipo_operacao": pl.Int32,
        "finnfe": pl.Int32,
    }
    loader = sqlite_loader(db, query, schema_override=override)

    df_raw = loader(CNPJ)
    df = df_raw.with_columns(
        pl.col("data_evento").str.strptime(pl.Datetime, format="%Y-%m-%dT%H:%M:%S")
    )
    fonte = SQLFonteMovimento(loader=lambda _cnpj: df)
    carregado = fonte.carregar(CNPJ)
    assert carregado.row(0, named=True)["cfop"] == "1102"
    assert carregado.schema["data_evento"] == pl.Datetime


def test_sqlite_loader_vazio_preserva_schema(tmp_path: Path):
    db = tmp_path / "fiscal.sqlite"
    with sqlite3.connect(str(db)) as conn:
        conn.execute("CREATE TABLE c170 (cnpj_titular TEXT)")

    loader = sqlite_loader(db, "SELECT * FROM c170 WHERE cnpj_titular = :cnpj")
    df = loader(CNPJ)
    assert df.is_empty()
    assert "id_linha_origem" in df.columns  # schema default
