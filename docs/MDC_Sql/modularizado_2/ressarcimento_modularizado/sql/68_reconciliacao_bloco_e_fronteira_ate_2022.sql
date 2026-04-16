/*
===============================================================================
MÓDULO 68 - RECONCILIAÇÃO COM BLOCO E DA TRILHA PRÉ-2022
-------------------------------------------------------------------------------
Objetivo
- Agregar o cálculo refeito por período e confrontar com E111/E210/E220.

Observação
- Este módulo é opcional porque a query original trabalha por chave, e não
  necessariamente por universo mensal completo.
===============================================================================
*/

WITH resultado_pre_2022 AS (
    SELECT * FROM resultado_final_fronteira_ate_2022
),
base_bloco_e AS (
    SELECT * FROM base_ajustes_bloco_e
)
SELECT
    TRUNC(nf.dhemi, 'MM') AS competencia,
    COUNT(*) AS qtd_itens_auditados,
    SUM(NVL(r.calc_st_pre_2022, 0)) AS vl_calc_st_pre_2022,
    SUM(NVL(nf.icms_vicmsst, 0)) AS vl_st_xml,
    SUM(NVL(nf.icms_vicms, 0)) AS vl_icms_proprio_xml,
    SUM(CASE WHEN e.registro_bloco = 'E111' THEN NVL(e.valor_ajuste, 0) ELSE 0 END) AS vl_e111,
    SUM(CASE WHEN e.registro_bloco IN ('E210','E220') THEN NVL(e.valor_ajuste, 0) ELSE 0 END) AS vl_e210_e220
FROM resultado_pre_2022 r
JOIN bi.fato_nfe_detalhe nf
  ON nf.chave_acesso = r.chave_acesso
 AND nf.prod_nitem = r.n_item
LEFT JOIN base_bloco_e e
  ON TRUNC(e.data_referencia, 'MM') = TRUNC(nf.dhemi, 'MM')
GROUP BY TRUNC(nf.dhemi, 'MM')
ORDER BY competencia;
