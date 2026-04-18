/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Autos de Infração
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CNPJ_CPF | prompt=CO_CNPJ_CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
WITH ACAO_FISCAL AS (
							SELECT SUBSTR(DFT.IT_NU_DILIGENCIA,1,5)||'7'||SUBSTR(DFT.IT_NU_DILIGENCIA,7)  NU_ACAO_FISCAL FROM SITAFE.SITAFE_DILIGENCIA_FISCAL_TAREF DFT WHERE DFT.IT_NU_IDENTIFICACAO = :CO_CNPJ_CPF
							UNION
							SELECT T.NU_ACAO_FISCAL FROM BI.DM_ACAO_FISCAL T WHERE T.CO_CNPJ_CPF = :CO_CNPJ_CPF
                            UNION
                            SELECT AINF.NU_ACAO_FISCAL FROM BI.ARR_F_LANCAMENTO_DETALHE L INNER JOIN BI.FATO_ACAO_FISCAL_AINF AINF ON AINF.NU_GUIA_LANC_MULTA = L.NUMERO_GUIA WHERE L.CNPJ_CPF = :CO_CNPJ_CPF
                            )
							SELECT
									CNPJ_CPF,
                                    DA_LAVRATURA,
									NU_TERMO_INFRACAO,
									CASE WHEN LOCAL IS NULL THEN '<html><b>VALOR TOTAL DOS AUTOS DE INFRAÇÕES LAVRADOS:' ELSE LOCAL END LOCAL,
									LPAD(TRIM(TO_CHAR(VA_TRIBUTO, '999G999G999G990D00')),18) VA_TRIBUTO,
									LPAD(TRIM(TO_CHAR(VA_MULTA, '999G999G999G990D00')),18) VA_MULTA,
									LPAD(TRIM(TO_CHAR(VA_JUROS, '999G999G999G990D00')),18) VA_JUROS,
									LPAD(TRIM(TO_CHAR(TOTAL, '999G999G999G990D00')),18) TOTAL,
									PERIODO_FISCALIZADO,
									SITUACAO_TATE,
									GUIA_T,
									SIT_GUIA_T,
									SOLID_TRIB,
									GUIA_M,
									SIT_GUIA_M,
									SOLID_MULTA
							FROM (
							SELECT
									L.CNPJ_CPF,
                                    T.DA_LAVRATURA_AUTO                                                     DA_LAVRATURA,
									T.NU_TERMO_INFRACAO                                                     NU_TERMO_INFRACAO,
									UPPER(CONVERT(T.NO_LOCAL_LAVRATURA,'AL32UTF8','WE8MSWIN1252'))          LOCAL,
									SUM(T.VA_TRIBUTO)                                                       VA_TRIBUTO,
									SUM(T.VA_MULTA)                                                         VA_MULTA,
									SUM(T.VA_JUROS)                                                         VA_JUROS,
									SUM(T.VA_TRIBUTO + T.VA_MULTA + T.VA_JUROS)                             TOTAL,
									'  '||
										T.DA_PERIODO_INICIO_AUTO|| '    -    '||
										T.DA_PERIODO_FINAL_AUTO|| '  '                                      PERIODO_FISCALIZADO,
									TATE.NO_SITUACAO                                                        SITUACAO_TATE,
									T.NU_GUIA_LANC_TRIB                                                     GUIA_T,
									T.IN_IN_SIT_LANC_TRIB                                                   SIT_GUIA_T,
									SOLID_TRIB.SOLIDARIOS_TRIB                                              SOLID_TRIB,
									T.NU_GUIA_LANC_MULTA                                                    GUIA_M,
									T.IN_IN_SIT_LANC_MULTA                                                  SIT_GUIA_M,
									SOLID_MULTA.SOLIDARIOS_MULTA                                            SOLID_MULTA
							FROM ACAO_FISCAL A
								LEFT JOIN BI.FATO_ACAO_FISCAL_AINF T ON A.NU_ACAO_FISCAL = T.NU_ACAO_FISCAL
								LEFT JOIN BI.DM_ACAO_FISCAL U ON T.NU_ACAO_FISCAL = U.NU_ACAO_FISCAL
								LEFT JOIN BI.DM_ACAO_FISCAL_HISTORICO_TATE TATE ON T.NU_TERMO_INFRACAO = TATE.NU_TERMO_INFRACAO
							LEFT JOIN (SELECT D.IT_NU_GUIA,
											  LISTAGG(PTRIB.CO_CNPJ_CPF||' - '||PTRIB.NO_RAZAO_SOCIAL,', ') WITHIN GROUP (ORDER BY D.IT_NU_GUIA) SOLIDARIOS_TRIB
										 FROM SITAFE.SITAFE_DEVEDOR_SOLIDARIO D
									LEFT JOIN BI.DM_PESSOA PTRIB
										   ON D.IT_NU_CPF_CNPJ_DEVEDOR = PTRIB.CO_CNPJ_CPF
									 GROUP BY D.IT_NU_GUIA
									  ) SOLID_TRIB
									 ON SOLID_TRIB.IT_NU_GUIA = T.NU_GUIA_LANC_TRIB
							LEFT JOIN (SELECT D.IT_NU_GUIA,
											  LISTAGG(PMULTA.CO_CNPJ_CPF||' - '||PMULTA.NO_RAZAO_SOCIAL,', ') WITHIN GROUP (ORDER BY D.IT_NU_GUIA) SOLIDARIOS_MULTA
										 FROM SITAFE.SITAFE_DEVEDOR_SOLIDARIO D
									LEFT JOIN BI.DM_PESSOA PMULTA
										   ON D.IT_NU_CPF_CNPJ_DEVEDOR = PMULTA.CO_CNPJ_CPF
									 GROUP BY D.IT_NU_GUIA
									 ) SOLID_MULTA
									ON SOLID_MULTA.IT_NU_GUIA = T.NU_GUIA_LANC_MULTA
							LEFT JOIN BI.ARR_F_LANCAMENTO_DETALHE L
                                   ON T.NU_TERMO_INFRACAO = L.NUMERO_COMPLEMENTO
                            WHERE TATE.IN_ULTIMA = 9
                              AND (L.CNPJ_CPF IS NULL OR L.CNPJ_CPF = :CO_CNPJ_CPF)
							GROUP BY GROUPING SETS((),(L.CNPJ_CPF,
                                                       T.DA_LAVRATURA_AUTO,
													   T.NU_TERMO_INFRACAO,
													   UPPER(CONVERT(T.NO_LOCAL_LAVRATURA,'AL32UTF8','WE8MSWIN1252')),
														'  '|| T.DA_PERIODO_INICIO_AUTO|| '    -    '|| T.DA_PERIODO_FINAL_AUTO|| '  ',
														TATE.NO_SITUACAO,
														T.NU_GUIA_LANC_TRIB,
														T.IN_IN_SIT_LANC_TRIB,
														SOLID_TRIB.SOLIDARIOS_TRIB,
														T.NU_GUIA_LANC_MULTA,
														T.IN_IN_SIT_LANC_MULTA,
														SOLID_MULTA.SOLIDARIOS_MULTA)
													)
							ORDER BY T.DA_LAVRATURA_AUTO DESC)
