/*
===============================================================================
MÓDULO 67 - RESULTADO FINAL DA TRILHA PRÉ-2022
-------------------------------------------------------------------------------
Objetivo
- Expor, item a item, os valores documentais do XML e o cálculo refeito do ST.
===============================================================================
*/

WITH calc_pre_2022 AS (
    SELECT * FROM calculo_st_pre_2022
)
SELECT
    c.chave_acesso,
    c.prod_nitem AS n_item,
    c.seq_nitem AS seq_item,
    c.prod_cprod AS cprod_xml,
    c.prod_xprod AS descricao_item,
    c.prod_ucom AS unid,
    c.prod_qcom AS qtde,
    c.prod_ncm AS ncm,
    c.prod_cest AS cest,
    c.icms_vicms AS icms_prop_nf,
    c.icms_vicmssubstituto AS icms_vicms_substituto_xml,
    c.icms_vicmsst AS icms_st_nf,
    c.icms_vicmsstret AS icms_vicms_st_ret_xml,
    c.it_co_sefin,
    c.it_pc_mva,
    c.it_in_isento_icms,
    c.it_in_reducao,
    c.it_pc_reducao,
    c.it_pc_interna,
    c.it_pc_icms,
    c.it_in_pmpf,
    ROUND(NVL(c.rateio_frete_nf_item,0), 2) AS rateio_frete_nf_item,
    ROUND(NVL(c.rateio_icms_frete_nf_item,0), 2) AS rateio_icms_frete_nf_item,
    c.it_nu_chave_cte,
    c.cred_calc AS credito_calculado_operacional,
    c.metodo_calculo_pre_2022,
    c.calc_st_pre_2022,
    CASE
        WHEN c.calc_st_pre_2022 IS NULL THEN 'NAO_ST'
        WHEN ABS(NVL(c.calc_st_pre_2022,0) - NVL(c.icms_vicmsst,0)) <= 0.05 THEN 'ADERENTE AO ST DESTACADO'
        WHEN ABS(NVL(c.calc_st_pre_2022,0) - NVL(c.icms_vicmsstret,0)) <= 0.05 THEN 'ADERENTE AO ST RETIDO'
        ELSE 'DIVERGENTE / EXIGE REVISAO'
    END AS status_calc_st_pre_2022
FROM calc_pre_2022 c
ORDER BY c.chave_acesso, c.prod_nitem;
