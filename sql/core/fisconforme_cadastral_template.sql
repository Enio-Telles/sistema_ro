-- Core SQL template: dados cadastrais do Fisconforme

SELECT
    p.co_cnpj_cpf AS cnpj,
    p.co_cad_icms AS ie,
    p.no_razao_social AS razao_social,
    p.no_fantasia AS nome_fantasia,
    p.desc_endereco,
    p.bairro,
    l.no_municipio,
    l.co_uf,
    rp.no_regime_pagamento,
    sc.no_situacao_contribuinte
FROM bi.dm_pessoa p
LEFT JOIN bi.dm_localidade l
  ON l.co_municipio = p.co_municipio
LEFT JOIN bi.dm_regime_pagto_descricao rp
  ON rp.co_regime_pagamento = p.co_regime_pagto
LEFT JOIN bi.dm_situacao_contribuinte sc
  ON sc.co_situacao_contribuinte = p.in_situacao
WHERE regexp_replace(p.co_cnpj_cpf, '[^0-9]', '') = :cnpj;
