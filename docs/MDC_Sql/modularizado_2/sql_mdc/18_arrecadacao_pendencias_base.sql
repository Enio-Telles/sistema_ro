/*
===============================================================================
MDC 18 - ARRECADAÇÃO / CONTA CORRENTE / PENDÊNCIAS
-------------------------------------------------------------------------------
Objetivo
- Reunir a camada de pagamento, inadimplência e malhas Fisconforme.
- Serve aos relatórios EFD Master, dossiês e análises de risco fiscal.

Granularidade
- 1 linha por lançamento arrecadatório ou pendência.
===============================================================================
*/
SELECT
    'ARRECADACAO' AS origem,
    t.co_cnpj_cpf,
    t.da_referencia,
    TO_CHAR(t.id_receita) AS codigo_1,
    TO_CHAR(t.id_situacao) AS codigo_2,
    t.va_principal,
    t.va_multa,
    t.va_juros,
    t.va_acrescimo,
    t.va_pago,
    t.da_arrecadacao,
    t.vencido,
    t.nu_complemento
FROM bi.fato_lanc_arrec_sum t
WHERE t.co_cnpj_cpf = REGEXP_REPLACE(TRIM(:CNPJ_CPF), '[^0-9]', '')
UNION ALL
SELECT
    'PENDENCIA' AS origem,
    p.cpf_cnpj,
    TO_DATE(p.periodo, 'YYYYMM') AS da_referencia,
    TO_CHAR(p.malhas_id) AS codigo_1,
    TO_CHAR(p.status) AS codigo_2,
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
FROM app_pendencia.pendencias p
WHERE p.cpf_cnpj = REGEXP_REPLACE(TRIM(:CNPJ_CPF), '[^0-9]', '');
