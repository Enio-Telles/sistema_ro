/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Vistoria(s)
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CNPJ_CPF | prompt=CO_CNPJ_CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
with total as
							(
							select
								  'APP VISTORIA' tipo,
								  to_char(t.id)                                                             id,
								  t.status,
								  t.dt_vistoria,
								  t.modalidade_id || ' - ' || m.nome                                        modalidade,
								  t.dsf,
								  t.processo,
								  ps.no_razao_social                                                        solicitante,
								  p.no_razao_social                                                         auditor,
								  null                                                                      autos
							  from
								  vistoria.empresas_vistorias@vistoria_producao t
							left join vistoria.modalidades@vistoria_producao  m on t.modalidade_id = m.id
							left join bi.dm_pessoa p on t.cpf_auditor = p.co_cnpj_cpf
							left join bi.dm_pessoa ps on t.cpf_solicitante = ps.co_cnpj_cpf
							left join vistoria.documentos_assinados@vistoria_producao  d on t.id = d.empresa_vistoria_id
							where t.cnpj_empresa = :CO_CNPJ_CPF

							union

							select
									'SITAFE VISTORIA' as                                                    tipo,
									to_char(df.it_nu_diligencia)                                            id,
									case when df.it_co_situacao_diligencia = 01 then '01 - DOC. REGISTRADO'
										 when df.it_co_situacao_diligencia = 02 then '02 - DIL. GERADA'
										 when df.it_co_situacao_diligencia = 03 then '03 - DIL. ENTREGUE'
										 when df.it_co_situacao_diligencia = 04 then '04 - DIL. CONCLUÍDA'
										 when df.it_co_situacao_diligencia = 05 then '05 - DIL. EXCLUÍDA'
									end                                                                     status,
									to_date(df.it_da_lancamento,'yyyymmdd')                                 dt_vistoria,
									dft.it_nu_documento_origem                                              modalidade,
									null                                                                    dsf,
									dft.it_nu_diligencia                                                    processo,
									null                                                                    solicitante,
									su.it_co_matricula_usuario||' - '||su.it_no_usuario                     auditor,
									da.autos                                                                autos
							from sitafe.sitafe_diligencia_fiscal_taref dft
							left join sitafe.sitafe_diligencia_fiscal df
								   on df.it_nu_diligencia = substr(dft.it_nu_diligencia,1,5)||'7'||substr(dft.it_nu_diligencia,7)
							left join sitafe.sitafe_dilig_it_nu_afte afte
								   on afte.tuk = df.tuk
								  and afte.m_occurs = 1
							left join sitafe.sitafe_usuario su
								   on to_number(su.it_co_matricula_usuario) = to_number(afte.it_nu_afte)
							left join (select da.it_nu_acao_fiscal,
											  listagg(da.it_nu_ai,' * ' on overflow truncate) within group (order by da.it_nu_acao_fiscal) autos
										 from sitafe.sitafe_diligencia_autos da
									 group by da.it_nu_acao_fiscal) da
									   on da.it_nu_acao_fiscal = df.it_nu_diligencia
							where dft.it_nu_identificacao = :CO_CNPJ_CPF--'12238651000101'
							)

							SELECT
								t.tipo,
								t.id,
								t.status,
								t.dt_vistoria,
								t.modalidade,
								t.dsf,
								t.processo,
								t.solicitante,
								t.auditor,
								t.autos,
								d.documento_assinatura relatorio
							FROM
								total                                           t
								LEFT JOIN vistoria.documentos_assinados@vistoria_producao d ON t.tipo || t.id = 'APP VISTORIA' || d.empresa_vistoria_id
							order by 4 desc
