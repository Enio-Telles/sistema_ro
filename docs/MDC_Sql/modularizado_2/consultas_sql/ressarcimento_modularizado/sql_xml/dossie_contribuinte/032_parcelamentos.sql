/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Parcelamentos
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CNPJ_CPF | prompt=CO_CNPJ_CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
							t.it_nu_proc_parcelamento,
							CASE
                                WHEN t.it_in_situacao_parcelamento = '0'    THEN
									'Cancelado'
								WHEN t.it_in_situacao_parcelamento = '1'    THEN
									'Deferido / Pago'
								WHEN t.it_in_situacao_parcelamento = '2'    THEN
									'Indeferido / Cancelado'
								WHEN t.it_in_situacao_parcelamento = '3'    THEN
									'Aguardando deferimento / Não pago'
								WHEN t.it_in_situacao_parcelamento = '4'    THEN
									'Liquidado'
								WHEN t.it_in_situacao_parcelamento = '5'    THEN
									'Reparcelado'
								WHEN t.it_in_situacao_parcelamento = '6'    THEN
									'Cancelado'
								WHEN t.it_in_situacao_parcelamento = '7'    THEN
									'Indeferido por falta de garantia'
								WHEN t.it_in_situacao_parcelamento = '8'    THEN
									'Inscrito em dívida ativa'
								WHEN t.it_in_situacao_parcelamento = '9'    THEN
									'Excluído'
								WHEN t.it_in_situacao_parcelamento = ' '    THEN
									'Ainda não confirmado'
								ELSE
									NULL
							END situacao_parc,
							t.it_co_receita,
							t.it_nu_guia_parcelamento,
							t.it_qt_parcela,
							t.it_va_principal,
							t.it_va_total_parcelamento,
							t.it_va_parcela_inicial,
							t.it_va_total_parc_inic,
							t.it_va_parcela_vincenda,
							t.it_va_total_parc_vinc
						FROM
							sitafe.sitafe_parcelamento t
						WHERE SUBSTR(t.gr_identificacao,2,14) = :CO_CNPJ_CPF
						ORDER BY
							t.it_da_parcelamento DESC
