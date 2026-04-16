/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_pessoa_fisica.xml
CAMINHO_NO_XML: Dossiê Pessoa Física 1.3 > Empresas em que é/foi sócio(a)
ESTILO: Table
HABILITADA: true
BINDS:
 - CPF | prompt=CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
      b.inicio_ativ,
      b.cnpj_cpf,
      b.ie,
      '<html><b>'||b.nome nome,
      b.municipio,
      b.rp,
      CASE
            WHEN b.in_situacao = '001' THEN
                  '<html><p style="color:blue">' || b.situacao
            ELSE
                  '<html><p style="color:red">' || b.situacao
      END          situacao,
      to_date(b.da_entr, 'yyyymmdd')    inicio_part,
      CASE
            WHEN ult_fac = 9 THEN
                  NULL
            ELSE
                  to_date(b.da_saida, 'yyyymmdd') 
      END          fim_part,
      '<html><font color="red">'
      || lpad(
            TRIM(to_char(
                  b.total,
                  '999G999G999G990D00'
            )),
            length(
                         b.total
                   )+ 6
      )            inadimplencia
  FROM
      (
            SELECT
                  p.co_cnpj_cpf                                                                cnpj_cpf,
                  t.it_nu_inscricao_estadual                                                   ie,
                  p.no_razao_social                                                            nome,
                  l.no_municipio                                                               municipio,
                  p.in_situacao,
                  p.in_situacao
                  || ' - '
                  || s.no_situacao                                                             situacao,
                  p.co_regime_pagto
                  || ' - '
                  || r.no_regime_pagamento                                                     rp,
                  p.da_inicio_atividade                                                        inicio_ativ,
                  MIN(h.it_da_referencia)
                  OVER(PARTITION BY h.it_nu_inscricao_estadual || t.gr_identificacao)          da_entr,
                  MAX(h.it_da_referencia)
                  OVER(PARTITION BY h.it_nu_inscricao_estadual || t.gr_identificacao)          da_saida,
                  MAX(h.it_in_ultima_fac)
                  OVER(PARTITION BY h.it_nu_inscricao_estadual || t.gr_identificacao)          ult_fac,
                  total
              FROM
                  sitafe.sitafe_historico_socio           t
                    LEFT JOIN sitafe.sitafe_historico_contribuinte    h ON t.it_nu_fac = h.it_nu_fac
                    LEFT JOIN bi.dm_pessoa                            p ON substr(
                        h.gr_identificacao,
                        2
                  )= p.co_cnpj_cpf
                    LEFT JOIN bi.dm_localidade                        l ON p.co_municipio = l.co_municipio
                    LEFT JOIN bi.dm_regime_pagto_descricao            r ON p.co_regime_pagto = r.co_regime_pagamento
                    LEFT JOIN bi.vw_situacao_contribuinte             s ON p.in_situacao = s.in_situacao
                    LEFT JOIN sitafe.sitafe_tabelas_cadastro          tb ON t.it_co_cargo_socio = tb.it_co_cargo_socio
                    LEFT JOIN(
                        SELECT
                              v.co_cnpj_cpf,
                              SUM(v.va_principal + v.va_multa + v.va_juros + v.va_acrescimo)total
                          FROM
                              bi.fato_lanc_arrec_sum v
                         WHERE
                                    v.vencido = 3
                                 AND v.id_situacao = '01'
                         GROUP BY
                              v.co_cnpj_cpf
                  )                                       vencido ON p.co_cnpj_cpf = vencido.co_cnpj_cpf
             WHERE
                  substr(
                        t.gr_identificacao,
                        2
                  )= :CPF
      )b
 GROUP BY
      b.inicio_ativ,
      b.cnpj_cpf,
      b.ie,
      b.nome,
      b.municipio,
      CASE
            WHEN b.in_situacao = '001' THEN
                        '<html><p style="color:blue">' || b.situacao
            ELSE
                  '<html><p style="color:red">' || b.situacao
      END,
      b.rp,
      b.da_entr,
      CASE
            WHEN ult_fac = 9 THEN
                  NULL
            ELSE
                  to_date(b.da_saida, 'yyyymmdd') 
      END ,
      '<html><font color="red">'
      || lpad(
            TRIM(to_char(
                  b.total,
                  '999G999G999G990D00'
            )),
            length(
                         b.total
                   )+ 6
      )
 ORDER BY
      fim_part DESC,
      inicio_part
