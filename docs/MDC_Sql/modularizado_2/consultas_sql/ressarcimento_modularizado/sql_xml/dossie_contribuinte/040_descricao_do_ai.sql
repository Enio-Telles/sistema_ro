/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Autos de Infração > Descrição do AI
ESTILO: Script
HABILITADA: true
BINDS:
 - NU_TERMO_INFRACAO | prompt=NU_TERMO_INFRACAO | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
set pagesize 25;
                                        SET LINESIZE 110;
                                        SELECT
                                            'Número do Auto de Infração: '
                                            || t.nu_termo_infracao
                                            || '                 Data da lavratura: '
                                            || t.da_lavratura_auto
                                            || CHR(10)
                                            || 'Sujeito passivo: '
                                            || pessoa.no_razao_social
                                            || CHR(10)
                                            || 'CNPJ: '|| pessoa.co_cnpj_cpf || '            IE: ' || pessoa.co_cad_icms
                                            || CHR(10)
                                            || CHR(10)
                                            || 'Histórico da infração:'
                                            || CHR(10)
                                            ||CONVERT(t.tx_infracao, 'AL32UTF8', 'WE8MSWIN1252')
                                            || CHR(10)
                                            || CHR(10)
                                            || 'Penalidade:'
                                            || CHR(10)
                                            || t.no_penalidade_auto
                                            || CHR(10)
                                            || CHR(10)
                                            || 'Trâmite do processo no TATE: '
                                            || CHR(10)
                                            || TO_CHAR(
                                                LISTAGG(u.da_situacao
                                                        || ' - '
                                                        || u.no_situacao, CHR(10)) WITHIN GROUP(
                                                    ORDER BY
                                                        u.da_situacao
                                                )
                                            ) tramite
                                        FROM
                                            bi.fato_acao_fiscal_ainf           t
                                            LEFT JOIN bi.dm_acao_fiscal_historico_tate   u ON t.nu_termo_infracao = u.nu_termo_infracao
                                            LEFT JOIN bi.dm_acao_fiscal                  acao ON t.nu_acao_fiscal = acao.nu_acao_fiscal
                                            LEFT JOIN bi.dm_pessoa                       pessoa ON acao.co_cnpj_cpf = pessoa.co_cnpj_cpf
                                        WHERE
                                            t.nu_termo_infracao = :NU_TERMO_INFRACAO
                                        GROUP BY
                                            t.nu_termo_infracao,
                                            t.da_lavratura_auto,
                                            t.no_penalidade_auto,
                                            t.tx_infracao,
                                            pessoa.no_razao_social,  pessoa.co_cnpj_cpf, pessoa.co_cad_icms
