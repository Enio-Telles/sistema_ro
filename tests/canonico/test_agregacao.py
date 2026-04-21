"""Testes da agregação de produtos."""

from __future__ import annotations

import polars as pl
import pytest

from sistema_ro.agregacao import (
    detectar_ambiguidades,
    gerar_id_produto_agrupado_base,
    gerar_id_produto_origem,
    normalizar_descricao,
    resolver_id_produto_agrupado,
)


class TestNormalizarDescricao:
    def test_idempotencia(self):
        entrada = "  Coca-Cola 350ML Lata  "
        primeiro = normalizar_descricao(entrada)
        segundo = normalizar_descricao(primeiro)
        assert primeiro == segundo

    def test_remove_diacriticos(self):
        assert normalizar_descricao("Açaí") == "acai"

    def test_remove_embalagem(self):
        assert "350ml" not in normalizar_descricao("Refri 350ml Lata").split()
        assert "500g" not in normalizar_descricao("Arroz 500g pct").split()

    def test_colapsa_espacos_e_alfanumerico(self):
        assert normalizar_descricao("AB,,,  C!!!D") == "ab c d"

    def test_none_vira_string_vazia(self):
        assert normalizar_descricao(None) == ""


class TestIdProdutoOrigem:
    def test_formato(self):
        assert gerar_id_produto_origem("12345678901234", "X01") == "12345678901234|X01"

    def test_exige_ambos(self):
        with pytest.raises(ValueError):
            gerar_id_produto_origem("", "X")
        with pytest.raises(ValueError):
            gerar_id_produto_origem("1", "")


class TestIdProdutoAgrupadoBase:
    def test_determinismo(self):
        a = gerar_id_produto_agrupado_base("arroz", "10063020", None, "kg")
        b = gerar_id_produto_agrupado_base("arroz", "10063020", None, "kg")
        assert a == b

    def test_muda_se_insumo_muda(self):
        a = gerar_id_produto_agrupado_base("arroz", "10063020", None, "kg")
        b = gerar_id_produto_agrupado_base("arroz", "10063020", None, "g")
        assert a != b


class TestResolverIdProdutoAgrupado:
    def test_sem_overrides_usa_base(self):
        df = pl.DataFrame(
            {
                "id_produto_origem": ["P1", "P2"],
                "descricao_normalizada": ["arroz", "arroz"],
                "ncm": ["10063020", "10063020"],
                "cest": ["", ""],
                "unidade_referencia": ["kg", "kg"],
            }
        )
        out = resolver_id_produto_agrupado(df)
        # mesmo descricao+ncm+cest+unidade → mesmo base → mesmo agrupado
        assert out["id_produto_agrupado"][0] == out["id_produto_agrupado"][1]

    def test_override_por_produto_origem_prevalece(self):
        df = pl.DataFrame(
            {
                "id_produto_origem": ["P1", "P2"],
                "descricao_normalizada": ["arroz", "arroz"],
                "ncm": ["10063020", "10063020"],
                "cest": ["", ""],
                "unidade_referencia": ["kg", "kg"],
            }
        )
        overrides = pl.DataFrame(
            {
                "id_produto_origem": ["P1"],
                "id_produto_agrupado": ["CUSTOM"],
                "tipo_override": ["por_produto_origem"],
            }
        )
        out = resolver_id_produto_agrupado(df, overrides)
        linha_p1 = out.filter(pl.col("id_produto_origem") == "P1")
        linha_p2 = out.filter(pl.col("id_produto_origem") == "P2")
        assert linha_p1["id_produto_agrupado"][0] == "CUSTOM"
        assert linha_p2["id_produto_agrupado"][0] != "CUSTOM"


class TestDetectarAmbiguidades:
    def test_produto_origem_multivalorado(self):
        df = pl.DataFrame(
            {
                "id_produto_origem": ["P1", "P1"],
                "descricao_normalizada": ["arroz branco", "arroz integral"],
                "ncm": ["10063020", "10063020"],
            }
        )
        amb = detectar_ambiguidades(df)
        assert "id_produto_origem_multivalorado" in amb["motivo_quarentena"].to_list()

    def test_descricao_com_ncm_divergente(self):
        df = pl.DataFrame(
            {
                "id_produto_origem": ["P1", "P2"],
                "descricao_normalizada": ["arroz", "arroz"],
                "ncm": ["10063020", "10064000"],
            }
        )
        amb = detectar_ambiguidades(df)
        assert "descricao_com_ncm_divergente" in amb["motivo_quarentena"].to_list()
