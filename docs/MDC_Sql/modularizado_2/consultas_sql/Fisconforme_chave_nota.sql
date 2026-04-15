/* ==========================================================================
   NOME: Consulta de Chaves e Pendências Fiscais (Otimizada)
   DESCRIÇÃO: Retorna chaves de acesso, status das malhas e resoluções
              filtradas por Contribuinte e Período.
   
   MELHORIAS DE PERFORMANCE:
   1. CTE 'PENDENCIA_DO_CONTRIBUINTE': Aplica filtro de CNPJ antes do JOIN.
   2. Deduplicação Antecipada: Usa ROW_NUMBER() na subquery reduzida.
   3. Filtro de Datas: Movido para o WHERE principal para evitar leitura inútil.
   ========================================================================== */

WITH 
--------------------------------------------------------------------------------
-- 1. CTE DE PARAMETROS
-- Objetivo: Centralizar as variáveis (:cnpj, :data) e formatá-las uma única vez.
-- Isso evita chamadas repetitivas de conversão (TO_CHAR/TO_DATE) nas linhas.
--------------------------------------------------------------------------------
PARAMETROS AS (
    SELECT 
        :cnpj AS cnpj_filtro,
        -- Converte DD/MM/YYYY para YYYYMM (formato numérico/texto de comparação rápida)
        TO_CHAR(TO_DATE(:data_inicial, 'DD/MM/YYYY'), 'YYYYMM') AS p_ini_yyyymm,
        TO_CHAR(TO_DATE(:data_final,   'DD/MM/YYYY'), 'YYYYMM') AS p_fim_yyyymm
    FROM dual
),

--------------------------------------------------------------------------------
-- 2. CTE PENDENCIA_DO_CONTRIBUINTE (O "Coração" da Otimização)
-- Problema anterior: A query lia TODA a tabela de pendências antes de filtrar.
-- Solução: Filtramos pelo CNPJ aqui dentro. O banco processa um dataset minúsculo.
--------------------------------------------------------------------------------
PENDENCIA_DO_CONTRIBUINTE AS (
    SELECT 
        p.referencia_malhas_id,
        p.malhas_id,
        p.status,
        -- ROW_NUMBER: Cria um ranking para identificar a pendência mais recente
        -- PARTITION BY: Reinicia a contagem para cada par (Referência + Malha)
        -- ORDER BY ... DESC: Garante que o número 1 seja o registro mais novo
        ROW_NUMBER() OVER (
            PARTITION BY p.referencia_malhas_id, p.malhas_id 
            ORDER BY p.id DESC
        ) AS rn
    FROM app_pendencia.pendencias p
    -- Join com parâmetros para garantir que só buscamos dados deste CNPJ
    INNER JOIN PARAMETROS param ON 1=1 
    WHERE p.cpf_cnpj = param.cnpj_filtro -- <--- OTIMIZAÇÃO CRÍTICA (Pushdown Predicate)
)

--------------------------------------------------------------------------------
-- 3. SELECT PRINCIPAL
-- Consolida os dados da View principal com as tabelas de domínio.
--------------------------------------------------------------------------------
SELECT 
    chv.chave_acesso,
    chv.referencia_malhas_id,
    chv.malhas_id,
    m.titulo AS descricao_malha,
    rm.periodo,
    
    -- Tradução do Status Numérico para Texto Legível
    -- O COALESCE garante que se não houver pendência (NULL), mostra '0 - pendente'
    CASE COALESCE(pu.status, 0)
        WHEN 0 THEN '0 - pendente'
        WHEN 1 THEN '1 - contestado'
        WHEN 2 THEN '2 - resolvido'
        WHEN 3 THEN '3 - acao fiscal'
        WHEN 4 THEN '4 - pendente indeferido'
        WHEN 5 THEN '5 - deferido'
        WHEN 6 THEN '6 - notificado'
        WHEN 7 THEN '7 - deferido automaticamente'
        ELSE TO_CHAR(pu.status)
    END AS status_descricao,

    rm.resolucao

FROM app_pendencia.vw_fisconforme_chave_nota chv

-- Traz os parâmetros para o contexto principal (sem custo, pois é 1 linha)
CROSS JOIN PARAMETROS param

-- JOIN 1: Referência de Malhas (Períodos)
-- Mudado para INNER JOIN. Se a chave não tem período válido na tabela referência,
-- ela não deve aparecer num relatório temporal.
INNER JOIN app_pendencia.referencia_malhas rm 
       ON rm.id = chv.referencia_malhas_id

-- JOIN 2: Tabela de Malhas (Para pegar o Título)
-- Mantido LEFT JOIN caso existam malhas históricas deletadas ou IDs órfãos
LEFT JOIN app_pendencia.malhas m 
       ON m.id = chv.malhas_id
       
-- JOIN 3: Pendências (Nossa CTE Otimizada)
-- Conecta apenas com o registro mais recente (rn = 1) daquele CNPJ
LEFT JOIN PENDENCIA_DO_CONTRIBUINTE pu 
       ON pu.referencia_malhas_id = chv.referencia_malhas_id
      AND pu.malhas_id = chv.malhas_id
      AND pu.rn = 1

--------------------------------------------------------------------------------
-- 4. FILTROS FINAIS
--------------------------------------------------------------------------------
WHERE 
    -- Filtra a View principal pelo CNPJ
    chv.cpf_cnpj = param.cnpj_filtro
    
    -- Lógica de Data:
    -- Garante que o período da malha esteja dentro do intervalo solicitado.
    -- O uso de "param.p_ini_yyyymm IS NULL OR ..." permite que os parâmetros
    -- sejam opcionais. Se o usuário não informar data, traz tudo.
    AND (param.p_ini_yyyymm IS NULL OR rm.periodo >= param.p_ini_yyyymm)
    AND (param.p_fim_yyyymm IS NULL OR rm.periodo <= param.p_fim_yyyymm)

--------------------------------------------------------------------------------
-- 5. ORDENAÇÃO
--------------------------------------------------------------------------------
ORDER BY 
    rm.periodo DESC NULLS LAST, -- Períodos mais recentes primeiro
    chv.chave_acesso;           -- Ordem secundária para facilitar leitura