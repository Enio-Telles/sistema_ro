/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Ações Fiscais > Autos de Infração
ESTILO: Table
HABILITADA: true
BINDS:
 - ACAO_FISCAL | prompt=ACAO_FISCAL | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
select
							t.da_lavratura_auto     da_lavratura,
							t.nu_termo_infracao,
							t.no_local_lavratura,
							t.va_tributo,
							t.va_multa,
							t.va_juros,
							t.da_periodo_inicio_auto,
							t.da_periodo_final_auto,
							tate.no_situacao situacao_tate,
							t.nu_guia_lanc_trib,
							t.in_in_sit_lanc_trib   sit_guia_t,
							solid_trib.solidarios_trib  solid_trib,
							t.nu_guia_lanc_multa    ,
							t.in_in_sit_lanc_multa sit_guia_m,
							solid_multa.solidarios_multa solid_multa
						from bi.fato_acao_fiscal_ainf t
						left join bi.dm_acao_fiscal u 
							on t.nu_acao_fiscal = u.nu_acao_fiscal
						left join bi.dm_acao_fiscal_historico_tate tate
							on t.nu_termo_infracao = tate.nu_termo_infracao
						left join (select d.it_nu_guia, listagg(ptrib.co_cnpj_cpf||' - '||ptrib.no_razao_social,', ') within group (order by d.it_nu_guia) solidarios_trib 
									from sitafe.sitafe_devedor_solidario d
									left join bi.dm_pessoa ptrib
										on d.it_nu_cpf_cnpj_devedor = ptrib.co_cnpj_cpf
									group by d.it_nu_guia) solid_trib
							on solid_trib.it_nu_guia = t.nu_guia_lanc_trib
						left join (select d.it_nu_guia, listagg(pmulta.co_cnpj_cpf||' - '||pmulta.no_razao_social,', ') within group (order by d.it_nu_guia) solidarios_multa
									from sitafe.sitafe_devedor_solidario d
									left join bi.dm_pessoa pmulta
										on d.it_nu_cpf_cnpj_devedor = pmulta.co_cnpj_cpf
									group by d.it_nu_guia) solid_multa
							on solid_multa.it_nu_guia = t.nu_guia_lanc_multa
						left join bi.arr_f_lancamento_detalhe l
							   on l.numero_guia = t.nu_guia_lanc_multa
						where t.nu_acao_fiscal = :ACAO_FISCAL
							and tate.in_ultima = 9
							and (l.cnpj_cpf is null or l.cnpj_cpf = :CO_CNPJ_CPF)
						order by t.da_lavratura_auto desc
