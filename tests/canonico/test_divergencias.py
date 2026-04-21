"""Testes das fórmulas de divergência — especialmente a correção
semântica das fórmulas de desacobertos.
"""

from __future__ import annotations

from sistema_ro.divergencias import calcular_base_e_icms, calcular_divergencias


def test_saldo_maior_que_declarado_produz_saidas_desacobertas():
    # Saldo calculado = 100, declarado = 80 → 20 de saídas não documentadas.
    r = calcular_divergencias(
        estoque_inicial=0.0,
        entradas=100.0,
        entradas_desacobertas=0.0,
        estoque_final_declarado=80.0,
        saldo_final_calculado=100.0,
    )
    assert r.saidas_desacobertas == 20.0
    assert r.estoque_final_desacoberto == 0.0


def test_declarado_maior_que_saldo_produz_estoque_desacoberto():
    # Saldo calculado = 50, declarado = 80 → 30 de estoque físico sem lastro.
    r = calcular_divergencias(
        estoque_inicial=0.0,
        entradas=60.0,
        entradas_desacobertas=0.0,
        estoque_final_declarado=80.0,
        saldo_final_calculado=50.0,
    )
    assert r.estoque_final_desacoberto == 30.0
    assert r.saidas_desacobertas == 0.0


def test_mutuamente_exclusivos():
    """Pelo menos uma das duas é zero em qualquer configuração."""

    import itertools

    for ei, e, ed, ef, sf in itertools.product(
        [0.0, 10.0], [0.0, 10.0], [0.0, 5.0], [0.0, 15.0], [0.0, 20.0]
    ):
        r = calcular_divergencias(
            estoque_inicial=ei,
            entradas=e,
            entradas_desacobertas=ed,
            estoque_final_declarado=ef,
            saldo_final_calculado=sf,
        )
        assert r.saidas_desacobertas == 0.0 or r.estoque_final_desacoberto == 0.0


def test_saidas_calculadas_nao_negativa():
    r = calcular_divergencias(
        estoque_inicial=10.0,
        entradas=5.0,
        entradas_desacobertas=0.0,
        estoque_final_declarado=100.0,  # absurdamente maior
        saldo_final_calculado=15.0,
    )
    assert r.saidas_calculadas == 0.0


class TestIcms:
    def test_usa_pms_quando_positivo(self):
        icms = calcular_base_e_icms(
            saidas_desacobertas=10.0,
            estoque_final_desacoberto=0.0,
            pme=5.0,
            pms=8.0,
            aliquota_interna=17.0,
            st_vigente=False,
        )
        assert icms.base_saida == 80.0
        assert round(icms.icms_saidas_desacobertas, 4) == round(80.0 * 0.17, 4)

    def test_fallback_pme_com_margem(self):
        icms = calcular_base_e_icms(
            saidas_desacobertas=10.0,
            estoque_final_desacoberto=0.0,
            pme=5.0,
            pms=0.0,
            aliquota_interna=17.0,
            st_vigente=False,
        )
        assert icms.base_saida == 10.0 * 5.0 * 1.30

    def test_st_zera_icms_saidas_mas_nao_estoque(self):
        icms = calcular_base_e_icms(
            saidas_desacobertas=10.0,
            estoque_final_desacoberto=4.0,
            pme=5.0,
            pms=8.0,
            aliquota_interna=17.0,
            st_vigente=True,
        )
        assert icms.icms_saidas_desacobertas == 0.0
        assert icms.icms_estoque_final_desacoberto > 0.0
