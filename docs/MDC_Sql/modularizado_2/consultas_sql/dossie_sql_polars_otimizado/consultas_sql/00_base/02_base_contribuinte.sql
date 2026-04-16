-- Objetivo: resolver a base mestra do contribuinte selecionado
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    p.co_cnpj_cpf,
    p.co_cad_icms,
    p.no_razao_social,
    p.desc_endereco,
    p.bairro,
    p.nu_cep,
    p.co_municipio,
    p.co_regime_pagto,
    p.in_situacao,
    p.in_conder,
    p.da_inicio_atividade,
    p.co_cnae
FROM bi.dm_pessoa p
WHERE p.co_cnpj_cpf = :CO_CNPJ_CPF;
