/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Historico Situação
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CAD_ICMS | prompt=CO_CAD_ICMS | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
                                        to_date(u.it_da_transacao, 'YYYYMMDD')        data,
                                        t.it_co_situacao_contribuinte                 sit,
                                        CONVERT(cad_sit.it_no_situacao_contribuinte, 'AL32UTF8', 'WE8MSWIN1252')descricao,                                           
                                        u.it_nu_fac                                   fac,
                                        u.it_co_usuario                               usuario,
                                        u.tuk
                                    FROM
                                        sitafe.sitafe_historico_gr_situacao    t
                                        LEFT JOIN sitafe.sitafe_historico_situacao       u ON t.tuk = u.tuk
                                        LEFT JOIN sitafe.sitafe_tabelas_cadastro         cad_sit ON t.it_co_situacao_contribuinte = cad_sit.it_co_situacao_contribuinte
                                    WHERE
                                        u.it_nu_inscricao_estadual = :CO_CAD_ICMS
                                        AND t.it_co_situacao_contribuinte NOT IN ( '030', '150', '005' )
                                        AND u.it_co_usuario not in('INTERNET', 'P30015AC   ')
                                    ORDER BY
                                        u.it_in_ultima_situacao DESC,
                                        u.it_da_atualizacao_situacao DESC,
                                        u.it_ho_transacao DESC,
                                        t.it_da_situacao_contribuinte DESC
