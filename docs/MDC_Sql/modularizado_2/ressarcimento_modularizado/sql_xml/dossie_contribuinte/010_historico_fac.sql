/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Histórico FAC
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CAD_ICMS | prompt=CO_CAD_ICMS | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
                                    t.it_da_transacao da_trans,
                                    t.it_da_referencia da_ref,
                                    t.it_nu_fac nu_fac,
                                    t.it_nu_inscricao_estadual IE,
                                    sit_pessoa.it_no_pessoa Nome,
                                    sit_pessoa.it_no_fantasia No_fantasia,
                                    t.it_co_regime_pagamento rp,
                                    t.it_va_capital_social c_soc,
                                    t.it_co_atividade_economica atv_pr,
                                    tg.it_co_tipo_logradouro tl,
                                    tg.it_no_logradouro logradouro,
                                    sit_pessoa.it_ed_numero num,
                                    localid.no_municipio municipio,
                                    sit_pessoa.it_sg_uf uf,
                                    sit_pessoa.it_co_correio_eletronico email,
                                    sit_pessoa.it_co_correio_eletro_corresp email_corr,
                                    substr(t.gr_ident_contador, 2, 14)           cpf_contador,
                                    pessoa.no_razao_social                     no_contador,
                                    t.it_in_ultima_fac ult_fac
                                FROM
                                    sitafe.sitafe_historico_contribuinte    t
                                    LEFT JOIN sitafe.sitafe_pessoa                    sit_pessoa ON t.it_nu_fac = sit_pessoa.it_nu_fac
                                    LEFT JOIN sitafe.sitafe_tabelas_cadastro          tg ON sit_pessoa.it_co_logradouro = tg.it_co_logradouro
                                    LEFT JOIN bi.dm_localidade                        localid ON sit_pessoa.it_co_municipio = localid.co_municipio
                                    LEFT JOIN bi.dm_pessoa                            pessoa ON substr(t.gr_ident_contador, 2, 14) = pessoa.co_cnpj_cpf
                                WHERE
                                    t.it_nu_inscricao_estadual = :CO_CAD_ICMS
                                ORDER BY
                                    t.it_da_transacao DESC
