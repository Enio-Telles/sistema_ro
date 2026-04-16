-- Origem: EFD_master.xml
-- Título no relatório: Lançamento
-- Caminho no XML: EFD Master 2.0 > Lançamento
-- Utilidade fiscal: Alta
-- Foco: Arrecadação/lançamentos financeiros por receita, situação e guia no período.
-- Uso sugerido: Conciliar apuração declarada com recolhimento efetivo, inadimplemento e situação do débito.
-- Riscos/Limites: O filtro substr(t.nu_complemento, 5) like '1500000000' é regra operacional forte e precisa ser validado no ambiente.
-- Tabelas/fontes identificadas: bi.fato_lanc_arrec, bi.dm_receita, bi.dm_situacao_lancamento
-- Binds declarados: DATA_INICIAL, DATA_FINAL, CNPJ_CPF

--<html><b style="color:blue">Σ Período total pesquisado
SELECT
    CASE
        WHEN t.da_referencia IS NULL THEN
            NULL
        ELSE
            :DATA_INICIAL
    END               data_inicial,
    CASE
        WHEN t.da_referencia IS NULL THEN
            NULL
        ELSE
            :DATA_FINAL
    END               data_final,
    t.da_referencia,
    t.nu_guia,
    CASE
        WHEN t.da_referencia IS NULL THEN
            NULL
        ELSE
            t.id_receita
    END               id_rec,
    CASE
        WHEN t.da_referencia IS NULL THEN
            NULL
        ELSE
            t.id_situacao
    END               sit,
    CASE
        WHEN id_receita IS NULL
             AND id_situacao IS NULL THEN
            '<html><b>Σ Total geral'
        WHEN id_receita IS NOT NULL
             AND id_situacao IS NULL THEN
            '<html><p style="color:blue">= 1 - Total da receita <b>'
            || t.id_receita
            || ' - '
            || rec.it_no_receita
        WHEN t.da_referencia IS NULL
             AND t.id_receita IS NULL
             AND t.id_situacao IS NOT NULL THEN
            '<html><p style="color:blue">= 2 - Total com a situação <b>'
            || t.id_situacao
            || ' - '
            || sit.it_no_situacao
        WHEN t.da_referencia IS NULL
             AND t.id_receita IS NOT NULL
             AND t.id_situacao IS NOT NULL THEN
            '<html><p style="color:blue">= 3 - Total da receita '
            || t.id_receita
            || ' - '
            || rec.it_no_receita
            || ', na situação '
            || t.id_situacao
            || ' - '
            || sit.it_no_situacao
        ELSE
            t.id_receita
            || ' - '
            || rec.it_no_receita
    END               info,
    lpad(TRIM(to_char(round(RATIO_TO_REPORT(SUM(t.va_principal))
                            OVER(PARTITION BY
        CASE
            WHEN da_referencia IS NULL
                 AND id_receita IS NULL
                 AND id_situacao IS NULL THEN
                0
            WHEN da_referencia IS NULL
                 AND id_receita IS NOT NULL
                 AND id_situacao IS NULL THEN
                1
            WHEN da_referencia IS NULL
                 AND id_receita IS NOT NULL
                 AND id_situacao IS NOT NULL THEN
                2
            WHEN t.da_referencia IS NULL
                 AND t.id_receita IS NULL
                 AND t.id_situacao IS NOT NULL THEN
                3
            ELSE
                4
        END
                            ),
                            4) * 100,
                      '990.00L',
                      'NLS_CURRENCY=%')),
         8)           rr,
    lpad(TRIM(to_char(SUM(t.va_principal), '999G999G999G990D00')), length(MAX(SUM(t.va_principal))
                                                                          OVER()) + 6)      va_principal,
    lpad(TRIM(to_char(SUM(t.va_multa), '999G999G999G990D00')), length(MAX(SUM(t.va_multa))
                                                                      OVER()) + 6)      va_multa,
    lpad(TRIM(to_char(SUM(t.va_juros), '999G999G999G990D00')), length(MAX(SUM(t.va_juros))
                                                                      OVER()) + 6)      va_juros,
    lpad(TRIM(to_char(SUM(t.va_acrescimo), '999G999G999G990D00')), length(MAX(SUM(t.va_acrescimo))
                                                                          OVER()) + 6)      va_acrescimo,
    lpad(TRIM(to_char(SUM(t.va_pago), '999G999G999G990D00')), length(MAX(SUM(t.va_pago))
                                                                     OVER()) + 6)      va_pago
FROM
    bi.fato_lanc_arrec           t
    LEFT JOIN bi.dm_receita                rec ON t.id_receita = rec.it_co_receita
    LEFT JOIN bi.dm_situacao_lancamento    sit ON t.id_situacao = sit.it_co_situacao
WHERE
        t.id_cpf_cnpj = :CNPJ_CPF
    AND t.da_referencia BETWEEN :DATA_INICIAL AND :DATA_FINAL
    AND substr(t.nu_complemento, 5) LIKE '1500000000'
GROUP BY
    GROUPING SETS ( ( ), ( t.id_receita,
                           rec.it_no_receita ), ( t.id_situacao,
                                                  sit.it_no_situacao ), ( t.id_receita,
                                                                          rec.it_no_receita,
                                                                          t.id_situacao,
                                                                          sit.it_no_situacao ), ( t.id_receita,
                                                                                                  rec.it_no_receita,
                                                                                                  t.id_situacao,
                                                                                                  sit.it_no_situacao,
                                                                                                  t.da_referencia,
                                                                                                  t.nu_guia ) )
ORDER BY
    CASE
        WHEN da_referencia IS NULL
             AND id_receita IS NULL
             AND id_situacao IS NULL THEN
            0
        WHEN da_referencia IS NULL
             AND id_receita IS NOT NULL
             AND id_situacao IS NULL THEN
            1
        WHEN da_referencia IS NULL
             AND id_receita IS NOT NULL
             AND id_situacao IS NOT NULL THEN
            3
        WHEN t.da_referencia IS NULL
             AND t.id_receita IS NULL
             AND t.id_situacao IS NOT NULL THEN
            2
        ELSE
            4
    END,
    SUM(t.va_principal) DESC
