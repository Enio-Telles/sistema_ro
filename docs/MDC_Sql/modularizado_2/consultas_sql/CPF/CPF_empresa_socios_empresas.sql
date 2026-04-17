/*
    Analise da Consulta: CPF_empresa_socios_empresas.sql
    Objetivo: Para cada socio de uma empresa, listar TODAS as outras empresas
    onde esse socio tambem participa (atual ou anteriormente).

    Tabelas Utilizadas:
    - sitafe.sitafe_historico_contribuinte: Historico de contribuintes.
    - sitafe.sitafe_historico_socio: Historico de socios.
    - bi.dm_pessoa: Cadastro de pessoas juridicas.
    - bi.dm_localidade: Municipios.
    - bi.dm_situacao_contribuinte: Situacoes cadastrais.
    - bi.fato_lanc_arrec_sum: Debitos vencidos (inadimplencia).

    Logica Principal:
    1. Identifica todos os socios da empresa informada (pela IE).
    2. Para cada socio, busca todas as empresas onde ele participa.
    3. Calcula inadimplencia de cada empresa relacionada.
    4. Usa GROUPING SETS para agregar por socio e detalhar por empresa.

    Uso Tipico:
    - Identificar grupo economico.
    - Verificar "laranja" ou socios em comum entre empresas.
*/

SELECT
      CASE
            WHEN nome IS NULL THEN
                  nome_socio
            ELSE
                  nome
      END          nome,
      cnpj_cpf,
      it_nu_inscricao_estadual,
      to_date(entrada, 'YYYYMMDD')    entrada,
      CASE
            WHEN saida IS NULL THEN
                  NULL
            ELSE
                  to_date(saida, 'YYYYMMDD')
      END          saida,
      LPAD(TRIM(to_char(SUM(inadimplencia), '999G999G999G990D00')), 18) inadimplencia,
      no_municipio,
      in_situacao,
      no_situacao_contribuinte,
      in_conder,
      da_inicio_atividade
  FROM
      (
            SELECT
                  cpf_cnpj_socio,
                  nome_socio,
                  CASE
                        WHEN no_razao_social IS NULL
                           AND it_nu_inscricao_estadual IS NOT NULL THEN
                              cpf_cnpj_socio
                        ELSE
                              co_cnpj_cpf
                  END  cnpj_cpf,
                  it_nu_inscricao_estadual,
                  CASE
                        WHEN no_razao_social IS NULL
                           AND it_nu_inscricao_estadual IS NOT NULL THEN
                              nome_socio
                        ELSE
                              no_razao_social
                  END  nome,
                  to_date(entrada, 'YYYYMMDD')    entrada,
                  CASE
                        WHEN ult_fac = 9 THEN
                              NULL
                        ELSE
                              to_date(saida, 'YYYYMMDD')
                  END  saida,
                  ult_fac,
                  inadimplencia,
                  no_municipio,
                  in_situacao,
                  no_situacao_contribuinte,
                  in_conder,
                  da_inicio_atividade
              FROM
                  (
                        SELECT
                              substr(h.gr_identificacao, 2)                                                            cpf_cnpj_socio,
                              pe.no_razao_social                                                           nome_socio,
                              p.co_cnpj_cpf,
                              t.it_nu_inscricao_estadual,
                              p.no_razao_social,
                              l.no_municipio,
                              p.in_situacao,
                              s.no_situacao_contribuinte,
                              p.in_conder,
                              p.da_inicio_atividade,
                              MIN(it_da_referencia) OVER(PARTITION BY t.it_nu_inscricao_estadual || t.gr_identificacao)          entrada,
                              MAX(t.it_da_referencia) OVER(PARTITION BY t.it_nu_inscricao_estadual || t.gr_identificacao)          saida,
                              MAX(t.it_in_ultima_fac) OVER(PARTITION BY t.it_nu_inscricao_estadual || t.gr_identificacao)          ult_fac,
                              a.inadimplencia
                          FROM
                              sitafe.sitafe_historico_contribuinte    t
                                LEFT JOIN sitafe.sitafe_historico_socio           h ON t.it_nu_fac = h.it_nu_fac
                                LEFT JOIN bi.dm_pessoa                            p ON t.it_nu_inscricao_estadual = p.co_cad_icms
                                LEFT JOIN bi.dm_localidade                        l ON p.co_municipio = l.co_municipio
                                LEFT JOIN bi.dm_situacao_contribuinte             s ON p.in_situacao = s.co_situacao_contribuinte
                                LEFT JOIN(
                                    SELECT
                                          t.co_cnpj_cpf,
                                          SUM(t.va_principal + t.va_multa + t.va_juros + t.va_acrescimo)inadimplencia
                                      FROM
                                          bi.fato_lanc_arrec_sum t
                                     WHERE
                                          t.da_arrecadacao IS NULL
                                             AND t.id_situacao = '01'
                                             AND t.vencido = '3'
                                     GROUP BY
                                          t.co_cnpj_cpf
                              )                                       a ON p.co_cnpj_cpf = a.co_cnpj_cpf
                                LEFT JOIN bi.dm_pessoa                            pe ON substr(h.gr_identificacao, 2)= pe.co_cnpj_cpf
                             WHERE
                                  h.gr_identificacao IN(
                                        SELECT
                                              socio.gr_identificacao
                                          FROM
                                              sitafe.sitafe_historico_contribuinte    t
                                                LEFT JOIN sitafe.sitafe_historico_socio           socio ON t.it_nu_fac = socio.it_nu_fac
                                         WHERE
                                              t.it_nu_inscricao_estadual = :CO_CAD_ICMS
                                         GROUP BY
                                              socio.gr_identificacao
                                  )
                  )
             GROUP BY
                  co_cnpj_cpf, cpf_cnpj_socio, nome_socio, it_nu_inscricao_estadual, no_razao_social,
                  entrada, saida, ult_fac, inadimplencia, no_municipio, in_situacao, in_conder,
                  da_inicio_atividade, no_situacao_contribuinte
             ORDER BY
                  nome_socio, no_razao_social DESC
      )
 GROUP BY
      GROUPING SETS((cpf_cnpj_socio, nome_socio),(cpf_cnpj_socio, nome_socio, cnpj_cpf, it_nu_inscricao_estadual,
                    nome, entrada, saida, ult_fac, no_municipio, in_situacao, in_conder,
                    da_inicio_atividade, no_situacao_contribuinte))
 ORDER BY
      nome_socio, saida DESC, entrada DESC
