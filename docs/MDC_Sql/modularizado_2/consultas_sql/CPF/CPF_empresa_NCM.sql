-- CPF_empresa_NCM.sql
-- Análise de NCM das notas fiscais recebidas pela empresa (compras)
-- Parâmetro: :CO_CNPJ_CPF (14 dígitos - CNPJ)
-- 
-- Objetivo: Identificar os tipos de produtos adquiridos pela empresa
-- através da classificação NCM das notas fiscais recebidas.

SELECT
    d.CO_DESTINATARIO AS CNPJ_DESTINATARIO,
    TO_CHAR(d.DHEMI, 'YYYY/MM') AS MES_REFERENCIA,
    d.PROD_NCM AS NCM,
    ncm.NO_NCM AS DESCRICAO_NCM,
    
    -- Contagens
    COUNT(DISTINCT d.CHAVE_ACESSO) AS QTD_NFS,
    COUNT(*) AS QTD_ITENS,
    
    -- Valores
    SUM(d.PROD_VPROD) AS VALOR_PRODUTOS,
    SUM(NVL(d.PROD_VFRETE,0)) AS VALOR_FRETE,
    SUM(NVL(d.PROD_VSEG,0)) AS VALOR_SEGURO,
    SUM(NVL(d.PROD_VOUTRO,0)) AS VALOR_OUTROS,
    SUM(NVL(d.PROD_VDESC,0)) AS VALOR_DESCONTO,
    SUM(d.PROD_VPROD + NVL(d.PROD_VFRETE,0) + NVL(d.PROD_VSEG,0) + NVL(d.PROD_VOUTRO,0) - NVL(d.PROD_VDESC,0)) AS VALOR_TOTAL,
    
    -- Origem das mercadorias
    COUNT(DISTINCT d.CO_EMITENTE) AS QTD_FORNECEDORES
    
FROM bi.fato_nfe_detalhe d
LEFT JOIN bi.dm_ncm ncm ON d.PROD_NCM = ncm.CO_NCM
WHERE d.CO_DESTINATARIO = :CO_CNPJ_CPF
  AND d.PROD_NCM IS NOT NULL
  AND d.INFPROT_CSTAT IN (100, 150)
GROUP BY 
    d.CO_DESTINATARIO,
    TO_CHAR(d.DHEMI, 'YYYY/MM'),
    d.PROD_NCM,
    ncm.NO_NCM
ORDER BY 
    MES_REFERENCIA DESC,
    VALOR_TOTAL DESC
