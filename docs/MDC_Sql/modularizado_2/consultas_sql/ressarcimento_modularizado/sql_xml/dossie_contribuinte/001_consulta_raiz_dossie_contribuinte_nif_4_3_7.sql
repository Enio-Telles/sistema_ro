/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7
ESTILO: Table
HABILITADA: true
BINDS:
 - CNPJ | prompt=CNPJ | default=49746556000110
 - IE | prompt=IE | default=NULL_VALUE
 - NOME | prompt=NOME | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
						  case when co_cnpj_cpf is null then :CNPJ else co_cnpj_cpf end co_cnpj_cpf,
						  co_cad_icms,
						  nome,
						  inicio_ativ
					  FROM 
						  dual
							LEFT JOIN(
								SELECT
									  t.co_cnpj_cpf,
									  t.co_cad_icms,
									  '<html><b>' || t.no_razao_social nome,
									  t.da_inicio_atividade            inicio_ativ
								  FROM
									  bi.dm_pessoa t
								 WHERE 
									  t.co_cnpj_cpf like '%'||regexp_replace(:CNPJ,'\D+', '')||'%'
								  and t.co_cad_icms like '%'||regexp_replace(:IE,'\D+', '')
								  and upper(t.no_razao_social) like '%'||regexp_replace(upper(:NOME),'\s', '%')||'%'
						  )b ON b.co_cnpj_cpf like REGEXP_REPLACE(:CNPJ,'\D+', '')||'%'
					order by 
						case when :NOME is not null then nome end
