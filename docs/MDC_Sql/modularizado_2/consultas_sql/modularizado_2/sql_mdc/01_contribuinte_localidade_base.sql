/*
===============================================================================
MDC 01 - CONTRIBUINTE E LOCALIDADE
-------------------------------------------------------------------------------
Objetivo
- Consolidar a identificação básica do sujeito passivo.
- Servir de base para relatórios EFD, dossiês, Fronteira e Fisconforme.

Granularidade
- 1 linha por CNPJ/CPF.
===============================================================================
*/
SELECT
    p.co_cnpj_cpf,
    p.no_razao_social,
    p.co_municipio,
    l.no_municipio,
    l.co_uf,
    p.co_regime_pagto,
    p.in_situacao
FROM bi.dm_pessoa p
LEFT JOIN bi.dm_localidade l
       ON l.co_municipio = p.co_municipio
WHERE p.co_cnpj_cpf = REGEXP_REPLACE(TRIM(:CNPJ_CPF), '[^0-9]', '');
