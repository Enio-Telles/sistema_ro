-- Objetivo: regimes especiais associados ao contribuinte
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    SUBSTR(t.gr_identificacao, 2, 14) AS co_cnpj_cpf,
    t.it_co_regime,
    r.it_no_regime,
    t.it_nu_ato,
    t.it_nu_processo,
    CASE WHEN t.it_da_transacao > '1' THEN TO_DATE(t.it_da_transacao, 'YYYYMMDD') END AS dt_transacao,
    CASE WHEN t.it_da_cadastro > '1' THEN TO_DATE(t.it_da_cadastro, 'YYYYMMDD') END AS dt_cadastro,
    CASE WHEN t.it_da_vencimento > '1' THEN TO_DATE(t.it_da_vencimento, 'YYYYMMDD') END AS dt_vencimento,
    CASE WHEN t.it_da_baixa > '1' THEN TO_DATE(t.it_da_baixa, 'YYYYMMDD') END AS dt_baixa,
    t.it_tx_observacao,
    t.it_tx_motivo_baixa,
    CASE WHEN t.it_da_baixa = '       ' THEN 'ATIVO' ELSE 'CANCELADO' END AS situacao_regime
FROM sitafe.sitafe_regime_contribuinte t
LEFT JOIN sitafe.sitafe_regime_especial_padrao r
       ON t.it_co_regime = r.it_co_regime
WHERE SUBSTR(t.gr_identificacao, 2, 14) = :CO_CNPJ_CPF
  AND t.it_in_ultima = '9';
