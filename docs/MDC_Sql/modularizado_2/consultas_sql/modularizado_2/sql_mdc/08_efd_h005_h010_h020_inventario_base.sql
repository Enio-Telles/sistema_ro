/*
===============================================================================
MDC 08 - INVENTÁRIO E MUDANÇA DE TRIBUTAÇÃO (H005/H010/H020)
-------------------------------------------------------------------------------
Objetivo
- Centralizar a base do Bloco H para inventário e mudança de tributação.
- Sustenta as trilhas de inventário, última entrada e PEPS sobre estoque.

Granularidade
- 1 linha por item inventariado por data de inventário.

Observação
- Os nomes físicos SPED abaixo refletem a convenção encontrada nas queries de
  mudança de tributação analisadas.
===============================================================================
*/
WITH arquivos_validos AS (
    SELECT reg_0000_id, dt_ini
    FROM (
        SELECT r.id AS reg_0000_id,
               r.dt_ini,
               ROW_NUMBER() OVER (
                   PARTITION BY r.cnpj, r.dt_ini, NVL(r.dt_fin, r.dt_ini)
                   ORDER BY r.data_entrega DESC, r.id DESC
               ) rn
        FROM sped.reg_0000 r
        WHERE r.cnpj = REGEXP_REPLACE(TRIM(:CNPJ_CPF), '[^0-9]', '')
          AND r.dt_ini BETWEEN TO_DATE(:DATA_INICIAL, 'DD/MM/YYYY')
                           AND ADD_MONTHS(TO_DATE(:DATA_FINAL, 'DD/MM/YYYY'), 2)
    )
    WHERE rn = 1
)
SELECT
    a.dt_ini AS efd_ref,
    TO_DATE(h005.dt_inv, 'DDMMYYYY') AS dt_inv,
    h005.mot_inv,
    h010.id AS reg_h010_id,
    h010.cod_item,
    h010.unid,
    h010.qtd,
    h010.vl_item,
    h010.vl_unit,
    r0200.descr_item,
    r0200.cod_ncm,
    r0200.cest,
    h020.reg      AS reg_h020,
    h020.bc_icms  AS bc_icms_h020,
    h020.cst_icms AS cst_icms_h020,
    h020.vl_icms  AS vl_icms_h020
FROM sped.reg_h010 h010
JOIN arquivos_validos a
  ON a.reg_0000_id = h010.reg_0000_id
LEFT JOIN sped.reg_h005 h005
       ON h005.reg_0000_id = h010.reg_0000_id
LEFT JOIN sped.reg_h020 h020
       ON h020.reg_h010_id = h010.id
      AND h020.reg_0000_id = h010.reg_0000_id
LEFT JOIN sped.reg_0200 r0200
       ON r0200.reg_0000_id = h010.reg_0000_id
      AND r0200.cod_item    = h010.cod_item
WHERE :COD_ITEM IS NULL
   OR REPLACE(REPLACE(REPLACE(LTRIM(h010.cod_item, '0'), ' ', ''), '.', ''), '-', '') =
      REPLACE(REPLACE(REPLACE(LTRIM(:COD_ITEM, '0'), ' ', ''), '.', ''), '-', '');
