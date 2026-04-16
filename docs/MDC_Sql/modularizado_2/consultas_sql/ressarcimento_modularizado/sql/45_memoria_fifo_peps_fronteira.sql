/*
===============================================================================
MÓDULO 45 - MEMÓRIA FIFO/PEPS
-------------------------------------------------------------------------------
Objetivo
- Calcular a quantidade de entrada já consumida antes da linha corrente.
- Preservar a ordem PEPS/FIFO declarada pela consulta original.
===============================================================================
*/

WITH base_apurada AS (
    SELECT * FROM apuracao_ouro_unitaria
)
SELECT
    ba.*,
    NVL(
        SUM(ba.xml_qtd_comercial_entrada) OVER (
            PARTITION BY ba.chave_saida, ba.num_item_saida
            ORDER BY ba.xml_dhemi_entrada ASC, ba.chave_nfe_ultima_entrada ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ),
        0
    ) AS qtd_entrada_acumulada_anterior
FROM base_apurada ba
ORDER BY ba.dt_ini, ba.dt_emissao_saida, ba.num_item_saida, ba.xml_dhemi_entrada;
