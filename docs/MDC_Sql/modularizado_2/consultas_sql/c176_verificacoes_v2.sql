/*
================================================================================
SCRIPT DE REVISÃO E CRUZAMENTO: RESSARCIMENTO DE ICMS ST (SPED vs XML) - OTIMIZADO
Criado a partir do verf.sql com uso intensivo de CTEs para ganhos de performance.
================================================================================
*/
WITH
    -- 1. Parâmetros de Filtro
    PARAMETROS AS (
        SELECT
:CNPJ AS cnpj_filtro,
            NVL (
                TO_DATE(:data_inicial, 'DD/MM/YYYY'),
                TO_DATE('01/01/1900', 'DD/MM/YYYY')
            ) AS dt_ini_filtro,
            NVL (
                TO_DATE(:data_final, 'DD/MM/YYYY'),
                TRUNC(SYSDATE)
            ) AS dt_fim_filtro,
            NVL (
                TO_DATE(
:data_limite_processamento,
                    'DD/MM/YYYY'
                ),
                TRUNC(SYSDATE)
            ) AS dt_corte
        FROM dual
    ),

-- 2. Identificação do Arquivo SPED EFD mais recente (Ranking Filtrado Antecipadamente)
ARQUIVOS_VALIDOS AS (
    SELECT
        reg_0000.id AS reg_0000_id,
        reg_0000.cnpj,
        reg_0000.cod_fin AS cod_fin_efd,
        reg_0000.dt_ini,
        reg_0000.data_entrega
    FROM (
            SELECT
                id, cnpj, cod_fin, dt_ini, data_entrega, ROW_NUMBER() OVER (
                    PARTITION BY
                        cnpj, dt_ini
                    ORDER BY data_entrega DESC, id DESC
                ) AS rn
            FROM sped.reg_0000
                JOIN PARAMETROS p ON cnpj = p.cnpj_filtro
            WHERE
                data_entrega <= p.dt_corte
                AND dt_ini BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
        ) reg_0000
    WHERE
        rn = 1
),

-- 3. Detalhamento das Saídas e Ressarcimento (C100 + C170 + C176)
-- Ao invés de fazer JOINs em cascata no final, já filtramos o universo de saídas que importam
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
        c170.qtd AS qtd_saida,
        c170.vl_item AS vl_total_item_saida,
        c170.vl_icms,
        c176.cod_mot_res,
        c176.chave_nfe_ult AS chave_nfe_ultima_entrada,
        c176.dt_ult_e,
        c176.vl_unit_ult_e AS vl_unit_bc_st_entrada,
        c176.vl_unit_icms_ult_e AS vl_unit_icms_proprio_entrada,
        c176.vl_unit_res AS vl_unit_ressarcimento_st
    FROM
        sped.reg_c176 c176
        JOIN ARQUIVOS_VALIDOS arq ON c176.reg_0000_id = arq.reg_0000_id
        JOIN sped.reg_c100 c100 ON c176.reg_c100_id = c100.id
        JOIN sped.reg_c170 c170 ON c176.reg_c170_id = c170.id
        -- Ajuda muito o otimizador a cortar caminhos em tabelas grandes:
    WHERE
        c100.reg_0000_id = arq.reg_0000_id
        AND c170.reg_0000_id = arq.reg_0000_id
),

-- 4. Cadastro de Produtos (0200) isolado para os arquivos válidos
PRODUTOS AS (
    SELECT DISTINCT
        r0200.reg_0000_id,
        r0200.cod_item,
        r0200.cod_barra,
        r0200.descr_item,
        r0200.cod_ncm,
        r0200.cest
    FROM sped.reg_0200 r0200
        JOIN ARQUIVOS_VALIDOS arq ON r0200.reg_0000_id = arq.reg_0000_id
),

-- 5. Busca do C170 da Entrada otimizada para buscar SÓ as chaves já conhecidas (que estão no C176)
ITENS_ENTRADA_SPED AS (
    SELECT c100_in.chv_nfe, c170_in.cod_item, MAX(c170_in.num_item) AS num_item_ult_entr
    FROM sped.reg_c100 c100_in
        JOIN sped.reg_c170 c170_in ON c170_in.reg_c100_id = c100_in.id
        -- Pre-filtra varreduras completas no SPED validando apenas chaves listadas nas saídas
    WHERE
        c100_in.chv_nfe IN (
            SELECT DISTINCT
                chave_nfe_ultima_entrada
            FROM SAIDAS_RESSARCIMENTO
            WHERE
                chave_nfe_ultima_entrada IS NOT NULL
        )
    GROUP BY
        c100_in.chv_nfe,
        c170_in.cod_item
),

-- 6. Tabela fato de NFe Detalhe enxuta: trazemos dados massivos restritos ao universo já avaliado
XML_ENTRADA AS (
    SELECT
        nfe_ent.chave_acesso,
        nfe_ent.seq_nitem,
        nfe_ent.prod_xprod AS xml_descricao_item_entrada,
        nfe_ent.prod_ncm AS xml_ncm_entrada,
        nfe_ent.prod_cest AS xml_cest_entrada,
        nfe_ent.icms_vicms AS xml_icms_vicms_entrada
    FROM bi.fato_nfe_detalhe nfe_ent
    WHERE
        nfe_ent.co_iddest = 2 -- 2: Operação interestadual
        AND nfe_ent.co_uf_dest = 'RO' -- Destino Final: Rondônia
        AND nfe_ent.co_uf_emit <> 'RO' -- Emitente de outro Estado
        AND nfe_ent.chave_acesso IN (
            SELECT DISTINCT
                chave_nfe_ultima_entrada
            FROM SAIDAS_RESSARCIMENTO
            WHERE
                chave_nfe_ultima_entrada IS NOT NULL
        )
)

-- 7. Junção Final e Amigável de todos os blocos já pré-filtrados (Evita Multi-Joins e Cartesianos Ocultos)
SELECT
    TO_CHAR(s.comp_efd, 'MM/YYYY') AS periodo_efd,
    CASE s.cod_fin_efd
        WHEN '0' THEN '0 - Original'
        WHEN '1' THEN '1 - Substituto'
        ELSE TO_CHAR(s.cod_fin_efd)
    END AS finalidade_efd,
    s.chave_saida,
    s.num_nf_saida,
    CASE
        WHEN s.dt_doc IS NOT NULL
        AND REGEXP_LIKE (s.dt_doc, '^\d{8}$') THEN TO_DATE(s.dt_doc, 'DDMMYYYY')
        ELSE NULL
    END AS dt_emissao_saida,
    s.num_item_saida,
    s.cod_item,
    p.cod_barra,
    p.descr_item,
    p.cod_ncm,
    p.cest,
    s.descricao_item,
    s.qtd_saida,
    s.vl_total_item_saida,
    s.cod_mot_res,
    CASE s.cod_mot_res
        WHEN '1' THEN '1 - Saida para outra UF'
        WHEN '2' THEN '2 - Isencao ou nao incidencia'
        WHEN '3' THEN '3 - Perda ou deterioracao'
        WHEN '4' THEN '4 - Furto ou roubo'
        WHEN '5' THEN '5 - Exportacao'
        WHEN '6' THEN '6 - Venda interna p/ Simples Nacional'
        WHEN '9' THEN '9 - Outros'
        ELSE s.cod_mot_res
    END AS descricao_motivo_ressarcimento,
    s.chave_nfe_ultima_entrada,
    ie.num_item_ult_entr,
    CASE
        WHEN s.dt_ult_e IS NOT NULL
        AND REGEXP_LIKE (s.dt_ult_e, '^\d{8}$') THEN TO_DATE(s.dt_ult_e, 'DDMMYYYY')
        ELSE NULL
    END AS dt_ultima_entrada,
    s.vl_unit_bc_st_entrada,
    s.vl_unit_icms_proprio_entrada,
    s.vl_unit_ressarcimento_st,
    xmle.xml_descricao_item_entrada,
    xmle.xml_ncm_entrada,
    xmle.xml_cest_entrada,
    (
        NVL (s.qtd_saida, 0) * NVL (
            s.vl_unit_icms_proprio_entrada,
            0
        )
    ) AS sped_vl_ressarc_credito_proprio,
    xmle.xml_icms_vicms_entrada,
    (
        NVL (s.qtd_saida, 0) * NVL (
            s.vl_unit_icms_proprio_entrada,
            0
        )
    ) - NVL (
        xmle.xml_icms_vicms_entrada,
        0
    ) AS diferenca_sped_xml,
    CASE
        WHEN xmle.chave_acesso IS NULL THEN 'XML NÃO ENCONTRADO/FORA DO FILTRO'
        WHEN ROUND(
            (
                NVL (s.qtd_saida, 0) * NVL (
                    s.vl_unit_icms_proprio_entrada,
                    0
                )
            ),
            2
        ) = ROUND(
            NVL (
                xmle.xml_icms_vicms_entrada,
                0
            ),
            2
        ) THEN 'VALORES IGUAIS'
        ELSE 'VALORES DIVERGENTES'
    END AS status_comparacao_icms,
    (
        NVL (s.qtd_saida, 0) * NVL (s.vl_unit_ressarcimento_st, 0)
    ) AS vl_ressarc_st_retido,
    CASE
        WHEN NVL (s.vl_icms, 0) > 0 THEN (
            s.qtd_saida * s.vl_unit_ressarcimento_st
        ) + (
            s.qtd_saida * s.vl_unit_icms_proprio_entrada
        )
        ELSE (
            s.qtd_saida * s.vl_unit_ressarcimento_st
        )
    END AS vr_total_ressarcimento
FROM
    SAIDAS_RESSARCIMENTO s
    LEFT JOIN PRODUTOS p ON s.reg_0000_id = p.reg_0000_id
    AND s.cod_item = p.cod_item
    LEFT JOIN ITENS_ENTRADA_SPED ie ON s.chave_nfe_ultima_entrada = ie.chv_nfe
    AND s.cod_item = ie.cod_item
    LEFT JOIN XML_ENTRADA xmle ON s.chave_nfe_ultima_entrada = xmle.chave_acesso
    AND ie.num_item_ult_entr = xmle.seq_nitem
ORDER BY s.comp_efd, dt_emissao_saida, s.num_nf_saida, s.num_item_saida;
