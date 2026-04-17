/*
    Analise da Consulta: CPF_empresa_regime_especial.sql
    Objetivo: Listar regimes especiais concedidos a uma empresa (beneficios fiscais).

    Tabelas Utilizadas:
    - sitafe.sitafe_regime_contribuinte (t): Regimes especiais vinculados ao contribuinte.
      Colunas: gr_identificacao, it_co_regime, it_nu_ato, it_nu_processo, datas, observacoes.
    - sitafe.sitafe_regime_especial_padrao (r): Descricoes dos tipos de regime.
      Colunas: it_co_regime, it_no_regime.

    Regimes Especiais Tipicos:
    - Diferimento de ICMS
    - Credito presumido
    - Reducao de base de calculo
    - Isencao

    Logica Principal:
    1. Busca regimes vinculados ao CNPJ (extraido de gr_identificacao).
    2. Filtra apenas registros "ultima versao" (it_in_ultima = '9').
    3. Formata datas armazenadas como string (YYYYMMDD) para DATE.
    4. Indica situacao: ATIVO (sem data baixa) ou CANCELADO (com data baixa).
*/

SELECT
                                        t.it_co_regime         co_reg,               -- Codigo do regime
                                        r.it_no_regime         regime,               -- Nome do regime especial
                                        t.it_nu_ato            nu_ato,               -- Numero do ato normativo
                                        t.it_nu_processo       nu_processo,          -- Numero do processo
                                        -- Conversao de datas (string YYYYMMDD para DATE)
                                        CASE
                                            WHEN t.it_da_transacao > '1' THEN
                                                TO_DATE(t.it_da_transacao, 'YYYYMMDD')
                                        END da_transacao,
                                        CASE
                                            WHEN t.it_da_cadastro > '1' THEN
                                                TO_DATE(t.it_da_cadastro, 'YYYYMMDD')
                                        END da_cadastro,
                                        CASE
                                            WHEN t.it_da_vencimento > '1' THEN
                                                TO_DATE(t.it_da_vencimento, 'YYYYMMDD')
                                        END da_vencimento,
                                        CASE
                                            WHEN t.it_da_baixa > '1' THEN
                                                TO_DATE(t.it_da_baixa, 'YYYYMMDD')
                                        END da_baixa,

                                        t.it_tx_observacao observacao,
                                        t.it_tx_motivo_baixa motivo_baixa,
                                        -- Situacao com cores: Azul = ATIVO, Vermelho = CANCELADO
                                        CASE
                                            WHEN t.it_da_baixa = '       ' THEN
                                                'ATIVO'
                                            ELSE
                                                'CANCELADO'
                                        END situacao
                                    FROM
                                        sitafe.sitafe_regime_contribuinte      t
                                        LEFT JOIN sitafe.sitafe_regime_especial_padrao   r ON t.it_co_regime = r.it_co_regime
                                    WHERE
                                        substr(t.gr_identificacao,2,14) = :CO_CNPJ_CPF    -- CNPJ (sem digito verificador inicial)
                                        AND t.it_in_ultima = '9'                           -- Apenas ultima versao do registro
                                    GROUP BY
                                        t.it_co_regime,
                                        r.it_no_regime,
                                        t.it_nu_ato,
                                        t.it_nu_processo,
                                        CASE
                                                WHEN t.it_da_transacao > '1' THEN
                                                    TO_DATE(t.it_da_transacao, 'YYYYMMDD')
                                            END,
                                        CASE
                                                WHEN t.it_da_cadastro > '1' THEN
                                                    TO_DATE(t.it_da_cadastro, 'YYYYMMDD')
                                            END,
                                        CASE
                                                WHEN t.it_da_vencimento > '1' THEN
                                                    TO_DATE(t.it_da_vencimento, 'YYYYMMDD')
                                            END,
                                        CASE
                                                WHEN t.it_da_baixa > '1' THEN
                                                    TO_DATE(t.it_da_baixa, 'YYYYMMDD')
                                            END,
                                        t.it_tx_motivo_baixa,
                                        CASE
                                            WHEN t.it_da_baixa = '       ' THEN
                                                    'ATIVO'
                                                ELSE
                                                    'CANCELADO'
                                            END,
                                            t.it_tx_observacao,
                                            t.it_tx_motivo_baixa
