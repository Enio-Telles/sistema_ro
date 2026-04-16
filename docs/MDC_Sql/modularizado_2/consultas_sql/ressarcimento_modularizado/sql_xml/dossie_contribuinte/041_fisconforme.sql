/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > FisConforme
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CNPJ_CPF | prompt=CO_CNPJ_CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT

					  case when malha is null and status is null then
					  '<html><b>TOTAL DE NOTIFICAÇÕES RECEBIDAS: '||quant 
					  when malha is null and status is not null then
					   '<html><b>-------Quantidade '||status||': '||quant 
					  when malha is not null and periodo is null and status is null then
					  '<html>------------'||malha||' - <b>'||quant
					  else
					  '<html>'||malha||' - '||Status end info,
					  periodo,
					  co_cpf_cnpj_ciencia,
					  no_pessoa_ciencia,
					  dt_ciencia,
					  nu_ip_ciencia
				  FROM
					  (
							SELECT
								  t.malhas_id
								  || ' - '
								  || m.titulo     malha,
								  t.periodo,
										CASE
							WHEN t.status = 0  THEN
								  '<html><strong><font color="red">0 - Pendente'
							WHEN t.status = 1  THEN
								  '<html><strong><font color="orange">1 - Contestado'
							WHEN t.status = 2  THEN
								  '<html><strong><font color="blue">2 - Resolvido'
							WHEN t.status = 4  THEN
								  '<html><strong><font color="red">4 - Indeferido'
							WHEN t.status = 5  THEN
								  '<html><strong><font color="blue">5 - Deferido'
							WHEN t.status = 7  THEN
								  '<html><strong><font color="blue">7 - Deferido Automaticamente'
							ELSE
								  to_char(t.status)
					  END status,
								  n.co_cpf_cnpj_ciencia,
								  n.no_pessoa_ciencia,
								  n.dt_ciencia,
								  n.nu_ip_ciencia,
								  COUNT(distinct t.id)        quant
							  FROM
								  app_pendencia.pendencias    t
									LEFT JOIN app_pendencia.malhas        m ON t.malhas_id = m.id
									LEFT JOIN bi.fato_det_notificacao     n ON t.id = n.id_fisconforme
							 WHERE
								  cpf_cnpj = :CO_CNPJ_CPF
							 GROUP BY
								  GROUPING SETS((),(                  t.malhas_id
								  || ' - '
								  || m.titulo),
								  (CASE
							WHEN t.status = 0  THEN
								  '<html><strong><font color="red">0 - Pendente'
							WHEN t.status = 1  THEN
								  '<html><strong><font color="orange">1 - Contestado'
							WHEN t.status = 2  THEN
								  '<html><strong><font color="blue">2 - Resolvido'
							WHEN t.status = 4  THEN
								  '<html><strong><font color="red">4 - Indeferido'
							WHEN t.status = 5  THEN
								  '<html><strong><font color="blue">5 - Deferido'
							WHEN t.status = 7  THEN
								  '<html><strong><font color="blue">7 - Deferido Automaticamente'
							ELSE
								  to_char(t.status)
					  END),(t.malhas_id
											  || ' - '
											  || m.titulo,
											  t.periodo,
													CASE
							WHEN t.status = 0  THEN
								  '<html><strong><font color="red">0 - Pendente'
							WHEN t.status = 1  THEN
								  '<html><strong><font color="orange">1 - Contestado'
							WHEN t.status = 2  THEN
								  '<html><strong><font color="blue">2 - Resolvido'
							WHEN t.status = 4  THEN
								  '<html><strong><font color="red">4 - Indeferido'
							WHEN t.status = 5  THEN
								  '<html><strong><font color="blue">5 - Deferido'
							WHEN t.status = 7  THEN
								  '<html><strong><font color="blue">7 - Deferido Automaticamente'
							ELSE
								  to_char(t.status)
					  END,
											  n.co_cpf_cnpj_ciencia,
											  n.no_pessoa_ciencia,
											  n.dt_ciencia,
											  n.nu_ip_ciencia))
					  )
				order by case when malha is null and status is null then 1
					  when malha is null and status is not null then 2
					  when malha is not null and periodo is null and status is null then 3
					  else 4 end, periodo desc, quant desc
