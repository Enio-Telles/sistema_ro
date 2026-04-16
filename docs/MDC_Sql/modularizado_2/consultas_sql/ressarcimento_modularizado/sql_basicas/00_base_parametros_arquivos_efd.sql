/*
===============================================================================
CONSULTA BÁSICA COMPARTILHADA 00
PARÂMETROS + ÚLTIMA EFD VÁLIDA POR PERÍODO
-------------------------------------------------------------------------------
Objetivo:
- centralizar parâmetros reutilizáveis pelas duas abordagens;
- escolher a última EFD entregue por período, respeitando data de corte.

Observação:
- esta consulta é base documental comum;
- a regra tributária específica será aplicada nos módulos próprios de
  ressarcimento (C176) e de mudança de tributação (Bloco H/H020).
===============================================================================
*/
WITH PARAMETROS AS (
    SELECT
        :CNPJ AS cnpj_filtro,
        TO_DATE(:data_inicial, 'DD/MM/YYYY') AS dt_ini_filtro,
        TO_DATE(NVL(:data_final, TO_CHAR(SYSDATE, 'DD/MM/YYYY')), 'DD/MM/YYYY') AS dt_fim_filtro,
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte
    FROM dual
),
ARQUIVOS_ULTIMA_EFD_PERIODO AS (
    SELECT *
    FROM (
        SELECT
            r.id AS reg_0000_id,
            r.cnpj,
            r.cod_fin,
            r.dt_ini,
            r.dt_fin,
            r.data_entrega,
            ROW_NUMBER() OVER (
                PARTITION BY r.cnpj, r.dt_ini, NVL(r.dt_fin, r.dt_ini)
                ORDER BY r.data_entrega DESC, r.id DESC
            ) AS rn
        FROM sped.reg_0000 r
        JOIN PARAMETROS p
          ON r.cnpj = p.cnpj_filtro
        WHERE r.data_entrega <= p.dt_corte
    )
    WHERE rn = 1
)
SELECT *
FROM ARQUIVOS_ULTIMA_EFD_PERIODO
WHERE dt_ini BETWEEN (SELECT dt_ini_filtro FROM PARAMETROS)
                 AND (SELECT dt_fim_filtro FROM PARAMETROS);
