-- ==============================================================================================
-- QUERY: Identificação de Arquivos EFD Válidos (Versão Corrigida)
-- OBJETIVO: Retornar o arquivo ativo (Original ou Retificador mais recente) para um período,
--           respeitando uma data de corte para simulação de cenários passados.
-- BANCO DE DADOS: Oracle SQL (sintaxe compatível)
-- ==============================================================================================

WITH PARAMETROS AS (
    -- Padronização dos inputs do usuário
    SELECT 
        :CNPJ AS cnpj_filtro,
        TO_DATE(:data_inicial, 'DD/MM/YYYY') AS dt_ini_filtro,
        TO_DATE(:data_final, 'DD/MM/YYYY')   AS dt_fim_filtro,
        -- Se a data limite for nula, assume hoje (visão atual)
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte
    FROM dual
),

TODOS_ARQUIVOS_VALIDOS AS (
    SELECT 
        dm.REG_0000_ID AS reg_0000_id,
        dm.DA_INICIO_ARQUIVO AS dt_ini,
        dm.DA_FINAL_ARQUIVO AS dt_fin,
        dm.CO_CNPJ_CPF_DECLARANTE AS cnpj,
        dm.DA_ENTREGA_ARQUIVO AS data_entrega,
        dm.IN_CODIGO_FINALIDADE,
        
        -- CORREÇÃO: Uso de aspas simples para literais de texto
        CASE 
            WHEN dm.IN_CODIGO_FINALIDADE = 0 THEN '0 - Remessa do arquivo original'
            WHEN dm.IN_CODIGO_FINALIDADE = 1 THEN '1 - Remessa do arquivo substituto'
            ELSE 'Outros'    
        END AS desc_finalidade,
        
        -- Colunas de controle trazidas do CTE Parametros para filtro posterior
        p.dt_corte, 
        p.dt_ini_filtro, 
        p.dt_fim_filtro,
        
        -- Lógica de Versionamento:
        -- Particiona por Empresa e Mês de Referência (dt_inicio)
        -- Ordena por Data de Entrega decrescente (o mais recente fica com rn=1)
        ROW_NUMBER() OVER (
            PARTITION BY dm.CO_CNPJ_CPF_DECLARANTE, dm.DA_INICIO_ARQUIVO 
            ORDER BY dm.DA_ENTREGA_ARQUIVO DESC
        ) AS rn
        
    FROM BI.DM_EFD_ARQUIVO_VALIDO dm
    JOIN PARAMETROS p ON dm.CO_CNPJ_CPF_DECLARANTE = p.cnpj_filtro
    WHERE 
        -- Filtro de "Viagem no Tempo": Ignora retificações feitas após a data de corte
        dm.DA_ENTREGA_ARQUIVO <= p.dt_corte
)

-- Seleção Final: Apenas o arquivo "Vencedor" (rn = 1) dentro do período filtrado
SELECT 
    reg_0000_id,
    cnpj,
    dt_ini,
    dt_fin,
    data_entrega,
    desc_finalidade,
    --IN_CODIGO_FINALIDADE,
    dt_corte AS data_limite_processamento
FROM TODOS_ARQUIVOS_VALIDOS
WHERE rn = 1 
  AND dt_ini BETWEEN dt_ini_filtro AND dt_fim_filtro
ORDER BY dt_ini;