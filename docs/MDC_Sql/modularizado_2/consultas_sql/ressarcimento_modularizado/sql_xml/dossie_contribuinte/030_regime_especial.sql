/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Regime Especial
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CNPJ_CPF | prompt=CO_CNPJ_CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
                                        t.it_co_regime         co_reg,
                                        r.it_no_regime         regime,
                                        t.it_nu_ato            nu_ato,
                                        t.it_nu_processo       nu_processo,
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
                                        CASE
                                            WHEN t.it_da_baixa = '       ' THEN
                                                '<html><strong><font color="blue">'
                                                || 'ATIVO'
                                                || '</font></strong>'
                                            ELSE
                                                        '<html><strong><font color="red">'
                                                || 'CANCELADO'
                                                || '</font></strong>'
                                        END situacao
                                    FROM
                                        sitafe.sitafe_regime_contribuinte      t
                                        LEFT JOIN sitafe.sitafe_regime_especial_padrao   r ON t.it_co_regime = r.it_co_regime
                                    WHERE
                                        substr(t.gr_identificacao,2,14) = :CO_CNPJ_CPF
                                        AND t.it_in_ultima = '9'
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
                                                    '<html><strong><font color="blue">'
                                                    || 'ATIVO'
                                                    || '</font></strong>'
                                                ELSE
                                                    '<html><strong><font color="red">'
                                                    || 'CANCELADO'
                                                    || '</font></strong>'
                                            END,
                                            t.it_tx_observacao,
                                            t.it_tx_motivo_baixa
