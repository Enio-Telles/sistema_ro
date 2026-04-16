/*
===============================================================================
MÓDULO 43 - CAMADA FISCAL FRONTEIRA + SEFIN + MVA
-------------------------------------------------------------------------------
Objetivo
- Integrar a base documental com o cálculo do Fronteira/SITAFE.
- Inferir produto Sefin, alíquota interna, ST e MVA vigentes.
===============================================================================
*/

WITH base_doc AS (
    SELECT * FROM base_sped_xml_saida_entrada
)
SELECT
    b.*,
    NVL(TO_CHAR(calc_front.it_co_rotina_calculo), 'sem calculo') AS xml_fronteira_entrada,
    NVL(calc_front.it_vl_icms, 0) AS xml_calc_fronteira_entrada_total,
    COALESCE(calc_front.it_co_sefin, cest_ncm.it_co_sefin) AS co_sefin_efetivo,
    h.it_pc_interna,
    h.it_in_st,
    h.it_in_mva_ajustado,
    h.it_pc_mva,
    CASE
        WHEN h.it_in_mva_ajustado = 'S' THEN
            (((1 + (NVL(h.it_pc_mva, 0) / 100))
              * (1 - (NVL(b.xml_aliquota_icms_proprio_entrada, 0) / 100))
              / NULLIF((1 - (NVL(h.it_pc_interna, 0) / 100)), 0)) - 1) * 100
        ELSE NVL(h.it_pc_mva, 0)
    END AS mva_calculado_efetivo
FROM base_doc b
LEFT JOIN sitafe.sitafe_nfe_calculo_item calc_front
    ON calc_front.it_nu_chave_acesso = b.chave_nfe_ultima_entrada
   AND calc_front.it_nu_item = b.num_item_ult_entr
LEFT JOIN sitafe.sitafe_cest_ncm cest_ncm
    ON cest_ncm.it_nu_ncm = b.xml_ncm_entrada
   AND (b.xml_cest_entrada IS NULL OR cest_ncm.it_nu_cest = b.xml_cest_entrada)
   AND NVL(cest_ncm.it_in_status, 'A') <> 'C'
LEFT JOIN sitafe.sitafe_produto_sefin_aux h
    ON h.it_co_sefin = COALESCE(calc_front.it_co_sefin, cest_ncm.it_co_sefin)
   AND TO_CHAR(b.xml_dhemi_entrada, 'YYYYMMDD') >= h.it_da_inicio
   AND (h.it_da_final IS NULL OR TO_CHAR(b.xml_dhemi_entrada, 'YYYYMMDD') <= h.it_da_final)
ORDER BY b.dt_ini, b.dt_emissao_saida, b.num_item_saida;
