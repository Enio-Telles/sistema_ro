/*
CONSULTA EXTRAÍDA DE XML DE PAINEL
ORIGEM_XML: dossie_contribuinte.xml
CAMINHO_NO_XML: Dossiê Contribuinte NIF - 4.3.7 > Atividades
ESTILO: Table
HABILITADA: true
BINDS:
 - CO_CNPJ_CPF | prompt=CO_CNPJ_CPF | default=NULL_VALUE
OBSERVACAO:
 - SQL extraído do XML sem alteração funcional.
 - Tags HTML, formatação de apresentação e scripts de SQL*Plus foram preservados quando existentes.
*/
SELECT
                                    base.tipo,
                                    base.co_cnae,
                                    cnae.no_cnae
                                FROM
                                    (
                                        SELECT
                                            'SECUND' tipo,
                                            t.co_cnae_secundaria co_cnae
                                        FROM
                                            bi.dm_cnae_secundaria t
                                        WHERE
                                            t.co_cnpj_cpf = :CO_CNPJ_CPF
                                        UNION
                                        SELECT
                                            'PRINCIPAL' tipo,
                                            t.co_cnae co_cnae
                                        FROM
                                            bi.dm_pessoa t
                                        WHERE
                                            t.co_cnpj_cpf = :CO_CNPJ_CPF
                                    ) base
                                    LEFT JOIN bi.dm_cnae cnae ON base.co_cnae = cnae.co_cnae
                                ORDER BY
                                    base.tipo ASC,
                                    base.co_cnae
