/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > DET
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CNPJ_CPF | prompt=CO_CNPJ_CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
            t.dt_envio,
      t.id_notificacao,
      upper(t.tx_descricao) descricao,

      case when t.tp_status = '4 - CIENCIA' then  '<html><font color="blue">'||t.tp_status||' - '||t.dt_ciencia||' - <b><font color="black">'||t.co_cpf_cnpj_ciencia||' - '||t.no_pessoa_ciencia
      when t.tp_status = '3 - TACITA' then  '<html><font color="red">'||t.tp_status
      else t.tp_status end ciencia,
      t.nu_ip_ciencia ip_ciencia,
      n.cpf||'   '||p.no_razao_social notificador
  FROM
      bi.fato_det_notificacao    t
        LEFT JOIN det.notificadores          n ON t.id_notificador = n.id
        LEFT JOIN bi.dm_pessoa               p ON n.cpf = p.co_cnpj_cpf
 WHERE
      t.id_fisconforme IS NULL
         AND co_cnpj_notif = :CO_CNPJ_CPF
         and t.tp_status not in('1 - PROCESSADA', '5 - CANCELADA')
order by t.dt_envio desc
