-- PRE: ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';
/*
 * CONSULTA UNIFICADA: Dados Fato/Fronteira (Sem Extração de XML)
 * Objetivo: Conciliar valores de ST e identificar tipo de operação.
 * Lógica de SEFIN: Prioriza o código da Fronteira; se nulo, utiliza o Inferido por CEST/NCM.
 * Atualização: Ajuste de nomes de colunas para PROD_NCM e PROD_CEST.
 */

WITH parametros AS (
    SELECT 
        :CNPJ         AS cnpj_filtro,          
        :CHAVE_ACESSO AS chave_acesso_filtro,
        
        CASE 
            WHEN :DATA_INICIAL IS NULL OR TRIM(:DATA_INICIAL) IS NULL 
            THEN TO_DATE('01/01/2020', 'DD/MM/YYYY')
            ELSE TO_DATE(TRIM(:DATA_INICIAL), 'DD/MM/YYYY')
        END AS data_inicial,
        
        CASE 
            WHEN :DATA_FINAL IS NULL OR TRIM(:DATA_FINAL) IS NULL 
            THEN TRUNC(SYSDATE) + INTERVAL '1' DAY - INTERVAL '1' SECOND
            ELSE TO_DATE(TRIM(:DATA_FINAL), 'DD/MM/YYYY') + INTERVAL '1' DAY - INTERVAL '1' SECOND
        END AS data_final
        
    FROM DUAL
),

BASE_FATO AS (
    SELECT
        CASE 
            WHEN d.co_emitente     = p.cnpj_filtro AND d.co_tp_nf = 1 THEN '1 - SAIDA'
            WHEN d.co_emitente     = p.cnpj_filtro AND d.co_tp_nf = 0 THEN '0 - ENTRADA'
            WHEN d.co_destinatario = p.cnpj_filtro AND d.co_tp_nf = 1 THEN '0 - ENTRADA'
            WHEN d.co_destinatario = p.cnpj_filtro AND d.co_tp_nf = 0 THEN '1 - SAIDA'
            ELSE 'INDEFINIDO'
        END AS tipo_operacao,
        
        CASE 
            WHEN d.dhsaient IS NOT NULL AND d.dhsaient > d.dhemi 
            THEN d.dhsaient 
            ELSE d.dhemi 
        END AS data_efetiva,
        
        d.dhemi,
        d.chave_acesso,
        d.seq_nitem,
        d.prod_nitem,
        -- Nomes de colunas conforme solicitado
        d.PROD_NCM,
        d.PROD_CEST,
        
        calc_front.it_co_rotina_calculo,
        calc_front.it_co_sefin AS co_sefin_fronteira,
        calc_front.it_vl_icms AS vl_icms_fronteira
        
    FROM bi.fato_nfe_detalhe d
    CROSS JOIN parametros p
    LEFT JOIN sitafe.sitafe_nfe_calculo_item calc_front 
           ON calc_front.it_nu_chave_acesso = d.chave_acesso 
          AND calc_front.it_nu_item = d.prod_nitem
    WHERE 
        (
            d.dhemi    BETWEEN p.data_inicial AND p.data_final
            OR 
            d.dhsaient BETWEEN p.data_inicial AND p.data_final
        )
        AND (d.co_destinatario = p.cnpj_filtro OR d.co_emitente = p.cnpj_filtro)
        AND d.INFPROT_CSTAT IN (100, 150)
        AND (p.chave_acesso_filtro IS NULL OR d.chave_acesso = p.chave_acesso_filtro)
),

BASE_COM_SEFIN AS (
    SELECT 
        b.*,
        cest_ncm.IT_CO_SEFIN AS co_sefin_inferido,
        -- REGRA: Prioriza fronteira. Se nulo, usa o código inferido por NCM/CEST.
        COALESCE(b.co_sefin_fronteira, cest_ncm.IT_CO_SEFIN) AS co_sefin_efetivo
    FROM BASE_FATO b
    LEFT JOIN SITAFE.SITAFE_CEST_NCM cest_ncm 
           ON cest_ncm.IT_NU_NCM = b.PROD_NCM
          AND (b.PROD_CEST IS NULL OR cest_ncm.IT_NU_CEST = b.PROD_CEST)
          AND cest_ncm.IT_IN_STATUS <> 'C'
)

SELECT
    s.tipo_operacao,
    s.data_efetiva,
    s.dhemi,
    s.chave_acesso,
    s.seq_nitem,
    s.prod_nitem,
    s.it_co_rotina_calculo,
    s.vl_icms_fronteira,
    
    -- Identificação de Produtos
    s.co_sefin_fronteira,
    s.co_sefin_inferido,
    s.co_sefin_efetivo,
    prod_sefin.it_no_produto AS no_produto_sefin,
    
    -- Dados Históricos (Baseados no co_sefin_efetivo)
    h.it_pc_interna,
    h.it_in_st,
    h.it_in_mva_ajustado,
    h.it_pc_mva,
    
    -- Metadados de Produto
    s.PROD_NCM,
    s.PROD_CEST

FROM BASE_COM_SEFIN s

-- Join para obter o Nome do Produto (Prioriza SEFIN da Fronteira via co_sefin_efetivo)
LEFT JOIN sitafe.sitafe_produto_sefin prod_sefin
       ON prod_sefin.it_co_sefin = s.co_sefin_efetivo

-- Join para obter Histórico de Alíquotas/MVA (Prioriza SEFIN da Fronteira via co_sefin_efetivo)
LEFT JOIN sitafe.sitafe_produto_sefin_aux h
       ON h.it_co_sefin = s.co_sefin_efetivo
      AND TO_CHAR(s.dhemi, 'YYYYMMDD') >= h.it_da_inicio 
      AND (h.it_da_final IS NULL OR TO_CHAR(s.dhemi, 'YYYYMMDD') <= h.it_da_final)

ORDER BY s.data_efetiva DESC, s.chave_acesso, s.prod_nitem