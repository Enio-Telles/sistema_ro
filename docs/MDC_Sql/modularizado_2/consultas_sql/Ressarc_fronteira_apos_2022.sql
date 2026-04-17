/* =========================================================================================
   PAINEL DE AUDITORIA 360º - RESSARCIMENTO DE ICMS ST (SPED x XML x SITAFE)
   =========================================================================================
   Objetivo: Cruzar os dados declarados no SPED EFD (Blocos C100, C170, C176, 0200)
   com os dados reais das Notas Fiscais Eletrônicas (XMLs de Entrada e Saída) e
   com a cobrança de fronteira do SITAFE (Estado de Rondônia).

   Lógica Principal: Aplica o método PEPS (Primeiro a Entrar, Primeiro a Sair - FIFO)
   para ratear e limitar as quantidades de entrada de acordo com a quantidade vendida na saída.
========================================================================================= */

-- Define o ponto como separador decimal para leitura correta do XML (XMLTABLE)
ALTER SESSION SET NLS_NUMERIC_CHARACTERS='.,';

WITH
    -------------------------------------------------------------------------
    -- 1. PARAMETROS: Tratamento de filtros informados pelo utilizador.
    -------------------------------------------------------------------------
    PARAMETROS AS (
        SELECT
            :CNPJ AS cnpj_filtro,
            NVL(TO_DATE(:data_inicial, 'DD/MM/YYYY'), TO_DATE('01/01/1900', 'DD/MM/YYYY')) AS dt_ini_filtro,
            NVL(TO_DATE(:data_final, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_fim_filtro,
            NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte
        FROM dual
    ),

    -------------------------------------------------------------------------
    -- 2. ARQUIVOS_RANKING: Controlo de Versionamento (Retificadoras SPED)
    -------------------------------------------------------------------------
    ARQUIVOS_RANKING AS (
        SELECT
            reg_0000.id AS reg_0000_id,
            reg_0000.cnpj,
            reg_0000.cod_fin AS cod_fin_efd,
            reg_0000.dt_ini,
            reg_0000.data_entrega,
            ROW_NUMBER() OVER (
                PARTITION BY reg_0000.cnpj, reg_0000.dt_ini
                ORDER BY reg_0000.data_entrega DESC, reg_0000.id DESC
            ) AS rn
        FROM sped.reg_0000 reg_0000
        JOIN PARAMETROS p ON reg_0000.cnpj = p.cnpj_filtro
        WHERE reg_0000.data_entrega <= p.dt_corte
          AND reg_0000.dt_ini BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
    ),

    -------------------------------------------------------------------------
    -- 3. CHAVES_ENTRADA_FILTRADAS: Otimização de Performance
    -------------------------------------------------------------------------
    CHAVES_ENTRADA_FILTRADAS AS (
        SELECT DISTINCT c176_sub.chave_nfe_ult
        FROM sped.reg_c176 c176_sub
        INNER JOIN ARQUIVOS_RANKING arq_sub ON c176_sub.reg_0000_id = arq_sub.reg_0000_id
        WHERE arq_sub.rn = 1
    ),

    -------------------------------------------------------------------------
    -- 3.5. XML_EXTRAIDO: Extração Direta de Campos do XML (CLOB)
    -- Extrai o vICMSSubstituto que não está nativamente na fato_nfe_detalhe.
    -- O INNER JOIN com as chaves filtradas garante altíssima performance.
    -------------------------------------------------------------------------
    XML_EXTRAIDO AS (
        SELECT
            x.chave_acesso,
            xml_item.prod_nitem,
            xml_item.icms_vICMSSubstituto
        FROM bi.nfe_xml x
        INNER JOIN CHAVES_ENTRADA_FILTRADAS cef ON x.chave_acesso = cef.chave_nfe_ult
        CROSS JOIN XMLTABLE(
            XMLNAMESPACES (DEFAULT 'http://www.portalfiscal.inf.br/nfe'),
            '//det' PASSING x.xml
            COLUMNS
                Prod_nItem           NUMBER       PATH '@nItem',
                icms_vICMSSubstituto NUMBER       PATH 'imposto/ICMS//vICMSSubstituto' DEFAULT 0
        ) xml_item
    ),

    -------------------------------------------------------------------------
    -- 4. DADOS_BASE: Recolhe todos os dados brutos e calcula VALORES UNITÁRIOS
    -------------------------------------------------------------------------
    DADOS_BASE AS (
        SELECT
            arq.dt_ini,
            TO_CHAR(arq.dt_ini, 'MM/YYYY') AS periodo_efd,
            CASE arq.cod_fin_efd
                WHEN '0' THEN '0 - Original'
                WHEN '1' THEN '1 - Substituto'
                ELSE TO_CHAR(arq.cod_fin_efd)
            END AS finalidade_efd,

            -- DADOS DA SAÍDA DECLARADOS NO SPED (Blocos C100 e C170)
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

            -- DADOS DA SAÍDA EXTRAÍDOS DO XML (fato_nfe_detalhe)
            nfe_sai.dhemi      AS xml_dhemi_saida,
            nfe_sai.prod_qcom  AS xml_qtd_comercial_saida,
            nfe_sai.prod_xprod AS xml_descricao_item_saida,
            nfe_sai.prod_cean  AS xml_cean_saida,
            nfe_sai.prod_ncm   AS xml_ncm_saida,
            nfe_sai.prod_cest  AS xml_cest_saida,
            nfe_sai.co_iddest  AS xml_iddest_saida,
            nfe_sai.co_uf_emit AS xml_uf_emit_saida,
            nfe_sai.co_uf_dest AS xml_uf_dest_saida,

            -- DADOS DA ENTRADA DECLARADOS NO SPED (Registo C176)
            c176.cod_mot_res,
            c176.chave_nfe_ult AS chave_nfe_ultima_entrada,
            c170_entrada.num_item AS num_item_ult_entr,
            CASE WHEN c176.dt_ult_e IS NOT NULL AND REGEXP_LIKE(c176.dt_ult_e, '^\d{8}$')
                 THEN TO_DATE(c176.dt_ult_e, 'DDMMYYYY') ELSE NULL END AS dt_ultima_entrada,
            NVL(c176.quant_ult_e, 0) AS qtd_entrada_sped,
            NVL(c176.vl_unit_ult_e, 0) AS vl_unit_bc_st_entrada_sped,
            NVL(c176.vl_unit_icms_ult_e, 0) AS vl_unit_icms_proprio_entrada_sped,
            NVL(c176.vl_unit_res, 0) AS vl_unit_ressarcimento_st_sped,

            -- DADOS DA ENTRADA EXTRAÍDOS DO XML (fato_nfe_detalhe)
            nfe_ent.dhemi      AS xml_dhemi_entrada,
            NVL(nfe_ent.prod_qcom, 0) AS xml_qtd_comercial_entrada,
            nfe_ent.prod_xprod AS xml_descricao_item_entrada,
            nfe_ent.prod_cean  AS xml_cean_entrada,
            nfe_ent.prod_ncm   AS xml_ncm_entrada,
            nfe_ent.prod_cest  AS xml_cest_entrada,
            nfe_ent.co_iddest  AS xml_iddest_entrada,
            nfe_ent.co_uf_emit AS xml_uf_emit_entrada,
            nfe_ent.co_uf_dest AS xml_uf_dest_entrada,
            NVL(nfe_ent.prod_vprod, 0) AS xml_vprod_entrada,
            NVL(nfe_ent.ipi_vipi, 0)   AS xml_vipi_entrada,

            -- TOTAIS DA ENTRADA (Extraídos do XML e do SITAFE)
            NVL(nfe_ent.icms_vbc, 0)                            AS xml_vbc_icms_entrada,
            nfe_ent.icms_picms                                  AS xml_aliquota_icms_proprio_entrada,
            NVL(nfe_ent.icms_vicms, 0)                          AS xml_icms_vicms_entrada_total,
            NVL(nfe_ent.icms_vicmsstret, 0)                     AS xml_icms_vicmsstret_entrada,
            NVL(nfe_ent.icms_vicmsst, 0)                        AS xml_icms_vicmsst_entrada, -- ST Destacado

            -- CAMPO INTEGRADO VIA LEITURA DIRETA DO XML (XMLTABLE)
            NVL(xml_ext.icms_vICMSSubstituto, 0)                AS xml_icms_vicmssubstituto_entrada,

            NVL(TO_CHAR(calc_front.it_co_rotina_calculo), 'sem calculo') AS xml_fronteira_entrada,
            NVL(calc_front.it_vl_icms, 0)                       AS xml_calc_fronteira_entrada_total,

            -- CAMPOS DE PRODUTO SEFIN E MVA
            COALESCE(calc_front.it_co_sefin, cest_ncm.IT_CO_SEFIN) AS co_sefin_efetivo,
            h.it_pc_interna,
            h.it_in_st,
            h.it_in_mva_ajustado,
            h.it_pc_mva,

            CASE
                WHEN h.it_in_mva_ajustado = 'S' THEN
                    (((1 + (NVL(h.it_pc_mva, 0) / 100)) * (1 - (NVL(nfe_ent.icms_picms, 0) / 100)) / NULLIF((1 - (NVL(h.it_pc_interna, 0) / 100)), 0)) - 1) * 100
                ELSE
                    NVL(h.it_pc_mva, 0)
            END AS mva_calculado_efetivo,

            /* =========================================================================================
               A P U R A Ç Ã O   O U R O   ( 4   N Í V E I S )
               Lógica baseada em cascata de prioridades para descobrir o valor unitário real de ST e Próprio.
               ========================================================================================= */

            -- NÍVEL DEFINIDO PARA ICMS ST
            CASE
                WHEN calc_front.it_co_rotina_calculo IS NOT NULL THEN '1 - Fronteira (SITAFE)'
                WHEN NVL(nfe_ent.icms_vicmsst, 0) > 0 THEN '2 - ICMS ST Destacado na NF'
                WHEN NVL(nfe_ent.icms_vicmsstret, 0) > 0 THEN '3 - ICMS ST Retido / Substituto'
                ELSE '4 - Refeito pelo MVA (Estimado)'
            END AS xml_nivel_apuracao_st,

            -- NÍVEL DEFINIDO PARA ICMS PRÓPRIO
            CASE
                WHEN calc_front.it_co_rotina_calculo IS NOT NULL THEN '1 - Fronteira (SITAFE)'
                WHEN NVL(nfe_ent.icms_vicms, 0) > 0 THEN '2 - ICMS Próprio Destacado na NF'
                WHEN NVL(xml_ext.icms_vICMSSubstituto, 0) > 0 THEN '3 - ICMS Substituto Preenchido'
                ELSE '4 - Sem Destaque (Considerado 0)'
            END AS xml_nivel_apuracao_proprio,

            -- CÁLCULO FINAL: ICMS ST UNITÁRIO APURADO
            CASE
                WHEN calc_front.it_co_rotina_calculo IS NOT NULL THEN
                     (NVL(calc_front.it_vl_icms, 0) / NULLIF(nfe_ent.prod_qcom, 0))
                WHEN NVL(nfe_ent.icms_vicmsst, 0) > 0 THEN
                     (NVL(nfe_ent.icms_vicmsst, 0) / NULLIF(nfe_ent.prod_qcom, 0))
                WHEN NVL(nfe_ent.icms_vicmsstret, 0) > 0 THEN
                     (NVL(nfe_ent.icms_vicmsstret, 0) / NULLIF(nfe_ent.prod_qcom, 0))
                ELSE
                     -- INFERÊNCIA ST (Nível 4)
                     GREATEST(0, (
                         (
                             (NVL(nfe_ent.prod_vprod, NVL(nfe_ent.icms_vbc, 0)) + NVL(nfe_ent.ipi_vipi, 0))
                             * (1 + (
                                 CASE
                                     WHEN h.it_in_mva_ajustado = 'S' THEN
                                         (((1 + (NVL(h.it_pc_mva, 0) / 100)) * (1 - (NVL(nfe_ent.icms_picms, 0) / 100)) / NULLIF((1 - (NVL(h.it_pc_interna, 0) / 100)), 0)) - 1) * 100
                                     ELSE NVL(h.it_pc_mva, 0)
                                 END
                             ) / 100)
                         ) * (NVL(h.it_pc_interna, 0) / 100)
                         - NVL(nfe_ent.icms_vicms, 0)
                     ) / NULLIF(nfe_ent.prod_qcom, 0))
            END AS xml_apurado_st_unitario,

            -- CÁLCULO FINAL: ICMS PRÓPRIO UNITÁRIO APURADO
            CASE
                WHEN calc_front.it_co_rotina_calculo IS NOT NULL THEN
                     (NVL(nfe_ent.icms_vicms, 0) / NULLIF(nfe_ent.prod_qcom, 0))
                WHEN NVL(nfe_ent.icms_vicms, 0) > 0 THEN
                     (NVL(nfe_ent.icms_vicms, 0) / NULLIF(nfe_ent.prod_qcom, 0))
                WHEN NVL(xml_ext.icms_vICMSSubstituto, 0) > 0 THEN
                     (NVL(xml_ext.icms_vICMSSubstituto, 0) / NULLIF(nfe_ent.prod_qcom, 0))
                ELSE
                     0 -- Se não se enquadra em nada, não há crédito de ICMS próprio.
            END AS xml_apurado_proprio_unitario

        FROM sped.reg_c176 c176
            INNER JOIN ARQUIVOS_RANKING arq ON c176.reg_0000_id = arq.reg_0000_id AND arq.rn = 1
            INNER JOIN sped.reg_c100 c100 ON c176.reg_c100_id = c100.id
            INNER JOIN sped.reg_c170 c170 ON c176.reg_c170_id = c170.id
            LEFT JOIN sped.reg_0200 r0200 ON r0200.reg_0000_id = c176.reg_0000_id AND r0200.cod_item = c170.cod_item

            -- XML SAIDA
            LEFT JOIN bi.fato_nfe_detalhe nfe_sai ON nfe_sai.chave_acesso = c100.chv_nfe AND nfe_sai.seq_nitem = TO_NUMBER(c170.num_item)

            -- SUBQUERY IDENTIFICACAO DO ITEM DE ENTRADA
            LEFT JOIN (
                SELECT c100_in.chv_nfe, c170_in.cod_item, MAX(c170_in.num_item) AS num_item
                FROM sped.reg_c100 c100_in
                INNER JOIN sped.reg_c170 c170_in ON c170_in.reg_c100_id = c100_in.id
                INNER JOIN CHAVES_ENTRADA_FILTRADAS cef ON c100_in.chv_nfe = cef.chave_nfe_ult
                GROUP BY c100_in.chv_nfe, c170_in.cod_item
            ) c170_entrada ON c170_entrada.chv_nfe = c176.chave_nfe_ult AND c170_entrada.cod_item = c170.cod_item

            -- XML ENTRADA E CALCULO SITAFE
            LEFT JOIN bi.fato_nfe_detalhe nfe_ent ON nfe_ent.chave_acesso = c176.chave_nfe_ult AND nfe_ent.seq_nitem = TO_NUMBER(c170_entrada.num_item)

            -- EXTRAÇÃO DIRETA DO XML (vICMSSubstituto)
            LEFT JOIN XML_EXTRAIDO xml_ext ON xml_ext.chave_acesso = c176.chave_nfe_ult AND xml_ext.prod_nitem = TO_NUMBER(c170_entrada.num_item)

            LEFT JOIN sitafe.sitafe_nfe_calculo_item calc_front ON calc_front.it_nu_chave_acesso = nfe_ent.chave_acesso AND calc_front.it_nu_item = nfe_ent.prod_nitem

            -- PRODUTO SEFIN E MVA
            LEFT JOIN SITAFE.SITAFE_CEST_NCM cest_ncm
                   ON cest_ncm.IT_NU_NCM = nfe_ent.prod_ncm
                  AND (nfe_ent.prod_cest IS NULL OR cest_ncm.IT_NU_CEST = nfe_ent.prod_cest)
                  AND cest_ncm.IT_IN_STATUS <> 'C'
            LEFT JOIN sitafe.sitafe_produto_sefin_aux h
                   ON h.it_co_sefin = COALESCE(calc_front.it_co_sefin, cest_ncm.IT_CO_SEFIN)
                  AND TO_CHAR(nfe_ent.dhemi, 'YYYYMMDD') >= h.it_da_inicio
                  AND (h.it_da_final IS NULL OR TO_CHAR(nfe_ent.dhemi, 'YYYYMMDD') <= h.it_da_final)
    ),

    -------------------------------------------------------------------------
    -- 5. DADOS_ACUMULADOS: Aplicando a memória FIFO (PEPS)
    -------------------------------------------------------------------------
    DADOS_ACUMULADOS AS (
        SELECT
            db.*,
            NVL(SUM(db.xml_qtd_comercial_entrada) OVER (
                PARTITION BY db.chave_saida, db.num_item_saida
                ORDER BY db.xml_dhemi_entrada ASC, db.chave_nfe_ultima_entrada ASC
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ), 0) AS qtd_entrada_acumulada_anterior
        FROM DADOS_BASE db
    ),

    -------------------------------------------------------------------------
    -- 6. DADOS_RATEIO: Definindo o teto/limite utilizável de cada entrada
    -------------------------------------------------------------------------
    DADOS_RATEIO AS (
        SELECT
            da.*,
            GREATEST(0, LEAST(da.xml_qtd_comercial_entrada, da.qtd_saida - da.qtd_entrada_acumulada_anterior)) AS qtd_entrada_utilizada
        FROM DADOS_ACUMULADOS da
    )

-------------------------------------------------------------------------
-- 7. SELEÇÃO FINAL: O PAINEL DE AUDITORIA 360º ORDENADO POR FONTE
-------------------------------------------------------------------------
SELECT
    dr.periodo_efd,
    dr.finalidade_efd,

    -- 1. SPED EFD - DADOS DA SAÍDA
    dr.chave_saida,
    dr.num_nf_saida,
    dr.dt_emissao_saida AS dt_saida_sped,
    dr.num_item_saida,
    dr.cod_item,
    dr.cod_barra,
    dr.descr_item,
    dr.descr_compl,
    dr.cod_ncm AS ncm_sped,
    dr.cest,
    dr.qtd_saida AS qtd_saida_sped,
    dr.vl_total_item_saida,
    dr.c170_vl_icms,

    -- 2. SPED EFD - DADOS DA ÚLTIMA ENTRADA
    dr.cod_mot_res,
    CASE dr.cod_mot_res
        WHEN '1' THEN '1 - Saída para outra UF'
        WHEN '2' THEN '2 - Saída amparada por isenção ou não incidência'
        WHEN '3' THEN '3 - Perda ou deterioração'
        WHEN '4' THEN '4 - Furto ou roubo'
        WHEN '5' THEN '5 - Exportação'
        WHEN '6' THEN '6 - Venda interna para Simples Nacional'
        WHEN '9' THEN '9 - Outros'
        ELSE dr.cod_mot_res
    END AS descricao_motivo_ressarcimento,
    dr.chave_nfe_ultima_entrada,
    dr.num_item_ult_entr,
    dr.dt_ultima_entrada AS dt_entrada_sped,
    dr.qtd_entrada_sped,
    dr.vl_unit_bc_st_entrada_sped,
    dr.vl_unit_icms_proprio_entrada_sped,
    dr.vl_unit_ressarcimento_st_sped,

    -- 3. XML - DADOS DA SAÍDA
    TRUNC(dr.xml_dhemi_saida) AS dt_saida_xml,
    dr.xml_qtd_comercial_saida AS qtd_saida_xml,
    dr.xml_descricao_item_saida,
    dr.xml_cean_saida,
    dr.xml_ncm_saida,
    dr.xml_cest_saida,
    dr.xml_iddest_saida,
    dr.xml_uf_emit_saida,
    dr.xml_uf_dest_saida,

    -- 4. XML - DADOS DA ENTRADA E VARIÁVEIS MVA
    TRUNC(dr.xml_dhemi_entrada) AS dt_entrada_xml,
    dr.xml_qtd_comercial_entrada AS qtd_entrada_xml,
    dr.xml_descricao_item_entrada,
    dr.xml_cean_entrada,
    dr.xml_ncm_entrada,
    dr.xml_cest_entrada,
    dr.xml_iddest_entrada,
    dr.xml_uf_emit_entrada,
    dr.xml_uf_dest_entrada,

    dr.xml_icms_vicmssubstituto_entrada, -- EXIBINDO O CAMPO EXTRAÍDO DO XML AQUI

    dr.xml_fronteira_entrada,
    dr.co_sefin_efetivo,
    dr.it_pc_interna,
    dr.it_in_st,
    dr.it_in_mva_ajustado,
    dr.it_pc_mva AS mva_original,
    dr.mva_calculado_efetivo,

    -- 5. AUDITORIA: NÍVEIS IDENTIFICADOS E VALORES APURADOS (PADRÃO OURO)
    dr.xml_nivel_apuracao_st,
    dr.xml_nivel_apuracao_proprio,
    dr.xml_apurado_st_unitario,
    dr.xml_apurado_proprio_unitario,

    -- 6. AUDITORIA: COMPARAÇÕES, LIMITES E DIFERENÇAS FINANCEIRAS
    dr.qtd_entrada_acumulada_anterior,
    dr.qtd_entrada_utilizada AS qtd_base_calculo_ressarcimento,

    CASE WHEN dr.xml_dhemi_saida IS NULL THEN 'XML SAÍDA AUSENTE' ELSE 'OK' END AS status_xml_saida,
    CASE WHEN dr.xml_dhemi_entrada IS NULL THEN 'XML ENTRADA AUSENTE' ELSE 'OK' END AS status_xml_entrada,
    CASE WHEN dr.dt_emissao_saida IS NULL OR dr.xml_dhemi_saida IS NULL THEN 'DATA EM FALTA'
         WHEN dr.dt_emissao_saida = TRUNC(dr.xml_dhemi_saida) THEN 'OK' ELSE 'DATA DIVERGENTE' END AS status_data_saida,
    CASE WHEN dr.dt_ultima_entrada IS NULL OR dr.xml_dhemi_entrada IS NULL THEN 'DATA EM FALTA'
         WHEN dr.dt_ultima_entrada = TRUNC(dr.xml_dhemi_entrada) THEN 'OK' ELSE 'DATA DIVERGENTE' END AS status_data_entrada,
    CASE WHEN dr.cod_ncm = dr.xml_ncm_saida AND dr.cod_ncm = dr.xml_ncm_entrada THEN 'OK' ELSE 'NCM DIVERGENTE (SPED/XML)' END AS status_ncm,
    CASE WHEN dr.qtd_saida = NVL(dr.xml_qtd_comercial_saida, 0) THEN 'OK' ELSE 'DIVERGENTE' END AS status_qtd_saida,
    CASE WHEN dr.qtd_entrada_sped = dr.xml_qtd_comercial_entrada THEN 'OK' ELSE 'DIVERGENTE' END AS status_qtd_entrada_c176,

    -- Validação: ICMS Próprio Informado (SPED) vs Apurado Ouro
    CASE WHEN ABS(ROUND(dr.vl_unit_icms_proprio_entrada_sped, 2) - ROUND(dr.xml_apurado_proprio_unitario, 2)) <= 0.05 THEN 'OK' ELSE 'DIVERGENTE' END AS status_icms_proprio_apurado,
    (dr.qtd_saida * dr.vl_unit_icms_proprio_entrada_sped) AS total_sped_icms_proprio_informado,
    (dr.qtd_entrada_utilizada * dr.xml_apurado_proprio_unitario) AS total_xml_icms_proprio_apurado,

    -- Validação: ST Retido Informado (SPED) vs Apurado Ouro
    CASE WHEN ABS(ROUND(dr.vl_unit_ressarcimento_st_sped, 2) - ROUND(dr.xml_apurado_st_unitario, 2)) <= 0.05 THEN 'OK' ELSE 'DIVERGENTE' END AS status_icms_st_apurado,
    (dr.qtd_entrada_utilizada * dr.vl_unit_ressarcimento_st_sped) AS total_sped_ressarc_st_rateado,
    (dr.qtd_entrada_utilizada * dr.xml_apurado_st_unitario) AS total_apurado_ressarc_st_rateado,

    -- O Foco do Ressarcimento (A Diferença a Pagar ou Glosar)
    (dr.qtd_entrada_utilizada * dr.vl_unit_ressarcimento_st_sped) - (dr.qtd_entrada_utilizada * dr.xml_apurado_st_unitario) AS diferenca_financeira_st_sped_vs_apurado

FROM DADOS_RATEIO dr
ORDER BY dr.dt_ini, dr.dt_emissao_saida, dr.num_nf_saida, dr.num_item_saida, dr.xml_dhemi_entrada;
