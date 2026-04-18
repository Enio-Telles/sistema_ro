-- ============================================================================
-- SCRIPT: Verificação de Duplicidade (Chave NFe + Num Item)
-- ============================================================================
-- OBJETIVO:
-- 1. Filtrar arquivos válidos (mesma lógica do script anterior).
-- 2. Identificar itens duplicados (mesma nota, mesmo número de item).
-- 3. Retornar a linha completa para análise, sem descrições (apenas códigos).
-- ============================================================================

WITH PARAMETROS AS (
    SELECT
        :CNPJ AS cnpj_alvo,
        TO_DATE(:inicio, 'DD/MM/YYYY') AS dt_ini_filtro,
        TO_DATE(:fim, 'DD/MM/YYYY')    AS dt_fim_filtro,
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte
    FROM dual
),

-- 1. Seleção dos Arquivos Válidos (Evita falsos positivos de arquivos retificados)
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
    SELECT id_arquivo, dt_ini, dt_fin, data_entrega, cod_fin
    FROM (
        SELECT reg_0000_id AS id_arquivo, dt_ini, dt_fin, data_entrega, cod_fin, rn
        FROM ARQUIVOS_RANKEADOS
    )
    WHERE rn = 1
),

-- 2. Extração dos Dados Brutos (Apenas Tabelas Core: C170, C100, 0000)
DADOS_BRUTOS AS (
    SELECT
        -- Dados do Arquivo
        av.dt_ini AS periodo_apuracao,
        av.id_arquivo,

        -- Chave de Duplicidade Principal
        c100.chv_nfe,
        c170.num_item,

        -- Dados Informativos C100
        c100.dt_doc,
        c100.dt_e_s,
        c100.num_doc,
        c100.ser,
        c100.ind_oper,
        c100.ind_emit,
        c100.cod_part,
        c100.cod_sit,

        -- Dados Informativos C170
        c170.cod_item,
        c170.descr_compl,
        c170.qtd,
        c170.unid,
        c170.vl_item,
        c170.vl_desc,
        c170.cfop,
        c170.cst_icms,
        c170.aliq_icms,
        c170.vl_bc_icms,
        c170.vl_icms,
        c170.vl_bc_icms_st,
        c170.vl_icms_st,
        c170.cst_ipi,
        c170.vl_ipi,
        c170.cod_cta,

        -- Função de Janela para Contagem de Duplicidade
        -- Particiona por Chave da Nota e Número do Item
        COUNT(*) OVER (PARTITION BY c100.chv_nfe, c170.num_item) AS qtd_ocorrencias

    FROM sped.reg_c170 c170
    INNER JOIN ARQUIVOS_VALIDOS av ON av.id_arquivo = c170.reg_0000_id
    INNER JOIN sped.reg_c100 c100 ON c100.id = c170.reg_c100_id

    WHERE c100.chv_nfe IS NOT NULL -- Garante que estamos olhando notas eletrônicas
)

-- 3. Filtro Final: Retorna apenas o que tem duplicidade (>1)
SELECT *
FROM DADOS_BRUTOS
WHERE qtd_ocorrencias > 1
ORDER BY chv_nfe, num_item, periodo_apuracao;
