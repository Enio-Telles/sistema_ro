/*
===============================================================================
MDC 00 - PARÂMETROS CANÔNICOS
-------------------------------------------------------------------------------
Objetivo
- Normalizar os parâmetros mínimos comuns a quase todas as trilhas analisadas.
- Padronizar CNPJ/CPF, período e data limite de processamento.

Granularidade
- 1 linha por execução.

Por que está no MDC
- Quase todas as consultas analisadas nesta conversa começam por filtros de
  contribuinte, período e, quando a origem é SPED, data de corte da entrega.
===============================================================================
*/
SELECT
    REGEXP_REPLACE(TRIM(:CNPJ_CPF), '[^0-9]', '') AS cnpj_cpf,
    NVL(TO_DATE(:DATA_INICIAL, 'DD/MM/YYYY'), DATE '1900-01-01') AS data_inicial,
    NVL(TO_DATE(:DATA_FINAL,   'DD/MM/YYYY'), TRUNC(SYSDATE))    AS data_final,
    NVL(TO_DATE(:DATA_LIMITE_PROCESSAMENTO, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS data_corte,
    NULLIF(:COD_ITEM, '') AS cod_item,
    TO_DATE(NULLIF(:DATA_INVENTARIO, ''), 'DD/MM/YYYY') AS data_inventario
FROM dual;
