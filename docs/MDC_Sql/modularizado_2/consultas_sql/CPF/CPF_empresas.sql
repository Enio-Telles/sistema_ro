/*
    Analise da Consulta: CPF_empresas.sql
    Objetivo: Listar todas as empresas onde um CPF e/foi socio.

    Tabelas Utilizadas:
    - sitafe.sitafe_historico_socio (t): Historico de participacao societaria.
    - sitafe.sitafe_historico_contribuinte (h): Historico de contribuintes.
    - bi.dm_pessoa (p): Cadastro de pessoas juridicas.
    - bi.dm_localidade (l): Municipios.
    - bi.dm_regime_pagto_descricao (r): Regimes de pagamento.
    - bi.vw_situacao_contribuinte (s): Situacoes cadastrais.
    - bi.fato_lanc_arrec_sum (vencido): Debitos vencidos.

    Logica Principal:
    1. Busca o CPF informado como socio (gr_identificacao).
    2. Para cada empresa onde participou, obtem dados cadastrais.
    3. Calcula inadimplencia (debitos vencidos nao pagos).
    4. Mostra periodo de participacao (inicio/fim).
    5. Formata situacao: Azul = Ativo, Vermelho = Demais.
*/

SELECT
      b.inicio_ativ,
      b.cnpj_cpf,
      b.ie,
      b.nome nome,
      b.endereco,
      b.municipio,
      b.uf,
      b.rp,
      b.situacao,
      to_date(b.da_entr, 'yyyymmdd')    inicio_part,
      CASE
            WHEN ult_fac = 9 THEN
                  NULL
            ELSE
                  to_date(b.da_saida, 'yyyymmdd')
      END          fim_part,
      lpad(
            TRIM(to_char(
                  b.total,
                  '999G999G999G990D00'
            )),
            length(b.total)+ 6
      )            inadimplencia
  FROM
      (
            SELECT
                  p.co_cnpj_cpf                                                                cnpj_cpf,
                  t.it_nu_inscricao_estadual                                                   ie,
                  p.no_razao_social                                                            nome,
                  p.desc_endereco || ', ' || p.bairro                                          endereco,
                  l.no_municipio                                                               municipio,
                  l.co_uf                                                                      uf,
                  p.in_situacao,
                  p.in_situacao || ' - ' || s.no_situacao                                      situacao,
                  p.co_regime_pagto || ' - ' || r.no_regime_pagamento                          rp,
                  p.da_inicio_atividade                                                        inicio_ativ,
                  MIN(h.it_da_referencia) OVER(PARTITION BY h.it_nu_inscricao_estadual || t.gr_identificacao)          da_entr,
                  MAX(h.it_da_referencia) OVER(PARTITION BY h.it_nu_inscricao_estadual || t.gr_identificacao)          da_saida,
                  MAX(h.it_in_ultima_fac) OVER(PARTITION BY h.it_nu_inscricao_estadual || t.gr_identificacao)          ult_fac,
                  total
              FROM
                  sitafe.sitafe_historico_socio           t
                    LEFT JOIN sitafe.sitafe_historico_contribuinte    h ON t.it_nu_fac = h.it_nu_fac
                    LEFT JOIN bi.dm_pessoa                            p ON substr(h.gr_identificacao, 2)= p.co_cnpj_cpf
                    LEFT JOIN bi.dm_localidade                        l ON p.co_municipio = l.co_municipio
                    LEFT JOIN bi.dm_regime_pagto_descricao            r ON p.co_regime_pagto = r.co_regime_pagamento
                    LEFT JOIN bi.vw_situacao_contribuinte             s ON p.in_situacao = s.in_situacao
                    LEFT JOIN sitafe.sitafe_tabelas_cadastro          tb ON t.it_co_cargo_socio = tb.it_co_cargo_socio
                    LEFT JOIN(
                        -- Calculo de inadimplencia (debitos vencidos nao pagos)
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
                  substr(t.gr_identificacao, 2)= :CPF      -- CPF do socio
      )b
 GROUP BY
      b.inicio_ativ, b.cnpj_cpf, b.ie, b.nome, b.endereco, b.municipio, b.uf,
      b.situacao,
      b.rp, b.da_entr,
      CASE WHEN ult_fac = 9 THEN NULL ELSE to_date(b.da_saida, 'yyyymmdd') END,
      lpad(TRIM(to_char(b.total, '999G999G999G990D00')), length(b.total)+ 6)
 ORDER BY
      fim_part DESC,
      inicio_part
