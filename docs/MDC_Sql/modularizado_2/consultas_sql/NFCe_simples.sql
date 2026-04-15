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
)
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
    
    d.*
FROM 
    bi.fato_nfe_detalhe d
    CROSS JOIN parametros p
WHERE 
    (
        d.dhemi    BETWEEN p.data_inicial AND p.data_final
        OR 
        d.dhsaient BETWEEN p.data_inicial AND p.data_final
    )
    AND (d.co_destinatario = p.cnpj_filtro OR d.co_emitente = p.cnpj_filtro)
    AND d.INFPROT_CSTAT IN (100, 150)
    AND (p.chave_acesso_filtro IS NULL OR d.chave_acesso = p.chave_acesso_filtro)