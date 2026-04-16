/*
===============================================================================
MÓDULO 80 - PARÂMETROS E AJUSTE DO TOMADOR NO CT-e
-------------------------------------------------------------------------------
Objetivo
- Receber os parâmetros da trilha documental.
- Resolver o CNPJ/CPF efetivo do tomador no CT-e.

Granularidade
- 1 linha por chave de CT-e na base ajustada.

Regra de negócio
- O papel do tomador no CT-e depende de CO_TOMADOR3.
===============================================================================
*/

WITH parametros AS (
    SELECT
        REGEXP_REPLACE(TRIM(:CNPJ), '[^0-9]', '') AS cnpj,
        NVL(TO_DATE(:DATA_INICIAL, 'DD/MM/YYYY'), DATE '1900-01-01') AS data_inicial,
        NVL(TO_DATE(:DATA_FINAL,   'DD/MM/YYYY'), TRUNC(SYSDATE))    AS data_final
    FROM dual
),
cte_ajuste AS (
    SELECT
        c.chave_acesso,
        c.infprot_cstat,
        c.co_serie,
        c.co_nct,
        c.prest_vtprest,
        c.icms_vicms,
        c.dhemi,
        c.emit_co_cnpj,
        c.co_ufini,
        c.co_uffim,
        CASE
            WHEN c.co_tomador3 = '0' THEN c.rem_cnpj_cpf
            WHEN c.co_tomador3 = '1' THEN c.exp_co_cnpj_cpf
            WHEN c.co_tomador3 = '2' THEN c.receb_cnpj_cpf
            WHEN c.co_tomador3 = '3' THEN c.dest_cnpj_cpf
            ELSE c.co_tomador4_cnpj_cpf
        END AS cnpj_cpf_tomador
    FROM bi.fato_cte_detalhe c
)
SELECT *
FROM cte_ajuste;
