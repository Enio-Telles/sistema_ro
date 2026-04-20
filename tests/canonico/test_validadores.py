"""Testes dos validadores de integridade."""

from __future__ import annotations

from datetime import datetime

import polars as pl

from sistema_ro.enums import TipoOperacao
from sistema_ro.movimentacao import montar_movimentacao_estoque
from sistema_ro.validadores import (
    checar_consistencia_mensal_anual,
    checar_consistencia_periodos_anual,
    checar_desacobertos_mutuamente_exclusivos,
    checar_movimentacao,
)


def _minimo() -> pl.DataFrame:
    from datetime import date

    movimentos = pl.DataFrame(
        {
            "id_linha_origem": ["L1", "L2"],
            "id_produto_origem": ["P1", "P1"],
            "data_evento": [datetime(2025, 1, 1), datetime(2025, 2, 1)],
            "tipo_operacao": [int(TipoOperacao.ENTRADA), int(TipoOperacao.SAIDA)],
            "quantidade_original": [10.0, 3.0],
            "unidade_original": ["UN", "UN"],
            "preco_item": [100.0, 60.0],
            "cfop": ["1102", "5102"],
            "finnfe": [1, 1],
        }
    )
    inventarios = pl.DataFrame(
        {
            "id_linha_origem": ["H1"],
            "id_produto_origem": ["P1"],
            "data_inventario": [date(2025, 12, 31)],
            "quantidade_original": [7.0],
            "unidade_original": ["UN"],
            "valor_unitario": [10.0],
        }
    )
    mapeamento = pl.DataFrame(
        {
            "id_produto_origem": ["P1"],
            "id_produto_agrupado": ["G1"],
            "id_produto_agrupado_base": ["G1"],
            "descricao_normalizada": ["x"],
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


def test_checar_movimentacao_valido():
    mov = _minimo()
    assert checar_movimentacao(mov) == []


def test_detecta_saldo_inconsistente():
    mov = _minimo()
    # corrompe uma linha
    mov = mov.with_columns(
        pl.when(pl.col("id_linha_origem") == "L2")
        .then(pl.lit(999.0))
        .otherwise(pl.col("saldo_estoque_corrente"))
        .alias("saldo_estoque_corrente")
    )
    problemas = checar_movimentacao(mov)
    assert any("saldo cronológico" in p for p in problemas)


def test_desacobertos_mutuamente_exclusivos_ok():
    df = pl.DataFrame(
        {
            "saidas_desacobertas_ano": [10.0, 0.0],
            "estoque_final_desacoberto_ano": [0.0, 5.0],
        }
    )
    assert checar_desacobertos_mutuamente_exclusivos(df) == []


def test_desacobertos_mutuamente_exclusivos_violacao():
    df = pl.DataFrame(
        {
            "saidas_desacobertas_ano": [10.0],
            "estoque_final_desacoberto_ano": [5.0],
        }
    )
    problemas = checar_desacobertos_mutuamente_exclusivos(df)
    assert problemas and "ambos positivos" in problemas[0]


# ---------------------------------------------------------------------------
# Consistência mensal ↔ anual
# ---------------------------------------------------------------------------


def _mensal_anual_coerentes() -> tuple[pl.DataFrame, pl.DataFrame]:
    mensal = pl.DataFrame(
        {
            "id_produto_agrupado": ["G1", "G1", "G1"],
            "ano": [2025, 2025, 2025],
            "mes": [1, 2, 3],
            "quantidade_entradas_mes": [10.0, 20.0, 30.0],
            "quantidade_saidas_mes": [5.0, 4.0, 3.0],
            "entradas_desacobertas_mes": [0.0, 1.0, 0.0],
        }
    )
    anual = pl.DataFrame(
        {
            "id_produto_agrupado": ["G1"],
            "ano": [2025],
            "entradas_ano": [60.0],
            "saidas_ano": [12.0],
            "entradas_desacobertas_ano": [1.0],
        }
    )
    return mensal, anual


def test_consistencia_mensal_anual_ok():
    mensal, anual = _mensal_anual_coerentes()
    assert checar_consistencia_mensal_anual(mensal, anual) == []


def test_consistencia_mensal_anual_detecta_divergencia():
    mensal, anual = _mensal_anual_coerentes()
    anual = anual.with_columns(pl.lit(999.0).alias("entradas_ano"))
    problemas = checar_consistencia_mensal_anual(mensal, anual)
    assert any("entradas divergente" in p for p in problemas)


def test_consistencia_mensal_anual_detecta_produto_orfao():
    mensal, anual = _mensal_anual_coerentes()
    # adiciona produto no mensal que não está no anual
    novo = pl.DataFrame(
        {
            "id_produto_agrupado": ["G2"],
            "ano": [2025],
            "mes": [1],
            "quantidade_entradas_mes": [1.0],
            "quantidade_saidas_mes": [0.0],
            "entradas_desacobertas_mes": [0.0],
        }
    )
    mensal = pl.concat([mensal, novo])
    problemas = checar_consistencia_mensal_anual(mensal, anual)
    assert any("não aparecem em anual" in p for p in problemas)


# ---------------------------------------------------------------------------
# Consistência períodos ↔ anual
# ---------------------------------------------------------------------------


def test_consistencia_periodos_anual_sem_mapa_detecta_orfao():
    periodos = pl.DataFrame(
        {
            "id_produto_agrupado": ["G1", "G_ORFAO"],
            "codigo_periodo": [1, 1],
            "entradas_periodo": [10.0, 2.0],
            "saidas_periodo": [0.0, 0.0],
            "entradas_desacobertas_periodo": [0.0, 0.0],
        }
    )
    anual = pl.DataFrame(
        {
            "id_produto_agrupado": ["G1"],
            "ano": [2025],
            "entradas_ano": [10.0],
            "saidas_ano": [0.0],
            "entradas_desacobertas_ano": [0.0],
        }
    )
    problemas = checar_consistencia_periodos_anual(periodos, anual)
    assert any("sem presença na tabela anual" in p for p in problemas)


def test_consistencia_periodos_anual_com_mapa_ok():
    periodos = pl.DataFrame(
        {
            "id_produto_agrupado": ["G1", "G1"],
            "codigo_periodo": [1, 2],
            "entradas_periodo": [4.0, 6.0],
            "saidas_periodo": [1.0, 2.0],
            "entradas_desacobertas_periodo": [0.0, 0.0],
        }
    )
    anual = pl.DataFrame(
        {
            "id_produto_agrupado": ["G1"],
            "ano": [2025],
            "entradas_ano": [10.0],
            "saidas_ano": [3.0],
            "entradas_desacobertas_ano": [0.0],
        }
    )
    mapa = {1: 2025, 2: 2025}
    assert checar_consistencia_periodos_anual(periodos, anual, mapa_periodo_ano=mapa) == []


def test_consistencia_periodos_anual_com_mapa_detecta():
    periodos = pl.DataFrame(
        {
            "id_produto_agrupado": ["G1"],
            "codigo_periodo": [1],
            "entradas_periodo": [99.0],
            "saidas_periodo": [0.0],
            "entradas_desacobertas_periodo": [0.0],
        }
    )
    anual = pl.DataFrame(
        {
            "id_produto_agrupado": ["G1"],
            "ano": [2025],
            "entradas_ano": [10.0],
            "saidas_ano": [0.0],
            "entradas_desacobertas_ano": [0.0],
        }
    )
    problemas = checar_consistencia_periodos_anual(
        periodos, anual, mapa_periodo_ano={1: 2025}
    )
    assert any("entradas divergente" in p for p in problemas)
