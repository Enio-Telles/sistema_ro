/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Manifesto(s)
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CNPJ_CPF | prompt=CO_CNPJ_CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
WITH chaves_nfe AS(
						  SELECT
								chave_acesso
							FROM
								bi.fato_nfe_detalhe
						   WHERE
								co_destinatario = :CO_CNPJ_CPF or co_emitente = :CO_CNPJ_CPF
						   GROUP BY
								chave_acesso
					)
					select md.it_nu_chave_mdfe, md.it_da_emissao, md.it_uf_inicio, md.it_uf_fim, md.it_cnpj_emitente, md.it_uf_emitente, md.it_nu_placa_veiculo, md.it_nu_placa_reboque1, md.it_nu_placa_uf, md.it_valor_carga, md.it_cpf_motorista, md.it_no_motorista, :CO_CNPJ_CPF CO_CNPJ_CPF from (
					SELECT
						  distinct it_nu_chave_mdfe
					  FROM
						  (
								SELECT
									  it_nu_chave_mdfe
								  FROM
										   sitafe.sitafe_mdfe_item m
									   INNER JOIN sitafe.sitafe_cte_itens    c ON m.it_nu_chave_acesso = c.it_nu_chave_cte
									   INNER JOIN chaves_nfe                 ch ON c.it_nu_chave_nfe = ch.chave_acesso
								UNION ALL
								SELECT
									  it_nu_chave_mdfe
								  FROM
										   sitafe.sitafe_mdfe_item m
									   INNER JOIN chaves_nfe ch ON m.it_nu_chave_acesso = ch.chave_acesso
						  ))g
					LEFT JOIN sitafe.sitafe_mdfe    md ON g.it_nu_chave_mdfe = md.it_nu_chave_mdfe
					order by md.it_da_emissao desc
