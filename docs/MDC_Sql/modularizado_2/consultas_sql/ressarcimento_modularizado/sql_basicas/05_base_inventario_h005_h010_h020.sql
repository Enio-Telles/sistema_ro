/*
===============================================================================
CONSULTA BÁSICA COMPARTILHADA 05
BASE MÍNIMA DO INVENTÁRIO (H005/H010/H020)
-------------------------------------------------------------------------------
Objetivo:
- abrir o inventário do Bloco H de forma reutilizável;
- servir tanto à mudança de tributação quanto a validações complementares da
  rotina de ressarcimento.
===============================================================================
*/
WITH arquivos_validos AS (
    SELECT * FROM (
        SELECT
            r.id AS reg_0000_id,
            r.cnpj,
            r.dt_ini,
            ROW_NUMBER() OVER (
                PARTITION BY r.cnpj, r.dt_ini, NVL(r.dt_fin, r.dt_ini)
                ORDER BY r.data_entrega DESC, r.id DESC
            ) AS rn
        FROM sped.reg_0000 r
        WHERE r.cnpj = :CNPJ
          AND r.data_entrega <= NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE))
    )
    WHERE rn = 1
)
SELECT
    h005.reg_0000_id,
    TO_DATE(h005.dt_inv, 'DDMMYYYY') AS dt_inv,
    h005.mot_inv,
    h010.id AS reg_h010_id,
    h010.cod_item,
    REPLACE(REPLACE(REPLACE(LTRIM(h010.cod_item, '0'), ' ', ''), '.', ''), '-', '') AS cod_item_normalizado,
    h010.unid,
    h010.qtd,
    h010.vl_unit,
    h010.vl_item,
    h020.reg AS reg_h020,
    h020.bc_icms,
    h020.cst_icms,
    h020.vl_icms
FROM sped.reg_h005 h005
JOIN arquivos_validos av
  ON av.reg_0000_id = h005.reg_0000_id
LEFT JOIN sped.reg_h010 h010
  ON h010.reg_0000_id = h005.reg_0000_id
LEFT JOIN sped.reg_h020 h020
  ON h020.reg_h010_id = h010.id
 AND h020.reg_0000_id = h010.reg_0000_id;
