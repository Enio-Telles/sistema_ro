-- Objetivo: histórico de FAC por inscrição estadual
-- Binds esperados: :CO_CAD_ICMS

SELECT
    h.it_da_transacao AS da_transacao_raw,
    h.it_da_referencia AS da_referencia_raw,
    h.it_nu_fac,
    h.it_nu_inscricao_estadual AS co_cad_icms,
    p.it_no_pessoa AS no_pessoa,
    p.it_no_fantasia AS no_fantasia,
    h.it_co_regime_pagamento,
    h.it_va_capital_social,
    h.it_co_atividade_economica,
    tg.it_co_tipo_logradouro,
    tg.it_no_logradouro,
    p.it_ed_numero,
    l.no_municipio,
    p.it_sg_uf,
    p.it_co_correio_eletronico AS email,
    p.it_co_correio_eletro_corresp AS email_correspondencia,
    SUBSTR(h.gr_ident_contador, 2, 14) AS cpf_cnpj_contador,
    dc.no_razao_social AS no_contador,
    h.it_in_ultima_fac
FROM sitafe.sitafe_historico_contribuinte h
LEFT JOIN sitafe.sitafe_pessoa p
       ON h.it_nu_fac = p.it_nu_fac
LEFT JOIN sitafe.sitafe_tabelas_cadastro tg
       ON p.it_co_logradouro = tg.it_co_logradouro
LEFT JOIN bi.dm_localidade l
       ON p.it_co_municipio = l.co_municipio
LEFT JOIN bi.dm_pessoa dc
       ON SUBSTR(h.gr_ident_contador, 2, 14) = dc.co_cnpj_cpf
WHERE h.it_nu_inscricao_estadual = :CO_CAD_ICMS
ORDER BY h.it_da_transacao DESC;
