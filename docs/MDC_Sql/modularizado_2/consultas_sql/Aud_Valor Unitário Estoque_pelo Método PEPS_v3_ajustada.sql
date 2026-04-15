/* AUDITORIA DE VALOR UNITÁRIO DE ESTOQUE - MÉTODO PEPS (FIFO)
    
    OBJETIVO:
    Calcular o valor unitário do estoque final declarado (H010) comparando-o com 
    o valor praticado nas últimas entradas (C170), seguindo a lógica PEPS 
    (Primeiro a Entrar, Primeiro a Sair).
    
    PARÂMETROS:
    :CNPJ - CNPJ do contribuinte
    :data_inicial - Data inicial do período de análise das entradas
    :data_final - Data final do período (Define a data do Estoque Final em 31/12 do ano)
    :data_limite_processamento - Data de corte para considerar os arquivos EFD (simula a visão do fisco em determinada data)
    :cod_item - (Opcional) Código do item específico para filtrar
*/

WITH PARAMETROS AS (
    SELECT 
        :CNPJ AS cnpj_filtro,
        TO_DATE(:data_inicial, 'DD/MM/YYYY') AS dt_ini_filtro,
        TO_DATE(:data_final,   'DD/MM/YYYY') AS dt_fim_filtro,
        -- Se não informada data limite, usa a data atual
        NVL(TO_DATE(:data_limite_processamento, 'DD/MM/YYYY'), TRUNC(SYSDATE)) AS dt_corte,
        :cod_item AS cod_filtro -- Alias alterado para corresponder ao snippet ARQUIVOS_RANKING
    FROM dual
)

-- TRATAMENTOS DE CFOP
-- Define quais CFOPs geram crédito/valor agregado para compor o custo
,cfop_vaf AS (
    SELECT 
        1 AS ddd,    
        '' AS TODOS_CFOP -- 'SIM' para todos, ou vazio para filtrar apenas VAF
    FROM dual
)  

,CFOP_AJ AS (
    SELECT 
        co_cfop, 
        in_vaf, 
        CASE 
            WHEN TODOS_CFOP = 'SIM' THEN 'X'
            WHEN CO_CFOP IN ('') AND in_vaf IS NULL THEN 'X'
            WHEN CO_CFOP IN ('') AND in_vaf = 'X' THEN ''
            ELSE in_vaf 
        END AS in_vaf_aj 
    FROM bi.dm_cfop
    JOIN cfop_vaf ON cfop_vaf.ddd = 1   
)

-- SELEÇÃO DE ARQUIVOS VÁLIDOS (PADRÃO - RANKING)
-- Filtra apenas os arquivos EFD ativos na data de corte dentro do período de análise
,ARQUIVOS_RANKING AS (
    SELECT
        r.id AS reg_0000_id,
        r.cnpj,
        r.dt_ini,
        r.data_entrega,
        p.cod_filtro,
        ROW_NUMBER() OVER (
            PARTITION BY r.cnpj, r.dt_ini 
            ORDER BY r.data_entrega DESC
        ) AS rn
    FROM sped.reg_0000 r
    JOIN PARAMETROS p ON r.cnpj = p.cnpj_filtro
    WHERE 
        r.data_entrega <= p.dt_corte
        AND r.dt_ini BETWEEN p.dt_ini_filtro AND p.dt_fim_filtro
)

-- SELEÇÃO ESPECÍFICA PARA O ARQUIVO DE INVENTÁRIO
-- Como o inventário de 31/12 geralmente está no arquivo de Fev do ano seguinte,
-- ele pode estar fora do range da CTE ARQUIVOS_RANKING (que foca nas entradas do período).
,ARQUIVO_ESTOQUE_ID AS (
    SELECT reg_0000_id FROM (
        SELECT 
            r.id AS reg_0000_id,
            ROW_NUMBER() OVER (PARTITION BY r.cnpj, r.dt_ini ORDER BY r.data_entrega DESC) AS rn
        FROM sped.reg_0000 r
        JOIN PARAMETROS p ON r.cnpj = p.cnpj_filtro
        WHERE 
            -- Busca o arquivo que inicia aprox. em 01/02 do ano seguinte (padrão SPED para inventário)
            r.dt_ini = TO_DATE('31/12/' || TO_CHAR(p.dt_fim_filtro, 'YYYY'), 'dd/mm/yyyy') + 32
            AND r.data_entrega <= p.dt_corte
    ) WHERE rn = 1
)

-- BUSCA O ESTOQUE FINAL (H010)
,estoque_final AS (  
    SELECT                     
        replace(replace(replace(LTRIM(h010.cod_item, '0'), ' ',''), '.', ''),'-','') AS COD,                    
        r0200.DESCR_ITEM,
        h010.UNID,
        H010.VL_UNIT, 
        H010.VL_ITEM,
        h010.qtd AS QTDE                
    FROM sped.reg_h010 h010
    JOIN sped.reg_0000 r0000 ON h010.REG_0000_ID = r0000.id 
    JOIN sped.reg_0200 r0200 ON h010.cod_item = r0200.COD_ITEM AND r0200.REG_0000_ID = h010.REG_0000_ID        
    -- Join com a CTE específica de estoque para garantir o arquivo correto
    JOIN ARQUIVO_ESTOQUE_ID arq_est ON h010.REG_0000_ID = arq_est.reg_0000_id
    JOIN PARAMETROS p ON 1=1
    WHERE 
        (p.cod_filtro IS NULL OR replace(replace(replace(LTRIM(h010.cod_item, '0'), ' ',''), '.', ''),'-','') = p.cod_filtro)
)

-- Identifica itens duplicados no estoque (mesmo código aparecendo mais de uma vez)
,estoque_rept_cod AS (
    SELECT 
        ef.COD,                            
        COUNT(ef.COD) AS REPT_COD, 
        LISTAGG(DISTINCT ef.UNID, ', ') WITHIN GROUP (ORDER BY ef.UNID) AS UNID
    FROM estoque_final ef
    GROUP BY ef.COD
)

,estoque_ajustado AS (
    SELECT
        ef.COD,
        rc.REPT_COD,
        ef.DESCR_ITEM,
        rc.UNID,
        ef.VL_UNIT,
        ef.VL_ITEM,
        ef.QTDE                                
    FROM estoque_final ef
    JOIN estoque_rept_cod rc ON rc.cod = ef.cod                            
)

-- Busca notas fiscais (Entradas) para comparação na base NFe (para validação cruzada se necessário)
,NSU AS (
    SELECT NSU, CHAVE_ACESSO 
    FROM bi.fato_nfe_detalhe 
    JOIN PARAMETROS p ON 1=1
    WHERE (co_emitente = p.cnpj_filtro OR co_destinatario = p.cnpj_filtro)
        AND dhemi BETWEEN p.dt_ini_filtro - 120 AND p.dt_fim_filtro 
        AND INFPROT_CSTAT IN ('100','150')
        AND SEQ_NITEM = 1
)

-- ENTRADAS (C170)
-- Recupera as notas de compra para calcular o custo médio/PEPS
,ENTRADAS AS (
    SELECT 
        NVL(NSU.NSU, 0) AS NSU,
        c100.chv_nfe AS CHAVE_ACESSO,
        replace(replace(replace(LTRIM(c170.cod_item, '0'), ' ',''), '.', ''),'-','') AS COD,
        upper(r0200.descr_item) AS descricao,
        UNID,
        substr(c170.CFOP, 1, 4) AS CFOP,
        IN_VAF_AJ,
        (VL_ITEM - VL_DESC) AS VALOR, 
        QTD,
        CASE WHEN VL_ITEM = 0 THEN 0 ELSE QTD END AS QTDE_AJ,
        1 AS CONTAR_NF,
        CASE WHEN VL_ITEM = 0 THEN 0 ELSE 1 END AS CONTAR_NF_AJ 
    FROM sped.reg_c170 c170
    LEFT JOIN (SELECT id, chv_nfe FROM sped.reg_c100) c100 ON c170.REG_C100_ID = c100.id
    LEFT JOIN sped.reg_0000 r0000 ON c170.REG_0000_ID = r0000.id
    LEFT JOIN sped.reg_0200 r0200 ON (c170.cod_item = r0200.cod_item AND r0200.REG_0000_ID = r0000.id)
    -- Join com ARQUIVOS_RANKING garantindo apenas arquivos ativos (rn=1)
    JOIN ARQUIVOS_RANKING arq ON c170.REG_0000_ID = arq.reg_0000_id AND arq.rn = 1
    LEFT JOIN (SELECT CO_CFOP, nvl(IN_VAF_AJ, '-') AS IN_VAF_AJ FROM CFOP_AJ) CFOP ON substr(CFOP.CO_CFOP, 1, 4) = substr(c170.CFOP, 1, 4)
    LEFT JOIN NSU ON NSU.CHAVE_ACESSO = c100.chv_nfe
    JOIN PARAMETROS p ON 1=1
    WHERE 
        substr(c170.CFOP, 1, 1) IN ('1','2','3') -- Apenas entradas
        -- O filtro de data já está implícito em ARQUIVOS_RANKING, mas reforçamos pelo r0000 se necessário,
        -- porém ARQUIVOS_RANKING já garante o período.
        AND (SUBSTR(c170.CFOP, 2,3) NOT BETWEEN '200' AND '249' 
            OR SUBSTR(c170.CFOP, 2,3) NOT IN ('410','411','412','413','503','506','553','555','556','660','661','662','918','919'))
        AND (p.cod_filtro IS NULL OR replace(replace(replace(LTRIM(c170.cod_item, '0'), ' ',''), '.', ''),'-','') = p.cod_filtro)
)

-- CÁLCULO ACUMULADO (PEPS)
-- Ordena as entradas da mais recente para a mais antiga e acumula quantidades
,QTDE_ACUM_ULTIMAS_NF AS (
    SELECT 
        ET.COD, 
        ET.NSU, 
        ET.CHAVE_ACESSO, 
        ET.QTD AS QTDE_NF,
        ET.QTDE_AJ AS QTDE_NF_AJ,                        
        ET.VALOR,
        AJ.QTDE AS QTDE_EF,
        ET.UNID AS UNID_NF,
        CONTAR_NF,
        CONTAR_NF_AJ,
        CFOP,
        SUM(ET.QTD) OVER (PARTITION BY ET.COD ORDER BY ET.NSU DESC) AS QTDE_ACUM_ULTIMAS_NF,                        
        SUM(ET.QTD) OVER (PARTITION BY ET.COD ORDER BY ET.NSU DESC) - ET.QTD AS QTDE_ANTERIOR,                        
        SUM(ET.QTDE_AJ) OVER (PARTITION BY ET.COD ORDER BY ET.NSU DESC) AS QTDE_ACUM_ULTIMAS_NF_AJ,                        
        SUM(ET.QTDE_AJ) OVER (PARTITION BY ET.COD ORDER BY ET.NSU DESC) - ET.QTDE_AJ AS QTDE_ANTERIOR_AJ
    FROM ENTRADAS ET
    JOIN estoque_ajustado AJ ON AJ.COD = ET.COD                    
)

-- SELEÇÃO DA BASE DE CÁLCULO
-- Filtra apenas as notas necessárias para cobrir a quantidade do estoque final
,BASE_PEPS AS (
    SELECT 
        COD, NSU, CHAVE_ACESSO, QTDE_NF, QTDE_NF_AJ, VALOR, QTDE_EF,
        NVL2(NULLIF(CONTAR_NF_AJ, 0), UNID_NF, NULL) AS UNID_NF,
        CONTAR_NF, CONTAR_NF_AJ,
        (CONTAR_NF - CONTAR_NF_AJ) AS NF_ZERO_VALOR,
        NVL2(NULLIF(CONTAR_NF_AJ, 0), CFOP, NULL) AS CFOP,
        QTDE_ACUM_ULTIMAS_NF, QTDE_ANTERIOR, QTDE_ACUM_ULTIMAS_NF_AJ, QTDE_ANTERIOR_AJ,
        ROW_NUMBER() OVER (PARTITION BY COD, CHAVE_ACESSO ORDER BY NSU DESC) AS RN_DUPLICATA,
        COUNT(*) OVER (PARTITION BY COD, CHAVE_ACESSO) AS TOTAL_DUPLICATAS
    FROM QTDE_ACUM_ULTIMAS_NF 
    WHERE (QTDE_ACUM_ULTIMAS_NF_AJ <= QTDE_EF OR QTDE_ANTERIOR_AJ < QTDE_EF) 
        AND QTDE_ANTERIOR_AJ < QTDE_EF
)

,BASE_PEPS_DEDUPLICATED AS (
    SELECT 
        COD, NSU, CHAVE_ACESSO, QTDE_NF, QTDE_NF_AJ, VALOR, QTDE_EF,
        UNID_NF, CONTAR_NF, CONTAR_NF_AJ, NF_ZERO_VALOR, CFOP,
        QTDE_ACUM_ULTIMAS_NF, QTDE_ANTERIOR, QTDE_ACUM_ULTIMAS_NF_AJ, QTDE_ANTERIOR_AJ,
        CASE WHEN TOTAL_DUPLICATAS > 1 THEN TOTAL_DUPLICATAS - 1 ELSE 0 END AS QTD_DUPLICATAS_REMOVIDAS
    FROM BASE_PEPS
    WHERE RN_DUPLICATA = 1
)

-- RELATÓRIO DE DUPLICATAS
,VERIFICACAO_DUPLICATAS AS (
    SELECT 
        COD, CHAVE_ACESSO, (COUNT(*) - 1) AS QTD_DUPLICATAS_CHAVE
    FROM BASE_PEPS
    WHERE TOTAL_DUPLICATAS > 1
    GROUP BY COD, CHAVE_ACESSO
    HAVING COUNT(*) > 1
)

,DUPLICATAS_POR_COD AS (
    SELECT 
        COD,
        SUM(QTD_DUPLICATAS_CHAVE) AS TOTAL_DUPLICATAS,
        LISTAGG(CHAVE_ACESSO || ' (' || QTD_DUPLICATAS_CHAVE || 'x)', '; ') 
            WITHIN GROUP (ORDER BY CHAVE_ACESSO) AS DETALHES_DUPLICATAS
    FROM VERIFICACAO_DUPLICATAS
    GROUP BY COD
)

-- CÁLCULO FINAL DO VALOR UNITÁRIO PEPS
,VL_UNIT_PEPS AS (
    SELECT 
        bp.COD,                        
        ROUND(SUM(bp.VALOR) / REPLACE(SUM(bp.QTDE_NF_AJ), 0, 1), 2) AS V_UNIT_PEPS,
        MAX(bp.QTDE_ACUM_ULTIMAS_NF_AJ) || ' volume(s) (' ||
            LISTAGG(DISTINCT bp.UNID_NF, ', ') WITHIN GROUP (ORDER BY bp.UNID_NF) || '); apuração em ' || 
            SUM(bp.CONTAR_NF) || ' últimos registros de entrada' ||                        
            NVL2(NULLIF(SUM(bp.NF_ZERO_VALOR), 0), '; ' || SUM(bp.NF_ZERO_VALOR) || ' registro(s) com valor de entrada ZERADOS', NULL) ||
            NVL2(MAX(dc.TOTAL_DUPLICATAS), '; ?? DUPLICATAS: ' || MAX(dc.TOTAL_DUPLICATAS) || ' registro(s) duplicado(s) - Chaves: ' || MAX(dc.DETALHES_DUPLICATAS), NULL)
        AS APURACAO,
        LISTAGG(DISTINCT bp.CFOP, ', ') WITHIN GROUP (ORDER BY bp.CFOP) AS CFOP
    FROM BASE_PEPS_DEDUPLICATED bp
    LEFT JOIN DUPLICATAS_POR_COD dc ON dc.COD = bp.COD
    GROUP BY bp.COD                    
)

,BASE_COMANDO_FINAL AS (                   
    SELECT
        ef.COD,
        ef.REPT_COD,
        ef.DESCR_ITEM,
        ef.UNID,
        ef.QTDE,    
        ef.VL_ITEM, 
        ef.VL_UNIT AS VL_UNIT_EST,
        nvl(V_UNIT_PEPS, 0) AS V_UNIT_PEPS,
        ef.VL_UNIT * ef.QTDE AS VL_UNIT_X_QTDE,
        nvl(V_UNIT_PEPS, 0) * ef.QTDE AS VL_UNIT_PEPS_X_QTDE,
        (ef.VL_UNIT * ef.QTDE - nvl(V_UNIT_PEPS, 0) * ef.QTDE) AS DIF, 
        peps.APURACAO,
        peps.CFOP
    FROM estoque_ajustado ef
    JOIN VL_UNIT_PEPS peps ON peps.COD = ef.COD 
)

-- SAÍDA FINAL
SELECT 
    COD,
    REPT_COD,
    DESCR_ITEM,
    UNID,
    QTDE,    
    TO_CHAR(VL_ITEM, 'FM999G999G999G990D00') AS VL_TOTAL_E, 
    TO_CHAR(VL_UNIT_EST, 'FM999G999G999G990D00') AS VL_UNIT_EST,
    TO_CHAR(V_UNIT_PEPS, 'FM999G999G999G990D00') AS V_UNIT_PEPS,
    TO_CHAR(VL_UNIT_X_QTDE, 'FM999G999G999G990D00') AS VL_UNIT_X_QTDE,
    TO_CHAR(VL_UNIT_PEPS_X_QTDE, 'FM999G999G999G990D00') AS VL_UNIT_PEPS_X_QTDE,
    TO_CHAR(DIF, 'FM999G999G999G990D00') AS DIFER, 
    APURACAO,
    CFOP
FROM BASE_COMANDO_FINAL  
ORDER BY COD;