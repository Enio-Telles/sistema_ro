-- Objetivo: endereço cadastral atual do contribuinte
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    p.co_cnpj_cpf,
    'CADASTRO' AS origem_endereco,
    p.desc_endereco AS logradouro,
    CAST(NULL AS VARCHAR2(50)) AS numero,
    CAST(NULL AS VARCHAR2(200)) AS complemento,
    p.bairro,
    CAST(NULL AS VARCHAR2(50)) AS fone,
    p.nu_cep AS cep,
    l.no_municipio AS municipio,
    l.co_uf AS uf
FROM bi.dm_pessoa p
LEFT JOIN bi.dm_localidade l
       ON p.co_municipio = l.co_municipio
WHERE p.co_cnpj_cpf = :CO_CNPJ_CPF;
