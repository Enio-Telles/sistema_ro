/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Histórico de Sócios > DIMP Sócios
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CNPJ_CPF | prompt=CO_CNPJ_CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
with 
						cartao as (
						select case
								when ano is null and periodo is null 
								  then '<html><b style="color:blue">Σ TOTAL GERAL'
								when ano is not null and periodo is null 
								  then '<html><b style="color:green">Σ Total no ano ' || ano
								when ano is not null and periodo is not null 
								  then '----Total no período ' || periodo
							   end                                                                      info,
							   operacoes,
							   cartao                                                                   cartao
						from(
						select extract(year from dt_op)                                                 ano,
							   extract(year from dt_op)||'/'||lpad(extract(month from dt_op),2,'0')     periodo,
							   count(*)                                                                 operacoes,
							   sum(valor)                                                               cartao
						from bi.mpg_f_detalhe_operacao
						where cnpj_cpf = :CO_CNPJ_CPF
						group by grouping sets 
								( ( ),
									(extract(year from dt_op)), 
										(extract(year from dt_op), extract(year from dt_op)||'/'||lpad(extract(month from dt_op),2,'0'))
								)
							 )
						order by ano desc, periodo desc
						),

						saidas as (
						select case
								when ano is null and periodo is null 
								  then '<html><b style="color:blue">Σ TOTAL GERAL'
								when ano is not null and periodo is null 
								  then '<html><b style="color:green">Σ Total no ano ' || ano
								when ano is not null and periodo is not null 
								  then '----Total no período ' || periodo
							   end                                                                                      info,
							   nfe_nfce                                                                                 nfe_nfce
						from(
						select extract(year from da_referencia)                                                 ano,
							   extract(year from da_referencia)||'/'||lpad(extract(month from da_referencia),2,'0')     periodo,
							   sum(prod_vprod+prod_vfrete+prod_vseg+prod_voutro-prod_vdesc)             nfe_nfce
						from BI.fato_nfe_nfce_sumarizada
						where co_emitente = :CO_CNPJ_CPF
						  and co_tp_nf = 1
						group by grouping sets 
								( ( ),
									(extract(year from da_referencia)), 
										(extract(year from da_referencia), extract(year from da_referencia)||'/'||lpad(extract(month from da_referencia),2,'0'))
								)
							 )
						order by ano desc, periodo desc
						)
						select nvl(cartao.info,saidas.info)                                                                             info,
							   cartao.operacoes                                                                                         operacoes_cartao,
							   lpad(trim(to_char(cartao.cartao, '999G999G999G990D00')), length(max(cartao.cartao) over()) + 7)          valor_cartao,
							   lpad(trim(to_char(saidas.nfe_nfce , '999G999G999G990D00')), length(max(saidas.nfe_nfce) over()) + 7)     valor_nfe_nfce,
							   case when substr(nvl(cartao.info,saidas.info),1,6) = '<html>' 
									 then lpad(trim(to_char('-')),
											   length(max(cartao.cartao) over()) + 7)
									when nvl(cartao.cartao,0) - nvl(saidas.nfe_nfce,0) > 0 
									 then lpad(trim(to_char(nvl(cartao.cartao,0)-nvl(saidas.nfe_nfce,0),'999G999G999G990D00')),
											   length(max(nvl(cartao.cartao,0)) over()) + 7)
									else lpad(to_char('-'),
											  length(max(cartao.cartao) over()) + 7)
									end                                                                                                 excesso_valor 
						from cartao
						left join saidas
							   on cartao.info = saidas.info
