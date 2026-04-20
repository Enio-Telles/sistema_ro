"""Testes de conversão de unidades."""

from __future__ import annotations

import polars as pl

from sistema_ro.conversao import (
    aplicar_conversao_quantidade,
    linhas_em_quarentena_conversao,
    resolver_fator_conversao,
    resolver_unidade_referencia,
)
from sistema_ro.enums import FatorConversaoOrigem


class TestResolverUnidadeReferencia:
    def test_override_vence(self):
        assert resolver_unidade_referencia("L", "ML", "G") == "L"

    def test_sugerida_vence_se_sem_override(self):
        assert resolver_unidade_referencia(None, "ML", "G") == "ML"

    def test_auto_ultimo_recurso(self):
        assert resolver_unidade_referencia(None, None, "G") == "G"

    def test_tudo_nulo(self):
        assert resolver_unidade_referencia(None, None, None) is None

    def test_strings_vazias_ignoradas(self):
        assert resolver_unidade_referencia("", "L", None) == "L"


class TestResolverFatorConversao:
    def test_precedencia_manual(self):
        fator, origem = resolver_fator_conversao(
            override=0.5, fisico=0.7, catalogo=1.0, preco=2.0
        )
        assert fator == 0.5
        assert origem == FatorConversaoOrigem.MANUAL.value

    def test_precedencia_fisico(self):
        fator, origem = resolver_fator_conversao(
            override=None, fisico=0.5, catalogo=1.0, preco=2.0
        )
        assert fator == 0.5
        assert origem == FatorConversaoOrigem.FISICO.value

    def test_quarentena_quando_nada(self):
        fator, origem = resolver_fator_conversao(override=None)
        assert fator is None
        assert origem == FatorConversaoOrigem.QUARENTENA.value

    def test_ignora_zeros_e_negativos(self):
        fator, origem = resolver_fator_conversao(override=0.0, fisico=-1, preco=0.75)
        assert fator == 0.75
        assert origem == FatorConversaoOrigem.PRECO.value


class TestAplicarConversaoQuantidade:
    def test_multiplica_por_fator(self):
        df = pl.DataFrame(
            {"quantidade_original": [2.0, 3.0], "fator_conversao": [0.5, 1.0]}
        )
        out = aplicar_conversao_quantidade(df)
        assert out["quantidade_convertida"].to_list() == [1.0, 3.0]


class TestQuarentenaConversao:
    def test_retorna_linhas_com_fator_nulo(self):
        df = pl.DataFrame(
            {
                "id_produto_agrupado": ["G1", "G2"],
                "fator_conversao": [None, 1.0],
            }
        )
        q = linhas_em_quarentena_conversao(df)
        assert q.height == 1
        assert q["id_produto_agrupado"][0] == "G1"
