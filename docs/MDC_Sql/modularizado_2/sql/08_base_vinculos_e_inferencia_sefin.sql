/*
===============================================================================
MÓDULO 08 - BASE DE VÍNCULOS + INFERÊNCIA SEFIN
-------------------------------------------------------------------------------
Objetivo
- Unir a saída, o item escolhido da entrada, XML de saída, XML/Fronteira da entrada
  e a parametrização fiscal inferida por NCM/CEST e vigência.

Granularidade
- 1 linha por item de saída vinculado a um item de entrada.

Função analítica
- Este módulo separa o problema do "qual item é?" do problema "qual regra fiscal
  provavelmente se aplica a esse item?".
===============================================================================
*/

WITH
saidas_ressarcimento AS (
    SELECT * FROM saidas_ressarcimento_c176
),
produtos_saida AS (
    SELECT * FROM produtos_saida_0200
),
xml_saida AS (
    SELECT * FROM xml_saida
),
vinculo_entrada_escolhido AS (
    SELECT * FROM vinculo_entrada_escolhido
),
base_vinculos AS (
    SELECT
        s.comp_efd,
        s.cod_fin_efd,
        s.reg_0000_id,
        s.chave_saida,
        s.num_nf_saida,
        CASE
            WHEN s.dt_doc IS NOT NULL AND REGEXP_LIKE(s.dt_doc, '^[0-9]{8}$')
            THEN TO_DATE(s.dt_doc, 'DDMMYYYY')
            ELSE NULL
        END AS dt_emissao_saida,
        s.num_item_saida,
        s.cod_item,
        ps.cod_barra,
        ps.descr_item,
        ps.cod_ncm,
        ps.cest,
        s.descricao_item,
        s.qtd_saida_sped,
        s.vl_total_item_saida,
        s.vl_icms,
        s.cod_mot_res,
        s.chave_nfe_ultima_entrada,
        ve.cod_item_entrada_candidato,
        ve.ind_match_cod_item,
        ve.ind_match_num_item_doc,
        ve.existe_match_cod_item,
        ve.regra_vinculo_entrada,
        ve.num_item_ult_entr,
        CASE
            WHEN s.dt_ult_e IS NOT NULL AND REGEXP_LIKE(s.dt_ult_e, '^[0-9]{8}$')
            THEN TO_DATE(s.dt_ult_e, 'DDMMYYYY')
            ELSE NULL
        END AS dt_ultima_entrada,
        s.vl_unit_bc_st_entrada,
        s.vl_unit_icms_proprio_entrada,
        s.vl_unit_ressarcimento_st,
        xs.seq_nitem AS seq_nitem_saida,
        xs.prod_nitem AS prod_nitem_saida,
        xs.item_xml_padrao AS item_xml_saida_padrao,
        xs.qcom_saida,
        ve.seq_nitem_entrada,
        ve.prod_nitem_entrada,
        ve.item_xml_entrada_padrao,
        ve.xml_descricao_item_entrada,
        ve.xml_ncm_entrada,
        ve.xml_cest_entrada,
        ve.qcom_entrada,
        ve.prod_vprod,
        ve.prod_vfrete,
        ve.prod_vseg,
        ve.prod_voutro,
        ve.prod_vdesc,
        ve.ipi_vipi,
        ve.xml_icms_vicms_total_entrada,
        ve.aliq_inter_entrada,
        ve.it_co_rotina_calculo,
        ve.vl_icms_fronteira,
        ve.ind_match_cod_barra,
        ve.ind_conflito_ncm,
        ve.ind_conflito_cest,
        ve.score_cod_item,
        ve.score_num_item_doc,
        ve.score_cod_barra,
        ve.score_ncm,
        ve.score_cest,
        ve.score_ncm_cest_combo,
        ve.score_descricao,
        ve.score_quantidade,
        ve.score_xml,
        ve.penalidade_ncm,
        ve.penalidade_cest,
        ve.penalidade_total,
        ve.score_vinculo_entrada,
        ve.score_segundo_colocado,
        ve.gap_top2,
        ve.status_gap_vinculo,
        ve.diff_qtd_vinculo,
        COALESCE(NULLIF(TRIM(ve.ncm_prioritario_candidato), ''), NULLIF(TRIM(ps.cod_ncm), '')) AS ncm_prioritario_sefin,
        COALESCE(NULLIF(TRIM(ve.cest_prioritario_candidato), ''), NULLIF(TRIM(ps.cest), '')) AS cest_prioritario_sefin,
        CASE
            WHEN NVL(ve.qcom_entrada, 0) <> 0
            THEN ve.xml_icms_vicms_total_entrada / ve.qcom_entrada
            ELSE NULL
        END AS xml_vl_unit_icms_proprio_entrada,
        CASE
            WHEN UPPER(TRIM(ve.it_co_rotina_calculo)) = 'ST'
             AND NVL(ve.qcom_entrada, 0) <> 0
            THEN ve.vl_icms_fronteira / ve.qcom_entrada
            ELSE NULL
        END AS fronteira_vl_unit_ressarcimento_st
    FROM saidas_ressarcimento s
    LEFT JOIN produtos_saida ps
      ON s.reg_0000_id = ps.reg_0000_id
     AND s.cod_item = ps.cod_item
    LEFT JOIN vinculo_entrada_escolhido ve
      ON s.chave_saida = ve.chave_saida
     AND s.num_item_saida = ve.num_item_saida
     AND s.cod_item = ve.cod_item_saida
     AND s.chave_nfe_ultima_entrada = ve.chave_nfe_ultima_entrada
    LEFT JOIN xml_saida xs
      ON s.chave_saida = xs.chave_acesso
     AND s.num_item_saida = xs.item_xml_padrao
),
aux_vigencias AS (
    SELECT
        aux.it_co_sefin,
        CASE
            WHEN REGEXP_LIKE(TRIM(TO_CHAR(aux.it_da_inicio)), '^[0-9]{8}$')
            THEN TO_DATE(TRIM(TO_CHAR(aux.it_da_inicio)), 'YYYYMMDD')
        END AS dt_inicio_vig,
        CASE
            WHEN aux.it_da_final IS NULL THEN NULL
            WHEN REGEXP_LIKE(TRIM(TO_CHAR(aux.it_da_final)), '^[0-9]{8}$')
            THEN TO_DATE(TRIM(TO_CHAR(aux.it_da_final)), 'YYYYMMDD')
        END AS dt_final_vig,
        aux.it_pc_interna,
        aux.it_in_st,
        aux.it_pc_mva,
        aux.it_in_mva_ajustado
    FROM sitafe.sitafe_produto_sefin_aux aux
),
sefin_inferido_vigente AS (
    SELECT
        b.chave_saida,
        b.num_item_saida,
        b.cod_item,
        b.chave_nfe_ultima_entrada,
        b.num_item_ult_entr,
        c.it_co_sefin AS co_sefin_inferido,
        v.it_pc_interna AS aliq_interna_inferida,
        v.it_in_st AS st_inferido,
        v.it_pc_mva AS mva_inferido,
        v.it_in_mva_ajustado AS mva_ajustado_inferido,
        ROW_NUMBER() OVER (
            PARTITION BY b.chave_saida, b.num_item_saida, b.cod_item, b.chave_nfe_ultima_entrada, NVL(b.num_item_ult_entr, 0)
            ORDER BY v.dt_inicio_vig DESC, v.dt_final_vig DESC NULLS LAST, c.it_co_sefin DESC
        ) AS rn
    FROM base_vinculos b
    JOIN sitafe.sitafe_cest_ncm c
      ON TRIM(b.ncm_prioritario_sefin) = TRIM(c.it_nu_ncm)
     AND TRIM(b.cest_prioritario_sefin) = TRIM(c.it_nu_cest)
     AND NVL(c.it_in_status, 'A') <> 'C'
    JOIN aux_vigencias v
      ON v.it_co_sefin = c.it_co_sefin
     AND v.dt_inicio_vig IS NOT NULL
     AND b.dt_ultima_entrada IS NOT NULL
     AND b.dt_ultima_entrada >= v.dt_inicio_vig
     AND (v.dt_final_vig IS NULL OR b.dt_ultima_entrada <= v.dt_final_vig)
)
SELECT
    b.*,
    s.co_sefin_inferido,
    s.aliq_interna_inferida,
    s.st_inferido,
    s.mva_inferido,
    s.mva_ajustado_inferido
FROM base_vinculos b
LEFT JOIN sefin_inferido_vigente s
  ON b.chave_saida = s.chave_saida
 AND b.num_item_saida = s.num_item_saida
 AND b.cod_item = s.cod_item
 AND b.chave_nfe_ultima_entrada = s.chave_nfe_ultima_entrada
 AND NVL(b.num_item_ult_entr, 0) = NVL(s.num_item_ult_entr, 0)
 AND s.rn = 1;
