/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Parcelamentos > Origem
ESTILO: Table
HABILITADA: true
BINDS:
 - IT_NU_GUIA_PARCELAMENTO | prompt=IT_NU_GUIA_PARCELAMENTO | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
								lanc.nu_guia,
								substr(lanc.nu_guia_parcela,15,2) p,
								lanc.nu_complemento,
								lanc.da_referencia,
								lanc.da_vencimento,
								lanc.da_pagamento,
								lanc.id_receita,
								rec.it_no_receita,
								lanc.id_situacao,
								sit.it_no_situacao,
								lanc.va_principal,
								lanc.va_multa,
								lanc.va_juros,
								lanc.va_acrescimo,
								lanc.va_pago
							FROM
								bi.dm_hist_redir_lanc        t
								LEFT JOIN bi.fato_lanc_arrec           lanc ON t.nu_guia_parcela_origem = lanc.nu_guia_parcela
								LEFT JOIN bi.dm_receita                rec ON lanc.id_receita = rec.it_co_receita
								LEFT JOIN bi.dm_situacao_lancamento    sit ON lanc.id_situacao = sit.it_co_situacao
							WHERE
								t.nu_guia_redir = :IT_NU_GUIA_PARCELAMENTO
