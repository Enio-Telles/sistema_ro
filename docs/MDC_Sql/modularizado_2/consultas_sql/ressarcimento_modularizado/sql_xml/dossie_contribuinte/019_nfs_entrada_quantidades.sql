/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > NFs Entrada - Quantidades
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CNPJ_CPF | prompt=CO_CNPJ_CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
select :CO_CNPJ_CPF CO_CNPJ_CPF, ano,
sum(total_nfes) total,
sum(origem_ro) RO,
sum(origem_ouf) O_UF,
sum(fronteira) FR,
listagg(case when co_uf_emit != 'RO' then '<html><b>'||co_uf_emit||'</b> (T '||total_nfes||' - F '||fronteira||')' end, '   |   ') within group (order by total_nfes desc) origem_outras_UFs

from (
SELECT
	  EXTRACT(YEAR FROM dhemi)                 ano,
	  t.co_uf_emit,
	  COUNT(DISTINCT chave_acesso)             total_nfes,
	  COUNT(DISTINCT
			CASE
				  WHEN co_uf_emit = 'RO' THEN
						chave_acesso
				  ELSE
						NULL
			END
	  )                                        origem_ro,
	  COUNT(DISTINCT
			CASE
				  WHEN co_uf_emit != 'RO' THEN
						chave_acesso
				  ELSE
						NULL
			END
	  )                                        origem_ouf,
	  COUNT(DISTINCT f.it_nu_identificao_nf_e) fronteira
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
 GROUP BY
	  EXTRACT(YEAR FROM dhemi),
	  t.co_uf_emit) b
	  
group by ano

order by ano desc
