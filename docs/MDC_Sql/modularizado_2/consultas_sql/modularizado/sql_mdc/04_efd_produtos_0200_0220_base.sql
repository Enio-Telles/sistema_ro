/*
===============================================================================
MDC 04 - PRODUTOS EFD (0200 + 0220)
-------------------------------------------------------------------------------
Objetivo
- Centralizar cadastro fiscal do item e fatores de conversão de unidade.
- Suportar ressarcimento, inventário, divergência de item e dossiês fiscais.

Granularidade
- 1 linha por item por arquivo EFD; 1..N fatores de conversão.
===============================================================================
*/
WITH arquivos_validos AS (
    SELECT reg_0000_id
    FROM (
        SELECT r.id AS reg_0000_id,
               ROW_NUMBER() OVER (
                   PARTITION BY r.cnpj, r.dt_ini, NVL(r.dt_fin, r.dt_ini)
                   ORDER BY r.data_entrega DESC, r.id DESC
               ) rn
        FROM sped.reg_0000 r
        WHERE r.cnpj = REGEXP_REPLACE(TRIM(:CNPJ_CPF), '[^0-9]', '')
          AND r.dt_ini BETWEEN TO_DATE(:DATA_INICIAL, 'DD/MM/YYYY')
                           AND TO_DATE(:DATA_FINAL, 'DD/MM/YYYY')
    )
    WHERE rn = 1
)
SELECT
    i.reg_0000_id,
    i.cod_item,
    i.descr_item,
    i.cod_barra,
    i.cod_ncm,
    i.cest,
    i.unid_inv,
    c.unid_conv,
    c.fat_conv
FROM sped.reg_0200 i
LEFT JOIN sped.reg_0220 c
       ON c.reg_0000_id = i.reg_0000_id
      AND c.cod_item    = i.cod_item
WHERE i.reg_0000_id IN (SELECT reg_0000_id FROM arquivos_validos);
