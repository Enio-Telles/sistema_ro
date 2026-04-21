"""Testes do módulo ``sistema_ro.sitafe``.

Os testes usam fixtures Polars em memória com o mesmo schema das tabelas
SITAFE reais (``sitafe_cest``, ``sitafe_cest_ncm``, ``sitafe_ncm``,
``sitafe_produto_sefin`` e ``sitafe_produto_sefin_aux``) para evitar
acoplamento a arquivos de disco durante a execução dos testes.

Há também um teste opcional que carrega os parquets reais se disponíveis
em ``C:\\sistema_ro\\referencias\\CO_SEFIN`` (roda-se apenas no ambiente do
auditor).
"""

from __future__ import annotations

from datetime import date
from pathlib import Path

import polars as pl
import pytest

from sistema_ro.sitafe import (
    SitafeCarregado,
    aliquotas_st_mva_para,
    carregar_sitafe,
    parametros_fiscais_por_periodo,
    resolver_co_sefin,
    vigencia_por_co_sefin,
)


# ---------------------------------------------------------------------------
# Fixtures in-memory
# ---------------------------------------------------------------------------


def _sitafe_fake() -> SitafeCarregado:
    cest = pl.DataFrame(
        {
            "cest": ["0100100", "0200100", "1700100"],
            "co_sefin": ["8605", "2290", "1700"],
        }
    )
    cest_ncm = pl.DataFrame(
        {
            "cest": ["0100100", "0200100"],
            "ncm": ["38151290", "22051000"],
            "co_sefin": ["8605_ESPEC", "2290_ESPEC"],
        }
    )
    ncm = pl.DataFrame(
        {
            "ncm": ["38151290", "99999999", "17011400"],
            "co_sefin": ["8605", "9017", "8000"],
            "descricao": ["outros", "outros", "acucar"],
        }
    )
    produto = pl.DataFrame(
        {
            "co_sefin": ["8000", "8605_ESPEC", "2290_ESPEC", "9017"],
            "nome_produto": ["ACUCAR", "OUTROS_ESPEC", "VINHO", "OUTROS"],
            "ativo": ["S", "S", "S", "S"],
        }
    )
    vigencia = pl.DataFrame(
        {
            # acucar: duas vigências — uma até 2019-02-28 (com ST) e outra aberta
            "co_sefin": ["8000", "8000", "8605_ESPEC", "2290_ESPEC", "9017"],
            "data_inicio": [
                date(1996, 12, 30),
                date(2019, 3, 1),
                date(2020, 1, 1),
                date(2020, 1, 1),
                date(2020, 1, 1),
            ],
            "data_final": [date(2019, 2, 28), None, None, None, None],
            "aliquota_interna": [12.0, 12.0, 17.5, 37.0, 17.5],
            "st": [True, False, True, True, False],
            "mva": [40.0, 0.0, 35.0, 30.0, 0.0],
            "mva_ajustado": [False, False, True, False, False],
            "isento_icms": [False, False, False, False, False],
            "reducao": [False, False, False, False, False],
            "pc_reducao": [0.0, 0.0, 0.0, 0.0, 0.0],
        }
    )
    # adicionar flags UF
    for uf in ("ac", "al", "am", "ap", "ba", "ce", "df", "es", "go", "ma", "mg",
              "ms", "mt", "pa", "pb", "pe", "pi", "pr", "rj", "rn", "rr", "rs",
              "sc", "se", "sp", "to"):
        vigencia = vigencia.with_columns(pl.lit(True).alias(f"uf_{uf}"))

    return SitafeCarregado(
        cest=cest, cest_ncm=cest_ncm, ncm=ncm, produto=produto, vigencia=vigencia
    )


# ---------------------------------------------------------------------------
# Resolução de co_sefin
# ---------------------------------------------------------------------------


def test_resolver_co_sefin_preferencia_cest_ncm():
    s = _sitafe_fake()
    produtos = pl.DataFrame(
        {
            "id_produto_agrupado": ["G_CESTNCM", "G_CEST", "G_NCM", "G_DESC"],
            "ncm": ["38151290", "99999999", "17011400", "00000000"],
            "cest": ["0100100", "1700100", "", ""],
        }
    )
    out = resolver_co_sefin(produtos, s)
    por_id = {row["id_produto_agrupado"]: row for row in out.to_dicts()}

    assert por_id["G_CESTNCM"]["co_sefin"] == "8605_ESPEC"
    assert por_id["G_CESTNCM"]["origem_co_sefin"] == "cest_ncm"

    assert por_id["G_CEST"]["co_sefin"] == "1700"
    assert por_id["G_CEST"]["origem_co_sefin"] == "cest"

    assert por_id["G_NCM"]["co_sefin"] == "8000"
    assert por_id["G_NCM"]["origem_co_sefin"] == "ncm"

    assert por_id["G_DESC"]["co_sefin"] is None
    assert por_id["G_DESC"]["origem_co_sefin"] == "desconhecido"


def test_resolver_co_sefin_ignora_espacos():
    s = _sitafe_fake()
    produtos = pl.DataFrame(
        {
            "id_produto_agrupado": ["G1"],
            "ncm": ["  38151290 "],
            "cest": [" 0100100"],
        }
    )
    out = resolver_co_sefin(produtos, s)
    assert out.row(0, named=True)["co_sefin"] == "8605_ESPEC"


# ---------------------------------------------------------------------------
# Vigência temporal
# ---------------------------------------------------------------------------


def test_vigencia_respeita_data_final():
    s = _sitafe_fake()

    # dentro do período com ST
    v = vigencia_por_co_sefin(s, "8000", "2018-06-15")
    assert v is not None and v.row(0, named=True)["st"] is True

    # fora — depois de 2019-03-01, ST some
    v = vigencia_por_co_sefin(s, "8000", "2020-01-15")
    assert v is not None and v.row(0, named=True)["st"] is False

    # antes de qualquer vigência
    v = vigencia_por_co_sefin(s, "8000", "1990-01-01")
    assert v is None

    # co_sefin inexistente
    v = vigencia_por_co_sefin(s, "ZZZZ", "2022-01-01")
    assert v is None


def test_vigencia_sobreposicao_pega_mais_recente():
    s = _sitafe_fake()
    # Em 2019-03-01 as duas linhas de 8000 se encostam; vigência aberta
    # tem data_inicio mais recente.
    v = vigencia_por_co_sefin(s, "8000", "2019-03-15")
    assert v is not None
    linha = v.row(0, named=True)
    assert linha["st"] is False and linha["data_final"] is None


# ---------------------------------------------------------------------------
# Aplicação
# ---------------------------------------------------------------------------


def test_aliquotas_st_mva_populacao_correta():
    s = _sitafe_fake()
    produtos = pl.DataFrame(
        {
            "id_produto_agrupado": ["G1", "G2", "G_SEM_CO"],
            "co_sefin": ["8605_ESPEC", "2290_ESPEC", None],
        }
    )
    out = aliquotas_st_mva_para(produtos, s, data_referencia="2022-06-01")
    por_id = {row["id_produto_agrupado"]: row for row in out.to_dicts()}

    assert por_id["G1"]["aliquota_interna"] == pytest.approx(17.5)
    assert por_id["G1"]["st_vigente"] is True
    assert por_id["G1"]["mva_efetivo"] == pytest.approx(1.35)

    assert por_id["G2"]["aliquota_interna"] == pytest.approx(37.0)
    assert por_id["G2"]["st_vigente"] is True
    assert por_id["G2"]["mva_efetivo"] == pytest.approx(1.30)

    # sem co_sefin → defaults seguros
    assert por_id["G_SEM_CO"]["aliquota_interna"] == 0.0
    assert por_id["G_SEM_CO"]["st_vigente"] is False
    assert por_id["G_SEM_CO"]["mva_efetivo"] == 1.0


def test_aliquotas_st_desaparece_quando_data_fora_vigencia():
    s = _sitafe_fake()
    produtos = pl.DataFrame(
        {
            "id_produto_agrupado": ["ACUCAR"],
            "co_sefin": ["8000"],
        }
    )
    # ST vigente em 2018
    antes = aliquotas_st_mva_para(produtos, s, data_referencia="2018-06-01").row(0, named=True)
    assert antes["st_vigente"] is True
    assert antes["mva_efetivo"] == pytest.approx(1.40)

    # ST derrubado em 2020
    depois = aliquotas_st_mva_para(produtos, s, data_referencia="2020-01-15").row(0, named=True)
    assert depois["st_vigente"] is False
    assert depois["mva_efetivo"] == pytest.approx(1.0)


# ---------------------------------------------------------------------------
# Helper por período
# ---------------------------------------------------------------------------


def test_parametros_fiscais_por_periodo_anual():
    s = _sitafe_fake()
    produtos = pl.DataFrame(
        {
            "id_produto_agrupado": ["ACUCAR"],
            "co_sefin": ["8000"],
        }
    )
    aliq, st_df, mva_df = parametros_fiscais_por_periodo(
        produtos,
        s,
        periodos=[("2018", "2018-06-01"), ("2020", "2020-06-01")],
        granularidade="ano",
    )

    assert aliq.columns == ["id_produto_agrupado", "aliquota_interna"]
    assert aliq.row(0, named=True)["aliquota_interna"] == pytest.approx(12.0)

    # ST cai entre 2018 e 2020
    por_ano = {r["ano"]: r["st_vigente"] for r in st_df.to_dicts()}
    assert por_ano[2018] is True
    assert por_ano[2020] is False

    mva_por_ano = {r["ano"]: r["mva_efetivo"] for r in mva_df.to_dicts()}
    assert mva_por_ano[2018] == pytest.approx(1.40)
    assert mva_por_ano[2020] == pytest.approx(1.0)


def test_parametros_fiscais_por_periodo_mensal_e_periodo():
    s = _sitafe_fake()
    produtos = pl.DataFrame(
        {"id_produto_agrupado": ["G1"], "co_sefin": ["8605_ESPEC"]}
    )
    _, st_mensal, _ = parametros_fiscais_por_periodo(
        produtos, s, periodos=[("2022-01", "2022-01-31")], granularidade="mes"
    )
    assert set(st_mensal.columns) == {"id_produto_agrupado", "ano", "mes", "st_vigente"}
    assert st_mensal.row(0, named=True) == {
        "id_produto_agrupado": "G1",
        "ano": 2022,
        "mes": 1,
        "st_vigente": True,
    }

    _, st_per, _ = parametros_fiscais_por_periodo(
        produtos, s, periodos=[("P1", "2022-12-31")], granularidade="periodo"
    )
    assert set(st_per.columns) == {"id_produto_agrupado", "codigo_periodo", "st_vigente"}
    assert st_per.row(0, named=True)["codigo_periodo"] == "P1"


# ---------------------------------------------------------------------------
# Carregamento dos parquets reais (opcional)
# ---------------------------------------------------------------------------


_CO_SEFIN_DIR = Path("/sessions/affectionate-trusting-thompson/mnt/C:--sistema_ro/referencias/CO_SEFIN")


@pytest.mark.skipif(
    not _CO_SEFIN_DIR.exists(), reason="parquets CO_SEFIN não montados no ambiente"
)
def test_carregar_sitafe_parquets_reais():
    s = carregar_sitafe(_CO_SEFIN_DIR)

    assert s.cest.height > 100
    assert s.cest_ncm.height > 100
    assert s.ncm.height > 1000
    assert s.vigencia.height > 100

    # colunas normalizadas
    assert {"cest", "co_sefin"}.issubset(set(s.cest.columns))
    assert {"cest", "ncm", "co_sefin"}.issubset(set(s.cest_ncm.columns))
    assert {"ncm", "co_sefin", "descricao"}.issubset(set(s.ncm.columns))

    # datas convertidas corretamente (tipo Date)
    assert s.vigencia.schema["data_inicio"] == pl.Date
    assert s.vigencia.schema["data_final"] == pl.Date

    # pelo menos uma linha com co_sefin conhecido (acucar = 8000)
    assert s.vigencia.filter(pl.col("co_sefin") == "8000").height > 0

    # resolução de um NCM conhecido (38151290)
    produtos = pl.DataFrame(
        {
            "id_produto_agrupado": ["X"],
            "ncm": ["38151290"],
            "cest": ["0100100"],
        }
    )
    r = resolver_co_sefin(produtos, s)
    assert r.row(0, named=True)["co_sefin"] is not None
