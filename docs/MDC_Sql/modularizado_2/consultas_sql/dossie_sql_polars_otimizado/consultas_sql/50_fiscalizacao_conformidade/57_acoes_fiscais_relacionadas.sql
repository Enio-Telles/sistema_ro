-- Objetivo: conjunto de chaves de ações fiscais relacionadas ao contribuinte
-- Binds esperados: :CO_CNPJ_CPF

SELECT SUBSTR(dft.it_nu_diligencia,1,5) || '7' || SUBSTR(dft.it_nu_diligencia,7) AS nu_acao_fiscal
FROM sitafe.sitafe_diligencia_fiscal_taref dft
WHERE dft.it_nu_identificacao = :CO_CNPJ_CPF

UNION

SELECT t.nu_acao_fiscal
FROM bi.dm_acao_fiscal t
WHERE t.co_cnpj_cpf = :CO_CNPJ_CPF

UNION

SELECT ainf.nu_acao_fiscal
FROM bi.arr_f_lancamento_detalhe l
INNER JOIN bi.fato_acao_fiscal_ainf ainf
        ON ainf.nu_guia_lanc_multa = l.numero_guia
WHERE l.cnpj_cpf = :CO_CNPJ_CPF;
