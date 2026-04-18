-- CPF_NF_entrada_quantidades.sql
-- Extraído de dossie_contribuinte.xml - NFs Entrada Quantidades
-- Parâmetro: :CO_CNPJ_CPF

SELECT
    :CO_CNPJ_CPF CO_CNPJ_CPF,
    ano ANO,
    sum(total_nfes) TOTAL_NFS,
    sum(origem_ro) ORIGEM_RO,
    sum(origem_ouf) ORIGEM_OUTRAS_UFS,
    sum(fronteira) FRONTEIRA
FROM (
    SELECT
        EXTRACT(YEAR FROM dhemi) ano,
        t.co_uf_emit,
        COUNT(DISTINCT chave_acesso) total_nfes,
        COUNT(DISTINCT
            CASE
                WHEN co_uf_emit = 'RO' THEN chave_acesso
                ELSE NULL
            END
        ) origem_ro,
        COUNT(DISTINCT
            CASE
                WHEN co_uf_emit != 'RO' THEN chave_acesso
                ELSE NULL
            END
        ) origem_ouf,
        COUNT(DISTINCT f.it_nu_identificao_nf_e) fronteira
    FROM
        bi.fato_nfe_detalhe t
        LEFT JOIN (
            SELECT f.it_nu_identificao_nf_e
            FROM sitafe.sitafe_nota_fiscal f
            WHERE f.it_nucnpj_cpf_destino_nf = :CO_CNPJ_CPF
        ) f ON t.chave_acesso = f.it_nu_identificao_nf_e
    WHERE
        co_destinatario = :CO_CNPJ_CPF
        AND t.infprot_cstat IN('100','150')
    GROUP BY
        EXTRACT(YEAR FROM dhemi),
        t.co_uf_emit
) b
GROUP BY ano
ORDER BY ano DESC
