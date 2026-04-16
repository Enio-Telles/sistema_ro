/*
===============================================================================
MÓDULO 48 - RECONCILIAÇÃO BLOCO E (TRILHA FRONTEIRA PÓS-2022)
-------------------------------------------------------------------------------
Objetivo
- Confrontar o resultado final da trilha Fronteira com os ajustes do Bloco E.
- Medir se o total apurado por item conversa com E111, E210 e E220.
===============================================================================
*/

WITH resultado_final AS (
    SELECT * FROM resultado_final_fronteira
),
ajustes_bloco_e AS (
    SELECT * FROM base_ajustes_bloco_e
),
base_periodizada AS (
    SELECT periodo_efd,
           SUM(total_xml_icms_proprio_apurado) AS total_icms_proprio_apurado,
           SUM(total_apurado_ressarc_st_rateado) AS total_st_apurado
    FROM resultado_final
    GROUP BY periodo_efd
),
bloco_e_periodizado AS (
    SELECT TO_CHAR(dt_ini, 'MM/YYYY') AS periodo_efd,
           SUM(CASE WHEN origem_ajuste = 'E111' THEN vl_ajuste ELSE 0 END) AS total_e111,
           SUM(CASE WHEN origem_ajuste IN ('E210', 'E220') THEN vl_ajuste ELSE 0 END) AS total_e210_e220
    FROM ajustes_bloco_e
    GROUP BY TO_CHAR(dt_ini, 'MM/YYYY')
)
SELECT bp.periodo_efd,
       bp.total_icms_proprio_apurado,
       bp.total_st_apurado,
       be.total_e111,
       be.total_e210_e220,
       NVL(be.total_e111, 0) - NVL(bp.total_icms_proprio_apurado, 0) AS diff_e111_vs_icms_proprio,
       NVL(be.total_e210_e220, 0) - NVL(bp.total_st_apurado, 0) AS diff_e210e220_vs_st
FROM base_periodizada bp
LEFT JOIN bloco_e_periodizado be ON bp.periodo_efd = be.periodo_efd
ORDER BY bp.periodo_efd;
