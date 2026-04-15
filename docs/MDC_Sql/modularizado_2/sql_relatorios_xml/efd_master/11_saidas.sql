-- Origem: EFD_master.xml
-- Título no relatório: Saídas
-- Caminho no XML: EFD Master 2.0 > Saídas
-- Utilidade fiscal: Alta
-- Foco: Visão agregada das saídas por destinatário e UF, com base e ICMS/ST.
-- Uso sugerido: Ajuda a explicar geração de débitos, concentração de clientes, peso interestadual e exposição ST.
-- Riscos/Limites: Não revela por si só a natureza fiscal item a item nem substitui análise de CFOP/CST/documento.
-- Tabelas/fontes identificadas: bi.dm_efd_arquivo_valido, sped.reg_c100, sped.reg_0150, bi.dm_localidade
-- Binds declarados: nenhum

SELECT
    :CNPJ_CPF cnpj_cpf,
    :DATA_INICIAL DATA_INICIAL,
    :DATA_FINAL DATA_FINAL,
    cnpj_cpf CNPJ_CPF_DEST,
    
        CASE
        WHEN cod_mod IS NULL AND cnpj_cpf IS NULL and nome is null and co_uf is null THEN
            '<html><font size=4><b>---Σ Total geral'
        WHEN cod_mod IS NULL AND cnpj_cpf IS NULL and nome is null and co_uf is not null THEN
            '<html>--------Σ Total de operações de saída,  por Estado'
        ELSE
            nome
    END                                   nome,
    co_uf,
    lpad(TRIM(to_char(round(RATIO_TO_REPORT(SUM(vl_doc))
                            OVER(PARTITION BY
        CASE
            WHEN cnpj_cpf IS NULL
                 AND co_uf IS NULL
                 AND cod_mod IS NULL THEN
                0
            WHEN cnpj_cpf IS NULL
                 AND cod_mod IS NULL
                 AND co_uf IS NOT NULL THEN
                1
            ELSE
                2
        END
                            ),
                            4) * 100,
                      '990.00L',
                      'NLS_CURRENCY=%')),
         8)                               rr_geral,
    lpad(TRIM(to_char(SUM(vl_doc), '999G999G999G990D00')), length(MAX(SUM(vl_doc))
                                                                  OVER()) + 6)                          vl_doc,
    lpad(TRIM(to_char(SUM(vl_bc_icms), '999G999G999G990D00')), length(MAX(SUM(vl_bc_icms))
                                                                      OVER()) + 6)                          vl_bc_icms,
    lpad(TRIM(to_char(SUM(vl_icms), '999G999G999G990D00')), length(MAX(SUM(vl_icms))
                                                                   OVER()) + 6)                          vl_icms,
    lpad(TRIM(to_char(SUM(vl_bc_icms_st), '999G999G999G990D00')), length(MAX(SUM(vl_bc_icms_st))
                                                                         OVER()) + 6)                          vl_bc_icms_st,
    lpad(TRIM(to_char(SUM(vl_icms_st), '999G999G999G990D00')), length(MAX(SUM(vl_icms_st))
                                                                      OVER()) + 6)                          vl_icms_st,
    '<html><i>'
    || nvl(round(nullif(SUM(vl_bc_icms), 0) / nullif(SUM(vl_doc), 0) * 100, 2), 0)
    || '%'                                ind_bcvt,
    '<html><i>'
    || nvl(round(nullif(SUM(vl_icms), 0) / nullif(SUM(vl_bc_icms), 0) * 100, 2), 0)
    || '%'                                ind_ibc
FROM
    (
        SELECT
            rc100.cod_mod,
            CASE
                WHEN r0150.cnpj IS NULL THEN
                    r0150.cpf
                ELSE
                    r0150.cnpj
            END  cnpj_cpf,
            CASE
                WHEN r0150.nome IS NULL THEN
                    'Venda a consumidor final'
                ELSE
                    r0150.nome
            END  nome,
            CASE
                WHEN l.co_uf IS NULL THEN
                    'RO'
                ELSE
                    l.co_uf
            END  co_uf,
            rc100.vl_doc,
            rc100.vl_bc_icms,
            rc100.vl_icms,
            rc100.vl_bc_icms_st,
            rc100.vl_icms_st
        FROM
            bi.dm_efd_arquivo_valido    t
            LEFT JOIN sped.reg_c100               rc100 ON t.reg_0000_id = rc100.reg_0000_id
            LEFT JOIN sped.reg_0150               r0150 ON t.reg_0000_id = r0150.reg_0000_id
                                             AND rc100.cod_part = r0150.cod_part
            LEFT JOIN bi.dm_localidade            l ON r0150.cod_mun = l.co_mun_ibge
        WHERE
                t.co_cnpj_cpf_declarante = :CNPJ_CPF 
            AND t.da_inicio_arquivo BETWEEN :DATA_INICIAL AND :DATA_FINAL
            AND rc100.cod_sit NOT IN ( '02', '04', '05' )
            AND rc100.ind_oper = '1'
    )
GROUP BY
    GROUPING SETS ( ( ),
    ( co_uf ), ( co_uf,
                 cnpj_cpf,
                 nome,
                 '<html><p style=color:blue>1 - Saída',
                 cod_mod ) )
                 
ORDER BY
        CASE
            WHEN CNPJ_CPF_DEST IS NULL
                 AND co_uf IS NULL
                 AND cod_mod IS NULL THEN
                0
            WHEN CNPJ_CPF_DEST IS NULL
                 AND cod_mod IS NULL
                 AND co_uf IS NOT NULL THEN
                1
            ELSE
                2
        END, vl_doc desc
