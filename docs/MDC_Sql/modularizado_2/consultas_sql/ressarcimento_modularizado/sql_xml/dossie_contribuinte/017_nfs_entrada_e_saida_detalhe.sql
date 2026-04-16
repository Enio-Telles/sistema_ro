/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > NFs - Entr X Saida (VAF) > NFs - Entrada e Saída Detalhe
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CNPJ_CPF | prompt=CO_CNPJ_CPF | default=NULL_VALUE
 - ANO | prompt=ANO | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
    CASE
        WHEN co_grupo IS NULL
             AND tipo = 'ENTRADAS' THEN
            '<html><strong><font color="red">'
            || tipo
            || ' TOTAL'
        WHEN co_grupo IS NULL
             AND tipo = 'SAÍDAS' THEN
            '<html><strong><font color="blue">'
            || tipo
            || ' TOTAL'
        WHEN co_grupo IS NOT NULL
             AND co_subgrupo IS NULL THEN
            '<HTML><b> -> '
            || to_char(co_grupo)
            || ' '
            || descricao_grupo
        WHEN co_grupo IS NOT NULL
             AND co_subgrupo IS NOT NULL THEN
            '<HTML><i> ----> '
            || to_char(co_subgrupo)
            || ' '
            || lower(descricao_subgrupo)
    END                                                                                          descricao,
    concat(to_char((RATIO_TO_REPORT(particao)
                    OVER(PARTITION BY
        CASE
            WHEN co_grupo IS NULL THEN
                tipo || '1'
            WHEN co_grupo IS NOT NULL
                 AND co_subgrupo IS NULL THEN
                tipo || '2'
            WHEN co_grupo IS NOT NULL
                 AND co_subgrupo IS NOT NULL THEN
                tipo
                || co_grupo
                || '3'
        END
                    ) * 100), '990D00'), '%')                                                                    rr,
    total,
    vbc,
    concat(to_char(((nullif(particao_vbc, 0) / nullif(particao, 0)) * 100), '990D00'), '%')      "TOTAL / VBC",
    icms,
    concat(to_char((nullif(particao_vicms, 0) /(nullif(particao_vbc, 0)) * 100), '990D00'), '%') "VBC / ICMS"
FROM
    (
        SELECT
            CASE
                WHEN t.co_emitente = :CO_CNPJ_CPF
                     AND t.co_tp_nf = '1' THEN
                    'SAÍDAS'
                ELSE
                    'ENTRADAS'
            END                                                                    tipo,
            d.co_grupo,
            d.descricao_grupo,
            d.co_subgrupo,
            d.descricao_subgrupo,
            SUM(t.prod_vprod + prod_vfrete + prod_vseg + prod_voutro - prod_vdesc) particao,
            SUM(icms_vbc)                                                          particao_vbc,
            SUM(icms_vicms)                                                        particao_vicms,
            lpad(TRIM(to_char(SUM(t.prod_vprod + prod_vfrete + prod_vseg + prod_voutro - prod_vdesc), '999G999G999G990D00')), length(
            MAX(SUM(t.prod_vprod + prod_vfrete + prod_vseg + prod_voutro - prod_vdesc))
                                                                                                                                    OVER()) +
                                                                                                                                    6)                                                           total,
            lpad(TRIM(to_char(SUM(icms_vbc), '999G999G999G990D00')), length(MAX(SUM(icms_vbc))
                                                                            OVER()) + 6)                                                           vbc,
            lpad(TRIM(to_char(SUM(icms_vicms), '999G999G999G990D00')), length(MAX(SUM(icms_vicms))
                                                                              OVER()) + 6)                                                           icms
        FROM
                 bi.fato_nfe_nfce_sumarizada t
            INNER JOIN bi.dm_calendario c ON t.da_referencia = c.data
            INNER JOIN bi.dm_cfop       d ON t.co_cfop = d.co_cfop
        WHERE
            ( t.co_emitente = :CO_CNPJ_CPF
              OR t.co_destinatario = :CO_CNPJ_CPF )
            AND c.ano = :ANO
            AND d.in_vaf = 'X'
        GROUP BY
            GROUPING SETS ( (
                CASE
                    WHEN t.co_emitente = :CO_CNPJ_CPF
                         AND t.co_tp_nf = '1' THEN
                        'SAÍDAS'
                    ELSE
                        'ENTRADAS'
                END
            ), (
                CASE
                    WHEN t.co_emitente = :CO_CNPJ_CPF
                         AND t.co_tp_nf = '1' THEN
                        'SAÍDAS'
                    ELSE
                        'ENTRADAS'
                END,
                d.co_grupo,
                d.descricao_grupo ), (
                CASE
                    WHEN t.co_emitente = :CO_CNPJ_CPF
                         AND t.co_tp_nf = '1' THEN
                        'SAÍDAS'
                    ELSE
                        'ENTRADAS'
                END,
                d.co_grupo,
                d.descricao_grupo,
                d.co_subgrupo,
                d.descricao_subgrupo ) )
    )
ORDER BY
    CASE
        WHEN tipo = 'ENTRADAS'
             AND co_grupo IS NULL THEN
            1
        WHEN tipo = 'ENTRADAS'
             AND co_grupo IS NOT NULL THEN
            2
        WHEN tipo = 'SAÍDAS'
             AND co_grupo IS NULL THEN
            3
        WHEN tipo = 'SAÍDAS'
             AND co_grupo IS NOT NULL THEN
            4
    END,
    co_grupo,
    CASE
        WHEN co_subgrupo IS NULL THEN
                0
        ELSE
            1
    END,
    total DESC
