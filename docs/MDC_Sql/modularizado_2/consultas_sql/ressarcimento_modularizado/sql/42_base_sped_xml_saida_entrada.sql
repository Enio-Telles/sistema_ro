/*
===============================================================================
MÓDULO 42 - BASE DOCUMENTAL SPED + XML (SAÍDA E ENTRADA)
-------------------------------------------------------------------------------
Objetivo
- Unificar a prova documental mínima da saída e da entrada.
- Trazer SPED (C100/C170/C176/0200) e XML estruturado (fato_nfe_detalhe).

Ponto crítico
- A identificação do item da entrada aqui ainda é simplificada:
  chv_nfe + cod_item + MAX(num_item).
===============================================================================
*/

WITH arquivos_validos AS (
    SELECT * FROM arquivos_validos_fronteira
),
xml_extraido AS (
    SELECT * FROM xml_extraido_nfe_entrada
)
SELECT
    arq.dt_ini,
    TO_CHAR(arq.dt_ini, 'MM/YYYY') AS periodo_efd,
    CASE arq.cod_fin_efd
        WHEN '0' THEN '0 - Original'
        WHEN '1' THEN '1 - Substituto'
        ELSE TO_CHAR(arq.cod_fin_efd)
    END AS finalidade_efd,
    c100.chv_nfe AS chave_saida,
    c100.num_doc AS num_nf_saida,
    CASE WHEN c100.dt_doc IS NOT NULL AND REGEXP_LIKE(c100.dt_doc, '^\d{8}$')
         THEN TO_DATE(c100.dt_doc, 'DDMMYYYY') ELSE NULL END AS dt_emissao_saida,
    c170.num_item AS num_item_saida,
    c170.cod_item,
    r0200.cod_barra,
    r0200.descr_item,
    c170.descr_compl,
    r0200.cod_ncm,
    r0200.cest,
    NVL(c170.qtd, 0) AS qtd_saida,
    c170.vl_item AS vl_total_item_saida,
    NVL(c170.vl_icms, 0) AS c170_vl_icms,
    nfe_sai.dhemi AS xml_dhemi_saida,
    nfe_sai.prod_qcom AS xml_qtd_comercial_saida,
    nfe_sai.prod_xprod AS xml_descricao_item_saida,
    nfe_sai.prod_cean AS xml_cean_saida,
    nfe_sai.prod_ncm AS xml_ncm_saida,
    nfe_sai.prod_cest AS xml_cest_saida,
    nfe_sai.co_iddest AS xml_iddest_saida,
    nfe_sai.co_uf_emit AS xml_uf_emit_saida,
    nfe_sai.co_uf_dest AS xml_uf_dest_saida,
    c176.cod_mot_res,
    c176.chave_nfe_ult AS chave_nfe_ultima_entrada,
    c170_entrada.num_item AS num_item_ult_entr,
    CASE WHEN c176.dt_ult_e IS NOT NULL AND REGEXP_LIKE(c176.dt_ult_e, '^\d{8}$')
         THEN TO_DATE(c176.dt_ult_e, 'DDMMYYYY') ELSE NULL END AS dt_ultima_entrada,
    NVL(c176.quant_ult_e, 0) AS qtd_entrada_sped,
    NVL(c176.vl_unit_ult_e, 0) AS vl_unit_bc_st_entrada_sped,
    NVL(c176.vl_unit_icms_ult_e, 0) AS vl_unit_icms_proprio_entrada_sped,
    NVL(c176.vl_unit_res, 0) AS vl_unit_ressarcimento_st_sped,
    nfe_ent.dhemi AS xml_dhemi_entrada,
    NVL(nfe_ent.prod_qcom, 0) AS xml_qtd_comercial_entrada,
    nfe_ent.prod_xprod AS xml_descricao_item_entrada,
    nfe_ent.prod_cean AS xml_cean_entrada,
    nfe_ent.prod_ncm AS xml_ncm_entrada,
    nfe_ent.prod_cest AS xml_cest_entrada,
    nfe_ent.co_iddest AS xml_iddest_entrada,
    nfe_ent.co_uf_emit AS xml_uf_emit_entrada,
    nfe_ent.co_uf_dest AS xml_uf_dest_entrada,
    NVL(nfe_ent.prod_vprod, 0) AS xml_vprod_entrada,
    NVL(nfe_ent.ipi_vipi, 0) AS xml_vipi_entrada,
    NVL(nfe_ent.icms_vbc, 0) AS xml_vbc_icms_entrada,
    nfe_ent.icms_picms AS xml_aliquota_icms_proprio_entrada,
    NVL(nfe_ent.icms_vicms, 0) AS xml_icms_vicms_entrada_total,
    NVL(nfe_ent.icms_vicmsstret, 0) AS xml_icms_vicmsstret_entrada,
    NVL(nfe_ent.icms_vicmsst, 0) AS xml_icms_vicmsst_entrada,
    NVL(xml_ext.icms_vICMSSubstituto, 0) AS xml_icms_vicmssubstituto_entrada
FROM sped.reg_c176 c176
INNER JOIN arquivos_validos arq ON c176.reg_0000_id = arq.reg_0000_id
INNER JOIN sped.reg_c100 c100 ON c176.reg_c100_id = c100.id
INNER JOIN sped.reg_c170 c170 ON c176.reg_c170_id = c170.id
LEFT JOIN sped.reg_0200 r0200 ON r0200.reg_0000_id = c176.reg_0000_id AND r0200.cod_item = c170.cod_item
LEFT JOIN bi.fato_nfe_detalhe nfe_sai ON nfe_sai.chave_acesso = c100.chv_nfe AND nfe_sai.seq_nitem = TO_NUMBER(c170.num_item)
LEFT JOIN (
    SELECT c100_in.chv_nfe, c170_in.cod_item, MAX(c170_in.num_item) AS num_item
    FROM sped.reg_c100 c100_in
    INNER JOIN sped.reg_c170 c170_in ON c170_in.reg_c100_id = c100_in.id
    GROUP BY c100_in.chv_nfe, c170_in.cod_item
) c170_entrada
    ON c170_entrada.chv_nfe = c176.chave_nfe_ult AND c170_entrada.cod_item = c170.cod_item
LEFT JOIN bi.fato_nfe_detalhe nfe_ent ON nfe_ent.chave_acesso = c176.chave_nfe_ult AND nfe_ent.seq_nitem = TO_NUMBER(c170_entrada.num_item)
LEFT JOIN xml_extraido xml_ext ON xml_ext.chave_acesso = c176.chave_nfe_ult AND xml_ext.prod_nitem = TO_NUMBER(c170_entrada.num_item)
ORDER BY arq.dt_ini, c100.num_doc, c170.num_item;
