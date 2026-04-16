-- Objetivo: CNAE principal
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    p.co_cnpj_cpf,
    'PRINCIPAL' AS tipo_cnae,
    p.co_cnae,
    c.no_cnae
FROM bi.dm_pessoa p
LEFT JOIN bi.dm_cnae c
       ON p.co_cnae = c.co_cnae
WHERE p.co_cnpj_cpf = :CO_CNPJ_CPF;
