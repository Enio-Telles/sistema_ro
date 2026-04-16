-- lookup_contribuinte.sql
-- grupo: core
-- dominio: fonte consolidada de contribuinte
-- objetivo: lookup cadastral mínimo por CNPJ/IEKCPF
-- parametros esperados: cnpj, ie, cpf
-- observacao: retorna contexto cadastral mínimo e chaves para domínios seguintes
-- status: query canônica promovida a partir do eixo cadastral já autorizado no projeto
-- regra: selecionar apenas colunas necessárias e preservar chaves físicas

/* :cnpj :ie :cpf */
WITH parametros AS (
    SELECT
        REGEXP_REPLACE(TRIM(COALESCE(:cnpj, '')), '[^0-9]', '') AS cnpj_norm,
        REGEXP_REPLACE(TRIM(COALESCE(:ie, '')), '[^0-9]', '') AS ie_norm,
        REGEXP_REPLACE(TRIM(COALESCE(:cpf, '')), '[^0-9]', '') AS cpf_norm
    FROM dual
)
SELECT
    p.co_cnpj_cpf AS cnpj_cpf,
    p.co_cad_icms AS ie,
    p.no_razao_social AS razao_social,
    p.no_fantasia AS nome_fantasia,
    p.co_municipio,
    l.no_municipio,
    l.co_uf,
    p.co_regime_pagto,
    rp.no_regime_pagamento,
    p.in_situacao AS co_situacao_contribuinte,
    sc.no_situacao_contribuinte
FROM bi.dm_pessoa p
LEFT JOIN bi.dm_localidade l
  ON l.co_municipio = p.co_municipio
LEFT JOIN bi.dm_regime_pagto_descricao rp
  ON rp.co_regime_pagamento = p.co_regime_pagto
LEFT JOIN bi.dm_situacao_contribuinte sc
  ON sc.co_situacao_contribuinte = p.in_situacao
CROSS JOIN parametros paR
WHERE
    (par.cnpj_norm <> '' AND REGEXP_REPLACE(p.co_cnpj_cpf, '[^0-9]', '') = par.cnpj_norm)
    OR
    (par.ie_norm <> '' AND REGEXP_REPLACE(p.co_cad_icms, '[^0-9]', '') = par.ie_norm)
    OR
    (par.cpf_norm <> '' AND REGEXP_REPLACE(p.co_cnpj_cpf, '[^0-9]', '') = par.cpf_norm);
