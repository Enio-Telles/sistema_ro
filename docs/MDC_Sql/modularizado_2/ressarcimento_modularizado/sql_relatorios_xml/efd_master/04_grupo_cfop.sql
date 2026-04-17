-- Origem: EFD_master.xml
-- Título no relatório: Grupo CFOP
-- Caminho no XML: EFD Master 2.0 > Grupo CFOP
-- Utilidade fiscal: Alta
-- Foco: Composição das operações por grupo de CFOP, separando entradas e saídas e somando base/ICMS/ST.
-- Uso sugerido: Explicar a formação dos valores de apuração e localizar grupos de operação que mais pressionam débito, crédito ou ST.
-- Riscos/Limites: É agregação por grupo; não substitui análise item a item nem resolve classificação incorreta de CFOP.
-- Tabelas/fontes identificadas: bi.fato_efd_sumarizada, bi.dm_cfop
-- Binds declarados: CNPJ_CPF, DATA_INICIAL, DATA_FINAL

select
                                    case when grupo is null then ' ' ELSE :CNPJ_CPF end CNPJ_CPF,
                                    case when grupo is null then null ELSE :DATA_INICIAL end DATA_INICIAL,
                                    case when grupo is null then null ELSE :DATA_FINAL end DATA_FINAL,
                                    case when grupo is null then null ELSE to_char(grupo) end grupo,
                                    case when descricao is null and operacao = 999 then '<html><b style="color:red">TOTAL DAS ENTRADAS ---------------------------------------------------'
                                    when descricao is null and operacao = 4999 then '<html><b style="color:blue">TOTAL DAS SAÍDAS ------------------------------------------------------' ELSE descricao end DESCRICAO,
                                    case when rr is null then ' ' else rr end Perc,

                                    lpad(TRIM(to_char(sum(vl_operacao), '999G999G999G990D00')), length(MAX(sum(vl_operacao))
                                                                                                                                             OVER()) + 6) VL_OPERACAO,
                                    lpad(TRIM(to_char(sum(vl_bc_icms), '999G999G999G990D00')), length(MAX(sum(vl_bc_icms))
                                                                                                                                             OVER()) + 6) vl_bc_icms,
                                    lpad(TRIM(to_char(sum(vl_icms), '999G999G999G990D00')), length(MAX(sum(vl_icms))
                                                                                                                                             OVER()) + 6) vl_icms,
                                    lpad(TRIM(to_char(sum(vl_bc_icms_st), '999G999G999G990D00')), length(MAX(sum(vl_bc_icms_st))
                                                                                                                                             OVER()) + 6) vl_bc_icms_st,
                                    lpad(TRIM(to_char(sum(vl_icms_st), '999G999G999G990D00')), length(MAX(sum(vl_icms_st))
                                                                                                                                             OVER()) + 6) vl_icms_st,
                                    lpad(TRIM(to_char(sum(vl_red_bc), '999G999G999G990D00')), length(MAX(sum(vl_red_bc))
                                                                                                                                             OVER()) + 6) vl_red_bc

                                    from
                                    (SELECT
                                        CASE
                                            WHEN c.co_grupo > 4000 THEN
                                                4999
                                            ELSE
                                                999
                                        END                        operacao,
                                        c.co_grupo                 grupo,
                                        c.descricao_grupo          descricao,
                                            lpad(TRIM(to_char(round(RATIO_TO_REPORT(SUM(t.vl_operacao))
                                                                OVER(PARTITION BY
                                            CASE
                                                WHEN c.co_grupo > 4000 THEN
                                                    4999
                                                ELSE
                                                    999
                                            END
                                                                ),
                                                                4) * 100,
                                                          '990.00L',
                                                          'NLS_CURRENCY=%')),
                                             8)                    rr,
                                        SUM(t.vl_operacao)         vl_operacao,
                                        SUM(t.vl_bc_icms)          vl_bc_icms,
                                        SUM(t.vl_icms)             vl_icms,
                                        SUM(t.vl_bc_icms_st)       vl_bc_icms_st,
                                        SUM(t.vl_icms_st)          vl_icms_st,
                                        SUM(t.vl_red_bc)           vl_red_bc
                                    FROM
                                        bi.fato_efd_sumarizada    t
                                        LEFT JOIN bi.dm_cfop                c ON t.co_cfop = c.co_cfop
                                    WHERE
                                            t.co_cfop != 0
                                        AND t.co_cnpj_cpf_declarante = :CNPJ_CPF
                                        AND t.da_referencia between :DATA_INICIAL and :DATA_FINAL
                                    GROUP BY
                                        c.co_grupo,
                                        c.descricao_grupo

                                    ORDER BY
                                       operacao asc,  c.co_grupo asc)
                                    group by grouping sets ((operacao),(
                                    operacao, grupo,
                                    descricao, rr))
                                    order by operacao asc
