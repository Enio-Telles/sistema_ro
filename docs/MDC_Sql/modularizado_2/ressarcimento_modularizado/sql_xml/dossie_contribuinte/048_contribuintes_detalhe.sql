/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > IP(s) das NFs > Contribuintes Detalhe
ESTILO: Table
HABILITADA: true
BINDS:
 - CNPJ | prompt=CNPJ | default=NULL_VALUE
 - IP | prompt=IP | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT ip.ip_transmissor,
                                               CASE
                                                   WHEN pemit.co_cnpj_cpf = :CNPJ THEN
                                                       'ALVO'
                                                   ELSE
                                                       'OUTROS'
                                               END                      AS alvo,
                                               d.co_emitente            cnpj_emit,
                                               pemit.no_razao_social    razao_emit,
                                               pcont.co_cnpj_cpf        emit_cont_cnpj,
                                               pcont.no_razao_social    emit_cont_razao,
                                               locemit.no_municipio mun_emit,
                                               d.co_destinatario        cnpj_dest,
                                               pdest.no_razao_social    razao_dest,
                                               locdest.no_municipio mun_dest,
                                               SUM(d.prod_vprod)        vprod,
                                               SUM(d.icms_vicms)        vicms
                                          FROM bi.dm_ip_transmissor    ip
                                          LEFT JOIN bi.fato_nfe_detalhe     d ON d.chave_acesso = ip.chave_acesso
                                           AND d.infprot_cstat IN ( '100', '150' )
                                          LEFT JOIN bi.dm_pessoa            pemit ON pemit.co_cnpj_cpf = d.co_emitente
                                          LEFT JOIN bi.dm_localidade        locemit ON pemit.co_municipio = locemit.co_municipio
                                          LEFT JOIN bi.dm_pessoa            pcont ON pcont.co_cnpj_cpf = pemit.co_cnpj_cpf_contador
                                          LEFT JOIN bi.dm_pessoa            pdest ON pdest.co_cnpj_cpf = d.co_destinatario
                                          LEFT JOIN bi.dm_localidade        locdest ON pdest.co_municipio = locdest.co_municipio
                                         WHERE ip.ip_transmissor = :IP
                                           AND ip.tipo_reg = '55'
                                           AND d.co_emitente IS NOT NULL
                                         GROUP BY
                                            CASE
                                                WHEN pemit.co_cnpj_cpf = :CNPJ THEN
                                                    'ALVO'
                                                ELSE
                                                    'OUTROS'
                                            END,
                                            ip.ip_transmissor,
                                            d.co_emitente,
                                            pemit.no_razao_social,
                                            pcont.co_cnpj_cpf,
                                            pcont.no_razao_social,
                                            locemit.no_municipio,
                                            d.co_destinatario,
                                            locdest.no_municipio,
                                            pdest.no_razao_social
                                         ORDER BY SUM(d.prod_vprod) DESC
