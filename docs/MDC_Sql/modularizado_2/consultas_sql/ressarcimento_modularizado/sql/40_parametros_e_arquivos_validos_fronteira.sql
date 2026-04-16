/*
===============================================================================
MÓDULO 40 - PARÂMETROS E ARQUIVOS VÁLIDOS (TRILHA FRONTEIRA PÓS-2022)
-------------------------------------------------------------------------------
Objetivo
- Receber os filtros da consulta.
- Escolher a última EFD válida por período, respeitando a data de corte.

Granularidade
- 1 linha por reg_0000_id selecionado.

Regra de negócio
- A trilha parte sempre da última EFD disponível no período.
===============================================================================
*/

WITH PARAMETROS AS (
    SELECT
        :CNPJ AS cnpj_filtro,
        NVL(TO_DATE(:data_inicial, 'DD/MM/YYYY'), TO_DATE('01/01/1900', 'DD/MM/YYYY')) AS dt_ini_filtro,
        NVL(TO_DATE(:data_final, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_fim_filtro,
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte
    FROM dual
),
ARQUIVOS_RANKING AS (
    SELECT
        reg_0000.id AS reg_0000_id,
        reg_0000.cnpj,
        reg_0000.cod_fin AS cod_fin_efd,
        reg_0000.dt_ini,
        reg_0000.data_entrega,
        ROW_NUMBER() OVER (
            PARTITION BY reg_0000.cnpj, reg_0000.dt_ini
            ORDER BY reg_0000.data_entrega DESC, reg_0000.id DESC
        ) AS rn
    FROM sped.reg_0000 reg_0000
    JOIN PARAMETROS p
      ON reg_0000.cnpj = p.cnpj_filtro
    WHERE reg_0000.data_entrega <= p.dt_corte
      AND reg_0000.dt_ini BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
)
SELECT reg_0000_id, cnpj, cod_fin_efd, dt_ini, data_entrega
FROM ARQUIVOS_RANKING
WHERE rn = 1
ORDER BY dt_ini;
