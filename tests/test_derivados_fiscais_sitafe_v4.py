"""
Testes do enriquecimento temporal ST via sitafe_produto_sefin_aux
para build_aba_anual_v4 e build_aba_mensal_v4.
"""
import polars as pl
import pytest

from pipeline.estoque.derivados_fiscais_v4 import build_aba_anual_v4, build_aba_mensal_v4


def _sitafe_aux_st_ativo() -> pl.DataFrame:
    """Produto '8510' com ST ativo de 2016-03-20 a 2099-12-31 (período aberto)."""
    return pl.DataFrame([
        {
            "it_co_sefin": "8510",
            "it_da_inicio": "20160320",
            "it_da_final": "20991231",
            "it_in_st": "S",
            "it_pc_interna": 17.0,
        }
    ])


def _sitafe_aux_st_expirado() -> pl.DataFrame:
    """Produto '8510' com ST que expirou em 2022-12-31."""
    return pl.DataFrame([
        {
            "it_co_sefin": "8510",
            "it_da_inicio": "20160320",
            "it_da_final": "20221231",
            "it_in_st": "S",
            "it_pc_interna": 17.0,
        }
    ])


def _mov_anual_sem_st(sefin: str = "8510", ano: int = 2024) -> pl.DataFrame:
    """mov_estoque anual com it_in_st=N (sem ST na movimentação), mas sefin existe no SITAFE."""
    return pl.DataFrame([
        {
            "id_agrupado": "P_SIT",
            "descr_padrao": "PRODUTO X",
            "unid_ref": "UN",
            "tipo_operacao": "1 - ENTRADA",
            "dt_doc": f"{ano}-01-10",
            "dt_e_s": f"{ano}-01-10",
            "q_conv": 10.0,
            "qtd": 10.0,
            "vl_item": 200.0,
            "preco_unit": 20.0,
            "entr_desac_anual": 4.0,  # 4 unidades sem cobertura fiscal
            "saldo_estoque_anual": 6.0,
            "co_sefin_agr": sefin,
            "it_pc_interna": 17.0,
            "it_in_st": "N",
        },
        {
            "id_agrupado": "P_SIT",
            "descr_padrao": "PRODUTO X",
            "unid_ref": "UN",
            "tipo_operacao": "2 - SAIDAS",
            "dt_doc": f"{ano}-06-15",
            "dt_e_s": f"{ano}-06-15",
            "q_conv": 3.0,
            "qtd": 3.0,
            "vl_item": 75.0,
            "preco_unit": 25.0,
            "entr_desac_anual": 0.0,
            "saldo_estoque_anual": 6.0,
            "co_sefin_agr": sefin,
            "it_pc_interna": 17.0,
            "it_in_st": "N",
        },
        {
            "id_agrupado": "P_SIT",
            "descr_padrao": "PRODUTO X",
            "unid_ref": "UN",
            "tipo_operacao": "3 - ESTOQUE FINAL",
            "dt_doc": f"{ano}-12-31",
            "dt_e_s": f"{ano}-12-31",
            "q_conv": 7.0,
            "qtd": 7.0,
            "vl_item": 0.0,
            "preco_unit": None,
            "entr_desac_anual": 0.0,
            "saldo_estoque_anual": 6.0,
            "co_sefin_agr": sefin,
            "it_pc_interna": 17.0,
            "it_in_st": "N",
        },
    ])


def _mov_mensal_sem_st(sefin: str = "8510", ano: int = 2024, mes: int = 6) -> pl.DataFrame:
    """mov_estoque mensal com it_in_st=N, entr_desac_periodo=2.0."""
    return pl.DataFrame([
        {
            "id_agrupado": "P_SIT_MES",
            "descr_padrao": "PRODUTO Y",
            "unid_ref": "UN",
            "unid": "UN",
            "tipo_operacao": "1 - ENTRADA",
            "dt_doc": f"{ano}-{mes:02d}-10",
            "dt_e_s": f"{ano}-{mes:02d}-10",
            "q_conv": 8.0,
            "qtd": 8.0,
            "vl_item": 160.0,
            "preco_unit": 20.0,
            "entr_desac_anual": 2.0,
            "saldo_estoque_anual": 8.0,
            "custo_medio_anual": 20.0,
            "entr_desac_periodo": 2.0,
            "saldo_estoque_periodo": 8.0,
            "custo_medio_periodo": 20.0,
            "co_sefin_agr": sefin,
            "it_pc_interna": 17.0,
            "it_in_st": "N",
            "it_pc_mva": 30.0,
            "it_in_mva_ajustado": "N",
            "aliq_inter": 12.0,
        }
    ])


# ----- Testes anual -----

def test_build_aba_anual_v4_sitafe_overrides_sem_st_to_st() -> None:
    """
    mov tem it_in_st=N → ST='SEM ST' sem sitafe_aux.
    Com sitafe_aux cobrindo 2024, deve mudar para ST='ST (...)' e zerar ICMS_saidas_desac.
    """
    mov = _mov_anual_sem_st(ano=2024)
    result_sem = build_aba_anual_v4(mov)
    row_sem = result_sem.row(0, named=True)
    assert row_sem["ST"] == "SEM ST"

    result_com = build_aba_anual_v4(mov, sitafe_aux_df=_sitafe_aux_st_ativo())
    row_com = result_com.row(0, named=True)

    assert row_com["ST"].startswith("ST")
    assert row_com["ICMS_saidas_desac"] == 0.0
    # ICMS_estoque_desac ainda é calculado (ST não zera estoque)
    # saldo_final=6.0, estoque_final=7.0 → saidas_desacob=max(7-6,0)=1.0, estoque_final_desacob=0.0
    assert row_com["ICMS_estoque_desac"] == 0.0  # estoque_final_desacob=0


def test_build_aba_anual_v4_sitafe_expired_does_not_affect_2024() -> None:
    """
    Sitafe com ST expirado em 2022. Em 2024, não deve mudar ST='SEM ST'.
    """
    mov = _mov_anual_sem_st(ano=2024)
    result = build_aba_anual_v4(mov, sitafe_aux_df=_sitafe_aux_st_expirado())
    row = result.row(0, named=True)
    assert row["ST"] == "SEM ST"


def test_build_aba_anual_v4_sitafe_expired_affects_2022() -> None:
    """
    Sitafe com ST expirado em 2022-12-31. Em 2022, deve ativar ST.
    """
    mov = _mov_anual_sem_st(ano=2022)
    result = build_aba_anual_v4(mov, sitafe_aux_df=_sitafe_aux_st_expirado())
    row = result.row(0, named=True)
    assert row["ST"].startswith("ST")
    assert row["ICMS_saidas_desac"] == 0.0


def test_build_aba_anual_v4_sitafe_updates_aliq_interna() -> None:
    """
    Sitafe fornece it_pc_interna=17.0 para um produto que tinha aliq_interna diferente.
    Após enriquecimento, aliq_interna deve refletir o valor do sitafe.
    """
    mov = _mov_anual_sem_st(sefin="8510", ano=2024)
    # Mudar aliq_interna nos dados de mov para 12.0 (diferente do sitafe 17.0)
    mov = mov.with_columns(pl.lit(12.0).alias("it_pc_interna"))

    sitafe = pl.DataFrame([{
        "it_co_sefin": "8510",
        "it_da_inicio": "20200101",
        "it_da_final": "20991231",
        "it_in_st": "S",
        "it_pc_interna": 17.0,
    }])

    result = build_aba_anual_v4(mov, sitafe_aux_df=sitafe)
    row = result.row(0, named=True)
    assert row["aliq_interna"] == 17.0


def test_build_aba_anual_v4_sitafe_none_unchanged() -> None:
    """
    Sem sitafe_aux_df, o comportamento é idêntico ao original.
    """
    mov = _mov_anual_sem_st(ano=2024)
    result = build_aba_anual_v4(mov, sitafe_aux_df=None)
    row = result.row(0, named=True)
    assert row["ST"] == "SEM ST"
    # ICMS_saidas_desac > 0 pois tem saidas_desacob = max(7-6, 0) = 1.0
    # pms = 75/3 = 25.0 → base = 1.0 * 25.0 = 25.0 → ICMS = 25.0 * 0.17 = 4.25
    assert round(row["ICMS_saidas_desac"], 2) == 4.25


# ----- Testes mensal -----

def test_build_aba_mensal_v4_sitafe_overrides_sem_st_to_st() -> None:
    """
    mov mensal tem it_in_st=N. Com sitafe cobrindo jun/2024, deve mudar ST e recalcular ICMS.
    """
    mov = _mov_mensal_sem_st(ano=2024, mes=6)
    result_sem = build_aba_mensal_v4(mov)
    row_sem = result_sem.row(0, named=True)
    assert row_sem["ST"] == "SEM ST"
    assert row_sem["ICMS_entr_desacob"] == 0.0  # sem ST, ICMS_entr_desacob=0

    result_com = build_aba_mensal_v4(mov, sitafe_aux_df=_sitafe_aux_st_ativo())
    row_com = result_com.row(0, named=True)

    assert row_com["ST"].startswith("ST")
    # Com ST ativo e pms=0: ICMS_entr_desacob = pme(20.0) * entradas_desacob(2.0) * aliq(17%) * MVA_efetivo(30/100=0.30)
    # = 20.0 * 2.0 * 0.17 * 0.30 = 2.04
    assert round(row_com["ICMS_entr_desacob"], 2) == 2.04


def test_build_aba_mensal_v4_sitafe_expired_does_not_affect_2024() -> None:
    """
    Sitafe expirado em 2022 não deve afetar jun/2024.
    """
    mov = _mov_mensal_sem_st(ano=2024, mes=6)
    result = build_aba_mensal_v4(mov, sitafe_aux_df=_sitafe_aux_st_expirado())
    row = result.row(0, named=True)
    assert row["ST"] == "SEM ST"
    assert row["ICMS_entr_desacob"] == 0.0


def test_build_aba_mensal_v4_sitafe_expired_affects_2022() -> None:
    """
    Sitafe expirado em 2022 deve ativar ST em jun/2022.
    """
    mov = _mov_mensal_sem_st(ano=2022, mes=6)
    result = build_aba_mensal_v4(mov, sitafe_aux_df=_sitafe_aux_st_expirado())
    row = result.row(0, named=True)
    assert row["ST"].startswith("ST")
    assert row["ICMS_entr_desacob"] > 0.0
