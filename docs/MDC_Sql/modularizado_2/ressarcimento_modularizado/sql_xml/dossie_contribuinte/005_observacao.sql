/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Historico Situação > Observação
ESTILO: Script
HABILITADA: true
BINDS:
 - TUK | prompt=TUK | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SET PAGESIZE 25;
                                            SET LINESIZE 110;
                                            SET NEWPAGE 0;
                                            SET ECHO OFF;
                                            SET FEEDBACK OFF;
                                            SET HEADING OFF;
                                            
                                            SELECT
                                                LISTAGG(CONVERT(t.it_no_ocorrencia, 'AL32UTF8', 'WE8MSWIN1252'), ' ') WITHIN GROUP(
                                                    ORDER BY
                                                        t.m_occurs
                                                ) "Ocorrência"
                                            FROM
                                                sitafe.sitafe_historico_sit_no_ocorre t
                                            WHERE
                                                t.tuk = :TUK;
