-- dados_cadastrais.sql
-- grupo: core
-- dominio: cadastro contribuinte
-- objetivo: dados cadastrais completos para contribuinte
-- parametros esperados: cnpj
-- observacao: base para dossiê e Fisconforme
-- status: query canônica promovida a partir do eixo cadastral já autorizado no projeto
-- regra: selecionar apenas colunas necessárias e preservar chaves físicas

/* :cnpj */
SELECT
    p.co_cnpj_cpf AS cnpj,
    p.co_cad_icms AS ie,
    p.no_razao_social AS razao_social,
    p.no_fantasia AS nome_fantasia,
    p.desc_endereco,
    p.bairro,
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
WHERE regexp_replace(p.co_cnpj_cpf, '[^0-9]', '') = :cnpj;
