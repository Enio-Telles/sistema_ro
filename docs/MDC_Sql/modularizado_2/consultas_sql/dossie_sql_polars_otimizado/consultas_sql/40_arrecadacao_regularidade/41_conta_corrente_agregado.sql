-- Objetivo: agregar conta corrente por receita e situação funcional
-- Binds esperados: :CO_CNPJ_CPF

WITH base AS (
    SELECT
        t.id_cpf_cnpj AS co_cnpj_cpf,
        t.id_receita,
        t.id_situacao,
        CASE
            WHEN t.id_situacao = '01' AND t.da_vencimento < SYSDATE THEN '01 - NAO_PAGO_VENCIDO'
            WHEN t.id_situacao = '01' AND t.da_vencimento > SYSDATE THEN '01 - NAO_PAGO_A_VENCER'
            ELSE t.id_situacao || ' - ' || INITCAP(s.it_no_situacao)
        END AS situacao_funcional,
        CASE
            WHEN t.va_pago IS NULL THEN (t.va_principal + t.va_multa + t.va_juros + t.va_acrescimo)
            ELSE t.va_pago
        END AS valor_total
    FROM bi.fato_lanc_arrec t
    LEFT JOIN bi.dm_situacao_lancamento s
           ON t.id_situacao = s.it_co_situacao
    WHERE t.id_cpf_cnpj = :CO_CNPJ_CPF
)
SELECT
    co_cnpj_cpf,
    situacao_funcional,
    id_receita,
    SUM(valor_total) AS valor_total
FROM base
GROUP BY
    co_cnpj_cpf,
    situacao_funcional,
    id_receita
ORDER BY situacao_funcional, valor_total DESC;
