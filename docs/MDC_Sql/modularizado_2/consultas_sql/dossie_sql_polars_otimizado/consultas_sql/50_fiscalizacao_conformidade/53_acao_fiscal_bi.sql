-- Objetivo: ações fiscais oriundas da base BI
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    t.co_cnpj_cpf,
    t.in_modelo_acao_fiscal AS tipo_acao,
    t.no_situacao_acao AS situacao_acao,
    t.nu_acao_fiscal,
    t.nu_dfe,
    t.da_periodo_inicio_fisc,
    t.da_periodo_fim_fisc,
    t.nu_prazo_acao,
    t.nu_prazo_prorrog,
    t.da_distri_acao_fiscal,
    t.da_abertu_acao_fiscal,
    t.da_conclu_acao_fiscal,
    o.tx_origem_acao,
    t.tx_documento,
    t.tx_observacao
FROM bi.dm_acao_fiscal t
LEFT JOIN bi.dm_acao_fiscal_origem_acao o
       ON t.nu_acao_fiscal = o.nu_acao_fiscal
WHERE t.co_cnpj_cpf = :CO_CNPJ_CPF;
