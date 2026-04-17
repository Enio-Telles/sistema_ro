/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Empresas dos Sócios > Conta Corrente
ESTILO: Table
HABILITADA: true
BINDS:
 - INFO | prompt=INFO | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
      CASE
            WHEN instr(
                  :INFO,
                  ' - '
            )= 34 THEN
                  substr(
                        :INFO,
                        20,
                        14
                  )
            ELSE
                  substr(
                        :INFO,
                        20,
                        11
                  )
      END CO_CNPJ_CPF,
      case when id_situacao is null then '<html><b>Σ TOTAL GERAL'
      when id_situacao = '01 - Não pago e Vencido' then '<html><b style="color:#CF3434">01 - Não pago e Vencido'
      when id_situacao = '01 - Não pago a vencer' then '<html><b style="color:#3440CF">01 - Não pago a Vencer'
      else  '<html><p style="color:#121212">'||id_situacao  end situacao,

      lpad(
            TRIM(to_char(
                  SUM(total),
                  '999G999G999G990D00'
            )),
            length(
                   MAX(SUM(total))
                   OVER()
             )+7
      )    total,
         lpad(TRIM(to_char(round(RATIO_TO_REPORT(SUM(total))
                       OVER(PARTITION BY case when id_situacao is null then 1 else 2 end), 4) * 100,
                 '990.00L',
                 'NLS_CURRENCY=%')),
      8)           rr,
      receitas
  FROM
      (
            SELECT
                  id_situacao_,
                  id_situacao,
                  SUM(valor)     total,
                  LISTAGG('<html><b>'
                          || id_receita
                          || '</b> - '
                          || '<i style="color:#854607">'||rr||'</i>',
                          '; ')WITHIN GROUP(
                         ORDER BY
                              rr DESC
                  )              receitas
              FROM
                  (
                        SELECT
                              id_situacao  id_situacao_,
                              CASE
                                    WHEN t.id_situacao = '01'
                                       AND t.da_vencimento < sysdate THEN
                                          '01 - Não pago e Vencido'
                                    WHEN t.id_situacao = '01'
                                       AND t.da_vencimento > sysdate THEN
                                          '01 - Não pago a vencer'
                                    ELSE
                                          t.id_situacao
                                          || ' - '
                                          || initcap(
                                                s.it_no_situacao
                                          )
                              END          id_situacao,
                              t.id_receita,
                              SUM(
                                    CASE
                                          WHEN t.va_pago IS NULL THEN
                                                (t.va_principal + t.va_multa + t.va_juros + t.va_acrescimo)
                                          ELSE
                                                t.va_pago
                                    END
                              )            valor,
                              lpad(
                                    TRIM(to_char(
                                          round(
                                                RATIO_TO_REPORT(SUM(
                                                      CASE
                                                            WHEN va_pago IS NULL THEN
                                                                  (t.va_principal + t.va_multa + t.va_juros + t.va_acrescimo)
                                                            ELSE
                                                                  t.va_pago
                                                      END
                                                ))
                                                OVER(PARTITION BY
                                                      CASE
                                                            WHEN t.id_situacao = '01'
                                                               AND t.da_vencimento < sysdate THEN
                                                                  '01 - Não pago e Vencido'
                                                            WHEN t.id_situacao = '01'
                                                               AND t.da_vencimento > sysdate THEN
                                                                  '01 - Não pago a vencer'
                                                            ELSE
                                                                  t.id_situacao
                                                                  || ' - '
                                                                  || initcap(
                                                                        s.it_no_situacao
                                                                  )
                                                      END
                                                ),
                                                4
                                          )* 100,
                                          '990.00L',
                                          'NLS_CURRENCY=%'
                                    )),
                                    8
                              )            rr
                          FROM
                              bi.fato_lanc_arrec           t
                                LEFT JOIN bi.dm_situacao_lancamento    s ON t.id_situacao = s.it_co_situacao
                         WHERE
                              t.id_cpf_cnpj =       CASE
            WHEN instr(
                  :INFO,
                  ' - '
            )= 34 THEN
                  substr(
                        :INFO,
                        20,
                        14
                  )
            ELSE
                  substr(
                        :INFO,
                        20,
                        11
                  )
      END
                         GROUP BY
                                    CASE
                                          WHEN t.id_situacao = '01'
                                             AND t.da_vencimento < sysdate THEN
                                                '01 - Não pago e Vencido'
                                          WHEN t.id_situacao = '01'
                                             AND t.da_vencimento > sysdate THEN
                                                '01 - Não pago a vencer'
                                          ELSE
                                                t.id_situacao
                                                || ' - '
                                                || initcap(
                                                      s.it_no_situacao
                                                )
                                    END,
                                    t.id_situacao,
                                    t.id_receita
                  )
             GROUP BY
                  id_situacao_,
                  id_situacao
      )
 GROUP BY
      GROUPING SETS((),(id_situacao_,
                        id_situacao,
                        receitas))

order by case when id_situacao_ is null then 1
                  when id_situacao_ = '01' then 2
                  else 3 end, total desc
