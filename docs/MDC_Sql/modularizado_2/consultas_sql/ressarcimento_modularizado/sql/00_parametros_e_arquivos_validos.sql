/*
===============================================================================
MÓDULO 00 - PARÂMETROS E ARQUIVOS VÁLIDOS
-------------------------------------------------------------------------------
Objetivo
- Resolver os parâmetros da execução.
- Identificar a última EFD entregue para cada período.
- Restringir a análise à janela temporal pedida.

Granularidade
- 1 linha por arquivo EFD válido do contribuinte no intervalo.

Observação
- Este módulo é a base de versionamento. Ele não calcula ressarcimento.
- Qualquer erro aqui contamina todos os módulos seguintes.
===============================================================================
*/

WITH
PARAMETROS AS (
    SELECT
        :CNPJ AS cnpj_filtro,
        NVL(TO_DATE(:data_inicial, 'DD/MM/YYYY'), TO_DATE('01/01/1900', 'DD/MM/YYYY')) AS dt_ini_filtro,
        NVL(TO_DATE(:data_final, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_fim_filtro,
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte
    FROM dual
),
ARQUIVOS_ULTIMA_EFD_PERIODO AS (
    SELECT
        reg_0000_id,
        cnpj,
        cod_fin_efd,
        dt_ini,
        dt_fin,
        data_entrega
    FROM (
        SELECT
            r.id AS reg_0000_id,
            r.cnpj,
            r.cod_fin AS cod_fin_efd,
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
),
ARQUIVOS_VALIDOS AS (
    SELECT
        a.reg_0000_id,
        a.cnpj,
        a.cod_fin_efd,
        a.dt_ini,
        a.dt_fin,
        a.data_entrega
    FROM ARQUIVOS_ULTIMA_EFD_PERIODO a
    JOIN PARAMETROS p
      ON a.dt_ini BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
)
SELECT *
FROM ARQUIVOS_VALIDOS
ORDER BY dt_ini, data_entrega, reg_0000_id;
