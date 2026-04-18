/*
===============================================================================
SCRIPT: RESSARCIMENTO DE ICMS-ST - SAÍDA DIAGNÓSTICA
-------------------------------------------------------------------------------
Objetivo:
- gerar uma visão de depuração do vínculo entre:
  1) saída SPED
  2) última entrada informada
  3) item XML padronizado
  4) score de aderência
  5) diferenças entre SPED, XML, Fronteira e Cálculo

Características:
- usa sempre a última EFD do período;
- consome as entradas da mais antiga para a mais nova;
- prioriza NCM/CEST do XML para inferência SEFIN;
- calcula sempre o valor calculado;
- seleciona o melhor vínculo da última entrada por score de aderência.

Parâmetros esperados:
- :CNPJ
- :data_inicial            (DD/MM/YYYY)
- :data_final              (DD/MM/YYYY)
- :data_limite_processamento (DD/MM/YYYY)

Saída:
- visão diagnóstica para depuração de vínculo, conferência do item XML e
  análise de confiança do casamento entre saída e última entrada.
===============================================================================
*/
WITH
PARAMETROS AS (
    SELECT
        :CNPJ AS cnpj_filtro,
        NVL(TO_DATE(:data_inicial, 'DD/MM/YYYY'), TO_DATE('01/01/1900', 'DD/MM/YYYY')) AS dt_ini_filtro,
        NVL(TO_DATE(:data_final, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_fim_filtro,
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte
    FROM dual
),

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
    SELECT DISTINCT s.chave_nfe_ultima_entrada AS chave_acesso
    FROM SAIDAS_RESSARCIMENTO s
    WHERE s.chave_nfe_ultima_entrada IS NOT NULL
),

CHAVES_SAIDA AS (
    SELECT DISTINCT s.chave_saida AS chave_acesso
    FROM SAIDAS_RESSARCIMENTO s
    WHERE s.chave_saida IS NOT NULL
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
    SELECT
        chave_acesso,
        seq_nitem,
        prod_nitem,
        item_xml_padrao,
        xml_descricao_item_entrada,
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

XML_SAIDA_BASE AS (
    SELECT
        nfe_sai.chave_acesso,
        nfe_sai.seq_nitem,
        nfe_sai.prod_nitem,
        COALESCE(nfe_sai.prod_nitem, nfe_sai.seq_nitem) AS item_xml_padrao,
        nfe_sai.prod_qcom AS qcom_saida,
        ROW_NUMBER() OVER (
            PARTITION BY nfe_sai.chave_acesso, COALESCE(nfe_sai.prod_nitem, nfe_sai.seq_nitem)
            ORDER BY NVL(nfe_sai.prod_nitem, -1) DESC, NVL(nfe_sai.seq_nitem, -1) DESC
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

CANDIDATOS_VINCULO_ENTRADA AS (
    SELECT
        s.chave_saida,
        s.num_item_saida,
        s.cod_item,
        s.chave_nfe_ultima_entrada,
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
        COALESCE(NULLIF(TRIM(xe.xml_ncm_entrada), ''), NULLIF(TRIM(i.cod_ncm_entrada_sped), '')) AS ncm_prioritario_candidato,
        COALESCE(NULLIF(TRIM(xe.xml_cest_entrada), ''), NULLIF(TRIM(i.cest_entrada_sped), '')) AS cest_prioritario_candidato,
        (
            CASE WHEN xe.item_xml_padrao IS NOT NULL THEN 1000 ELSE 0 END +
            CASE WHEN TRIM(COALESCE(xe.xml_ncm_entrada, i.cod_ncm_entrada_sped)) = TRIM(ps.cod_ncm) AND ps.cod_ncm IS NOT NULL THEN 200 ELSE 0 END +
            CASE WHEN TRIM(COALESCE(xe.xml_cest_entrada, i.cest_entrada_sped)) = TRIM(ps.cest) AND ps.cest IS NOT NULL THEN 150 ELSE 0 END +
            CASE WHEN UPPER(TRIM(COALESCE(xe.xml_descricao_item_entrada, i.descr_compl_entrada_sped, i.descr_item_entrada_sped))) = UPPER(TRIM(s.descricao_item)) AND s.descricao_item IS NOT NULL THEN 120 ELSE 0 END +
            CASE WHEN UPPER(TRIM(COALESCE(xe.xml_descricao_item_entrada, i.descr_compl_entrada_sped, i.descr_item_entrada_sped))) = UPPER(TRIM(ps.descr_item)) AND ps.descr_item IS NOT NULL THEN 80 ELSE 0 END +
            CASE
                WHEN COALESCE(xe.qcom_entrada, i.qtd_item_entrada_sped) = s.qtd_saida_sped AND s.qtd_saida_sped IS NOT NULL THEN 60
                WHEN ABS(NVL(COALESCE(xe.qcom_entrada, i.qtd_item_entrada_sped), 0) - NVL(s.qtd_saida_sped, 0)) <= 1 THEN 20
                ELSE 0
            END
        ) AS score_vinculo_entrada,
        ABS(NVL(COALESCE(xe.qcom_entrada, i.qtd_item_entrada_sped), 0) - NVL(s.qtd_saida_sped, 0)) AS diff_qtd_vinculo,
        ROW_NUMBER() OVER (
            PARTITION BY s.chave_saida, s.num_item_saida, s.cod_item, s.chave_nfe_ultima_entrada
            ORDER BY
                (
                    CASE WHEN xe.item_xml_padrao IS NOT NULL THEN 1000 ELSE 0 END +
                    CASE WHEN TRIM(COALESCE(xe.xml_ncm_entrada, i.cod_ncm_entrada_sped)) = TRIM(ps.cod_ncm) AND ps.cod_ncm IS NOT NULL THEN 200 ELSE 0 END +
                    CASE WHEN TRIM(COALESCE(xe.xml_cest_entrada, i.cest_entrada_sped)) = TRIM(ps.cest) AND ps.cest IS NOT NULL THEN 150 ELSE 0 END +
                    CASE WHEN UPPER(TRIM(COALESCE(xe.xml_descricao_item_entrada, i.descr_compl_entrada_sped, i.descr_item_entrada_sped))) = UPPER(TRIM(s.descricao_item)) AND s.descricao_item IS NOT NULL THEN 120 ELSE 0 END +
                    CASE WHEN UPPER(TRIM(COALESCE(xe.xml_descricao_item_entrada, i.descr_compl_entrada_sped, i.descr_item_entrada_sped))) = UPPER(TRIM(ps.descr_item)) AND ps.descr_item IS NOT NULL THEN 80 ELSE 0 END +
                    CASE
                        WHEN COALESCE(xe.qcom_entrada, i.qtd_item_entrada_sped) = s.qtd_saida_sped AND s.qtd_saida_sped IS NOT NULL THEN 60
                        WHEN ABS(NVL(COALESCE(xe.qcom_entrada, i.qtd_item_entrada_sped), 0) - NVL(s.qtd_saida_sped, 0)) <= 1 THEN 20
                        ELSE 0
                    END
                ) DESC,
                ABS(NVL(COALESCE(xe.qcom_entrada, i.qtd_item_entrada_sped), 0) - NVL(s.qtd_saida_sped, 0)) ASC,
                i.num_item_ult_entr_candidato ASC
        ) AS rn
    FROM SAIDAS_RESSARCIMENTO s
    LEFT JOIN PRODUTOS_SAIDA ps
      ON ps.reg_0000_id = s.reg_0000_id
     AND ps.cod_item = s.cod_item
    JOIN ITENS_ENTRADA_SPED_BASE i
      ON i.chv_nfe = s.chave_nfe_ultima_entrada
     AND i.cod_item = s.cod_item
    LEFT JOIN XML_ENTRADA xe
      ON xe.chave_acesso = i.chv_nfe
     AND xe.item_xml_padrao = i.num_item_ult_entr_candidato
),

VINCULO_ENTRADA_ESCOLHIDO AS (
    SELECT *
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
        ve.score_vinculo_entrada,
        ve.diff_qtd_vinculo,
        COALESCE(NULLIF(TRIM(ve.ncm_prioritario_candidato), ''), NULLIF(TRIM(ps.cod_ncm), '')) AS ncm_prioritario_sefin,
        COALESCE(NULLIF(TRIM(ve.cest_prioritario_candidato), ''), NULLIF(TRIM(ps.cest), '')) AS cest_prioritario_sefin,
        CASE
            WHEN NVL(ve.qcom_entrada, 0) <> 0
            THEN ve.xml_icms_vicms_total_entrada / ve.qcom_entrada
            ELSE NULL
        END AS xml_vl_unit_icms_proprio_entrada,
        CASE
            WHEN UPPER(TRIM(ve.it_co_rotina_calculo)) = 'ST' AND NVL(ve.qcom_entrada, 0) <> 0
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
     AND s.cod_item = ve.cod_item
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
            PARTITION BY b.chave_saida, b.num_item_saida, b.cod_item, b.chave_nfe_ultima_entrada, NVL(b.num_item_ult_entr, 0)
            ORDER BY v.dt_inicio_vig DESC, v.dt_final_vig DESC NULLS LAST, c.it_co_sefin DESC
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
            ORDER BY CASE WHEN b.dt_ultima_entrada IS NULL THEN 1 ELSE 0 END,
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
        NVL(q.vl_unit_icms_proprio_entrada, 0) * NVL(q.qtd_considerada, 0) AS sped_vl_ressarc_credito_proprio,
        NVL(q.xml_vl_unit_icms_proprio_entrada, 0) * NVL(q.qtd_considerada, 0) AS xml_vl_ressarc_credito_proprio,
        NVL(q.vl_unit_ressarcimento_st, 0) * NVL(q.qtd_considerada, 0) AS vl_ressarc_st_retido,
        NVL(q.fronteira_vl_unit_ressarcimento_st, 0) * NVL(q.qtd_considerada, 0) AS fronteira_vl_ressarcimento_st,
        CASE
            WHEN UPPER(TRIM(q.mva_ajustado_inferido)) = 'S'
             AND q.mva_inferido IS NOT NULL
             AND q.aliq_interna_inferida IS NOT NULL
             AND q.aliq_inter_entrada IS NOT NULL
             AND (1 - (q.aliq_interna_inferida / 100)) <> 0
            THEN ((((1 + (q.mva_inferido / 100)) * (1 - (q.aliq_inter_entrada / 100))) /
                  (1 - (q.aliq_interna_inferida / 100))) - 1) * 100
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
                    NVL(c.prod_vprod, 0) +
                    NVL(c.prod_vfrete, 0) +
                    NVL(c.prod_vseg, 0) +
                    NVL(c.prod_voutro, 0) +
                    NVL(c.ipi_vipi, 0) -
                    NVL(c.prod_vdesc, 0)
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
                                NVL(c.prod_vprod, 0) +
                                NVL(c.prod_vfrete, 0) +
                                NVL(c.prod_vseg, 0) +
                                NVL(c.prod_voutro, 0) +
                                NVL(c.ipi_vipi, 0) -
                                NVL(c.prod_vdesc, 0)
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
        END AS calculado_vl_ressarcimento_st
    FROM BASE_FINAL_1 f
)

SELECT
    TO_CHAR(b.comp_efd, 'MM/YYYY')      AS ref_periodo_efd,
    b.chave_saida                       AS ref_chave_nfe_saida,
    b.num_nf_saida                      AS ref_num_nf_saida,
    b.num_item_saida                    AS ref_num_item_saida,
    b.cod_item                          AS produto_cod_item,
    b.chave_nfe_ultima_entrada          AS ref_chave_nfe_ultima_entrada,
    b.num_item_ult_entr                 AS ref_num_item_ultima_entrada_sped,
    b.dt_ultima_entrada                 AS ref_dt_ultima_entrada,
    b.seq_nitem_saida                   AS aud_xml_saida_seq_nitem,
    b.prod_nitem_saida                  AS aud_xml_saida_prod_nitem,
    b.item_xml_saida_padrao             AS aud_xml_saida_item_padrao,
    b.seq_nitem_entrada                 AS aud_xml_entrada_seq_nitem,
    b.prod_nitem_entrada                AS aud_xml_entrada_prod_nitem,
    b.item_xml_entrada_padrao           AS aud_xml_entrada_item_padrao,
    b.score_vinculo_entrada             AS aud_score_vinculo_entrada,
    b.diff_qtd_vinculo                  AS aud_diff_qtd_vinculo,
    CASE
        WHEN b.score_vinculo_entrada >= 1400 THEN 'ALTA CONFIANÇA'
        WHEN b.score_vinculo_entrada >= 1100 THEN 'MÉDIA CONFIANÇA'
        WHEN b.score_vinculo_entrada IS NOT NULL THEN 'BAIXA CONFIANÇA'
        ELSE 'SEM VÍNCULO AVALIADO'
    END AS aud_nivel_confianca_vinculo,
    b.descr_item                        AS produto_descr_item_0200,
    b.descricao_item                    AS produto_descr_compl_saida_sped,
    b.xml_descricao_item_entrada        AS xml_descr_item_entrada,
    b.cod_ncm                           AS produto_ncm_0200,
    b.cest                              AS produto_cest_0200,
    b.xml_ncm_entrada                   AS xml_ncm_entrada,
    b.xml_cest_entrada                  AS xml_cest_entrada,
    b.ncm_prioritario_sefin             AS sefin_ncm_prioritario,
    b.cest_prioritario_sefin            AS sefin_cest_prioritario,
    b.qtd_saida_sped                    AS sped_qtd_saida,
    b.qcom_saida                        AS xml_qcom_saida,
    b.qcom_entrada                      AS xml_qcom_entrada,
    b.soma_qcom_entrada_total           AS xml_soma_qcom_entrada_total,
    b.soma_qcom_entrada_acum            AS xml_soma_qcom_entrada_acum,
    b.qtd_considerada                   AS sped_qtd_considerada,
    b.vl_unit_bc_st_entrada             AS sped_vl_unit_bc_st_entrada,
    b.vl_unit_icms_proprio_entrada      AS sped_vl_unit_icms_proprio_entrada,
    b.vl_unit_ressarcimento_st          AS sped_vl_unit_ressarcimento_st,
    b.xml_vl_unit_icms_proprio_entrada  AS xml_vl_unit_icms_proprio_entrada,
    b.fronteira_vl_unit_ressarcimento_st AS fronteira_vl_unit_ressarcimento_st,
    b.calculado_vl_unit_ressarcimento_st AS calc_vl_unit_ressarcimento_st,
    b.sped_vl_ressarc_credito_proprio   AS sped_vl_ressarc_credito_proprio,
    b.xml_vl_ressarc_credito_proprio    AS xml_vl_ressarc_credito_proprio,
    b.vl_ressarc_st_retido              AS sped_vl_ressarc_st_retido,
    b.fronteira_vl_ressarcimento_st     AS fronteira_vl_ressarcimento_st,
    b.calculado_vl_ressarcimento_st     AS calc_vl_ressarcimento_st,
    b.aliq_interna_inferida             AS sefin_aliq_interna_inferida,
    b.aliq_inter_entrada                AS sefin_aliq_inter_entrada,
    b.mva_inferido                      AS sefin_mva_inferido,
    b.mva_ajustado_inferido             AS sefin_ind_mva_ajustado,
    b.mva_ajustado_inferido_calc        AS sefin_mva_ajustado_calc,
    b.bc_icms_st_calc                   AS calc_bc_icms_st,
    b.it_co_rotina_calculo              AS fronteira_rotina_calculo,
    b.vl_icms_fronteira                 AS fronteira_vl_icms_total,
    b.sped_vl_ressarc_credito_proprio - b.xml_vl_ressarc_credito_proprio AS aud_diff_sped_xml_icms_proprio,
    b.vl_ressarc_st_retido - b.fronteira_vl_ressarcimento_st AS aud_diff_sped_fronteira_st,
    NVL(b.calculado_vl_ressarcimento_st, 0) - NVL(b.vl_ressarc_st_retido, 0) AS aud_diff_calc_sped_st,
    CASE
        WHEN NVL(b.qcom_saida, 0) = 0 THEN 'SEM QCOM DE SAÍDA'
        WHEN NVL(b.qcom_entrada, 0) = 0 THEN 'SEM QCOM DE ENTRADA'
        WHEN b.soma_qcom_entrada_total > b.qcom_saida THEN 'LIMITADO PELA QCOM DA SAÍDA'
        ELSE 'QCOM TOTAL DE ENTRADA DENTRO DO LIMITE DA SAÍDA'
    END AS aud_status_qtd_considerada,
    CASE
        WHEN b.qcom_saida IS NULL THEN 'QCOM DE SAÍDA NÃO ENCONTRADA'
        WHEN NVL(b.qcom_saida, 0) = 0 THEN 'QCOM DE SAÍDA ZERADA'
        WHEN b.qtd_considerada = 0 THEN 'SEM QUANTIDADE CONSIDERADA'
        WHEN b.xml_vl_unit_icms_proprio_entrada IS NULL THEN 'XML NÃO ENCONTRADO/FORA DO FILTRO'
        WHEN ABS(NVL(b.sped_vl_ressarc_credito_proprio, 0) - NVL(b.xml_vl_ressarc_credito_proprio, 0)) > 10 THEN 'VALORES DIVERGENTES'
        ELSE 'VALORES IGUAIS'
    END AS aud_status_sped_xml_icms_proprio,
    CASE
        WHEN b.it_co_rotina_calculo IS NULL THEN 'FRONTEIRA NÃO ENCONTRADA'
        WHEN UPPER(TRIM(b.it_co_rotina_calculo)) <> 'ST' THEN 'ROTINA DIFERENTE DE ST'
        WHEN b.qcom_saida IS NULL THEN 'QCOM DE SAÍDA NÃO ENCONTRADA'
        WHEN NVL(b.qcom_saida, 0) = 0 THEN 'QCOM DE SAÍDA ZERADA'
        WHEN b.qtd_considerada = 0 THEN 'SEM QUANTIDADE CONSIDERADA'
        WHEN ABS(NVL(b.vl_ressarc_st_retido, 0) - NVL(b.fronteira_vl_ressarcimento_st, 0)) > 10 THEN 'VALORES DIVERGENTES'
        ELSE 'VALORES IGUAIS'
    END AS aud_status_sped_fronteira_st,
    CASE
        WHEN b.calculado_vl_ressarcimento_st IS NULL THEN 'VALOR CALCULADO NÃO DISPONÍVEL'
        WHEN ABS(NVL(b.calculado_vl_ressarcimento_st, 0) - NVL(b.vl_ressarc_st_retido, 0)) > 10 THEN 'VALORES DIVERGENTES'
        ELSE 'VALORES IGUAIS'
    END AS aud_status_calc_sped_st
FROM BASE_FINAL b
ORDER BY
    b.comp_efd,
    b.dt_emissao_saida,
    b.chave_saida,
    b.num_item_saida,
    b.dt_ultima_entrada,
    b.chave_nfe_ultima_entrada,
    b.num_item_ult_entr;
