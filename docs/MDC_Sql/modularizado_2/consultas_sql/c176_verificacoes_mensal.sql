/*
===============================================================================
SCRIPT: RELATÓRIO MENSAL CONSOLIDADO DE RESSARCIMENTO ICMS-ST
-------------------------------------------------------------------------------
Objetivo:
- consolidar mensalmente, por período EFD, os valores considerados de
  ressarcimento;
- comparar o valor considerado com:
  1) o valor declarado no C176
  2) o valor ajustado no E111

Blocos do relatório final:
A) MODELO TÉCNICO CONSIDERADO
   - RESSARC_ICMS_PROPRIO_CONSIDERADO
   - RESSARC_ST_CONSIDERADO

B) DECLARADO NO C176
   - ressarcimento crédito próprio
   - ressarcimento ST retido
   - quantidade de itens analisados

C) AJUSTADO NO E111
   - crédito próprio
   - ST retido
   - códigos adicionais de exibição

Regras principais:
1) usa sempre a última EFD do período;
2) usa a chave da última entrada informada no C176;
3) tenta vincular primeiro por COD_ITEM;
4) se não houver COD_ITEM igual na entrada, usa fallback pelo melhor score:
   - Existência no XML (1000)
   - Descrição idêntica na nota (800)
   - Descrição idêntica no cadastro (700)
   - Quantidade exata (300)
   - GTIN/cód barras idêntico (XML prod_cean/prod_ceantrib ou SPED) (300)
   - NCM idêntico (300)
   - CEST idêntico (300)
5) consome a quantidade da entrada mais antiga para a mais nova;
6) RESSARC_ICMS_PROPRIO_CONSIDERADO = valor com base na nota fiscal;
7) RESSARC_ST_CONSIDERADO:
   - usa Fronteira se encontrada e rotina = ST
   - senão usa CALC_VL_RESSARCIMENTO_ST

Parâmetros esperados:
- :CNPJ
- :data_inicial
- :data_final
- :data_limite_processamento
===============================================================================
*/
WITH
/* ============================================================================
   1) PARÂMETROS
   ============================================================================ */
PARAMETROS AS (
    SELECT
        :CNPJ AS cnpj_filtro,
        NVL(
            TO_DATE(:data_inicial, 'DD/MM/YYYY'),
            TO_DATE('01/01/1900', 'DD/MM/YYYY')
        ) AS dt_ini_filtro,
        NVL(
            TO_DATE(:data_final, 'DD/MM/YYYY'),
            TRUNC(SYSDATE)
        ) AS dt_fim_filtro,
        NVL(
            TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'),
            TRUNC(SYSDATE)
        ) AS dt_corte
    FROM dual
),

/* ============================================================================
   2) ÚLTIMA EFD DISPONÍVEL POR PERÍODO
   ============================================================================ */
ARQUIVOS_ULTIMA_EFD_PERIODO AS (
    SELECT
        reg_0000_id,
        cnpj,
        cod_fin_efd,
        dt_ini,
        dt_fin,
        data_entrega
    FROM (
        SELECT
            r.id AS reg_0000_id,
            r.cnpj,
            r.cod_fin AS cod_fin_efd,
            r.dt_ini,
            r.dt_fin,
            r.data_entrega,
            ROW_NUMBER() OVER (
                PARTITION BY
                    r.cnpj,
                    r.dt_ini,
                    NVL(r.dt_fin, r.dt_ini)
                ORDER BY
                    r.data_entrega DESC,
                    r.id DESC
            ) AS rn
        FROM sped.reg_0000 r
        JOIN PARAMETROS p
          ON r.cnpj = p.cnpj_filtro
        WHERE r.data_entrega <= p.dt_corte
    )
    WHERE rn = 1
),

/* ============================================================================
   3) ARQUIVOS DA JANELA CONSULTADA
   ============================================================================ */
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

/* ============================================================================
   4) SAÍDAS COM RESSARCIMENTO (C176)
   ============================================================================ */
SAIDAS_RESSARCIMENTO AS (
    SELECT
        arq.reg_0000_id,
        arq.dt_ini AS comp_efd,
        arq.cod_fin_efd,
        c100.chv_nfe AS chave_saida,
        c100.num_doc AS num_nf_saida,
        c100.dt_doc,
        c170.num_item AS num_item_saida,
        c170.cod_item,
        c170.descr_compl AS descricao_item,
        c170.qtd AS qtd_saida_sped,
        c170.vl_item AS vl_total_item_saida,
        c170.vl_icms,
        c176.cod_mot_res,
        c176.chave_nfe_ult AS chave_nfe_ultima_entrada,
        c176.dt_ult_e,
        c176.vl_unit_ult_e AS vl_unit_bc_st_entrada,
        c176.vl_unit_icms_ult_e AS vl_unit_icms_proprio_entrada,
        c176.vl_unit_res AS vl_unit_ressarcimento_st
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

/* ============================================================================
   5) PRODUTOS DAS EFDs DE SAÍDA
   ============================================================================ */
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
    GROUP BY
        r0200.reg_0000_id,
        r0200.cod_item
),

/* ============================================================================
   6) PRODUTOS DE TODAS AS ÚLTIMAS EFDs
   ============================================================================ */
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
    GROUP BY
        r0200.reg_0000_id,
        r0200.cod_item
),

/* ============================================================================
   7) CHAVES DE ENTRADA E SAÍDA
   ============================================================================ */
CHAVES_ENTRADA AS (
    SELECT DISTINCT
        s.chave_nfe_ultima_entrada AS chave_acesso
    FROM SAIDAS_RESSARCIMENTO s
    WHERE s.chave_nfe_ultima_entrada IS NOT NULL
),

CHAVES_SAIDA AS (
    SELECT DISTINCT
        s.chave_saida AS chave_acesso
    FROM SAIDAS_RESSARCIMENTO s
    WHERE s.chave_saida IS NOT NULL
),

/* ============================================================================
   8) XML DE ENTRADA
   ============================================================================ */
XML_ENTRADA_BASE AS (
    SELECT
        nfe_ent.chave_acesso,
        nfe_ent.seq_nitem,
        nfe_ent.prod_nitem,
        COALESCE(nfe_ent.prod_nitem, nfe_ent.seq_nitem) AS item_xml_padrao,
        nfe_ent.prod_xprod AS xml_descricao_item_entrada,
        nfe_ent.prod_cean AS xml_cean_entrada,
        nfe_ent.prod_ceantrib AS xml_ceantrib_entrada,
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
            PARTITION BY
                nfe_ent.chave_acesso,
                COALESCE(nfe_ent.prod_nitem, nfe_ent.seq_nitem)
            ORDER BY
                NVL(nfe_ent.prod_nitem, -1) DESC,
                NVL(nfe_ent.seq_nitem, -1) DESC
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
    SELECT
        chave_acesso,
        seq_nitem,
        prod_nitem,
        item_xml_padrao,
        xml_descricao_item_entrada,
        xml_cean_entrada,
        xml_ceantrib_entrada,
        xml_ncm_entrada,
        xml_cest_entrada,
        qcom_entrada,
        prod_vprod,
        prod_vfrete,
        prod_vseg,
        prod_voutro,
        prod_vdesc,
        ipi_vipi,
        xml_icms_vicms_total_entrada,
        aliq_inter_entrada,
        it_co_rotina_calculo,
        vl_icms_fronteira
    FROM XML_ENTRADA_BASE
    WHERE rn = 1
),

/* ============================================================================
   9) XML DE SAÍDA
   ============================================================================ */
XML_SAIDA_BASE AS (
    SELECT
        nfe_sai.chave_acesso,
        nfe_sai.seq_nitem,
        nfe_sai.prod_nitem,
        COALESCE(nfe_sai.prod_nitem, nfe_sai.seq_nitem) AS item_xml_padrao,
        nfe_sai.prod_qcom AS qcom_saida,
        ROW_NUMBER() OVER (
            PARTITION BY
                nfe_sai.chave_acesso,
                COALESCE(nfe_sai.prod_nitem, nfe_sai.seq_nitem)
            ORDER BY
                NVL(nfe_sai.prod_nitem, -1) DESC,
                NVL(nfe_sai.seq_nitem, -1) DESC
        ) AS rn
    FROM bi.fato_nfe_detalhe nfe_sai
    JOIN CHAVES_SAIDA cs
      ON nfe_sai.chave_acesso = cs.chave_acesso
),

XML_SAIDA AS (
    SELECT
        chave_acesso,
        seq_nitem,
        prod_nitem,
        item_xml_padrao,
        qcom_saida
    FROM XML_SAIDA_BASE
    WHERE rn = 1
),

/* ============================================================================
   10) TODOS OS ITENS POSSÍVEIS DA NOTA DE ENTRADA
   ============================================================================ */
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

/* ============================================================================
   11) CANDIDATOS DE VÍNCULO - BASE (COM GTIN DO XML INCLUSO)
   ============================================================================ */
CANDIDATOS_VINCULO_ENTRADA_BASE AS (
    SELECT
        s.chave_saida,
        s.num_item_saida,
        s.cod_item AS cod_item_saida,
        s.chave_nfe_ultima_entrada,

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
        xe.xml_cean_entrada,
        xe.xml_ceantrib_entrada,
        xe.xml_ncm_entrada,
        xe.xml_cest_entrada,
        xe.qcom_entrada,
        xe.prod_vprod,
        xe.prod_vfrete,
        xe.prod_vseg,
        xe.prod_voutro,
        xe.prod_vdesc,
        xe.ipi_vipi,
        xe.xml_icms_vicms_total_entrada,
        xe.aliq_inter_entrada,
        xe.it_co_rotina_calculo,
        xe.vl_icms_fronteira,

        COALESCE(
            NULLIF(TRIM(xe.xml_ncm_entrada), ''),
            NULLIF(TRIM(i.cod_ncm_entrada_sped), '')
        ) AS ncm_prioritario_candidato,

        COALESCE(
            NULLIF(TRIM(xe.xml_cest_entrada), ''),
            NULLIF(TRIM(i.cest_entrada_sped), '')
        ) AS cest_prioritario_candidato,

        CASE
            WHEN i.cod_item = s.cod_item THEN 1
            ELSE 0
        END AS ind_match_cod_item,

        (
            /* EXISTÊNCIA NO XML */
            CASE
                WHEN xe.item_xml_padrao IS NOT NULL THEN 1000
                ELSE 0
            END
            +
            /* GTIN / CODIGO DE BARRAS IDÊNTICO (XML ou SPED) */
            CASE
                WHEN (
                         TRIM(xe.xml_cean_entrada) = TRIM(ps.cod_barra)
                      OR TRIM(xe.xml_ceantrib_entrada) = TRIM(ps.cod_barra)
                      OR TRIM(i.cod_barra_entrada_sped) = TRIM(ps.cod_barra)
                     )
                 AND ps.cod_barra IS NOT NULL
                 AND UPPER(TRIM(ps.cod_barra)) NOT IN ('SEM GTIN', 'NT')
                THEN 300
                ELSE 0
            END
            +
            /* NCM IDÊNTICO */
            CASE
                WHEN TRIM(COALESCE(xe.xml_ncm_entrada, i.cod_ncm_entrada_sped)) = TRIM(ps.cod_ncm)
                 AND ps.cod_ncm IS NOT NULL
                THEN 300
                ELSE 0
            END
            +
            /* CEST IDÊNTICO */
            CASE
                WHEN TRIM(COALESCE(xe.xml_cest_entrada, i.cest_entrada_sped)) = TRIM(ps.cest)
                 AND ps.cest IS NOT NULL
                THEN 300
                ELSE 0
            END
            +
            /* DESCRIÇÃO IDÊNTICA NA NOTA */
            CASE
                WHEN UPPER(TRIM(COALESCE(
                        xe.xml_descricao_item_entrada,
                        i.descr_compl_entrada_sped,
                        i.descr_item_entrada_sped
                     ))) = UPPER(TRIM(s.descricao_item))
                 AND s.descricao_item IS NOT NULL
                THEN 800
                ELSE 0
            END
            +
            /* DESCRIÇÃO IDÊNTICA NO CADASTRO */
            CASE
                WHEN UPPER(TRIM(COALESCE(
                        xe.xml_descricao_item_entrada,
                        i.descr_compl_entrada_sped,
                        i.descr_item_entrada_sped
                     ))) = UPPER(TRIM(ps.descr_item))
                 AND ps.descr_item IS NOT NULL
                THEN 700
                ELSE 0
            END
            +
            /* QUANTIDADE COMPATÍVEL */
            CASE
                WHEN COALESCE(xe.qcom_entrada, i.qtd_item_entrada_sped) = s.qtd_saida_sped
                 AND s.qtd_saida_sped IS NOT NULL
                THEN 300
                WHEN ABS(
                         NVL(COALESCE(xe.qcom_entrada, i.qtd_item_entrada_sped), 0) -
                         NVL(s.qtd_saida_sped, 0)
                     ) <= 1
                THEN 30
                ELSE 0
            END
        ) AS score_vinculo_entrada,

        ABS(
            NVL(COALESCE(xe.qcom_entrada, i.qtd_item_entrada_sped), 0) -
            NVL(s.qtd_saida_sped, 0)
        ) AS diff_qtd_vinculo
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

CANDIDATOS_VINCULO_ENTRADA_FLAG AS (
    SELECT
        c.*,
        MAX(c.ind_match_cod_item) OVER (
            PARTITION BY
                c.chave_saida,
                c.num_item_saida,
                c.cod_item_saida,
                c.chave_nfe_ultima_entrada
        ) AS existe_match_cod_item
    FROM CANDIDATOS_VINCULO_ENTRADA_BASE c
),

CANDIDATOS_VINCULO_ENTRADA AS (
    SELECT
        c.*,
        ROW_NUMBER() OVER (
            PARTITION BY
                c.chave_saida,
                c.num_item_saida,
                c.cod_item_saida,
                c.chave_nfe_ultima_entrada
            ORDER BY
                CASE
                    WHEN c.existe_match_cod_item = 1
                    THEN c.ind_match_cod_item
                    ELSE 1
                END DESC,
                c.score_vinculo_entrada DESC,
                c.diff_qtd_vinculo ASC,
                c.num_item_ult_entr ASC
        ) AS rn
    FROM CANDIDATOS_VINCULO_ENTRADA_FLAG c
),

VINCULO_ENTRADA_ESCOLHIDO AS (
    SELECT
        chave_saida,
        num_item_saida,
        cod_item_saida,
        chave_nfe_ultima_entrada,
        cod_item_entrada_candidato,
        num_item_ult_entr,
        descr_compl_entrada_sped,
        qtd_item_entrada_sped,
        cod_barra_entrada_sped,
        descr_item_entrada_sped,
        cod_ncm_entrada_sped,
        cest_entrada_sped,
        seq_nitem_entrada,
        prod_nitem_entrada,
        item_xml_entrada_padrao,
        xml_descricao_item_entrada,
        xml_cean_entrada,
        xml_ceantrib_entrada,
        xml_ncm_entrada,
        xml_cest_entrada,
        qcom_entrada,
        prod_vprod,
        prod_vfrete,
        prod_vseg,
        prod_voutro,
        prod_vdesc,
        ipi_vipi,
        xml_icms_vicms_total_entrada,
        aliq_inter_entrada,
        it_co_rotina_calculo,
        vl_icms_fronteira,
        ncm_prioritario_candidato,
        cest_prioritario_candidato,
        ind_match_cod_item,
        existe_match_cod_item,
        score_vinculo_entrada,
        diff_qtd_vinculo
    FROM CANDIDATOS_VINCULO_ENTRADA
    WHERE rn = 1
),

BASE_VINCULOS AS (
    SELECT
        s.comp_efd,
        s.cod_fin_efd,
        s.reg_0000_id,
        s.chave_saida,
        s.num_nf_saida,
        CASE
            WHEN s.dt_doc IS NOT NULL
             AND REGEXP_LIKE(s.dt_doc, '^[0-9]{8}$')
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
        ve.existe_match_cod_item,
        ve.num_item_ult_entr,

        CASE
            WHEN s.dt_ult_e IS NOT NULL
             AND REGEXP_LIKE(s.dt_ult_e, '^[0-9]{8}$')
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
        ve.xml_cean_entrada,
        ve.xml_ceantrib_entrada,
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
        ve.score_vinculo_entrada,
        ve.diff_qtd_vinculo,

        COALESCE(
            NULLIF(TRIM(ve.ncm_prioritario_candidato), ''),
            NULLIF(TRIM(ps.cod_ncm), '')
        ) AS ncm_prioritario_sefin,

        COALESCE(
            NULLIF(TRIM(ve.cest_prioritario_candidato), ''),
            NULLIF(TRIM(ps.cest), '')
        ) AS cest_prioritario_sefin,

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
    FROM SAIDAS_RESSARCIMENTO s
    LEFT JOIN PRODUTOS_SAIDA ps
      ON s.reg_0000_id = ps.reg_0000_id
     AND s.cod_item = ps.cod_item
    LEFT JOIN VINCULO_ENTRADA_ESCOLHIDO ve
      ON s.chave_saida = ve.chave_saida
     AND s.num_item_saida = ve.num_item_saida
     AND s.cod_item = ve.cod_item_saida
     AND s.chave_nfe_ultima_entrada = ve.chave_nfe_ultima_entrada
    LEFT JOIN XML_SAIDA xs
      ON s.chave_saida = xs.chave_acesso
     AND s.num_item_saida = xs.item_xml_padrao
),

AUX_VIGENCIAS AS (
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

SEFIN_INFERIDO_VIGENTE AS (
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
            PARTITION BY
                b.chave_saida,
                b.num_item_saida,
                b.cod_item,
                b.chave_nfe_ultima_entrada,
                NVL(b.num_item_ult_entr, 0)
            ORDER BY
                v.dt_inicio_vig DESC,
                v.dt_final_vig DESC NULLS LAST,
                c.it_co_sefin DESC
        ) AS rn
    FROM BASE_VINCULOS b
    JOIN sitafe.sitafe_cest_ncm c
      ON TRIM(b.ncm_prioritario_sefin) = TRIM(c.it_nu_ncm)
     AND TRIM(b.cest_prioritario_sefin) = TRIM(c.it_nu_cest)
     AND NVL(c.it_in_status, 'A') <> 'C'
    JOIN AUX_VIGENCIAS v
      ON v.it_co_sefin = c.it_co_sefin
     AND v.dt_inicio_vig IS NOT NULL
     AND b.dt_ultima_entrada IS NOT NULL
     AND b.dt_ultima_entrada >= v.dt_inicio_vig
     AND (v.dt_final_vig IS NULL OR b.dt_ultima_entrada <= v.dt_final_vig)
),

BASE_ENRIQUECIDA AS (
    SELECT
        b.*,
        s.co_sefin_inferido,
        s.aliq_interna_inferida,
        s.st_inferido,
        s.mva_inferido,
        s.mva_ajustado_inferido
    FROM BASE_VINCULOS b
    LEFT JOIN SEFIN_INFERIDO_VIGENTE s
      ON b.chave_saida = s.chave_saida
     AND b.num_item_saida = s.num_item_saida
     AND b.cod_item = s.cod_item
     AND b.chave_nfe_ultima_entrada = s.chave_nfe_ultima_entrada
     AND NVL(b.num_item_ult_entr, 0) = NVL(s.num_item_ult_entr, 0)
     AND s.rn = 1
),

BASE_RATEIO AS (
    SELECT
        b.*,
        SUM(NVL(b.qcom_entrada, 0)) OVER (
            PARTITION BY b.chave_saida, b.num_item_saida, b.cod_item
            ORDER BY
                CASE WHEN b.dt_ultima_entrada IS NULL THEN 1 ELSE 0 END,
                b.dt_ultima_entrada,
                b.chave_nfe_ultima_entrada,
                NVL(b.num_item_ult_entr, 0)
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS soma_qcom_entrada_acum,
        SUM(NVL(b.qcom_entrada, 0)) OVER (
            PARTITION BY b.chave_saida, b.num_item_saida, b.cod_item
        ) AS soma_qcom_entrada_total
    FROM BASE_ENRIQUECIDA b
),

BASE_QTD AS (
    SELECT
        r.*,
        CASE
            WHEN NVL(r.qcom_saida, 0) <= 0 THEN 0
            WHEN NVL(r.qcom_entrada, 0) <= 0 THEN 0
            WHEN r.soma_qcom_entrada_acum <= r.qcom_saida THEN r.qcom_entrada
            WHEN r.soma_qcom_entrada_acum - NVL(r.qcom_entrada, 0) >= r.qcom_saida THEN 0
            ELSE r.qcom_saida - (r.soma_qcom_entrada_acum - NVL(r.qcom_entrada, 0))
        END AS qtd_considerada
    FROM BASE_RATEIO r
),

BASE_CALCULOS AS (
    SELECT
        q.*,

        NVL(q.vl_unit_icms_proprio_entrada, 0) * NVL(q.qtd_considerada, 0)
            AS sped_vl_ressarc_credito_proprio,

        NVL(q.xml_vl_unit_icms_proprio_entrada, 0) * NVL(q.qtd_considerada, 0)
            AS xml_vl_ressarc_credito_proprio,

        NVL(q.vl_unit_ressarcimento_st, 0) * NVL(q.qtd_considerada, 0)
            AS vl_ressarc_st_retido,

        NVL(q.fronteira_vl_unit_ressarcimento_st, 0) * NVL(q.qtd_considerada, 0)
            AS fronteira_vl_ressarcimento_st,

        CASE
            WHEN UPPER(TRIM(q.mva_ajustado_inferido)) = 'S'
             AND q.mva_inferido IS NOT NULL
             AND q.aliq_interna_inferida IS NOT NULL
             AND q.aliq_inter_entrada IS NOT NULL
             AND (1 - (q.aliq_interna_inferida / 100)) <> 0
            THEN (
                    (
                        (1 + (q.mva_inferido / 100)) *
                        (1 - (q.aliq_inter_entrada / 100))
                    ) /
                    (1 - (q.aliq_interna_inferida / 100))
                 - 1
                 ) * 100
            ELSE q.mva_inferido
        END AS mva_ajustado_inferido_calc,

        CASE
            WHEN NVL(q.vl_icms, 0) > 0 THEN
                (NVL(q.vl_unit_ressarcimento_st, 0) * NVL(q.qtd_considerada, 0)) +
                (NVL(q.vl_unit_icms_proprio_entrada, 0) * NVL(q.qtd_considerada, 0))
            ELSE
                (NVL(q.vl_unit_ressarcimento_st, 0) * NVL(q.qtd_considerada, 0))
        END AS vr_total_ressarcimento
    FROM BASE_QTD q
),

BASE_FINAL_1 AS (
    SELECT
        c.*,

        CASE
            WHEN c.mva_ajustado_inferido_calc IS NOT NULL
            THEN (
                    NVL(c.prod_vprod, 0)
                  + NVL(c.prod_vfrete, 0)
                  + NVL(c.prod_vseg, 0)
                  + NVL(c.prod_voutro, 0)
                  + NVL(c.ipi_vipi, 0)
                  - NVL(c.prod_vdesc, 0)
                 ) * (1 + (c.mva_ajustado_inferido_calc / 100))
            ELSE NULL
        END AS bc_icms_st_calc,

        CASE
            WHEN c.qcom_entrada IS NOT NULL
             AND NVL(c.qcom_entrada, 0) <> 0
             AND c.aliq_interna_inferida IS NOT NULL
             AND c.mva_ajustado_inferido_calc IS NOT NULL
            THEN (
                    (
                        (
                            (
                                NVL(c.prod_vprod, 0)
                              + NVL(c.prod_vfrete, 0)
                              + NVL(c.prod_vseg, 0)
                              + NVL(c.prod_voutro, 0)
                              + NVL(c.ipi_vipi, 0)
                              - NVL(c.prod_vdesc, 0)
                            ) * (1 + (c.mva_ajustado_inferido_calc / 100))
                        ) * (c.aliq_interna_inferida / 100)
                    ) - NVL(c.xml_icms_vicms_total_entrada, 0)
                 ) / c.qcom_entrada
            ELSE NULL
        END AS calculado_vl_unit_ressarcimento_st
    FROM BASE_CALCULOS c
),

BASE_FINAL AS (
    SELECT
        f.*,

        CASE
            WHEN f.calculado_vl_unit_ressarcimento_st IS NOT NULL
            THEN f.calculado_vl_unit_ressarcimento_st * NVL(f.qtd_considerada, 0)
            ELSE NULL
        END AS calculado_vl_ressarcimento_st,

        f.xml_vl_ressarc_credito_proprio AS ressarc_icms_proprio_considerado,

        CASE
            WHEN f.it_co_rotina_calculo IS NULL
              OR UPPER(TRIM(f.it_co_rotina_calculo)) <> 'ST'
            THEN
                CASE
                    WHEN f.calculado_vl_unit_ressarcimento_st IS NOT NULL
                    THEN f.calculado_vl_unit_ressarcimento_st * NVL(f.qtd_considerada, 0)
                    ELSE NULL
                END
            ELSE f.fronteira_vl_ressarcimento_st
        END AS ressarc_st_considerado,

        NVL(f.xml_vl_ressarc_credito_proprio, 0)
          - NVL(f.sped_vl_ressarc_credito_proprio, 0) AS dif_icms_prop_considerada,

        NVL(
            CASE
                WHEN f.it_co_rotina_calculo IS NULL
                  OR UPPER(TRIM(f.it_co_rotina_calculo)) <> 'ST'
                THEN
                    CASE
                        WHEN f.calculado_vl_unit_ressarcimento_st IS NOT NULL
                        THEN f.calculado_vl_unit_ressarcimento_st * NVL(f.qtd_considerada, 0)
                        ELSE NULL
                    END
                ELSE f.fronteira_vl_ressarcimento_st
            END,
            0
        ) - NVL(f.vl_ressarc_st_retido, 0) AS dif_st_considerada

    FROM BASE_FINAL_1 f
),

/* ============================================================================
   20) RESUMO MENSAL DO MODELO CONSIDERADO
   ============================================================================ */
RESUMO_CONSIDERADO AS (
    SELECT
        TRUNC(b.comp_efd, 'MM') AS mes_referencia,
        COUNT(*) AS qtd_registros_modelo,
        COUNT(DISTINCT b.chave_saida) AS qtd_nfes_saida,
        COUNT(
            DISTINCT b.chave_saida || '|' || LPAD(NVL(TO_CHAR(b.num_item_saida), '0'), 6, '0')
        ) AS qtd_itens_saida_modelo,
        SUM(NVL(b.ressarc_icms_proprio_considerado, 0)) AS vl_ressarc_icms_proprio_considerado,
        SUM(NVL(b.ressarc_st_considerado, 0)) AS vl_ressarc_st_considerado,
        SUM(NVL(b.dif_icms_prop_considerada, 0)) AS vl_dif_icms_prop_considerada,
        SUM(NVL(b.dif_st_considerada, 0)) AS vl_dif_st_considerada,
        SUM(
            NVL(b.ressarc_icms_proprio_considerado, 0) +
            NVL(b.ressarc_st_considerado, 0)
        ) AS vl_total_ressarcimento_considerado
    FROM BASE_FINAL b
    GROUP BY
        TRUNC(b.comp_efd, 'MM')
),

/* ============================================================================
   21) RESUMO MENSAL DO C176 DECLARADO
   ============================================================================ */
RESUMO_C176_DECLARADO AS (
    SELECT
        TRUNC(arq.dt_ini, 'MM') AS mes_referencia,
        COUNT(c176.id) AS qtd_itens_analisados_c176,
        SUM(NVL(c170.qtd, 0) * NVL(c176.vl_unit_icms_ult_e, 0)) AS vl_ressarc_credito_proprio_c176,
        SUM(NVL(c170.qtd, 0) * NVL(c176.vl_unit_res, 0)) AS vl_ressarc_st_retido_c176
    FROM sped.reg_c176 c176
    JOIN ARQUIVOS_ULTIMA_EFD_PERIODO arq
      ON c176.reg_0000_id = arq.reg_0000_id
    JOIN sped.reg_c100 c100
      ON c176.reg_c100_id = c100.id
     AND c100.reg_0000_id = arq.reg_0000_id
    JOIN sped.reg_c170 c170
      ON c176.reg_c170_id = c170.id
     AND c170.reg_0000_id = arq.reg_0000_id
    JOIN PARAMETROS p
      ON arq.cnpj = p.cnpj_filtro
    WHERE arq.dt_ini BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
    GROUP BY
        TRUNC(arq.dt_ini, 'MM')
),

/* ============================================================================
   22) RESUMO MENSAL DOS AJUSTES E111
   ============================================================================ */
RESUMO_E111 AS (
    SELECT
        TRUNC(arq.dt_ini, 'MM') AS mes_referencia,
        SUM(
            CASE
                WHEN e111.cod_aj_apur IN ('RO020023', 'RO020049')
                THEN e111.vl_aj_apur
                ELSE 0
            END
        ) AS vl_ajuste_credito_proprio_e111,
        SUM(
            CASE
                WHEN e111.cod_aj_apur IN ('RO020022', 'RO020047')
                THEN e111.vl_aj_apur
                ELSE 0
            END
        ) AS vl_ajuste_st_retido_e111,
        SUM(
            CASE
                WHEN e111.cod_aj_apur = 'RO020050'
                THEN e111.vl_aj_apur
                ELSE 0
            END
        ) AS vl_ajuste_ro020050_e111,
        SUM(
            CASE
                WHEN e111.cod_aj_apur = 'RO020048'
                THEN e111.vl_aj_apur
                ELSE 0
            END
        ) AS vl_ajuste_ro020048_e111
    FROM ARQUIVOS_ULTIMA_EFD_PERIODO arq
    JOIN sped.reg_e111 e111
      ON e111.reg_0000_id = arq.reg_0000_id
    JOIN PARAMETROS p
      ON arq.cnpj = p.cnpj_filtro
    WHERE arq.dt_ini BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
    GROUP BY
        TRUNC(arq.dt_ini, 'MM')
),

/* ============================================================================
   23) TODOS OS MESES EXISTENTES EM QUALQUER BLOCO
   ============================================================================ */
PERIODOS_REFERENCIA AS (
    SELECT mes_referencia FROM RESUMO_CONSIDERADO
    UNION
    SELECT mes_referencia FROM RESUMO_C176_DECLARADO
    UNION
    SELECT mes_referencia FROM RESUMO_E111
)

/* ============================================================================
   24) RELATÓRIO MENSAL FINAL
   ============================================================================ */
SELECT
    (SELECT cnpj_filtro FROM PARAMETROS) AS cnpj,
    TO_CHAR(p.mes_referencia, 'MM/YYYY') AS periodo_efd,

    /* A) MODELO TÉCNICO CONSIDERADO */
    NVL(c.qtd_registros_modelo, 0) AS qtd_registros_modelo,
    NVL(c.qtd_nfes_saida, 0) AS qtd_nfes_saida,
    NVL(c.qtd_itens_saida_modelo, 0) AS qtd_itens_saida_modelo,
    NVL(c.vl_ressarc_icms_proprio_considerado, 0) AS vl_ressarc_icms_proprio_considerado,
    NVL(c.vl_ressarc_st_considerado, 0) AS vl_ressarc_st_considerado,
    NVL(c.vl_total_ressarcimento_considerado, 0) AS vl_total_ressarcimento_considerado,

    /* B) DECLARADO NO C176 */
    NVL(r.qtd_itens_analisados_c176, 0) AS qtd_itens_analisados_c176,
    NVL(r.vl_ressarc_credito_proprio_c176, 0) AS vl_ressarc_credito_proprio_c176,
    NVL(r.vl_ressarc_st_retido_c176, 0) AS vl_ressarc_st_retido_c176,
    NVL(r.vl_ressarc_credito_proprio_c176, 0) + NVL(r.vl_ressarc_st_retido_c176, 0)
        AS vl_total_ressarcimento_c176,

    /* C) AJUSTADO NO E111 */
    NVL(e.vl_ajuste_credito_proprio_e111, 0) AS vl_ajuste_credito_proprio_e111,
    NVL(e.vl_ajuste_st_retido_e111, 0) AS vl_ajuste_st_retido_e111,
    NVL(e.vl_ajuste_credito_proprio_e111, 0) + NVL(e.vl_ajuste_st_retido_e111, 0)
        AS vl_total_ajuste_e111,
    NVL(e.vl_ajuste_ro020050_e111, 0) AS vl_ajuste_ro020050_e111,
    NVL(e.vl_ajuste_ro020048_e111, 0) AS vl_ajuste_ro020048_e111,

    /* D) DIFERENÇAS CONSIDERADO x C176 */
    NVL(c.vl_ressarc_icms_proprio_considerado, 0) - NVL(r.vl_ressarc_credito_proprio_c176, 0)
        AS dif_considerado_x_c176_icms_proprio,
    NVL(c.vl_ressarc_st_considerado, 0) - NVL(r.vl_ressarc_st_retido_c176, 0)
        AS dif_considerado_x_c176_st,

    /* E) DIFERENÇAS CONSIDERADO x E111 */
    NVL(c.vl_ressarc_icms_proprio_considerado, 0) - NVL(e.vl_ajuste_credito_proprio_e111, 0)
        AS dif_considerado_x_e111_icms_proprio,
    NVL(c.vl_ressarc_st_considerado, 0) - NVL(e.vl_ajuste_st_retido_e111, 0)
        AS dif_considerado_x_e111_st,

    /* F) DIFERENÇAS C176 x E111 */
    NVL(r.vl_ressarc_credito_proprio_c176, 0) - NVL(e.vl_ajuste_credito_proprio_e111, 0)
        AS dif_c176_x_e111_icms_proprio,
    NVL(r.vl_ressarc_st_retido_c176, 0) - NVL(e.vl_ajuste_st_retido_e111, 0)
        AS dif_c176_x_e111_st,

    /* G) DIFERENÇAS CONSIDERADAS JÁ CONSOLIDADAS DO MODELO */
    NVL(c.vl_dif_icms_prop_considerada, 0) AS vl_dif_icms_prop_considerada_modelo,
    NVL(c.vl_dif_st_considerada, 0) AS vl_dif_st_considerada_modelo

FROM PERIODOS_REFERENCIA p
LEFT JOIN RESUMO_CONSIDERADO c
  ON c.mes_referencia = p.mes_referencia
LEFT JOIN RESUMO_C176_DECLARADO r
  ON r.mes_referencia = p.mes_referencia
LEFT JOIN RESUMO_E111 e
  ON e.mes_referencia = p.mes_referencia
ORDER BY
    p.mes_referencia;