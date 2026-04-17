-- CPF_DIMP_comparativo.sql
-- Extraído de dossie_contribuinte.xml - DIMP Sócios (comparativo cartão vs NF)
-- Parâmetro: :CO_CNPJ_CPF

WITH cartao AS (
    SELECT
        CASE
            WHEN ano IS NULL AND periodo IS NULL THEN 'TOTAL GERAL'
            WHEN ano IS NOT NULL AND periodo IS NULL THEN 'Total ' || ano
            WHEN ano IS NOT NULL AND periodo IS NOT NULL THEN periodo
        END info,
        operacoes,
        cartao
    FROM(
        SELECT
            extract(year from dt_op) ano,
            extract(year from dt_op)||'/'||lpad(extract(month from dt_op),2,'0') periodo,
            count(*) operacoes,
            sum(valor) cartao
        FROM bi.mpg_f_detalhe_operacao
        WHERE cnpj_cpf = :CO_CNPJ_CPF
        GROUP BY grouping sets
            ((),
            (extract(year from dt_op)),
            (extract(year from dt_op), extract(year from dt_op)||'/'||lpad(extract(month from dt_op),2,'0')))
    )
    ORDER BY ano DESC, periodo DESC
),
saidas AS (
    SELECT
        CASE
            WHEN ano IS NULL AND periodo IS NULL THEN 'TOTAL GERAL'
            WHEN ano IS NOT NULL AND periodo IS NULL THEN 'Total ' || ano
            WHEN ano IS NOT NULL AND periodo IS NOT NULL THEN periodo
        END info,
        nfe_nfce
    FROM(
        SELECT
            extract(year from da_referencia) ano,
            extract(year from da_referencia)||'/'||lpad(extract(month from da_referencia),2,'0') periodo,
            sum(prod_vprod+prod_vfrete+prod_vseg+prod_voutro-prod_vdesc) nfe_nfce
        FROM BI.fato_nfe_nfce_sumarizada
        WHERE co_emitente = :CO_CNPJ_CPF
          AND co_tp_nf = 1
        GROUP BY grouping sets
            ((),
            (extract(year from da_referencia)),
            (extract(year from da_referencia), extract(year from da_referencia)||'/'||lpad(extract(month from da_referencia),2,'0')))
    )
    ORDER BY ano DESC, periodo DESC
)
SELECT
    nvl(cartao.info, saidas.info) PERIODO,
    cartao.operacoes QTD_OPERACOES_CARTAO,
    cartao.cartao VALOR_CARTAO,
    saidas.nfe_nfce VALOR_NFE_NFCE,
    CASE
        WHEN nvl(cartao.cartao,0) - nvl(saidas.nfe_nfce,0) > 0
            THEN nvl(cartao.cartao,0) - nvl(saidas.nfe_nfce,0)
        ELSE 0
    END EXCESSO_VALOR
FROM cartao
LEFT JOIN saidas ON cartao.info = saidas.info
