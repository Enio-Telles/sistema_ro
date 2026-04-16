/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_pessoa_fisica.xml
CAMINHO_NO_XML: Dossiê Pessoa Física 1.3 > Processo(s) Administrativo(s)
ESTILO: Table
HABILITADA: true
BINDS:
 - CPF | prompt=CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
      t.dt_abertura,
      t.nu_processo,
      t.co_servico,
      t.in_status,
      t.cpf_solicitante,
      serv.it_co_servico
      || ' - '
      || upper(
            convert(
                  serv.it_no_servico,
                  'AL32UTF8',
                  'WE8MSWIN1252'
            )
      )servico
  FROM
      bi.dm_processo_administrativo    t
        LEFT JOIN sitafe.sitafe_servico            serv ON t.co_servico = serv.it_co_servico
        LEFT JOIN bi.dm_pessoa                     pessoa ON t.cpf_solicitante = pessoa.co_cnpj_cpf
 WHERE
      t.co_cpf_cnpj_contribuinte = :CPF
 ORDER BY
      t.dt_abertura DESC
