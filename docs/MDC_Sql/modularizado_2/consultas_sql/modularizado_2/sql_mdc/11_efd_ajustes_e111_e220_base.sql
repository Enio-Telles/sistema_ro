/*
===============================================================================
MDC 11 - AJUSTES DE APURAÇÃO (E111 / E220)
-------------------------------------------------------------------------------
Objetivo
- Trazer a camada de ajustes que efetivamente altera a apuração do período.
- Base direta para reconciliação de ressarcimento, mudança de tributação,
  relatórios EFD Master e análise por código de ajuste.

Granularidade
- 1 linha por ajuste lançado em apuração.
===============================================================================
*/
SELECT
    t.co_cnpj_cpf_declarante,
    t.da_referencia,
    t.registro,
    t.uf_st,
    t.cod_aj,
    aj.no_cod_aj,
    t.vl_aj_apur
FROM bi.fato_efd_sumarizada t
LEFT JOIN bi.dm_efd_ajustes aj
       ON aj.co_cod_aj = t.cod_aj
WHERE t.co_cnpj_cpf_declarante = REGEXP_REPLACE(TRIM(:CNPJ_CPF), '[^0-9]', '')
  AND t.da_referencia BETWEEN TO_DATE(:DATA_INICIAL, 'DD/MM/YYYY')
                           AND TO_DATE(:DATA_FINAL, 'DD/MM/YYYY')
  AND (
       t.registro = 'E111'
       OR (t.registro = 'E220' AND NVL(t.uf_st, 'RO') = 'RO')
  );
