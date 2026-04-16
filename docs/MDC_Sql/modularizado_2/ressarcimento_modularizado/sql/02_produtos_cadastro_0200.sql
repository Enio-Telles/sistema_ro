/*
===============================================================================
MÓDULO 02 - CADASTRO DE PRODUTOS 0200
-------------------------------------------------------------------------------
Objetivo
- Extrair NCM, CEST, GTIN e descrição do cadastro 0200.
- Produzir duas visões:
  1) produtos das EFDs da janela;
  2) produtos das últimas EFDs por período.

Granularidade
- 1 linha por reg_0000_id + cod_item.

Risco
- O uso de MAX() em campos cadastrais resolve duplicidade técnica, mas pode ocultar
  inconsistência cadastral dentro do próprio arquivo. Em produção, vale criar um
  relatório separado de divergência do 0200.
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
    SELECT *
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
),
PRODUTOS_SAIDA AS (
    SELECT
        r0200.reg_0000_id,
        r0200.cod_item,
        MAX(r0200.cod_barra) AS cod_barra,
        MAX(r0200.descr_item) AS descr_item,
        MAX(r0200.cod_ncm) AS cod_ncm,
        MAX(r0200.cest) AS cest
    FROM sped.reg_0200 r0200
    JOIN ARQUIVOS_VALIDOS arq
      ON r0200.reg_0000_id = arq.reg_0000_id
    GROUP BY r0200.reg_0000_id, r0200.cod_item
),
PRODUTOS_ULTIMA_EFD AS (
    SELECT
        r0200.reg_0000_id,
        r0200.cod_item,
        MAX(r0200.cod_barra) AS cod_barra,
        MAX(r0200.descr_item) AS descr_item,
        MAX(r0200.cod_ncm) AS cod_ncm,
        MAX(r0200.cest) AS cest
    FROM sped.reg_0200 r0200
    JOIN ARQUIVOS_ULTIMA_EFD_PERIODO arq
      ON r0200.reg_0000_id = arq.reg_0000_id
    GROUP BY r0200.reg_0000_id, r0200.cod_item
)
SELECT
    'PRODUTOS_SAIDA' AS origem_modulo,
    p.*
FROM PRODUTOS_SAIDA p
UNION ALL
SELECT
    'PRODUTOS_ULTIMA_EFD' AS origem_modulo,
    p.*
FROM PRODUTOS_ULTIMA_EFD p;
