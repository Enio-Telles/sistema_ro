/*
===============================================================================
MUDANÇA DE TRIBUTAÇÃO ST - MÓDULO 25
BASE COMPARATIVA DA MUDANÇA DE TRIBUTAÇÃO
-------------------------------------------------------------------------------
Objetivo:
- unir inventário, H020 e última entrada rastreada;
- publicar diferença de valor unitário e lacunas de prova documental.
===============================================================================
*/
SELECT
    e.dt_inv AS data_inventario,
    e.mot_inv,
    e.cod_item_normalizado AS codigo_item,
    e.cod_item_original,
    e.descr_item,
    e.unid AS unidade_inventario,
    e.qtd_inventario,
    e.vl_unit_inventario,
    e.vl_total_inventario,
    ue.data_ultima_compra,
    ue.vl_unit_entrada AS vl_unit_ultima_entrada,
    ue.cfop AS cfop_ultima_entrada,
    ue.chave_acesso AS chave_nfe_ultima_entrada,
    e.reg_h020,
    e.bc_icms_h020,
    e.cst_icms_h020,
    e.vl_icms_h020,
    ue.co_uf_emit AS uf_emitente_ultima_entrada,
    ue.co_uf_dest AS uf_destinatario_ultima_entrada,
    (e.vl_unit_inventario - NVL(ue.vl_unit_entrada, 0)) AS diff_valor_unitario,
    CASE
        WHEN ue.chave_acesso IS NULL THEN 'SEM ENTRADA ANTERIOR LOCALIZADA'
        WHEN e.reg_h020 IS NULL THEN 'SEM H020'
        ELSE 'BASE DOCUMENTAL MÍNIMA PRESENTE'
    END AS status_base_documental
FROM estoque_bloco_h e
LEFT JOIN ranking_ultima_entrada_inventario ue
  ON e.cod_item_normalizado = ue.cod_item_normalizado
 AND e.dt_inv = ue.dt_inv
 AND ue.rn = 1;
