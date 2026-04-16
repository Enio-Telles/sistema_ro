/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > IP(s) das NFs > Contribuintes
ESTILO: Table
HABILITADA: true
BINDS:
 - IP | prompt=IP | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT ip.ip_transmissor,
                                           substr(ip.chave_acesso, 7,14)            cnpj,
                                           pemit.no_razao_social    razao,
                                           locemit.no_municipio mun,
                                           count(DISTINCT ip.CHAVE_ACESSO) quant_nfs,
                                           case 
                                                     when pcont.CO_CNPJ_CPF is not null 
                                                         then pcont.CO_CNPJ_CPF
                                                     else hc.cnpj_cont end as cnpj_cont,
                                                 case 
                                             when pcont.NO_RAZAO_SOCIAL is not null 
                                               then pcont.NO_RAZAO_SOCIAL
                                             else hc.razao_cont end as razao_cont
                                           
                                      FROM bi.dm_ip_transmissor    ip
                                      LEFT JOIN bi.dm_pessoa            pemit ON pemit.co_cnpj_cpf = substr(ip.chave_acesso, 7,14)
                                      LEFT JOIN bi.dm_localidade        locemit ON pemit.co_municipio = locemit.co_municipio
                                      LEFT JOIN bi.dm_pessoa            pcont ON pcont.co_cnpj_cpf = pemit.co_cnpj_cpf_contador
                                      left join (select hc.IT_NU_INSCRICAO_ESTADUAL,
                                                      pcont.CO_CNPJ_CPF  cnpj_cont,
                                                      pcont.NO_RAZAO_SOCIAL razao_cont,
                                                      ROW_NUMber() over (partition by hc.IT_NU_INSCRICAO_ESTADUAL order by hc.IT_DA_TRANSACAO||hc.IT_HO_TRANSACAO desc) as linha
                                                from sitafe.SITAFE_HISTORICO_CONTRIBUINTE hc
                                              left join bi.DM_PESSOA pcont
                                                     on pcont.CO_CNPJ_CPF = substr(hc.GR_IDENT_CONTADOR,2)
                                                where hc.GR_IDENT_CONTADOR > ' ' ) hc
                                           on hc.IT_NU_INSCRICAO_ESTADUAL = pemit.CO_CAD_ICMS
                                          and hc.linha = 1
                                     WHERE ip.ip_transmissor = :IP
                                       AND ip.tipo_reg = '55'
                                     GROUP BY ip.ip_transmissor,
                                              substr(ip.chave_acesso, 7,14),
                                                        pemit.no_razao_social,
                                               case 
                                             when pcont.CO_CNPJ_CPF is not null 
                                               then pcont.CO_CNPJ_CPF
                                             else hc.cnpj_cont end,
                                           case 
                                             when pcont.NO_RAZAO_SOCIAL is not null 
                                               then pcont.NO_RAZAO_SOCIAL
                                             else hc.razao_cont end,
                                            locemit.no_municipio
                                    order by 5 DESC
