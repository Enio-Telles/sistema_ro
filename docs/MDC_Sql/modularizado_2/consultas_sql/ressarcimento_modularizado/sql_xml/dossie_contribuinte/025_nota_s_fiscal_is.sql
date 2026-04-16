/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Manifesto(s) > Nota(s) Fiscal(is)
ESTILO: Table
HABILITADA: true
BINDS:
 - IT_NU_CHAVE_MDFE | prompt=IT_NU_CHAVE_MDFE | default=NULL_VALUE
 - CO_CNPJ_CPF | prompt=CO_CNPJ_CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
								n.chave_acesso,
								n.co_emitente,
								'<html><b>'||n.xnome_emit nome,
								sum(n.prod_vprod+n.prod_vfrete+ n.prod_vseg+n.prod_voutro-n.prod_vdesc) total,
								sum(n.icms_vbc) bc_icms,
								sum(n.icms_vicms) icms,
								sum(n.icms_vbcst) bc_st,
								sum(n.icms_vicmsst) icms_st

								  FROM
									  sitafe.sitafe_mdfe_item t
								inner join sitafe.sitafe_cte_itens c on t.it_nu_chave_acesso = c.it_nu_chave_cte
								inner join bi.fato_nfe_detalhe n on c.it_nu_chave_nfe = n.chave_acesso
								where t.it_nu_chave_mdfe = :IT_NU_CHAVE_MDFE
									  and c.it_inf_tipo = 'NFE'
									  and (n.co_emitente = :CO_CNPJ_CPF or n.co_destinatario = :CO_CNPJ_CPF)

								group by n.chave_acesso,
								n.co_emitente,
								n.xnome_emit
