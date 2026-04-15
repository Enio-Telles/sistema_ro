/*
    Analise da Consulta: CPF_infracao.sql
    Objetivo: Listar autos de infracao lavrados contra um contribuinte.
    
    Tabelas Utilizadas:
    - bi.fato_acao_fiscal_ainf (t): Autos de infracao.
      Colunas: da_lavratura_auto, nu_termo_infracao, va_tributo, va_multa, va_juros, etc.
    - bi.dm_acao_fiscal (u): Acoes fiscais vinculadas.
    - bi.dm_acao_fiscal_historico_tate (tate): Situacao no TATE (tribunal administrativo).
    - sitafe.sitafe_devedor_solidario: Devedores solidarios.
    - bi.dm_pessoa: Dados dos devedores solidarios.

    Logica Principal:
    1. Busca autos de infracao pelo CPF/CNPJ do contribuinte.
    2. Filtra apenas a ultima situacao do TATE (in_ultima = 9).
    3. Agrupa devedores solidarios (LISTAGG) para tributo e multa.
    4. Usa GROUPING SETS para gerar total geral e detalhes.
    5. Formata valores monetarios com separadores.
    
    Campos Retornados:
    - Tributo, multa, juros e total por auto.
    - Periodo fiscalizado.
    - Situacao no TATE.
    - Devedores solidarios.
*/

SELECT
      da_lavratura,
      nu_termo_infracao,
      case when local is null then 'VALOR TOTAL DOS AUTOS DE INFRACOES LAVRADOS:' else local end local,
      LPAD(TRIM(to_char(va_tributo, '999G999G999G990D00')),18) va_tributo,      
      LPAD(TRIM(to_char(va_multa, '999G999G999G990D00')),18) va_multa,   
      LPAD(TRIM(to_char(va_juros, '999G999G999G990D00')),18) va_juros,   
       LPAD(TRIM(to_char(total, '999G999G999G990D00')),18) total,
      periodo_fiscalizado,
      situacao_tate,
      solid_trib,
      solid_multa
  FROM
      (
            SELECT
                  t.da_lavratura_auto                                   da_lavratura,
                  t.nu_termo_infracao,
                  upper(convert(t.no_local_lavratura, 'AL32UTF8', 'WE8MSWIN1252'))     local,
                  SUM(t.va_tributo)                                     va_tributo,
                  SUM(t.va_multa)                                       va_multa,
                  SUM(t.va_juros)                                       va_juros,
                  SUM(t.va_tributo + t.va_multa + t.va_juros)           total,
                  '  ' || t.da_periodo_inicio_auto || '    -    ' || t.da_periodo_final_auto || '  '    periodo_fiscalizado,
                  tate.no_situacao                                      situacao_tate,
                  solid_trib.solidarios_trib                            solid_trib,
                  solid_multa.solidarios_multa                          solid_multa
              FROM
                  bi.fato_acao_fiscal_ainf            t
                    LEFT JOIN bi.dm_acao_fiscal                   u ON t.nu_acao_fiscal = u.nu_acao_fiscal
                    LEFT JOIN bi.dm_acao_fiscal_historico_tate    tate ON t.nu_termo_infracao = tate.nu_termo_infracao
                    -- Devedores solidarios do tributo
                    LEFT JOIN(
                        SELECT
                              d.it_nu_guia,
                              LISTAGG(ptrib.co_cnpj_cpf || ' - ' || ptrib.no_razao_social, ', ')
                              WITHIN GROUP(ORDER BY d.it_nu_guia) solidarios_trib
                          FROM
                              sitafe.sitafe_devedor_solidario    d
                                LEFT JOIN bi.dm_pessoa                       ptrib ON d.it_nu_cpf_cnpj_devedor = ptrib.co_cnpj_cpf
                         GROUP BY
                              d.it_nu_guia
                  )                                   solid_trib ON solid_trib.it_nu_guia = t.nu_guia_lanc_trib
                    -- Devedores solidarios da multa
                    LEFT JOIN(
                        SELECT
                              d.it_nu_guia,
                              LISTAGG(pmulta.co_cnpj_cpf || ' - ' || pmulta.no_razao_social, ', ')
                              WITHIN GROUP(ORDER BY d.it_nu_guia) solidarios_multa
                          FROM
                              sitafe.sitafe_devedor_solidario    d
                                LEFT JOIN bi.dm_pessoa                       pmulta ON d.it_nu_cpf_cnpj_devedor = pmulta.co_cnpj_cpf
                         GROUP BY
                              d.it_nu_guia
                  )                                   solid_multa ON solid_multa.it_nu_guia = t.nu_guia_lanc_multa
             WHERE
                        u.co_cnpj_cpf = :CPF
                     AND tate.in_ultima = 9
             GROUP BY
                  GROUPING SETS((),(t.da_lavratura_auto,
                                    t.nu_termo_infracao,
                                    upper(convert(t.no_local_lavratura, 'AL32UTF8', 'WE8MSWIN1252')),
                                    '  ' || t.da_periodo_inicio_auto || '    -    ' || t.da_periodo_final_auto || '  ',
                                    tate.no_situacao,
                                    solid_trib.solidarios_trib,
                                    solid_multa.solidarios_multa))
             ORDER BY
                  t.da_lavratura_auto DESC
      )
