-- Objetivo: MDF-e relacionado às NFe do contribuinte
-- Binds esperados: :CO_CNPJ_CPF

WITH chaves_nfe AS (
    SELECT chave_acesso
    FROM bi.fato_nfe_detalhe
    WHERE co_destinatario = :CO_CNPJ_CPF
       OR co_emitente = :CO_CNPJ_CPF
    GROUP BY chave_acesso
),
mdfe_chaves AS (
    SELECT DISTINCT m.it_nu_chave_mdfe
    FROM sitafe.sitafe_mdfe_item m
    INNER JOIN sitafe.sitafe_cte_itens c
            ON m.it_nu_chave_acesso = c.it_nu_chave_cte
    INNER JOIN chaves_nfe n
            ON c.it_nu_chave_nfe = n.chave_acesso
    UNION
    SELECT DISTINCT m.it_nu_chave_mdfe
    FROM sitafe.sitafe_mdfe_item m
    INNER JOIN chaves_nfe n
            ON m.it_nu_chave_acesso = n.chave_acesso
)
SELECT
    md.it_nu_chave_mdfe,
    md.it_da_emissao,
    md.it_uf_inicio,
    md.it_uf_fim,
    md.it_cnpj_emitente,
    md.it_uf_emitente,
    md.it_nu_placa_veiculo,
    md.it_nu_placa_reboque1,
    md.it_nu_placa_uf,
    md.it_valor_carga,
    md.it_cpf_motorista,
    md.it_no_motorista
FROM mdfe_chaves x
LEFT JOIN sitafe.sitafe_mdfe md
       ON x.it_nu_chave_mdfe = md.it_nu_chave_mdfe
ORDER BY md.it_da_emissao DESC;
