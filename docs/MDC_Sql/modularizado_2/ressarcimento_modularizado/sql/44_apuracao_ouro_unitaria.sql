/*
===============================================================================
MÓDULO 44 - APURAÇÃO OURO UNITÁRIA
-------------------------------------------------------------------------------
Objetivo
- Definir a hierarquia de apuração do ICMS-ST e do ICMS próprio.
- Calcular o valor unitário apurado com base na melhor fonte disponível.
===============================================================================
*/

WITH base_fiscal AS (
    SELECT * FROM base_fronteira_sefin_mva
)
SELECT
    bf.*,
    CASE
        WHEN bf.xml_fronteira_entrada <> 'sem calculo' THEN '1 - Fronteira (SITAFE)'
        WHEN NVL(bf.xml_icms_vicmsst_entrada, 0) > 0 THEN '2 - ICMS ST Destacado na NF'
        WHEN NVL(bf.xml_icms_vicmsstret_entrada, 0) > 0 THEN '3 - ICMS ST Retido / Substituto'
        ELSE '4 - Refeito pelo MVA (Estimado)'
    END AS xml_nivel_apuracao_st,
    CASE
        WHEN bf.xml_fronteira_entrada <> 'sem calculo' THEN '1 - Fronteira (SITAFE)'
        WHEN NVL(bf.xml_icms_vicms_entrada_total, 0) > 0 THEN '2 - ICMS Próprio Destacado na NF'
        WHEN NVL(bf.xml_icms_vicmssubstituto_entrada, 0) > 0 THEN '3 - ICMS Substituto Preenchido'
        ELSE '4 - Sem Destaque (Considerado 0)'
    END AS xml_nivel_apuracao_proprio,
    CASE
        WHEN bf.xml_fronteira_entrada <> 'sem calculo' THEN NVL(bf.xml_calc_fronteira_entrada_total, 0) / NULLIF(bf.xml_qtd_comercial_entrada, 0)
        WHEN NVL(bf.xml_icms_vicmsst_entrada, 0) > 0 THEN NVL(bf.xml_icms_vicmsst_entrada, 0) / NULLIF(bf.xml_qtd_comercial_entrada, 0)
        WHEN NVL(bf.xml_icms_vicmsstret_entrada, 0) > 0 THEN NVL(bf.xml_icms_vicmsstret_entrada, 0) / NULLIF(bf.xml_qtd_comercial_entrada, 0)
        ELSE GREATEST(0, (((NVL(bf.xml_vprod_entrada, NVL(bf.xml_vbc_icms_entrada, 0)) + NVL(bf.xml_vipi_entrada, 0)) * (1 + (NVL(bf.mva_calculado_efetivo, 0) / 100))) * (NVL(bf.it_pc_interna, 0) / 100) - NVL(bf.xml_icms_vicms_entrada_total, 0)) / NULLIF(bf.xml_qtd_comercial_entrada, 0))
    END AS xml_apurado_st_unitario,
    CASE
        WHEN bf.xml_fronteira_entrada <> 'sem calculo' THEN NVL(bf.xml_icms_vicms_entrada_total, 0) / NULLIF(bf.xml_qtd_comercial_entrada, 0)
        WHEN NVL(bf.xml_icms_vicms_entrada_total, 0) > 0 THEN NVL(bf.xml_icms_vicms_entrada_total, 0) / NULLIF(bf.xml_qtd_comercial_entrada, 0)
        WHEN NVL(bf.xml_icms_vicmssubstituto_entrada, 0) > 0 THEN NVL(bf.xml_icms_vicmssubstituto_entrada, 0) / NULLIF(bf.xml_qtd_comercial_entrada, 0)
        ELSE 0
    END AS xml_apurado_proprio_unitario
FROM base_fiscal bf
ORDER BY bf.dt_ini, bf.dt_emissao_saida, bf.num_item_saida;
