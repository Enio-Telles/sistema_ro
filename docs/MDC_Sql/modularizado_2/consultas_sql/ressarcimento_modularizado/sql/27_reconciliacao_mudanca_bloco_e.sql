/*
===============================================================================
MUDANÇA DE TRIBUTAÇÃO ST - MÓDULO 27
RECONCILIAÇÃO COM BLOCO E
-------------------------------------------------------------------------------
Objetivo:
- verificar se o efeito da mudança de tributação foi refletido no Bloco E;
- separar créditos potenciais (E111) de débitos potenciais (E210/E220).

Observação:
- os códigos de ajuste devem ser parametrizados conforme o período e a UF.
===============================================================================
*/
WITH ajustes_bloco_e AS (
    SELECT * FROM base_ajustes_bloco_e
)
SELECT
    b.reg_0000_id,
    b.data_inventario,
    b.codigo_item,
    b.valor_h020_documental,
    b.status_juridico_inicial,
    SUM(CASE WHEN a.origem_bloco_e = 'E111' THEN NVL(a.vl_aj_apur, 0) ELSE 0 END) AS vl_total_e111,
    SUM(CASE WHEN a.origem_bloco_e = 'E220' THEN NVL(a.vl_aj_apur, 0) ELSE 0 END) AS vl_total_e220,
    CASE
        WHEN b.status_juridico_inicial LIKE 'POTENCIAL CRÉDITO%' AND SUM(CASE WHEN a.origem_bloco_e = 'E111' THEN NVL(a.vl_aj_apur, 0) ELSE 0 END) = 0
            THEN 'PENDENTE DE CONCILIAÇÃO NO E111'
        WHEN b.status_juridico_inicial LIKE 'POTENCIAL CRÉDITO%' THEN 'CONCILIADO OU PARCIALMENTE CONCILIADO'
        ELSE 'SEM TESTE AUTOMÁTICO CONCLUSIVO'
    END AS status_reconciliacao_bloco_e
FROM base_juridica_mudanca b
LEFT JOIN ajustes_bloco_e a
  ON a.reg_0000_id = b.reg_0000_id
GROUP BY
    b.reg_0000_id,
    b.data_inventario,
    b.codigo_item,
    b.valor_h020_documental,
    b.status_juridico_inicial;
