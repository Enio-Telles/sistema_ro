with
                socios as (
                    select  /*+driving_site(s) parallel(5)*/
                        substr(s.gr_identificacao,2,14) cnpj_cpf,
                        null as co_cad_icms,
                        'Sócio' vinculo,
                        psocio.no_razao_social,
                        null as in_situacao
                    from
                        bi.dm_pessoa              p
                        left join sitafe.sitafe_historico_socio   s
                            on p.co_cad_icms = s.it_nu_inscricao_estadual
                        left join bi.dm_pessoa psocio
                            on psocio.co_cnpj_cpf = substr(s.gr_identificacao,2,14)
                    where
                        s.it_in_ultima_fac = 9
                        and trim(it_da_fim_part_societaria) is null
                        and p.co_cnpj_cpf = :v_co_emitente
      and it_co_cargo_socio in ('10','17','18','19','20', '24','47')
                )
                ,filiais as (
                    select distinct
                        p.co_cnpj_cpf cnpj_cpf
                        ,p.co_cad_icms
                        ,case when p.co_cnpj_cpf <> :v_co_emitente then 'Filial' else null end vinculo,
                        p.no_razao_social,
                        p.in_situacao
                    from
                        bi.dm_pessoa p
                    where
                        length(trim(p.co_cnpj_cpf)) = 14
                        and p.co_cnpj_raiz = substr(:v_co_emitente,1,8)
                        and p.co_cnpj_cpf <> :v_co_emitente
                        and p.in_situacao = '001'
                )
                ,vinculos as (
                    /*Filiais*/
                    select
                        *
                    from
                        filiais
                    union

                    /*Sócios*/
                    select
                        *
                    from
                        socios
                    union
                    /*Empresas ligadas aos sócios*/
                    select /*+driving_site(s) parallel(5)*/ distinct
                        p.co_cnpj_cpf       cnpj_cpf
                        ,p.co_cad_icms
                        ,case p.co_regime_pagto when '011' then 'Produtor Rural' else 'Empresa ligada ao sócio' end vinculo,
                        psocio.no_Razao_social,
                        psocio.in_situacao
                    from
                        sitafe.sitafe_historico_socio@sitafe_producao   s
                        left join bi.dm_contribuinte             p
                            on p.co_cad_icms = s.it_nu_inscricao_estadual
                        inner join socios                          ss
                            on substr(s.gr_identificacao,2,14)= ss.cnpj_cpf
                        left join bi.dm_pessoa psocio
                            on p.co_cnpj_cpf = psocio.co_cnpj_cpf
                    where
                        s.it_in_ultima_fac = 9
                        and trim(s.it_da_fim_part_societaria) is null
                        and p.co_cnpj_cpf <> :v_co_emitente
                        and not exists(select * from filiais f where f.cnpj_cpf=p.co_cnpj_cpf)
                        and p.co_regime_pagto <> '011'
                        and psocio.in_situacao = '001'
                )
                select
                    v.cnpj_cpf
                    ,v.co_cad_icms
                    ,v.no_razao_social
                    ,v.vinculo
                    ,v.in_situacao
                    ,s.no_situacao
                    --,p.co_regime_pagto
                from
                    vinculos v
                    --left join bi.dm_pessoa p
                    --    on v.co_cad_icms = p.co_cad_icms
                    left join bi.vw_situacao_contribuinte s
                        on v.in_situacao = s.in_situacao
                --where p.in_situacao = '001'
                order by
                    4, 1

                    ;
