/*
    Analise da Consulta: CPF_empresa_enderecos.sql
    Objetivo: Consolidar enderecos de uma empresa de multiplas fontes (cadastro e notas fiscais).
    
    Tabelas Utilizadas:
    - bi.dm_pessoa (t): Cadastro oficial do contribuinte.
      Colunas: desc_endereco, bairro, nu_cep, co_municipio.
    - bi.dm_localidade (localid): Tabela de municipios.
    - bi.fato_nfe_detalhe (t): Notas fiscais recebidas (endereco de entrega).
      Colunas: xlgr_dest, nro_dest, xbairro_dest, xmun_dest, cep_dest, co_uf_dest.

    Logica Principal:
    1. Primeiro bloco: Endereco cadastral atual (DM_PESSOA/SITAFE).
    2. Segundo bloco: Enderecos extraidos de NF-e (como destinatario).
    3. UNION ALL: Combina as duas fontes.
    4. Agrupa por periodo (ano/mes) para mostrar historico de enderecos.
*/

select 'DM_PESSOA/SITAFE' origem,
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
                                    
                                    -- Enderecos de Notas Fiscais (historico)
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