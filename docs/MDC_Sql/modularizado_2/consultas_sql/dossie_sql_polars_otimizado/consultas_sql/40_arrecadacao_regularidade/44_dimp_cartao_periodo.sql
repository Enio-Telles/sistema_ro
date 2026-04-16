-- Objetivo: movimentação de cartão por ano e período
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    cnpj_cpf AS co_cnpj_cpf,
    EXTRACT(YEAR FROM dt_op) AS ano,
    TO_CHAR(dt_op, 'YYYY-MM') AS periodo_ym,
    COUNT(*) AS qtd_operacoes_cartao,
    SUM(valor) AS valor_cartao
FROM bi.mpg_f_detalhe_operacao
WHERE cnpj_cpf = :CO_CNPJ_CPF
GROUP BY
    cnpj_cpf,
    EXTRACT(YEAR FROM dt_op),
    TO_CHAR(dt_op, 'YYYY-MM')
ORDER BY ano DESC, periodo_ym DESC;
