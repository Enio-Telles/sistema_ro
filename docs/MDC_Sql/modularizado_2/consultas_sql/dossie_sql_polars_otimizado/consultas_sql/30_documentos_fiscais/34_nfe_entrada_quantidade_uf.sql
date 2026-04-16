-- Objetivo: quantidade de NF de entrada por UF de origem e vínculo com fronteira
-- Binds esperados: :CO_CNPJ_CPF

SELECT
    EXTRACT(YEAR FROM t.dhemi) AS ano,
    t.co_uf_emit,
    COUNT(DISTINCT t.chave_acesso) AS total_nfes,
    COUNT(DISTINCT CASE WHEN t.co_uf_emit = 'RO' THEN t.chave_acesso END) AS qtd_ro,
    COUNT(DISTINCT CASE WHEN t.co_uf_emit != 'RO' THEN t.chave_acesso END) AS qtd_outras_ufs,
    COUNT(DISTINCT f.it_nu_identificao_nf_e) AS qtd_fronteira
FROM bi.fato_nfe_detalhe t
LEFT JOIN (
    SELECT f.it_nu_identificao_nf_e
    FROM sitafe.sitafe_nota_fiscal f
    WHERE f.it_nucnpj_cpf_destino_nf = :CO_CNPJ_CPF
) f
       ON t.chave_acesso = f.it_nu_identificao_nf_e
WHERE t.co_destinatario = :CO_CNPJ_CPF
  AND t.infprot_cstat IN ('100', '150')
GROUP BY
    EXTRACT(YEAR FROM t.dhemi),
    t.co_uf_emit
ORDER BY ano DESC, total_nfes DESC;
