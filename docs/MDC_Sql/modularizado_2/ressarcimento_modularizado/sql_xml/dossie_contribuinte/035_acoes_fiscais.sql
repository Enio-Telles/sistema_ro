/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Ações Fiscais
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CNPJ_CPF | prompt=CO_CNPJ_CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
select 
								t.in_modelo_acao_fiscal   tipo,
								t.no_situacao_acao        situacao,
								t.nu_acao_fiscal          acao_fiscal,
								t.nu_dfe                  nu_dfe_dsf,
								t.da_periodo_inicio_fisc  p_ini,
								t.da_periodo_fim_fisc     p_fin,
								t.nu_prazo_acao           prazo,
								t.nu_prazo_prorrog        prorr,
								t.da_distri_acao_fiscal   da_distr,
								t.da_abertu_acao_fiscal   da_aber,
								t.da_conclu_acao_fiscal   da_concl,
								o.tx_origem_acao,
								t.tx_documento,
								t.tx_observacao

						from bi.dm_acao_fiscal t
						left join bi.dm_acao_fiscal_origem_acao o 
							   on t.nu_acao_fiscal = o.nu_acao_fiscal
						where co_cnpj_cpf = :CO_CNPJ_CPF

						union

						select 
            'DSF' as                                                                tipo,
            case when df.it_co_situacao_diligencia = 01 then '01 - DOC. REGISTRADO'
                 when df.it_co_situacao_diligencia = 02 then '02 - DIL. GERADA'
                 when df.it_co_situacao_diligencia = 03 then '03 - DIL. ENTREGUE'
                 when df.it_co_situacao_diligencia = 04 then '04 - DIL. CONCLUÍDA'
                 when df.it_co_situacao_diligencia = 05 then '05 - DIL. EXCLUÍDA'
            end                                                                     situacao,
            to_char(df.it_nu_diligencia)                                            acao_fiscal,
            dft.it_nu_diligencia                                                    dsf, 
            null                                                                    p_ini,
            null                                                                    p_fin,
            df.it_prazo_max                                                         prazo,
            null                                                                    prorr,
            null                                                                    da_distr,
            to_date(df.it_da_lancamento default null on conversion error,'yyyymmdd')da_aber,
            to_date(df.it_da_retorno default null on conversion error,'yyyymmdd')   da_concl,
            dta.tx_origem_acao                                                      tx_origem_acao,
            dft.it_nu_documento_origem                                              tx_documento,
            null                                                                    tx_observacao
    from sitafe.sitafe_diligencia_fiscal_taref dft
    left join sitafe.sitafe_diligencia_fiscal df
           on df.it_nu_diligencia = substr(dft.it_nu_diligencia,1,5)||'7'||substr(dft.it_nu_diligencia,7)
    left join sitafe.sitafe_dilig_it_nu_afte afte
           on afte.tuk = df.tuk
          and afte.m_occurs = 1
    left join sitafe.sitafe_usuario su
           on to_number(su.it_co_matricula_usuario) = to_number(afte.it_nu_afte)
    left join (select da.it_nu_acao_fiscal,
                      listagg(da.it_nu_ai,' * ' on overflow truncate) within group (order by da.it_nu_acao_fiscal) autos
                 from sitafe.sitafe_diligencia_autos da
             group by da.it_nu_acao_fiscal) da
               on da.it_nu_acao_fiscal = df.it_nu_diligencia
    left join (select dta.tuk,
                       listagg(dta.it_tx_atividade) within group (order by dta.m_occurs) tx_origem_acao
                from sitafe.sitafe_diligencia_tx_atividade dta
                group by dta.tuk) dta
                on dta.tuk = dft.tuk
    where dft.it_nu_identificacao = :CO_CNPJ_CPF
union
select 
            'DSF' as                                                                tipo,
            case when df.it_co_situacao_diligencia = 01 then '01 - DOC. REGISTRADO'
                 when df.it_co_situacao_diligencia = 02 then '02 - DIL. GERADA'
                 when df.it_co_situacao_diligencia = 03 then '03 - DIL. ENTREGUE'
                 when df.it_co_situacao_diligencia = 04 then '04 - DIL. CONCLUÍDA'
                 when df.it_co_situacao_diligencia = 05 then '05 - DIL. EXCLUÍDA'
            end                                                                     situacao,
            to_char(df.it_nu_diligencia)                                            acao_fiscal,
            dft.it_nu_diligencia                                                    dsf, 
            null                                                                    p_ini,
            null                                                                    p_fin,
            df.it_prazo_max                                                         prazo,
            null                                                                    prorr,
            null                                                                    da_distr,
            to_date(df.it_da_lancamento default null on conversion error,'yyyymmdd')da_aber,
            to_date(df.it_da_retorno default null on conversion error,'yyyymmdd')   da_concl,
            dta.tx_origem_acao                                                      tx_origem_acao,
            dft.it_nu_documento_origem                                              tx_documento,
            null                                                                    tx_observacao
    from sitafe.sitafe_diligencia_fiscal_taref dft
    left join sitafe.sitafe_diligencia_fiscal df
           on df.it_nu_diligencia = substr(dft.it_nu_diligencia,1,5)||'7'||substr(dft.it_nu_diligencia,7)
    left join sitafe.sitafe_dilig_it_nu_afte afte
           on afte.tuk = df.tuk
          and afte.m_occurs = 1
    left join sitafe.sitafe_usuario su
           on to_number(su.it_co_matricula_usuario) = to_number(afte.it_nu_afte)
    left join (select da.it_nu_acao_fiscal,
                      listagg(da.it_nu_ai,' * ' on overflow truncate) within group (order by da.it_nu_acao_fiscal) autos
                 from sitafe.sitafe_diligencia_autos da
             group by da.it_nu_acao_fiscal) da
               on da.it_nu_acao_fiscal = df.it_nu_diligencia
    left join (select dta.tuk,
                       listagg(dta.it_tx_atividade) within group (order by dta.m_occurs) tx_origem_acao
                from sitafe.sitafe_diligencia_tx_atividade dta
                group by dta.tuk) dta
                on dta.tuk = dft.tuk
    where substr(dft.it_nu_DILIGENCIA,1,5)||substr(dft.it_nu_DILIGENCIA,7,8) IN (SELECT DISTINCT substr(AINF.NU_ACAO_FISCAL,1,5)||substr(AINF.NU_ACAO_FISCAL,7,8) FROM BI.ARR_F_LANCAMENTO_DETALHE L INNER JOIN BI.FATO_ACAO_FISCAL_AINF AINF ON AINF.NU_GUIA_LANC_MULTA = L.NUMERO_GUIA WHERE L.CNPJ_CPF = :CO_CNPJ_CPF)
						order by 3 desc
