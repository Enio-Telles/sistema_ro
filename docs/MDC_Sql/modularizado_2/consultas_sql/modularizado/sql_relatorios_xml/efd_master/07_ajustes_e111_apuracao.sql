-- Origem: EFD_master.xml
-- Título no relatório: Ajustes E111 (Apuração)
-- Caminho no XML: EFD Master 2.0 > Ajustes E111 (Apuração)
-- Utilidade fiscal: Altíssima
-- Foco: Classifica os ajustes do E111 por apuração (ICMS, ST, DIFAL, FCP) e por natureza do ajuste.
-- Uso sugerido: Crucial para identificar créditos, estornos, deduções e débitos especiais registrados na apuração.
-- Riscos/Limites: Depende da qualidade do cod_aj e do cadastro dm_efd_ajustes; sem isso, o sentido jurídico do ajuste pode ficar obscuro.
-- Tabelas/fontes identificadas: bi.fato_efd_sumarizada, bi.dm_efd_ajustes
-- Binds declarados: CNPJ_CPF, DATA_INICIAL, DATA_FINAL

SELECT
    apuracao,
    CASE
        WHEN tipo IS NULL THEN
            substr(cod_aj,4,1) || ' - ' ||no_cod_aj
        ELSE
            tipo
    END tipo,
    rr,
    valor,
    cod_aj
FROM
    (
        SELECT
            CASE
                WHEN substr(cod_aj, 3, 1) = '0'       THEN
                    'ICMS'
                WHEN substr(cod_aj, 3, 1) = '1'       THEN
                    'ICMS Substituição Tributária'
                WHEN substr(cod_aj, 3, 1) = '2'       THEN
                    'ICMS Difal'
                WHEN substr(cod_aj, 3, 1) = '3'       THEN
                    'ICMS FCP'
            END               apuracao,
            CASE
                WHEN substr(cod_aj, 4, 1) = '0'       THEN
                    '<html><b style="color:red">0 - Total em ajuste de Outros débitos'
                WHEN substr(cod_aj, 4, 1) = '1'       THEN
                    '<html><b style="color:red">1 - Total em ajuste de Estorno de créditos'
                WHEN substr(cod_aj, 4, 1) = '2'       THEN
                    '<html><b style="color:blue">2 - Total em ajuste de Outros créditos'
                WHEN substr(cod_aj, 4, 1) = '3'       THEN
                    '<html><b style="color:blue">3 - Total em ajuste de Estorno de débitos'
                WHEN substr(cod_aj, 4, 1) = '4'       THEN
                    '<html><b style="color:blue">4 - Total em ajuste de Deduções do imposto apurado'
                WHEN substr(cod_aj, 4, 1) = '5'       THEN
                    '<html><b style="color:blue">5 - Total em ajuste de Débito especial'
                WHEN substr(cod_aj, 4, 1) = '6'       THEN
                    '<html><b style="color:blue">6 - Total em ajuste de Controle do ICMS extra-apuração'
            END               tipo,
            lpad(TRIM(to_char(round(RATIO_TO_REPORT(SUM(t.vl_aj_apur))
                                    OVER(PARTITION BY
                CASE
                    WHEN cod_aj IS NULL THEN
                        '1'
                    ELSE
                        '2'||substr(cod_aj,4,1)
                END
                                    ),
                                    4) * 100,
                              '990.00L',
                              'NLS_CURRENCY=%')),
                 8)           rr,
            cod_aj,
            no_cod_aj,
            lpad(TRIM(to_char(SUM(t.vl_aj_apur), '999G999G999G990D00')), length(MAX(SUM(t.vl_aj_apur))
                                                                                OVER()) + 6)      valor
        FROM
            bi.fato_efd_sumarizada    t
            LEFT JOIN bi.dm_efd_ajustes         aj ON t.cod_aj = aj.co_cod_aj
        WHERE
                registro = 'E111'
            AND co_cnpj_cpf_declarante = :CNPJ_CPF
            AND da_referencia BETWEEN :DATA_INICIAL AND :DATA_FINAL
        GROUP BY
            GROUPING SETS ( (
                CASE
                    WHEN substr(cod_aj, 3, 1) = '0'       THEN
                        'ICMS'
                    WHEN substr(cod_aj, 3, 1) = '1'       THEN
                        'ICMS Substituição Tributária'
                    WHEN substr(cod_aj, 3, 1) = '2'       THEN
                        'ICMS Difal'
                    WHEN substr(cod_aj, 3, 1) = '3'       THEN
                        'ICMS FCP'
                END,
                CASE
                    WHEN substr(cod_aj, 4, 1) = '0'       THEN
                        '<html><b style="color:red">0 - Total em ajuste de Outros débitos'
                    WHEN substr(cod_aj, 4, 1) = '1'       THEN
                        '<html><b style="color:red">1 - Total em ajuste de Estorno de créditos'
                    WHEN substr(cod_aj, 4, 1) = '2'       THEN
                        '<html><b style="color:blue">2 - Total em ajuste de Outros créditos'
                    WHEN substr(cod_aj, 4, 1) = '3'       THEN
                        '<html><b style="color:blue">3 - Total em ajuste de Estorno de débitos'
                    WHEN substr(cod_aj, 4, 1) = '4'       THEN
                        '<html><b style="color:blue">4 - Total em ajuste de Deduções do imposto apurado'
                    WHEN substr(cod_aj, 4, 1) = '5'       THEN
                        '<html><b style="color:blue">5 - Total em ajuste de Débito especial'
                    WHEN substr(cod_aj, 4, 1) = '6'       THEN
                        '<html><b style="color:blue">6 - Total em ajuste de Controle do ICMS extra-apuração'
                END
            ), (
                CASE
                    WHEN substr(cod_aj, 3, 1) = '0'       THEN
                        'ICMS'
                    WHEN substr(cod_aj, 3, 1) = '1'       THEN
                        'ICMS Substituição Tributária'
                    WHEN substr(cod_aj, 3, 1) = '2'       THEN
                        'ICMS Difal'
                    WHEN substr(cod_aj, 3, 1) = '3'       THEN
                        'ICMS FCP'
                END,
                cod_aj,
                no_cod_aj ) )
    )
ORDER BY
    CASE
        WHEN cod_aj IS NULL THEN
            1
        ELSE
            2
    END,
    valor DESC
