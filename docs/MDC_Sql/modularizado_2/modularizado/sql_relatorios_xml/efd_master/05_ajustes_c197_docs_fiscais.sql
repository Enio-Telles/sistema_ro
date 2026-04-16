-- Origem: EFD_master.xml
-- Título no relatório: Ajustes C197 (Docs Fiscais)
-- Caminho no XML: EFD Master 2.0 > Ajustes C197 (Docs Fiscais)
-- Utilidade fiscal: Altíssima
-- Foco: Mapeia ajustes documentais do C197 por reflexo na apuração, código e nome do ajuste.
-- Uso sugerido: Essencial para entender quanto do resultado fiscal deriva de documentos com ajustes e quais naturezas estão empurrando crédito, débito, dedução ou informativo.
-- Riscos/Limites: Consulta de síntese; em casos críticos precisa descer ao documento fiscal e ao item.
-- Tabelas/fontes identificadas: bi.dm_efd_c197, bi.dm_efd_ajustes
-- Binds declarados: CNPJ_CPF, DATA_INICIAL, DATA_FINAL

select cnpj_cpf CNPJ_CPF,
data_inicial DATA_INICIAL,
data_final DATA_FINAL,
case when cod_aj is null  and substr(ref_apur,1,1) = 'C' then  '<html><b>Total - Reflexo na Apuração - <b style=color:blue>'||ref_apur 
when cod_aj is null  and substr(ref_apur,1,1) = 'D' then  '<html><b>Total - Reflexo na Apuração - <b style=color:red>'||ref_apur
when cod_aj is null  then '<html><b>Total - Reflexo na Apuração - '||ref_apur 
when substr(ref_apur,1,1) = 'C' then  '<html><p style=color:blue>' ||ref_apur
when substr(ref_apur,1,1) = 'D' then  '<html><p style=color:red>' ||ref_apur
else ref_apur
end Tipo,
rr RR,
vl_bc_icms VL_BC_ICMS,
vl_icms VL_ICMS,
vl_outros VL_OUTROS,
cod_aj COD_AJ,
no_cod_aj NO_COD_AJ from 


(SELECT
    :CNPJ_CPF         cnpj_cpf,
    :DATA_INICIAL     data_inicial,
    :DATA_FINAL       data_final,
    CASE
        WHEN substr(t.cod_aj, 3, 1) = '0'           THEN
            'C - Crédito por Entrada'
        WHEN substr(t.cod_aj, 3, 1) = '1'           THEN
            'C - Outros Créditos'
        WHEN substr(t.cod_aj, 3, 1) = '2'           THEN
            'C - Estorno de Débito '
        WHEN substr(t.cod_aj, 3, 1) = '3'           THEN
            'D - Débito por Saída '
        WHEN substr(t.cod_aj, 3, 1) = '4'           THEN
            'D - Outros Débitos '
        WHEN substr(t.cod_aj, 3, 1) = '5'           THEN
            'D - Estorno de Crédito'
        WHEN substr(t.cod_aj, 3, 1) = '6'           THEN
            'Dedução'
        WHEN substr(t.cod_aj, 3, 1) = '7'           THEN
            'Débitos especiais'
        WHEN substr(t.cod_aj, 3, 1) = '9'           THEN
            'Informativo'
    END               ref_apur,

    lpad(TRIM(to_char(round(RATIO_TO_REPORT(SUM(t.vl_bc_icms))
                            OVER(PARTITION BY
        CASE
            WHEN t.cod_aj IS NULL THEN
                '99'
            ELSE
                substr(t.cod_aj, 3, 1)
        END
                            ),
                            4) * 100,
                      '990.00L',
                      'NLS_CURRENCY=%')),
         8)           rr,
    lpad(TRIM(to_char(SUM(t.vl_bc_icms), '999G999G999G990D00')), length(MAX(SUM(t.vl_bc_icms))
                                                                        OVER()) + 6)      vl_bc_icms,
    lpad(TRIM(to_char(SUM(t.vl_icms), '999G999G999G990D00')), length(MAX(SUM(t.vl_icms))
                                                                     OVER()) + 6)      vl_icms,
    lpad(TRIM(to_char(SUM(t.vl_outros), '999G999G999G990D00')), length(MAX(SUM(t.vl_outros))
                                                                       OVER()) + 6)      vl_outros,
        t.cod_aj,
    aj.no_cod_aj
FROM
    bi.dm_efd_c197       t
    LEFT JOIN bi.dm_efd_ajustes    aj ON t.cod_aj = co_cod_aj
WHERE
        t.co_declarante = :CNPJ_CPF
    AND t.da_referencia BETWEEN :DATA_INICIAL AND :DATA_FINAL
GROUP BY
    GROUPING SETS ( (
        CASE
            WHEN substr(t.cod_aj, 3, 1) = '0'           THEN
                'C - Crédito por Entrada'
            WHEN substr(t.cod_aj, 3, 1) = '1'           THEN
                'C - Outros Créditos'
            WHEN substr(t.cod_aj, 3, 1) = '2'           THEN
                'C - Estorno de Débito '
            WHEN substr(t.cod_aj, 3, 1) = '3'           THEN
                'D - Débito por Saída '
            WHEN substr(t.cod_aj, 3, 1) = '4'           THEN
                'D - Outros Débitos '
            WHEN substr(t.cod_aj, 3, 1) = '5'           THEN
                'D - Estorno de Crédito'
            WHEN substr(t.cod_aj, 3, 1) = '6'           THEN
                'Dedução'
            WHEN substr(t.cod_aj, 3, 1) = '7'           THEN
                'Débitos especiais'
            WHEN substr(t.cod_aj, 3, 1) = '9'           THEN
                'Informativo'
        END
    ), (
        CASE
            WHEN substr(t.cod_aj, 3, 1) = '0'           THEN
                'C - Crédito por Entrada'
            WHEN substr(t.cod_aj, 3, 1) = '1'           THEN
                'C - Outros Créditos'
            WHEN substr(t.cod_aj, 3, 1) = '2'           THEN
                'C - Estorno de Débito '
            WHEN substr(t.cod_aj, 3, 1) = '3'           THEN
                'D - Débito por Saída '
            WHEN substr(t.cod_aj, 3, 1) = '4'           THEN
                'D - Outros Débitos '
            WHEN substr(t.cod_aj, 3, 1) = '5'           THEN
                'D - Estorno de Crédito'
            WHEN substr(t.cod_aj, 3, 1) = '6'           THEN
                'Dedução'
            WHEN substr(t.cod_aj, 3, 1) = '7'           THEN
                'Débitos especiais'
            WHEN substr(t.cod_aj, 3, 1) = '9'           THEN
                'Informativo'
        END,
        t.cod_aj,
        aj.no_cod_aj ) )
ORDER BY
    CASE
        WHEN t.cod_aj IS NULL THEN
            '-'
        ELSE
            substr(t.cod_aj, 3, 1)
    END ,
    sum(t.vl_bc_icms) DESC)
