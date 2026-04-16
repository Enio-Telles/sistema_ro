/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Histórico Regime de Pagamento
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CNPJ_CPF | prompt=CO_CNPJ_CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
select
								co_regime_pagto,
								desc_reg_pagto,
								min(da_referencia)  inicio,
								case when max(da_referencia) = trunc(sysdate,'mm') then 'Atual' else to_char(max(da_referencia)) end fim
							from BI.dm_regime_pagto_contribuinte
							where co_cnpj_cpf  = :CO_CNPJ_CPF
							group by co_cnpj_cpf,
								co_regime_pagto,
								desc_reg_pagto
							order by 3 desc
