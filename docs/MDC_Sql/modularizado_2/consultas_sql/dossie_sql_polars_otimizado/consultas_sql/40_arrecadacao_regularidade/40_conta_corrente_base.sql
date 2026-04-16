-- Objetivo: fatos de conta corrente sem formatação visual
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    t.id_cpf_cnpj AS co_cnpj_cpf,
    t.id_receita,
    t.id_situacao,
    s.it_no_situacao AS no_situacao,
    t.da_vencimento,
    t.da_arrecadacao,
    CASE
        WHEN t.va_pago IS NULL THEN (t.va_principal + t.va_multa + t.va_juros + t.va_acrescimo)
        ELSE t.va_pago
    END AS valor_total
FROM bi.fato_lanc_arrec t
LEFT JOIN bi.dm_situacao_lancamento s
       ON t.id_situacao = s.it_co_situacao
WHERE t.id_cpf_cnpj = :CO_CNPJ_CPF;
