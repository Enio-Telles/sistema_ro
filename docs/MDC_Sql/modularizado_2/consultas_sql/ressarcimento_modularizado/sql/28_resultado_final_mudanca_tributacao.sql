/*
===============================================================================
MUDANÇA DE TRIBUTAÇÃO ST - MÓDULO 28
RESULTADO FINAL AUDITÁVEL
-------------------------------------------------------------------------------
Objetivo:
- publicar a visão final da abordagem de mudança de tributação;
- combinar estoque, última entrada, H020, classificação jurídica e Bloco E.
===============================================================================
*/
SELECT
    b.data_inventario,
    b.mot_inv,
    b.codigo_item,
    b.cod_item_original,
    b.descr_item,
    b.unidade_inventario,
    b.qtd_inventario,
    b.vl_unit_inventario,
    b.vl_total_inventario,
    b.data_ultima_compra,
    b.vl_unit_ultima_entrada,
    b.cfop_ultima_entrada,
    b.chave_nfe_ultima_entrada,
    b.uf_emitente_ultima_entrada,
    b.uf_destinatario_ultima_entrada,
    b.reg_h020,
    b.bc_icms_h020,
    b.cst_icms_h020,
    b.vl_icms_h020,
    b.diff_valor_unitario,
    j.status_juridico_inicial,
    r.vl_total_e111,
    r.vl_total_e220,
    r.status_reconciliacao_bloco_e,
    CASE
        WHEN b.mot_inv <> '02' THEN 'REVISAR MOTIVO DO INVENTÁRIO'
        WHEN b.reg_h020 IS NULL THEN 'REVISAR AUSÊNCIA DE H020'
        WHEN r.status_reconciliacao_bloco_e = 'PENDENTE DE CONCILIAÇÃO NO E111' THEN 'REVISAR BLOCO E'
        ELSE 'BASE ANALÍTICA DISPONÍVEL PARA VALIDAÇÃO TRIBUTÁRIA'
    END AS recomendacao_auditoria
FROM base_mudanca_tributacao b
LEFT JOIN base_juridica_mudanca j
  ON j.reg_0000_id = b.reg_0000_id
 AND j.codigo_item = b.codigo_item
 AND j.data_inventario = b.data_inventario
LEFT JOIN reconciliacao_mudanca_bloco_e r
  ON r.reg_0000_id = b.reg_0000_id
 AND r.codigo_item = b.codigo_item
 AND r.data_inventario = b.data_inventario
ORDER BY b.data_inventario DESC, b.codigo_item;
