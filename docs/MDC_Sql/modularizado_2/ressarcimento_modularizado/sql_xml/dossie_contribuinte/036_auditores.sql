/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Ações Fiscais > Auditores
ESTILO: Table
HABILITADA: true
BINDS:
 - ACAO_FISCAL | prompt=ACAO_FISCAL | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
                                            t.co_matricula,
                                            t.co_cpf_auditor,
                                            p.no_razao_social
                                        FROM
                                            bi.dm_acao_fiscal_auditores    t
                                            LEFT JOIN bi.dm_pessoa                   p ON t.co_cpf_auditor = p.co_cnpj_cpf
                                        WHERE
                                            t.nu_acao_fiscal = :ACAO_FISCAL
