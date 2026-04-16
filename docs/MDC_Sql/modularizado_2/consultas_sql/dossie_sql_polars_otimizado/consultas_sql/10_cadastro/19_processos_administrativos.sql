-- Objetivo: processos administrativos do contribuinte
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    p.nu_processo,
    p.dt_abertura,
    p.in_status,
    p.co_servico,
    s.it_no_servico,
    p.cpf_solicitante,
    dp.no_razao_social AS no_solicitante
FROM bi.dm_processo_administrativo p
LEFT JOIN sitafe.sitafe_servico s
       ON p.co_servico = s.it_co_servico
LEFT JOIN bi.dm_pessoa dp
       ON p.cpf_solicitante = dp.co_cnpj_cpf
WHERE p.co_cpf_cnpj_contribuinte = :CO_CNPJ_CPF
ORDER BY p.dt_abertura DESC;
