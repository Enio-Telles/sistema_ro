/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Contador
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CAD_ICMS | prompt=CO_CAD_ICMS | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
select
								case when b.fim_ref is null and b.co_cnpj_cpf_contador = '   -   ' then '<html><b>Atual - sem contador indicado'
									 when b.fim_ref is null and b.co_cnpj_cpf_contador != '   -   ' then '<html><b>Atual'
									 when b.fim_ref is not null and b.co_cnpj_cpf_contador = '   -   ' then 'Anterior - Período sem indicação de contador'
									 else 'Anterior'
								end                     situacao,
								b.co_cnpj_cpf_contador  co_cnpj_cpf_contador,
								p.no_razao_social       nome,
								l.no_municipio          municipio,
								l.co_uf                 uf,
								b.ini_ref               inicio,
								b.fim_ref               fim
								from
								(
									select
										it_nu_inscricao_estadual                   ie,
										cnpj,
										case when substr(gr_ident_contador, 2) is null then '   -   '
											 else substr(gr_ident_contador, 2)
										end                                        co_cnpj_cpf_contador,
										to_date(it_da_referencia, 'yyyymmdd')      ini_ref,
										case
											when lead(it_da_referencia) over(order by it_nu_fac ) is null then null
											else to_date(lead(it_da_referencia) over(order by it_nu_fac), 'yyyymmdd')
										end                                        fim_ref
									from
										(
											select
												c.it_nu_inscricao_estadual,
												substr(c.gr_identificacao, 2)        cnpj,
												c.it_nu_fac,
												c.it_da_referencia,
												c.gr_ident_contador,
												case
													when row_number() over( order by c.it_nu_fac ) = 1  then 1
													when c.gr_ident_contador != lag(c.gr_ident_contador) over( order by c.it_nu_fac ) then 1
													else 0
												end                                  usar
											from
												sitafe.sitafe_historico_contribuinte c
											where
												c.it_nu_inscricao_estadual = :CO_CAD_ICMS
											order by
												c.it_nu_inscricao_estadual,
												c.it_nu_fac
										)
									where
										usar = 1
									order by
											case
												when lead(it_da_referencia) over( order by it_nu_fac ) is null then '99999999'
												else lead(it_da_referencia) over( order by it_nu_fac )
											end
										desc
								)               b
								left join bi.dm_pessoa    p on b.co_cnpj_cpf_contador = p.co_cnpj_cpf
								left join bi.dm_localidade l on p.co_municipio = l.co_municipio
