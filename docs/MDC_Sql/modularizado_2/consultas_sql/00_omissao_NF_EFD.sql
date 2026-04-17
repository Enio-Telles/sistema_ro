-- ==========================================================================================
-- RELATÓRIO CONSOLIDADO: NOTAS FISCAIS EMITIDAS/RECEBIDAS AUSENTES NO SPED
-- COM IDENTIFICAÇÃO DE FLUXO (ENTRADA/SAÍDA)
-- ==========================================================================================

WITH PARAMETROS AS (
    SELECT
        :cnpj AS cnpj_filtro,
        TO_DATE(:data_inicial, 'DD/MM/YYYY') AS dt_ini_filtro,
        TO_DATE(:data_final, 'DD/MM/YYYY') AS dt_fim_filtro,
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte
    FROM dual
),

-- 1. Último arquivo válido por período (agregação antecipada)
ULTIMO_ARQUIVO_POR_PERIODO AS (
    SELECT /*+ MATERIALIZE */
        r.id AS reg_0000_id,
        r.cnpj,
        r.dt_ini,
        r.dt_fin
    FROM (
        SELECT
            id, cnpj, dt_ini, dt_fin,
            ROW_NUMBER() OVER (PARTITION BY cnpj, dt_ini ORDER BY data_entrega DESC) AS rn
        FROM sped.reg_0000
        CROSS JOIN PARAMETROS p
        WHERE cnpj = p.cnpj_filtro
          AND data_entrega <= p.dt_corte
          AND dt_ini <= p.dt_fim_filtro
          AND dt_fin >= p.dt_ini_filtro
    ) r
    WHERE r.rn = 1
),

-- 2. Chaves do SPED (único acesso ao reg_c100)
CHAVES_SPED AS (
    SELECT
        c100.chv_nfe
    FROM ULTIMO_ARQUIVO_POR_PERIODO arq
    INNER JOIN sped.reg_c100 c100
        ON c100.reg_0000_id = arq.reg_0000_id
    WHERE c100.chv_nfe IS NOT NULL
),

-- 3. NFe emitidas (Modelo 55) com Lógica de Entrada/Saída
CHAVES_NFE AS (
    -- Parte 3.1: Emitente (Quando o CNPJ Filtro é quem emitiu)
    SELECT
        d.chave_acesso,
        d.dhemi AS dt_emissao,
        d.dhsaient AS dt_e_s,
        d.co_emitente,      -- Necessário para validação visual se quiser
        d.co_destinatario,  -- Necessário para validação visual se quiser
        d.co_tp_nf,
        -- Lógica de entrada/saída considerando tipo de NF
        CASE
            WHEN d.co_destinatario = p.cnpj_filtro AND d.co_tp_nf = 1 THEN 'ENTRADA'
            WHEN d.co_destinatario = p.cnpj_filtro AND d.co_tp_nf = 0 THEN 'ENTRADA'
            WHEN d.co_emitente     = p.cnpj_filtro AND d.co_tp_nf = 0 THEN 'ENTRADA'
            WHEN d.co_emitente     = p.cnpj_filtro AND d.co_tp_nf = 1 THEN 'SAÍDA'
            ELSE 'DESCONHECIDO'
        END AS entrada_saida
    FROM bi.fato_nfe_detalhe d
    CROSS JOIN PARAMETROS p
    WHERE d.infprot_cstat IN ('100', '150')
      AND d.co_emitente = p.cnpj_filtro
      AND GREATEST(d.dhemi, NVL(d.dhsaient, d.dhemi)) >= p.dt_ini_filtro
      AND d.dhemi <= p.dt_fim_filtro
      AND NOT EXISTS (
          SELECT 1
          FROM CHAVES_SPED s
          WHERE s.chv_nfe = d.chave_acesso
      )

    UNION

    -- Parte 3.2: Destinatário (Quando o CNPJ Filtro é quem recebeu)
    SELECT
        d.chave_acesso,
        d.dhemi AS dt_emissao,
        d.dhsaient AS dt_e_s,
        d.co_emitente,
        d.co_destinatario,
        d.co_tp_nf,
        -- Lógica de entrada/saída considerando tipo de NF
        CASE
            WHEN d.co_destinatario = p.cnpj_filtro AND d.co_tp_nf = 1 THEN 'ENTRADA'
            WHEN d.co_destinatario = p.cnpj_filtro AND d.co_tp_nf = 0 THEN 'ENTRADA'
            WHEN d.co_emitente     = p.cnpj_filtro AND d.co_tp_nf = 0 THEN 'ENTRADA'
            WHEN d.co_emitente     = p.cnpj_filtro AND d.co_tp_nf = 1 THEN 'SAÍDA'
            ELSE 'DESCONHECIDO'
        END AS entrada_saida
    FROM bi.fato_nfe_detalhe d
    CROSS JOIN PARAMETROS p
    WHERE d.infprot_cstat IN ('100', '150')
      AND d.co_destinatario = p.cnpj_filtro
      AND GREATEST(d.dhemi, NVL(d.dhsaient, d.dhemi)) >= p.dt_ini_filtro
      AND d.dhemi <= p.dt_fim_filtro
      AND NOT EXISTS (
          SELECT 1
          FROM CHAVES_SPED s
          WHERE s.chv_nfe = d.chave_acesso
      )
),

-- 4. NFCe emitidas (Modelo 65)
-- Geralmente NFCe é sempre Saída (Venda a Consumidor), mas mantivemos a estrutura.
CHAVES_NFCE AS (
    SELECT
        d.chave_acesso,
        d.dhemi AS dt_emissao,
        CAST(NULL AS DATE) AS dt_e_s,
        d.co_emitente,
        NULL AS co_destinatario, -- NFCe muitas vezes não tem destinatário identificado ou é CPF
        d.co_tp_nf,
        -- Lógica de entrada/saída considerando tipo de NF
        CASE
            WHEN d.co_destinatario = p.cnpj_filtro AND d.co_tp_nf = 1 THEN 'ENTRADA'
            WHEN d.co_destinatario = p.cnpj_filtro AND d.co_tp_nf = 0 THEN 'ENTRADA'
            WHEN d.co_emitente     = p.cnpj_filtro AND d.co_tp_nf = 0 THEN 'ENTRADA'
            WHEN d.co_emitente     = p.cnpj_filtro AND d.co_tp_nf = 1 THEN 'SAÍDA'
            ELSE 'DESCONHECIDO'
        END AS entrada_saida
    FROM bi.fato_nfce_detalhe d
    CROSS JOIN PARAMETROS p
    WHERE d.infprot_cstat IN ('100', '150')
      AND d.co_emitente = p.cnpj_filtro
      AND d.dhemi BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
      AND NOT EXISTS (
          SELECT 1
          FROM CHAVES_SPED s
          WHERE s.chv_nfe = d.chave_acesso
      )
),

-- 5. União das chaves faltantes
CHAVES_FALTANTES AS (
    SELECT
        chave_acesso,
        dt_emissao,
        dt_e_s,
        co_emitente,
        co_destinatario,
        co_tp_nf,
        entrada_saida,
        'NFe' as modelo
    FROM CHAVES_NFE

    UNION

    SELECT
        chave_acesso,
        dt_emissao,
        dt_e_s,
        co_emitente,
        co_destinatario,
        co_tp_nf,
        entrada_saida,
        'NFCe' as modelo
    FROM CHAVES_NFCE
)
SELECT * FROM CHAVES_FALTANTES
ORDER BY CHAVE_ACESSO;
/*
CHAVE_MALHAS AS (
SELECT
c.*,
cf.referencia_malhas_id,
cf.malhas_id
FROM CHAVES_FALTANTES c
LEFT JOIN app_pendencia.vw_fisconforme_chave_nota cf ON c.chave_acesso = cf.chave_acesso)
SELECT * FROM CHAVE_MALHAS
*/
