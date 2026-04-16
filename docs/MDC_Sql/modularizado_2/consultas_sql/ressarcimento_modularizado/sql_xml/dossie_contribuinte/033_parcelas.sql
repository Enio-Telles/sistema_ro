/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Parcelamentos > Parcelas
ESTILO: Table
HABILITADA: true
BINDS:
 - IT_NU_GUIA_PARCELAMENTO | prompt=IT_NU_GUIA_PARCELAMENTO | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
						t.da_vencimento,
						t.da_pagamento,
						t.da_referencia,
						t.id_receita,
						rec.it_no_receita,
						t.id_situacao,
						lanc.it_no_situacao,
						t.nu_guia_parcela,
						t.va_principal,
						t.va_multa,
						t.va_juros,
						t.va_acrescimo,
						t.va_pago
						
					FROM
						bi.fato_lanc_arrec           t
						LEFT JOIN bi.dm_situacao_lancamento    lanc ON t.id_situacao = lanc.it_co_situacao
						LEFT JOIN bi.dm_receita                rec ON t.id_receita = rec.it_co_receita
					WHERE
						t.nu_guia = :IT_NU_GUIA_PARCELAMENTO
					order by t.da_vencimento
