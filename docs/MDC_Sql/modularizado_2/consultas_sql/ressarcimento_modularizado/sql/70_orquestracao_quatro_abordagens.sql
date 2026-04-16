/*
===============================================================================
MÓDULO 70 - ORQUESTRAÇÃO DAS QUATRO ABORDAGENS DO PACOTE
-------------------------------------------------------------------------------
Objetivo
- Mostrar como as quatro trilhas podem coexistir.
===============================================================================
*/

SELECT 'ABORDAGEM 1 - C176 + SCORE DE VINCULO' AS abordagem, COUNT(*) AS qtd_linhas
FROM resultado_final_auditoria
UNION ALL
SELECT 'ABORDAGEM 2 - MUDANCA DE TRIBUTACAO', COUNT(*)
FROM resultado_final_mudanca_tributacao
UNION ALL
SELECT 'ABORDAGEM 3 - FRONTEIRA POS-2022', COUNT(*)
FROM resultado_final_fronteira
UNION ALL
SELECT 'ABORDAGEM 4 - FRONTEIRA PRE-2022', COUNT(*)
FROM resultado_final_fronteira_ate_2022;
