/*
===============================================================================
MDC 09 - AJUSTES DOCUMENTAIS (C197)
-------------------------------------------------------------------------------
Objetivo
- Capturar ajustes por documento fiscal que ainda não estão na apuração E111/E220.
- Base útil para relatórios EFD Master e malhas de coerência entre documento e
  apuração.

Granularidade
- 1 linha por ajuste documental agregado na dimensão C197.
===============================================================================
*/
SELECT
    t.co_declarante,
    t.da_referencia,
    t.cod_aj,
    aj.no_cod_aj,
    t.vl_bc_icms,
    t.vl_icms,
    t.vl_outros
FROM bi.dm_efd_c197 t
LEFT JOIN bi.dm_efd_ajustes aj
       ON aj.co_cod_aj = t.cod_aj
WHERE t.co_declarante = REGEXP_REPLACE(TRIM(:CNPJ_CPF), '[^0-9]', '')
  AND t.da_referencia BETWEEN TO_DATE(:DATA_INICIAL, 'DD/MM/YYYY')
                           AND TO_DATE(:DATA_FINAL, 'DD/MM/YYYY');
