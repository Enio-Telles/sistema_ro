/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_pessoa_fisica.xml
CAMINHO_NO_XML: Dossiê Pessoa Física 1.3 > DIMP
ESTILO: Table
HABILITADA: true
BINDS:
 - CPF | prompt=CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
      case when ano is null and periodo is null then '<html><b style="color:blue">Σ TOTAL GERAL'
      when ano is not null and periodo is null then '<html><b style="color:green">Σ Total no ano '|| ano
      when ano is not null and periodo is not null then '----Total no período '||periodo
      END info,
      operacoes,
          lpad(
            TRIM(to_char(
                  total,
                  '999G999G999G990D00'
            )),
            length(
                   MAX(total)
                   OVER()
             )+7
      )    total


  FROM
      (
            SELECT
                  EXTRACT(YEAR FROM dt_ini)          ano,
                  EXTRACT(YEAR FROM dt_ini)
                  || '/'
                  || EXTRACT(MONTH FROM dt_ini)      periodo,
                  SUM(qtd)                           operacoes,
                  SUM(valor)                         total
              FROM
                  (
                        SELECT
                              t.cnpj,
                              reg0100.cpf,
                              reg1100.dt_ini,
                              reg1100.dt_fin,
                              reg1100.qtd,
                              reg1100.valor
                          FROM
                              dimp.reg0000s    t
                                LEFT JOIN dimp.reg0100s    reg0100 ON t.id = reg0100.reg0000_id
                                LEFT JOIN dimp.reg1100s    reg1100 ON t.id = reg1100.reg0000_id
                                 AND reg0100.cod_cliente = reg1100.cod_cliente
                         WHERE
                              reg0100.cpf = :CPF
                         GROUP BY
                              t.cnpj,
                              reg0100.cpf,
                              reg1100.dt_ini,
                              reg1100.dt_fin,
                              reg1100.qtd,
                              reg1100.valor
                  )
             GROUP BY
                  GROUPING SETS((),
                  (EXTRACT(YEAR FROM dt_ini)),(EXTRACT(YEAR FROM dt_ini),
                                               EXTRACT(YEAR FROM dt_ini)
                                               || '/'
                                               || EXTRACT(MONTH FROM dt_ini)))
      )

order by ano desc, periodo desc
