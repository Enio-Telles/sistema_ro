-- Objetivo: veículos atuais associados ao contribuinte no SITAFE
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    v.it_nu_devedor AS co_cnpj_cpf,
    'SITAFE' AS origem,
    tv.it_no_marca_modelo AS modelo,
    v.it_da_ano_fabricacao AS ano_fabricacao,
    v.it_da_ano_modelo AS ano_modelo,
    v.it_nu_placa AS placa,
    v.it_co_renavam AS renavam,
    v.it_nu_chassi AS chassi
FROM sitafe.sitafe_veiculo v
LEFT JOIN sitafe.sitafe_tab_veiculo tv
       ON v.it_co_marca_modelo = tv.it_co_marca_modelo
WHERE v.it_nu_devedor = :CO_CNPJ_CPF;
