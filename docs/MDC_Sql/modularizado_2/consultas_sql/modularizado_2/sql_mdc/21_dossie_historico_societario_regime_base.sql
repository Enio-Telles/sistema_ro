/*
===============================================================================
MDC 21 - DOSSIÊ HISTÓRICO SOCIETÁRIO / REGIME / SITUAÇÃO
-------------------------------------------------------------------------------
Objetivo
- Cobrir o núcleo mínimo dos dossiês XML ligados a sócios, histórico cadastral e
  regime de pagamento.
- Útil quando a análise fiscal precisa conectar pessoa física a empresas e a
  situação cadastral no tempo.

Granularidade
- 1 linha por vínculo histórico relevante.
===============================================================================
*/
SELECT
    hs.gr_identificacao,
    hc.it_nu_inscricao_estadual,
    hc.it_in_ultima_fac,
    hc.it_da_referencia,
    p.co_cnpj_cpf,
    p.no_razao_social,
    l.no_municipio,
    l.co_uf,
    r.desc_reg_pagto,
    s.situacao,
    tb.it_co_cargo_socio
FROM sitafe.sitafe_historico_socio hs
LEFT JOIN sitafe.sitafe_historico_contribuinte hc
       ON hc.it_nu_fac = hs.it_nu_fac
LEFT JOIN bi.dm_pessoa p
       ON SUBSTR(hc.gr_identificacao, 2) = p.co_cnpj_cpf
LEFT JOIN bi.dm_localidade l
       ON l.co_municipio = p.co_municipio
LEFT JOIN bi.dm_regime_pagto_descricao r
       ON r.co_regime_pagamento = p.co_regime_pagto
LEFT JOIN bi.vw_situacao_contribuinte s
       ON s.in_situacao = p.in_situacao
LEFT JOIN sitafe.sitafe_tabelas_cadastro tb
       ON tb.it_co_cargo_socio = hs.it_co_cargo_socio
WHERE SUBSTR(hs.gr_identificacao, 2) = REGEXP_REPLACE(TRIM(:CNPJ_CPF), '[^0-9]', '');
