-- ==========================================================================================
-- RELATÓRIO: APENAS CHAVES DE ACESSO NÃO ESCRITURADAS (FALTA NO SPED)
-- Objetivo: Listar somente as chaves de acesso (NFe/NFCe) que existem na base do governo
--           dentro do período filtrado, mas que NÃO foram encontradas na VERSÃO VÁLIDA
--           dos arquivos SPED entregues até a data limite de processamento.
-- ==========================================================================================

WITH PARAMETROS AS (
    SELECT
        :cnpj AS cnpj_filtro,
        TO_DATE(:data_inicial, 'DD/MM/YYYY') AS dt_ini_filtro,
        TO_DATE(:data_final, 'DD/MM/YYYY')   AS dt_fim_filtro,
        -- Define até quando considerar os arquivos SPED enviados.
        -- Se nulo, considera até hoje (SYSDATE).
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte
    FROM dual
),

-- 1. Mapeia os Arquivos Válidos (Última Retificação) até a data de corte
--    Se houver retificadora, pega apenas a mais recente entregue até o limite definido.
ARQUIVOS_VALIDOS_ATE_CORTE AS (
    SELECT
        r.id AS reg_0000_id,
        r.cnpj,
        r.dt_ini,
        r.data_entrega,
        -- Rankeia por data de entrega decrescente para o mesmo período (dt_ini) e CNPJ
        ROW_NUMBER() OVER (
            PARTITION BY r.cnpj, r.dt_ini
            ORDER BY r.data_entrega DESC
        ) AS rn
    FROM sped.reg_0000 r
    INNER JOIN PARAMETROS p ON r.cnpj = p.cnpj_filtro
    WHERE r.data_entrega <= p.dt_corte
),

-- 2. Mapeia TODAS as chaves presentes APENAS nos arquivos válidos filtrados acima
--    Isso ignora chaves presentes em arquivos retificados (obsoletos).
CHAVES_NO_SPED AS (
    SELECT DISTINCT c100.chv_nfe
    FROM sped.reg_c100 c100
    INNER JOIN ARQUIVOS_VALIDOS_ATE_CORTE arq ON c100.reg_0000_id = arq.reg_0000_id
    WHERE c100.chv_nfe IS NOT NULL
      AND arq.rn = 1 -- FILTRO CRUCIAL: Garante que olhamos apenas para a versão final do arquivo
),

-- 3. Mapeia as chaves esperadas (Base do Governo - BI) dentro do período
CHAVES_NO_GOVERNO AS (
    -- Notas Fiscais Eletrônicas (Modelo 55)
    SELECT
        d.chave_acesso AS chv_nfe
    FROM bi.fato_nfe_detalhe d
    INNER JOIN PARAMETROS p ON 1=1
    WHERE (d.co_emitente = p.cnpj_filtro OR d.co_destinatario = p.cnpj_filtro)
      AND d.infprot_cstat IN ('100', '150') -- Apenas notas autorizadas
      -- Filtra pela data efetiva (Maior data entre Emissão e Saída/Entrada)
      AND GREATEST(d.dhemi, NVL(d.dhsaient, d.dhemi)) BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro

    UNION ALL

    -- Notas Fiscais de Consumidor (Modelo 65)
    SELECT
        d.chave_acesso AS chv_nfe
    FROM bi.fato_nfce_detalhe d
    INNER JOIN PARAMETROS p ON d.co_emitente = p.cnpj_filtro
    WHERE d.infprot_cstat IN ('100', '150') -- Apenas notas autorizadas
      AND d.dhemi BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
)

-- 4. Operação Final: Governo MENOS Sped
--    Retorna apenas as chaves que estão na lista do Governo mas NÃO estão na lista do SPED Válido
SELECT chv_nfe
FROM CHAVES_NO_GOVERNO
WHERE chv_nfe NOT IN (SELECT chv_nfe FROM CHAVES_NO_SPED)

ORDER BY chv_nfe;
