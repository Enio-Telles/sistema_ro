-- Objetivo: consulta de checagem para comparar totais entre bases singulares e agregados
-- Binds esperados: :CO_CNPJ_CPF

WITH docs AS (
    SELECT
        CASE
            WHEN d.co_emitente     = :CO_CNPJ_CPF AND d.co_tp_nf = 1 THEN 'SAIDA'
            WHEN d.co_destinatario = :CO_CNPJ_CPF AND d.co_tp_nf = 0 THEN 'SAIDA'
            WHEN d.co_destinatario = :CO_CNPJ_CPF AND d.co_tp_nf = 1 THEN 'ENTRADA'
            WHEN d.co_emitente     = :CO_CNPJ_CPF AND d.co_tp_nf = 0 THEN 'ENTRADA'
            ELSE 'NAO_CLASSIFICADO'
        END AS direcao,
        (d.prod_vprod + d.prod_vfrete + d.prod_vseg + d.prod_voutro - d.prod_vdesc) AS valor_item
    FROM bi.fato_nfe_detalhe d
    WHERE (d.co_emitente = :CO_CNPJ_CPF OR d.co_destinatario = :CO_CNPJ_CPF)
      AND d.infprot_cstat IN ('100','150')
)
SELECT
    direcao,
    COUNT(*) AS qtd_itens,
    SUM(valor_item) AS valor_total
FROM docs
GROUP BY direcao
ORDER BY direcao;
