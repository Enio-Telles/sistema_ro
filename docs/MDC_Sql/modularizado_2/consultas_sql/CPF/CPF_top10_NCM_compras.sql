-- CPF_top10_NCM_compras.sql
-- Análise dos 10 NCMs com maiores valores de compras por CPF
-- Parâmetro: :CO_CNPJ_CPF

SELECT * FROM (
    SELECT
        :CO_CNPJ_CPF AS CO_CNPJ_CPF,
        n.prod_ncm AS NCM,
        ncm.no_ncm AS DESCRICAO_NCM,
        COUNT(DISTINCT n.chave_acesso) AS QTD_NOTAS,
        SUM(n.prod_qcom) AS QTD_TOTAL,
        ROUND(SUM(n.prod_vprod + n.prod_vfrete + n.prod_vseg + n.prod_voutro - n.prod_vdesc), 2) AS VALOR_TOTAL,
        ROUND(AVG(n.prod_vuncom), 2) AS VALOR_MEDIO_UNIT,
        MIN(n.dhemi) AS PRIMEIRA_COMPRA,
        MAX(n.dhemi) AS ULTIMA_COMPRA,
        COUNT(DISTINCT n.co_emitente) AS QTD_FORNECEDORES,
        ROUND(
            SUM(n.prod_vprod + n.prod_vfrete + n.prod_vseg + n.prod_voutro - n.prod_vdesc) / 
            NULLIF(SUM(SUM(n.prod_vprod + n.prod_vfrete + n.prod_vseg + n.prod_voutro - n.prod_vdesc)) OVER(), 0) * 100
        , 2) AS PERCENTUAL_TOTAL,
        ROW_NUMBER() OVER (ORDER BY SUM(n.prod_vprod + n.prod_vfrete + n.prod_vseg + n.prod_voutro - n.prod_vdesc) DESC) AS RANKING
    FROM bi.fato_nfe_detalhe n
    LEFT JOIN bi.dm_ncm ncm ON n.prod_ncm = ncm.co_ncm
    WHERE 
        -- Notas de entrada (compras)
        (
            (n.co_destinatario = :CO_CNPJ_CPF AND n.co_tp_nf = 1)  -- Destinatário em NF própria
            OR (n.co_emitente = :CO_CNPJ_CPF AND n.co_tp_nf = 0)   -- Emitente em NF terceiros
        )
        AND n.infprot_cstat IN ('100', '150')  -- Apenas autorizadas
        AND n.prod_ncm IS NOT NULL
    GROUP BY 
        n.prod_ncm,
        ncm.no_ncm
    ORDER BY VALOR_TOTAL DESC
)
WHERE RANKING <= 10
