/*
===============================================================================
MÓDULO 65 - BASE DOCUMENTAL E FISCAL PRÉ-2022
-------------------------------------------------------------------------------
Objetivo
- Integrar item do XML, campos extraídos do XML bruto, item do SITAFE e o
  rateio de frete por item.
===============================================================================
*/

WITH classificacao_vigente AS (
    SELECT * FROM classificacao_fiscal_vigente
),
xml_extraido AS (
    SELECT * FROM xml_portalfiscal_extraido_ate_2022
),
credito_calc AS (
    SELECT * FROM credito_calculado_operacional
),
rateio_item AS (
    SELECT * FROM rateio_frete_cte_itens
)
SELECT
    nf.chave_acesso,
    nf.prod_nitem,
    nf.seq_nitem,
    nf.prod_cprod,
    nf.prod_xprod,
    nf.prod_ucom,
    nf.prod_qcom,
    nf.prod_ncm,
    nf.prod_cest,
    nf.co_crt,
    nf.dhemi,
    nf.icms_vicms,
    nf.icms_vicmsst,
    p.icms_vicmssubstituto,
    p.icms_vicmsstret,
    d.it_co_sefin,
    d.it_pc_icms,
    d.it_va_produto,
    d.it_va_frete,
    d.it_va_seguro,
    d.it_va_desconto,
    d.it_va_outro,
    d.it_va_ipi_item,
    cv.it_pc_interna,
    cv.it_in_st,
    cv.it_pc_mva,
    cv.it_in_mva_ajustado,
    cv.it_in_isento_icms,
    cv.it_in_reducao,
    cv.it_pc_reducao,
    cv.it_in_pmpf,
    cc.cred_calc,
    ri.rateio_frete_nf_item,
    ri.rateio_icms_frete_nf_item,
    ri.it_nu_chave_cte
FROM bi.fato_nfe_detalhe nf
LEFT JOIN sitafe.sitafe_nfe_item d
  ON nf.chave_acesso = d.it_nu_chave_acesso
 AND d.it_nu_item = nf.prod_nitem
LEFT JOIN classificacao_vigente cv
  ON cv.it_co_sefin = d.it_co_sefin
 AND nf.dhemi >= cv.dt_inicio_vig
 AND nf.dhemi <= cv.dt_final_vig
LEFT JOIN xml_extraido p
  ON p.chave_acesso = nf.chave_acesso
 AND p.prod_nitem = nf.prod_nitem
JOIN credito_calc cc
  ON cc.chave_acesso = nf.chave_acesso
 AND cc.prod_nitem = nf.prod_nitem
LEFT JOIN rateio_item ri
  ON ri.chave_acesso = nf.chave_acesso
 AND ri.prod_nitem = nf.prod_nitem
WHERE nf.chave_acesso IN (SELECT chave_acesso FROM tabela_chaves_alvo)
ORDER BY nf.chave_acesso, nf.prod_nitem;
