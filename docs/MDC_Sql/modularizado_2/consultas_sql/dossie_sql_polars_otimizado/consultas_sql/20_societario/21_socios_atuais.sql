-- Objetivo: sócios atuais do contribuinte
-- Binds esperados: :CO_CAD_ICMS

SELECT DISTINCT
    s.it_nu_inscricao_estadual AS co_cad_icms,
    SUBSTR(s.gr_identificacao, 2) AS cpf_cnpj_socio,
    p.it_no_pessoa AS no_socio
FROM sitafe.sitafe_historico_socio s
LEFT JOIN sitafe.sitafe_pessoa p
       ON p.gr_identificacao = s.gr_identificacao
      AND p.it_in_ultima_situacao = '9'
WHERE s.it_nu_inscricao_estadual = :CO_CAD_ICMS
  AND s.it_in_ultima_fac = '9'
  AND (s.it_da_fim_part_societaria = '        ' OR s.it_da_fim_part_societaria > TO_CHAR(SYSDATE, 'YYYYMMDD'))
ORDER BY no_socio;
