/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Dados cadastrais
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CNPJ_CPF | prompt=CO_CNPJ_CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
								  t.co_cnpj_cpf 																		"CNPJ",
								  t.co_cad_icms 																		"IE",
								  '<html><b>' || t.no_razao_social														"Nome",
								  t.DESC_ENDERECO||' '||t.BAIRRO 														"Endereço",
								  localid.no_municipio																	"Município",
								  localid.co_uf																			"UF",
								  t.co_regime_pagto|| ' - '|| rp.no_regime_pagamento									"Regime de Pagamento",
								  CASE WHEN t.in_situacao = '001'
										THEN '<html><p style="color:blue">'||t.in_situacao
											|| ' - '|| s.desc_situacao
										ELSE '<html><p style="color:red">'|| t.in_situacao
											  || ' - '|| convert(s.desc_situacao,'AL32UTF8','WE8MSWIN1252')
										END																				"Situação da IE",
								  t.da_inicio_atividade																	"Data de Início da Atividade",
								  to_date(us.data_ult_sit, 'YYYYMMDD')													"Data da última situação",
								  to_char(trunc(months_between((CASE WHEN t.in_situacao = '001'
																		THEN SYSDATE
																	ELSE to_date(us.data_ult_sit, 'YYYYMMDD')
																END),
																t.da_inicio_atividade),2))||' meses' 					"Período em atividade",
								  'https://portalcontribuinte.sefin.ro.gov.br/Publico/parametropublica.jsp?NuDevedor=' || t.co_cad_icms redesim
							  FROM
								  bi.dm_pessoa                 t
									LEFT JOIN bi.dm_localidade localid ON t.co_municipio = localid.co_municipio
									LEFT JOIN bi.dm_regime_pagto_descricao rp ON t.co_regime_pagto = rp.co_regime_pagamento
									LEFT JOIN(
												SELECT
														CO_SITUACAO_CONTRIBUINTE    CO_SITUACAO,
														NO_SITUACAO_CONTRIBUINTE    DESC_SITUACAO
													FROM BI.DM_SITUACAO_CONTRIBUINTE
										  )	s ON t.in_situacao = s.co_situacao
									LEFT JOIN(
												SELECT
														MAX(u.it_da_transacao) data_ult_sit,
														u.it_nu_inscricao_estadual
												  FROM
														sitafe.sitafe_historico_gr_situacao t
														LEFT JOIN sitafe.sitafe_historico_situacao    u ON t.tuk = u.tuk
												 WHERE
													  t.it_co_situacao_contribuinte NOT IN('030','150','005')
														 AND u.it_co_usuario NOT IN('INTERNET','P30015AC   ')
												 GROUP BY
													  u.it_nu_inscricao_estadual
										  )	us ON t.co_cad_icms = us.it_nu_inscricao_estadual
							 WHERE
								  t.co_cnpj_cpf = :CO_CNPJ_CPF
