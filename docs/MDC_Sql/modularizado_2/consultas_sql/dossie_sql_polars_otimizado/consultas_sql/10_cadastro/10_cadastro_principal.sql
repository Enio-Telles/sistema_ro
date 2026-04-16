-- Objetivo: retornar o cadastro principal do contribuinte sem formatação de apresentação
-- Binds esperados: :CO_CNPJ_CPF

WITH ultima_situacao AS (
    SELECT
        u.it_nu_inscricao_estadual,
        MAX(u.it_da_transacao) AS data_ult_sit
    FROM sitafe.sitafe_historico_gr_situacao t
    LEFT JOIN sitafe.sitafe_historico_situacao u
           ON t.tuk = u.tuk
    WHERE t.it_co_situacao_contribuinte NOT IN ('030','150','005')
      AND u.it_co_usuario NOT IN ('INTERNET','P30015AC   ')
    GROUP BY u.it_nu_inscricao_estadual
)
SELECT
    p.co_cnpj_cpf,
    p.co_cad_icms,
    p.no_razao_social,
    p.desc_endereco,
    p.bairro,
    l.no_municipio,
    l.co_uf,
    p.co_regime_pagto,
    rp.no_regime_pagamento,
    p.in_situacao,
    s.no_situacao_contribuinte,
    p.da_inicio_atividade,
    TO_DATE(us.data_ult_sit, 'YYYYMMDD') AS data_ultima_situacao
FROM bi.dm_pessoa p
LEFT JOIN bi.dm_localidade l
       ON p.co_municipio = l.co_municipio
LEFT JOIN bi.dm_regime_pagto_descricao rp
       ON p.co_regime_pagto = rp.co_regime_pagamento
LEFT JOIN bi.dm_situacao_contribuinte s
       ON p.in_situacao = s.co_situacao_contribuinte
LEFT JOIN ultima_situacao us
       ON p.co_cad_icms = us.it_nu_inscricao_estadual
WHERE p.co_cnpj_cpf = :CO_CNPJ_CPF;
