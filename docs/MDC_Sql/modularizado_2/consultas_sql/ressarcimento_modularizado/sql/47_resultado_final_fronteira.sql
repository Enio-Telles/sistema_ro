/*
===============================================================================
MÓDULO 47 - RESULTADO FINAL DA TRILHA FRONTEIRA PÓS-2022
-------------------------------------------------------------------------------
Objetivo
- Expor a visão final de auditoria da terceira abordagem.
- Comparar o valor declarado no SPED com o valor apurado pelo padrão ouro.
===============================================================================
*/

WITH base_rateio AS (
    SELECT * FROM rateio_fronteira
)
SELECT
    br.periodo_efd,
    br.finalidade_efd,
    br.chave_saida,
    br.num_nf_saida,
    br.dt_emissao_saida AS dt_saida_sped,
    br.num_item_saida,
    br.cod_item,
    br.cod_barra,
    br.descr_item,
    br.descr_compl,
    br.cod_ncm AS ncm_sped,
    br.cest,
    br.qtd_saida AS qtd_saida_sped,
    br.vl_total_item_saida,
    br.c170_vl_icms,
    br.cod_mot_res,
    CASE br.cod_mot_res
        WHEN '1' THEN '1 - Saída para outra UF'
        WHEN '2' THEN '2 - Saída amparada por isenção ou não incidência'
        WHEN '3' THEN '3 - Perda ou deterioração'
        WHEN '4' THEN '4 - Furto ou roubo'
        WHEN '5' THEN '5 - Exportação'
        WHEN '6' THEN '6 - Venda interna para Simples Nacional'
        WHEN '9' THEN '9 - Outros'
        ELSE br.cod_mot_res
    END AS descricao_motivo_ressarcimento,
    br.chave_nfe_ultima_entrada,
    br.num_item_ult_entr,
    br.dt_ultima_entrada AS dt_entrada_sped,
    br.qtd_entrada_sped,
    br.vl_unit_bc_st_entrada_sped,
    br.vl_unit_icms_proprio_entrada_sped,
    br.vl_unit_ressarcimento_st_sped,
    TRUNC(br.xml_dhemi_saida) AS dt_saida_xml,
    br.xml_qtd_comercial_saida AS qtd_saida_xml,
    br.xml_descricao_item_saida,
    br.xml_cean_saida,
    br.xml_ncm_saida,
    br.xml_cest_saida,
    br.xml_iddest_saida,
    br.xml_uf_emit_saida,
    br.xml_uf_dest_saida,
    TRUNC(br.xml_dhemi_entrada) AS dt_entrada_xml,
    br.xml_qtd_comercial_entrada AS qtd_entrada_xml,
    br.xml_descricao_item_entrada,
    br.xml_cean_entrada,
    br.xml_ncm_entrada,
    br.xml_cest_entrada,
    br.xml_iddest_entrada,
    br.xml_uf_emit_entrada,
    br.xml_uf_dest_entrada,
    br.xml_icms_vicmssubstituto_entrada,
    br.xml_fronteira_entrada,
    br.co_sefin_efetivo,
    br.it_pc_interna,
    br.it_in_st,
    br.it_in_mva_ajustado,
    br.it_pc_mva AS mva_original,
    br.mva_calculado_efetivo,
    br.xml_nivel_apuracao_st,
    br.xml_nivel_apuracao_proprio,
    br.xml_apurado_st_unitario,
    br.xml_apurado_proprio_unitario,
    br.qtd_entrada_acumulada_anterior,
    br.qtd_entrada_utilizada AS qtd_base_calculo_ressarcimento,
    CASE WHEN br.xml_dhemi_saida IS NULL THEN 'XML SAÍDA AUSENTE' ELSE 'OK' END AS status_xml_saida,
    CASE WHEN br.xml_dhemi_entrada IS NULL THEN 'XML ENTRADA AUSENTE' ELSE 'OK' END AS status_xml_entrada,
    CASE WHEN br.dt_emissao_saida IS NULL OR br.xml_dhemi_saida IS NULL THEN 'DATA EM FALTA' WHEN br.dt_emissao_saida = TRUNC(br.xml_dhemi_saida) THEN 'OK' ELSE 'DATA DIVERGENTE' END AS status_data_saida,
    CASE WHEN br.dt_ultima_entrada IS NULL OR br.xml_dhemi_entrada IS NULL THEN 'DATA EM FALTA' WHEN br.dt_ultima_entrada = TRUNC(br.xml_dhemi_entrada) THEN 'OK' ELSE 'DATA DIVERGENTE' END AS status_data_entrada,
    CASE WHEN br.cod_ncm = br.xml_ncm_saida AND br.cod_ncm = br.xml_ncm_entrada THEN 'OK' ELSE 'NCM DIVERGENTE (SPED/XML)' END AS status_ncm,
    CASE WHEN br.qtd_saida = NVL(br.xml_qtd_comercial_saida, 0) THEN 'OK' ELSE 'DIVERGENTE' END AS status_qtd_saida,
    CASE WHEN br.qtd_entrada_sped = br.xml_qtd_comercial_entrada THEN 'OK' ELSE 'DIVERGENTE' END AS status_qtd_entrada_c176,
    CASE WHEN ABS(ROUND(br.vl_unit_icms_proprio_entrada_sped, 2) - ROUND(br.xml_apurado_proprio_unitario, 2)) <= 0.05 THEN 'OK' ELSE 'DIVERGENTE' END AS status_icms_proprio_apurado,
    (br.qtd_saida * br.vl_unit_icms_proprio_entrada_sped) AS total_sped_icms_proprio_informado,
    (br.qtd_entrada_utilizada * br.xml_apurado_proprio_unitario) AS total_xml_icms_proprio_apurado,
    CASE WHEN ABS(ROUND(br.vl_unit_ressarcimento_st_sped, 2) - ROUND(br.xml_apurado_st_unitario, 2)) <= 0.05 THEN 'OK' ELSE 'DIVERGENTE' END AS status_icms_st_apurado,
    (br.qtd_entrada_utilizada * br.vl_unit_ressarcimento_st_sped) AS total_sped_ressarc_st_rateado,
    (br.qtd_entrada_utilizada * br.xml_apurado_st_unitario) AS total_apurado_ressarc_st_rateado,
    (br.qtd_entrada_utilizada * br.vl_unit_ressarcimento_st_sped) - (br.qtd_entrada_utilizada * br.xml_apurado_st_unitario) AS diferenca_financeira_st_sped_vs_apurado
FROM base_rateio br
ORDER BY br.dt_ini, br.dt_emissao_saida, br.num_nf_saida, br.num_item_saida, br.xml_dhemi_entrada;
