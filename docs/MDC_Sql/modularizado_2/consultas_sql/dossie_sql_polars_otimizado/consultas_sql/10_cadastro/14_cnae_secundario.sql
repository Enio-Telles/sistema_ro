-- Objetivo: CNAEs secundários
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    s.co_cnpj_cpf,
    'SECUNDARIO' AS tipo_cnae,
    s.co_cnae_secundaria AS co_cnae,
    c.no_cnae
FROM bi.dm_cnae_secundaria s
LEFT JOIN bi.dm_cnae c
       ON s.co_cnae_secundaria = c.co_cnae
WHERE s.co_cnpj_cpf = :CO_CNPJ_CPF
ORDER BY s.co_cnae_secundaria;
