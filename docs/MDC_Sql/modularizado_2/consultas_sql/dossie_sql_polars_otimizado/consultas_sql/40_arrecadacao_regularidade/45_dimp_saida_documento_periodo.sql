-- Objetivo: saídas documentais por ano e período para confronto com DIMP
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    co_emitente AS co_cnpj_cpf,
    EXTRACT(YEAR FROM da_referencia) AS ano,
    TO_CHAR(da_referencia, 'YYYY-MM') AS periodo_ym,
    SUM(prod_vprod + prod_vfrete + prod_vseg + prod_voutro - prod_vdesc) AS valor_nfe_nfce
FROM bi.fato_nfe_nfce_sumarizada
WHERE co_emitente = :CO_CNPJ_CPF
  AND co_tp_nf = 1
GROUP BY
    co_emitente,
    EXTRACT(YEAR FROM da_referencia),
    TO_CHAR(da_referencia, 'YYYY-MM')
ORDER BY ano DESC, periodo_ym DESC;
