-- Objetivo: apuração anual de entradas e saídas elegíveis ao VAF
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    :CO_CNPJ_CPF AS co_cnpj_cpf,
    EXTRACT(YEAR FROM t.da_referencia) AS ano,
    SUM(
        CASE
            WHEN t.co_emitente = :CO_CNPJ_CPF     AND t.co_tp_nf = 1 THEN (t.prod_vprod + t.prod_vfrete + t.prod_vseg + t.prod_voutro - t.prod_vdesc)
            WHEN t.co_destinatario = :CO_CNPJ_CPF AND t.co_tp_nf = 0 THEN (t.prod_vprod + t.prod_vfrete + t.prod_vseg + t.prod_voutro - t.prod_vdesc)
            ELSE 0
        END
    ) AS saida,
    SUM(
        CASE
            WHEN t.co_destinatario = :CO_CNPJ_CPF AND t.co_tp_nf = 1 THEN (t.prod_vprod + t.prod_vfrete + t.prod_vseg + t.prod_voutro - t.prod_vdesc)
            WHEN t.co_emitente     = :CO_CNPJ_CPF AND t.co_tp_nf = 0 THEN (t.prod_vprod + t.prod_vfrete + t.prod_vseg + t.prod_voutro - t.prod_vdesc)
            ELSE 0
        END
    ) AS entrada
FROM bi.fato_nfe_nfce_sumarizada t
INNER JOIN bi.dm_cfop c
        ON t.co_cfop = c.co_cfop
WHERE (t.co_emitente = :CO_CNPJ_CPF OR t.co_destinatario = :CO_CNPJ_CPF)
  AND c.in_vaf = 'X'
GROUP BY EXTRACT(YEAR FROM t.da_referencia)
ORDER BY ano DESC;
