/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_pessoa_fisica.xml
CAMINHO_NO_XML: Dossiê Pessoa Física 1.3 > Conta Corrente > Detalhe
ESTILO: Table
HABILITADA: true
BINDS:
 - CPF | prompt=CPF | default=NULL_VALUE
 - SITUACAO | prompt=SITUACAO | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
      da_vencimento,
      da_pagamento,
      nu_guia_parcela,
      nu_complemento,
      CASE
            WHEN da_vencimento IS NULL
               AND da_pagamento IS NULL THEN
                  '<html><b>' || receita
            ELSE
                  receita
      END            receita,
      lpad(
            TRIM(to_char(
                  round(
                        RATIO_TO_REPORT(SUM(total))
                        OVER(PARTITION BY
                              CASE
                                    WHEN da_vencimento IS NULL
                                       AND da_pagamento IS NULL THEN
                                          1
                                    ELSE
                                          2
                              END
                        ),
                        4
                  )* 100,
                  '990.00L',
                  'NLS_CURRENCY=%'
            )),
            8
      )              rr,
      
          lpad(
            TRIM(to_char(
                  SUM(total),
                  '999G999G999G990D00'
            )),
            length(
                   MAX(SUM(total))
                   OVER()
             )+7
      )    total  
      
  FROM
      (
            SELECT
                  t.da_vencimento,
                  t.da_pagamento,
                  t.nu_guia_parcela,
                  t.nu_complemento,
                  t.va_principal + t.va_multa + t.va_juros + t.va_acrescimo          total,
                  t.va_pago,
                  substr(
                        t.id_receita
                        || ' - '
                        || r.it_no_receita,
                        1,
                        100
                  )                                                                  receita
              FROM
                  bi.fato_lanc_arrec    t
                    LEFT JOIN bi.dm_receita         r ON t.id_receita = r.it_co_receita
             WHERE
                        id_cpf_cnpj = :CPF
                     AND(:SITUACAO = '<html><b>Σ TOTAL GERAL'
                      OR id_situacao = substr(
                        :SITUACAO,
                        32,
                        2
                  ))
      )
 GROUP BY
      GROUPING SETS((receita),(da_vencimento,
                               da_pagamento,
                               nu_guia_parcela,
                               nu_complemento,
                               receita))
 ORDER BY
      CASE
            WHEN da_vencimento IS NULL
               AND da_pagamento IS NULL THEN
                  1
            ELSE
                  2
      END,
      total DESC
