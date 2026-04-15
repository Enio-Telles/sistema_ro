/*
    Análise da Consulta: CPF_conta_corrente.sql
    Objetivo: Gerar um extrato de "Conta Corrente" fiscal para um CPF, categorizando os lançamentos
    entre Vencidos, A Vencer e Outras Situações (ex: Pagos).
    
    Tabelas Utilizadas (Baseado no Metadata/SQL):
    - bi.fato_lanc_arrec (t): Tabela fato contendo os lançamentos e arrecadações.
      Colunas Chave: id_cpf_cnpj, id_situacao, da_vencimento, valores (va_principal, va_pago, etc).
    - bi.dm_situacao_lancamento (s): Tabela dimensão com as descrições das situações.
      Colunas Chave: it_co_situacao, it_no_situacao.

    Lógica Principal:
    1. Classificação da Situação (CASE):
       - Se id_situacao = '01' (Em aberto):
         - Vencimento < Hoje -> '01 - Não pago e Vencido'
         - Vencimento > Hoje -> '01 - Não pago a vencer'
       - Outros -> Usa a descrição da tabela dimensão (ex: Pago).
    
    2. Cálculo do Valor:
       - Se va_pago é NULL (não pago), soma os componentes da dívida (principal + multa + juros + acréscimo).
       - Se va_pago existe, usa o valor pago.

    3. Agregação e Visualização:
       - Agrupa por 'Situação' calculada.
       - Gera lista de Receitas (id_receita) formatada em HTML.
       - Calcula % representativo (Ratio to Report).
*/

SELECT
            :CPF cpf,
            -- Formatação da Situação com HTML para cores (Vermelho para vencido, Azul para a vencer)
            case when id_situacao is null then 'Σ TOTAL GERAL' 
            when id_situacao = '01 - Não pago e Vencido' then '01 - Não pago e Vencido'
            when id_situacao = '01 - Não pago a vencer' then '01 - Não pago a Vencer'
            else  id_situacao  end situacao,

            lpad(
                  TRIM(to_char(
                        SUM(total),
                        '999G999G999G990D00'
                  )),
                  length(
                        MAX(SUM(total))
                        OVER()
                  )+7
            )    total,
               -- Cálculo da porcentagem (Ratio to Report) formatada
               lpad(TRIM(to_char(round(RATIO_TO_REPORT(SUM(total))
                             OVER(PARTITION BY case when id_situacao is null then 1 else 2 end), 4) * 100,
                       '990.00L',
                       'NLS_CURRENCY=%')),
            8)           rr,
            receitas
  FROM
      (
            -- Subquery 2: Agrupa por Situação e concatena as receitas
            SELECT
                  id_situacao_,
                  id_situacao,
                  SUM(valor)     total,
                  -- Concatena as receitas distintas para exibição na mesma linha
                  LISTAGG(id_receita
                          || ' - '
                          || rr,
                          '; ')WITHIN GROUP(
                         ORDER BY
                              rr DESC
                  )              receitas
              FROM
                  (
                        -- Subquery 1: Nível detalhado de extração e tratamento de regras de negócio
                        SELECT
                              id_situacao  id_situacao_,
                              -- Regra para separar '01' em Vencido vs A Vencer
                              CASE
                                    WHEN t.id_situacao = '01'
                                       AND t.da_vencimento < sysdate THEN
                                          '01 - Não pago e Vencido'
                                    WHEN t.id_situacao = '01'
                                       AND t.da_vencimento > sysdate THEN
                                          '01 - Não pago a vencer'
                                    ELSE
                                          t.id_situacao
                                          || ' - '
                                          || initcap(
                                                s.it_no_situacao
                                          )
                              END          id_situacao,
                              t.id_receita,
                              -- Regra de Valor: Dívida Total ou Valor Pago
                              SUM(
                                    CASE
                                          WHEN t.va_pago IS NULL THEN
                                                (t.va_principal + t.va_multa + t.va_juros + t.va_acrescimo)
                                          ELSE
                                                t.va_pago
                                    END
                              )            valor,
                              -- Cálculo do % de representatividade da linha
                              lpad(
                                    TRIM(to_char(
                                          round(
                                                RATIO_TO_REPORT(SUM(
                                                      CASE
                                                            WHEN va_pago IS NULL THEN
                                                                  (t.va_principal + t.va_multa + t.va_juros + t.va_acrescimo)
                                                            ELSE
                                                                  t.va_pago
                                                      END
                                                ))
                                                OVER(PARTITION BY
                                                      CASE
                                                            WHEN t.id_situacao = '01'
                                                               AND t.da_vencimento < sysdate THEN
                                                                  '01 - Não pago e Vencido'
                                                            WHEN t.id_situacao = '01'
                                                               AND t.da_vencimento > sysdate THEN
                                                                  '01 - Não pago a vencer'
                                                            ELSE
                                                                  t.id_situacao
                                                                  || ' - '
                                                                  || initcap(
                                                                        s.it_no_situacao
                                                                  )
                                                      END
                                                ),
                                                4
                                          )* 100,
                                          '990.00L',
                                          'NLS_CURRENCY=%'
                                    )),
                                    8
                              )            rr
                          FROM
                              bi.fato_lanc_arrec           t
                                LEFT JOIN bi.dm_situacao_lancamento    s ON t.id_situacao = s.it_co_situacao
                         WHERE
                              t.id_cpf_cnpj = :CPF
                         GROUP BY
                                    CASE
                                          WHEN t.id_situacao = '01'
                                             AND t.da_vencimento < sysdate THEN
                                                '01 - Não pago e Vencido'
                                          WHEN t.id_situacao = '01'
                                             AND t.da_vencimento > sysdate THEN
                                                '01 - Não pago a vencer'
                                          ELSE
                                                t.id_situacao
                                                || ' - '
                                                || initcap(
                                                      s.it_no_situacao
                                                )
                                    END,
                                    t.id_situacao,
                                    t.id_receita
                   )
              GROUP BY
                   id_situacao_,
                   id_situacao
       )
 GROUP BY
      -- Grouping Sets para gerar o Total Geral e as linhas de detalhe
      GROUPING SETS((),(id_situacao_,
                        id_situacao,
                        receitas))
                        
order by case when id_situacao_ is null then 1
                  when id_situacao_ = '01' then 2
                  else 3 end, total desc