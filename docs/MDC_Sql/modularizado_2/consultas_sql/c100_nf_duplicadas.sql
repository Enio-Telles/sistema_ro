-- ============================================================================
-- SCRIPT: Verificação de Duplicidade de Notas Fiscais (Nível C100 - Cabeçalho)
-- ============================================================================
-- OBJETIVO: 
-- 1. Identificar se a mesma CHAVE DE NFE (chv_nfe) foi escriturada mais de uma vez.
-- 2. Isso pode ocorrer por erro de escrituração (lançar 2x) ou duplicidade
--    entre arquivos de períodos diferentes (ex: lançada em Jan e Fev).
-- ============================================================================

WITH PARAMETROS AS (
    SELECT 
        :CNPJ AS cnpj_alvo,
        TO_DATE(:inicio, 'DD/MM/YYYY') AS dt_ini_filtro,
        TO_DATE(:fim, 'DD/MM/YYYY')    AS dt_fim_filtro,
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte
    FROM dual
),

-- 1. Seleção dos Arquivos Válidos (Mesma lógica robusta dos anteriores)
ARQUIVOS_RANKEADOS AS (
    SELECT 
        r.id AS reg_0000_id,
        r.dt_ini,
        r.dt_fin,
        r.data_entrega,
        r.cod_fin,
        ROW_NUMBER() OVER (
            PARTITION BY r.cnpj, r.dt_ini 
            ORDER BY r.data_entrega DESC
        ) AS rn
    FROM sped.reg_0000 r
    JOIN PARAMETROS p ON r.cnpj = p.cnpj_alvo
    WHERE r.data_entrega <= p.dt_corte
      AND r.dt_ini BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
),

ARQUIVOS_VALIDOS AS (
    SELECT reg_0000_id AS id_arquivo, dt_ini, dt_fin, data_entrega, cod_fin
    FROM ARQUIVOS_RANKEADOS
    WHERE rn = 1
),

-- 2. Extração e Contagem de Notas
DADOS_NOTAS AS (
    SELECT
        -- Dados de Origem para Rastreabilidade
        av.dt_ini AS periodo_apuracao_arquivo,
        TO_CHAR(av.dt_ini, 'MM/YYYY') AS mes_ref,
        
        -- Dados da Nota
        c100.chv_nfe,
        c100.num_doc,
        c100.ser,
        c100.dt_doc,
        c100.dt_e_s,
        c100.vl_doc,
        c100.ind_oper, -- 0-Entrada, 1-Saída
        c100.cod_sit,  -- 00-Regular, 02-Cancelada, etc.
        c100.cod_part,
        
        -- Contagem: Quantas vezes essa chave aparece neste universo de arquivos válidos?
        COUNT(*) OVER (PARTITION BY c100.chv_nfe) AS qtd_ocorrencias_chave

    FROM sped.reg_c100 c100
    INNER JOIN ARQUIVOS_VALIDOS av ON av.id_arquivo = c100.reg_0000_id
    
    WHERE c100.chv_nfe IS NOT NULL 
      AND LENGTH(TRIM(c100.chv_nfe)) = 44 -- Garante que é uma chave válida de NFe/NFCe
)

-- 3. Filtro Final: Exibe apenas as duplicadas
SELECT 
    qtd_ocorrencias_chave AS "Qtd Repetições",
    chv_nfe               AS "Chave NFe",
    num_doc               AS "Número Doc",
    ser                   AS "Série",
    cod_part              AS "Cód. Participante",
    ind_oper              AS "Operação (0-E/1-S)",
    cod_sit               AS "Situação",
    periodo_apuracao_arquivo,
    dt_doc,
    vl_doc
FROM DADOS_NOTAS
WHERE qtd_ocorrencias_chave > 1
ORDER BY chv_nfe, dt_doc;