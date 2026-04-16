-- Objetivo: parcelamentos do contribuinte
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    SUBSTR(t.gr_identificacao, 2, 14) AS co_cnpj_cpf,
    t.it_nu_proc_parcelamento,
    t.it_in_situacao_parcelamento,
    CASE
        WHEN t.it_in_situacao_parcelamento = '0' THEN 'CANCELADO'
        WHEN t.it_in_situacao_parcelamento = '1' THEN 'DEFERIDO_PAGO'
        WHEN t.it_in_situacao_parcelamento = '2' THEN 'INDEFERIDO_CANCELADO'
        WHEN t.it_in_situacao_parcelamento = '3' THEN 'AGUARDANDO_DEFERIMENTO_NAO_PAGO'
        WHEN t.it_in_situacao_parcelamento = '4' THEN 'LIQUIDADO'
        WHEN t.it_in_situacao_parcelamento = '5' THEN 'REPARCELADO'
        WHEN t.it_in_situacao_parcelamento = '6' THEN 'CANCELADO'
        WHEN t.it_in_situacao_parcelamento = '7' THEN 'INDEFERIDO_FALTA_GARANTIA'
        WHEN t.it_in_situacao_parcelamento = '8' THEN 'INSCRITO_DIVIDA_ATIVA'
        WHEN t.it_in_situacao_parcelamento = '9' THEN 'EXCLUIDO'
        WHEN t.it_in_situacao_parcelamento = ' ' THEN 'AINDA_NAO_CONFIRMADO'
        ELSE NULL
    END AS situacao_parcelamento,
    t.it_co_receita,
    t.it_nu_guia_parcelamento,
    t.it_qt_parcela,
    t.it_va_principal,
    t.it_va_total_parcelamento,
    t.it_va_parcela_inicial,
    t.it_va_total_parc_inic,
    t.it_va_parcela_vincenda,
    t.it_va_total_parc_vinc
FROM sitafe.sitafe_parcelamento t
WHERE SUBSTR(t.gr_identificacao, 2, 14) = :CO_CNPJ_CPF
ORDER BY t.it_da_parcelamento DESC;
