/*
===============================================================================
MÓDULO 06 - SCORE DOS CANDIDATOS DE VÍNCULO
-------------------------------------------------------------------------------
Objetivo
- Comparar cada item de saída com todos os itens possíveis da nota de entrada.
- Atribuir score e penalidades para escolher o candidato mais aderente.

Granularidade
- 1 linha por combinação:
    chave_saida + num_item_saida + cod_item_saida + item_candidato_entrada

Score considerado
- cod_item
- número do item documental
- GTIN/código de barras
- NCM
- CEST
- NCM + CEST
- descrição normalizada
- compatibilidade de quantidade
- existência do item no XML

Penalidades
- conflito de NCM
- conflito de CEST

Importante
- Este módulo é excelente para auditoria, mas, arquiteturalmente, score e ranking
  idealmente deveriam migrar para uma camada externa ao Oracle.
===============================================================================
*/

WITH
-- 1) Base mínima de saídas com C176
PARAMETROS AS (
    SELECT
        :CNPJ AS cnpj_filtro,
        NVL(TO_DATE(:data_inicial, 'DD/MM/YYYY'), TO_DATE('01/01/1900', 'DD/MM/YYYY')) AS dt_ini_filtro,
        NVL(TO_DATE(:data_final, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_fim_filtro,
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte
    FROM dual
),
ARQUIVOS_ULTIMA_EFD_PERIODO AS (
    SELECT *
    FROM (
        SELECT
            r.id AS reg_0000_id,
            r.cnpj,
            r.cod_fin AS cod_fin_efd,
            r.dt_ini,
            r.dt_fin,
            r.data_entrega,
            ROW_NUMBER() OVER (
                PARTITION BY r.cnpj, r.dt_ini, NVL(r.dt_fin, r.dt_ini)
                ORDER BY r.data_entrega DESC, r.id DESC
            ) AS rn
        FROM sped.reg_0000 r
        JOIN PARAMETROS p
          ON r.cnpj = p.cnpj_filtro
        WHERE r.data_entrega <= p.dt_corte
    )
    WHERE rn = 1
),
ARQUIVOS_VALIDOS AS (
    SELECT
        a.reg_0000_id,
        a.cnpj,
        a.cod_fin_efd,
        a.dt_ini,
        a.dt_fin,
        a.data_entrega
    FROM ARQUIVOS_ULTIMA_EFD_PERIODO a
    JOIN PARAMETROS p
      ON a.dt_ini BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
),
SAIDAS_RESSARCIMENTO AS (
    SELECT
        arq.reg_0000_id,
        c100.chv_nfe AS chave_saida,
        c170.num_item AS num_item_saida,
        c170.cod_item,
        c170.descr_compl AS descricao_item,
        c170.qtd AS qtd_saida_sped,
        c176.chave_nfe_ult AS chave_nfe_ultima_entrada
    FROM sped.reg_c176 c176
    JOIN ARQUIVOS_VALIDOS arq
      ON c176.reg_0000_id = arq.reg_0000_id
    JOIN sped.reg_c100 c100
      ON c176.reg_c100_id = c100.id
     AND c100.reg_0000_id = arq.reg_0000_id
    JOIN sped.reg_c170 c170
      ON c176.reg_c170_id = c170.id
     AND c170.reg_0000_id = arq.reg_0000_id
),
PRODUTOS_SAIDA AS (
    SELECT
        r0200.reg_0000_id,
        r0200.cod_item,
        MAX(r0200.cod_barra) AS cod_barra,
        MAX(r0200.descr_item) AS descr_item,
        MAX(r0200.cod_ncm) AS cod_ncm,
        MAX(r0200.cest) AS cest
    FROM sped.reg_0200 r0200
    JOIN ARQUIVOS_VALIDOS arq
      ON r0200.reg_0000_id = arq.reg_0000_id
    GROUP BY r0200.reg_0000_id, r0200.cod_item
),
PRODUTOS_ULTIMA_EFD AS (
    SELECT
        r0200.reg_0000_id,
        r0200.cod_item,
        MAX(r0200.cod_barra) AS cod_barra,
        MAX(r0200.descr_item) AS descr_item,
        MAX(r0200.cod_ncm) AS cod_ncm,
        MAX(r0200.cest) AS cest
    FROM sped.reg_0200 r0200
    JOIN ARQUIVOS_ULTIMA_EFD_PERIODO arq
      ON r0200.reg_0000_id = arq.reg_0000_id
    GROUP BY r0200.reg_0000_id, r0200.cod_item
),
CHAVES_ENTRADA AS (
    SELECT DISTINCT chave_nfe_ultima_entrada AS chave_acesso
    FROM SAIDAS_RESSARCIMENTO
    WHERE chave_nfe_ultima_entrada IS NOT NULL
),
XML_ENTRADA_BASE AS (
    SELECT
        nfe_ent.chave_acesso,
        nfe_ent.seq_nitem,
        nfe_ent.prod_nitem,
        COALESCE(nfe_ent.prod_nitem, nfe_ent.seq_nitem) AS item_xml_padrao,
        nfe_ent.prod_xprod AS xml_descricao_item_entrada,
        nfe_ent.prod_ncm AS xml_ncm_entrada,
        nfe_ent.prod_cest AS xml_cest_entrada,
        nfe_ent.prod_qcom AS qcom_entrada,
        nfe_ent.prod_vprod,
        nfe_ent.prod_vfrete,
        nfe_ent.prod_vseg,
        nfe_ent.prod_voutro,
        nfe_ent.prod_vdesc,
        nfe_ent.ipi_vipi,
        nfe_ent.icms_vicms AS xml_icms_vicms_total_entrada,
        nfe_ent.icms_picms AS aliq_inter_entrada,
        calc_front.it_co_rotina_calculo,
        calc_front.it_vl_icms AS vl_icms_fronteira,
        ROW_NUMBER() OVER (
            PARTITION BY nfe_ent.chave_acesso, COALESCE(nfe_ent.prod_nitem, nfe_ent.seq_nitem)
            ORDER BY NVL(nfe_ent.prod_nitem, -1) DESC, NVL(nfe_ent.seq_nitem, -1) DESC
        ) AS rn
    FROM bi.fato_nfe_detalhe nfe_ent
    JOIN CHAVES_ENTRADA ce
      ON nfe_ent.chave_acesso = ce.chave_acesso
    LEFT JOIN sitafe.sitafe_nfe_calculo_item calc_front
      ON calc_front.it_nu_chave_acesso = nfe_ent.chave_acesso
     AND calc_front.it_nu_item = COALESCE(nfe_ent.prod_nitem, nfe_ent.seq_nitem)
    WHERE nfe_ent.co_iddest = 2
      AND nfe_ent.co_uf_dest = 'RO'
      AND nfe_ent.co_uf_emit <> 'RO'
),
XML_ENTRADA AS (
    SELECT *
    FROM XML_ENTRADA_BASE
    WHERE rn = 1
),
ITENS_ENTRADA_SPED_BASE AS (
    SELECT
        c100_in.chv_nfe,
        c100_in.reg_0000_id,
        c170_in.cod_item,
        c170_in.num_item AS num_item_ult_entr_candidato,
        c170_in.descr_compl AS descr_compl_entrada_sped,
        c170_in.qtd AS qtd_item_entrada_sped,
        p_in.cod_barra AS cod_barra_entrada_sped,
        p_in.descr_item AS descr_item_entrada_sped,
        p_in.cod_ncm AS cod_ncm_entrada_sped,
        p_in.cest AS cest_entrada_sped
    FROM CHAVES_ENTRADA ce
    JOIN sped.reg_c100 c100_in
      ON c100_in.chv_nfe = ce.chave_acesso
    JOIN ARQUIVOS_ULTIMA_EFD_PERIODO arq_ref
      ON c100_in.reg_0000_id = arq_ref.reg_0000_id
    JOIN sped.reg_c170 c170_in
      ON c170_in.reg_c100_id = c100_in.id
     AND c170_in.reg_0000_id = c100_in.reg_0000_id
    LEFT JOIN PRODUTOS_ULTIMA_EFD p_in
      ON p_in.reg_0000_id = c170_in.reg_0000_id
     AND p_in.cod_item = c170_in.cod_item
),
CANDIDATOS_BASE AS (
    SELECT
        s.chave_saida,
        s.num_item_saida,
        s.cod_item AS cod_item_saida,
        s.chave_nfe_ultima_entrada,
        s.descricao_item,
        s.qtd_saida_sped,
        ps.cod_barra AS cod_barra_saida,
        ps.descr_item AS descr_item_saida_0200,
        ps.cod_ncm AS cod_ncm_saida,
        ps.cest AS cest_saida,
        i.cod_item AS cod_item_entrada_candidato,
        i.num_item_ult_entr_candidato AS num_item_ult_entr,
        i.descr_compl_entrada_sped,
        i.qtd_item_entrada_sped,
        i.cod_barra_entrada_sped,
        i.descr_item_entrada_sped,
        i.cod_ncm_entrada_sped,
        i.cest_entrada_sped,
        xe.seq_nitem AS seq_nitem_entrada,
        xe.prod_nitem AS prod_nitem_entrada,
        xe.item_xml_padrao AS item_xml_entrada_padrao,
        xe.xml_descricao_item_entrada,
        xe.xml_ncm_entrada,
        xe.xml_cest_entrada,
        xe.qcom_entrada,
        xe.it_co_rotina_calculo,
        xe.vl_icms_fronteira,
        COALESCE(NULLIF(TRIM(xe.xml_ncm_entrada), ''), NULLIF(TRIM(i.cod_ncm_entrada_sped), '')) AS ncm_prioritario_candidato,
        COALESCE(NULLIF(TRIM(xe.xml_cest_entrada), ''), NULLIF(TRIM(i.cest_entrada_sped), '')) AS cest_prioritario_candidato,
        NULLIF(
            TRIM(REGEXP_REPLACE(REGEXP_REPLACE(
                TRANSLATE(UPPER(COALESCE(xe.xml_descricao_item_entrada, i.descr_compl_entrada_sped, i.descr_item_entrada_sped, '')),
                          'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ','AAAAAEEEEIIIIOOOOOUUUUCN'),
                '[^A-Z0-9 ]', ' '), ' +', ' ')),
            ''
        ) AS desc_candidato_norm,
        NULLIF(
            TRIM(REGEXP_REPLACE(REGEXP_REPLACE(
                TRANSLATE(UPPER(COALESCE(s.descricao_item, '')),
                          'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ','AAAAAEEEEIIIIOOOOOUUUUCN'),
                '[^A-Z0-9 ]', ' '), ' +', ' ')),
            ''
        ) AS desc_saida_sped_norm,
        NULLIF(
            TRIM(REGEXP_REPLACE(REGEXP_REPLACE(
                TRANSLATE(UPPER(COALESCE(ps.descr_item, '')),
                          'ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ','AAAAAEEEEIIIIOOOOOUUUUCN'),
                '[^A-Z0-9 ]', ' '), ' +', ' ')),
            ''
        ) AS desc_saida_0200_norm,
        CASE WHEN i.cod_item = s.cod_item THEN 1 ELSE 0 END AS ind_match_cod_item,
        CASE
            WHEN TRIM(TO_CHAR(i.num_item_ult_entr_candidato)) = TRIM(TO_CHAR(COALESCE(xe.prod_nitem, xe.seq_nitem, xe.item_xml_padrao)))
             AND COALESCE(xe.prod_nitem, xe.seq_nitem, xe.item_xml_padrao) IS NOT NULL
            THEN 1 ELSE 0 END AS ind_match_num_item_doc,
        CASE
            WHEN REGEXP_LIKE(TRIM(COALESCE(i.cod_barra_entrada_sped, '')), '^[0-9]{8,14}$')
             AND NOT REGEXP_LIKE(TRIM(i.cod_barra_entrada_sped), '^0+$')
             AND REGEXP_LIKE(TRIM(COALESCE(ps.cod_barra, '')), '^[0-9]{8,14}$')
             AND NOT REGEXP_LIKE(TRIM(ps.cod_barra), '^0+$')
             AND TRIM(i.cod_barra_entrada_sped) = TRIM(ps.cod_barra)
            THEN 1 ELSE 0 END AS ind_match_cod_barra,
        CASE
            WHEN ps.cod_ncm IS NOT NULL
             AND COALESCE(xe.xml_ncm_entrada, i.cod_ncm_entrada_sped) IS NOT NULL
             AND TRIM(COALESCE(xe.xml_ncm_entrada, i.cod_ncm_entrada_sped)) <> TRIM(ps.cod_ncm)
            THEN 1 ELSE 0 END AS ind_conflito_ncm,
        CASE
            WHEN ps.cest IS NOT NULL
             AND COALESCE(xe.xml_cest_entrada, i.cest_entrada_sped) IS NOT NULL
             AND TRIM(COALESCE(xe.xml_cest_entrada, i.cest_entrada_sped)) <> TRIM(ps.cest)
            THEN 1 ELSE 0 END AS ind_conflito_cest
    FROM SAIDAS_RESSARCIMENTO s
    LEFT JOIN PRODUTOS_SAIDA ps
      ON ps.reg_0000_id = s.reg_0000_id
     AND ps.cod_item = s.cod_item
    JOIN ITENS_ENTRADA_SPED_BASE i
      ON i.chv_nfe = s.chave_nfe_ultima_entrada
    LEFT JOIN XML_ENTRADA xe
      ON xe.chave_acesso = i.chv_nfe
     AND xe.item_xml_padrao = i.num_item_ult_entr_candidato
),
CANDIDATOS_SCORE AS (
    SELECT
        r.*,
        CASE WHEN r.ind_match_cod_item = 1 THEN 35 ELSE 0 END AS score_cod_item,
        CASE WHEN r.ind_match_num_item_doc = 1 THEN 8 ELSE 0 END AS score_num_item_doc,
        CASE WHEN r.ind_match_cod_barra = 1 THEN 25 ELSE 0 END AS score_cod_barra,
        CASE
            WHEN TRIM(COALESCE(r.xml_ncm_entrada, r.cod_ncm_entrada_sped)) = TRIM(r.cod_ncm_saida)
             AND r.cod_ncm_saida IS NOT NULL
            THEN 20 ELSE 0 END AS score_ncm,
        CASE
            WHEN TRIM(COALESCE(r.xml_cest_entrada, r.cest_entrada_sped)) = TRIM(r.cest_saida)
             AND r.cest_saida IS NOT NULL
            THEN 15 ELSE 0 END AS score_cest,
        CASE
            WHEN TRIM(COALESCE(r.xml_ncm_entrada, r.cod_ncm_entrada_sped)) = TRIM(r.cod_ncm_saida)
             AND TRIM(COALESCE(r.xml_cest_entrada, r.cest_entrada_sped)) = TRIM(r.cest_saida)
             AND r.cod_ncm_saida IS NOT NULL
             AND r.cest_saida IS NOT NULL
            THEN 10 ELSE 0 END AS score_ncm_cest_combo,
        CASE
            WHEN r.desc_candidato_norm IS NOT NULL
             AND r.desc_saida_sped_norm IS NOT NULL
             AND r.desc_candidato_norm = r.desc_saida_sped_norm
            THEN 12
            WHEN r.desc_candidato_norm IS NOT NULL
             AND r.desc_saida_0200_norm IS NOT NULL
             AND r.desc_candidato_norm = r.desc_saida_0200_norm
            THEN 10
            WHEN r.desc_candidato_norm IS NOT NULL
             AND r.desc_saida_sped_norm IS NOT NULL
             AND LENGTH(r.desc_candidato_norm) >= 8
             AND LENGTH(r.desc_saida_sped_norm) >= 8
             AND (r.desc_candidato_norm LIKE '%' || r.desc_saida_sped_norm || '%'
               OR r.desc_saida_sped_norm LIKE '%' || r.desc_candidato_norm || '%')
            THEN 6
            WHEN r.desc_candidato_norm IS NOT NULL
             AND r.desc_saida_0200_norm IS NOT NULL
             AND LENGTH(r.desc_candidato_norm) >= 8
             AND LENGTH(r.desc_saida_0200_norm) >= 8
             AND (r.desc_candidato_norm LIKE '%' || r.desc_saida_0200_norm || '%'
               OR r.desc_saida_0200_norm LIKE '%' || r.desc_candidato_norm || '%')
            THEN 4
            ELSE 0 END AS score_descricao,
        CASE
            WHEN COALESCE(r.qcom_entrada, r.qtd_item_entrada_sped) = r.qtd_saida_sped
             AND NVL(r.qtd_saida_sped, 0) > 0
            THEN 5
            WHEN NVL(r.qtd_saida_sped, 0) > 0
             AND ABS(NVL(COALESCE(r.qcom_entrada, r.qtd_item_entrada_sped), 0) - NVL(r.qtd_saida_sped, 0)) / r.qtd_saida_sped <= 0.20
            THEN 2
            ELSE 0 END AS score_quantidade,
        CASE WHEN r.item_xml_entrada_padrao IS NOT NULL THEN 3 ELSE 0 END AS score_xml,
        CASE WHEN r.ind_conflito_ncm = 1 THEN 20 ELSE 0 END AS penalidade_ncm,
        CASE WHEN r.ind_conflito_cest = 1 THEN 15 ELSE 0 END AS penalidade_cest
    FROM CANDIDATOS_BASE r
),
CANDIDATOS_FINAL AS (
    SELECT
        c.*,
        (CASE WHEN c.ind_conflito_ncm = 1 THEN 20 ELSE 0 END +
         CASE WHEN c.ind_conflito_cest = 1 THEN 15 ELSE 0 END) AS penalidade_total,
        GREATEST(
            0,
            NVL(c.score_cod_item, 0)
          + NVL(c.score_num_item_doc, 0)
          + NVL(c.score_cod_barra, 0)
          + NVL(c.score_ncm, 0)
          + NVL(c.score_cest, 0)
          + NVL(c.score_ncm_cest_combo, 0)
          + NVL(c.score_descricao, 0)
          + NVL(c.score_quantidade, 0)
          + NVL(c.score_xml, 0)
          - (CASE WHEN c.ind_conflito_ncm = 1 THEN 20 ELSE 0 END +
             CASE WHEN c.ind_conflito_cest = 1 THEN 15 ELSE 0 END)
        ) AS score_vinculo_entrada,
        ABS(NVL(COALESCE(c.qcom_entrada, c.qtd_item_entrada_sped), 0) - NVL(c.qtd_saida_sped, 0)) AS diff_qtd_vinculo
    FROM CANDIDATOS_SCORE c
)
SELECT *
FROM CANDIDATOS_FINAL
ORDER BY chave_saida, num_item_saida, score_vinculo_entrada DESC, diff_qtd_vinculo ASC, num_item_ult_entr ASC;
