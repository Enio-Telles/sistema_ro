-- Objetivo: histórico societário completo do contribuinte
-- Binds esperados: :CO_CAD_ICMS

SELECT
    s.it_nu_inscricao_estadual AS co_cad_icms,
    s.gr_identificacao,
    SUBSTR(s.gr_identificacao, 2) AS cpf_cnpj_socio,
    p.it_no_pessoa AS no_socio,
    CASE WHEN s.it_da_inicio_part_societaria != '        '
         THEN TO_DATE(s.it_da_inicio_part_societaria, 'YYYYMMDD')
    END AS dt_entrada,
    CASE WHEN s.it_da_fim_part_societaria != '        '
         THEN TO_DATE(s.it_da_fim_part_societaria, 'YYYYMMDD')
    END AS dt_saida,
    s.it_in_ultima_fac
FROM sitafe.sitafe_historico_socio s
LEFT JOIN sitafe.sitafe_pessoa p
       ON p.gr_identificacao = s.gr_identificacao
      AND p.it_in_ultima_situacao = '9'
WHERE s.it_nu_inscricao_estadual = :CO_CAD_ICMS
ORDER BY dt_entrada DESC NULLS LAST, dt_saida DESC NULLS LAST, no_socio;
