/*
===============================================================================
ORQUESTRAÇÃO DE DUAS ABORDAGENS
-------------------------------------------------------------------------------
Objetivo:
- mostrar como as consultas básicas podem abastecer, ao mesmo tempo,
  a trilha de ressarcimento por C176 e a trilha de mudança de tributação.

Fluxo sugerido:
1) materializar as bases compartilhadas em views ou tabelas temporárias;
2) executar a trilha de ressarcimento;
3) executar a trilha de mudança de tributação;
4) reconciliar ambas no Bloco E e em painéis de auditoria.
===============================================================================
*/

-- Etapa A: bases compartilhadas
--   base_parametros_arquivos_efd
--   base_produtos_0200
--   base_documentos_c100_c170
--   base_xml_nfe_itens
--   base_inventario_h005_h010_h020
--   base_ajustes_bloco_e

-- Etapa B: abordagem 1 - ressarcimento com C176
--   saidas_ressarcimento_c176
--   itens_entrada_sped_base
--   score_candidatos_vinculo
--   vinculo_entrada_escolhido
--   base_vinculos_e_inferencia_sefin
--   base_juridica_icms_proprio
--   reconciliacao_bloco_e

-- Etapa C: abordagem 2 - mudança de tributação com inventário
--   estoque_bloco_h
--   nsu_documental
--   entradas_sped
--   ranking_ultima_entrada_inventario
--   base_mudanca_tributacao
--   base_juridica_mudanca
--   reconciliacao_mudanca_bloco_e

-- Etapa D: visão integrada (exemplo conceitual)
SELECT
    'RESSARCIMENTO_C176' AS abordagem,
    r.ref_periodo_efd AS referencia_periodo,
    r.produto_cod_item_saida AS codigo_item,
    r.RESSARC_ST_Considerado AS valor_principal,
    r.DIF_ST_Considerada AS diferenca
FROM resultado_final_ressarcimento r
UNION ALL
SELECT
    'MUDANCA_TRIBUTACAO' AS abordagem,
    TO_CHAR(m.data_inventario, 'MM/YYYY') AS referencia_periodo,
    m.codigo_item,
    m.vl_icms_h020 AS valor_principal,
    m.diff_valor_unitario AS diferenca
FROM resultado_final_mudanca_tributacao m;
