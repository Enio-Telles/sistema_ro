/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Endereços
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CNPJ_CPF | prompt=CO_CNPJ_CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
select '<html><b>DM_PESSOA/SITAFE' origem,
                                            'ATUAL' ano_mes,
                                            t.desc_endereco logradouro,
                                            null numero,
                                            null complemento,
                                            t.bairro bairro,
                                            null fone,
                                            t.nu_cep cep,
                                            localid.no_municipio municipio,
                                            localid.co_uf uf
                                    from bi.dm_pessoa t
                                    LEFT JOIN bi.dm_localidade    localid ON t.co_municipio = localid.co_municipio
                                    where co_cnpj_cpf = :CO_CNPJ_CPF

                                    union all

                                    select * from (
                                    SELECT
                                        'NFE' origem,
                                        extract(year from dhemi)||'/'||extract(month from dhemi) ano_mes,
                                        upper(xlgr_dest) logradouro,
                                        upper(nro_dest) numero,
                                        upper(xcpl_dest) complemento,
                                        upper(xbairro_dest) bairro,
                                        upper(fone_dest) fone,
                                        upper(cep_dest) cep,
                                        upper(xmun_dest) muncipio,
                                        upper(co_uf_dest) uf
                                    FROM
                                        bi.fato_nfe_detalhe t
                                    where t.co_destinatario = :CO_CNPJ_CPF
                                    group by    upper(xlgr_dest),
                                        upper(nro_dest),
                                        upper(xcpl_dest),
                                        upper(xbairro_dest),
                                        upper(fone_dest),
                                        upper(xmun_dest),
                                        upper(cep_dest),
                                        upper(co_uf_dest),
                                        extract(year from dhemi)||'/'||extract(month from dhemi)

                                    order by extract(year from dhemi)||'/'||extract(month from dhemi) desc)
