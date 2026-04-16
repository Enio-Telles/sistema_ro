/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > NFs Entrada - Quantidades > Emitente(s)
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CNPJ_CPF | prompt=CO_CNPJ_CPF | default=NULL_VALUE
 - ANO | prompt=ANO | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
	  ano,
	  co_emitente,
	  case when co_emitente is null then null else nome end nome,
	  case when co_emitente is null then null else municipio end municipio,
	  uf,
	  quant,
	  rr,
	  total,
	  icms,
	  icms_st
  FROM
	  (
			SELECT
				  EXTRACT(YEAR FROM dhemi) ano,
				  t.co_emitente,
				  upper(
						MAX(xnome_emit)
				  )                        nome,
				  upper(
						MAX(xmun_emit)
				  )                        municipio,
				  t.co_uf_emit            uf,
				  'T '
				  || to_char(
						COUNT(DISTINCT chave_acesso)
				  )
				  || ', F '
				  || to_char(
						COUNT(DISTINCT f.it_nu_identificao_nf_e)
				  )                        quant,
				  lpad(
						TRIM(to_char(
							  round(
									RATIO_TO_REPORT(SUM(prod_vprod))
									OVER(PARTITION BY
										  CASE
												WHEN EXTRACT(YEAR FROM dhemi)IS NULL THEN
													  1
												ELSE
													  0
										  END
									),
									4
							  )* 100,
							  '990.00L',
							  'NLS_CURRENCY=%'
						)),
						8
				  )                        rr,
				  lpad(
						TRIM(to_char(
							  SUM(prod_vprod),
							  '999G999G999G990D00'
						)),
						length(
							   MAX(SUM(prod_vprod))
							   OVER()
						 )+ 6
				  )                        total,
				  lpad(
						TRIM(to_char(
							  SUM(icms_vicms),
							  '999G999G999G990D00'
						)),
						length(
							   MAX(SUM(icms_vicms))
							   OVER()
						 )+ 6
				  )                        icms,
				  lpad(
						TRIM(to_char(
							  SUM(icms_vicmsst),
							  '999G999G999G990D00'
						)),
						length(
							   MAX(SUM(icms_vicmsst))
							   OVER()
						 )+ 6
				  )                        icms_st
			  FROM
				  bi.fato_nfe_detalhe t
					LEFT JOIN(
						SELECT
							  f.it_nu_identificao_nf_e
						  FROM
							  sitafe.sitafe_nota_fiscal f
						 WHERE
							  f.it_nucnpj_cpf_destino_nf = :CO_CNPJ_CPF
				  )                    f ON t.chave_acesso = f.it_nu_identificao_nf_e
			 WHERE
						co_destinatario = :CO_CNPJ_CPF
					 AND t.infprot_cstat IN('100',
											'150')
					 AND EXTRACT(YEAR FROM dhemi)= :ANO
			 GROUP BY
				  GROUPING SETS((),(EXTRACT(YEAR FROM dhemi),
									t.co_uf_emit,
									t.co_emitente))
			 ORDER BY
				  total DESC
	  )
