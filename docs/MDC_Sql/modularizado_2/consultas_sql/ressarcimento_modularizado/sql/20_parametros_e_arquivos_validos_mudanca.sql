/*
===============================================================================
MUDANÇA DE TRIBUTAÇÃO ST - MÓDULO 20
PARÂMETROS + ÚLTIMA EFD VÁLIDA
-------------------------------------------------------------------------------
Objetivo:
- reproduzir, de forma auditável, a seleção da última EFD por período usada
  na consulta original de mudança de tributação.

Observação crítica:
- a lógica original acrescenta 2 meses à data final. Isso pode ser útil para
  capturar inventários e apurações escriturados após o evento, mas é regra
  operacional do projeto, não imposição literal do leiaute.
===============================================================================
*/
WITH PARAMETROS AS (
    SELECT
        :CNPJ AS cnpj_filtro,
        TO_DATE(:data_inicial, 'DD/MM/YYYY') AS dt_ini_filtro,
        ADD_MONTHS(
            TO_DATE(NVL(:data_final, TO_CHAR(SYSDATE, 'DD/MM/YYYY')), 'DD/MM/YYYY'),
            2
        ) AS dt_fim_filtro,
        NULLIF(:cod_item, '') AS cod_filtro,
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte,
        TO_DATE(NULLIF(:data_inventario, ''), 'DD/MM/YYYY') AS dt_inv_especifica
    FROM dual
),
ARQUIVOS_RANKING AS (
    SELECT
        r.id AS reg_0000_id,
        r.cnpj,
        r.dt_ini,
        r.dt_fin,
        r.cod_fin,
        r.data_entrega,
        p.cod_filtro,
        p.dt_inv_especifica,
        ROW_NUMBER() OVER (
            PARTITION BY r.cnpj, r.dt_ini, NVL(r.dt_fin, r.dt_ini)
            ORDER BY r.data_entrega DESC, r.id DESC
        ) AS rn
    FROM sped.reg_0000 r
    JOIN PARAMETROS p
      ON r.cnpj = p.cnpj_filtro
    WHERE r.data_entrega <= p.dt_corte
      AND r.dt_ini BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
)
SELECT *
FROM ARQUIVOS_RANKING
WHERE rn = 1;
