/*
===============================================================================
MUDANÇA DE TRIBUTAÇÃO ST - MÓDULO 21
ESTOQUE DO BLOCO H (H005 + H010 + H020 + 0200)
-------------------------------------------------------------------------------
Objetivo:
- materializar a fotografia do inventário;
- evidenciar, quando existir, o complemento tributário do H020.

Ponto jurídico relevante:
- para mudança de forma de tributação, recomenda-se filtrar H005.MOT_INV = '02'.
- o módulo deixa essa decisão explícita, para permitir tanto análise estrita
  quanto varredura ampliada.
===============================================================================
*/
WITH arquivos_validos AS (
    SELECT * FROM ARQUIVOS_RANKING WHERE rn = 1
)
SELECT
    TO_DATE(h005.dt_inv, 'DDMMYYYY') AS dt_inv,
    h005.mot_inv,
    REPLACE(REPLACE(REPLACE(LTRIM(h010.cod_item, '0'), ' ', ''), '.', ''), '-', '') AS cod_item_normalizado,
    h010.cod_item AS cod_item_original,
    r0200.descr_item,
    h010.unid,
    h010.vl_unit AS vl_unit_inventario,
    h010.vl_item AS vl_total_inventario,
    h010.qtd AS qtd_inventario,
    h020.reg AS reg_h020,
    h020.bc_icms AS bc_icms_h020,
    h020.cst_icms AS cst_icms_h020,
    h020.vl_icms AS vl_icms_h020,
    av.reg_0000_id,
    av.dt_ini AS data_arquivo_sped
FROM sped.reg_h010 h010
JOIN arquivos_validos av
  ON h010.reg_0000_id = av.reg_0000_id
JOIN sped.reg_0200 r0200
  ON r0200.reg_0000_id = h010.reg_0000_id
 AND r0200.cod_item = h010.cod_item
LEFT JOIN sped.reg_h005 h005
  ON h005.reg_0000_id = h010.reg_0000_id
LEFT JOIN sped.reg_h020 h020
  ON h020.reg_h010_id = h010.id
 AND h020.reg_0000_id = h010.reg_0000_id
WHERE (:filtrar_motivo_02 = 'N' OR h005.mot_inv = '02')
  AND (:cod_item IS NULL OR REPLACE(REPLACE(REPLACE(LTRIM(h010.cod_item, '0'), ' ', ''), '.', ''), '-', '') = :cod_item)
  AND (:data_inventario IS NULL OR TO_DATE(h005.dt_inv, 'DDMMYYYY') = TO_DATE(:data_inventario, 'DD/MM/YYYY'));
