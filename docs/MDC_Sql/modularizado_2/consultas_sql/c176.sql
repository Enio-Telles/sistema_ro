WITH
    PARAMETROS AS (
        SELECT
:CNPJ AS cnpj_filtro,
            -- Permite datas nulas: Se vazio, busca desde o início dos tempos (01/01/1900)
            NVL (
                TO_DATE(:data_inicial, 'DD/MM/YYYY'),
                TO_DATE('01/01/1900', 'DD/MM/YYYY')
            ) AS dt_ini_filtro,
            -- Se vazio, busca até a data atual
            NVL (
                TO_DATE(:data_final, 'DD/MM/YYYY'),
                TRUNC(SYSDATE)
            ) AS dt_fim_filtro,
            -- Data de Corte (Viagem no Tempo): Define qual era a versão "ativa" do arquivo naquela data
            NVL (
                TO_DATE(
:data_limite_processamento,
                    'DD/MM/YYYY'
                ),
                TRUNC(SYSDATE)
            ) AS dt_corte
        FROM dual
    ),
    ARQUIVOS_RANKING AS (
        /* Lógica de Versionamento: Seleciona o arquivo EFD mais recente entregue até a data de corte.
        Isso garante que, se um arquivo foi retificado, usaremos a versão correta.
        */
        SELECT
            reg_0000.id AS reg_0000_id,
            reg_0000.cnpj,
            reg_0000.cod_fin AS cod_fin_efd,
            reg_0000.dt_ini,
            reg_0000.data_entrega,
            ROW_NUMBER() OVER (
                PARTITION BY
                    reg_0000.cnpj,
                    reg_0000.dt_ini
                ORDER BY reg_0000.data_entrega DESC, reg_0000.id DESC
            ) AS rn
        FROM sped.reg_0000 reg_0000
            JOIN PARAMETROS p ON reg_0000.cnpj = p.cnpj_filtro
        WHERE
            reg_0000.data_entrega <= p.dt_corte
            AND reg_0000.dt_ini BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
    )

SELECT
    -------------------------------------------------------------------------
    -- BLOCO 0: IDENTIFICAÇÃO DO ARQUIVO (ORIGEM DOS DADOS)
    -------------------------------------------------------------------------
    TO_CHAR(arq.dt_ini, 'MM/YYYY') AS periodo_efd,
    --arq.data_entrega AS data_entrega_efd_periodo,
    CASE arq.cod_fin_efd
        WHEN '0' THEN '0 - Original'
        WHEN '1' THEN '1 - Substituto'
        ELSE TO_CHAR(arq.cod_fin_efd)
    END AS finalidade_efd,

-------------------------------------------------------------------------
-- REGISTRO C100: DADOS DO DOCUMENTO FISCAL DE SA�?DA (PAI DO C170)
-------------------------------------------------------------------------
c100.chv_nfe AS chave_saida, -- Chave da NF-e que gerou o direito ao ressarcimento
c100.num_doc AS num_nf_saida,
CASE
    WHEN c100.dt_doc IS NOT NULL
    AND REGEXP_LIKE (c100.dt_doc, '^\d{8}$') THEN TO_DATE(c100.dt_doc, 'DDMMYYYY')
    ELSE NULL
END AS dt_emissao_saida,

-------------------------------------------------------------------------
-- REGISTRO C170: ITENS DO DOCUMENTO (PAI DO C176)
-------------------------------------------------------------------------
c170.num_item,
c170.cod_item,
c170.descr_compl AS descricao_item,
c170.qtd AS qtd_saida, -- Quantidade do item na nota de saída/ajuste
c170.vl_item AS vl_total_item,
C176.cod_mot_res,
CASE C176.cod_mot_res
    WHEN '1' THEN '1 - Saida para outra UF'
    WHEN '2' THEN '2 - Isencao ou nao incidencia'
    WHEN '3' THEN '3 - Perda ou deterioracao'
    WHEN '4' THEN '4 - Furto ou roubo'
    WHEN '5' THEN '5 - Exportacao'
    WHEN '6' THEN '6 - Venda interna p/ Simples Nacional'
    WHEN '9' THEN '9 - Outros'
    ELSE C176.cod_mot_res
END AS descricao_motivo_ressarcimento,

-------------------------------------------------------------------------
-- REGISTRO C176: RESSARCIMENTO DE ICMS ST (DETALHAMENTO DA ENTRADA)
-- Baseado no Guia Prático EFD - Bloco C
-------------------------------------------------------------------------

-- Campo 04: Chave da NF-e da última entrada da mercadoria
c176.chave_nfe_ult AS chave_nfe_ultima_entrada,

-- Campo 06: Data da última entrada (necessário para identificar a vigência da base de cálculo)
CASE
    WHEN c176.dt_ult_e IS NOT NULL
    AND REGEXP_LIKE (c176.dt_ult_e, '^\d{8}$') THEN TO_DATE(c176.dt_ult_e, 'DDMMYYYY')
    ELSE NULL
END AS dt_ultima_entrada,

-- Campo 08: Valor unitário da base de cálculo do ICMS ST na última entrada
c176.vl_unit_ult_e AS vl_unit_bc_st_entrada,

-- Campo 11: Valor unitário do ICMS suportado pelo contribuinte (ICMS Operação Própria do Fornecedor)
c176.vl_unit_icms_ult_e AS vl_unit_icms_proprio_entrada,

-- Campo 16: Valor unitário do ressarcimento (Valor do ICMS ST retido na entrada)
c176.vl_unit_res AS vl_unit_ressarcimento_st,

-------------------------------------------------------------------------
-- C�?LCULOS DE APOIO (CONFORME REGRAS DE RESSARCIMENTO)
-------------------------------------------------------------------------

-- Cálculo do Crédito de ICMS Próprio (Qtd Saída * ICMS Unitário da Entrada)
(
    NVL (c170.qtd, 0) * NVL (c176.vl_unit_icms_ult_e, 0)
) AS vl_ressarc_credito_proprio,

-- Cálculo do Ressarcimento ST (Qtd Saída * ST Unitário da Entrada)
(
    NVL (c170.qtd, 0) * NVL (c176.vl_unit_res, 0)
) AS vl_ressarc_st_retido,

-- Valor Total do Direito (Soma do ICMS Próprio + ST Retido, se houver débito na saída)
CASE
    WHEN NVL (c170.vl_icms, 0) > 0 THEN (c170.qtd * c176.vl_unit_res) + (
        c170.qtd * c176.vl_unit_icms_ult_e
    )
    ELSE (c170.qtd * c176.vl_unit_res)
END AS vr_total_ressarcimento
FROM
    sped.reg_c176 c176
    INNER JOIN ARQUIVOS_RANKING arq ON c176.reg_0000_id = arq.reg_0000_id
    INNER JOIN sped.reg_c100 c100 ON c176.reg_c100_id = c100.id
    INNER JOIN sped.reg_c170 c170 ON c176.reg_c170_id = c170.id
WHERE
    arq.rn = 1 -- Garante apenas o arquivo vigente
ORDER BY arq.dt_ini, dt_emissao_saida, c100.num_doc;

-- VERIFICAR
-- (i) se saída é motivo de ressarcimento
