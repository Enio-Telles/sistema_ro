-- Objetivo: inadimplência consolidada por CNPJ/CPF
-- Binds esperados: nenhum

SELECT
    t.co_cnpj_cpf,
    SUM(t.va_principal + t.va_multa + t.va_juros + t.va_acrescimo) AS inadimplencia_total
FROM bi.fato_lanc_arrec_sum t
WHERE t.da_arrecadacao IS NULL
  AND t.id_situacao = '01'
  AND t.vencido = '3'
GROUP BY t.co_cnpj_cpf;
