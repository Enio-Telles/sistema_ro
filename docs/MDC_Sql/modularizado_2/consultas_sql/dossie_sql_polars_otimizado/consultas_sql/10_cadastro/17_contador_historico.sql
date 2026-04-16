-- Objetivo: identificar mudanças de contador por janela temporal
-- Binds esperados: :CO_CAD_ICMS

WITH mudancas AS (
    SELECT
        c.it_nu_inscricao_estadual AS co_cad_icms,
        SUBSTR(c.gr_identificacao, 2) AS co_cnpj_cpf,
        CASE
            WHEN SUBSTR(c.gr_ident_contador, 2) IS NULL THEN NULL
            ELSE SUBSTR(c.gr_ident_contador, 2)
        END AS co_cnpj_cpf_contador,
        TO_DATE(c.it_da_referencia, 'YYYYMMDD') AS inicio_ref,
        LEAD(TO_DATE(c.it_da_referencia, 'YYYYMMDD')) OVER (ORDER BY c.it_nu_fac) AS fim_ref,
        CASE
            WHEN ROW_NUMBER() OVER (ORDER BY c.it_nu_fac) = 1 THEN 1
            WHEN c.gr_ident_contador != LAG(c.gr_ident_contador) OVER (ORDER BY c.it_nu_fac) THEN 1
            ELSE 0
        END AS usar_linha
    FROM sitafe.sitafe_historico_contribuinte c
    WHERE c.it_nu_inscricao_estadual = :CO_CAD_ICMS
)
SELECT
    m.co_cad_icms,
    m.co_cnpj_cpf,
    m.co_cnpj_cpf_contador,
    p.no_razao_social AS no_contador,
    l.no_municipio,
    l.co_uf,
    m.inicio_ref,
    m.fim_ref
FROM mudancas m
LEFT JOIN bi.dm_pessoa p
       ON m.co_cnpj_cpf_contador = p.co_cnpj_cpf
LEFT JOIN bi.dm_localidade l
       ON p.co_municipio = l.co_municipio
WHERE m.usar_linha = 1
ORDER BY NVL(m.fim_ref, DATE '9999-12-31') DESC, m.inicio_ref DESC;
