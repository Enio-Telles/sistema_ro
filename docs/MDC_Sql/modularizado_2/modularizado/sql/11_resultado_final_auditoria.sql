/*
===============================================================================
MÓDULO 11 - RESULTADO FINAL DE AUDITORIA
-------------------------------------------------------------------------------
Objetivo
- Expor a visão final auditável do ressarcimento por item.

Granularidade
- 1 linha por item de saída analisado.

Observação
- Esta projeção pode ser reduzida ou expandida conforme a necessidade.
- Em produção, recomenda-se separar:
  1) colunas técnicas de rastreabilidade;
  2) colunas fiscais de cálculo;
  3) colunas amigáveis para UI/relatório.
===============================================================================
*/

WITH base_final AS (
    SELECT * FROM base_final_ressarcimento
)
SELECT
    TO_CHAR(b.comp_efd, 'MM/YYYY') AS ref_periodo_efd,
    CASE b.cod_fin_efd
        WHEN '0' THEN '0 - Original'
        WHEN '1' THEN '1 - Substituto'
        ELSE TO_CHAR(b.cod_fin_efd)
    END AS ref_finalidade_efd,
    b.chave_saida AS ref_chave_nfe_saida,
    b.num_nf_saida AS ref_num_nf_saida,
    b.dt_emissao_saida AS ref_dt_emissao_saida,
    b.num_item_saida AS ref_num_item_saida,
    b.chave_nfe_ultima_entrada AS ref_chave_nfe_ultima_entrada,
    b.dt_ultima_entrada AS ref_dt_ultima_entrada,
    b.num_item_ult_entr AS ref_num_item_ultima_entrada_sped,
    b.cod_item AS produto_cod_item_saida,
    b.cod_item_entrada_candidato AS produto_cod_item_entrada_escolhido,
    b.cod_barra AS produto_cod_barra,
    b.descr_item AS produto_descr_item_0200,
    b.descricao_item AS produto_descr_compl_saida_sped,
    b.cod_ncm AS produto_ncm_0200,
    b.cest AS produto_cest_0200,
    b.regra_vinculo_entrada AS aud_regra_vinculo_entrada,
    b.ind_match_cod_item AS aud_ind_match_cod_item,
    b.ind_match_num_item_doc AS aud_ind_match_num_item_doc,
    b.ind_match_cod_barra AS aud_ind_match_cod_barra,
    b.existe_match_cod_item AS aud_existe_match_cod_item,
    b.ind_conflito_ncm AS aud_ind_conflito_ncm,
    b.ind_conflito_cest AS aud_ind_conflito_cest,
    b.score_vinculo_entrada AS aud_score_vinculo_entrada,
    b.score_segundo_colocado AS aud_score_segundo_colocado,
    b.gap_top2 AS aud_gap_top2,
    b.status_gap_vinculo AS aud_status_gap_vinculo,
    b.diff_qtd_vinculo AS aud_diff_qtd_vinculo,
    CASE
        WHEN b.ind_conflito_ncm = 1 OR b.ind_conflito_cest = 1
            THEN 'REVISAO OBRIGATORIA'
        WHEN b.score_vinculo_entrada >= 75
         AND NVL(b.gap_top2, b.score_vinculo_entrada) >= 15
            THEN 'ALTA CONFIANCA'
        WHEN b.score_vinculo_entrada >= 55
         AND NVL(b.gap_top2, b.score_vinculo_entrada) >= 8
            THEN 'MEDIA CONFIANCA'
        WHEN b.score_vinculo_entrada IS NOT NULL
            THEN 'BAIXA CONFIANCA'
        ELSE 'SEM VINCULO AVALIADO'
    END AS aud_nivel_confianca_vinculo,
    b.co_sefin_inferido AS sefin_co_sefin_inferido,
    b.ncm_prioritario_sefin AS sefin_ncm_prioritario,
    b.cest_prioritario_sefin AS sefin_cest_prioritario,
    b.aliq_interna_inferida AS sefin_aliq_interna_inferida,
    b.st_inferido AS sefin_st_inferido,
    b.mva_inferido AS sefin_mva_inferido,
    b.mva_ajustado_inferido AS sefin_ind_mva_ajustado,
    b.aliq_inter_entrada AS sefin_aliq_inter_entrada,
    b.mva_ajustado_inferido_calc AS sefin_mva_ajustado_calc,
    b.qtd_saida_sped AS sped_qtd_saida,
    b.vl_total_item_saida AS sped_vl_total_item_saida,
    b.vl_icms AS sped_vl_icms_saida,
    b.vl_unit_bc_st_entrada AS sped_vl_unit_bc_st_entrada,
    b.vl_unit_icms_proprio_entrada AS sped_vl_unit_icms_proprio_entrada,
    b.vl_unit_ressarcimento_st AS sped_vl_unit_ressarcimento_st,
    b.qtd_considerada AS sped_qtd_considerada,
    b.sped_vl_ressarc_credito_proprio AS sped_vl_ressarc_credito_proprio,
    b.vl_ressarc_st_retido AS sped_vl_ressarc_st_retido,
    b.vr_total_ressarcimento AS sped_vl_total_ressarcimento,
    b.qcom_saida AS xml_qcom_saida,
    b.qcom_entrada AS xml_qcom_entrada,
    b.soma_qcom_entrada_total AS xml_soma_qcom_entrada_total,
    b.soma_qcom_entrada_acum AS xml_soma_qcom_entrada_acum,
    b.xml_descricao_item_entrada AS xml_descr_item_entrada,
    b.xml_ncm_entrada AS xml_ncm_entrada,
    b.xml_cest_entrada AS xml_cest_entrada,
    b.prod_vprod AS xml_vprod,
    b.prod_vfrete AS xml_vfrete,
    b.prod_vseg AS xml_vseg,
    b.prod_voutro AS xml_voutro,
    b.prod_vdesc AS xml_vdesc,
    b.ipi_vipi AS xml_vipi,
    b.xml_icms_vicms_total_entrada AS xml_vl_icms_total_entrada,
    b.xml_vl_unit_icms_proprio_entrada AS xml_vl_unit_icms_proprio_entrada,
    b.xml_vl_ressarc_credito_proprio AS xml_vl_ressarc_credito_proprio,
    b.it_co_rotina_calculo AS fronteira_rotina_calculo,
    b.vl_icms_fronteira AS fronteira_vl_icms_total,
    b.fronteira_vl_unit_ressarcimento_st AS fronteira_vl_unit_ressarcimento_st,
    b.fronteira_vl_ressarcimento_st AS fronteira_vl_ressarcimento_st,
    b.bc_icms_st_calc AS calc_bc_icms_st,
    b.calculado_vl_unit_ressarcimento_st AS calc_vl_unit_ressarcimento_st,
    b.calculado_vl_ressarcimento_st AS calc_vl_ressarcimento_st,
    b.sped_vl_ressarc_credito_proprio - b.xml_vl_ressarc_credito_proprio AS aud_diff_sped_xml_icms_proprio,
    b.vl_ressarc_st_retido - b.fronteira_vl_ressarcimento_st AS aud_diff_sped_fronteira_st,
    NVL(b.calculado_vl_ressarcimento_st, 0) - NVL(b.vl_ressarc_st_retido, 0) AS aud_diff_calc_sped_st,
    CASE
        WHEN NVL(b.qcom_saida, 0) = 0 THEN 'SEM QCOM DE SAIDA'
        WHEN NVL(b.qcom_entrada, 0) = 0 THEN 'SEM QCOM DE ENTRADA'
        WHEN b.soma_qcom_entrada_total > b.qcom_saida THEN 'LIMITADO PELA QCOM DA SAIDA'
        ELSE 'QCOM TOTAL DE ENTRADA DENTRO DO LIMITE DA SAIDA'
    END AS aud_status_qtd_considerada,
    CASE
        WHEN b.qcom_saida IS NULL THEN 'QCOM DE SAIDA NAO ENCONTRADA'
        WHEN NVL(b.qcom_saida, 0) = 0 THEN 'QCOM DE SAIDA ZERADA'
        WHEN b.qtd_considerada = 0 THEN 'SEM QUANTIDADE CONSIDERADA'
        WHEN b.xml_vl_unit_icms_proprio_entrada IS NULL THEN 'XML NAO ENCONTRADO/FORA DO FILTRO'
        WHEN ABS(NVL(b.sped_vl_ressarc_credito_proprio, 0) - NVL(b.xml_vl_ressarc_credito_proprio, 0)) > 10
        THEN 'VALORES DIVERGENTES'
        ELSE 'VALORES IGUAIS'
    END AS aud_status_sped_xml_icms_proprio,
    CASE
        WHEN b.it_co_rotina_calculo IS NULL THEN 'FRONTEIRA NAO ENCONTRADA'
        WHEN UPPER(TRIM(b.it_co_rotina_calculo)) <> 'ST' THEN 'ROTINA DIFERENTE DE ST'
        WHEN b.qcom_saida IS NULL THEN 'QCOM DE SAIDA NAO ENCONTRADA'
        WHEN NVL(b.qcom_saida, 0) = 0 THEN 'QCOM DE SAIDA ZERADA'
        WHEN b.qtd_considerada = 0 THEN 'SEM QUANTIDADE CONSIDERADA'
        WHEN ABS(NVL(b.vl_ressarc_st_retido, 0) - NVL(b.fronteira_vl_ressarcimento_st, 0)) > 10
        THEN 'VALORES DIVERGENTES'
        ELSE 'VALORES IGUAIS'
    END AS aud_status_sped_fronteira_st,
    CASE
        WHEN b.calculado_vl_ressarcimento_st IS NULL THEN 'VALOR CALCULADO NAO DISPONIVEL'
        WHEN ABS(NVL(b.calculado_vl_ressarcimento_st, 0) - NVL(b.vl_ressarc_st_retido, 0)) > 10
        THEN 'VALORES DIVERGENTES'
        ELSE 'VALORES IGUAIS'
    END AS aud_status_calc_sped_st,
    b.ressarc_icms_proprio_considerado AS RESSARC_ICMS_Proprio_Considerado,
    b.ressarc_st_considerado AS RESSARC_ST_Considerado,
    b.dif_icms_prop_considerada AS DIF_ICMS_Prop_Considerada,
    b.dif_st_considerada AS DIF_ST_Considerada
FROM base_final b
ORDER BY
    b.comp_efd,
    b.dt_emissao_saida,
    b.chave_saida,
    b.num_item_saida,
    b.dt_ultima_entrada,
    b.chave_nfe_ultima_entrada,
    b.num_item_ult_entr;
