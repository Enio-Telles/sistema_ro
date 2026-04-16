/*
===============================================================================
MÓDULO 10 - CÁLCULOS DE RESSARCIMENTO
-------------------------------------------------------------------------------
Objetivo
- Calcular os valores intermediários e finais do ressarcimento:
  * ICMS próprio declarado e reconstruído;
  * ST declarada;
  * ST apurada no Fronteira;
  * MVA ajustada inferida;
  * valor calculado do ressarcimento ST;
  * valores "considerados" para auditoria.

Granularidade
- 1 linha por item de saída vinculado e com quantidade considerada.

Cuidado conceitual
- O valor calculado é referência de plausibilidade e reconciliação.
- Ele não deve ser tratado automaticamente como prova jurídica superior à entrada
  correspondente ou ao Fronteira.
===============================================================================
*/

WITH base_qtd AS (
    SELECT * FROM base_qtd_ressarcimento
),
base_calculos AS (
    SELECT
        q.*,
        NVL(q.vl_unit_icms_proprio_entrada, 0) * NVL(q.qtd_considerada, 0) AS sped_vl_ressarc_credito_proprio,
        NVL(q.xml_vl_unit_icms_proprio_entrada, 0) * NVL(q.qtd_considerada, 0) AS xml_vl_ressarc_credito_proprio,
        NVL(q.vl_unit_ressarcimento_st, 0) * NVL(q.qtd_considerada, 0) AS vl_ressarc_st_retido,
        NVL(q.fronteira_vl_unit_ressarcimento_st, 0) * NVL(q.qtd_considerada, 0) AS fronteira_vl_ressarcimento_st,
        CASE
            WHEN UPPER(TRIM(q.mva_ajustado_inferido)) = 'S'
             AND q.mva_inferido IS NOT NULL
             AND q.aliq_interna_inferida IS NOT NULL
             AND q.aliq_inter_entrada IS NOT NULL
             AND (1 - (q.aliq_interna_inferida / 100)) <> 0
            THEN ((((1 + (q.mva_inferido / 100)) * (1 - (q.aliq_inter_entrada / 100)))
                    / (1 - (q.aliq_interna_inferida / 100))) - 1) * 100
            ELSE q.mva_inferido
        END AS mva_ajustado_inferido_calc,
        CASE
            WHEN NVL(q.vl_icms, 0) > 0 THEN
                (NVL(q.vl_unit_ressarcimento_st, 0) * NVL(q.qtd_considerada, 0)) +
                (NVL(q.vl_unit_icms_proprio_entrada, 0) * NVL(q.qtd_considerada, 0))
            ELSE
                (NVL(q.vl_unit_ressarcimento_st, 0) * NVL(q.qtd_considerada, 0))
        END AS vr_total_ressarcimento
    FROM base_qtd q
),
base_final_1 AS (
    SELECT
        c.*,
        CASE
            WHEN c.mva_ajustado_inferido_calc IS NOT NULL
            THEN (
                    NVL(c.prod_vprod, 0)
                  + NVL(c.prod_vfrete, 0)
                  + NVL(c.prod_vseg, 0)
                  + NVL(c.prod_voutro, 0)
                  + NVL(c.ipi_vipi, 0)
                  - NVL(c.prod_vdesc, 0)
                 ) * (1 + (c.mva_ajustado_inferido_calc / 100))
            ELSE NULL
        END AS bc_icms_st_calc,
        CASE
            WHEN c.qcom_entrada IS NOT NULL
             AND NVL(c.qcom_entrada, 0) <> 0
             AND c.aliq_interna_inferida IS NOT NULL
             AND c.mva_ajustado_inferido_calc IS NOT NULL
            THEN (
                    (
                        (
                            (
                                NVL(c.prod_vprod, 0)
                              + NVL(c.prod_vfrete, 0)
                              + NVL(c.prod_vseg, 0)
                              + NVL(c.prod_voutro, 0)
                              + NVL(c.ipi_vipi, 0)
                              - NVL(c.prod_vdesc, 0)
                            ) * (1 + (c.mva_ajustado_inferido_calc / 100))
                        ) * (c.aliq_interna_inferida / 100)
                    ) - NVL(c.xml_icms_vicms_total_entrada, 0)
                 ) / c.qcom_entrada
            ELSE NULL
        END AS calculado_vl_unit_ressarcimento_st
    FROM base_calculos c
),
base_final AS (
    SELECT
        f.*,
        CASE
            WHEN f.calculado_vl_unit_ressarcimento_st IS NOT NULL
            THEN f.calculado_vl_unit_ressarcimento_st * NVL(f.qtd_considerada, 0)
            ELSE NULL
        END AS calculado_vl_ressarcimento_st,
        f.xml_vl_ressarc_credito_proprio AS ressarc_icms_proprio_considerado,
        CASE
            WHEN f.it_co_rotina_calculo IS NULL
              OR UPPER(TRIM(f.it_co_rotina_calculo)) <> 'ST'
            THEN
                CASE
                    WHEN f.calculado_vl_unit_ressarcimento_st IS NOT NULL
                    THEN f.calculado_vl_unit_ressarcimento_st * NVL(f.qtd_considerada, 0)
                    ELSE NULL
                END
            ELSE f.fronteira_vl_ressarcimento_st
        END AS ressarc_st_considerado,
        NVL(f.xml_vl_ressarc_credito_proprio, 0) - NVL(f.sped_vl_ressarc_credito_proprio, 0) AS dif_icms_prop_considerada,
        NVL(
            CASE
                WHEN f.it_co_rotina_calculo IS NULL
                  OR UPPER(TRIM(f.it_co_rotina_calculo)) <> 'ST'
                THEN
                    CASE
                        WHEN f.calculado_vl_unit_ressarcimento_st IS NOT NULL
                        THEN f.calculado_vl_unit_ressarcimento_st * NVL(f.qtd_considerada, 0)
                        ELSE NULL
                    END
                ELSE f.fronteira_vl_ressarcimento_st
            END, 0
        ) - NVL(f.vl_ressarc_st_retido, 0) AS dif_st_considerada
    FROM base_final_1 f
)
SELECT *
FROM base_final;
