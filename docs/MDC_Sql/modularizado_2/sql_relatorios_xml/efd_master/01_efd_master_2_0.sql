-- Origem: EFD_master.xml
-- Título no relatório: EFD Master 2.0
-- Caminho no XML: EFD Master 2.0
-- Utilidade fiscal: Altíssima
-- Foco: Resumo executivo mensal/anual da apuração própria (E110), com indicação de meses sem arquivo e saldo credor transportado.
-- Uso sugerido: Triagem inicial da situação fiscal do contribuinte no período; ótimo ponto de entrada para decidir se a investigação seguirá por apuração, ajustes, documentos ou omissões.
-- Riscos/Limites: É painel de síntese. Não substitui a validação do arquivo efetivo, dos lançamentos individuais nem do vínculo com C100/C170/C197/E111.
-- Tabelas/fontes identificadas: bi.dm_pessoa, bi.dm_calendario, bi.fato_efd_sumarizada
-- Binds declarados: cnpj, data_inicial, data_final

select * from (
select '<html><b>'||pes.co_cnpj_cpf cnpj_cpf, '<html><b>'||pes.no_razao_social info, null data_inicial, null data_final, null vl_recolher, null vl_sld_cred from bi.dm_pessoa pes
where pes.co_cnpj_cpf = :cnpj
union all
select * from (
SELECT
    :cnpj CNPJ_CPF,
        CASE
        WHEN t.data IS NOT NULL
             AND e.da_referencia IS NOT NULL
             AND t.ano IS NOT NULL THEN
            '+ '
            || TRIM(lower(t.mes))
            || '/'
            || t.ano
        WHEN t.data IS NULL
             AND e.da_referencia IS NULL
             AND t.ano IS NOT NULL THEN
            '<html><p style="color:blue">═ Total no ano de ' || t.ano
        WHEN t.data IS NULL
             AND t.ano IS NULL THEN
            '<html><b style="color:blue">Σ Período total pesquisado'
        WHEN e.da_referencia IS NULL THEN
            '<html><p style="color:red">Ø Arquivo não entregue'
    END                                  info,
    MIN(t.data)                          data_inicial,
    MAX(last_day(t.data))                            data_final,
    lpad(TRIM(to_char(SUM(e.vl_recolher), '999G999G999G990D00')), length(MAX(SUM(e.vl_recolher))
                                                                         OVER()) + 6)                         vl_recolher,
    lpad(TRIM(to_char(SUM(e.vl_sld_credor_transportar), '999G999G999G990D00')), length(MAX(SUM(e.vl_sld_credor_transportar))
                                                                                       OVER()) + 6)                         vl_sld_cred

FROM
    bi.dm_calendario    t
    LEFT JOIN bi.dm_pessoa        p ON :cnpj = p.co_cnpj_cpf
    LEFT JOIN (
        SELECT
            r.da_referencia,
            r.co_cnpj_cpf_declarante,
            r.vl_recolher,
            r.vl_sld_credor_transportar
        FROM
            bi.fato_efd_sumarizada r
        WHERE
                r.registro = 'E110'
            AND r.da_referencia BETWEEN :data_inicial AND :data_final
            AND r.co_cnpj_cpf_declarante = :cnpj
    )                   e ON t.data = e.da_referencia
WHERE
        t.dia_no_mes = 1
    AND t.data BETWEEN :data_inicial AND :data_final
GROUP BY
    GROUPING SETS ( ( :cnpj,
                      '<html><b>'
                      || rtrim(substr(p.no_razao_social, 1, instr(p.no_razao_social, ' ')))
                      || '...',
                      CASE
                          WHEN t.data IS NOT NULL
                               AND e.da_referencia IS NOT NULL
                               AND t.ano IS NOT NULL THEN
                              'Período mensal:'
                          WHEN t.data IS NULL
                               AND e.da_referencia IS NULL
                               AND t.ano IS NOT NULL THEN
                              'Período do ano:'
                          WHEN t.data IS NULL
                               AND t.ano IS NULL THEN
                              '<html><b style="color:blue">Período total pesquisado:'
                          WHEN e.da_referencia IS NULL THEN
                              '<html><p style="color:red">Arquivo não entregue!'
                      END,
                      e.da_referencia,
                      t.data,
                      t.ano,
                      t.mes,
                      last_day(t.data),
                      t.ano ), ( '<html><b>'
                                 || rtrim(substr(p.no_razao_social, 1, instr(p.no_razao_social, ' ')))
                                 || '...',
                                 t.ano )
                                 , ())
ORDER BY
    t.ano DESC,
    t.data DESC,
    last_day(t.data)))
