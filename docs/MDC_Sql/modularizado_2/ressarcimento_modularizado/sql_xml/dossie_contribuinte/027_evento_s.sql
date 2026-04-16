/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Manifesto(s) > Evento(s)
ESTILO: Table
HABILITADA: true
BINDS:
 - IT_NU_CHAVE_MDFE | prompt=IT_NU_CHAVE_MDFE | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
									  z.*,
									  a.xml
								  FROM
									  xdb_mdfe.arquivo a,
									  XMLTABLE(XMLNAMESPACES(DEFAULT 'http://www.portalfiscal.inf.br/mdfe'), '//eventoMDFe/infEvento'
												  PASSING a.xml
											COLUMNS
												  corgao NUMBER PATH '//cOrgao',
												  dhevento timestamp with time zone PATH '//dhEvento',
												  tpevento VARCHAR2(60) PATH '//tpEvento',
												  nseqevento VARCHAR2(60) PATH '//nSeqEvento',
												  descEvento VARCHAR2(250) PATH '//detEvento//descEvento',
												  tpTransm VARCHAR2(250) PATH '//detEvento//tpTransm',
												  cUFTransito VARCHAR2(250) PATH '//detEvento//*/cUFTransito',
												  cIdEquip VARCHAR2(250) PATH '//detEvento//*/cIdEquip',
												  xIdEquip VARCHAR2(250) PATH '//detEvento//*/xIdEquip',
												  tpEquip VARCHAR2(250) PATH '//detEvento//*/tpEquip',
												  placa VARCHAR2(250) PATH '//detEvento//*/placa',
												  tpSentido VARCHAR2(250) PATH '//detEvento//*/tpSentido',
												  dhPass VARCHAR2(250) PATH '//detEvento//*/dhPass',
												  xUnidFiscal VARCHAR2(250) PATH '//detEvento//*/xUnidFiscal',
												  xObs VARCHAR2(250) PATH '//detEvento//*/xObs',
												  latitude VARCHAR2(250) PATH '//detEvento//*/latitude',
												  longitude VARCHAR2(250) PATH '//detEvento//*/longitude'

									  ) z
								 WHERE
											substr(
												  a.xml_schema,
												  1,
												  8
											)= 'procEven'
										 AND chave_acesso = :IT_NU_CHAVE_MDFE
										 order by dhevento
